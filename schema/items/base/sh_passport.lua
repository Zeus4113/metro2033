ITEM.category = "Documents"
ITEM.width = 1
ITEM.height = 1
ITEM.weight = 0.1
ITEM.price = 0

ITEM.iconCam = {
	pos = Vector(-0.42, -0.05, 200),
	ang = Angle(89.88, 6.19, 0),
	fov = 3.62
}


if SERVER then
	util.AddNetworkString("ix_passport_show")
	util.AddNetworkString("ix_passport_details")
	util.AddNetworkString("ix_passport_write")
	util.AddNetworkString("ix_passport_write_submit")
end

function ITEM:PassportCanIssue(char)
	return false
end

function ITEM:PopulateTooltip(tooltip)
	local holderName   = self:GetData("holderName", "")
	local holderHeight = self:GetData("holderHeight", "")
	local holderWeight = self:GetData("holderWeight", "")
	local holderEyes   = self:GetData("holderEyes", "")

	local function AddRow(id, text, color)
		local row = tooltip:AddRow(id)
		row:SetText(text)
		row:SetTextColor(color or color_white)
		row:SizeToContents()
	end

	if holderName ~= "" then
		local eyesDisplay = holderEyes ~= "" and (holderEyes:sub(1,1):upper() .. holderEyes:sub(2)) or "Unknown"
		AddRow("holder",  "Assigned to: " .. holderName, self.passportColorLight)
		AddRow("height",  "Height: " .. (holderHeight ~= "" and holderHeight or "?") .. "cm")
		AddRow("weight",  "Weight: " .. (holderWeight ~= "" and holderWeight or "?") .. "kg")
		AddRow("eyes",    "Eye Colour: " .. eyesDisplay)
	else
		AddRow("unassigned", "This passport is unassigned.", Color(160, 160, 160))
	end
end

ITEM.functions.Show = {
	name = "Show Passport",
	icon = "icon16/user.png",
	OnRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		local charName = char and char:GetName() or ""

		local nearby = {}
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetPos():Distance(client:GetPos()) <= 200 then
				nearby[#nearby + 1] = ply
			end
		end

		if #nearby > 0 then
			net.Start("ix_passport_show")
				net.WriteString(item.passportKey)
				net.WriteString(charName)
			net.Send(nearby)
		end

		return false
	end,
}

ITEM.functions.ShowDetails = {
	name = "Show Passport Details",
	icon = "icon16/zoom.png",
	OnRun = function(item)
		local client = item.player
		local char = client:GetCharacter()
		local charName = char and char:GetName() or ""

		local nearby = {}
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetPos():Distance(client:GetPos()) <= 200 then
				nearby[#nearby + 1] = ply
			end
		end

		if #nearby > 0 then
			net.Start("ix_passport_details")
				net.WriteString(item.passportKey)
				net.WriteString(charName)
				net.WriteString(item:GetData("holderName", ""))
				net.WriteString(item:GetData("holderHeight", ""))
				net.WriteString(item:GetData("holderWeight", ""))
				net.WriteString(item:GetData("holderEyes", ""))
			net.Send(nearby)
		end

		return false
	end,
}

ITEM.functions.WriteName = {
	name = "Fill Out Passport Details",
	icon = "icon16/pencil.png",
	OnRun = function(item)
		net.Start("ix_passport_write")
			net.WriteString(item.passportKey)
			net.WriteUInt(item.id, 32)
			net.WriteString(item:GetData("holderName", ""))
			net.WriteString(item:GetData("holderHeight", "175"))
			net.WriteString(item:GetData("holderWeight", "90"))
			net.WriteString(item:GetData("holderEyes", "brown"))
		net.Send(item.player)
		return false
	end,
	OnCanRun = function(item)
		local client = item.player
		if not IsValid(client) then return false end
		local char = client:GetCharacter()
		if not char then return false end
		return item:PassportCanIssue(char)
	end,
}

if CLIENT then
	local function GetPassportConfig(key)
		for _, item in pairs(ix.item.list) do
			if item.passportKey == key then
				return item
			end
		end
	end

	net.Receive("ix_passport_show", function()
		local key = net.ReadString()
		local charName = net.ReadString()
		local cfg = GetPassportConfig(key)
		if not cfg then return end

		local displayName = charName ~= "" and charName or "An unknown individual"
		chat.AddText(cfg.passportColorLight, displayName, cfg.passportColor, " presents their passport, it's stamped with the insignia of " .. cfg.passportFactionLabel .. ".")
	end)

	net.Receive("ix_passport_details", function()
		local key = net.ReadString()
		local showerName = net.ReadString()
		local holderName = net.ReadString()
		local holderHeight = net.ReadString()
		local holderWeight = net.ReadString()
		local holderEyes = net.ReadString()
		local cfg = GetPassportConfig(key)
		if not cfg then return end

		local displayShower = showerName ~= "" and showerName or "An unknown individual"

		if holderName ~= "" then
			local eyesDisplay = holderEyes ~= "" and (holderEyes:sub(1,1):upper() .. holderEyes:sub(2)) or "Unknown"
			chat.AddText(cfg.passportColorLight, displayShower, cfg.passportColor, " presents their passport for inspection. The document reads:")
			chat.AddText(cfg.passportColor, "Name: ", cfg.passportColorLight, holderName)
			chat.AddText(cfg.passportColor, "Height: ", cfg.passportColorLight, (holderHeight ~= "" and holderHeight or "?") .. "cm")
			chat.AddText(cfg.passportColor, "Weight: ", cfg.passportColorLight, (holderWeight ~= "" and holderWeight or "?") .. "kg")
			chat.AddText(cfg.passportColor, "Eye Colour: ", cfg.passportColorLight, eyesDisplay)
		else
			chat.AddText(cfg.passportColorLight, displayShower, cfg.passportColor, " presents their passport for inspection.")
			chat.AddText(cfg.passportColor, "The document is currently unassigned.")
		end
	end)

	net.Receive("ix_passport_write", function()
		local key = net.ReadString()
		local itemID = net.ReadUInt(32)
		local currentName = net.ReadString()
		local currentHeight = tonumber(net.ReadString()) or 175
		local currentWeight = tonumber(net.ReadString()) or 90
		local currentEyes = net.ReadString()
		if currentEyes == "" then currentEyes = "brown" end

		local frame = vgui.Create("DFrame")
		frame:SetTitle("Fill Out Passport Details")
		frame:SetSize(320, 300)
		frame:Center()
		frame:MakePopup()

		local content = frame:Add("DPanel")
		content:Dock(FILL)
		content:DockMargin(8, 4, 8, 8)
		content.Paint = nil

		local nameLabel = content:Add("DLabel")
		nameLabel:SetText("Full Name")
		nameLabel:SetTextColor(color_white)
		nameLabel:Dock(TOP)
		nameLabel:SetTall(18)

		local nameEntry = content:Add("DTextEntry")
		nameEntry:SetTall(24)
		nameEntry:Dock(TOP)
		nameEntry:DockMargin(0, 2, 0, 10)
		nameEntry:SetValue(currentName)

		local heightLabel = content:Add("DLabel")
		heightLabel:SetText("Height (cm)")
		heightLabel:SetTextColor(color_white)
		heightLabel:Dock(TOP)
		heightLabel:SetTall(18)

		local heightSlider = content:Add("DNumSlider")
		heightSlider:Dock(TOP)
		heightSlider:SetTall(30)
		heightSlider:SetMin(170)
		heightSlider:SetMax(200)
		heightSlider:SetDecimals(0)
		heightSlider:SetValue(currentHeight)
		heightSlider:DockMargin(0, 2, 0, 10)
		heightSlider.Label:SetVisible(false)

		local weightLabel = content:Add("DLabel")
		weightLabel:SetText("Weight (kg)")
		weightLabel:SetTextColor(color_white)
		weightLabel:Dock(TOP)
		weightLabel:SetTall(18)

		local weightSlider = content:Add("DNumSlider")
		weightSlider:Dock(TOP)
		weightSlider:SetTall(30)
		weightSlider:SetMin(60)
		weightSlider:SetMax(120)
		weightSlider:SetDecimals(0)
		weightSlider:SetValue(currentWeight)
		weightSlider:DockMargin(0, 2, 0, 10)
		weightSlider.Label:SetVisible(false)

		local eyesLabel = content:Add("DLabel")
		eyesLabel:SetText("Eye Colour")
		eyesLabel:SetTextColor(color_white)
		eyesLabel:Dock(TOP)
		eyesLabel:SetTall(18)

		local selectedEye = currentEyes
		local eyeOptions = {"brown", "blue", "green", "grey"}
		local eyeColors = {
			brown = Color(101, 67, 33),
			blue  = Color(50, 120, 210),
			green = Color(40, 140, 60),
			grey  = Color(110, 110, 120),
		}

		local eyePanel = content:Add("Panel")
		eyePanel:Dock(TOP)
		eyePanel:SetTall(28)
		eyePanel:DockMargin(0, 2, 0, 10)
		eyePanel.Paint = nil

		for _, eyeName in ipairs(eyeOptions) do
			local btn = eyePanel:Add("DButton")
			btn:Dock(LEFT)
			btn:SetText(eyeName:sub(1,1):upper() .. eyeName:sub(2))
			btn:SetTextColor(color_white)
			local col = eyeColors[eyeName]
			btn.Paint = function(this, w, h)
				local sel = selectedEye == eyeName
				surface.SetDrawColor(col.r, col.g, col.b, sel and 210 or 70)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(255, 255, 255, sel and 255 or 80)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
			btn.DoClick = function() selectedEye = eyeName end
		end

		function eyePanel:PerformLayout(w, h)
			local btnW = w / #eyeOptions
			for _, child in ipairs(self:GetChildren()) do
				child:SetWide(btnW)
			end
		end

		local submitBtn = content:Add("DButton")
		submitBtn:SetText("Issue Passport")
		submitBtn:Dock(BOTTOM)
		submitBtn:SetTall(28)
		submitBtn.DoClick = function()
			local name = string.Trim(nameEntry:GetValue())
			if #name >= 4 and #name <= 64 then
				net.Start("ix_passport_write_submit")
					net.WriteString(key)
					net.WriteUInt(itemID, 32)
					net.WriteString(name)
					net.WriteString(tostring(math.floor(heightSlider:GetValue())))
					net.WriteString(tostring(math.floor(weightSlider:GetValue())))
					net.WriteString(selectedEye)
				net.SendToServer()
				frame:Remove()
			end
		end
	end)
end

if SERVER then
	net.Receive("ix_passport_write_submit", function(_, client)
		local key = net.ReadString()
		local itemID = net.ReadUInt(32)
		local name = string.Trim(net.ReadString())
		local height = string.Trim(net.ReadString())
		local weight = string.Trim(net.ReadString())
		local eyes = string.Trim(net.ReadString())

		local char = client:GetCharacter()
		if not char then return end

		local inv = char:GetInventory()
		if not inv then return end

		local targetItem
		for _, invItem in pairs(inv:GetItems()) do
			if invItem.id == itemID then
				targetItem = invItem
				break
			end
		end

		if not targetItem or targetItem.passportKey ~= key then return end
		if not targetItem:PassportCanIssue(char) then return end

		if #name < 4 or #name > 64 then return end

		local hNum = tonumber(height)
		if not hNum or math.floor(hNum) < 170 or math.floor(hNum) > 200 then return end

		local wNum = tonumber(weight)
		if not wNum or math.floor(wNum) < 60 or math.floor(wNum) > 120 then return end

		local validEyes = {brown = true, blue = true, green = true, grey = true}
		if not validEyes[eyes] then return end

		targetItem:SetData("holderName", name)
		targetItem:SetData("holderHeight", height)
		targetItem:SetData("holderWeight", weight)
		targetItem:SetData("holderEyes", eyes)
		client:Notify("Passport details filled out for " .. name .. ".")
	end)
end
