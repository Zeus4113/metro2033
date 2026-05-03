if not CLIENT then return end

--------------------------------------------------------
-- METRO PLAYER AUDIO CONTROLLER
--------------------------------------------------------

local staminaThreshold = ix.config.Get("staminaThreshold", 50)
local healthThreshold = ix.config.Get("healthThreshold", 50)
local radThreshold = ix.config.Get("radiationThreshold", 500)

local nextGeigerTick = 0

local breathSound
local heartbeatSound
local maskBreathSound

local currentMaskBreathType

--------------------------------------------------------
-- SOUND TABLES
--------------------------------------------------------

local GEIGER_SOUNDS = {
    "player/geiger1.wav"
}

local BREATH_SOUNDS = {
   ["light"] = "affects/gas_mask_light.mp3",
   ["medium"] = "affects/gas_mask_middle.mp3",
   ["heavy"] = "affects/gas_mask_hard.mp3",
   ["noFilter"] = "affects/gas_mask_suffocation.mp3"
}

--------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------

timer.Create("MetroPlayerAudioController", 0.15, 0, function()

    local client = LocalPlayer()
    if not IsValid(client) then return end

    local char = client:GetCharacter()
    if not char then return end

    ----------------------------------------------------
    -- VARIABLES
    ----------------------------------------------------

    local stamina = client:GetLocalVar("stm", 100)
    local health = client:Health()
    local radiationGain = char:GetData("radiationToAdd", 0)

    ----------------------------------------------------
    -- GASMASK BREATHING
    ----------------------------------------------------

    local maskItem = GetEquippedMask(char)

    if maskItem and radiationGain > 0 then

        local breathType = "noFilter"

        if GasmaskHasFilter(maskItem) then
            local stage = GetMaskStage(maskItem)
            breathType = GetBreathTypeFromStage(stage)
        end

        if currentMaskBreathType ~= breathType then

            if maskBreathSound then
                maskBreathSound:FadeOut(0.5)
            end

            maskBreathSound = CreateSound(client, BREATH_SOUNDS[breathType])
            maskBreathSound:Play()

            currentMaskBreathType = breathType
        end

    else
  
        if maskBreathSound then
            maskBreathSound:FadeOut(1)
            maskBreathSound = nil
            currentMaskBreathType = nil
        end

    end

    ----------------------------------------------------
    -- STAMINA BREATHING (disabled if mask active)
    ----------------------------------------------------

    if not maskBreathSound and stamina < staminaThreshold then

        if not breathSound then
            breathSound = CreateSound(client, "actor/breath_1.mp3")
            breathSound:Play()
        end

        local intensity = 1 - (stamina / staminaThreshold)

        breathSound:ChangeVolume(0.3 + intensity * 0.5, 0.1)
        breathSound:ChangePitch(90 + intensity * 25, 0.1)

    else

        if breathSound then
            breathSound:FadeOut(0.5)
            breathSound = nil
        end

    end

    ----------------------------------------------------
    -- HEARTBEAT
    ----------------------------------------------------

    if health < healthThreshold then

        if not heartbeatSound then
            heartbeatSound = CreateSound(client, "player/heartbeat1.wav")
            heartbeatSound:Play()
        end

        local intensity = 1 - (health / healthThreshold)

        heartbeatSound:ChangeVolume(0.3 + intensity * 0.7, 0.1)
        heartbeatSound:ChangePitch(90 + intensity * 20, 0.1)

    else

        if heartbeatSound then
            heartbeatSound:FadeOut(0.5)
            heartbeatSound = nil
        end

    end

    ----------------------------------------------------
    -- RADIATION COUGHING
    ----------------------------------------------------

    local radiation = char:GetData("radiation", 0)
    local maxRad = char:GetData("radiationMax", 500)
    local coughThreshold = maxRad - ((maxRad - radThreshold) * 1.5)
    
    if radiation > coughThreshold then

        local chance = math.random(0, 100)
        local requirement = math.max(1, 3 * (radiation / maxRad))
        if chance < requirement  then

            client:EmitSound(
                "ambient/voices/cough"..math.random(1,2)..".wav",
                40,
                math.random(95,105),
                0.25
            )

        end
    end

    ----------------------------------------------------
    -- GEIGER COUNTER
    ----------------------------------------------------

    if char:GetInventory():HasItem("geiger_counter") and radiationGain > 0 then

        local max = 20
        local frac = math.Clamp(radiationGain / max, 0, 1)

        if CurTime() >= nextGeigerTick then

            local minDelay = 0.1
            local maxDelay = 1

            local delay = Lerp(frac, maxDelay, minDelay)

            nextGeigerTick = CurTime() + delay * math.Rand(0.8, 1.2)

            local snd = GEIGER_SOUNDS[
                math.max(math.Round(#GEIGER_SOUNDS * frac), 1)
            ]

            client:EmitSound(
                snd,
                60 + frac * 20,
                100 + frac * 20,
                0.7
            )

        end

    end

end)

--------------------------------------------------------
-- CLEANUP
--------------------------------------------------------

hook.Add("PlayerDeath", "MetroStopPlayerAudio", function()

    if breathSound then breathSound:Stop() breathSound = nil end
    if heartbeatSound then heartbeatSound:Stop() heartbeatSound = nil end
    if maskBreathSound then maskBreathSound:Stop() maskBreathSound = nil end

end)
