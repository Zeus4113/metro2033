local PLUGIN = PLUGIN

local PANEL = {}

function PANEL:Init()
	local parent = self:GetParent()

	self:SetSize(parent:GetWide() * 0.6, parent:GetTall())
	self:Dock(RIGHT)
	self:DockMargin(0, ScrH() * 0.05, 0, 0)

	self.VBar:SetWide(0)

	local suppress = {}
	hook.Run("CanCreateCharacterInfo", suppress)

	if not suppress.time then
		local format = ix.option.Get("24hourTime", false) and "%A, %B %d, %Y. %H:%M" or "%A, %B %d, %Y. %I:%M %p"

		self.time = self:Add("DLabel")
		self.time:SetFont("ixMediumFont")
		self.time:SetTall(28)
		self.time:SetContentAlignment(5)
		self.time:Dock(TOP)
		self.time:SetTextColor(color_white)
		self.time:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		self.time:DockMargin(0, 0, 0, 32)
		self.time:SetText(ix.date.GetFormatted(format))
		self.time.Think = function(this)
			if ((this.nextTime or 0) < CurTime()) then
				this:SetText(ix.date.GetFormatted(format))
				this.nextTime = CurTime() + 0.5
			end
		end
	end

	if not suppress.name then
		self.name = self:Add("ixLabel")
		self.name:Dock(TOP)
		self.name:DockMargin(0, 0, 0, 8)
		self.name:SetFont("ixMenuButtonHugeFont")
		self.name:SetContentAlignment(5)
		self.name:SetTextColor(color_white)
		self.name:SetPadding(8)
		self.name:SetScaleWidth(true)
	end

	if not suppress.description then
		self.description = self:Add("DLabel")
		self.description:Dock(TOP)
		self.description:DockMargin(0, 0, 0, 8)
		self.description:SetFont("ixMenuButtonFont")
		self.description:SetTextColor(color_white)
		self.description:SetContentAlignment(5)
		self.description:SetMouseInputEnabled(true)
		self.description:SetCursor("hand")

		self.description.Paint = function(this, width, height)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, width, height)
		end

		self.description.OnMousePressed = function(this, code)
			if (code == MOUSE_LEFT) then
				ix.command.Send("CharDesc")

				if (IsValid(ix.gui.menu)) then
					ix.gui.menu:Remove()
				end
			end
		end

		self.description.SizeToContents = function(this)
			if (this.bWrap) then
				return
			end

			local width, height = this:GetContentSize()

			if (width > self:GetWide()) then
				this:SetWide(self:GetWide())
				this:SetTextInset(16, 8)
				this:SetWrap(true)
				this:SizeToContentsY()
				this:SetTall(this:GetTall() + 16)

				self.description:SetContentAlignment(8)
				this.bWrap = true
			else
				this:SetSize(width + 16, height + 16)
			end
		end
	end

	if not suppress.physicalCharacteristics then
		local physPanel = self:Add("ixCategoryPanel")
		physPanel:SetText(L("physicalCharacteristics"))
		physPanel:Dock(TOP)
		physPanel:DockMargin(0, 0, 0, 8)

		local physList = {}

		self.physHeight = physPanel:Add("ixListRow")
		self.physHeight:SetList(physList)
		self.physHeight:Dock(TOP)

		self.physWeight = physPanel:Add("ixListRow")
		self.physWeight:SetList(physList)
		self.physWeight:Dock(TOP)

		self.physEyes = physPanel:Add("ixListRow")
		self.physEyes:SetList(physList)
		self.physEyes:Dock(TOP)

		physPanel:SizeToContents()
		self.physPanel = physPanel
	end

	if not suppress.characterInfo then
		self.characterInfo = self:Add("ixCategoryPanel")
		self.characterInfo:SetText(L("affiliation"))
		self.characterInfo.list = {}
		self.characterInfo:Dock(TOP)
		self.characterInfo:DockMargin(0, 0, 0, 8)

		if not suppress.faction then
			self.faction = self.characterInfo:Add("ixListRow")
			self.faction:SetList(self.characterInfo.list)
			self.faction:Dock(TOP)
		end

		if not suppress.class then
			self.class = self.characterInfo:Add("ixListRow")
			self.class:SetList(self.characterInfo.list)
			self.class:Dock(TOP)
		end

		hook.Run("CreateCharacterInfo", self.characterInfo)
		self.characterInfo:SizeToContents()
	end

	if not suppress.attributes then
		local character = LocalPlayer().GetCharacter and LocalPlayer():GetCharacter()

		if character then
			self.attributes = self:Add("ixCategoryPanel")
			self.attributes:SetText(L("attributes"))
			self.attributes:Dock(TOP)
			self.attributes:DockMargin(0, 0, 0, 8)

			local boost = character:GetBoosts()
			local bFirst = true

			for k, v in SortedPairsByMemberValue(ix.attributes.list, "name") do
				local attributeBoost = 0

				if boost[k] then
					for _, bValue in pairs(boost[k]) do
						attributeBoost = attributeBoost + bValue
					end
				end

				local bar = self.attributes:Add("ixAttributeBar")
				bar:Dock(TOP)

				if not bFirst then
					bar:DockMargin(0, 3, 0, 0)
				else
					bFirst = false
				end

				local value = character:GetAttribute(k, 0)

				if attributeBoost then
					bar:SetValue((value - attributeBoost) or 0)
				else
					bar:SetValue(value)
				end

				local maximum = v.maxValue or ix.config.Get("maxAttributes", 100)
				bar:SetMax(maximum)
				bar:SetReadOnly()
				bar:SetText(Format("%s [%.1f/%.1f] (%.1f%%)", L(v.name), value, maximum, value / maximum * 100))

				if attributeBoost then
					bar:SetBoost(attributeBoost)
				end
			end

			self.attributes:SizeToContents()
		end
	end

	hook.Run("CreateCharacterInfoCategory", self)
end

function PANEL:Update(character)
	if not character then return end

	local faction = ix.faction.indices[character:GetFaction()]
	local class = ix.class.list[character:GetClass()]

	if self.name then
		self.name:SetText(character:GetName())

		if faction then
			self.name.backgroundColor = ColorAlpha(faction.color, 150) or Color(0, 0, 0, 150)
		end

		self.name:SizeToContents()
	end

	if self.physPanel then
		local heightVal = character:GetHeight("?")
		local weightVal = character:GetWeight("?")
		local eyesVal   = character:GetEyes("unknown")

		self.physHeight:SetLabelText(L("height"))
		self.physHeight:SetText(heightVal .. " cm")
		self.physHeight:SizeToContents()

		self.physWeight:SetLabelText(L("weight"))
		self.physWeight:SetText(weightVal .. " kg")
		self.physWeight:SizeToContents()

		self.physEyes:SetLabelText(L("eyes"))
		self.physEyes:SetText(eyesVal:sub(1, 1):upper() .. eyesVal:sub(2))
		self.physEyes:SizeToContents()

		local labelW = self.physEyes:GetLabelWidth() + 16
		self.physHeight:SetLabelWidth(labelW)
		self.physWeight:SetLabelWidth(labelW)
		self.physEyes:SetLabelWidth(labelW)

		self.physPanel:SizeToContents()
	end

	if self.description then
		self.description:SetText(character:GetDescription())
		self.description:SizeToContents()
	end

	if self.faction then
		self.faction:SetLabelText(L("faction"))
		self.faction:SetText(L(faction.name))
		self.faction:SizeToContents()
	end

	if self.class then
		if class and class.name ~= faction.name then
			self.class:SetLabelText(L("class"))
			self.class:SetText(L(class.name))
			self.class:SizeToContents()
		else
			self.class:SetVisible(false)
		end
	end

	hook.Run("UpdateCharacterInfo", self.characterInfo, character)

	self.characterInfo:SizeToContents()

	hook.Run("UpdateCharacterInfoCategory", self, character)
end

function PANEL:OnSubpanelRightClick()
	properties.OpenEntityMenu(LocalPlayer())
end

vgui.Register("ixCharacterInfo", PANEL, "DScrollPanel")

hook.Add("MenuSubpanelCreated", "ixMoneyDisplay", function(name, subpanel)
	if name ~= "inv" then return end

	local row = subpanel:Add("DPanel")
	row:Dock(BOTTOM)
	row:SetTall(24)
	row.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, 0, w, h)
	end

	local lbl = row:Add("DLabel")
	lbl:Dock(FILL)
	lbl:SetContentAlignment(5)
	lbl:SetFont("ixSmallFont")
	lbl:SetTextColor(color_white)
	lbl:SetExpensiveShadow(1, Color(0, 0, 0, 200))

	local char = LocalPlayer():GetCharacter()
	if char then
		lbl:SetText(L("money") .. ": " .. ix.currency.Get(char:GetMoney()))
	end

	lbl.Think = function(this)
		if (this.nextUpdate or 0) < CurTime() then
			local character = LocalPlayer():GetCharacter()
			if character then
				this:SetText(L("money") .. ": " .. ix.currency.Get(character:GetMoney()))
			end
			this.nextUpdate = CurTime() + 1
		end
	end
end)
