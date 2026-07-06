AddCSLuaFile()

ENT.Base      = "base_gmodentity"
ENT.Type      = "anim"
ENT.PrintName = "Faction Recruitment Board"
ENT.Category  = "Metro 2033"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:GetFactionKey()
	return self:GetNWString("factionKey", "redline")
end

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

	function ENT:KeyValue(key, value)
		if key == "faction" then
			local fkey = string.lower(value)
			if fkey == "hansa" or fkey == "redline" or fkey == "reich" then
				self:SetNWString("factionKey", fkey)
			end
		end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		local char = activator:GetCharacter()
		if not char then return end

		local range = ix.config.Get("factionRepBoardRange", 96)
		if activator:GetPos():DistToSqr(self:GetPos()) > range ^ 2 then return end

		local plugin = ix.plugin.Get("ixfactionrep")
		if not plugin then return end

		local fkey = self:GetFactionKey()

		-- Block members of opposing factions
		for oppKey, oppMeta in pairs(plugin.factionMeta) do
			if oppKey ~= fkey and char:GetFaction() == oppMeta.faction() then
				activator:Notify("You cannot use this board as a member of the " .. oppMeta.name .. ".")
				return
			end
		end

		-- Block non-members from accepting contracts at cap
		-- (handled inside ixFactionRepAccept on server — just open the board)

		activator.ixFactionRepEnt = self
		plugin:OpenBoard(activator, self)
	end

	function ENT:OnRemove()
		local plugin = ix.plugin.Get("ixfactionrep")
		for _, ply in ipairs(player.GetAll()) do
			if ply.ixFactionRepEnt == self then
				if plugin then
					plugin:CloseBoard(ply)
				else
					ply.ixFactionRepEnt = nil
				end
			end
		end
	end

	function ENT:SpawnFunction(client, trace, className)
		local ent = ents.Create(className)
		ent:SetPos(trace.HitPos)
		ent:SetAngles(Angle(0, (trace.HitPos - client:GetPos()):Angle().y - 180, 0))
		ent:Spawn()
		ent:Activate()
		ent:SetNWString("factionKey", "redline")
		return ent
	end
end

if CLIENT then
	function ENT:OnPopulateEntityInfo(tooltip)
		local fkey = self:GetFactionKey()
		local names = { redline = "Red Line", hansa = "Hanseatic League", reich = "Fourth Reich" }
		local title = tooltip:AddRow("factionboard")
		title:SetText((names[fkey] or "Faction") .. " Recruitment Board")
		title:SetImportant()
		title:SizeToContents()

		local hint = tooltip:AddRow("hint")
		hint:SetText("Complete contracts to earn faction reputation, unlock ranks, or transfer allegiance.")
		hint:SizeToContents()
	end

	ENT.PopulateEntityInfo = true
end

-- Admin properties to set faction key in-game (persisted via boardFactionData)
properties.Add("ixFactionBoardSetRedLine", {
	MenuLabel = "Set Faction: Red Line",
	Order     = 900,
	MenuIcon  = "icon16/group.png",
	Filter = function(_, ent, ply)
		return IsValid(ent) and ent:GetClass() == "ix_faction_board" and ply:IsAdmin()
	end,
	Action = function(self, ent)
		self:MsgStart()
			net.WriteEntity(ent)
		self:MsgEnd()
	end,
	Receive = function(_, _, ply)
		if not ply:IsAdmin() then return end
		local ent = net.ReadEntity()
		if not IsValid(ent) or ent:GetClass() ~= "ix_faction_board" then return end
		ent:SetNWString("factionKey", "redline")
		local plugin = ix.plugin.Get("ixfactionrep")
		if plugin then
			plugin.boardFactionData[plugin:GetBoardKey(ent)] = "redline"
			plugin:SaveBoardFactionData()
		end
		ply:Notify("Faction board switched to Red Line.")
	end,
})

properties.Add("ixFactionBoardSetHansa", {
	MenuLabel = "Set Faction: Hanseatic League",
	Order     = 901,
	MenuIcon  = "icon16/group.png",
	Filter = function(_, ent, ply)
		return IsValid(ent) and ent:GetClass() == "ix_faction_board" and ply:IsAdmin()
	end,
	Action = function(self, ent)
		self:MsgStart()
			net.WriteEntity(ent)
		self:MsgEnd()
	end,
	Receive = function(_, _, ply)
		if not ply:IsAdmin() then return end
		local ent = net.ReadEntity()
		if not IsValid(ent) or ent:GetClass() ~= "ix_faction_board" then return end
		ent:SetNWString("factionKey", "hansa")
		local plugin = ix.plugin.Get("ixfactionrep")
		if plugin then
			plugin.boardFactionData[plugin:GetBoardKey(ent)] = "hansa"
			plugin:SaveBoardFactionData()
		end
		ply:Notify("Faction board switched to Hanseatic League.")
	end,
})

properties.Add("ixFactionBoardSetReich", {
	MenuLabel = "Set Faction: Fourth Reich",
	Order     = 902,
	MenuIcon  = "icon16/group.png",
	Filter = function(_, ent, ply)
		return IsValid(ent) and ent:GetClass() == "ix_faction_board" and ply:IsAdmin()
	end,
	Action = function(self, ent)
		self:MsgStart()
			net.WriteEntity(ent)
		self:MsgEnd()
	end,
	Receive = function(_, _, ply)
		if not ply:IsAdmin() then return end
		local ent = net.ReadEntity()
		if not IsValid(ent) or ent:GetClass() ~= "ix_faction_board" then return end
		ent:SetNWString("factionKey", "reich")
		local plugin = ix.plugin.Get("ixfactionrep")
		if plugin then
			plugin.boardFactionData[plugin:GetBoardKey(ent)] = "reich"
			plugin:SaveBoardFactionData()
		end
		ply:Notify("Faction board switched to Fourth Reich.")
	end,
})
