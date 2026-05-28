CLASS.name = "Hansa Stalker"
CLASS.faction = FACTION_HANSA
CLASS.isDefault = false
CLASS_HANSA_STALKER = CLASS.index

function CLASS:CanSwitchTo(client)
    return client:HasClassWhitelist(self.index)
end

function CLASS:OnCanBe(client)
    return false
end
