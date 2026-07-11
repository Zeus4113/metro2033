-- ix.skill — usage-based crafting skills with a dynamic cap + attribute-point pool.
-- Shared realm: constants, the skill registry, character-var storage, and all
-- read-only accessors. Server-only mutators (AddXP / SpendPoint) live in sv_skill.lua.

ix.skill = ix.skill or {}

-- ── Constants ─────────────────────────────────────────────────────────────────
ix.skill.BASE_CAP             = 10   -- starting cap before any points are spent
ix.skill.HARD_CEILING         = 20   -- absolute maximum level for any skill
ix.skill.CAP_PER_POINT        = 2.5  -- cap increase per attribute point spent
ix.skill.LEVELS_PER_POINT     = 5    -- combined skill levels needed to earn one point
ix.skill.MAX_POINTS           = 6    -- total attribute points obtainable
ix.skill.MAX_POINTS_PER_SKILL = 4    -- 4 * 2.5 spans the whole 10→20 range; a 5th would be wasted

-- id → display name. The id is the lowercased recipe skill key, so a recipe's
-- RECIPE.skills = {["Engineering"] = 17} maps straight through via string.lower.
ix.skill.list = {
	engineering = "Engineering",
	tailoring   = "Tailoring",
	chemistry   = "Chemistry",
}

-- ── Tiers (display/flavour) ───────────────────────────────────────────────────
-- Each entry: { minLevel, name }. Resolved on math.floor(level).
ix.skill.tiers = {
	{ 0,  "Novice" },
	{ 5,  "Trained" },
	{ 10, "Skilled" },
	{ 15, "Expert" },
	{ 20, "Master" },
}

function ix.skill.IsValid(id)
	return ix.skill.list[id] ~= nil
end

-- ── Accessors (read-only, shared) ─────────────────────────────────────────────

-- Current level of a skill (fractional). Unknown id → 0.
function ix.skill.Get(character, id)
	if (!character or !ix.skill.list[id]) then return 0 end
	return character:GetSkills()[id] or 0
end

-- Attribute points already allocated to a skill's cap. Unknown id → 0.
function ix.skill.GetPointsSpent(character, id)
	if (!character or !ix.skill.list[id]) then return 0 end
	return character:GetSkillPointsSpent()[id] or 0
end

-- Current cap for a skill given the points spent on it: 10 / 12.5 / 15 / 17.5 / 20.
function ix.skill.GetCap(character, id)
	local spent = ix.skill.GetPointsSpent(character, id)
	return math.min(ix.skill.BASE_CAP + ix.skill.CAP_PER_POINT * spent, ix.skill.HARD_CEILING)
end

-- Sum of the three current skill levels (floored — the point economy runs on
-- whole levels, so fractional XP never nudges a point boundary early).
function ix.skill.GetTotal(character)
	local total = 0

	for id in pairs(ix.skill.list) do
		total = total + math.floor(ix.skill.Get(character, id))
	end

	return total
end

-- Attribute points earned so far, capped at the pool maximum.
function ix.skill.GetEarnedPoints(character)
	return math.min(math.floor(ix.skill.GetTotal(character) / ix.skill.LEVELS_PER_POINT), ix.skill.MAX_POINTS)
end

-- Attribute points already allocated, summed across all skills.
function ix.skill.GetSpentPoints(character)
	local spent = 0

	for id in pairs(ix.skill.list) do
		spent = spent + ix.skill.GetPointsSpent(character, id)
	end

	return spent
end

-- Points available to spend.
function ix.skill.GetUnspentPoints(character)
	return ix.skill.GetEarnedPoints(character) - ix.skill.GetSpentPoints(character)
end

-- Tier index (1–5) for a raw level.
function ix.skill.GetTier(level)
	local floored = math.floor(level or 0)
	local tier = 1

	for i, info in ipairs(ix.skill.tiers) do
		if (floored >= info[1]) then
			tier = i
		end
	end

	return tier
end

-- Human-readable tier label for a raw level (phrase-backed, e.g. "@skillTierNovice").
function ix.skill.GetTierName(level)
	return ix.skill.tiers[ix.skill.GetTier(level)][2]
end

-- ── Storage (character vars) ──────────────────────────────────────────────────
-- Both are field-backed JSON tables, networked to the owner only. No OnDisplay,
-- so they never appear in character creation.

ix.char.RegisterVar("skills", {
	field = "skills",
	fieldType = ix.type.text,
	default = {},
	isLocal = true,
	bNoDisplay = true,
})

ix.char.RegisterVar("skillPointsSpent", {
	field = "skill_points_spent",
	fieldType = ix.type.text,
	default = {},
	isLocal = true,
	bNoDisplay = true,
})
