CLASS.name = "Red Line Veteran"
CLASS.faction = FACTION_REDLINE
CLASS.isDefault = false
CLASS_REDLINE_VETERAN = CLASS.index

function CLASS:CanSwitchTo(client)
    return client:HasClassWhitelist(self.index)
end

function CLASS:OnCanBe(client)
    return false
end
