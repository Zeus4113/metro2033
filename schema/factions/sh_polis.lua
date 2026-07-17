
FACTION.name = "Rangers of the Order"
FACTION.description = "The Order of Spartans — Polis's elite sentinels. Sworn to safeguard the last bastion of knowledge in the metro, they answer only to the Council and take the field where lesser soldiers would not dare."
FACTION.isDefault = false
FACTION.color = Color(70, 110, 140)
FACTION.models = {
"models/half-dead/metroll/a1b1.mdl",
"models/half-dead/metroll/a2b1.mdl",
"models/half-dead/metroll/a3b1.mdl",
"models/half-dead/metroll/a4b1.mdl",
"models/half-dead/metroll/a5b1.mdl",
}

FACTION_POLIS = FACTION.index

function FACTION:OnSpawn(client)
	client:SetMaxArmor(0)
end
