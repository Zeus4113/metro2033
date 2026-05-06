if not CLIENT then return end

-- =========================
-- Materials
-- =========================

local maskMaterials = {}

for i = 1, 6 do
    maskMaterials[i] = Material(
        "morganicism/metroredux/gasmask/metromask" .. i
    )
end

-- =========================
-- Overlay
-- =========================

function PLUGIN:DrawMaskOverlay(char)
    if not ix.option.Get("gasmaskOverlay", true) then return end
    local maskItem = char:GetEquippedMask()
    if not maskItem then return end

    local stage = GetMaskStage(maskItem)
    local mat = maskMaterials[math.Clamp(stage, 1, 6)]
    if not mat then return end

    surface.SetMaterial(mat)
    surface.SetDrawColor(0,0,0,100)
    surface.DrawTexturedRect(0,0,ScrW(),ScrH())
end