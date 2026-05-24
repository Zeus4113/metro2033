AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Water Pipe"
ENT.Category = "Metro 2033"
ENT.Spawnable = true
ENT.AdminOnly = true

local FILL_SOUND = "ambient/water/water_flow_loop1.wav"
local MAX_DIST_SQR = 80 * 80

local function ValveSound()
	return "ambient/machines/squeak_" .. math.random(1, 8) .. ".wav"
end

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/props_wasteland/prison_pipefaucet001a.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(false)
		end

		self:SetNWBool("filling", false)
	end

	function ENT:StopFilling()
		self:SetNWBool("filling", false)
		self:StopSound(FILL_SOUND)
		self:EmitSound(ValveSound(), 90, math.random(90, 110))
		timer.Remove("waterpipe_dist_" .. self:EntIndex())
		self.usingPlayer = nil
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		local char = activator:GetCharacter()
		if not char then return end

		if self.nextUseTime and self.nextUseTime > CurTime() then
			local remaining = math.ceil(self.nextUseTime - CurTime())
			activator:Notify("The pipe is dry. Try again in " .. remaining .. " seconds.")
			return
		end

		local fillTime = ix.config.Get("waterPipeFillTime", 3)
		local cooldown = ix.config.Get("waterPipeCooldown", 120)
		local ent = self

		self.usingPlayer = activator
		self:SetNWBool("filling", true)
		self:EmitSound(ValveSound(), 90, math.random(90, 110))
		self:EmitSound(FILL_SOUND, 65, 100, 0.2)

		local timerID = "waterpipe_dist_" .. self:EntIndex()
		timer.Create(timerID, 0.2, 0, function()
			if not IsValid(ent) then timer.Remove(timerID) return end

			if not IsValid(ent.usingPlayer) then
				ent:StopFilling()
				return
			end

			if ent.usingPlayer:GetPos():DistToSqr(ent:GetPos()) > MAX_DIST_SQR then
				ent.usingPlayer:SetAction(false)
				ent.usingPlayer:Notify("You stepped away from the pipe.")
				ent:StopFilling()
			end
		end)

		activator:SetAction("Filling container...", fillTime, function()
			if not IsValid(ent) then return end
			ent:StopFilling()
			ent.nextUseTime = CurTime() + cooldown

			local inv = char:GetInventory()
			if not inv then return end

			local success = inv:Add("dirty_water")
			if success then
				activator:Notify("You filled a bottle with dirty water.")
			else
				ix.item.Spawn("dirty_water", activator:GetPos() + activator:GetForward() * 40 + Vector(0, 0, 20))
				activator:Notify("You filled a bottle with dirty water, but your inventory is full.")
			end
		end)
	end

	function ENT:SpawnFunction(client, trace)
		local ent = ents.Create("ix_water_pipe")
		ent:SetPos(trace.HitPos)
		ent:SetAngles(Angle(0, (trace.HitPos - client:GetPos()):Angle().y - 180, 0))
		ent:Spawn()
		ent:Activate()
		return ent
	end
end

if CLIENT then
	function ENT:Think()
		if not self:GetNWBool("filling", false) then return end
		if (self.nextParticle or 0) > CurTime() then return end
		self.nextParticle = CurTime() + 0.05

		local attachIdx = self:LookupAttachment("nozzle")
		if attachIdx <= 0 then attachIdx = self:LookupAttachment("muzzle") end
		local pos
		if attachIdx > 0 then
			pos = self:GetAttachment(attachIdx).Pos
		else
			local obbMaxs = self:OBBMaxs()
			local obbCenter = self:OBBCenter()
			pos = self:LocalToWorld(Vector(obbCenter.x, obbMaxs.y - 2, obbCenter.z - 4))
		end
		local emitter = ParticleEmitter(pos)
		if not emitter then return end

		for _ = 1, 3 do
			local p = emitter:Add("particle/smokesprites_000" .. math.random(1, 4), pos + VectorRand() * 1.5)
			if p then
				p:SetVelocity(Vector(math.Rand(-15, 15), math.Rand(-15, 15), math.Rand(-80, -30)))
				p:SetLifeTime(0)
				p:SetDieTime(math.Rand(0.2, 0.5))
				p:SetStartAlpha(200)
				p:SetEndAlpha(0)
				p:SetStartSize(math.Rand(0.5, 1.5))
				p:SetEndSize(math.Rand(1.5, 3))
				p:SetColor(130, 180, 220)
				p:SetGravity(Vector(0, 0, -400))
				p:SetCollide(false)
			end
		end
		emitter:Finish()
	end

	ENT.PopulateEntityInfo = true

	function ENT:OnPopulateEntityInfo(tooltip)
		local title = tooltip:AddRow("loot")
		title:SetText("Water Pipe")
		title:SetImportant()
		title:SizeToContents()

		local desc = tooltip:AddRow("desc")
		desc:SetText("A leaking pipe. Use it to collect dirty water.")
		desc:SizeToContents()
	end
end
