ITEM.name = "Anti Radiation Pills"
ITEM.model = "models/wick/wrbstalker/anomaly/items/wick_dev_antirad.mdl"
ITEM.description = "Specialized medication designed to reduce radiation poisoning using refined chemical compounds."

ITEM.width = 1
ITEM.height = 1
ITEM.weight = 0.1
ITEM.price = 61

ITEM.thirst = 0
ITEM.hunger = 0
ITEM.radiation = -300
ITEM.health = 0

ITEM.duration = 50

ITEM.functions.Consume = {
    name = "Use",
    OnRun = function(item)

        local character = item.player:GetCharacter()
        if not character then return end

        item.player:EmitSound("items/medshot4.wav")

        item:HandleConsume(character, item)

        return true
    end
}