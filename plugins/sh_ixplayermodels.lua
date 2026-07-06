local PLUGIN = PLUGIN

PLUGIN.name = "IX Player Models Fix"
PLUGIN.author = "Masco"
PLUGIN.description = "Fixes models in IX to make Player Models."

ix.anim.SetModelClass("models/player/Group01/male_01.mdl", "player")
ix.anim.SetModelClass("models/player/Group01/male_02.mdl", "player")
ix.anim.SetModelClass("models/player/Group01/male_03.mdl", "player")
ix.anim.SetModelClass("models/player/Group01/male_04.mdl", "player")
ix.anim.SetModelClass("models/player/Group01/male_05.mdl", "player")
ix.anim.SetModelClass("models/player/Group01/male_06.mdl", "player")
ix.anim.SetModelClass("models/player/Group01/male_07.mdl", "player")
ix.anim.SetModelClass("models/player/Group01/male_08.mdl", "player")
ix.anim.SetModelClass("models/player/Group01/male_09.mdl", "player")
ix.anim.SetModelClass("models/player/Group03m/male_01.mdl", "player")
ix.anim.SetModelClass("models/player/Group03m/male_02.mdl", "player")
ix.anim.SetModelClass("models/player/Group03m/male_03.mdl", "player")
ix.anim.SetModelClass("models/player/Group03m/male_04.mdl", "player")
ix.anim.SetModelClass("models/player/Group03m/male_05.mdl", "player")
ix.anim.SetModelClass("models/player/Group03m/male_06.mdl", "player")
ix.anim.SetModelClass("models/player/Group03m/male_07.mdl", "player")
ix.anim.SetModelClass("models/player/Group03m/male_08.mdl", "player")
ix.anim.SetModelClass("models/player/Group03m/male_09.mdl", "player")

-- Model-pack folders whose contents should use the "player" animation class.
-- Kept here (schema) rather than in the Helix base so base updates don't clobber it.
local playerModelFolders = {
	"/randomguy",
	"/stlkrenegadaski",
	"/catnike",
	"/metroll",
	"/hassty",
	"/survivors",
	"/ganza",
	"/redlines",
	"/reich",
}

local baseGetModelClass = ix.anim.GetModelClass

function ix.anim.GetModelClass(model)
	local lowered = string.lower(model)

	for i = 1, #playerModelFolders do
		if (string.find(lowered, playerModelFolders[i], 1, true)) then
			return "player"
		end
	end

	return baseGetModelClass(model)
end
