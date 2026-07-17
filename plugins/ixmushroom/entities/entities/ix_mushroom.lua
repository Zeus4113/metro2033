ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Mushroom"
ENT.Category = "Metro 2033"
ENT.Spawnable = true
ENT.AdminSpawnable = true

if SERVER then
	local MODEL_DOUBLE = "models/devcon/mrp/props/mushroom_1.mdl"
	local MODEL_SINGLE = "models/devcon/mrp/props/mushroom_2.mdl"

	function ENT:Initialize()
		self:SetModel(MODEL_SINGLE)
		-- Use a simple sphere instead of the model's collision mesh: it's much
		-- easier for the player's use-trace to land on and has no janky geometry.
		self:PhysicsInitSphere(2, "flesh")
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		-- Stay solid so the use-trace can find us, but let players walk through
		-- instead of getting stuck.
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end

		self:StartGrowth(self.spawnFullGrown)
	end

	function ENT:StartGrowth(bInstant)
		self.isDouble = math.random(1, 100) <= ix.config.Get("mushroomDoubleChance", 20)
		self:SetModel(self.isDouble and MODEL_DOUBLE or MODEL_SINGLE)

		local baseTime = ix.config.Get("mushroomGrowthTime", 300)
		local variance = ix.config.Get("mushroomGrowthVariance", 20) / 100
		self.growthDuration = baseTime * (1 + math.Remap(math.random(), 0, 1, -variance, variance))

		if bInstant then
			-- Backdate the start so the entity is already fully grown on spawn.
			self.growthStartTime = CurTime() - self.growthDuration
			self.isGrown = true
			self:SetModelScale(1, 0)
		else
			self.growthStartTime = CurTime()
			self.isGrown = false
			self:SetModelScale(0, 0)
		end

		self:SetNWFloat("growthStart", self.growthStartTime)
		self:SetNWFloat("growthDuration", self.growthDuration)
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end

		if not self.isGrown then
			activator:Notify("This mushroom isn't ready yet.")
			return
		end

		local char = activator:GetCharacter()
		if not char then return end

		local inv = char:GetInventory()
		if not inv then return end

		local count = self.isDouble and 2 or 1
		for _ = 1, count do
			if not inv:Add("mushroom") then
				ix.item.Spawn("mushroom", activator:GetPos() + Vector(0, 0, 10))
			end
		end

		self:EmitSound("physics/flesh/flesh_squishy_impact_hard1.wav", 70, math.random(95, 105))
		activator:Notify("You picked " .. (count == 2 and "two mushrooms" or "a mushroom") .. ".")

		self:StartGrowth()
	end

	function ENT:SpawnFunction(client, trace)
		local ent = ents.Create("ix_mushroom")
		ent:SetPos(trace.HitPos)
		ent:SetAngles(Angle(0, (trace.HitPos - client:GetPos()):Angle().y - 180, 0))
		ent.spawnFullGrown = true
		ent:Spawn()
		ent:Activate()
		return ent
	end
end

if CLIENT then
	function ENT:Think()
		local growthStart = self:GetNWFloat("growthStart", 0)
		local growthDuration = self:GetNWFloat("growthDuration", ix.config.Get("mushroomGrowthTime", 300))
		if growthStart <= 0 or growthDuration <= 0 then return end
		local fraction = math.Clamp((CurTime() - growthStart) / growthDuration, 0, 1)
		self:SetModelScale(fraction, 0)
	end

	ENT.PopulateEntityInfo = true

	function ENT:OnPopulateEntityInfo(tooltip)
		local isDouble = self:GetNWBool("isDouble", false)
		local growthStart = self:GetNWFloat("growthStart", 0)
		local growthTime = ix.config.Get("mushroomGrowthTime", 300)
		local fraction = growthStart > 0 and math.Clamp((CurTime() - growthStart) / growthTime, 0, 1) or 0

		local title = tooltip:AddRow("loot")
		title:SetText(isDouble and "Double Mushroom" or "Mushroom")
		title:SetImportant()
		title:SizeToContents()

		local desc = tooltip:AddRow("desc")
		desc:SetText("Cave mushroom commonly farmed in the metro")
		desc:SizeToContents()
	end
end
