-- Skills tab — mirrors the group (ixgang) tab's flat, hand-painted style.

local COLOR_PAGE    = Color(20, 20, 23, 255)
local COLOR_CARD    = Color(33, 33, 38, 255)
local COLOR_ROW     = Color(41, 41, 47, 255)
local COLOR_TRACK   = Color(24, 24, 28, 255)
local COLOR_REACH   = Color(60, 60, 70, 255)
local COLOR_BORDER  = Color(58, 58, 66, 255)
local COLOR_TEXT    = Color(228, 228, 224, 255)
local COLOR_DIM     = Color(150, 150, 145, 255)
local COLOR_FAINT   = Color(110, 110, 108, 255)
local COLOR_MARKER  = Color(210, 210, 205, 255)

local function accent()
	return ix.config.Get("color", Color(200, 160, 60))
end

-- Fixed display order (ix.skill.list is an unordered hash).
local SKILL_ORDER = { "engineering", "tailoring", "chemistry" }

local function drawText(text, font, x, y, color, ax, ay)
	surface.SetFont(font)
	local tw, th = surface.GetTextSize(text)
	surface.SetTextColor(color)
	surface.SetTextPos(x - tw * (ax or 0), y - th * (ay or 0))
	surface.DrawText(text)
	return tw, th
end

-- Rendered height of a font at the current resolution. Helix fonts scale with
-- screen size, so all layout metrics are derived from these rather than fixed
-- pixels — that keeps spacing consistent across resolutions.
local function fontHeight(font)
	surface.SetFont(font)
	return select(2, surface.GetTextSize("Ag"))
end

-- ── Panel ─────────────────────────────────────────────────────────────────────

local PANEL = {}

function PANEL:Init()
	-- Dock to the top and size to content (below) so the panel hugs its rows
	-- instead of filling the whole menu area with empty background.
	self:Dock(TOP)

	self.padding = math.floor(fontHeight("ixMediumFont") * 0.7)
	self:DockPadding(self.padding, self.padding, self.padding, self.padding)

	self.Paint = function(_, w, h)
		draw.RoundedBox(4, 0, 0, w, h, COLOR_PAGE)
	end

	ix.gui.skillsPanel = self

	self.content = self:Add("DPanel")
	self.content:Dock(FILL)
	self.content.Paint = nil

	self:Rebuild()
end

function PANEL:Rebuild()
	self.content:Clear()

	local character = LocalPlayer():GetCharacter()

	if (!character) then
		self:SetTall(self.padding * 2)
		return
	end

	-- Each Build* returns the vertical space it consumes, so the panel can size
	-- itself exactly to its content.
	local total = self:BuildHeader(character)

	for _, id in ipairs(SKILL_ORDER) do
		if (ix.skill.list[id]) then
			total = total + self:BuildSkillRow(character, id)
		end
	end

	self:SetTall(total + self.padding * 2)
	self:InvalidateParent(true)
end

-- Summary card: earned / spent / unspent attribute points.
function PANEL:BuildHeader(character)
	local earned  = ix.skill.GetEarnedPoints(character)
	local spent   = ix.skill.GetSpentPoints(character)
	local unspent = ix.skill.GetUnspentPoints(character)

	local titleH = fontHeight("ixMediumFont")
	local subH   = fontHeight("ixSmallFont")
	local padX   = math.floor(titleH * 0.7)
	local padY   = math.floor(titleH * 0.5)
	local gap    = math.floor(subH * 0.3)

	local cardH  = padY * 2 + titleH + gap + subH
	local margin = math.floor(padY * 1.2)

	local card = self.content:Add("DPanel")
	card:Dock(TOP)
	card:SetTall(cardH)
	card:DockMargin(0, 0, 0, margin)
	card.Paint = function(_, w, h)
		draw.RoundedBox(4, 0, 0, w, h, COLOR_CARD)

		drawText(L("skills"):upper(), "ixMediumFont", padX, padY, COLOR_TEXT, 0, 0)

		local pointsText = unspent .. " " .. L("skillPointsUnspent")
		drawText(pointsText, "ixMediumFont", w - padX, padY, unspent > 0 and accent() or COLOR_DIM, 1, 0)

		drawText(L("skillPointsBreakdown", spent, earned), "ixSmallFont", w - padX, padY + titleH + gap, COLOR_FAINT, 1, 0)
	end

	return cardH + margin
end

-- One skill: name + tier on the left, level/cap on the right, a 0→20 bar showing
-- current progress, the unlocked cap range, the hard ceiling, and (when a point
-- can be usefully spent here) a "+" button. Every metric derives from the font
-- heights so the row scales cleanly with resolution.
function PANEL:BuildSkillRow(character, id)
	local ceiling = ix.skill.HARD_CEILING

	-- Whether a point can be spent here right now (drives the button + bar/number inset).
	local canSpend = ix.skill.GetUnspentPoints(character) > 0
		and ix.skill.GetPointsSpent(character, id) < ix.skill.MAX_POINTS_PER_SKILL

	local nameH   = fontHeight("ixMediumFont")
	local tierH   = fontHeight("ixSmallFont")
	local padX    = math.floor(nameH * 0.7)
	local padY    = math.floor(nameH * 0.45)
	local gap     = math.max(2, math.floor(tierH * 0.3))
	local barH    = math.max(6, math.floor(tierH * 0.55))
	local rowH    = padY * 2 + nameH + gap + tierH + gap + barH
	local btnSize = math.floor(nameH * 1.4)
	local inset   = canSpend and (btnSize + padX) or 0
	local margin  = math.floor(padY * 0.7)

	local row = self.content:Add("DPanel")
	row:Dock(TOP)
	row:SetTall(rowH)
	row:DockMargin(0, 0, 0, margin)
	row.Paint = function(_, w, h)
		draw.RoundedBox(4, 0, 0, w, h, COLOR_ROW)

		local level = ix.skill.Get(character, id)
		local cap   = ix.skill.GetCap(character, id)

		-- Left: name over tier.
		drawText(ix.skill.list[id], "ixMediumFont", padX, padY, COLOR_TEXT, 0, 0)
		drawText(ix.skill.GetTierName(level), "ixSmallFont", padX, padY + nameH + gap, accent(), 0, 0)

		-- Right: current level / cap (cleared to the left of the button when present).
		drawText(math.floor(level) .. " / " .. cap, "ixMediumFont", w - padX - inset, padY, COLOR_DIM, 1, 0)

		-- Bar along the bottom, spanning the full 0→20 range (short of the button).
		local barX, barY = padX, h - padY - barH
		local barW = w - padX * 2 - inset
		local capFrac  = math.Clamp(cap / ceiling, 0, 1)
		local fillFrac = math.Clamp(level / ceiling, 0, 1)

		draw.RoundedBox(4, barX, barY, barW, barH, COLOR_TRACK)                 -- locked (needs points)
		draw.RoundedBox(4, barX, barY, barW * capFrac, barH, COLOR_REACH)       -- unlocked cap range
		if (fillFrac > 0) then
			draw.RoundedBox(4, barX, barY, barW * fillFrac, barH, accent())     -- current progress
		end

		-- Cap marker at the edge of the unlocked range.
		local markerX = barX + barW * capFrac
		surface.SetDrawColor(COLOR_MARKER)
		surface.DrawRect(math.Clamp(markerX - 1, barX, barX + barW - 2), barY - 3, 2, barH + 6)
	end

	if (canSpend) then
		local btn = row:Add("DButton")
		btn:SetText("")
		btn:SetSize(btnSize, btnSize)
		btn:SetPos(0, 0) -- positioned in PerformLayout
		btn:SetTooltip(L("skillSpendTooltip"))
		btn.Paint = function(pnl, w, h)
			local c = pnl:IsHovered() and accent() or COLOR_CARD
			draw.RoundedBox(4, 0, 0, w, h, c)
			surface.SetDrawColor(COLOR_BORDER)
			surface.DrawOutlinedRect(0, 0, w, h)
			drawText("+", "ixMediumFont", w * 0.5, h * 0.5, COLOR_TEXT, 0.5, 0.5)
		end
		btn.DoClick = function()
			surface.PlaySound("buttons/button14.wav")
			net.Start("ixSkillSpendPoint")
				net.WriteString(id)
			net.SendToServer()
		end

		-- Vertically centred on the right edge.
		row.PerformLayout = function(_, w)
			btn:SetPos(w - padX - btnSize, math.floor((rowH - btnSize) / 2))
		end
	end

	return rowH + margin
end

vgui.Register("ixSkillsPanel", PANEL, "DPanel")

-- ── Menu tab registration (same hook the group tab uses) ──────────────────────

hook.Add("CreateMenuButtons", "ixSkills", function(tabs)
	tabs["skills"] = function(container)
		container:Add("ixSkillsPanel")
	end
end)

-- Live refresh when the server nudges us after an XP gain or a spent point.
net.Receive("ixSkillSync", function()
	if (IsValid(ix.gui.skillsPanel)) then
		ix.gui.skillsPanel:Rebuild()
	end
end)
