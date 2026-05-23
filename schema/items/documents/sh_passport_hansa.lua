ITEM.base = "base_passport"
ITEM.name = "Hansa Passport"
ITEM.description = "An official Hansa Commonwealth travel document. Required to pass through Hansa-controlled checkpoints."
ITEM.model = "models/cmz/passport/hansa.mdl"

ITEM.passportKey = "hansa"
ITEM.passportColor = Color(212, 175, 55)
ITEM.passportColorLight = Color(240, 210, 120)
ITEM.passportFactionLabel = "Hanseatic League"

function ITEM:PassportCanIssue(char)
	local class = char:GetClass()
	return class == CLASS_HANSA_OFFICER or class == CLASS_HANSA_SERGEANT
end
