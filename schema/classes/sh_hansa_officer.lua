CLASS.name = "Hansa Officer"
CLASS.faction = FACTION_HANSA
CLASS.isDefault = false
CLASS_HANSA_OFFICER = CLASS.index

function CLASS:CanSwitchTo(client)
    return client:HasClassWhitelist(self.index)
end

function CLASS:OnCanBe(client)
    return false
end
