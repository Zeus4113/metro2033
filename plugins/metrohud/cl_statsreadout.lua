if not CLIENT then return end


local hungerIcon = Material("icon16/feed.png")
local thirstIcon = Material("icon16/water.png")

local smoothHunger = 100
local smoothThirst = 100

local function GetNeedColor(frac)
    local r = Lerp(frac, 0, 255)
    local g = Lerp(frac, 255, 0)

    return Color(r, g, 0, 220)
end


function PLUGIN:DrawNeedsHUD(client)

    local char = client:GetCharacter()
    if not char then return end

    local hunger = char:GetHunger()
    local thirst = char:GetThirst()

    local ft = FrameTime()

    smoothHunger = Lerp(ft * 6, smoothHunger, hunger)
    smoothThirst = Lerp(ft * 6, smoothThirst, thirst)

    local hungerFrac = 1 - (smoothHunger / 100)
    local thirstFrac = 1 - (smoothThirst / 100)

    local hungerColor = GetNeedColor(hungerFrac)
    local thirstColor = GetNeedColor(thirstFrac)

    local size = 60
    local x = 50
    local y = 50

    --------------------------------
    -- HUNGER
    --------------------------------

    surface.SetMaterial(hungerIcon)
    surface.SetDrawColor(hungerColor)
    surface.DrawTexturedRect(x, y, size, size)

    --------------------------------
    -- THIRST
    --------------------------------

    surface.SetMaterial(thirstIcon)
    surface.SetDrawColor(thirstColor)
    surface.DrawTexturedRect(x, y + (size * 1.5), size, size)

end