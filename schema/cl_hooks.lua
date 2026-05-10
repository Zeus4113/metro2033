
-- Here is where all of your clientside hooks should go.

-- Disables the crosshair permanently.
function Schema:CharacterLoaded(character)
    self:ExampleFunction("@serverWelcome", character:GetName())
end

-- Suppress the default bottom-right ammo HUD.
hook.Add("CanDrawAmmoHUD", "MetroAmmoBottomLeft", function()
    return false
end)

-- Redraw ammo at the bottom left instead.
hook.Add("HUDPaintBackground", "MetroAmmoBottomLeft", function()
    local client = LocalPlayer()
    if not client:GetCharacter() then return end

    local weapon = client:GetActiveWeapon()
    if not IsValid(weapon) or weapon.DrawAmmo == false then return end

    local clip      = weapon:Clip1()
    local clipMax   = weapon:GetMaxClip1()
    local count     = client:GetAmmoCount(weapon:GetPrimaryAmmoType())
    local secondary = client:GetAmmoCount(weapon:GetSecondaryAmmoType())
    local x, y     = 16, ScrH() - 80

    if weapon:GetClass() ~= "weapon_slam" and clip > 0 or count > 0 then
        ix.util.DrawBlurAt(x, y, 128, 64)
        surface.SetDrawColor(255, 255, 255, 5)
        surface.DrawRect(x, y, 128, 64)
        surface.SetDrawColor(255, 255, 255, 3)
        surface.DrawOutlinedRect(x, y, 128, 64)
        ix.util.DrawText((clip == -1 or clipMax == -1) and count or clip .. "/" .. count, x + 64, y + 32, nil, 1, 1, "ixBigFont")
        x = x + 144
    end

    if secondary > 0 then
        ix.util.DrawBlurAt(x, y, 64, 64)
        surface.SetDrawColor(255, 255, 255, 5)
        surface.DrawRect(x, y, 64, 64)
        surface.SetDrawColor(255, 255, 255, 3)
        surface.DrawOutlinedRect(x, y, 64, 64)
        ix.util.DrawText(secondary, x + 32, y + 32, nil, 1, 1, "ixBigFont")
    end
end)
