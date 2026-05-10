
-- Here is where all of your clientside hooks should go.

-- Disables the crosshair permanently.
function Schema:CharacterLoaded(character)
    self:ExampleFunction("@serverWelcome", character:GetName())
end

-- Redefine ixSubTitleFont smaller so the intro description fits on screen.
-- Uses timer.Simple(0) to defer until after GM:LoadFonts finishes on the same tick.
hook.Add("LoadFonts", "MetroSmallSubtitleFont", function(font)
    timer.Simple(0, function()
        surface.CreateFont("ixSubTitleFont", {
            font = font,
            size = ScreenScale(8),
            extended = true,
            weight = 100,
        })
    end)
end)

-- Fix the subtitle label: SizeToContents() on a long description makes it wider
-- than the screen, causing a negative x. We also expand the logoPanel height to
-- fit the wrapped content (its height is fixed at init before wrapping is known).
hook.Add("OnCharacterMenuCreated", "MetroFixSubtitleLayout", function(menu)
    local mainPanel = menu.mainPanel
    if not IsValid(mainPanel) then return end

    for _, logoPanel in ipairs(mainPanel:GetChildren()) do
        for _, child in ipairs(logoPanel:GetChildren()) do
            if child.GetFont and child:GetFont() == "ixSubTitleFont" then
                local w = ScrW() * 0.75
                -- Fill the remaining vertical space inside the logo panel so the
                -- panel itself never needs to grow (which would overlap the buttons).
                local maxH = logoPanel:GetTall() - child:GetY() - ScreenScale(8)
                child:SetWrap(true)
                child:SetWide(w)
                child:SetTall(maxH)
                child:SetPos(ScrW() * 0.5 - w * 0.5, child:GetY())
                return
            end
        end
    end
end)

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
