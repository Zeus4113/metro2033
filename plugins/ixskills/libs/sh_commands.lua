-- Admin commands for inspecting/adjusting skills. Modelled on the core
-- CharSetAttribute / CharAddAttribute commands.

-- Resolves a typed name to a skill id, matching either the id ("engineering")
-- or the display name ("Engineering"). Returns id, display.
local function resolveSkill(name)
	for id, display in pairs(ix.skill.list) do
		if (ix.util.StringMatches(display, name) or ix.util.StringMatches(id, name)) then
			return id, display
		end
	end
end

ix.command.Add("CharSetSkill", {
	description = "@cmdCharSetSkill",
	privilege = "Manage Skills",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.string,
		ix.type.number
	},
	OnRun = function(self, client, target, skillName, level)
		local id, display = resolveSkill(skillName)

		if (!id) then
			return "@skillNotFound"
		end

		-- SetLevel clamps to the skill's current cap and returns what it applied,
		-- so an admin can't push a skill past its cap.
		local applied = ix.skill.SetLevel(target, id, math.floor(level))

		return "@skillSet", target:GetName(), display, math.floor(applied or 0)
	end
})

ix.command.Add("CharSetSkillPoints", {
	description = "@cmdCharSetSkillPoints",
	privilege = "Manage Skills",
	adminOnly = true,
	arguments = {
		ix.type.character,
		ix.type.string,
		ix.type.number
	},
	OnRun = function(self, client, target, skillName, points)
		local id, display = resolveSkill(skillName)

		if (!id) then
			return "@skillNotFound"
		end

		points = math.Clamp(math.floor(points), 0, ix.skill.MAX_POINTS_PER_SKILL)
		ix.skill.SetPointsSpent(target, id, points)

		return "@skillPointsSet", target:GetName(), display, points, ix.skill.GetCap(target, id)
	end
})

ix.command.Add("CharResetSkills", {
	description = "@cmdCharResetSkills",
	privilege = "Manage Skills",
	adminOnly = true,
	arguments = {
		ix.type.character
	},
	OnRun = function(self, client, target)
		ix.skill.Reset(target)

		return "@skillsReset", target:GetName()
	end
})
