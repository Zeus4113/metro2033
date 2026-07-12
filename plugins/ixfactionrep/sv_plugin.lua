local PLUGIN = PLUGIN

file.CreateDir("ix")
PLUGIN.refreshSeed      = tonumber(file.Read("ix/factionrep_refresh_seed.txt", "DATA")) or 0
PLUGIN.sharedContracts  = ix.data.Get("faction_contracts", {}, false, true) or {}
PLUGIN.vendorRepData    = ix.data.Get("vendor_rep",         {}, false, true) or {}
PLUGIN.boardFactionData = ix.data.Get("board_faction",      {}, false, true) or {}
PLUGIN.factionRoster    = ix.data.Get("faction_roster",     {}, false, true) or {}

local ALL_FACTIONS = { "redline", "hansa", "reich" }
local REP_DEFAULTS = { redline = 0, hansa = 0, reich = 0 }

-- ── Persistence helpers ───────────────────────────────────────────────────────

function PLUGIN:SaveSharedContracts()
	ix.data.Set("faction_contracts", self.sharedContracts, false, true)
end

function PLUGIN:Initialize()
	self:LoadVendorRepData()
	self:StartDecayTimer()
end

-- ── Vendor helpers ────────────────────────────────────────────────────────────

function PLUGIN:GetVendorKey(entity)
	local name = entity:GetName()
	if name and name ~= "" then return "name_" .. name end
	local pos = entity:GetPos()
	return string.format("pos_%.1f_%.1f_%.1f", pos.x, pos.y, pos.z)
end

function PLUGIN:LoadVendorRepData()
	self.vendorRepData = ix.data.Get("vendor_rep", {}, false, true) or {}
end

function PLUGIN:SaveVendorRepData()
	ix.data.Set("vendor_rep", self.vendorRepData, false, true)
end

function PLUGIN:ApplyVendorRep(entity)
	local data = self.vendorRepData[self:GetVendorKey(entity)]
	if data then
		entity:SetNWString("ixVendorRepFaction", data.faction or "")
		entity:SetNWInt("ixVendorRepMin", data.min or 0)
	end
end

-- ── Board/faction key helpers ─────────────────────────────────────────────────

function PLUGIN:GetBoardKey(entity)
	local name = entity:GetName()
	if name and name ~= "" then return "name_" .. name end
	local pos = entity:GetPos()
	return string.format("pos_%.1f_%.1f_%.1f", pos.x, pos.y, pos.z)
end

function PLUGIN:SaveBoardFactionData()
	ix.data.Set("board_faction", self.boardFactionData, false, true)
end

-- ── Roster helpers ────────────────────────────────────────────────────────────

function PLUGIN:GetFactionCount(fkey)
	return table.Count(self.factionRoster[fkey] or {})
end

function PLUGIN:AddToFactionRoster(fkey, steamID)
	self.factionRoster[fkey] = self.factionRoster[fkey] or {}
	self.factionRoster[fkey][steamID] = true
	ix.data.Set("faction_roster", self.factionRoster, false, true)
end

function PLUGIN:RemoveFromFactionRoster(fkey, steamID)
	if self.factionRoster[fkey] then
		self.factionRoster[fkey][steamID] = nil
		ix.data.Set("faction_roster", self.factionRoster, false, true)
	end
end

function PLUGIN:PurgeFromRosters(fkey, steamID)
	self:RemoveFromFactionRoster(fkey, steamID)
end

-- ── Bounty helpers ────────────────────────────────────────────────────────────

function PLUGIN:GetBountyList(fkey)
	local bountyT = ix.config.Get("factionRepBountyThreshold", -50)
	local list    = {}
	for _, ply in ipairs(player.GetAll()) do
		local char = ply:GetCharacter()
		if not char then continue end
		local rep = self:GetRep(char, fkey)
		if rep <= bountyT then
			list[#list + 1] = { steamID = ply:SteamID(), charName = char:GetName(), rep = rep }
		end
	end
	return list
end

function PLUGIN:GetBountyStateForClient(client, fkey)
	local char        = client:GetCharacter()
	local bountyList  = self:GetBountyList(fkey)
	local activeBounty = char and char:GetData("activeBounty", nil)
	local activeID    = (activeBounty and activeBounty.fkey == fkey and activeBounty.targetID) or ""
	local completed   = char and char:GetData("completedBounty", nil)
	local hasCompleted = completed ~= nil and completed.fkey == fkey
	return bountyList, activeID, hasCompleted
end

-- ── Net message helpers (board open / push state / close) ─────────────────────

function PLUGIN:OpenBoard(client, ent)
	local char = client:GetCharacter()
	if not char then return end
	local fkey      = ent:GetFactionKey()
	local contracts = self:GetDailyContracts(fkey)
	local shared    = self:GetOrInitShared(fkey)
	local progress  = self:GetCharProgress(char)
	local rep       = self:GetRep(char, fkey)
	local bountyList, activeID, hasCompleted = self:GetBountyStateForClient(client, fkey)

	net.Start("ixFactionRepOpen")
		net.WriteEntity(ent)
		net.WriteString(fkey)
		net.WriteTable(contracts)
		net.WriteTable(shared.contracts)
		net.WriteTable(progress)
		net.WriteInt(rep, 8)
		net.WriteTable(bountyList)
		net.WriteString(activeID)
		net.WriteBool(hasCompleted)
	net.Send(client)
end

function PLUGIN:PushBoardState(client, fkey, char)
	local contracts = self:GetDailyContracts(fkey)
	local shared    = self:GetOrInitShared(fkey)
	local progress  = self:GetCharProgress(char)
	local rep       = self:GetRep(char, fkey)
	local bountyList, activeID, hasCompleted = self:GetBountyStateForClient(client, fkey)

	net.Start("ixFactionRepStateUpdate")
		net.WriteTable(contracts)
		net.WriteTable(shared.contracts)
		net.WriteTable(progress)
		net.WriteInt(rep, 8)
		net.WriteTable(bountyList)
		net.WriteString(activeID)
		net.WriteBool(hasCompleted)
	net.Send(client)
end

function PLUGIN:CloseBoard(ply)
	if not IsValid(ply) then return end
	ply.ixFactionRepEnt = nil
	net.Start("ixFactionRepStateUpdate")
		net.WriteTable({})
		net.WriteTable({})
		net.WriteTable({})
		net.WriteInt(0, 8)
		net.WriteTable({})
		net.WriteString("")
		net.WriteBool(false)
	net.Send(ply)
end

-- Refreshes everyone currently viewing a board for the given faction so a
-- contract reservation/release is reflected live on their boards.
function PLUGIN:PushFactionViewers(fkey)
	for _, ply in ipairs(player.GetAll()) do
		local ent = ply.ixFactionRepEnt
		if IsValid(ent) and ent:GetFactionKey() == fkey then
			local pchar = ply:GetCharacter()
			if pchar then
				self:PushBoardState(ply, fkey, pchar)
			end
		end
	end
end

-- Releases a single reserved-but-uncompleted contract slot. Clears the holder's
-- per-character progress when their character is supplied.
function PLUGIN:ReleaseContract(fkey, idx, char)
	local shared = self:GetOrInitShared(fkey)
	local slot   = shared.contracts[idx]
	if not slot or slot.claimed or not slot.acceptedBy then return false end

	slot.acceptedBy   = nil
	slot.acceptedName = nil
	self:SaveSharedContracts()

	if char then
		local pkey     = self:GetProgressKey(fkey, idx)
		local progress = self:GetCharProgress(char)
		if progress[pkey] and not progress[pkey].claimed then
			progress[pkey] = nil
			self:SetCharProgress(char, progress)
		end
	end
	return true
end

-- Returns fkey, idx of the contract this character is currently holding
-- (reserved but not yet completed) today, or nil if none. Characters may only
-- hold one contract at a time.
function PLUGIN:GetHeldContract(charID)
	local today = os.date("%Y%m%d")
	for _, fkey in ipairs(ALL_FACTIONS) do
		local dayData = self.sharedContracts[today .. "_" .. fkey]
		if dayData then
			for idx, slot in pairs(dayData.contracts) do
				if slot.acceptedBy == charID and not slot.claimed then
					return fkey, idx
				end
			end
		end
	end
end

-- Releases every contract a character is holding (used on disconnect / character
-- switch) so the slots become available to others again.
function PLUGIN:ReleaseCharacterContracts(character)
	if not character then return end
	local charID   = character:GetID()
	local progress = self:GetCharProgress(character)

	local touched, progressChanged = {}, false
	for key, dayData in pairs(self.sharedContracts) do
		local fkey = string.match(key, "^%d+_(.+)$")
		for idx, slot in pairs(dayData.contracts) do
			if slot.acceptedBy == charID and not slot.claimed then
				slot.acceptedBy   = nil
				slot.acceptedName = nil
				if fkey then touched[fkey] = true end

				-- "<date>_<fkey>_<idx>" matches the per-character progress key
				local pkey = key .. "_" .. idx
				if progress[pkey] and not progress[pkey].claimed then
					progress[pkey]  = nil
					progressChanged = true
				end
			end
		end
	end

	if progressChanged then
		self:SetCharProgress(character, progress)
		character:Save()
	end

	if next(touched) then
		self:SaveSharedContracts()
		for fkey in pairs(touched) do
			self:PushFactionViewers(fkey)
		end
	end
end

-- ── Entity faction key persistence ───────────────────────────────────────────

hook.Add("OnEntityCreated", "ixFactionRepBoardFactionLoad", function(entity)
	if entity:GetClass() ~= "ix_faction_board" then return end
	timer.Simple(0, function()
		if not IsValid(entity) then return end
		local saved = PLUGIN.boardFactionData[PLUGIN:GetBoardKey(entity)]
		if saved then
			entity:SetNWString("factionKey", saved)
		end
	end)
end)

-- ── Contract helpers ──────────────────────────────────────────────────────────

function PLUGIN:GetOrInitShared(factionKey)
	local today = os.date("%Y%m%d")
	local key   = today .. "_" .. factionKey
	local count = ix.config.Get("factionRepContractCount", 3)

	if not self.sharedContracts[key] then
		local entries = {}
		for i = 1, count do
			entries[i] = { claimed = false, claimedBy = nil }
		end
		self.sharedContracts[key] = { date = today, contracts = entries }
		self:SaveSharedContracts()
	else
		local entries = self.sharedContracts[key].contracts
		local changed = false
		for i = 1, count do
			if not entries[i] then
				entries[i] = { claimed = false, claimedBy = nil }
				changed = true
			end
		end
		if changed then self:SaveSharedContracts() end
	end
	return self.sharedContracts[key]
end

function PLUGIN:GetCharProgress(character)
	return character:GetData("factionRepContracts", {})
end

function PLUGIN:SetCharProgress(character, progressTable)
	character:SetData("factionRepContracts", progressTable)
end

function PLUGIN:GetProgressKey(factionKey, contractIndex)
	return os.date("%Y%m%d") .. "_" .. factionKey .. "_" .. contractIndex
end

-- ── Rep get / set ─────────────────────────────────────────────────────────────

function PLUGIN:GetRep(character, factionKey)
	local rep = character:GetData("factionRep", REP_DEFAULTS)
	return rep[factionKey] or 0
end

function PLUGIN:SetRep(character, factionKey, value)
	local meta = self.factionMeta[factionKey]
	local cap  = 100
	if meta then
		local inFaction = character:GetFaction() == meta.faction()
		if not inFaction then
			cap = ix.config.Get("factionRepTransferThreshold", 20)
		end
	end
	local rep = character:GetData("factionRep", REP_DEFAULTS)
	rep[factionKey] = math.Clamp(value, -100, cap)
	character:SetData("factionRep", rep)
	self:ApplyThresholds(character, factionKey, rep[factionKey])
end

-- ── Threshold application ─────────────────────────────────────────────────────

function PLUGIN:ApplyThresholds(character, factionKey, repValue)
	local meta = self.factionMeta[factionKey]
	if not meta then return end

	local client = character:GetPlayer()

	local transferT     = ix.config.Get("factionRepTransferThreshold", 20)
	local targetFaction = meta.faction()
	local inFaction     = character:GetFaction() == targetFaction

	if repValue < transferT and inFaction then
		-- Rep fell below join threshold while in faction — demote to Dwellers
		local dwellerData = ix.faction.indices[FACTION_DWELLER]
		if dwellerData then
			character.vars.faction = dwellerData.uniqueID
			character:SetFaction(FACTION_DWELLER)
			character:Save()
		end
		character:SetData("repEligible_" .. factionKey, false)

		if IsValid(client) then
			self:PurgeFromRosters(factionKey, client:SteamID())
			client:SetWhitelisted(targetFaction, false)
			client:Notify("Your " .. meta.name .. " reputation has fallen below " .. transferT .. ". You have been returned to the Dwellers.")
			self:CloseBoard(client)
		end
	else
		local nowElig = repValue >= transferT
		if character:GetData("repEligible_" .. factionKey, false) ~= nowElig then
			character:SetData("repEligible_" .. factionKey, nowElig)
		end

		if IsValid(client) then
			local shouldHaveWhitelist = repValue >= transferT
			if client:HasWhitelist(targetFaction) ~= shouldHaveWhitelist then
				client:SetWhitelisted(targetFaction, shouldHaveWhitelist)
			end
		end
	end

	if not IsValid(client) then return end

	-- Force-set the member to the rank they're entitled to (immediate promotion/demotion).
	if character:GetFaction() == targetFaction then
		local forced = self:GetFactionForcedClass(character)
		if forced and character:GetClass() ~= forced then
			character:SetClass(forced)
		end
	end
end

-- ── Forced-class resolution (rep-based ranks, admin Sergeant/Officer) ──────────

-- Returns the class an in-faction character must hold, or nil if they aren't in a
-- managed faction. Resolution: officer/sergeant whitelist (admin) → veteran/regular
-- by rep → rookie. Used by both the load-time resolver hook and ApplyThresholds.
function PLUGIN:GetFactionForcedClass(character)
	local faction = character:GetFaction()
	local fkey, meta
	for key, m in pairs(self.factionMeta) do
		if m.faction() == faction then fkey = key; meta = m; break end
	end
	if not meta then return end

	local client = character:GetPlayer()
	if IsValid(client) then
		if client:HasClassWhitelist(meta.officer())  then return meta.officer() end
		if client:HasClassWhitelist(meta.sergeant()) then return meta.sergeant() end
	end

	local rep      = self:GetRep(character, fkey)
	local veteranT = ix.config.Get("factionRepVeteranThreshold", 80)
	local regularT = ix.config.Get("factionRepRegularThreshold", 50)
	if rep >= veteranT then return meta.veteran() end
	if rep >= regularT then return meta.regular() end
	return meta.rookie()
end

-- Resolver hook handler: faction members are force-set to their rank.
function PLUGIN:GetForcedClass(client, character)
	return self:GetFactionForcedClass(character)
end

-- Maps a character's current class to a rank level 0–5 (for outfit recipe gating).
function PLUGIN:GetRankLevel(character)
	local cls = character:GetClass()
	for _, meta in pairs(self.factionMeta) do
		if cls == meta.officer()  then return 5 end
		if cls == meta.sergeant() then return 4 end
		if cls == meta.veteran()  then return 3 end
		if cls == meta.regular()  then return 2 end
		if cls == meta.rookie()   then return 1 end
	end
	return 0
end

-- ── Character loaded: offline decay + threshold sync + roster reconciliation ──

function PLUGIN:CharacterLoaded(character)
	timer.Simple(0.1, function()
		if not character then return end

		local interval  = ix.config.Get("factionRepDecayInterval", 3600)
		local amount    = ix.config.Get("factionRepDecayAmount", 2)
		local lastDecay = character:GetData("factionRepLastDecay", os.time())
		local ticks     = math.floor((os.time() - lastDecay) / interval)

		if ticks > 0 and amount > 0 then
			local changed = false
			for _, fkey in ipairs(ALL_FACTIONS) do
				local current = self:GetRep(character, fkey)
				if current > 0 then
					-- Positive rep decays downward
					self:SetRep(character, fkey, math.max(0, current - ticks * amount))
					changed = true
				elseif current < 0 then
					-- Negative rep recovers upward toward 0
					self:SetRep(character, fkey, math.min(0, current + ticks * amount))
					changed = true
				end
			end
			character:SetData("factionRepLastDecay", lastDecay + ticks * interval)
			if changed then character:Save() end
		end

		for _, fkey in ipairs(ALL_FACTIONS) do
			self:ApplyThresholds(character, fkey, self:GetRep(character, fkey))
		end

		-- Roster reconciliation: heal any data drift
		local ply = character:GetPlayer()
		if not IsValid(ply) then return end
		local steamID = ply:SteamID()

		for _, fkey in ipairs(ALL_FACTIONS) do
			local meta = self.factionMeta[fkey]
			if not meta then continue end

			local inFaction = character:GetFaction() == meta.faction()
			local inRoster  = self.factionRoster[fkey] and self.factionRoster[fkey][steamID]
			if inFaction and not inRoster then
				self:AddToFactionRoster(fkey, steamID)
			elseif not inFaction and inRoster then
				self:RemoveFromFactionRoster(fkey, steamID)
			end
		end
	end)
end

-- ── NPC kill tracking for contracts ──────────────────────────────────────────

hook.Add("OnNPCKilled", "ixFactionRepKillTrack", function(npc, attacker)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	local char = attacker:GetCharacter()
	if not char then return end

	local changed = false

	for _, fkey in ipairs(ALL_FACTIONS) do
		local contracts = PLUGIN:GetDailyContracts(fkey)
		local shared    = PLUGIN:GetOrInitShared(fkey)
		local progress  = PLUGIN:GetCharProgress(char)

		for i, contract in ipairs(contracts) do
			if contract.type ~= "kill" then continue end
			if contract.target ~= npc:GetClass() then continue end
			if shared.contracts[i] and shared.contracts[i].claimed then continue end

			local pkey = PLUGIN:GetProgressKey(fkey, i)
			local qs   = progress[pkey]
			if not qs or not qs.accepted then continue end
			if (qs.progress or 0) >= contract.count then continue end

			qs.progress    = qs.progress + 1
			progress[pkey] = qs
			changed        = true
		end

		if changed then
			PLUGIN:SetCharProgress(char, progress)
		end
	end

	if changed then
		local ent = attacker.ixFactionRepEnt
		if IsValid(ent) then
			PLUGIN:PushBoardState(attacker, ent:GetFactionKey(), char)
		end
	end
end)

-- ── Contract: accept ─────────────────────────────────────────────────────────

net.Receive("ixFactionRepAccept", function(_, client)
	local ent = client.ixFactionRepEnt
	if not IsValid(ent) then return end

	local range = ix.config.Get("factionRepBoardRange", 96)
	if client:GetPos():DistToSqr(ent:GetPos()) > range ^ 2 then return end

	local char = client:GetCharacter()
	if not char then return end

	local idx  = net.ReadUInt(8)
	local fkey = ent:GetFactionKey()

	local contracts = PLUGIN:GetDailyContracts(fkey)
	if not contracts[idx] then return end

	local shared = PLUGIN:GetOrInitShared(fkey)
	local slot   = shared.contracts[idx]
	if slot and slot.claimed then
		client:Notify("That contract has already been completed by someone else.")
		return
	end

	-- Exclusive reservation: only one operative may hold a contract at a time
	if slot and slot.acceptedBy and slot.acceptedBy ~= char:GetID() then
		client:Notify("That contract is already taken by " .. (slot.acceptedName or "another operative") .. ".")
		return
	end

	local meta = PLUGIN.factionMeta[fkey]
	if meta and char:GetFaction() ~= meta.faction() then
		local cap        = ix.config.Get("factionRepTransferThreshold", 20)
		local currentRep = PLUGIN:GetRep(char, fkey)
		if currentRep >= cap then
			client:Notify("You are at the " .. cap .. " rep cap. Enlist in the " .. meta.name .. " to earn more.")
			return
		end
	end

	-- Already holding the reservation → nothing to do
	if slot.acceptedBy == char:GetID() then return end

	-- One contract at a time: block if this character already holds another
	if PLUGIN:GetHeldContract(char:GetID()) then
		client:Notify("You can only work one contract at a time. Finish or abandon your current contract first.")
		return
	end

	-- Reserve the shared slot
	slot.acceptedBy   = char:GetID()
	slot.acceptedName = char:GetName()
	PLUGIN:SaveSharedContracts()

	-- Record per-character progress (preserve any pre-existing progress)
	local pkey     = PLUGIN:GetProgressKey(fkey, idx)
	local progress = PLUGIN:GetCharProgress(char)
	if not (progress[pkey] and progress[pkey].accepted) then
		progress[pkey] = { accepted = true, progress = 0 }
		PLUGIN:SetCharProgress(char, progress)
	end

	-- Refresh every viewer so the contract now shows as taken
	PLUGIN:PushFactionViewers(fkey)
end)

-- ── Contract: unclaim (abandon a reserved contract) ───────────────────────────

net.Receive("ixFactionRepUnclaim", function(_, client)
	local ent = client.ixFactionRepEnt
	if not IsValid(ent) then return end

	local range = ix.config.Get("factionRepBoardRange", 96)
	if client:GetPos():DistToSqr(ent:GetPos()) > range ^ 2 then return end

	local char = client:GetCharacter()
	if not char then return end

	local idx  = net.ReadUInt(8)
	local fkey = ent:GetFactionKey()

	local shared = PLUGIN:GetOrInitShared(fkey)
	local slot   = shared.contracts[idx]
	if not slot or slot.claimed then return end

	if slot.acceptedBy ~= char:GetID() then
		client:Notify("You haven't taken that contract.")
		return
	end

	PLUGIN:ReleaseContract(fkey, idx, char)
	client:Notify("Contract released. It is available to others again.")
	PLUGIN:PushFactionViewers(fkey)
end)

-- Free a character's reserved contracts when they disconnect or switch character,
-- so others can take them on.
hook.Add("OnCharacterDisconnect", "ixFactionRepReleaseContracts", function(_, character)
	PLUGIN:ReleaseCharacterContracts(character)
end)

hook.Add("PrePlayerLoadedCharacter", "ixFactionRepReleaseContracts", function(_, _, previousChar)
	if previousChar then
		PLUGIN:ReleaseCharacterContracts(previousChar)
	end
end)

-- ── Contract: claim ───────────────────────────────────────────────────────────

net.Receive("ixFactionRepClaim", function(_, client)
	local ent = client.ixFactionRepEnt
	if not IsValid(ent) then return end

	local range = ix.config.Get("factionRepBoardRange", 96)
	if client:GetPos():DistToSqr(ent:GetPos()) > range ^ 2 then return end

	local char = client:GetCharacter()
	if not char then return end

	local idx  = net.ReadUInt(8)
	local fkey = ent:GetFactionKey()

	local contracts = PLUGIN:GetDailyContracts(fkey)
	local contract  = contracts[idx]
	if not contract then return end

	local shared = PLUGIN:GetOrInitShared(fkey)
	if shared.contracts[idx] and shared.contracts[idx].claimed then
		client:Notify("Someone already claimed that contract.")
		PLUGIN:PushBoardState(client, fkey, char)
		return
	end

	local pkey     = PLUGIN:GetProgressKey(fkey, idx)
	local progress = PLUGIN:GetCharProgress(char)
	local qs       = progress[pkey]

	if not qs or not qs.accepted then
		client:Notify("You haven't accepted this contract.")
		return
	end

	-- Must still hold the reservation to turn it in
	if shared.contracts[idx].acceptedBy and shared.contracts[idx].acceptedBy ~= char:GetID() then
		client:Notify("That contract is no longer reserved to you.")
		PLUGIN:PushBoardState(client, fkey, char)
		return
	end

	if contract.type == "kill" then
		if (qs.progress or 0) < contract.count then
			client:Notify("Contract incomplete. (" .. (qs.progress or 0) .. "/" .. contract.count .. ")")
			return
		end

	elseif contract.type == "collect" then
		local inv   = char:GetInventory()
		local items = inv:GetItems()
		local found = {}
		for _, item in pairs(items) do
			if item.uniqueID == contract.target and not item:GetData("equip", false) then
				found[#found + 1] = item
				if #found >= contract.count then break end
			end
		end
		if #found < contract.count then
			local def      = ix.item.list[contract.target]
			local itemName = (def and def.name) or contract.target
			client:Notify("You need " .. contract.count .. "x " .. itemName .. ". (" .. #found .. "/" .. contract.count .. ")")
			return
		end
		for _, item in ipairs(found) do
			item:Remove()
		end
	end

	shared.contracts[idx].claimed     = true
	shared.contracts[idx].claimedBy   = client:SteamID()
	shared.contracts[idx].acceptedBy  = nil
	shared.contracts[idx].acceptedName = nil
	PLUGIN:SaveSharedContracts()

	local newRep = math.Clamp(PLUGIN:GetRep(char, fkey) + contract.reward, -100, 100)
	PLUGIN:SetRep(char, fkey, newRep)
	qs.claimed     = true
	progress[pkey] = qs
	PLUGIN:SetCharProgress(char, progress)
	char:Save()

	local fname = PLUGIN.factionMeta[fkey] and PLUGIN.factionMeta[fkey].name or fkey
	client:Notify("Contract complete! +" .. contract.reward .. " " .. fname .. " reputation. Total: " .. newRep)

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply.ixFactionRepEnt) and ply.ixFactionRepEnt == ent then
			local pchar = ply:GetCharacter()
			if pchar then
				PLUGIN:PushBoardState(ply, fkey, pchar)
			end
		end
	end
end)

-- ── Board: close ─────────────────────────────────────────────────────────────

net.Receive("ixFactionRepClose", function(_, client)
	client.ixFactionRepEnt = nil
end)

-- ── Board: leave faction ──────────────────────────────────────────────────────

net.Receive("ixFactionRepLeave", function(_, client)
	local ent = client.ixFactionRepEnt
	if not IsValid(ent) then return end

	local range = ix.config.Get("factionRepBoardRange", 96)
	if client:GetPos():DistToSqr(ent:GetPos()) > range ^ 2 then return end

	local char = client:GetCharacter()
	if not char then return end

	local fkey = ent:GetFactionKey()
	local meta = PLUGIN.factionMeta[fkey]
	if not meta then return end

	local targetFaction = meta.faction()
	if char:GetFaction() ~= targetFaction then
		client:Notify("You are not a member of this faction.")
		return
	end

	-- Apply 20% rep penalty before demoting
	local currentRep = PLUGIN:GetRep(char, fkey)
	local newRep     = math.max(0, math.floor(currentRep * 0.8))

	-- Demote to Dweller
	local dwellerData = ix.faction.indices[FACTION_DWELLER]
	if dwellerData then
		char.vars.faction = dwellerData.uniqueID
		char:SetFaction(FACTION_DWELLER)
	end

	PLUGIN:PurgeFromRosters(fkey, client:SteamID())

	-- Strip admin rank whitelists (rep ranks are force-set, not whitelisted)
	client:SetClassWhitelisted(meta.officer(),   false)
	client:SetClassWhitelisted(meta.sergeant(),  false)

	-- Write rep directly (bypass non-member cap in SetRep)
	local rep = char:GetData("factionRep", REP_DEFAULTS)
	rep[fkey] = newRep
	char:SetData("factionRep", rep)

	-- Restore faction whitelist if rep still qualifies
	local transferT = ix.config.Get("factionRepTransferThreshold", 20)
	char:SetData("repEligible_" .. fkey, newRep >= transferT)
	client:SetWhitelisted(targetFaction, newRep >= transferT)

	char:Save()
	client:Notify("You have left the " .. meta.name .. ". Reputation: " .. currentRep .. " → " .. newRep .. " (-20%).")
	PLUGIN:CloseBoard(client)
end)

-- ── Board: join faction ───────────────────────────────────────────────────────

net.Receive("ixFactionRepTransfer", function(_, client)
	local ent = client.ixFactionRepEnt
	if not IsValid(ent) then return end

	local range = ix.config.Get("factionRepBoardRange", 96)
	if client:GetPos():DistToSqr(ent:GetPos()) > range ^ 2 then return end

	local char = client:GetCharacter()
	if not char then return end

	local fkey = ent:GetFactionKey()
	local meta = PLUGIN.factionMeta[fkey]
	if not meta then return end

	local transferT = ix.config.Get("factionRepTransferThreshold", 20)
	if PLUGIN:GetRep(char, fkey) < transferT then
		client:Notify("You need at least " .. transferT .. " " .. meta.name .. " reputation to transfer.")
		return
	end

	local currentFaction = char:GetFaction()
	local targetFaction  = meta.faction()

	if currentFaction ~= FACTION_DWELLER and currentFaction ~= targetFaction then
		client:Notify("You cannot transfer to this faction from your current allegiance.")
		return
	end

	if currentFaction == targetFaction then
		client:Notify("You are already a member of this faction.")
		return
	end

	local factionData = ix.faction.indices[targetFaction]
	if not factionData then return end

	local factionCap = ix.config.Get(meta.capConfig, 0)
	if factionCap > 0 and PLUGIN:GetFactionCount(fkey) >= factionCap then
		client:Notify("The " .. meta.name .. " is at capacity (" .. factionCap .. " members).")
		return
	end

	client:SetWhitelisted(targetFaction, true)
	char.vars.faction = factionData.uniqueID
	char:SetFaction(targetFaction)
	char:Save()
	PLUGIN:AddToFactionRoster(fkey, client:SteamID())
	PLUGIN:ApplyThresholds(char, fkey, PLUGIN:GetRep(char, fkey))

	client:Notify("You have joined the " .. factionData.name .. ". Welcome.")
	PLUGIN:CloseBoard(client)
end)

-- ── Bounty: accept ────────────────────────────────────────────────────────────

net.Receive("ixFactionRepBountyAccept", function(_, client)
	local ent = client.ixFactionRepEnt
	if not IsValid(ent) then return end

	local range = ix.config.Get("factionRepBoardRange", 96)
	if client:GetPos():DistToSqr(ent:GetPos()) > range ^ 2 then return end

	local char = client:GetCharacter()
	if not char then return end

	local fkey = ent:GetFactionKey()
	local meta = PLUGIN.factionMeta[fkey]
	if not meta or char:GetFaction() ~= meta.faction() then return end

	if char:GetData("activeBounty", nil) then
		client:Notify("You already have an active bounty. Abandon it before accepting another.")
		return
	end

	local targetID = net.ReadString()
	local bountyT  = ix.config.Get("factionRepBountyThreshold", -50)

	local targetValid = false
	for _, ply in ipairs(player.GetAll()) do
		if ply:SteamID() == targetID then
			local tc = ply:GetCharacter()
			if tc and PLUGIN:GetRep(tc, fkey) <= bountyT then
				targetValid = true
			end
			break
		end
	end

	if not targetValid then
		client:Notify("That bounty target is no longer valid.")
		PLUGIN:PushBoardState(client, fkey, char)
		return
	end

	char:SetData("activeBounty", { fkey = fkey, targetID = targetID })
	char:Save()
	client:Notify("Bounty accepted. Hunt them down and return here to claim your reward.")
	PLUGIN:PushBoardState(client, fkey, char)
end)

-- ── Bounty: claim ─────────────────────────────────────────────────────────────

net.Receive("ixFactionRepBountyClaim", function(_, client)
	local ent = client.ixFactionRepEnt
	if not IsValid(ent) then return end

	local range = ix.config.Get("factionRepBoardRange", 96)
	if client:GetPos():DistToSqr(ent:GetPos()) > range ^ 2 then return end

	local char = client:GetCharacter()
	if not char then return end

	local fkey     = ent:GetFactionKey()
	local completed = char:GetData("completedBounty", nil)

	if not completed or completed.fkey ~= fkey then
		client:Notify("You have no completed bounty to claim here.")
		return
	end

	local reward = ix.config.Get("factionRepBountyReward", 20)
	local newRep = PLUGIN:GetRep(char, fkey) + reward
	PLUGIN:SetRep(char, fkey, newRep)
	char:SetData("completedBounty", nil)
	char:Save()

	local meta  = PLUGIN.factionMeta[fkey]
	local fname = meta and meta.name or fkey
	client:Notify("Bounty claimed. +" .. reward .. " " .. fname .. " reputation. Total: " .. newRep)
	PLUGIN:PushBoardState(client, fkey, char)
end)

-- ── Bounty: kill tracking ─────────────────────────────────────────────────────

hook.Add("PlayerDeath", "ixFactionBountyKill", function(victim, _, attacker)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	if attacker == victim then return end
	local achar = attacker:GetCharacter()
	local vchar = victim:GetCharacter()
	if not achar or not vchar then return end

	local bounty = achar:GetData("activeBounty", nil)
	if not bounty or victim:SteamID() ~= bounty.targetID then return end

	local bountyT   = ix.config.Get("factionRepBountyThreshold", -50)
	local targetRep = PLUGIN:GetRep(vchar, bounty.fkey)
	if targetRep > bountyT then return end

	-- Anti-farming: each kill moves the target's rep toward 0 by the bounty reward
	local reward       = ix.config.Get("factionRepBountyReward", 20)
	local newTargetRep = math.min(0, targetRep + reward)
	PLUGIN:SetRep(vchar, bounty.fkey, newTargetRep)
	vchar:Save()

	-- Mark bounty completable for the killer
	achar:SetData("completedBounty", bounty)
	achar:SetData("activeBounty", nil)
	achar:Save()
	attacker:Notify("Bounty target eliminated. Return to the board to claim your reward.")

	-- If target's rep has recovered above the threshold, clear other hunters
	if newTargetRep > bountyT then
		local targetSID = victim:SteamID()
		for _, ply in ipairs(player.GetAll()) do
			local c = ply:GetCharacter()
			if not c then continue end
			local ab = c:GetData("activeBounty", nil)
			if ab and ab.targetID == targetSID and ab.fkey == bounty.fkey then
				c:SetData("activeBounty", nil)
				c:Save()
				ply:Notify("Your bounty target is no longer eligible — the bounty has been cleared.")
			end
		end
	end
end)

-- ── Decay timer (bidirectional: all rep trends toward 0) ──────────────────────

function PLUGIN:StartDecayTimer()
	timer.Create("ixFactionRepDecay", ix.config.Get("factionRepDecayInterval", 3600), 0, function()
		local amount = ix.config.Get("factionRepDecayAmount", 2)
		if amount <= 0 then return end

		for _, ply in ipairs(player.GetAll()) do
			local char = ply:GetCharacter()
			if not char then continue end

			local changed = false
			for _, fkey in ipairs(ALL_FACTIONS) do
				local current = PLUGIN:GetRep(char, fkey)
				if current > 0 then
					PLUGIN:SetRep(char, fkey, math.max(0, current - amount))
					changed = true
				elseif current < 0 then
					PLUGIN:SetRep(char, fkey, math.min(0, current + amount))
					changed = true
				end
			end

			char:SetData("factionRepLastDecay", os.time())
			if changed then
				char:Save()
				ply:Notify("Your faction reputation has decayed.")
			end
		end
	end)
end

-- ── Vendor rep gate ───────────────────────────────────────────────────────────
-- Gates *opening* the vendor menu (CanPlayerUseVendor fires on Use), not just
-- trading. CanPlayerTradeWithVendor would only fire once a buy/sell is attempted.

function PLUGIN:CanPlayerUseVendor(client, entity)
	local fkey = entity:GetNWString("ixVendorRepFaction", "")
	if fkey == "" then return end

	local char = client:GetCharacter()
	if not char then return end

	local repMin = entity:GetNWInt("ixVendorRepMin", 0)
	local meta   = self.factionMeta[fkey]
	if self:GetRep(char, fkey) < repMin then
		local fname = meta and meta.name or fkey
		client:Notify("You need " .. repMin .. " " .. fname .. " reputation to trade here.")
		return false
	end
end

hook.Add("OnEntityCreated", "ixFactionRepVendorRepLoad", function(entity)
	if entity:GetClass() ~= "ix_vendor" then return end
	timer.Simple(0, function()
		if not IsValid(entity) then return end
		PLUGIN:ApplyVendorRep(entity)
	end)
end)

net.Receive("ixFactionRepVendorSet", function(_, client)
	if not client:IsAdmin() then return end
	local entity = net.ReadEntity()
	local fkey   = net.ReadString()
	local num    = net.ReadInt(8)
	if not IsValid(entity) or entity:GetClass() ~= "ix_vendor" then return end
	if fkey ~= "" and fkey ~= "redline" and fkey ~= "hansa" and fkey ~= "reich" then return end
	entity:SetNWString("ixVendorRepFaction", fkey)
	entity:SetNWInt("ixVendorRepMin", num)
	local key = PLUGIN:GetVendorKey(entity)
	if fkey == "" then
		PLUGIN.vendorRepData[key] = nil
	else
		PLUGIN.vendorRepData[key] = { faction = fkey, min = num }
	end
	PLUGIN:SaveVendorRepData()
	client:Notify("Vendor rep gate updated.")
end)

-- ── Cleanup ───────────────────────────────────────────────────────────────────

function PLUGIN:OnUnloaded()
	timer.Remove("ixFactionRepDecay")
end

-- ── Player death hooks ────────────────────────────────────────────────────────

hook.Add("PlayerDeath", "ixFactionRepCloseOnDeath", function(ply) PLUGIN:CloseBoard(ply) end)

hook.Add("PlayerDeath", "ixFactionRepKillPenalty", function(victim, _, attacker)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	if attacker == victim then return end
	local vchar = victim:GetCharacter()
	if not vchar then return end
	local achar = attacker:GetCharacter()
	if not achar then return end

	local victimFaction = vchar:GetFaction()
	local penalty       = ix.config.Get("factionRepKillPenalty", 10)

	for fkey, meta in pairs(PLUGIN.factionMeta) do
		if meta.faction() == victimFaction then
			PLUGIN:SetRep(achar, fkey, PLUGIN:GetRep(achar, fkey) - penalty)
			achar:Save()
			attacker:Notify("You lost " .. penalty .. " " .. meta.name .. " reputation.")
			break
		end
	end
end)

-- Deferred one frame so all PlayerDeath hooks finish first.
hook.Add("PlayerDeath", "ixFactionRepPermakillWipe", function(ply)
	timer.Simple(0, function()
		if not IsValid(ply) then return end
		local char = ply:GetCharacter()
		if not char or not char:GetData("permakilled", false) then return end

		local wl = ply:GetData("whitelists", {})
		wl[Schema.folder] = {}
		ply:SetData("whitelists", wl)

		local cw = ply:GetData("classWhitelists", {})
		cw[Schema.folder] = {}
		ply:SetData("classWhitelists", cw)

		ply:SaveData()

		local steamID = ply:SteamID()
		for fkey in pairs(PLUGIN.factionMeta) do
			PLUGIN:PurgeFromRosters(fkey, steamID)
		end
	end)
end)

hook.Add("PlayerDisconnected", "ixFactionRepCloseOnDisconnect", function(ply) PLUGIN:CloseBoard(ply) end)

-- Admin commands are defined in sh_plugin.lua so they register on both
-- client and server, allowing in-game chat auto-complete to suggest them.
