PLUGIN.name = "SWEP & SENT Flags"
PLUGIN.author = "BarneyTheBandit"
PLUGIN.description = "Flag for spawning weapons through the Q menu."

ix.flag.Add("w", "Access to spawn weapons.")
ix.flag.Add("s", "Access to spawn entities.")

hook.Add("PlayerSpawnSENT", "FlagCheck", function(client, class)

	if not client:GetChar():HasFlags("s") then
		return false
	end

	return true
end)

hook.Add( "PlayerGiveSWEP", "FlagCheck", function(client, weapon, spawnInfo)

	if not client:GetChar():HasFlags("w") then
		return false
	end

	return true
end)

hook.Add("PlayerSpawnSWEP", "FlagCheck", function(client, weapon, swep)


	if not client:GetChar():HasFlags("w") then
		return false
	end

	return true
end)