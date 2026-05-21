if not CLIENT then return end

local PLUGIN = PLUGIN

local staminaThreshold = ix.config.Get("staminaThreshold", 50)
local healthThreshold = ix.config.Get("healthThreshold", 50)

PLUGIN.effectState = {
    addr = 0,
    addg = 0,
    addb = 0,

    brightness = 0,
    contrast = 1,
    colour = 1,

    blur = 0
}

--------------------------------------------------------
-- RADIATION STATE
--------------------------------------------------------

local smoothRadiation = 0
local staticMat = Material("effects/combine_binocoverlay")

--------------------------------------------------------
-- STAMINA SWAY
-- Phase accumulates at a rate driven by the same pitch formula as the
-- breath audio (90 + intensity*25)/100, so sway and sound stay in sync.
--------------------------------------------------------

local swayPhase = 0

hook.Add("Think", "Metro_StaminaSwayPhase", function()
    local client = LocalPlayer()
    if not IsValid(client) then return end
    local stamina = client:GetLocalVar("stm", 100)
    if stamina >= staminaThreshold then return end
    local intensity  = 1 - (stamina / staminaThreshold)
    local pitchScale = (90 + intensity * 25) / 100
    local baseRate   = 1.2 + intensity * 0.8
    swayPhase = (swayPhase + FrameTime() * baseRate * pitchScale) % (math.pi * 2)
end)

hook.Add("CalcView", "Metro_LowStaminaSway", function(ply, origin, angles, fov)
    local stamina = ply:GetLocalVar("stm", 100)
    if stamina >= staminaThreshold then return end

    local intensity = 1 - (stamina / staminaThreshold)

    angles.pitch = angles.pitch + math.sin(swayPhase)       * intensity * 1.2
    angles.yaw   = angles.yaw   + math.sin(swayPhase * 0.7) * intensity * 0.6
    angles.roll  = angles.roll  + math.sin(swayPhase * 0.5) * intensity * 0.4

    return { origin = origin, angles = angles, fov = fov }
end)

--------------------------------------------------------
-- RADIATION SWAY
--------------------------------------------------------

hook.Add("CalcView", "Metro_RadiationSway", function(ply, origin, angles, fov)

    local char = ply:GetCharacter()
    if not char then return end

    local rad = smoothRadiation
    if rad <= 300 then return end

    local sway = math.Clamp((rad - 300) / 200, 0, 1)

    angles.roll = angles.roll + math.sin(CurTime() * 1.5) * sway * 0.8
    angles.pitch = angles.pitch + math.sin(CurTime() * 1.2) * sway * 0.4

    return {
        origin = origin,
        angles = angles,
        fov = fov
    }

end)


function PLUGIN:ApplyEffects(client)
    if not IsValid(client) then return end

    local plugin = ix.plugin.Get("metrohud")

    if not plugin then return end

    plugin:ResetEffects()

    plugin:ApplyLowHealthDesaturation(client)
    plugin:ApplyHungerEffects(client)
    plugin:ApplyThirstEffects(client)
    plugin:ApplyRadiationEffects(client)

    local fx = PLUGIN.effectState

    DrawColorModify({
        ["$pp_colour_addr"] = fx.addr,
        ["$pp_colour_addg"] = fx.addg,
        ["$pp_colour_addb"] = fx.addb,

        ["$pp_colour_brightness"] = fx.brightness,
        ["$pp_colour_contrast"] = fx.contrast,
        ["$pp_colour_colour"] = fx.colour,

        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    })

    if fx.blur > 0 then
        DrawMotionBlur(0.01, fx.blur, 0.01)
    end

end

--------------------------------------------------------
-- RESET EFFECTS
--------------------------------------------------------

function PLUGIN:ResetEffects()

    local fx = self.effectState

    fx.addr = 0
    fx.addg = 0
    fx.addb = 0

    fx.brightness = 0
    fx.contrast = 1
    fx.colour = 1

    fx.blur = 0

end

--------------------------------------------------------
-- LOW HEALTH DESATURATION
--------------------------------------------------------

function PLUGIN:ApplyLowHealthDesaturation(client)

    local health = client:Health()
    if health >= healthThreshold then return end

    local frac = math.Clamp(health / healthThreshold, 0, 1)
    local intensity = 1 - (frac * frac)

    local maxDesat = 0.65
    local colourAmount = 1 - (intensity * maxDesat)

    self.effectState.colour = math.min(self.effectState.colour, colourAmount)

end

--------------------------------------------------------
-- THIRST VISUAL EFFECTS
--------------------------------------------------------

function PLUGIN:ApplyThirstEffects(client)

    local char = client:GetCharacter()
    if not char then return end

    local thirst = char:GetThirst()
    if thirst >= 50 then return end

    local frac = math.Clamp((50 - thirst) / 50, 0, 1)

    local blur = frac * 0.25

    self.effectState.blur = math.max(self.effectState.blur, blur)

end

--------------------------------------------------------
-- HUNGER VISUAL EFFECTS
--------------------------------------------------------

function PLUGIN:ApplyHungerEffects(client)

    local char = client:GetCharacter()
    if not char then return end

    local hunger = char:GetData("hunger", 100)
    if hunger >= 50 then return end

    local frac = math.Clamp((50 - hunger) / 50, 0, 1)

    local brightness = -frac * 0.02
    local contrast = 1 - frac * 0.05
    local colour = 1 - frac * 0.25

    local fx = self.effectState

    fx.brightness = fx.brightness + brightness
    fx.contrast = math.min(fx.contrast, contrast)
    fx.colour = math.min(fx.colour, colour)

end

--------------------------------------------------------
-- RADIATION VISUAL EFFECTS
--------------------------------------------------------

local nextCough = 0

function PLUGIN:ApplyRadiationEffects(client)

    local char = client:GetCharacter()
    if not char then return end

    local rad = char:GetRadiation()
    if rad <= 75 then return end

    local maxRad = 500
    local effectStart = 75

    local frac = math.Clamp((rad - effectStart) / (maxRad - effectStart), 0, 1)

    local fx = self.effectState

    ----------------------------------------------------
    -- COLOUR TINT
    ----------------------------------------------------

    fx.addr = fx.addr + (frac * 0.05)
    fx.addg = fx.addg + (frac * 0.07)

    fx.brightness = fx.brightness - (frac * 0.03)
    fx.contrast = math.min(fx.contrast, 1 - frac * 0.08)
    fx.colour = math.min(fx.colour, 1 - frac * 0.12)

    ----------------------------------------------------
    -- BLUR
    ----------------------------------------------------

    if rad > 225 then

        local blurFrac = math.Clamp((rad - 225) / 275, 0, 1)
        local blur = blurFrac * 0.4

        fx.blur = math.max(fx.blur, blur)

    end

end