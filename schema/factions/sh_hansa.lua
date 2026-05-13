
FACTION.name = "Hansa"
FACTION.description = "The Hanseatic League — a powerful ring of prosperous stations that controls the lifeblood of the metro's trade routes."
FACTION.isDefault = false
FACTION.color = Color(180, 140, 40)
FACTION.models = {
"models/half-dead/metroll/a1b1.mdl",
"models/half-dead/metroll/a2b1.mdl",
"models/half-dead/metroll/a3b1.mdl",
"models/half-dead/metroll/a4b1.mdl",
"models/half-dead/metroll/a5b1.mdl",
}

FACTION_HANSA = FACTION.index

function FACTION:OnSpawn(client)
	client:SetMaxArmor(0)
end
