local PLAYER = FindMetaTable("Player")


-- =========================
-- OUTFITS
-- =========================

function PLAYER:ApplyOutfit()
    local char = self:GetCharacter()
    if not char then return end

    local equipment = char:GetData("equipment", {})
    local outfitID = equipment["Outfit"]

    if not outfitID then
        local dwellerModel = char:GetData("dwellerModel")
        if dwellerModel then
            self:SetModel(dwellerModel)
        end
        return
    end

    local inv = char:GetInventory()
    if not inv then return end

    local item = inv:GetItemByID(outfitID)

    if not item or not item.outfitModel then
        local dwellerModel = char:GetData("dwellerModel")
        if dwellerModel then
            self:SetModel(dwellerModel)
        end
        return
    end

    self:SetModel(item.outfitModel)
end

local DEFAULT_MAX_ARMOR = 0

-- =========================
-- MAX ARMOR
-- =========================

function PLAYER:SetMaxArmor(amount)
    self:SetNWInt("ixMaxArmor", math.max(amount, 0))
end

function PLAYER:GetMaxArmor()
    return self:GetNWInt("ixMaxArmor", DEFAULT_MAX_ARMOR)
end

-- =========================
-- ARMOR CLAMPING
-- =========================

function PLAYER:ClampArmor()
    local maxArmor = self:GetMaxArmor()

    if self:Armor() > maxArmor then
        self:SetArmor(maxArmor)
    end

    if self:Armor() < 0 then
        self:SetArmor(0)
    end
end

-- When player spawns
hook.Add("PlayerSpawn", "ixResetArmorOnSpawn", function(ply)
    ply:SetMaxArmor(DEFAULT_MAX_ARMOR)
    ply:SetArmor(0)
end)

-- When character loads (Helix specific)
hook.Add("PlayerLoadedCharacter", "ixResetArmorOnCharLoad", function(ply, char)
    ply:SetMaxArmor(DEFAULT_MAX_ARMOR)
    ply:SetArmor(0)
end)

-- Clamp after damage
hook.Add("EntityTakeDamage", "ixClampArmorAfterDamage", function(ent, dmg)
    if ent:IsPlayer() then
        timer.Simple(0, function()
            if IsValid(ent) then
                ent:ClampArmor()
            end
        end)
    end
end)