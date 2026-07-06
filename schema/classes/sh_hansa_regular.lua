CLASS.name      = "Hansa Regular"
CLASS.faction   = FACTION_HANSA
CLASS.isDefault = false
CLASS_HANSA_REGULAR = CLASS.index

-- Force-set by reputation; not manually selectable.
function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnCanBe(client)
	return false
end
