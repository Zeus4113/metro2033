CLASS.name = "Red Line Sergeant"
CLASS.faction = FACTION_REDLINE
CLASS.isDefault = false
CLASS_REDLINE_SERGEANT = CLASS.index

function CLASS:CanSwitchTo(client)
    return client:HasClassWhitelist(self.index)
end

function CLASS:OnCanBe(client)
    return false
end
