net.Receive("ix_physchars_setup", function()
	if IsValid(ix.gui.physcharsSetup) then return end

	local frame = vgui.Create("DFrame")
	frame:SetTitle("Physical Characteristics")
	frame:SetSize(320, 290)
	frame:Center()
	frame:MakePopup()
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	ix.gui.physcharsSetup = frame

	local content = frame:Add("DPanel")
	content:Dock(FILL)
	content:DockMargin(8, 4, 8, 8)
	content.Paint = nil

	local intro = content:Add("DLabel")
	intro:SetText("Your character's physical details have not been set. Please fill them in.")
	intro:SetTextColor(Color(180, 180, 180))
	intro:SetWrap(true)
	intro:Dock(TOP)
	intro:SetTall(32)
	intro:DockMargin(0, 0, 0, 8)

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
	heightSlider:SetValue(175)
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
	weightSlider:SetValue(90)
	weightSlider:DockMargin(0, 2, 0, 10)
	weightSlider.Label:SetVisible(false)

	local eyesLabel = content:Add("DLabel")
	eyesLabel:SetText("Eye Colour")
	eyesLabel:SetTextColor(color_white)
	eyesLabel:Dock(TOP)
	eyesLabel:SetTall(18)

	local selectedEye = "brown"
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
	submitBtn:SetText("Confirm")
	submitBtn:Dock(BOTTOM)
	submitBtn:SetTall(28)
	submitBtn.DoClick = function()
		net.Start("ix_physchars_setup_submit")
			net.WriteString(tostring(math.floor(heightSlider:GetValue())))
			net.WriteString(tostring(math.floor(weightSlider:GetValue())))
			net.WriteString(selectedEye)
		net.SendToServer()
		frame:Remove()
	end
end)
