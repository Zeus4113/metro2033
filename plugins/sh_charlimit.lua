local PLUGIN = PLUGIN

PLUGIN.name = "Character Limit"
PLUGIN.author = "Kai Stevens"
PLUGIN.description = "Sets per-player character limits based on admin status."

ix.config.Add("maxCharactersPlayer", 1, "Maximum number of characters a normal player can have.", nil, {
	data = {min = 1, max = 50},
	category = "characters"
})

ix.config.Add("maxCharactersAdmin", 3, "Maximum number of characters an admin can have.", nil, {
	data = {min = 1, max = 50},
	category = "characters"
})

function PLUGIN:GetMaxPlayerCharacter(client)
	if client:IsAdmin() then
		return ix.config.Get("maxCharactersAdmin", 3)
	end

	return ix.config.Get("maxCharactersPlayer", 1)
end
