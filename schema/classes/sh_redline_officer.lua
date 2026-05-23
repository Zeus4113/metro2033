CLASS.name = "Red Line Officer"
CLASS.faction = FACTION_REDLINE
CLASS.isDefault = false
CLASS_REDLINE_OFFICER = CLASS.index

function CLASS:CanSwitchTo(client)
    return client:HasClassWhitelist(self.index)
end

function CLASS:OnCanBe(client)
    return false
end
