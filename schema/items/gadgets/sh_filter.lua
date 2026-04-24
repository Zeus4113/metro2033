ITEM.name = "Gasmask Filter"
ITEM.category = "Consumable"


ITEM.model = "models/teebeutel/metro/objects/gasmask_filter.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.iconCam = {
	pos = Vector(0, 0, 200),
	ang = Angle(90, 0, 0),
	fov = 2.72
}

ITEM.filterAmount = 300
ITEM.price = 10
ITEM.weight = 0.5

ITEM.functions.Insert = {
    name = "Insert into Mask",
    OnRun = function(item)
        local client = item.player
        local char = client:GetCharacter()

        local equipment = char:GetData("equipment", {})
        local maskID = equipment["Helmet"]

        if not maskID then
            client:Notify("You are not wearing a gasmask.")
            return false
        end

        local mask = ix.item.instances[maskID]
        if not mask or not mask.isGasmask then
            client:Notify("You are not wearing a gasmask.")
            return false
        end

        local maxTime = mask.maxFilterTime or 0
        local current = mask:GetData("filterTime", 0)

        if current >= maxTime then
            client:Notify("Your gasmask is already full.")
            return false
        end

        mask:SetData("filterTime", math.min(current + item.filterAmount, maxTime))

        client:EmitSound("metro2033/interface/gasmask/change_filter.ogg")

        return true
    end
}

