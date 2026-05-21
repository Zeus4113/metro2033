PLUGIN.name = "Metro HUD"
PLUGIN.author = "BarneytheBandit"
PLUGIN.description = "Handles Metro-style HUD, overlays and breathing."

ix.util.Include("cl_mask.lua")
ix.util.Include("cl_radiation.lua")
ix.util.Include("cl_visualeffects.lua")
ix.util.Include("cl_audioeffects.lua")
ix.util.Include("cl_statsreadout.lua")
ix.util.Include("cl_bars.lua")

ix.option.Add("gasmaskOverlay", ix.type.bool, true, {
    category = "Metro HUD",
    phrase = "Show Gasmask Overlay"
})

ix.config.Add("staminaThreshold", 25, "Stamina threshold before visual & audio effects are applied.", nil, {
    data = {min = 0, max = 100},
    category = "Metro HUD"
})

ix.config.Add("healthThreshold", 50, "Health threshold before visual & audio effects are applied.", nil, {
    data = {min = 0, max = 100},
    category = "Metro HUD"
})

function PLUGIN.ShouldHideBars()
    return true
end

if CLIENT then

    hook.Add("HUDPaint", "MetroHUD", function()
        local client = LocalPlayer()
        if not IsValid(client) then return end

        local char = client:GetCharacter()
        if not char then return end

        local plugin = ix.plugin.Get("metrohud")

        plugin:DrawRadiationWatch(char)
       -- plugin:DrawNeedsHUD(client)

    end)

    hook.Add("RenderScreenspaceEffects", "Metro_MaskOverlay", function()
        local client = LocalPlayer()
        if not IsValid(client) then return end

        local char = client:GetCharacter()
        if not char then return end

        local plugin = ix.plugin.Get("metrohud")

        plugin:DrawMaskOverlay(char)
        plugin:ApplyEffects(client)

    end)

    --------------------------------------------------------
    -- DRAW HUD
    --------------------------------------------------------

	function PLUGIN:DrawMetroHUD()
        local client = LocalPlayer()
        if not IsValid(client) then return end

        local char = client:GetCharacter()
        if not char then return end

        self:DrawRadiationWatch(char)
    end	

    function PLUGIN:DrawMetroHUDBackground(client)
        if not IsValid(client) then return end

        local char = client:GetCharacter()
        if not char then return end



        self:DrawMaskOverlay(char)
        self:ApplyRadiationEffects(client)
        self:ApplyLowHealthDesaturation(client)
    end

    --------------------------------------------------------
    -- MASK UTILITY FUNCTIONS
    --------------------------------------------------------

    function GetMaskStage(item)
        if not item.maxDurability then return 1 end

        local current = item:GetData("durability", item.maxDurability)
        local frac = current / item.maxDurability

        return math.Clamp(math.ceil(6 - (frac * 5)), 1, 6)
    end

    function GasmaskHasFilter(item)
        if item:GetData("filterTime") and item:GetData("filterTime") > 0 then
            return true
        else
            return false
        end
    end

    function GetBreathTypeFromStage(stage)
        if stage <= 2 then
            return "light"
        elseif stage <= 4 then
            return "medium"
        else
            return "heavy"
        end
    end
end

--------------------------------------------------------
-- SHARED AUDIO EFFECTS
--------------------------------------------------------

local hurtSounds = {
    "actor/hurt1.mp3",
    "actor/hurt2.mp3",
    "actor/hurt3.mp3",
    "actor/hurt4.mp3",
    "actor/hurt5.mp3",
    "actor/hurt6.mp3"
}

local bulletPainSounds = {
    "actor/bu  llet_hit_1.mp3",
    "actor/bullet_hit_2.mp3",
    "actor/bullet_hit_3.mp3",
    "actor/bullet_hit_4.mp3"
}

local painSounds = {
    "actor/pain1.mp3",
    "actor/pain2.mp3",
    "actor/pain3.mp3"
}

local deathSounds = {
    "actor/die0.mp3",
    "actor/die1.mp3",
    "actor/die2.mp3",
    "actor/die3.mp3"
}

local painCooldown = {}
--[[
hook.Add("EntityEmitSound", "MetroReplacePlayerSounds", function(data)

    local ent = data.Entity
    if not IsValid(ent) or not ent:IsPlayer() then return end

    local sound = string.lower(data.SoundName)

    if string.find(sound, "bullet") then
         data.SoundName = bulletPainSounds[math.random(#bulletPainSounds)]
         return true
    end

    if string.find(sound, "fall") then
         data.SoundName = hurtSounds[math.random(#hurtSounds)]
         return true
    end

end)
]]--
function PLUGIN:GetPlayerDeathSound(client)
    return deathSounds[math.random(#deathSounds)]
end


function PLUGIN:GetPlayerPainSound(client)
    return painSounds[math.random(#painSounds)]
end