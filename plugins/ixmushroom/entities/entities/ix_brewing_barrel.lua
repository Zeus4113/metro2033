AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Brewing Barrel"
ENT.Category = "Metro 2033"
ENT.Spawnable = true
ENT.AdminOnly = true

local BREW_SOUND = "ambient/water/water_flow_below2.wav"

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/z-o-m-b-i-e/st/workshop_room/st_kanistra_02.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end

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
		if char:GetAttribute("chemistry") < skillReq then
			client:Notify("You need Chemistry " .. skillReq .. " to brew. (Current: " .. char:GetAttribute("chemistry") .. ")")
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

		-- Start looping sound
		self.brewSound = CreateSound(self, BREW_SOUND)
		self.brewSound:SetSoundLevel(70)
		self.brewSound:Play()

		-- Schedule completion
		timer.Simple(brewTime, function()
			if not IsValid(self) or self.state ~= "brewing" then return end
			self.state = "ready"
			self:SetNWString("brewState", "ready")
			self.brewSound:Stop()
			self.brewSound = nil
			self:EmitSound("buttons/button14.wav", 75, 100)
		end)
	end

	function ENT:CollectVodka(client)
		local inv = client:GetCharacter():GetInventory()
		for _ = 1, 3 do
			if not inv:Add("mushroom_vodka") then
				ix.item.Spawn("mushroom_vodka", client:GetPos() + Vector(0, 0, 10))
			end
		end
		client:Notify("You collected 3x mushroom vodka.")
		self.state = "idle"
		self:SetNWString("brewState", "idle")
	end

	function ENT:OnRemove()
		if self.brewSound then
			self.brewSound:Stop()
			self.brewSound = nil
		end
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

		local brewState = self:GetNWString("brewState", "idle")
		local descText
		if brewState == "brewing" then
			local remaining = math.max(0, math.ceil(self:GetNWFloat("brewEndTime", 0) - CurTime()))
			descText = "A barrel used to brew mushroom vodka from organic materials. Brewing in progress — " .. remaining .. "s remaining."
		elseif brewState == "ready" then
			descText = "A barrel used to brew mushroom vodka from organic materials. Brewing complete — press [E] to collect your vodka."
		else
			descText = "A barrel used to brew mushroom vodka from organic materials. Press [E] to begin brewing."
		end
		local desc = tooltip:AddRow("desc")
		desc:SetText(descText)
		desc:SizeToContents()
	end
end
