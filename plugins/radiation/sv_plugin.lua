local NEXT_TICK = 0
local PLUGIN = PLUGIN

function PLUGIN:Initialize()
    self.zones = ix.data.Get("radiationZones", {})
end

function PLUGIN:OnCharacterCreated(client, character)
    if not client then return end
    if not character then return end
    character:SetRadiation(0)
    character:SetData("BlockingRadiation", false)
end

function PLUGIN:OnPlayerObserve(client, state)
    if not client then return end
    local character = client:GetCharacter()
    if not character then return end

    if state then
        character:SetData("BlockingRadiation", true)
    else
        character:SetData("BlockingRadiation", false)
    end
end

hook.Add("PlayerDeath", "ResetRadiation",  function( victim, inflictor, attacker )
    if not victim then return end
    local character = victim:GetCharacter()
    if not character then return end
    character:SetRadiation(0)
end)

function PLUGIN:Think()
    if CurTime() < NEXT_TICK then return end
    NEXT_TICK = CurTime() + ix.config.Get("radiationTickRate", 1)

    local noMaskThreshold = ix.config.Get("noGasmaskRadiationThreshold")
    local noMaskDamage    = ix.config.Get("noGasmaskRadiationDamage", 10)
    local survivalResist  = ix.config.Get("survivalRadResist")
    local radThreshold    = ix.config.Get("radiationThreshold", 60)
    local radMax          = ix.config.Get("radiationMax", 100)
    local baseDamage      = ix.config.Get("radiationDamage", 2)
    local radDecay        = ix.config.Get("radiationDecay", 0.5)

    for _, client in ipairs(player.GetAll()) do
        if not client:Alive() then continue end
        local char = client:GetCharacter()
        if not char then continue end

        if char:GetData("BlockingRadiation") then continue end

        local radiationGain = char:GetData("radiationToAdd")

        if not radiationGain then continue end

        local mask = GetEquippedItem(char, "Helmet")

        -- If no filter time or gasmask and in high rad zone, damage player
        if radiationGain > noMaskThreshold then
            if not mask or not mask.isGasmask then
                self:ApplyRadiationDamage(client, noMaskDamage)
            else
                if mask:GetData("filterTime", 0) <= 0 then
                    self:ApplyRadiationDamage(client, noMaskDamage)
                end
            end
        end

        if radiationGain > 0 then

            -- Apply radiation to character
            local protection = char:GetRadiationProtection()

            local survival = char:GetAttribute("survival", 0)
            radiationGain = radiationGain * (1 - survival * survivalResist)

            char:AddRadiation(radiationGain * (1 - protection))

            -- Apply filter drain on gasmask
            if mask and mask.isGasmask then

                local filterTime = mask:GetData("filterTime", 0)

                if filterTime > 0 then

                    local durability = mask:GetData("durability", mask.maxDurability)
                    local ratio = durability / mask.maxDurability
                    local drain = mask.filterDrainRate * (1 + (1 - ratio))

                    local newFilterTime = math.max(filterTime - drain, 0)
                    mask:SetData("filterTime", newFilterTime)

                    local threshold = mask.maxFilterTime * 0.1
                    if filterTime > threshold and newFilterTime <= threshold then
                        client:Notify("Warning: Gas mask filter is nearly depleted!")
                        net.Start("ixFilterWarning") net.WriteBool(false) net.Send(client)
                    end

                    if newFilterTime == 0 then
                        client:Notify("Your gas mask filter has run out!")
                        net.Start("ixFilterWarning") net.WriteBool(true) net.Send(client)
                    end
                end
            end

        else
            char:AddRadiation(-radDecay)
        end

        if char:GetRadiation() >= radThreshold then
            local range = radMax - radThreshold
            local t     = range > 0 and (char:GetRadiation() - radThreshold) / range or 1
            self:ApplyRadiationDamage(client, baseDamage * Lerp(t, 1, 10))
        end
    end
end

function PLUGIN:ApplyRadiationDamage(client, damage)
    if not client or not client:Alive() then return end
    local dmg = DamageInfo()
    dmg:SetDamage(damage)
    dmg:SetDamageType(DMG_RADIATION)
    dmg:SetAttacker(game.GetWorld())
    dmg:SetInflictor(game.GetWorld())
    client:TakeDamageInfo(dmg)
end