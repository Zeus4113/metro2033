
ITEM.name = "Flashlight"
ITEM.model = Model("models/wick/wrbstalker/anomaly/items/wick_dev_flashlight.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A standard flashlight that can be toggled."
ITEM.category = "Tools"
ITEM.weight = 0.5

ITEM:Hook("drop", function(item)
	item.player:Flashlight(false)
end)
