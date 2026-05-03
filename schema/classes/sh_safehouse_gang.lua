CLASS.name = "Safehouse Gang"
CLASS.faction = FACTION_DWELLER
CLASS.isDefault = false
CLASS_SAFEHOUSE = CLASS.index

function CLASS:CanSwitchTo(client)
    return client:HasClassWhitelist(self.index)
end

function CLASS:OnCanBe(client)
	return false
end