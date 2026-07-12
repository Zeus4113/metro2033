local PLUGIN = PLUGIN

PLUGIN.name        = "Groups & Gangs"
PLUGIN.author      = "metro2033"
PLUGIN.description = "Player-run groups that claim hideout bases to grant their members a gang class."

-- ── Config ────────────────────────────────────────────────────────────────────

ix.config.Add("gangClaimCost",           250,   "Currency cost to claim a hideout base.", nil, {
	data = { min = 0, max = 100000 }, category = PLUGIN.name,
})
ix.config.Add("gangUpkeepCost",          100,   "Currency cost per upkeep payment.", nil, {
	data = { min = 0, max = 100000 }, category = PLUGIN.name,
})
ix.config.Add("gangUpkeepDuration",      86400, "Seconds of ownership a single upkeep payment buys.", nil, {
	data = { min = 60, max = 1209600 }, category = PLUGIN.name,
})
ix.config.Add("gangUpkeepMax",           259200, "Maximum stockpiled upkeep time (seconds). Default 3 days.", nil, {
	data = { min = 3600, max = 2592000 }, category = PLUGIN.name,
})
ix.config.Add("gangUpkeepCheckInterval", 60,    "Seconds between upkeep expiry checks.", nil, {
	data = { min = 10, max = 3600 }, category = PLUGIN.name,
})
ix.config.Add("gangBaseRange",           96,    "Interaction radius for hideout bases (units).", nil, {
	data = { min = 32, max = 256 }, category = PLUGIN.name,
})
ix.config.Add("gangMaxMembers",          8,     "Maximum members per group.", nil, {
	data = { min = 2, max = 64 }, category = PLUGIN.name,
})
ix.config.Add("gangMinClaimMembers",     2,     "Minimum group members required to claim a hideout.", nil, {
	data = { min = 1, max = 64 }, category = PLUGIN.name,
})

-- ── Hideout → class map ───────────────────────────────────────────────────────
--
-- Class index globals (CLASS_BACKROOM, …) are defined when the schema's class
-- files load, so they're resolved lazily through a function, mirroring the
-- faction plugin's factionMeta pattern.

PLUGIN.hideouts = {
	backroom   = { name = "Backroom",           class = function() return CLASS_BACKROOM end },
	encampment = { name = "Encampment",         class = function() return CLASS_ENCAMPMENT end },
	hideout    = { name = "Hideout",            class = function() return CLASS_HIDEOUT end },
	safehouse  = { name = "Safehouse",          class = function() return CLASS_SAFEHOUSE end },
	barracks   = { name = "Barracks",           class = function() return CLASS_BARRACKS end },
	bunker     = { name = "Bunker",             class = function() return CLASS_BUNKER end },
	den        = { name = "Den",                class = function() return CLASS_DEN end },
}

function PLUGIN:IsValidHideout(key)
	return self.hideouts[key] ~= nil
end

function PLUGIN:GetHideoutName(key)
	local h = self.hideouts[key]
	return h and h.name or "Hideout"
end

function PLUGIN:GetHideoutClass(key)
	local h = self.hideouts[key]
	return h and h.class() or nil
end

-- ── Network strings & includes ────────────────────────────────────────────────

if SERVER then
	util.AddNetworkString("ixGangCreate")
	util.AddNetworkString("ixGangDisband")
	util.AddNetworkString("ixGangInvite")
	util.AddNetworkString("ixGangInvitePrompt")
	util.AddNetworkString("ixGangInviteResponse")
	util.AddNetworkString("ixGangKick")
	util.AddNetworkString("ixGangLeave")
	util.AddNetworkString("ixGangSetSuccessor")
	util.AddNetworkString("ixGangSync")
	util.AddNetworkString("ixGangRequestSync")
	util.AddNetworkString("ixGangBaseOpen")
	util.AddNetworkString("ixGangBaseClaim")
	util.AddNetworkString("ixGangBaseUpkeep")
	util.AddNetworkString("ixGangBaseAbandon")

	ix.util.Include("sv_plugin.lua")
end

if CLIENT then
	ix.util.Include("derma/cl_gang_tab.lua")
	ix.util.Include("derma/cl_gang_base.lua")
end
