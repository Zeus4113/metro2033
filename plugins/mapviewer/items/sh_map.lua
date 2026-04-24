ITEM.name = "Map"
ITEM.description = "A detailed map of the metro. Use it to view your surroundings."
ITEM.category = "Gadgets"

-- Use a PDA-like model or another suitable model
ITEM.model = "models/spec45as/stalker/items/pda.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.weight = 0.5
ITEM.price = 50

-- Icon camera settings (optional - for inventory icon preview)
ITEM.iconCam = {
	pos = Vector(0, 0, 200),
	ang = Angle(90, 0, 0),
	fov = 3.79
}

-- Hook: When the item is used/activated
ITEM:Hook("use", function(item)
	local client = item:GetOwner()
	
	-- Only run on client
	if not IsValid(client) or SERVER then
		return
	end

	-- Define your map image path here
	-- Make sure the image is in: garrysmod/materials/
	local mapImage = "materials/metro2033/map_station.png"
	
	-- Send message to client to open the map viewer
	net.Start("OpenMapViewer")
	net.WriteUInt(item:GetID(), 16)
	net.WriteString(mapImage)
	net.WriteString("Metro Map")
	net.SendToServer()
end)

-- Alternative: Using a custom use action on right-click
ITEM:Hook("use", function(item)
	if not IsValid(item:GetOwner()) then
		return false
	end
	
	-- The item can be used by the owner
	return true
end)
