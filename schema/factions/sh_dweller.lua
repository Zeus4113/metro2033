
-- You can define factions in the factions/ folder. You need to have at least one faction that is the default faction - i.e the
-- faction that will always be available without any whitelists and etc.

FACTION.name = "Dweller"
FACTION.description = "The lost children of the metro, cursed to wander the grim hellscape they call home."
FACTION.isDefault = true
FACTION.color = Color(104, 138, 76)
FACTION.models = {
"models/half-dead/metroll/a1b1.mdl",
"models/half-dead/metroll/a2b1.mdl",
"models/half-dead/metroll/a3b1.mdl",
"models/half-dead/metroll/a4b1.mdl",
"models/half-dead/metroll/a5b1.mdl",
}

-- You should define a global variable for this faction's index for easy access wherever you need. FACTION.index is
-- automatically set, so you can simply assign the value.

-- Note that the player's team will also have the same value as their current character's faction index. This means you can use
-- client:Team() == FACTION_CITIZEN to compare the faction of the player's current character.

FACTION_DWELLER = FACTION.index

function FACTION:OnCharacterCreated(client, character)
	character:SetData("dwellerModel", character:GetModel())
end

function FACTION:OnSpawn(client)
	client:SetMaxArmor(0)
end