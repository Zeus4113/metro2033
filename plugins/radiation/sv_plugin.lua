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

    for _, client in ipairs(player.GetAll()) do
        if not client:Alive() then continue end
        local char = client:GetCharacter()
        if not char then continue end

        if char:GetData("BlockingRadiation") then continue end

        local radiationGain = char:GetData("radiationToAdd")

        if not radiationGain then return end

        local mask = GetEquippedItem(char, "Helmet")

        -- If no filter time or gasmask and in high rad zone, damage player
        if radiationGain > ix.config.Get("noGasmaskRadiationThreshold") then
            if not mask or not mask.isGasmask then
                self:ApplyRadiationDamage(client, ix.config.Get("noGasmaskRadiationDamage", 10))
            else
                if mask:GetData("filterTime", 0) <= 0 then
                    self:ApplyRadiationDamage(client, ix.config.Get("noGasmaskRadiationDamage", 10))
                end
            end
        end

        if radiationGain > 0 then

            -- Apply radiation to character
            local protection = char:GetRadiationProtection()

            local survival = char:GetAttribute("survival", 0)
            radiationGain = radiationGain * (1 - survival * ix.config.Get("survivalRadResist"))

            char:AddRadiation(radiationGain * (1 - protection))

            -- Apply filter drain on gasmask
            if mask and mask.isGasmask then

                local filterTime = mask:GetData("filterTime", 0)

                if filterTime > 0 then

                    local durability = mask:GetData("durability", mask.maxDurability)
                    local ratio = durability / mask.maxDurability
                    local drain = mask.filterDrainRate * (1 + (1 - ratio))

                    mask:SetData("filterTime", math.max(filterTime - drain, 0))
                end
            end

        else
            char:AddRadiation(-ix.config.Get("radiationDecay", 0.5))
        end

        local threshold = ix.config.Get("radiationThreshold", 60)

        if char:GetRadiation() >= threshold then
            self:ApplyRadiationDamage(client, ix.config.Get("radiationDamage", 2)) 
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