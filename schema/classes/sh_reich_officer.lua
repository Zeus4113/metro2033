CLASS.name = "Reich Officer"
CLASS.faction = FACTION_FOURTH_REICH
CLASS.isDefault = false
CLASS_REICH_OFFICER = CLASS.index

function CLASS:CanSwitchTo(client)
    return client:HasClassWhitelist(self.index)
end

function CLASS:OnCanBe(client)
    return false
end
