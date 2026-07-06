local COLOR_PAGE    = Color(24, 24, 28, 252)
local COLOR_CARD    = Color(36, 36, 42, 255)
local COLOR_HEADER  = Color(29, 29, 34, 255)
local COLOR_BORDER  = Color(58, 58, 66, 255)
local COLOR_TEXT    = Color(230, 230, 226, 255)
local COLOR_DIM     = Color(155, 155, 150, 255)
local COLOR_FAINT   = Color(120, 120, 118, 255)
local COLOR_RED     = Color(176, 58, 58, 255)
local COLOR_GREEN   = Color(58, 132, 70, 255)
local COLOR_BLUE    = Color(54, 104, 150, 255)
local COLOR_DISABLE = Color(52, 52, 58, 255)

-- ── Layout constants ──────────────────────────────────────────────────────────

local FRAME_W   = 560
local ACCENT_H  = 3
local HEADER_H  = 92
local PAD       = 26    -- left/right inner padding
local BODY_PAD  = 24    -- body top/bottom padding
local CARD_PAD  = 22    -- inner padding of cards
local BTN_TALL  = 58
local GAP       = 14    -- gap between body elements

local function accent()
	return ix.config.Get("color", Color(200, 160, 60))
end

-- ── Text helpers ──────────────────────────────────────────────────────────────

local function drawText(text, font, x, y, color, ax, ay)
	surface.SetFont(font)
	local tw, th = surface.GetTextSize(text)
	surface.SetTextColor(color)
	surface.SetTextPos(math.Round(x - tw * (ax or 0)), math.Round(y - th * (ay or 0)))
	surface.DrawText(text)
	return tw, th
end

local function fitText(text, font, maxW)
	surface.SetFont(font)
	if maxW <= 0 or surface.GetTextSize(text) <= maxW then return text end
	while #text > 1 and surface.GetTextSize(text .. "…") > maxW do
		text = string.sub(text, 1, #text - 1)
	end
	return text .. "…"
end

local function formatDuration(seconds)
	seconds = math.max(0, math.floor(seconds))
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	local m = math.floor((seconds % 3600) / 60)
	if d > 0 then return d .. "d " .. h .. "h" end
	if h > 0 then return h .. "h " .. m .. "m" end
	return m .. "m"
end

-- Compact form that omits zero components (e.g. 3 days → "3d").
local function formatCompact(seconds)
	seconds = math.max(0, math.floor(seconds))
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local parts = {}
	if d > 0 then parts[#parts + 1] = d .. "d" end
	if h > 0 then parts[#parts + 1] = h .. "h" end
	if m > 0 and d == 0 then parts[#parts + 1] = m .. "m" end
	return #parts > 0 and table.concat(parts, " ") or "0m"
end

-- ── Action button ─────────────────────────────────────────────────────────────

-- Returns the button so the caller can dock it; height is fixed at BTN_TALL.
local function actionButton(parent, title, sub, baseColor, enabled, onClick)
	local btn = parent:Add("DButton")
	btn:SetTall(BTN_TALL)
	btn:SetText("")
	btn:SetEnabled(enabled)
	btn.Paint = function(pnl, w, h)
		local c
		if not enabled then
			c = COLOR_DISABLE
		else
			c = pnl:IsHovered()
				and Color(math.min(baseColor.r + 26, 255), math.min(baseColor.g + 26, 255), math.min(baseColor.b + 26, 255))
				or baseColor
		end
		draw.RoundedBox(5, 0, 0, w, h, c)

		local tcol = enabled and COLOR_TEXT or COLOR_FAINT
		if sub and sub ~= "" then
			drawText(title, "ixGenericFont", w * 0.5, h * 0.5 - 11, tcol, 0.5, 0.5)
			local subCol = enabled and Color(tcol.r, tcol.g, tcol.b, 190) or COLOR_FAINT
			drawText(fitText(sub, "ixSmallFont", w - 28), "ixSmallFont", w * 0.5, h * 0.5 + 13, subCol, 0.5, 0.5)
		else
			drawText(title, "ixGenericFont", w * 0.5, h * 0.5, tcol, 0.5, 0.5)
		end
	end
	if enabled then btn.DoClick = onClick end
	return btn
end

-- ── Panel ─────────────────────────────────────────────────────────────────────

local PANEL = {}

function PANEL:Init()
	self:SetSize(FRAME_W, 400)
	self:MakePopup()
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(false)

	ix.gui.gangBase = self

	self.entity     = nil
	self.data       = nil
	self.nextRange  = 0
	self.positioned = false

	self.Paint = function(_, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_PAGE)
		surface.SetDrawColor(COLOR_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		surface.SetDrawColor(accent())
		surface.DrawRect(1, 1, w - 2, ACCENT_H)
	end

	-- Header (also the drag handle)
	self.header = self:Add("DPanel")
	self.header:Dock(TOP)
	self.header:DockMargin(1, ACCENT_H + 1, 1, 0)
	self.header:SetTall(HEADER_H)
	self.header:SetCursor("sizeall")
	self.header.Paint = function(_, w, h)
		surface.SetDrawColor(COLOR_HEADER)
		surface.DrawRect(0, 0, w, h)

		local d = self.data
		local title = d and d.hideoutName or "Hideout"
		drawText(fitText(title, "ixBigFont", w - PAD - 50), "ixBigFont", PAD, 36, COLOR_TEXT, 0, 0.5)

		local status, scol
		if not d then
			status, scol = "", COLOR_DIM
		elseif d.ownedByUs then
			status, scol = "Held by your group", accent()
		elseif d.claimed then
			status, scol = "Claimed by " .. (d.ownerName or "another group"), COLOR_RED
		else
			status, scol = "Unclaimed territory", COLOR_DIM
		end
		drawText(fitText(status, "ixChatFont", w - PAD * 2), "ixChatFont", PAD, 64, scol, 0, 0.5)
	end
	self.header.OnMousePressed = function() self:StartDrag() end

	-- Close button
	self.close = self:Add("DButton")
	self:DefineCloseButton()

	-- Body
	self.body = self:Add("DPanel")
	self.body:Dock(FILL)
	self.body:DockMargin(PAD, BODY_PAD, PAD, BODY_PAD)
	self.body.Paint = nil
end

function PANEL:DefineCloseButton()
	self.close:SetText("")
	self.close:SetSize(30, 30)
	self.close.Paint = function(pnl, w, h)
		drawText("✕", "ixMediumFont", w * 0.5, h * 0.5,
			pnl:IsHovered() and COLOR_RED or COLOR_DIM, 0.5, 0.5)
	end
	self.close.DoClick = function() self:Remove() end
end

function PANEL:PerformLayout(w, h)
	if IsValid(self.close) then
		self.close:SetPos(w - 38, ACCENT_H + 8)
	end
end

-- ── Dragging ──────────────────────────────────────────────────────────────────

function PANEL:StartDrag()
	local mx, my = gui.MouseX(), gui.MouseY()
	local x, y   = self:GetPos()
	self.dragOff = { mx - x, my - y }
	self:MouseCapture(true)
end

function PANEL:OnMouseReleased()
	self.dragOff = nil
	self:MouseCapture(false)
end

-- ── State ─────────────────────────────────────────────────────────────────────

function PANEL:SetState(entity, data)
	self.entity = entity
	self.data   = data
	self:Rebuild()
end

function PANEL:ResizeToContent(contentH)
	local total = ACCENT_H + 1 + HEADER_H + BODY_PAD + contentH + BODY_PAD + 1
	local x, y  = self:GetPos()
	self:SetSize(FRAME_W, total)
	if self.positioned then
		self:SetPos(x, y)
	else
		self:Center()
		self.positioned = true
	end
end

function PANEL:Rebuild()
	if not IsValid(self.body) then return end
	self.body:Clear()

	local d = self.data
	if not d then return end

	local contentH = 0
	local buttons  = {}

	-- Info card
	local infoH = d.ownedByUs and 118 or 86
	local info  = self.body:Add("DPanel")
	info:Dock(TOP)
	info:SetTall(infoH)
	info.Paint = function(_, w, ih)
		draw.RoundedBox(6, 0, 0, w, ih, COLOR_CARD)

		if d.ownedByUs then
			local remaining = d.upkeepExpires - os.time()
			drawText("UPKEEP", "ixSmallFont", CARD_PAD, 28, COLOR_FAINT, 0, 0.5)

			if remaining <= 0 then
				drawText("EXPIRED", "ixMediumFont", CARD_PAD, 60, COLOR_RED, 0, 0.5)
			else
				-- "2d 12h remaining" in bold, "(3d maximum)" appended in a lighter font
				local rw = drawText(formatDuration(remaining) .. " remaining", "ixMediumFont",
					CARD_PAD, 60, COLOR_TEXT, 0, 0.5)
				drawText("(" .. formatCompact(d.upkeepMax) .. " maximum)", "ixChatFont",
					CARD_PAD + rw + 9, 62, d.upkeepAtMax and accent() or COLOR_FAINT, 0, 0.5)
			end

			drawText("Renewal " .. ix.currency.Get(d.upkeepCost), "ixChatFont", CARD_PAD, 94,
				COLOR_DIM, 0, 0.5)
		else
			drawText("CLAIM COST", "ixSmallFont", CARD_PAD, 30, COLOR_FAINT, 0, 0.5)
			drawText(ix.currency.Get(d.claimCost), "ixMediumFont", CARD_PAD, 62, accent(), 0, 0.5)
		end
	end
	contentH = contentH + infoH

	-- Action buttons (collected so the last one gets no trailing gap)
	if d.ownedByUs then
		buttons[#buttons + 1] = actionButton(self.body, "Pay Upkeep",
			d.upkeepAtMax and "Already at maximum" or ix.currency.Get(d.upkeepCost),
			COLOR_GREEN, d.canUpkeep, function()
				net.Start("ixGangBaseUpkeep")
				net.SendToServer()
			end)

		if d.canAbandon then
			buttons[#buttons + 1] = actionButton(self.body, "Abandon Hideout",
				"Releases the claim for your group", COLOR_RED, true, function()
					Derma_Query(
						"Abandon this hideout? Every member will lose its gang class.",
						"Confirm Abandon",
						"Abandon", function()
							net.Start("ixGangBaseAbandon")
							net.SendToServer()
						end,
						"Cancel")
				end)
		else
			buttons[#buttons + 1] = actionButton(self.body, "Abandon Hideout",
				"Only the group leader may abandon", COLOR_RED, false, nil)
		end
	else
		if d.canClaim then
			buttons[#buttons + 1] = actionButton(self.body, "Claim Hideout",
				ix.currency.Get(d.claimCost), COLOR_GREEN, true, function()
					net.Start("ixGangBaseClaim")
					net.SendToServer()
				end)
		else
			buttons[#buttons + 1] = actionButton(self.body, "Claim Hideout",
				d.claimReason ~= "" and d.claimReason or nil, COLOR_BLUE, false, nil)
		end
	end

	-- Dock the buttons with a gap above each, then total their height
	for _, btn in ipairs(buttons) do
		btn:Dock(TOP)
		btn:DockMargin(0, GAP, 0, 0)
		contentH = contentH + GAP + BTN_TALL
	end

	self:ResizeToContent(contentH)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function PANEL:Think()
	if self.dragOff then
		if not input.IsMouseDown(MOUSE_LEFT) then
			self:OnMouseReleased()
		else
			self:SetPos(gui.MouseX() - self.dragOff[1], gui.MouseY() - self.dragOff[2])
		end
	end

	if CurTime() < self.nextRange then return end
	self.nextRange = CurTime() + 0.4
	if not IsValid(self.entity) then self:Remove() return end
	if LocalPlayer():GetPos():DistToSqr(self.entity:GetPos()) > (96 * 2) ^ 2 then
		self:Remove()
	end
end

vgui.Register("ixGangBaseMenu", PANEL, "EditablePanel")

-- ── Net handler ───────────────────────────────────────────────────────────────

net.Receive("ixGangBaseOpen", function()
	local entity = net.ReadEntity()
	local data   = net.ReadTable()

	if IsValid(ix.gui.gangBase) then
		ix.gui.gangBase:SetState(entity, data)
	else
		local panel = vgui.Create("ixGangBaseMenu")
		panel:SetState(entity, data)
	end
end)
