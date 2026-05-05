if not CLIENT then return end

--------------------------------------------------------
-- METRO PLAYER AUDIO CONTROLLER
--------------------------------------------------------

local staminaThreshold = ix.config.Get("staminaThreshold", 50)
local healthThreshold = ix.config.Get("healthThreshold", 50)
local radThreshold = ix.config.Get("radiationThreshold", 500)

local nextGeigerTick = 0
local nextMaskBreathTick = 0

local breathSound
local heartbeatSound
local maskBreathSound

local currentMaskBreathType
local maskBreathActive = false
local hasPlayedSuffocating = false

--------------------------------------------------------
-- SOUND TABLES
--------------------------------------------------------

local GEIGER_SOUNDS = {
    "player/geiger1.wav"
}

local BREATH_SOUNDS = {
    ["light"] = {    
        "avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath1.wav",
        "avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath2.wav",
        "avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath3.wav",
        "avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath4.wav",
        "avoxgaming/gas_mask/gas_mask_light/gas_mask_light_breath5.wav"
   },
   ["medium"] = {
        --"avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath1.wav",
        --"avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath2.wav",
        --"avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath3.wav",
        "avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath4.wav",
        "avoxgaming/gas_mask/gas_mask_middle/gas_mask_middle_breath5.wav"

   },
   ["heavy"] = {
        "avoxgaming/gas_mask/gas_mask_hard/gas_mask_hard_breath1.wav",
        "avoxgaming/gas_mask/gas_mask_hard/gas_mask_hard_breath2.wav",
        "avoxgaming/gas_mask/gas_mask_hard/gas_mask_hard_breath3.wav",
        "avoxgaming/gas_mask/gas_mask_hard/gas_mask_hard_breath4.wav",
        "avoxgaming/gas_mask/gas_mask_hard/gas_mask_hard_breath5.wav"

   },
   ["suffocating"] = {
        "affects/gas_mask_suffocation.mp3"
   }
}

--------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------

timer.Create("MetroPlayerAudioController", 0.25, 0, function()
    local client = LocalPlayer()
    if not IsValid(client) then return end

    local char = client:GetCharacter()
    if not char then return end

    if char:GetData("BlockingRadiation", false) then return end
    ----------------------------------------------------
    -- VARIABLES
    ----------------------------------------------------

    local stamina = client:GetLocalVar("stm", 100)
    local health = client:Health()
    local radiationGain = char:GetData("radiationToAdd", 0)

    ----------------------------------------------------
    -- GASMASK BREATHING
    ----------------------------------------------------
    local mask = char:GetEquippedMask()
    local filter = false

    if mask then
        filter = GasmaskHasFilter(mask)
    end

    local isProtected = mask and filter
    local radiationThreshold = ix.config.Get("noGasmaskRadiationThreshold", 10)
    local aboveMaskThreshold = radiationGain > radiationThreshold
    local breathingCategory = nil

    if radiationGain <= 0 then
    elseif isProtected then
        if radiationGain < 5 then
            breathingCategory = "light"
    elseif radiationGain < radiationThreshold then
            breathingCategory = "medium"
        else
            breathingCategory = "heavy"
        end
    elseif aboveMaskThreshold then
        breathingCategory = "suffocating"
    end

    if breathingCategory == "suffocating" and not isProtected then
        if not hasPlayedSuffocating then
            client:EmitSound(table.Random(BREATH_SOUNDS.suffocating), 60, 100, 1)
            hasPlayedSuffocating = true
        end
        maskBreathActive = true
    else
        hasPlayedSuffocating = false

        if breathingCategory then
            maskBreathActive = true

            local staminaFrac = math.Clamp(stamina / 100, 0, 1)
            local breathInterval = 1 + 2 * (1 - math.pow(1 - staminaFrac, 2))
            breathInterval = math.Clamp(breathInterval, 1, 3)

            if CurTime() >= nextMaskBreathTick then
                nextMaskBreathTick = CurTime() + breathInterval

                client:EmitSound(
                    table.Random(BREATH_SOUNDS[breathingCategory]),
                    40,
                    100,
                    0.7
                )
            end
        else
            maskBreathActive = false
        end
    end

    ----------------------------------------------------
    -- STAMINA BREATHING (disabled if mask active)
    ----------------------------------------------------

    if not maskBreathActive and stamina < staminaThreshold then

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
