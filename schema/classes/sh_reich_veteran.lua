CLASS.name = "Reich Veteran"
CLASS.faction = FACTION_FOURTH_REICH
CLASS.isDefault = false
CLASS_REICH_VETERAN = CLASS.index

function CLASS:CanSwitchTo(client)
    return client:HasClassWhitelist(self.index)
end

function CLASS:OnCanBe(client)
    return false
end
