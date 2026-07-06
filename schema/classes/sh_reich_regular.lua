CLASS.name      = "Reich Regular"
CLASS.faction   = FACTION_FOURTH_REICH
CLASS.isDefault = false
CLASS_REICH_REGULAR = CLASS.index

-- Force-set by reputation; not manually selectable.
function CLASS:CanSwitchTo(client)
	return false
end

function CLASS:OnCanBe(client)
	return false
end
