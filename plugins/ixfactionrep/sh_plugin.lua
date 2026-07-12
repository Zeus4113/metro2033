local PLUGIN = PLUGIN

PLUGIN.name        = "Faction Reputation"
PLUGIN.author      = "metro2033"
PLUGIN.description = "Faction contract boards, class whitelists, rep-gated vendors, and bounties."

-- ── Core settings ─────────────────────────────────────────────────────────────

ix.config.Add("factionRepContractCount",      3,    "Contracts offered per faction per day.", nil, {
	data = { min = 1, max = 10 }, category = PLUGIN.name,
})
ix.config.Add("factionRepBoardRange",         96,   "Interaction radius (units).", nil, {
	data = { min = 32, max = 256 }, category = PLUGIN.name,
})
ix.config.Add("factionRepDecayInterval",      3600, "Seconds between reputation decay ticks.", nil, {
	data = { min = 60, max = 86400 }, category = PLUGIN.name,
})
ix.config.Add("factionRepDecayAmount",        2,    "Reputation lost/gained per decay tick (toward 0).", nil, {
	data = { min = 0, max = 20 }, category = PLUGIN.name,
})
ix.config.Add("factionRepKillPenalty",        10,   "Reputation lost for killing a faction member.", nil, {
	data = { min = 0, max = 50 }, category = PLUGIN.name,
})

-- ── Rep thresholds ─────────────────────────────────────────────────────────────

ix.config.Add("factionRepTransferThreshold",  40,   "Minimum rep to enlist in a faction (Rookie rank).", nil, {
	data = { min = 1, max = 100 }, category = PLUGIN.name,
})
ix.config.Add("factionRepRegularThreshold",   60,   "Minimum rep to be force-set to the Regular rank.", nil, {
	data = { min = 1, max = 100 }, category = PLUGIN.name,
})
ix.config.Add("factionRepVeteranThreshold",   80,   "Minimum rep to be force-set to the Veteran rank.", nil, {
	data = { min = 1, max = 100 }, category = PLUGIN.name,
})

-- ── Bounties ──────────────────────────────────────────────────────────────────

ix.config.Add("factionRepBountyThreshold",   -50,   "Rep at which a player becomes a bounty target.", nil, {
	data = { min = -100, max = -1 }, category = PLUGIN.name,
})
ix.config.Add("factionRepBountyReward",       20,   "Rep awarded for claiming a bounty.", nil, {
	data = { min = 1, max = 100 }, category = PLUGIN.name,
})

-- ── Roster caps ───────────────────────────────────────────────────────────────

ix.config.Add("factionCapRedline",    0, "Max Red Line members (0 = disabled).", nil, {
	data = { min = 0, max = 200 }, category = PLUGIN.name,
})
ix.config.Add("factionCapHansa",      0, "Max Hansa members (0 = disabled).", nil, {
	data = { min = 0, max = 200 }, category = PLUGIN.name,
})
ix.config.Add("factionCapReich",      0, "Max Fourth Reich members (0 = disabled).", nil, {
	data = { min = 0, max = 200 }, category = PLUGIN.name,
})

-- ── Faction metadata ──────────────────────────────────────────────────────────

PLUGIN.factionMeta = {
	redline = {
		faction  = function() return FACTION_REDLINE end,
		rookie   = function() return CLASS_REDLINE_ROOKIE end,
		regular  = function() return CLASS_REDLINE_REGULAR end,
		veteran  = function() return CLASS_REDLINE_VETERAN end,
		sergeant = function() return CLASS_REDLINE_SERGEANT end,
		officer  = function() return CLASS_REDLINE_OFFICER end,
		name      = "Red Line",
		capConfig = "factionCapRedline",
	},
	hansa = {
		faction  = function() return FACTION_HANSA end,
		rookie   = function() return CLASS_HANSA_ROOKIE end,
		regular  = function() return CLASS_HANSA_REGULAR end,
		veteran  = function() return CLASS_HANSA_VETERAN end,
		sergeant = function() return CLASS_HANSA_SERGEANT end,
		officer  = function() return CLASS_HANSA_OFFICER end,
		name      = "Hanseatic League",
		capConfig = "factionCapHansa",
	},
	reich = {
		faction  = function() return FACTION_FOURTH_REICH end,
		rookie   = function() return CLASS_REICH_ROOKIE end,
		regular  = function() return CLASS_REICH_REGULAR end,
		veteran  = function() return CLASS_REICH_VETERAN end,
		sergeant = function() return CLASS_REICH_SERGEANT end,
		officer  = function() return CLASS_REICH_OFFICER end,
		name      = "Fourth Reich",
		capConfig = "factionCapReich",
	},
}

-- Rank order, lowest → highest. Rookie is the faction default; Sergeant/Officer
-- are admin-whitelist-only. All are force-set (see GetFactionForcedClass).
PLUGIN.rankOrder = { "rookie", "regular", "veteran", "sergeant", "officer" }

-- ── Contract pools ────────────────────────────────────────────────────────────
--
-- Hansa   — Medical supplies, equipment (helmets/vests/backpacks), outfits
-- Redline — Weapons and ammo only
-- Reich   — Killing mutants only
--
-- All collect targets are crafted item outputs, not raw materials.

PLUGIN.contractPools = {

	hansa = {
		-- Medical supplies
		{ id = "hn_col_medkit",           type = "collect", target = "medkit",               count = 1, reward = 12, name = "Medical Priority",      desc = "Deliver a medkit to the Hansa field clinic." },
		{ id = "hn_col_first_aid",        type = "collect", target = "first_aid_kit",        count = 2, reward = 9,  name = "Aid Kit Stockpile",     desc = "Deliver %d first aid kits to the Ring Line hospital." },
		{ id = "hn_col_green_stuff",      type = "collect", target = "green_stuff",          count = 2, reward = 8,  name = "Stimulant Supply",      desc = "Deliver %d doses of green stuff to the medical store." },
		{ id = "hn_col_herbal",           type = "collect", target = "herbal_remedy",        count = 3, reward = 7,  name = "Herbal Stores",         desc = "Supply %d herbal remedies to the apothecary." },
		{ id = "hn_col_antirad",          type = "collect", target = "anti_radiation_pills", count = 3, reward = 8,  name = "Radiation Treatment",   desc = "Deliver %d anti-radiation pills to the Hansa medical unit." },
		{ id = "hn_col_bandage",          type = "collect", target = "bandage",              count = 4, reward = 6,  name = "Bandage Order",         desc = "Supply %d bandages to the Ring Line aid post." },
		-- Equipment — helmets, vests, backpacks
		{ id = "hn_col_helm_gasmask",     type = "collect", target = "helmet_gasmask",       count = 1, reward = 9,  name = "Gasmask Requisition",   desc = "Deliver a gasmask to the Hansa tunnel patrol." },
		{ id = "hn_col_helm_reinforced",  type = "collect", target = "helmet_reinforced",    count = 1, reward = 9,  name = "Reinforced Helmet",     desc = "Supply a reinforced helmet to the Ring Line garrison." },
		{ id = "hn_col_vest_carrier",     type = "collect", target = "vest_carrier_rig",     count = 1, reward = 10, name = "Carrier Rig Contract",  desc = "Deliver a carrier rig vest to the Hansa armoury." },
		{ id = "hn_col_vest_reinforced",  type = "collect", target = "vest_reinforced",      count = 1, reward = 10, name = "Reinforced Vest Order", desc = "Supply a reinforced vest to the Hansa guard corps." },
		{ id = "hn_col_pack_merchants",   type = "collect", target = "backpack_merchants",   count = 1, reward = 9,  name = "Merchant's Pack",       desc = "Deliver a merchant's backpack to the Ring Line depot." },
		{ id = "hn_col_pack_scavengers",  type = "collect", target = "backpack_scavengers",  count = 1, reward = 8,  name = "Scavenger's Pouch",     desc = "Supply a scavenger's pouch to the Hansa supply corps." },
		-- Outfits
		{ id = "hn_col_outfit_hunter",    type = "collect", target = "outfit_hunter",        count = 1, reward = 9,  name = "Hunter's Kit",          desc = "Supply a crafted hunter outfit to the Hansa quartermaster." },
		{ id = "hn_col_outfit_merchant",  type = "collect", target = "outfit_merchant",      count = 1, reward = 8,  name = "Merchant Attire",       desc = "Deliver a merchant outfit for the Ring Line trade delegation." },
		{ id = "hn_col_outfit_contractor",type = "collect", target = "outfit_contractor",    count = 1, reward = 8,  name = "Contractor Uniform",    desc = "Supply a contractor outfit to the Hansa labour corps." },
		{ id = "hn_col_outfit_recon",     type = "collect", target = "outfit_recon",         count = 1, reward = 10, name = "Recon Gear",            desc = "Deliver a recon outfit to the Hansa scouting division." },
		{ id = "hn_col_outfit_stalker",   type = "collect", target = "outfit_stalker",       count = 1, reward = 9,  name = "Stalker Outfit",        desc = "Supply a stalker outfit to the Hansa forward post." },
	},

	redline = {
		-- Crafted weapons
		{ id = "rl_col_kalash",      type = "collect", target = "kalash",      count = 1,  reward = 12, name = "Kalash Requisition", desc = "Deliver a crafted Kalash rifle to the Red Line armoury." },
		{ id = "rl_col_bastard",     type = "collect", target = "bastard",     count = 1,  reward = 11, name = "Bastard Delivery",   desc = "Supply a crafted Bastard SMG to the weapons depot." },
		{ id = "rl_col_revolver",    type = "collect", target = "revolver",    count = 1,  reward = 9,  name = "Sidearm Contract",   desc = "Deliver a crafted revolver to the Red Line officer corps." },
		{ id = "rl_col_duplet",      type = "collect", target = "duplet",      count = 1,  reward = 8,  name = "Shotgun Supply",     desc = "Supply a crafted Duplet to the tunnel guard post." },
		{ id = "rl_col_tikhar",      type = "collect", target = "tikhar",      count = 1,  reward = 13, name = "Tikhar Acquisition", desc = "Deliver a crafted Tikhar pneumatic rifle to command." },
		{ id = "rl_col_helsing",     type = "collect", target = "helsing",     count = 1,  reward = 12, name = "Helsing Contract",   desc = "Supply a crafted Helsing to the special operations unit." },
		{ id = "rl_col_vsk",         type = "collect", target = "vsk94",       count = 1,  reward = 14, name = "VSK-94 Priority",    desc = "Deliver a crafted VSK-94 to Red Line command." },
		-- Ammunition
		{ id = "rl_col_rifle_ammo",  type = "collect", target = "rifle_ammo",  count = 15, reward = 7,  name = "Rifle Ammunition",   desc = "Supply %d rifle rounds to the Red Line depot." },
		{ id = "rl_col_pistol_ammo", type = "collect", target = "pistol_ammo", count = 20, reward = 6,  name = "Pistol Ammunition",  desc = "Deliver %d pistol rounds to the armoury." },
		{ id = "rl_col_shotgun_ammo",type = "collect", target = "shotgun_ammo",count = 12, reward = 6,  name = "Shotgun Shells",     desc = "Supply %d shotgun shells to the tunnel garrison." },
		{ id = "rl_col_magnum_ammo", type = "collect", target = "magnum_ammo", count = 10, reward = 8,  name = "Magnum Rounds",      desc = "Deliver %d magnum rounds to the Red Line sniper corps." },
	},

	reich = {
		-- Mutant kills only — higher counts and rewards than other factions
		{ id = "rh_kill_nosach",  type = "kill", target = "npc_nosach_samec",      count = 8,  reward = 8,  name = "Nosalis Purge",      desc = "Exterminate %d Nosalises in the outer zones." },
		{ id = "rh_kill_churzik", type = "kill", target = "npc_churzik",           count = 10, reward = 7,  name = "Lurker Eradication", desc = "Hunt down %d Lurkers encroaching on Reich territory." },
		{ id = "rh_kill_murzik",  type = "kill", target = "npc_murzik",            count = 6,  reward = 10, name = "Watchmen Sanctioned",desc = "Eliminate %d Watchmen on the Reich perimeter." },
		{ id = "rh_kill_biblio",  type = "kill", target = "npc_bibliotekar_redux", count = 2,  reward = 14, name = "Librarian Cull",     desc = "Neutralise %d Librarians in the dead zones." },
		{ id = "rh_kill_demon",   type = "kill", target = "npc_krisomutant",       count = 1,  reward = 18, name = "Demon Slain",        desc = "Bring down a Demon — a test of true Reich mettle." },
	},
}

-- ── Daily contract selection ──────────────────────────────────────────────────

-- Unique seeding offsets so each faction draws a different selection each day.
local FACTION_OFFSETS = { redline = 0, hansa = 999983, reich = 1999967 }

function PLUGIN:GetDailyContracts(factionKey)
	local pool = self.contractPools[factionKey]
	if not pool then return {} end

	local fOffset = FACTION_OFFSETS[factionKey] or 0
	local dateKey = tonumber(os.date("%Y%m%d")) + (self.refreshSeed or 0) * 100003 + fOffset
	local count   = ix.config.Get("factionRepContractCount", 3)

	local selected, used = {}, {}
	local state = dateKey

	while #selected < math.min(count, #pool) do
		state = (state * 1664525 + 1013904223) % (2 ^ 32)
		local idx = (state % #pool) + 1
		if not used[idx] then
			used[idx] = true
			selected[#selected + 1] = table.Copy(pool[idx])
		end
	end
	return selected
end

-- ── Admin commands (shared so the client registers them for chat auto-complete) ─

ix.command.Add("FactionRepSet", {
	description = "Set a player's faction reputation. Args: playerName, redline|hansa|reich, value.",
	adminOnly   = true,
	arguments   = { ix.type.string, ix.type.string, ix.type.number },
	OnRun = function(_, client, targetName, fkey, amount)
		local target = ix.util.FindPlayer(targetName)
		if not target then client:Notify("Player not found.") return end
		local char = target:GetCharacter()
		if not char then client:Notify("Target has no character loaded.") return end
		if not PLUGIN.factionMeta[fkey] then
			client:Notify("Invalid faction key. Use 'redline', 'hansa', or 'reich'.")
			return
		end
		PLUGIN:SetRep(char, fkey, math.Clamp(amount, -100, 100))
		char:Save()
		client:Notify("Set " .. target:Name() .. "'s " .. fkey .. " rep to " .. PLUGIN:GetRep(char, fkey) .. ".")
		target:Notify("An admin has adjusted your faction reputation.")
	end,
})

ix.command.Add("FactionRepGet", {
	description = "View a player's current faction reputation. Args: playerName.",
	adminOnly   = true,
	arguments   = { ix.type.string },
	OnRun = function(_, client, targetName)
		local target = ix.util.FindPlayer(targetName)
		if not target then client:Notify("Player not found.") return end
		local char = target:GetCharacter()
		if not char then client:Notify("Target has no character loaded.") return end
		local rl = PLUGIN:GetRep(char, "redline")
		local hn = PLUGIN:GetRep(char, "hansa")
		local rc = PLUGIN:GetRep(char, "reich")
		client:Notify(target:Name() .. " — Red Line: " .. rl .. " | Hansa: " .. hn .. " | Reich: " .. rc)
	end,
})

ix.command.Add("FactionRepRefresh", {
	description = "Force-refresh faction rep contracts and reset shared claim state.",
	adminOnly   = true,
	OnRun = function(_, client)
		PLUGIN.refreshSeed = PLUGIN.refreshSeed + 1
		file.Write("ix/factionrep_refresh_seed.txt", tostring(PLUGIN.refreshSeed))
		PLUGIN.sharedContracts = {}
		PLUGIN:SaveSharedContracts()
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply.ixFactionRepEnt) then PLUGIN:CloseBoard(ply) end
		end
		client:Notify("Faction rep boards refreshed.")
	end,
})

ix.command.Add("FactionRepRosterSync", {
	description = "Rebuild faction membership roster from all online players' live state.",
	adminOnly   = true,
	OnRun = function(_, client)
		local synced = 0
		for _, ply in ipairs(player.GetAll()) do
			local char = ply:GetCharacter()
			if not char then continue end
			local steamID = ply:SteamID()
			for _, fkey in ipairs({ "redline", "hansa", "reich" }) do
				local meta = PLUGIN.factionMeta[fkey]
				if not meta then continue end
				local inFaction = char:GetFaction() == meta.faction()
				local inRoster  = PLUGIN.factionRoster[fkey] and PLUGIN.factionRoster[fkey][steamID]
				if inFaction and not inRoster then
					PLUGIN:AddToFactionRoster(fkey, steamID)
				elseif not inFaction and inRoster then
					PLUGIN:RemoveFromFactionRoster(fkey, steamID)
				end
			end
			synced = synced + 1
		end
		client:Notify("Roster synced for " .. synced .. " online player(s).")
	end,
})

-- ── Network strings & includes ────────────────────────────────────────────────

if SERVER then
	util.AddNetworkString("ixFactionRepOpen")
	util.AddNetworkString("ixFactionRepClose")
	util.AddNetworkString("ixFactionRepAccept")
	util.AddNetworkString("ixFactionRepUnclaim")
	util.AddNetworkString("ixFactionRepClaim")
	util.AddNetworkString("ixFactionRepStateUpdate")
	util.AddNetworkString("ixFactionRepTransfer")
	util.AddNetworkString("ixFactionRepLeave")
	util.AddNetworkString("ixFactionRepVendorSet")
	util.AddNetworkString("ixFactionRepBountyAccept")
	util.AddNetworkString("ixFactionRepBountyClaim")

	ix.util.Include("sv_plugin.lua")
end

if CLIENT then
	ix.util.Include("derma/cl_factionboard.lua")
	ix.util.Include("derma/cl_vendoreditor_ext.lua")
end
