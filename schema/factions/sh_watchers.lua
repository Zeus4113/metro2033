
FACTION.name = "Invisible Watchers"
FACTION.description = "Those who observe from the shadows, keeping order in a world that does not know they exist."
FACTION.isDefault = false
FACTION.color = Color(60, 50, 75)
FACTION.models = {
"models/half-dead/metroll/a1b1.mdl",
"models/half-dead/metroll/a2b1.mdl",
"models/half-dead/metroll/a3b1.mdl",
"models/half-dead/metroll/a4b1.mdl",
"models/half-dead/metroll/a5b1.mdl",
}

FACTION_WATCHERS = FACTION.index

local WATCHER_FLAGS = "Cccentrpsw"

function FACTION:OnCharacterCreated(_, character)
	character:GiveFlags(WATCHER_FLAGS)
end

function FACTION:OnSpawn(client)
	client:SetMaxArmor(0)
end

-- Catches existing characters transferred into this faction.
hook.Add("PlayerLoadedCharacter", "WatchersGrantFlags", function(_, character)
	if character:GetFaction() == FACTION_WATCHERS then
		character:GiveFlags(WATCHER_FLAGS)
	end
end)
