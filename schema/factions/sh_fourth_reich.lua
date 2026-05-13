
FACTION.name = "Fourth Reich"
FACTION.description = "Fanatical soldiers of a reborn fascist order, carving out iron-fisted dominion over their stations and waging war on all they deem unworthy of survival."
FACTION.isDefault = false
FACTION.color = Color(45, 45, 45)
FACTION.models = {
"models/half-dead/metroll/a1b1.mdl",
"models/half-dead/metroll/a2b1.mdl",
"models/half-dead/metroll/a3b1.mdl",
"models/half-dead/metroll/a4b1.mdl",
"models/half-dead/metroll/a5b1.mdl",
}

FACTION_FOURTH_REICH = FACTION.index

function FACTION:OnSpawn(client)
	client:SetMaxArmor(0)
end
