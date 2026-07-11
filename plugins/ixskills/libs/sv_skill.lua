-- ix.skill — server authority: mutators, persistence init, and networking.

-- Pushes a lightweight "refresh" nudge to the owner. The skill tables themselves
-- are already synced by the isLocal character-var networking; this just tells an
-- open Skills panel to rebuild.
local function SyncPlayer(character)
	local client = character:GetPlayer()

	if (!IsValid(client)) then return end

	net.Start("ixSkillSync")
	net.Send(client)
end

-- Ensures both storage tables exist with a zeroed entry for every skill. Safe to
-- call repeatedly. On a character's first load it can also seed levels from the
-- old craft-attribute values (pre-ix.skill progression) so nobody loses progress.
function ix.skill.Init(character)
	if (!character) then return end

	local skills = table.Copy(character:GetSkills())
	local spent = table.Copy(character:GetSkillPointsSpent())
	local dirty = false

	local bMigrate = ix.config.Get("skillMigrateLegacy", true) and !character:GetData("ixSkillsMigrated", false)

	for id in pairs(ix.skill.list) do
		if (skills[id] == nil) then
			-- One-time migration: read whatever the legacy attribute column held.
			local legacy = bMigrate and character:GetAttribute(id, 0) or 0
			skills[id] = math.Clamp(legacy, 0, ix.skill.HARD_CEILING)
			dirty = true
		end

		if (spent[id] == nil) then
			spent[id] = 0
			dirty = true
		end
	end

	if (dirty) then
		character:SetSkills(skills)
		character:SetSkillPointsSpent(spent)
	end

	if (bMigrate) then
		character:SetData("ixSkillsMigrated", true)
	end

	-- A migrated legacy level (old cap was a flat 20) can land above the new
	-- dynamic cap, so reconcile every load.
	ix.skill.EnforceCaps(character)
end

-- Adds XP (level) to a skill, clamped to its current cap. Returns true if any
-- level was gained, false (silent no-op) if the skill is invalid or already
-- capped. Fires OnSkillXP always, OnSkillTierUp on a tier crossing, and
-- OnSkillPointEarned when the earned-point count ticks up.
function ix.skill.AddXP(character, id, amount)
	if (!character or !ix.skill.list[id] or !isnumber(amount) or amount <= 0) then
		return false
	end

	local current = ix.skill.Get(character, id)
	local cap = ix.skill.GetCap(character, id)

	if (current >= cap) then
		return false
	end

	local oldTier = ix.skill.GetTier(current)
	local oldPoints = ix.skill.GetEarnedPoints(character)

	local newLevel = math.min(current + amount, cap)

	local skills = table.Copy(character:GetSkills())
	skills[id] = newLevel
	character:SetSkills(skills)

	hook.Run("OnSkillXP", character, id, amount, newLevel)

	local newTier = ix.skill.GetTier(newLevel)

	if (newTier > oldTier) then
		hook.Run("OnSkillTierUp", character, id, oldTier, newTier)
	end

	local newPoints = ix.skill.GetEarnedPoints(character)

	if (newPoints > oldPoints) then
		hook.Run("OnSkillPointEarned", character, ix.skill.GetUnspentPoints(character))
	end

	SyncPlayer(character)

	return true
end

-- Allocates one unspent attribute point to a skill, raising its cap by 2.5.
-- Returns (false, errorPhrase) if there are no unspent points or the skill is
-- already fully maxed (no wasted points). Fires OnSkillCapIncreased on success.
function ix.skill.SpendPoint(character, id)
	if (!character or !ix.skill.list[id]) then
		return false, "@skillInvalid"
	end

	if (ix.skill.GetUnspentPoints(character) < 1) then
		return false, "@skillNoPoints"
	end

	if (ix.skill.GetPointsSpent(character, id) >= ix.skill.MAX_POINTS_PER_SKILL) then
		return false, "@skillAtCeiling"
	end

	local spent = table.Copy(character:GetSkillPointsSpent())
	spent[id] = (spent[id] or 0) + 1
	character:SetSkillPointsSpent(spent)

	hook.Run("OnSkillCapIncreased", character, id, ix.skill.GetCap(character, id))

	SyncPlayer(character)

	return true
end

-- ── Cap enforcement ───────────────────────────────────────────────────────────

-- Clamps every skill level down to its current cap. The single invariant the
-- whole system relies on: a level can never exceed 10 + 2.5 × pointsSpent, no
-- matter how it was set (crafting, skillbook, admin command, or legacy import).
function ix.skill.EnforceCaps(character)
	if (!character) then return false end

	local skills = table.Copy(character:GetSkills())
	local changed = false

	for id in pairs(ix.skill.list) do
		local cap = ix.skill.GetCap(character, id)

		if ((skills[id] or 0) > cap) then
			skills[id] = cap
			changed = true
		end
	end

	if (changed) then
		character:SetSkills(skills)
		SyncPlayer(character)
	end

	return changed
end

-- ── Admin setters (bypass the earn economy, but never the cap) ────────────────

-- Force a skill's level directly, clamped to the skill's current cap. Returns
-- the level that was actually applied.
function ix.skill.SetLevel(character, id, level)
	if (!character or !ix.skill.list[id]) then return false end

	local applied = math.Clamp(tonumber(level) or 0, 0, ix.skill.GetCap(character, id))

	local skills = table.Copy(character:GetSkills())
	skills[id] = applied
	character:SetSkills(skills)

	SyncPlayer(character)

	return applied
end

-- Force the attribute points allocated to a skill (0–4), which sets its cap.
-- Lowering the cap below the current level clamps the level down to match.
function ix.skill.SetPointsSpent(character, id, points)
	if (!character or !ix.skill.list[id]) then return false end

	local spent = table.Copy(character:GetSkillPointsSpent())
	spent[id] = math.Clamp(math.floor(tonumber(points) or 0), 0, ix.skill.MAX_POINTS_PER_SKILL)
	character:SetSkillPointsSpent(spent)

	ix.skill.EnforceCaps(character)
	SyncPlayer(character)

	return true
end

-- Zero every skill level and allocated point.
function ix.skill.Reset(character)
	if (!character) then return false end

	local skills, spent = {}, {}

	for id in pairs(ix.skill.list) do
		skills[id] = 0
		spent[id] = 0
	end

	character:SetSkills(skills)
	character:SetSkillPointsSpent(spent)

	SyncPlayer(character)

	return true
end

-- ── Load hook ─────────────────────────────────────────────────────────────────

hook.Add("PlayerLoadedCharacter", "ixSkillsInit", function(client, character)
	ix.skill.Init(character)
end)

-- ── Spend request from the Skills panel ───────────────────────────────────────

net.Receive("ixSkillSpendPoint", function(length, client)
	local character = client:GetCharacter()

	if (!character) then return end

	local id = net.ReadString()
	local success, err = ix.skill.SpendPoint(character, id)

	if (!success and err) then
		client:NotifyLocalized(err:sub(1, 1) == "@" and err:sub(2) or err)
	end
end)

-- ── Default notifications ─────────────────────────────────────────────────────

hook.Add("OnSkillTierUp", "ixSkillsNotify", function(character, id, oldTier, newTier)
	local client = character:GetPlayer()

	if (!IsValid(client)) then return end

	client:NotifyLocalized("skillTierUp", ix.skill.list[id], ix.skill.tiers[newTier][2])
end)

hook.Add("OnSkillPointEarned", "ixSkillsNotify", function(character, unspent)
	local client = character:GetPlayer()

	if (!IsValid(client)) then return end

	client:NotifyLocalized("skillPointEarned")
end)
