local SECTION_H = 60

hook.Add("InitPostEntity", "ixFactionRepVendorEditorExtend", function()
	local meta = vgui.GetControlTable("ixVendorEditor")
	if not meta then return end

	local origInit = meta.Init
	meta.Init = function(self, ...)
		origInit(self, ...)

		local entity = ix.gui.vendor and ix.gui.vendor.entity
		if not IsValid(entity) then return end

		-- Grow the panel so the items list keeps its original height
		local w, h = self:GetSize()
		self:SetTall(h + SECTION_H)
		self:MoveLeftOf(ix.gui.vendor, 8)
		self:CenterVertical()

		-- Track selected faction locally so we don't need GetSelected()
		local selectedFaction = entity:GetNWString("ixVendorRepFaction", "")

		local function sendUpdate(minEntry)
			local num = math.Clamp(math.Round(tonumber(minEntry:GetValue()) or 0), -100, 100)
			net.Start("ixFactionRepVendorSet")
				net.WriteEntity(entity)
				net.WriteString(selectedFaction)
				net.WriteInt(num, 8)
			net.SendToServer()
		end

		-- Section panel docked to bottom — dock layout recalculates so items list shrinks
		local section = self:Add("DPanel")
		section:Dock(BOTTOM)
		section:SetTall(SECTION_H)
		section:DockMargin(0, 4, 0, 0)
		section.Paint = function() end

		local lbl = section:Add("DLabel")
		lbl:Dock(TOP)
		lbl:SetTall(18)
		lbl:SetText("Reputation Gate")
		lbl:SetTextColor(color_white)
		lbl:SetFont("DermaDefaultBold")

		local row = section:Add("DPanel")
		row:Dock(FILL)
		row:DockMargin(0, 4, 0, 0)
		row.Paint = function() end

		local factionDrop = row:Add("DComboBox")
		factionDrop:Dock(LEFT)
		factionDrop:SetWide(148)
		factionDrop:AddChoice("No Requirement", "")
		factionDrop:AddChoice("Red Line",        "redline")
		factionDrop:AddChoice("Hansa",           "hansa")
		factionDrop:AddChoice("Fourth Reich",    "reich")

		if selectedFaction == "redline" then
			factionDrop:ChooseOptionID(2)
		elseif selectedFaction == "hansa" then
			factionDrop:ChooseOptionID(3)
		elseif selectedFaction == "reich" then
			factionDrop:ChooseOptionID(4)
		else
			factionDrop:ChooseOptionID(1)
		end

		local minEntry = row:Add("DTextEntry")
		minEntry:Dock(FILL)
		minEntry:DockMargin(4, 0, 0, 0)
		minEntry:SetNumeric(true)
		minEntry:SetText(tostring(entity:GetNWInt("ixVendorRepMin", 0)))
		minEntry:SetPlaceholderText("Min rep")

		factionDrop.OnSelect = function(_, _, _, data)
			selectedFaction = data
			sendUpdate(minEntry)
		end

		minEntry.OnEnter = function(this)
			local val = math.Clamp(math.Round(tonumber(this:GetText()) or 0), -100, 100)
			this:SetText(tostring(val))
			sendUpdate(this)
		end
	end
end)
