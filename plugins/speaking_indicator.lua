local PLUGIN = PLUGIN

PLUGIN.name        = "Speaking Indicator"
PLUGIN.author      = "metro2033"
PLUGIN.description = "Shows a 'Speaking...' callout above players using voice chat."

if not CLIENT then return end

local standingOffset  = Vector(0, 0, 72)
local crouchingOffset = Vector(0, 0, 38)
local boneOffset      = Vector(0, 0, 10)
local textColor       = Color(250, 250, 250)
local shadowColor     = Color(66, 66, 66)
local SPEAK_TEXT      = "Speaking..."
local RANGE_SQ        = 280 ^ 2

function PLUGIN:LoadFonts(font, genericFont)
    surface.CreateFont("ixSpeakingIndicator", {
        font     = genericFont,
        size     = 128,
        extended = true,
        weight   = 1000,
    })
end

local function GetHeadPosition(client)
    for i = 1, client:GetBoneCount() do
        if string.find(client:GetBoneName(i):lower(), "head") then
            return client:GetBonePosition(i) + boneOffset
        end
    end
    local offset = client:Crouching() and crouchingOffset or standingOffset
    return client:GetPos() + offset
end

hook.Add("PlayerStartVoice", "ixSpeakingIndicator", function(ply)
    if ply == LocalPlayer() then return end
    ply.ixSpeaking = true
end)

hook.Add("PlayerEndVoice", "ixSpeakingIndicator", function(ply)
    ply.ixSpeaking = nil
end)

function PLUGIN:PostDrawTranslucentRenderables()
    local client = LocalPlayer()
    local pos    = client:GetPos()

    for _, v in player.Iterator() do
        if v == client or not v.ixSpeaking then continue end
        if not IsValid(v) or not v:Alive() then continue end

        local distSq = v:GetPos():DistToSqr(pos)
        if distSq >= RANGE_SQ then continue end

        local alpha = (1 - distSq / RANGE_SQ) * 255

        local angle = EyeAngles()
        angle:RotateAroundAxis(angle:Forward(), 90)
        angle:RotateAroundAxis(angle:Right(), 90)

        cam.Start3D2D(GetHeadPosition(v), Angle(0, angle.y, 90), 0.05)
            surface.SetFont("ixSpeakingIndicator")
            local _, textHeight = surface.GetTextSize(SPEAK_TEXT)

            draw.SimpleTextOutlined(
                SPEAK_TEXT,
                "ixSpeakingIndicator",
                0, -textHeight * 0.5,
                ColorAlpha(textColor, alpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                4,
                ColorAlpha(shadowColor, alpha)
            )
        cam.End3D2D()
    end
end
