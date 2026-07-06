CLASS.name      = "Red Line Regular"
CLASS.faction   = FACTION_REDLINE
CLASS.isDefault = false
CLASS_REDLINE_REGULAR = CLASS.index

-- Force-set by reputation; not manually selectable.
function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnCanBe(client)
	return false
end
