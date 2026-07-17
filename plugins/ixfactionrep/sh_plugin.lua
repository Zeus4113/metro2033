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
ix.config.Add("factionCapPolis",      0, "Max Rangers of the Order members (0 = disabled).", nil, {
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
	-- Rangers of the Order (Polis). Joinable, but has no rank classes/outfits, so
	-- the rookie…officer entries are intentionally absent. Rank-class logic must
	-- guard on `meta.rookie` before calling any rank accessor for this faction;
	-- its "rank" is derived from reputation instead (see GetFactionRankLevel).
	polis = {
		faction  = function() return FACTION_POLIS end,
		name      = "Rangers of the Order",
		capConfig = "factionCapPolis",
	},
}

-- Rank order, lowest → highest. Rookie is the faction default; Sergeant/Officer
-- are admin-whitelist-only. All are force-set (see GetFactionForcedClass).
PLUGIN.rankOrder = { "rookie", "regular", "veteran", "sergeant", "officer" }

-- ── Contract pools ────────────────────────────────────────────────────────────
--
-- Redline — Engineering: mechanical parts, weapon components, weapons, ammo
-- Hansa   — Tailoring: leather, cloth, equipment components, outfits, vests,
--           helmets, backpacks
-- Reich   — Killing mutants only
--
-- Collect targets are crafted/salvaged item outputs, not chemical raw materials.

-- Each contract carries a `tier` (1–3). A player is offered contracts from the
-- tier their faction rank unlocks (see GetUnlockedTier / GetFactionRankLevel):
--   Tier 1 — non-members & rookies    (basic materials / low mutant culls)
--   Tier 2 — regulars                 (intermediate goods, small bullet payouts)
--   Tier 3 — veterans and above       (flagship crafted goods / advanced mutants)
-- `money` (optional) is a bullet payout granted on completion in addition to rep.
PLUGIN.contractPools = {

	hansa = {
		-- Tier 1 — tailoring materials
		{ id = "hn_leather",       tier = 1, type = "collect", target = "leather",           count = 4, reward = 6,  name = "Tanned Hides",       desc = "Supply %d leather to the Hansa tailors." },
		{ id = "hn_cloth",         tier = 1, type = "collect", target = "cloth",             count = 5, reward = 6,  name = "Textile Order",      desc = "Deliver %d cloth to the Ring Line garment works." },
		{ id = "hn_textile_patch", tier = 1, type = "collect", target = "textile_patch",     count = 3, reward = 7,  name = "Ballistic Fibre",    desc = "Supply %d textile patches to the Hansa armour shop." },
		-- Tier 2 — finished equipment
		{ id = "hn_helm_reinforced", tier = 2, type = "collect", target = "helmet_reinforced", count = 1, reward = 9,  money = 20, name = "Reinforced Helmet",  desc = "Supply a reinforced helmet to the Ring Line garrison." },
		{ id = "hn_vest_carrier",    tier = 2, type = "collect", target = "vest_carrier_rig",  count = 1, reward = 10, money = 25, name = "Carrier Rig Order",  desc = "Deliver a carrier rig vest to the Hansa armoury." },
		{ id = "hn_pack_merchants",  tier = 2, type = "collect", target = "backpack_merchants", count = 1, reward = 9,  money = 20, name = "Merchant's Pack",    desc = "Deliver a merchant's backpack to the Ring Line depot." },
		{ id = "hn_outfit_recon",    tier = 2, type = "collect", target = "outfit_recon",       count = 1, reward = 10, money = 25, name = "Recon Gear",         desc = "Deliver a recon outfit to the Hansa scouting division." },
		-- Tier 3 — one-off advanced goods (bullets + reputation)
		{ id = "hn_kalash",          tier = 3, type = "collect", target = "kalash",         count = 1, reward = 15, money = 120, name = "Kalash Requisition", desc = "Deliver a crafted Kalash rifle to Hansa command." },
		{ id = "hn_vsk",             tier = 3, type = "collect", target = "vsk94",          count = 1, reward = 16, money = 140, name = "VSK-94 Priority",    desc = "Supply a crafted VSK-94 to the Ring Line marksmen." },
		{ id = "hn_outfit_stalker",  tier = 3, type = "collect", target = "outfit_stalker", count = 1, reward = 14, money = 100, name = "Stalker Outfit",     desc = "Supply a crafted stalker outfit to the Hansa forward post." },
		{ id = "hn_vest_ranger",     tier = 3, type = "collect", target = "vest_ranger",    count = 1, reward = 15, money = 120, name = "Ranger Vest",        desc = "Deliver a crafted ranger vest to the Hansa armoury." },
		{ id = "hn_helmet_ranger",   tier = 3, type = "collect", target = "helmet_ranger",  count = 1, reward = 14, money = 100, name = "Ranger Helmet",      desc = "Supply a crafted ranger helmet to the Ring Line garrison." },
		{ id = "hn_outfit_operator", tier = 3, type = "collect", target = "outfit_operator",count = 1, reward = 15, money = 120, name = "Operator Outfit",    desc = "Deliver a crafted operator outfit to Hansa command." },
	},

	redline = {
		-- Tier 1 — salvage & basic ammo
		{ id = "rl_mech_parts",  tier = 1, type = "collect", target = "mechanical_parts", count = 4, reward = 6, name = "Machine Salvage",    desc = "Deliver %d mechanical parts to the Red Line workshop." },
		{ id = "rl_spring",      tier = 1, type = "collect", target = "metal_spring",     count = 3, reward = 6, name = "Spring Requisition", desc = "Supply %d metal springs to the Red Line armourers." },
		{ id = "rl_pistol_ammo", tier = 1, type = "collect", target = "pistol_ammo",     count = 4, reward = 6, name = "Pistol Ammunition",  desc = "Deliver %d boxes of pistol ammo to the armoury." },
		-- Tier 2 — components & standard ammo
		{ id = "rl_gauge",      tier = 2, type = "collect", target = "pressure_gauge", count = 2, reward = 9,  money = 20, name = "Pressure Systems",  desc = "Deliver %d pressure gauges to the pneumatics bench." },
		{ id = "rl_rifle_ammo", tier = 2, type = "collect", target = "rifle_ammo",     count = 4, reward = 8,  money = 25, name = "Rifle Ammunition",  desc = "Supply %d boxes of rifle ammo to the Red Line depot." },
		{ id = "rl_revolver",   tier = 2, type = "collect", target = "revolver",       count = 1, reward = 10, money = 30, name = "Sidearm Contract",  desc = "Deliver a crafted revolver to the Red Line officer corps." },
		-- Tier 3 — bulk weapons & ammunition (bullets + reputation)
		{ id = "rl_bastard_bulk",     tier = 3, type = "collect", target = "bastard",     count = 2, reward = 16, money = 120, name = "Bastard Batch",        desc = "Supply %d crafted Bastard SMGs to the weapons depot." },
		{ id = "rl_duplet_bulk",      tier = 3, type = "collect", target = "duplet",      count = 2, reward = 15, money = 100, name = "Duplet Batch",         desc = "Deliver %d crafted Duplets to the tunnel guard post." },
		{ id = "rl_revolver_bulk",    tier = 3, type = "collect", target = "revolver",    count = 3, reward = 15, money = 110, name = "Revolver Consignment", desc = "Deliver %d crafted revolvers to the Red Line officer corps." },
		{ id = "rl_rifle_ammo_bulk",  tier = 3, type = "collect", target = "rifle_ammo",  count = 8, reward = 12, money = 90,  name = "Bulk Rifle Rounds",    desc = "Supply %d boxes of rifle ammo to the Red Line front." },
		{ id = "rl_magnum_ammo_bulk", tier = 3, type = "collect", target = "magnum_ammo", count = 6, reward = 12, money = 90,  name = "Bulk Magnum Rounds",   desc = "Deliver %d boxes of magnum ammo to the Red Line sniper corps." },
		{ id = "rl_shotgun_ammo_bulk",tier = 3, type = "collect", target = "shotgun_ammo",count = 8, reward = 12, money = 80,  name = "Bulk Shotgun Shells",  desc = "Supply %d boxes of shotgun ammo to the tunnel garrison." },
	},

	reich = {
		-- Tier 1 — common mutants
		{ id = "rh_churzik", tier = 1, type = "kill", target = "npc_churzik",      count = 10, reward = 7, name = "Lurker Eradication", desc = "Hunt down %d Lurkers encroaching on Reich territory." },
		{ id = "rh_nosach",  tier = 1, type = "kill", target = "npc_nosach_samec", count = 8,  reward = 8, name = "Nosalis Purge",      desc = "Exterminate %d Nosalises in the outer zones." },
		{ id = "rh_murzik",  tier = 1, type = "kill", target = "npc_murzik",       count = 4,  reward = 9, name = "Watchmen Patrol",    desc = "Cull %d Watchmen prowling the Reich perimeter." },
		-- Tier 2 — dangerous packs
		{ id = "rh_murzik_pack", tier = 2, type = "kill", target = "npc_murzik",       count = 6,  reward = 10, money = 20, name = "Watchmen Sanctioned", desc = "Eliminate %d Watchmen on the Reich perimeter." },
		{ id = "rh_nosach_horde", tier = 2, type = "kill", target = "npc_nosach_samec", count = 14, reward = 11, money = 25, name = "Nosalis Horde",       desc = "Break a nest — slay %d Nosalises in the dead tunnels." },
		-- Tier 3 — advanced mutants (bullets + reputation)
		{ id = "rh_biblio", tier = 3, type = "kill", target = "npc_bibliotekar_redux", count = 2, reward = 14, money = 100, name = "Librarian Cull", desc = "Neutralise %d Librarians in the dead zones." },
		{ id = "rh_brute",  tier = 3, type = "kill", target = "npc_krisomutant_brute", count = 2, reward = 16, money = 120, name = "Brute Hunt",     desc = "Bring down %d Amoeba brutes stalking the deep metro." },
		{ id = "rh_demon",  tier = 3, type = "kill", target = "npc_krisomutant",       count = 1, reward = 18, money = 150, name = "Demon Slain",    desc = "Bring down a Demon — a test of true Reich mettle." },
	},

	-- Rangers of the Order (Polis) — advanced medical goods, knowledge, and
	-- military-grade weaponry.
	polis = {
		-- Tier 1 — field medical supplies
		{ id = "po_bandage",  tier = 1, type = "collect", target = "bandage",              count = 4, reward = 6, name = "Field Dressings",   desc = "Supply %d bandages to the Order's field medics." },
		{ id = "po_firstaid", tier = 1, type = "collect", target = "first_aid_kit",        count = 2, reward = 7, name = "First Aid Order",   desc = "Deliver %d first aid kits to the Polis infirmary." },
		{ id = "po_antirad",  tier = 1, type = "collect", target = "anti_radiation_pills", count = 3, reward = 6, name = "Rad Prophylaxis",   desc = "Supply %d courses of anti-radiation pills to the Order." },
		-- Tier 2 — advanced medical goods
		{ id = "po_medkit",   tier = 2, type = "collect", target = "medkit",            count = 2, reward = 9, money = 25, name = "Medkit Requisition", desc = "Deliver %d medkits to the Order's surgeons." },
		{ id = "po_herbal",   tier = 2, type = "collect", target = "herbal_remedy",     count = 3, reward = 8, money = 20, name = "Herbal Remedies",    desc = "Supply %d herbal remedies to the Polis apothecary." },
		{ id = "po_reagents", tier = 2, type = "collect", target = "medical_reagents",  count = 3, reward = 9, money = 25, name = "Reagent Supply",     desc = "Deliver %d medical reagents to the Order's laboratory." },
		-- Tier 3 — knowledge & military-grade weaponry (bullets + reputation)
		{ id = "po_medical_journal",  tier = 3, type = "collect", target = "medical_journal",    count = 1, reward = 14, money = 100, name = "Medical Journal",     desc = "Deliver a medical journal to the Order's archive." },
		{ id = "po_engineers_book",   tier = 3, type = "collect", target = "engineers_handbook", count = 1, reward = 14, money = 100, name = "Engineer's Handbook", desc = "Supply an engineer's handbook to the Order's archive." },
		{ id = "po_military_docs",    tier = 3, type = "collect", target = "military_documents",  count = 1, reward = 13, money = 90,  name = "Military Documents",  desc = "Deliver classified military documents to Polis intelligence." },
		{ id = "po_akm",   tier = 3, type = "collect", target = "akm",          count = 1, reward = 16, money = 140, name = "AKM Requisition", desc = "Deliver a crafted AKM to the Order's armoury." },
		{ id = "po_mp5",   tier = 3, type = "collect", target = "mp5a4",        count = 1, reward = 15, money = 120, name = "MP5 Requisition", desc = "Supply a crafted MP5 to the Rangers of the Order." },
		{ id = "po_usp",   tier = 3, type = "collect", target = "usp_tactical", count = 1, reward = 14, money = 100, name = "USP Contract",    desc = "Deliver a crafted USP Tactical to the Polis guard." },
		{ id = "po_sks",   tier = 3, type = "collect", target = "sks",          count = 1, reward = 15, money = 120, name = "SKS Contract",    desc = "Supply a crafted SKS to the Order's marksmen." },
		{ id = "po_g3a3",  tier = 3, type = "collect", target = "g3a3",         count = 1, reward = 16, money = 140, name = "G3A3 Contract",   desc = "Deliver a crafted G3A3 to the Order's armoury." },
	},
}

-- ── Daily contract selection (per-player, rank-tiered) ────────────────────────

-- Unique seeding offsets so each faction draws a different selection.
local FACTION_OFFSETS = { redline = 0, hansa = 999983, reich = 1999967, polis = 2999999 }

-- Looks up a contract definition by its stable id within a faction pool.
function PLUGIN:GetContractByID(factionKey, id)
	local pool = self.contractPools[factionKey]
	if not pool then return nil end
	for _, c in ipairs(pool) do
		if c.id == id then return c end
	end
end

-- Returns the operative's personal daily contract set for a faction. The set is
-- seeded per (character, day, faction, tier) so every operative gets their own
-- contracts, drawn from the tier their rank unlocks (backfilling from lower tiers
-- when that tier has fewer than the configured count). Any contract they are
-- actively working (accepted, not claimed) is always included so a rank change
-- can't rotate it out from under them. Server-only: relies on GetUnlockedTier /
-- GetActiveContractIDs (sv_plugin).
function PLUGIN:GetDailyContracts(factionKey, character)
	local pool = self.contractPools[factionKey]
	if not pool or not character then return {} end

	local count = ix.config.Get("factionRepContractCount", 3)
	local tier  = self:GetUnlockedTier(character, factionKey)

	-- Eligible = the player's tier, backfilled from lower tiers until we have at
	-- least `count` candidates so low ranks always get a full board.
	local eligible = {}
	for t = tier, 1, -1 do
		for _, c in ipairs(pool) do
			if (c.tier or 1) == t then
				eligible[#eligible + 1] = c
			end
		end
		if #eligible >= count then break end
	end

	local dateKey = tonumber(os.date("%Y%m%d")) or 0
	local seed = dateKey
		+ (character:GetID() or 0) * 7919
		+ (FACTION_OFFSETS[factionKey] or 0)
		+ tier * 104729
		+ (self.refreshSeed or 0) * 100003

	local selected, used, state = {}, {}, seed
	local target = math.min(count, #eligible)
	while #selected < target do
		state = (state * 1664525 + 1013904223) % (2 ^ 32)
		local idx = (state % #eligible) + 1
		if not used[idx] then
			used[idx] = true
			selected[#selected + 1] = table.Copy(eligible[idx])
		end
	end

	-- Always surface every contract the operative is actively working so they stay
	-- claimable even if a rank change would otherwise rotate them out of view.
	for _, activeID in ipairs(self:GetActiveContractIDs(character, factionKey)) do
		local present = false
		for _, c in ipairs(selected) do
			if c.id == activeID then present = true break end
		end
		if not present then
			local def = self:GetContractByID(factionKey, activeID)
			if def then table.insert(selected, 1, table.Copy(def)) end
		end
	end

	return selected
end

-- ── Admin commands (shared so the client registers them for chat auto-complete) ─

ix.command.Add("FactionRepSet", {
	description = "Set a player's faction reputation. Args: playerName, redline|hansa|reich|polis, value.",
	adminOnly   = true,
	arguments   = { ix.type.string, ix.type.string, ix.type.number },
	OnRun = function(_, client, targetName, fkey, amount)
		local target = ix.util.FindPlayer(targetName)
		if not target then client:Notify("Player not found.") return end
		local char = target:GetCharacter()
		if not char then client:Notify("Target has no character loaded.") return end
		if not PLUGIN.factionMeta[fkey] then
			client:Notify("Invalid faction key. Use 'redline', 'hansa', 'reich', or 'polis'.")
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
		local po = PLUGIN:GetRep(char, "polis")
		client:Notify(target:Name() .. " — Red Line: " .. rl .. " | Hansa: " .. hn .. " | Reich: " .. rc .. " | Polis: " .. po)
	end,
})

ix.command.Add("FactionRepRefresh", {
	description = "Force-refresh every operative's faction rep contracts (re-rolls the daily seed).",
	adminOnly   = true,
	OnRun = function(_, client)
		PLUGIN.refreshSeed = PLUGIN.refreshSeed + 1
		file.Write("ix/factionrep_refresh_seed.txt", tostring(PLUGIN.refreshSeed))
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
			for _, fkey in ipairs({ "redline", "hansa", "reich", "polis" }) do
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
