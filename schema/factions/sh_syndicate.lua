
FACTION.name = "Syndicate"
FACTION.description = "A shadowy network of traders, fixers and opportunists who profit from the metro's chaos."
FACTION.isDefault = false
FACTION.color = Color(72, 110, 105)
FACTION.models = {
"models/half-dead/metroll/a1b1.mdl",
"models/half-dead/metroll/a2b1.mdl",
"models/half-dead/metroll/a3b1.mdl",
"models/half-dead/metroll/a4b1.mdl",
"models/half-dead/metroll/a5b1.mdl",
}

FACTION_SYNDICATE = FACTION.index

function FACTION:OnSpawn(client)
	client:SetMaxArmor(0)
end
