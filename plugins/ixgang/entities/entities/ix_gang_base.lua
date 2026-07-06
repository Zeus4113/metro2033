AddCSLuaFile()

ENT.Base      = "base_gmodentity"
ENT.Type      = "anim"
ENT.PrintName = "Gang Hideout Base"
ENT.Category  = "Metro 2033"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:GetHideoutKey()
	return self:GetNWString("hideoutKey", "backroom")
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
		if key == "hideout" then
			local hkey   = string.lower(value)
			local plugin = ix.plugin.Get("ixgang")
			if plugin and plugin:IsValidHideout(hkey) then
				self:SetNWString("hideoutKey", hkey)
			end
		end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		local char = activator:GetCharacter()
		if not char then return end

		local range = ix.config.Get("gangBaseRange", 96)
		if activator:GetPos():DistToSqr(self:GetPos()) > range ^ 2 then return end

		local plugin = ix.plugin.Get("ixgang")
		if not plugin then return end

		-- If the base is held by a group the player isn't part of, deny without a UI.
		local base = plugin:GetBaseData(plugin:GetBaseKey(self))
		if base and base.ownerGroupID and base.upkeepExpires > os.time() then
			local _, groupID = plugin:GetCharGroup(char)
			if base.ownerGroupID ~= groupID then
				activator:Notify("This area is already claimed by another group.")
				return
			end
		end

		plugin:OpenBaseMenu(activator, self)
	end

	function ENT:SpawnFunction(client, trace, className)
		local ent = ents.Create(className)
		ent:SetPos(trace.HitPos)
		ent:SetAngles(Angle(0, (trace.HitPos - client:GetPos()):Angle().y - 180, 0))
		ent:Spawn()
		ent:Activate()
		ent:SetNWString("hideoutKey", "backroom")
		return ent
	end
end

if CLIENT then
	function ENT:OnPopulateEntityInfo(tooltip)
		local plugin = ix.plugin.Get("ixgang")
		local hkey   = self:GetHideoutKey()
		local hname  = plugin and plugin:GetHideoutName(hkey) or "Hideout"

		local title = tooltip:AddRow("ganghideout")
		title:SetText(hname)
		title:SetImportant()
		title:SizeToContents()

		local hint = tooltip:AddRow("hint")
		hint:SetText("A group leader can claim this hideout to grant their members its gang class.")
		hint:SizeToContents()
	end

	ENT.PopulateEntityInfo = true
end

-- ── Admin properties: set the hideout key in-game (persisted on the entity) ────
-- Mirrors the faction board's faction-setter properties. The hideout key is a
-- map/entity property, so it is stored via the networked string and re-read on
-- spawn; persistence across restarts relies on the entity being map-placed or
-- re-set by an admin.

local function addHideoutProperty(hkey, label, order)
	properties.Add("ixGangBaseSet" .. hkey, {
		MenuLabel = "Set Hideout: " .. label,
		Order     = order,
		MenuIcon  = "icon16/house.png",
		Filter = function(_, ent, ply)
			return IsValid(ent) and ent:GetClass() == "ix_gang_base" and ply:IsAdmin()
		end,
		Action = function(self, ent)
			self:MsgStart()
				net.WriteEntity(ent)
				net.WriteString(hkey)
			self:MsgEnd()
		end,
		Receive = function(_, _, ply)
			if not ply:IsAdmin() then return end
			local ent  = net.ReadEntity()
			local key  = net.ReadString()
			if not IsValid(ent) or ent:GetClass() ~= "ix_gang_base" then return end
			local plugin = ix.plugin.Get("ixgang")
			if not plugin or not plugin:IsValidHideout(key) then return end
			ent:SetNWString("hideoutKey", key)
			plugin.baseHideouts[plugin:GetBaseKey(ent)] = key
			plugin:SaveBaseHideouts()
			ply:Notify("Hideout set to " .. plugin:GetHideoutName(key) .. ".")
		end,
	})
end

addHideoutProperty("backroom",   "Backroom",   910)
addHideoutProperty("encampment", "Encampment", 911)
addHideoutProperty("hideout",    "Hideout",    912)
addHideoutProperty("safehouse",  "Safehouse",  913)
addHideoutProperty("station",    "Station",    914)
addHideoutProperty("bunker",     "Bunker",     915)
addHideoutProperty("den",        "Den",        916)
