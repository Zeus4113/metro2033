AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Brewing Barrel"
ENT.Category = "Metro 2033"
ENT.Spawnable = true
ENT.AdminOnly = true

local BREW_SOUND = "ambient/machines/deep_boil.wav"

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/z-o-m-b-i-e/st/workshop_room/st_kanistra_02.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:Wake() end

		self.state = "idle"
		self:SetNWString("brewState", "idle")
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		local char = activator:GetCharacter()
		if not char then return end

		if self.state == "idle" then
			self:TryStartBrewing(activator)
		elseif self.state == "brewing" then
			local remaining = math.max(0, math.ceil(self.brewEndTime - CurTime()))
			activator:Notify("Already brewing. Ready in " .. remaining .. " seconds.")
		elseif self.state == "ready" then
			self:CollectVodka(activator)
		end
	end

	function ENT:TryStartBrewing(client)
		local char = client:GetCharacter()
		local skillReq = ix.plugin.Get("ixmushroom").brewSkillReq
		if ix.skill.Get(char, "chemistry") < skillReq then
			client:Notify("You need Chemistry " .. skillReq .. " to brew. (Current: " .. math.floor(ix.skill.Get(char, "chemistry")) .. ")")
			return
		end

		local inv = char:GetInventory()
		local ingredients = ix.plugin.Get("ixmushroom").brewIngredients

		-- Validate ingredients
		for _, ing in ipairs(ingredients) do
			local found = 0
			for _, item in pairs(inv:GetItems()) do
				if item.uniqueID == ing.id then found = found + 1 end
			end
			if found < ing.count then
				local def = ix.item.Get(ing.id)
				client:Notify("You need " .. ing.count .. "x " .. (def and def.name or ing.id) .. " to brew.")
				return
			end
		end

		-- Consume ingredients
		for _, ing in ipairs(ingredients) do
			local consumed = 0
			for _, item in pairs(inv:GetItems()) do
				if item.uniqueID == ing.id and consumed < ing.count then
					item:Remove()
					consumed = consumed + 1
				end
			end
		end

		local brewTime = ix.config.Get("mushroomBrewingTime", 300)
		self.state = "brewing"
		self.brewEndTime = CurTime() + brewTime
		self:SetNWString("brewState", "brewing")
		self:SetNWFloat("brewEndTime", self.brewEndTime)

		client:Notify("Brewing started. Ready in " .. brewTime .. " seconds.")
		self:EmitSound("ambient/water_splash2.wav", 55, 100)

		-- Schedule completion
		timer.Simple(brewTime, function()
			if not IsValid(self) or self.state ~= "brewing" then return end
			self.state = "ready"
			self:SetNWString("brewState", "ready")
			self:EmitSound("ambient/machines/steam_release_" .. math.random(1, 2) .. ".wav", 75, 100)
		end)
	end

	function ENT:CollectVodka(client)
		local inv = client:GetCharacter():GetInventory()
		for _ = 1, 2 do
			if not inv:Add("mushroom_vodka") then
				ix.item.Spawn("mushroom_vodka", client:GetPos() + Vector(0, 0, 10))
			end
		end
		self:EmitSound("physics/glass/glass_impact_soft1.wav", 75, math.random(90, 100))
		timer.Simple(0.25, function()
			if IsValid(self) then
				self:EmitSound("physics/glass/glass_impact_soft1.wav", 75, math.random(95, 110))
			end
		end)
		client:Notify("You collected 2x mushroom vodka.")
		self.state = "idle"
		self:SetNWString("brewState", "idle")
	end

	function ENT:SpawnFunction(client, trace)
		local ent = ents.Create("ix_brewing_barrel")
		ent:SetPos(trace.HitPos)
		ent:SetAngles(Angle(0, (trace.HitPos - client:GetPos()):Angle().y - 180, 0))
		ent:Spawn()
		ent:Activate()
		return ent
	end
end

if CLIENT then
	function ENT:Think()
		local brewing = self:GetNWString("brewState", "idle") == "brewing"

		if brewing then
			if not self.clientBrewSound then
				self.clientBrewSound = CreateSound(self, BREW_SOUND)
				self.clientBrewSound:SetSoundLevel(60)
				self.clientBrewSound:ChangeVolume(0.35, 0)
				self.clientBrewSound:Play()
			end

			if (self.nextBrewParticle or 0) <= CurTime() then
				self.nextBrewParticle = CurTime() + 0.4
				local pos = self:GetPos() + Vector(0, 0, 25)
				local emitter = ParticleEmitter(pos)
				if emitter then
					for _ = 1, 2 do
						local p = emitter:Add("particle/smokesprites_000" .. math.random(1, 4), pos + VectorRand() * 3)
						if p then
							p:SetVelocity(Vector(math.Rand(-5, 5), math.Rand(-5, 5), math.Rand(15, 30)))
							p:SetLifeTime(0)
							p:SetDieTime(math.Rand(1.5, 2.5))
							p:SetStartAlpha(80)
							p:SetEndAlpha(0)
							p:SetStartSize(math.Rand(3, 6))
							p:SetEndSize(math.Rand(10, 18))
							p:SetColor(220, 220, 220)
							p:SetCollide(false)
						end
					end
					emitter:Finish()
				end
			end
		else
			if self.clientBrewSound then
				self.clientBrewSound:Stop()
				self.clientBrewSound = nil
			end
		end
	end

	function ENT:OnRemove()
		if self.clientBrewSound then
			self.clientBrewSound:Stop()
			self.clientBrewSound = nil
		end
	end

	ENT.PopulateEntityInfo = true

	function ENT:OnPopulateEntityInfo(tooltip)
		local title = tooltip:AddRow("loot")
		title:SetText("Brewing Barrel")
		title:SetImportant()
		title:SizeToContents()

		local plugin = ix.plugin.Get("ixmushroom")
		if plugin then
			local ingString = ""
			for _, ing in ipairs(plugin.brewIngredients) do
				local def = ix.item.list[ing.id]
				local name = def and def.name or ing.id
				if ingString == "" then
					ingString = "Required Ingredients: " .. ing.count .. "x " .. name
				else
					ingString = ingString .. ", " .. ing.count .. "x " .. name
				end
			end
			local tools = tooltip:AddRow("tools")
			tools:SetText(ingString)
			tools:SetBackgroundColor(Color(157, 194, 120))
			tools:SizeToContents()
		end

		local desc = tooltip:AddRow("desc")
		desc:SetText("A barrel used to brew mushroom vodka from organic materials.")
		desc:SizeToContents()
	end
end
