local PLUGIN = PLUGIN

PLUGIN.groups        = ix.data.Get("gang_groups",        {}, false, true) or {}
PLUGIN.bases         = ix.data.Get("gang_bases",         {}, false, true) or {}
PLUGIN.baseHideouts  = ix.data.Get("gang_base_hideouts", {}, false, true) or {}

-- ── Persistence ───────────────────────────────────────────────────────────────

function PLUGIN:SaveGroups()
	ix.data.Set("gang_groups", self.groups, false, true)
end

function PLUGIN:SaveBases()
	ix.data.Set("gang_bases", self.bases, false, true)
end

function PLUGIN:SaveBaseHideouts()
	ix.data.Set("gang_base_hideouts", self.baseHideouts, false, true)
end

-- Restore admin-set hideout keys on entity spawn (mirrors faction board pattern)
hook.Add("OnEntityCreated", "ixGangBaseHideoutLoad", function(entity)
	if entity:GetClass() ~= "ix_gang_base" then return end
	timer.Simple(0, function()
		if not IsValid(entity) then return end
		local saved = PLUGIN.baseHideouts[PLUGIN:GetBaseKey(entity)]
		if saved then
			entity:SetNWString("hideoutKey", saved)
		end
	end)
end)

function PLUGIN:Initialize()
	self:StartUpkeepTimer()
end

function PLUGIN:OnUnloaded()
	timer.Remove("ixGangUpkeep")
end

-- ── Base keying (mirrors faction board GetBoardKey) ───────────────────────────

function PLUGIN:GetBaseKey(entity)
	local name = entity:GetName()
	if name and name ~= "" then return "name_" .. name end
	local pos = entity:GetPos()
	return string.format("pos_%.1f_%.1f_%.1f", pos.x, pos.y, pos.z)
end

function PLUGIN:GetBaseData(baseKey)
	return self.bases[baseKey]
end

-- ── Character / member resolution ─────────────────────────────────────────────

-- Resolves a character ID to a loaded character (online), or nil.
local function loadedChar(charID)
	return ix.char.loaded[charID]
end

-- Returns the connected player for a character ID, or nil.
local function onlinePlayer(charID)
	local char = loadedChar(charID)
	if not char then return nil end
	local ply = char:GetPlayer()
	return IsValid(ply) and ply or nil
end

-- ── Group helpers ─────────────────────────────────────────────────────────────

function PLUGIN:GetGroup(groupID)
	return groupID and self.groups[groupID] or nil
end

function PLUGIN:GetCharGroup(character)
	local groupID = character:GetData("groupID")
	if not groupID then return nil end
	local group = self.groups[groupID]
	if not group then
		-- Orphaned reference; clear silently
		character:SetData("groupID", nil)
		character:Save()
		return nil
	end
	return group, groupID
end

function PLUGIN:GenerateGroupID(leaderCharID)
	return "g_" .. leaderCharID .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function PLUGIN:CreateGroup(leaderChar, name)
	local leaderID = leaderChar:GetID()
	local groupID  = self:GenerateGroupID(leaderID)

	self.groups[groupID] = {
		name        = name,
		leaderID    = leaderID,
		successorID = nil,
		members     = { leaderID },
		baseKey     = nil,
	}
	leaderChar:SetData("groupID", groupID)
	leaderChar:Save()
	self:SaveGroups()
	return groupID
end

function PLUGIN:DeleteGroup(groupID)
	local group = self.groups[groupID]
	if not group then return end

	-- Release any held base
	if group.baseKey then
		self:Unclaim(group.baseKey, true)
	end

	-- Clear groupID on every member that is currently loaded
	for _, charID in ipairs(group.members) do
		local char = loadedChar(charID)
		if char and char:GetData("groupID") == groupID then
			char:SetData("groupID", nil)
			char:Save()
		end
	end

	self.groups[groupID] = nil
	self:SaveGroups()
end

-- ── Class assignment (single choke point) ─────────────────────────────────────

-- In-session class change for an online member. classIndex may be nil to drop
-- the member to the default Dweller class. Load-time restoration is handled by
-- the central class resolver via the GetForcedClass hook.
function PLUGIN:SetMemberClass(charID, classIndex)
	local char = loadedChar(charID)
	if not char then return end
	local ply = char:GetPlayer()
	if not IsValid(ply) then return end

	if classIndex then
		if char:GetClass() ~= classIndex then
			char:SetClass(classIndex)
		end
	else
		char:KickClass()
	end
end

-- ── Membership mutation ───────────────────────────────────────────────────────

function PLUGIN:AddMember(groupID, charID)
	local group = self.groups[groupID]
	if not group then return false end
	if #group.members >= ix.config.Get("gangMaxMembers", 8) then return false, "full" end

	for _, id in ipairs(group.members) do
		if id == charID then return false, "already" end
	end

	group.members[#group.members + 1] = charID
	local char = loadedChar(charID)
	if char then
		char:SetData("groupID", groupID)
		char:Save()
	end
	self:SaveGroups()

	-- Grant the gang class if the group currently holds a live claim
	if group.baseKey then
		local base = self.bases[group.baseKey]
		if base and base.ownerGroupID == groupID and base.upkeepExpires > os.time() then
			self:SetMemberClass(charID, self:GetHideoutClass(base.hideout))
		end
	end

	self:SyncGroup(groupID)
	return true
end

-- Removes a member. isPermadeath only affects messaging/intent; behaviour is identical.
function PLUGIN:RemoveMember(charID, isPermadeath)
	-- Find the group this character belongs to
	local groupID, group
	local char = loadedChar(charID)
	if char then
		group, groupID = self:GetCharGroup(char)
	end
	if not group then
		-- Fall back to scanning (covers offline permadeath where char data is gone)
		for id, g in pairs(self.groups) do
			for _, mid in ipairs(g.members) do
				if mid == charID then group = g; groupID = id; break end
			end
			if group then break end
		end
	end
	if not group then return end

	-- Strip class while still resolvable
	self:SetMemberClass(charID, nil)

	-- Remove from members list
	for i = #group.members, 1, -1 do
		if group.members[i] == charID then
			table.remove(group.members, i)
		end
	end

	-- Clear the character's groupID
	if char and char:GetData("groupID") == groupID then
		char:SetData("groupID", nil)
		char:Save()
	end

	-- Empty group → delete
	if #group.members == 0 then
		self:DeleteGroup(groupID)
		return
	end

	-- Leadership succession
	if group.leaderID == charID then
		local newLeader

		if group.successorID then
			for _, mid in ipairs(group.members) do
				if mid == group.successorID then newLeader = group.successorID break end
			end
		end
		newLeader = newLeader or group.members[1]   -- oldest remaining

		group.leaderID    = newLeader
		group.successorID = nil

		local lp = onlinePlayer(newLeader)
		if IsValid(lp) then lp:Notify("You are now the leader of " .. group.name .. ".") end
	elseif group.successorID == charID then
		group.successorID = nil
	end

	self:SaveGroups()
	self:SyncGroup(groupID)
end

-- ── Claim / upkeep / abandon / unclaim ────────────────────────────────────────

function PLUGIN:ClaimBase(client, char, entity)
	local group, groupID = self:GetCharGroup(char)
	if not group then
		client:Notify("You must be in a group to claim a hideout.")
		return
	end
	if group.leaderID ~= char:GetID() then
		client:Notify("Only the group leader may claim a hideout.")
		return
	end
	if group.baseKey then
		client:Notify("Your group already holds a hideout. Abandon it first.")
		return
	end

	local baseKey  = self:GetBaseKey(entity)
	local hideout  = entity:GetHideoutKey()
	local classIdx = self:GetHideoutClass(hideout)
	if not classIdx then
		client:Notify("This hideout is not configured.")
		return
	end

	-- Base must be unowned or expired
	local base = self.bases[baseKey]
	if base and base.ownerGroupID and base.upkeepExpires > os.time() then
		client:Notify("This hideout is already held by another group.")
		return
	end

	local cost = ix.config.Get("gangClaimCost", 250)
	if not char:HasMoney(cost) then
		client:Notify("You need " .. ix.currency.Get(cost) .. " to claim this hideout.")
		return
	end
	char:TakeMoney(cost)

	-- Release any stale/expired owner still referencing this base
	if base and base.ownerGroupID and base.ownerGroupID ~= groupID then
		self:Unclaim(baseKey, false)
	end

	self.bases[baseKey] = {
		ownerGroupID  = groupID,
		upkeepExpires = os.time() + ix.config.Get("gangUpkeepDuration", 86400),
		hideout       = hideout,
	}
	self:SaveBases()

	group.baseKey = baseKey
	self:SaveGroups()

	-- Grant the class to all online members
	for _, charID in ipairs(group.members) do
		self:SetMemberClass(charID, classIdx)
		local mp = onlinePlayer(charID)
		if IsValid(mp) then mp:Notify(group.name .. " has claimed the " .. self:GetHideoutName(hideout) .. ".") end
	end

	self:SyncGroup(groupID)
	return true
end

function PLUGIN:PayUpkeep(client, char, entity)
	local group, groupID = self:GetCharGroup(char)
	if not group then return end

	local baseKey = self:GetBaseKey(entity)
	local base    = self.bases[baseKey]
	if not base or base.ownerGroupID ~= groupID then
		client:Notify("Your group does not own this hideout.")
		return
	end

	local now    = os.time()
	local maxExp = now + ix.config.Get("gangUpkeepMax", 259200)

	-- Block payment when already stockpiled to the cap
	if base.upkeepExpires >= maxExp then
		client:Notify("Upkeep is already at the maximum. You cannot stockpile more time.")
		return
	end

	local cost = ix.config.Get("gangUpkeepCost", 100)
	if not char:HasMoney(cost) then
		client:Notify("You need " .. ix.currency.Get(cost) .. " to pay upkeep.")
		return
	end
	char:TakeMoney(cost)

	-- Extend, but never beyond the stockpile cap
	local extended = math.max(base.upkeepExpires, now) + ix.config.Get("gangUpkeepDuration", 86400)
	base.upkeepExpires = math.min(extended, maxExp)
	self:SaveBases()

	client:Notify("Upkeep paid. The " .. self:GetHideoutName(entity:GetHideoutKey()) ..
		" is held until " .. os.date("%c", base.upkeepExpires) .. ".")
	self:SyncGroup(groupID)
	return true
end

function PLUGIN:AbandonClaim(client, char, entity)
	local group, groupID = self:GetCharGroup(char)
	if not group then return end
	if group.leaderID ~= char:GetID() then
		client:Notify("Only the group leader may abandon the hideout.")
		return
	end

	local baseKey = self:GetBaseKey(entity)
	local base    = self.bases[baseKey]
	if not base or base.ownerGroupID ~= groupID then
		client:Notify("Your group does not own this hideout.")
		return
	end

	self:Unclaim(baseKey, false, "Your group has abandoned its hideout.")
	client:Notify("You have abandoned the " .. self:GetHideoutName(entity:GetHideoutKey()) .. ".")
	return true
end

-- Releases a base claim. skipGroupSync avoids redundant work during DeleteGroup.
-- reason overrides the member notification (defaults to the upkeep-lapsed message).
function PLUGIN:Unclaim(baseKey, skipGroupSync, reason)
	local base = self.bases[baseKey]
	if not base then return end

	local groupID = base.ownerGroupID
	self.bases[baseKey] = nil
	self:SaveBases()

	local group = groupID and self.groups[groupID]
	if group then
		group.baseKey = nil
		self:SaveGroups()

		for _, charID in ipairs(group.members) do
			self:SetMemberClass(charID, nil)
			local mp = onlinePlayer(charID)
			if IsValid(mp) then mp:Notify(reason or "Your group has lost its hideout — upkeep lapsed.") end
		end

		if not skipGroupSync then self:SyncGroup(groupID) end
	end
end

-- ── Base management menu ──────────────────────────────────────────────────────

-- Builds the state snapshot a client needs to render the management popup.
function PLUGIN:GetBaseState(char, entity)
	local group, groupID = self:GetCharGroup(char)
	local baseKey = self:GetBaseKey(entity)
	local base    = self.bases[baseKey]
	local now     = os.time()

	local claimed   = (base and base.ownerGroupID and base.upkeepExpires > now) and true or false
	local ownedByUs = (claimed and group and base.ownerGroupID == groupID) and true or false
	local isLeader  = (group and group.leaderID == char:GetID()) and true or false

	local ownerName
	if claimed then
		local owner = self.groups[base.ownerGroupID]
		ownerName = owner and owner.name or "another group"
	end

	-- Determine whether this character may claim (unclaimed bases only)
	local canClaim, claimReason = false, ""
	if not claimed then
		if not group then
			claimReason = "You must be in a group to claim."
		elseif not isLeader then
			claimReason = "Only your group leader can claim."
		elseif group.baseKey then
			claimReason = "Your group already holds a hideout."
		else
			canClaim = true
		end
	end

	-- Upkeep is blocked once stockpiled to the cap
	local atMax = false
	if ownedByUs and base then
		atMax = base.upkeepExpires >= now + ix.config.Get("gangUpkeepMax", 259200)
	end

	return {
		hideoutName    = self:GetHideoutName(entity:GetHideoutKey()),
		claimed        = claimed,
		ownedByUs      = ownedByUs,
		ownerName      = ownerName,
		upkeepExpires  = (base and base.upkeepExpires) or 0,
		claimCost      = ix.config.Get("gangClaimCost", 250),
		upkeepCost     = ix.config.Get("gangUpkeepCost", 100),
		upkeepMax      = ix.config.Get("gangUpkeepMax", 259200),
		canClaim       = canClaim,
		claimReason    = claimReason,
		canUpkeep      = ownedByUs and not atMax,
		upkeepAtMax    = atMax,
		canAbandon     = ownedByUs and isLeader,
	}
end

function PLUGIN:SendBaseState(client, entity)
	if not IsValid(entity) then return end
	local char = client:GetCharacter()
	if not char then return end
	net.Start("ixGangBaseOpen")
		net.WriteEntity(entity)
		net.WriteTable(self:GetBaseState(char, entity))
	net.Send(client)
end

function PLUGIN:OpenBaseMenu(client, entity)
	client.ixGangBaseEnt = entity
	self:SendBaseState(client, entity)
end

-- Resolves the entity a client is acting on, enforcing the interaction range.
local function actionEntity(client)
	local ent = client.ixGangBaseEnt
	if not IsValid(ent) then return nil end
	local range = ix.config.Get("gangBaseRange", 96)
	if client:GetPos():DistToSqr(ent:GetPos()) > range ^ 2 then return nil end
	return ent
end

net.Receive("ixGangBaseClaim", function(_, client)
	local ent = actionEntity(client)
	if not ent then return end
	local char = client:GetCharacter()
	if not char then return end
	PLUGIN:ClaimBase(client, char, ent)
	PLUGIN:SendBaseState(client, ent)
end)

net.Receive("ixGangBaseUpkeep", function(_, client)
	local ent = actionEntity(client)
	if not ent then return end
	local char = client:GetCharacter()
	if not char then return end
	PLUGIN:PayUpkeep(client, char, ent)
	PLUGIN:SendBaseState(client, ent)
end)

net.Receive("ixGangBaseAbandon", function(_, client)
	local ent = actionEntity(client)
	if not ent then return end
	local char = client:GetCharacter()
	if not char then return end
	PLUGIN:AbandonClaim(client, char, ent)
	PLUGIN:SendBaseState(client, ent)
end)

-- ── Upkeep expiry timer ───────────────────────────────────────────────────────

function PLUGIN:StartUpkeepTimer()
	timer.Create("ixGangUpkeep", ix.config.Get("gangUpkeepCheckInterval", 60), 0, function()
		local now = os.time()
		for baseKey, base in pairs(table.Copy(self.bases)) do
			if base.ownerGroupID and base.upkeepExpires <= now then
				self:Unclaim(baseKey, false)
			end
		end
	end)
end

-- ── Forced class provider ─────────────────────────────────────────────────────

-- Answered by the central class resolver (perma_class) on character load. Returns
-- the hideout class a character must hold while their group's claim is live, or
-- nil. Also heals stale references encountered along the way.
function PLUGIN:GetForcedClass(client, character)
	local groupID = character:GetData("groupID")
	if not groupID then return end

	local group = self.groups[groupID]
	if not group then
		character:SetData("groupID", nil)   -- orphaned reference
		character:Save()
		return
	end

	if not group.baseKey then return end

	local base = self.bases[group.baseKey]
	if not base or base.ownerGroupID ~= groupID or base.upkeepExpires <= os.time() then
		-- Claim expired or was lost while offline
		group.baseKey = nil
		self:SaveGroups()
		return
	end

	return self:GetHideoutClass(base.hideout)
end

-- ── Permadeath ────────────────────────────────────────────────────────────────

hook.Add("PlayerDeath", "ixGangPermakill", function(ply)
	timer.Simple(0, function()
		if not IsValid(ply) then return end
		local char = ply:GetCharacter()
		if not char or not char:GetData("permakilled", false) then return end
		PLUGIN:RemoveMember(char:GetID(), true)
	end)
end)

-- ── Client sync ───────────────────────────────────────────────────────────────

-- Builds the snapshot a client needs to render the tab for their group.
function PLUGIN:BuildSyncPayload(groupID)
	local group = self.groups[groupID]
	if not group then return nil end

	local members = {}
	for _, charID in ipairs(group.members) do
		local char = loadedChar(charID)
		members[#members + 1] = {
			id     = charID,
			name   = char and char:GetName() or ("Character #" .. charID),
			online = onlinePlayer(charID) ~= nil,
		}
	end

	local baseName, upkeepExpires
	if group.baseKey then
		local base = self.bases[group.baseKey]
		if base then
			upkeepExpires = base.upkeepExpires
			baseName      = self:GetHideoutName(base.hideout)
		end
	end

	return {
		groupID       = groupID,
		name          = group.name,
		leaderID      = group.leaderID,
		successorID   = group.successorID,
		members       = members,
		baseName      = baseName,
		upkeepExpires = upkeepExpires,
	}
end

function PLUGIN:SyncToPlayer(ply, groupID)
	if not IsValid(ply) then return end
	local payload = groupID and self:BuildSyncPayload(groupID) or nil
	net.Start("ixGangSync")
		net.WriteBool(payload ~= nil)
		if payload then net.WriteTable(payload) end
	net.Send(ply)
end

-- Pushes fresh state to every online member of a group.
function PLUGIN:SyncGroup(groupID)
	local group = self.groups[groupID]
	if not group then return end
	for _, charID in ipairs(group.members) do
		local mp = onlinePlayer(charID)
		if IsValid(mp) then self:SyncToPlayer(mp, groupID) end
	end
end

-- ── Net receivers ─────────────────────────────────────────────────────────────

net.Receive("ixGangCreate", function(_, client)
	local char = client:GetCharacter()
	if not char then return end
	if PLUGIN:GetCharGroup(char) then
		client:Notify("You are already in a group.")
		return
	end

	local name = string.Trim(net.ReadString())
	if #name < 3 or #name > 32 then
		client:Notify("Group name must be 3-32 characters.")
		return
	end

	local groupID = PLUGIN:CreateGroup(char, name)
	client:Notify("Group '" .. name .. "' created.")
	PLUGIN:SyncToPlayer(client, groupID)
end)

net.Receive("ixGangLeave", function(_, client)
	local char = client:GetCharacter()
	if not char then return end
	local group = PLUGIN:GetCharGroup(char)
	if not group then return end

	PLUGIN:RemoveMember(char:GetID(), false)
	client:Notify("You have left the group.")
	PLUGIN:SyncToPlayer(client, nil)
end)

net.Receive("ixGangDisband", function(_, client)
	local char = client:GetCharacter()
	if not char then return end
	local group, groupID = PLUGIN:GetCharGroup(char)
	if not group then return end
	if group.leaderID ~= char:GetID() then
		client:Notify("Only the leader can disband the group.")
		return
	end

	-- Notify all members before teardown
	for _, charID in ipairs(group.members) do
		local mp = onlinePlayer(charID)
		if IsValid(mp) then
			mp:Notify("Your group has been disbanded.")
			PLUGIN:SyncToPlayer(mp, nil)
		end
	end

	PLUGIN:DeleteGroup(groupID)
end)

net.Receive("ixGangInvite", function(_, client)
	local char = client:GetCharacter()
	if not char then return end
	local group, groupID = PLUGIN:GetCharGroup(char)
	if not group then return end
	if group.leaderID ~= char:GetID() then
		client:Notify("Only the leader can invite.")
		return
	end
	if #group.members >= ix.config.Get("gangMaxMembers", 8) then
		client:Notify("Your group is full.")
		return
	end

	local target = net.ReadEntity()
	if not IsValid(target) or not target:IsPlayer() then return end
	local tchar = target:GetCharacter()
	if not tchar then return end
	if PLUGIN:GetCharGroup(tchar) then
		client:Notify("That player is already in a group.")
		return
	end

	target.ixGangInviteFrom = groupID
	target.ixGangInviteExpires = os.time() + 30

	net.Start("ixGangInvitePrompt")
		net.WriteString(group.name)
		net.WriteString(client:Name())
	net.Send(target)

	client:Notify("Invitation sent to " .. target:Name() .. ".")
end)

net.Receive("ixGangInviteResponse", function(_, client)
	local accepted = net.ReadBool()
	local groupID  = client.ixGangInviteFrom
	local expires  = client.ixGangInviteExpires or 0
	client.ixGangInviteFrom = nil
	client.ixGangInviteExpires = nil

	if not accepted then return end
	if os.time() > expires then
		client:Notify("That invitation has expired.")
		return
	end

	local char = client:GetCharacter()
	if not char then return end
	if PLUGIN:GetCharGroup(char) then
		client:Notify("You are already in a group.")
		return
	end

	local group = PLUGIN:GetGroup(groupID)
	if not group then
		client:Notify("That group no longer exists.")
		return
	end

	local ok, reason = PLUGIN:AddMember(groupID, char:GetID())
	if not ok then
		client:Notify(reason == "full" and "That group is now full." or "Could not join the group.")
		return
	end
	client:Notify("You joined " .. group.name .. ".")
	PLUGIN:SyncToPlayer(client, groupID)
end)

net.Receive("ixGangKick", function(_, client)
	local char = client:GetCharacter()
	if not char then return end
	local group, groupID = PLUGIN:GetCharGroup(char)
	if not group then return end
	if group.leaderID ~= char:GetID() then
		client:Notify("Only the leader can kick members.")
		return
	end

	local targetID = net.ReadUInt(32)
	if targetID == char:GetID() then
		client:Notify("You cannot kick yourself. Disband or leave instead.")
		return
	end

	-- Confirm the target is actually in this group
	local inGroup = false
	for _, mid in ipairs(group.members) do
		if mid == targetID then inGroup = true break end
	end
	if not inGroup then return end

	PLUGIN:RemoveMember(targetID, false)
	local tp = onlinePlayer(targetID)
	if IsValid(tp) then
		tp:Notify("You have been removed from " .. group.name .. ".")
		PLUGIN:SyncToPlayer(tp, nil)
	end
	client:Notify("Member removed.")
end)

net.Receive("ixGangSetSuccessor", function(_, client)
	local char = client:GetCharacter()
	if not char then return end
	local group, groupID = PLUGIN:GetCharGroup(char)
	if not group then return end
	if group.leaderID ~= char:GetID() then
		client:Notify("Only the leader can set a successor.")
		return
	end

	local targetID = net.ReadUInt(32)
	if targetID == char:GetID() then
		client:Notify("You cannot designate yourself.")
		return
	end

	local inGroup = false
	for _, mid in ipairs(group.members) do
		if mid == targetID then inGroup = true break end
	end
	if not inGroup then return end

	group.successorID = targetID
	PLUGIN:SaveGroups()
	client:Notify("Successor designated.")
	PLUGIN:SyncGroup(groupID)
end)

net.Receive("ixGangRequestSync", function(_, client)
	local char = client:GetCharacter()
	if not char then
		PLUGIN:SyncToPlayer(client, nil)
		return
	end
	local _, groupID = PLUGIN:GetCharGroup(char)
	PLUGIN:SyncToPlayer(client, groupID)
end)
