local PLUGIN = PLUGIN

-- Map viewer frame
local mapFrame = nil

-- Function to open the map viewer
local function OpenMapViewer(imagePath, title)
	if IsValid(mapFrame) then
		mapFrame:Remove()
	end

	mapFrame = vgui.Create("DFrame")
	mapFrame:SetTitle(title or "Map")
	mapFrame:SetSize(800, 600)
	mapFrame:Center()
	mapFrame:MakePopup()

	-- Image panel
	local imagePanel = vgui.Create("DImage", mapFrame)
	imagePanel:SetImage(imagePath)
	imagePanel:Dock(FILL)
end

-- Register net message to open map
net.Receive("OpenMapViewer", function()
	local itemID = net.ReadUInt(16)
	local imagePath = net.ReadString()
	local title = net.ReadString()
	
	OpenMapViewer(imagePath, title)
end)

-- Close map with Escape key
hook.Add("Think", "MapViewerEscapeKey", function()
	if IsValid(mapFrame) and input.IsKeyDown(KEY_ESCAPE) then
		mapFrame:Remove()
		mapFrame = nil
	end
end)
