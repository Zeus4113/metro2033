AddCSLuaFile()

ENT.Base      = "base_gmodentity"
ENT.Type      = "anim"
ENT.PrintName = "Bounty Board"
ENT.Category  = "Metro 2033"
ENT.Spawnable = true
ENT.AdminOnly = true

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/props_phx/construct/metal_plate1.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        local char = activator:GetCharacter()
        if not char then return end

        local range = ix.config.Get("bountyBoardRange", 96)
        if activator:GetPos():DistToSqr(self:GetPos()) > range ^ 2 then return end

        local plugin = ix.plugin.Get("ixbountyboard")
        if not plugin then return end

        local state = plugin:GetOrInitState(char)

        activator.ixBountyEnt = self

        net.Start("ixBountyOpen")
            net.WriteEntity(self)
            net.WriteTable(plugin:GetDailyBounties())
            net.WriteTable(state.quests)
        net.Send(activator)
    end

    function ENT:OnRemove()
        -- Close panel for anyone looking at this board.
        for _, ply in ipairs(player.GetAll()) do
            if ply.ixBountyEnt == self then
                ply.ixBountyEnt = nil
                net.Start("ixBountyStateUpdate")
                    net.WriteTable({})
                net.Send(ply)
            end
        end
    end

    function ENT:SpawnFunction(client, trace)
        local ent = ents.Create("ix_bountyboard")
        ent:SetPos(trace.HitPos)
        ent:SetAngles(Angle(0, (trace.HitPos - client:GetPos()):Angle().y - 180, 0))
        ent:Spawn()
        ent:Activate()
        return ent
    end
end

if CLIENT then
    function ENT:OnPopulateEntityInfo(tooltip)
        local title = tooltip:AddRow("bountyboard")
        title:SetText("Bounty Board")
        title:SetImportant()
        title:SizeToContents()

        local hint = tooltip:AddRow("hint")
        hint:SetText("A corkboard covered in handwritten notes and torn paper slips — jobs posted by those desperate enough to pay.")
        hint:SizeToContents()
    end

    ENT.PopulateEntityInfo = true
end
