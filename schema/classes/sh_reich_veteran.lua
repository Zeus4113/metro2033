CLASS.name = "Reich Veteran"
CLASS.faction = FACTION_FOURTH_REICH
CLASS.isDefault = false
CLASS_REICH_VETERAN = CLASS.index

-- Force-set by reputation; not manually selectable.
function CLASS:CanSwitchTo(client)
    return false
end

function CLASS:OnCanBe(client)
    return false
end
