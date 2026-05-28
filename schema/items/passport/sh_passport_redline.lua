ITEM.base = "base_passport"
ITEM.name = "Redline Passport"
ITEM.description = "An official Redline travel document. Required to pass through Redline-controlled checkpoints."
ITEM.model = "models/cmz/passport/redline.mdl"

ITEM.passportKey = "redline"
ITEM.passportColor = Color(180, 30, 30)
ITEM.passportColorLight = Color(220, 110, 110)
ITEM.passportFactionLabel = "Red Line"

function ITEM:PassportCanIssue(char)
	local class = char:GetClass()
	return class == CLASS_REDLINE_OFFICER or class == CLASS_REDLINE_SERGEANT
end
