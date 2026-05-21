
FACTION.name = "Red Line"
FACTION.description = "Soldiers of the Communist state reborn beneath the earth — disciplined, fanatical, and convinced that the metro's salvation lies in total collectivism."
FACTION.isDefault = false
FACTION.color = Color(190, 25, 25)
FACTION.models = {
"models/half-dead/metroll/a1b1.mdl",
"models/half-dead/metroll/a2b1.mdl",
"models/half-dead/metroll/a3b1.mdl",
"models/half-dead/metroll/a4b1.mdl",
"models/half-dead/metroll/a5b1.mdl",
}

FACTION_REDLINE = FACTION.index

function FACTION:OnSpawn(client)
	client:SetMaxArmor(0)
end
