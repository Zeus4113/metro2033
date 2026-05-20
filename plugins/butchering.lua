local PLUGIN = PLUGIN

PLUGIN.name   = "Corpse Butchering"
PLUGIN.author = "Bilwin"

PLUGIN.list = {
    ["models/m2033r/npc/churzik.mdl"] = {
        butcheringTime    = 1,
        slicingSound      = {"ambient/machines/slicer2.wav", "ambient/machines/slicer3.wav"},
        butcheringWeapons = {"tfa_nmrih_kknife"},
        items             = {"mutant_meat", "mutant_guts"},
    },
    ["models/m2033r/npc/nosach_male.mdl"] = {
        butcheringTime    = 2,
        slicingSound      = {"ambient/machines/slicer2.wav", "ambient/machines/slicer3.wav"},
        butcheringWeapons = {"tfa_nmrih_kknife"},
        items             = {"mutant_meat", "mutant_meat", "mutant_skin"},
    },
    ["models/m2033r/npc/nosach.mdl"] = {
        butcheringTime    = 2,
        slicingSound      = {"ambient/machines/slicer2.wav", "ambient/machines/slicer3.wav"},
        butcheringWeapons = {"tfa_nmrih_kknife"},
        items             = {"mutant_meat", "mutant_meat", "mutant_skin"},
    },
    ["models/m2033r/npc/murzik.mdl"] = {
        butcheringTime    = 2,
        slicingSound      = {"ambient/machines/slicer2.wav", "ambient/machines/slicer3.wav"},
        butcheringWeapons = {"tfa_nmrih_kknife"},
        items             = {"watcher_hide", "mutant_meat", "mutant_meat"},
    },
    ["models/m2033r/npc/baby_murzik.mdl"] = {
        butcheringTime    = 1,
        slicingSound      = {"ambient/machines/slicer2.wav", "ambient/machines/slicer3.wav"},
        butcheringWeapons = {"tfa_nmrih_kknife"},
        items             = {"mutant_meat"},
    },
    ["models/m2033r/npc/demon.mdl"] = {
        butcheringTime    = 3,
        slicingSound      = {"ambient/machines/slicer2.wav", "ambient/machines/slicer3.wav"},
        butcheringWeapons = {"tfa_nmrih_kknife"},
        items             = {"mutant_meat", "mutant_meat", "mutant_skin", "mutant_skin", "mutant_skin"},
    },
    ["models/m2033r/npc/demon2.mdl"] = {
        butcheringTime    = 3,
        slicingSound      = {"ambient/machines/slicer2.wav", "ambient/machines/slicer3.wav"},
        butcheringWeapons = {"tfa_nmrih_kknife"},
        items             = {"mutant_meat", "mutant_meat", "mutant_skin", "mutant_skin", "mutant_skin"},
    },
    ["models/m2033r/npc/demon_buffed.mdl"] = {
        butcheringTime    = 3,
        slicingSound      = {"ambient/machines/slicer2.wav", "ambient/machines/slicer3.wav"},
        butcheringWeapons = {"tfa_nmrih_kknife"},
        items             = {"mutant_meat", "mutant_meat", "mutant_skin", "mutant_skin", "mutant_skin"},
    },
    ["models/m2033r/npc/librarian.mdl"] = {
        butcheringTime    = 3,
        slicingSound      = {"ambient/machines/slicer2.wav", "ambient/machines/slicer3.wav"},
        butcheringWeapons = {"tfa_nmrih_kknife"},
        items             = {"mutant_meat", "mutant_meat", "mutant_skin", "mutant_skin"},
    },
}

ix.config.Add("ragdollLifetime", 120, "Seconds before an unbutchered corpse ragdoll is automatically removed.", nil, {
    data = {min = 10, max = 600},
    category = PLUGIN.name
})

if SERVER then
    ix.log.AddType("playerButchered", function(client, corpse)
        return string.format("%s butchered %s.", client:Name(), corpse:GetModel())
    end)

    util.AddNetworkString("ixClearClientRagdolls")

    local function FindButcheringTool(client, allowedWeapons)
        local inv = client:GetCharacter():GetInventory()
        if not inv then return nil end
        for _, item in pairs(inv:GetItems()) do
            if item.class and table.HasValue(allowedWeapons, item.class) then
                return item
            end
        end
    end

    local function DeductToolDurability(client, tool)
        if not tool.maxDurability or tool.maxDurability <= 0 then return end

        local newDur = tool:GetData("durability", tool.maxDurability) - ix.config.Get("toolDurabilityDec", 15)
        tool:SetData("durability", newDur)

        if newDur > 0 then return end

        if tool.Unequip then tool:Unequip(client) end
        local size = (tool.width or 1) * (tool.height or 1)
        client:GetCharacter():GetInventory():Add("metal_scrap", size)
        tool:Remove()
        client:Notify(tool.name .. " has broken.")
    end

    function PLUGIN:OnNPCKilled(npc)
        if not IsValid(npc) or not self.list[npc:GetModel()] then return end

        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll:SetPos(npc:GetPos())
        ragdoll:SetAngles(npc:EyeAngles())
        ragdoll:SetModel(npc:GetModel())
        ragdoll:SetModelScale(npc:GetModelScale())
        ragdoll:SetSkin(npc:GetSkin())

        for i = 0, npc:GetNumBodyGroups() - 1 do
            ragdoll:SetBodygroup(i, npc:GetBodygroup(i))
        end

        ragdoll:Spawn()
        ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        ragdoll:Activate()

        timer.Simple(ix.config.Get("ragdollLifetime", 120), function()
            if IsValid(ragdoll) then ragdoll:Remove() end
        end)

        local velocity = npc:GetVelocity()
        for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
            local physObj = ragdoll:GetPhysicsObjectNum(i)
            if not IsValid(physObj) then continue end

            physObj:SetVelocity(velocity)

            local index = ragdoll:TranslatePhysBoneToBone(i)
            if index then
                local pos, ang = npc:GetBonePosition(index)
                physObj:SetPos(pos)
                physObj:SetAngles(ang)
            end
        end

        net.Start("ixClearClientRagdolls")
            net.WriteString(npc:GetModel())
        net.SendPVS(npc:GetPos())

        npc:Remove()
    end

    function PLUGIN:KeyPress(client, key)
        if key ~= IN_USE then return end

        local char = client:GetCharacter()
        if not char or not client:Alive() then return end

        local target = client:GetEyeTraceNoCursor().Entity
        if not IsValid(target) or not target:IsRagdoll() then return end

        local corpseData = self.list[target:GetModel()]
        if not corpseData then return end

        if target:GetNetVar("cutting", false) then return end
        if hook.Run("CanButchEntity", client, target) == false then return end

        local allowedWeapons = corpseData.butcheringWeapons or {"weapon_crowbar"}
        local tool = FindButcheringTool(client, allowedWeapons)
        if not tool then return end

        local physObj = target:GetPhysicsObject()
        local butcheringTime = corpseData.butcheringTime or 2
        if IsValid(physObj) and not isnumber(corpseData.butcheringTime) then
            butcheringTime = math.ceil(physObj:GetMass())
        end

        client:ForceSequence(corpseData.animation or "Roofidle1", nil, 0)
        client:SetAction("Butchering...", butcheringTime)
        target:SetNetVar("cutting", true)
        target:EmitSound(corpseData.slicingSound[1] or "ambient/machines/slicer1.wav")

        client:DoStaredAction(target, function()
            if not IsValid(client) then return end
            client:LeaveSequence()
            if not IsValid(target) then return end

            target:SetNetVar("cutting", nil)
            target:EmitSound(corpseData.slicingSound[2] or "ambient/machines/slicer4.wav")

            local center = target:LocalToWorld(target:OBBCenter())
            local effect = EffectData()
            effect:SetStart(center)
            effect:SetOrigin(center)
            effect:SetScale(3)
            util.Effect(corpseData.impactEffect or "BloodImpact", effect)

            local inv = char:GetInventory()
            for _, itemID in ipairs(corpseData.items or {}) do
                if not inv:Add(itemID) then
                    ix.item.Spawn(itemID, client)
                end
            end

            DeductToolDurability(client, tool)
            ix.log.Add(client, "playerButchered", target)
            hook.Run("OnButchered", client, target)
            target:Remove()
        end, butcheringTime, function()
            if not IsValid(client) then return end
            client:SetAction()
            client:LeaveSequence()
            target:SetNetVar("cutting", false)
        end)
    end

    function PLUGIN:CanButchEntity(client, target)
        return true
    end
end

if CLIENT then
    net.Receive("ixClearClientRagdolls", function()
        local model = net.ReadString()
        timer.Simple(FrameTime() * 2, function()
            for _, ragdoll in ipairs(ents.GetAll()) do
                if ragdoll:GetClass() == "class C_ClientRagdoll" and ragdoll:GetModel() == model then
                    ragdoll:Remove()
                end
            end
        end)
    end)
end
