local PLUGIN = PLUGIN

PLUGIN.name        = "Skills"
PLUGIN.author      = "metro2033"
PLUGIN.description = "Usage-based crafting skills (Engineering / Tailoring / Chemistry) with a dynamic cap and an attribute-point pool."

-- ── Config ────────────────────────────────────────────────────────────────────

ix.config.Add("skillMigrateLegacy", true,
	"Seed a character's new skill levels from their old craft-attribute values the first time they load.", nil, {
		category = PLUGIN.name,
	})

-- ── Network strings ───────────────────────────────────────────────────────────
--
-- Skill data itself rides the built-in isLocal character-var networking
-- (ixCharacterVarChanged). These two only carry the spend request and a
-- lightweight "your skills changed, refresh the panel" nudge.

if (SERVER) then
	util.AddNetworkString("ixSkillSpendPoint")
	util.AddNetworkString("ixSkillSync")
end

-- Everything else auto-loads from libs/ (shared + server API), derma/ (the tab)
-- and languages/. See libs/sh_skill.lua for the ix.skill API.
