ITEM.name = "Kettle"
ITEM.description = "A battered metal pot. Put mushrooms and purified water in it near a fire to brew tea."
ITEM.model = "models/props_interiors/pot01a.mdl"

ITEM.width = 2
ITEM.height = 2
ITEM.weight = 1.5

ITEM.iconCam = {
	pos = Vector(-200, 0, 0),
	ang = Angle(0, 0, 0),
	fov = 4.56
}
ITEM.price = 20

local BREW_DIST_SQR = 150 * 150
local BREW_TIME = 8

ITEM.functions.BrewTea = {
	name = "Brew Tea",
	OnRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		if not char then return false end

		local nearFire = false
		for _, v in pairs(ents.FindByClass("ix_station_cooking_station")) do
			if client:GetPos():DistToSqr(v:GetPos()) <= BREW_DIST_SQR then
				nearFire = true
				break
			end
		end

		if not nearFire then
			client:Notify("You need to be near a fire to brew tea.")
			return false
		end

		local inv = char:GetInventory()
		if not inv then return false end

		local mushroom, water
		for itm in inv:Iter() do
			if itm.uniqueID == "mushroom" and not mushroom then
				mushroom = itm
			elseif itm.uniqueID == "purified_water" and not water then
				water = itm
			end
			if mushroom and water then break end
		end

		if not mushroom then
			client:Notify("You need a mushroom to brew tea.")
			return false
		end

		if not water then
			client:Notify("You need purified water to brew tea.")
			return false
		end

		inv:Remove(mushroom:GetID())
		inv:Remove(water:GetID())

		client:EmitSound("ambient/water/water_flow_loop1.wav", 60, 120, 0.4)
		client:SetAction("Brewing mushroom tea...", BREW_TIME, function()
			if not IsValid(client) then return end
			local success = inv:Add("mushroom_tea")
			if success then
				client:Notify("You brewed a cup of mushroom tea.")
			else
				ix.item.Spawn("mushroom_tea", client:GetPos() + client:GetForward() * 40 + Vector(0, 0, 20))
				client:Notify("You brewed a cup of mushroom tea, but your inventory is full.")
			end
		end)

		return false
	end
}
