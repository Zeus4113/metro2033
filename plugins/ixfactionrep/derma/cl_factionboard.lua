local COLOR_BG       = Color(18, 18, 18, 248)
local COLOR_SECTION  = Color(28, 28, 28, 255)
local COLOR_ROW      = Color(34, 34, 34, 255)
local COLOR_ROW_SEL  = Color(55, 48, 30, 255)
local COLOR_ROW_WANT = Color(55, 22, 22, 255)   -- wanted row selected
local COLOR_ACCENT   = Color(200, 160, 60, 255)
local COLOR_TEXT     = Color(220, 220, 210, 255)
local COLOR_DIM      = Color(140, 135, 120, 255)
local COLOR_BAR_BG   = Color(45, 45, 45, 255)
local COLOR_RED      = Color(190, 40, 40, 255)
local COLOR_RED_DIM  = Color(100, 30, 30, 255)

local FACTION_COLORS = {
	redline = Color(190, 25, 25),
	hansa   = Color(135, 105, 52),
	reich   = Color(60,  60,  80),
	polis   = Color(70,  110, 140),
}
local FACTION_NAMES = {
	redline = "RED LINE",
	hansa   = "HANSEATIC LEAGUE",
	reich   = "FOURTH REICH",
	polis   = "RANGERS OF THE ORDER",
}
local FACTION_TAGLINES = {
	redline = "Protecting the tunnels of the proletariat.",
	hansa   = "Commerce and order through the Ring Line.",
	reich   = "Order, strength, and purification of the metro.",
	polis   = "Guardians of the last light of knowledge.",
}

-- Scales a value authored at 1920x1080 to the player's resolution. Behaves
-- identically to Helix's ScreenScale (width-proportional, matching its fonts);
-- 1920/640 = 3, so a 1080p pixel value maps straight through ScreenScale.
local function Scale(n)
	return ScreenScale(n / 3)
end

local PANEL_W       = Scale(510)
local GAP           = Scale(4)
local ROW_H         = Scale(44)
local ROW_GAP       = Scale(2)
local FRAME_TITLE_H = Scale(24)
local HEADER_H      = Scale(60)
local TAGLINE_H     = Scale(42)
local REP_H         = Scale(56)    -- taller than before to fit tier name
local DETAIL_MIN    = Scale(260)

local _chatLineH = 0
local function chatLineH()
	if _chatLineH == 0 then
		surface.SetFont("ixChatFont")
		local _, h = surface.GetTextSize("Ag")
		_chatLineH = math.max(Scale(18), h)
	end
	return _chatLineH
end

local function calcListH(n)
	return n * ROW_H + math.max(0, n - 1) * ROW_GAP
end

local function calcPanelH(n, descLines, bountyCount)
	local lh = chatLineH()
	-- name + reward + desc + progress + action(46) + unclaim(38) + transfer(48)
	local detailContent = Scale(42) + (lh + Scale(8)) + (descLines * lh + Scale(22)) + Scale(36) + Scale(46) + Scale(38) + Scale(48)
	local detailH  = math.max(DETAIL_MIN, detailContent)
	local bountyH  = (bountyCount > 0) and (ROW_H + calcListH(bountyCount) + GAP) or 0
	return FRAME_TITLE_H + HEADER_H + GAP + TAGLINE_H + GAP + REP_H + GAP + calcListH(n) + bountyH + GAP + detailH + Scale(20)
end

local function getRepColor(rep)
	if rep >= 80     then return Color(210, 190, 80,  220)   -- Veteran (gold)
	elseif rep >= 60 then return Color(200, 140, 50,  220)   -- Regular (amber)
	elseif rep >= 40 then return Color(55,  130, 55,  220)   -- Enlisted (green)
	elseif rep >= 20 then return Color(70,  100, 50,  220)   -- Affiliated (olive)
	elseif rep >= 0  then return Color(70,  70,  70,  220)   -- Stranger (grey)
	elseif rep >= -50 then return Color(120, 45,  45,  220)  -- Weary (red)
	else                  return Color(150, 30,  30,  220)   -- Wanted (deep red)
	end
end

local function getTierName(rep)
	if rep >= 80     then return "VETERAN"
	elseif rep >= 60 then return "REGULAR"
	elseif rep >= 40 then return "ENLISTED"
	elseif rep >= 20 then return "AFFILIATED"
	elseif rep >= 0  then return "STRANGER"
	elseif rep >= -50 then return "WEARY"
	else                  return "WANTED"
	end
end

-- Per-character progress key for a contract (matches the server's keying).
local function pkeyFor(fkey, contract)
	return os.date("%Y%m%d") .. "_" .. fkey .. "_" .. (contract.id or "")
end

-- Reward summary line: reputation, plus a bullet payout for higher-tier contracts.
local function rewardText(contract, fkey)
	local txt   = "+" .. contract.reward .. " " .. (FACTION_NAMES[fkey] or fkey) .. " reputation"
	local money = tonumber(contract.money) or 0
	if money > 0 then
		local bullets = (ix.currency and ix.currency.Get) and ix.currency.Get(money) or (money .. " bullets")
		txt = txt .. "  ·  +" .. bullets
	end
	return txt
end

local function getBadge(qs, contract)
	if qs and qs.claimed then
		return "Completed", Color(80, 160, 80, 255)
	end

	if qs and qs.accepted then
		if contract.type == "kill" then
			if (qs.progress or 0) >= contract.count then
				return "Ready to Claim", Color(80, 160, 80, 255)
			end
			return "In Progress", COLOR_DIM
		end
		return "Turn In", Color(200, 160, 60, 255)
	end

	return "Available", Color(200, 160, 60, 255)
end

local function measureLines(text, font, maxW)
	surface.SetFont(font)
	local tw = surface.GetTextSize(text)
	return math.max(1, math.ceil(tw / (maxW * 0.88)))
end

-- ── Panel ─────────────────────────────────────────────────────────────────────

local PANEL = {}

function PANEL:Init()
	self:SetSize(PANEL_W, Scale(500))
	self:SetTitle("")
	self:SetDraggable(true)
	self:SetDeleteOnClose(true)
	self:MakePopup()
	self:Center()

	self.factionKey        = "redline"
	self.contracts         = {}
	self.progress          = {}
	self.rep               = 0
	self.selected          = nil   -- contract index (integer)
	self.selectedBounty    = nil   -- bounty steamID (string)
	self.entity            = nil
	self.bountyList        = {}
	self.activeBountyID    = ""
	self.hasCompletedBounty = false
	self.nextRangeCheck    = 0

	-- ── Faction header ───────────────────────────────────────────────────────
	self.header = self:Add("DPanel")
	self.header:Dock(TOP)
	self.header:SetTall(HEADER_H)
	self.header.Paint = function(_, w, h)
		local col = FACTION_COLORS[self.factionKey] or COLOR_ACCENT
		surface.SetDrawColor(col.r, col.g, col.b, 220)
		surface.DrawRect(0, 0, w, h)
		surface.SetFont("ixMediumFont")
		surface.SetTextColor(255, 255, 255, 255)
		local title = FACTION_NAMES[self.factionKey] or "FACTION"
		local tw = surface.GetTextSize(title)
		surface.SetTextPos((w - tw) * 0.5, Scale(6))
		surface.DrawText(title)
		surface.SetFont("ixChatFont")
		surface.SetTextColor(255, 255, 255, 160)
		local sub = "CONTRACT BOARD"
		tw = surface.GetTextSize(sub)
		surface.SetTextPos((w - tw) * 0.5, Scale(28))
		surface.DrawText(sub)
	end

	-- ── Faction tagline ──────────────────────────────────────────────────────
	self.tagline = self:Add("DPanel")
	self.tagline:Dock(TOP)
	self.tagline:SetTall(TAGLINE_H)
	self.tagline:DockMargin(0, GAP, 0, 0)
	self.tagline.Paint = function(_, w, h)
		surface.SetDrawColor(COLOR_SECTION)
		surface.DrawRect(0, 0, w, h)
		surface.SetFont("ixChatFont")
		surface.SetTextColor(COLOR_DIM)
		local txt = FACTION_TAGLINES[self.factionKey] or ""
		local tw, th = surface.GetTextSize(txt)
		surface.SetTextPos(math.max(Scale(10), (w - tw) * 0.5), math.floor((h - th) * 0.5))
		surface.DrawText(txt)
	end

	-- ── Reputation bar ───────────────────────────────────────────────────────
	self.repPanel = self:Add("DPanel")
	self.repPanel:Dock(TOP)
	self.repPanel:SetTall(REP_H)
	self.repPanel:DockMargin(0, GAP, 0, 0)
	self.repPanel.Paint = function(_, w, h)
		surface.SetDrawColor(COLOR_SECTION)
		surface.DrawRect(0, 0, w, h)

		local barX, barY = Scale(14), Scale(8)
		local barW, barH = w - Scale(28), Scale(14)
		local tickW = math.max(1, Scale(1))

		-- Background
		surface.SetDrawColor(COLOR_BAR_BG)
		surface.DrawRect(barX, barY, barW, barH)

		-- Fill — rep maps -100 → 100 to 0 → 1
		local frac = math.Clamp((self.rep + 100) / 200, 0, 1)
		surface.SetDrawColor(getRepColor(self.rep))
		surface.DrawRect(barX, barY, math.Round(barW * frac), barH)

		-- Zero midpoint line
		surface.SetDrawColor(80, 80, 80, 200)
		surface.DrawRect(barX + math.Round(barW * 0.5), barY, tickW, barH)

		-- Tier threshold ticks (positive half: 20, 40, 60, 80)
		for _, t in ipairs({ 20, 40, 60, 80 }) do
			surface.SetDrawColor(0, 0, 0, 140)
			surface.DrawRect(barX + math.Round(barW * (t + 100) / 200), barY, tickW, barH)
		end

		-- Bounty threshold tick at -50 (red marker)
		surface.SetDrawColor(180, 40, 40, 220)
		surface.DrawRect(barX + math.Round(barW * ((-50 + 100) / 200)), barY, math.max(1, Scale(2)), barH)

		-- Rep label + tier name
		surface.SetFont("ixChatFont")
		surface.SetTextColor(COLOR_TEXT)
		local sign  = self.rep >= 0 and "+" or ""
		local label = "REPUTATION: " .. sign .. self.rep .. "  —  " .. getTierName(self.rep)
		local tw = surface.GetTextSize(label)
		surface.SetTextPos((w - tw) * 0.5, barY + barH + Scale(4))
		surface.DrawText(label)
	end

	-- ── Contract + bounty list ───────────────────────────────────────────────
	self.listPanel = self:Add("DScrollPanel")
	self.listPanel:Dock(TOP)
	self.listPanel:SetTall(0)   -- set in Setup
	self.listPanel:DockMargin(0, GAP, 0, 0)
	self.listPanel:GetVBar():SetWide(Scale(4))
	self.listPanel.Paint = function(_, w, h)
		surface.SetDrawColor(COLOR_SECTION)
		surface.DrawRect(0, 0, w, h)
	end

	-- ── Detail panel ─────────────────────────────────────────────────────────
	self.detail = self:Add("DPanel")
	self.detail:Dock(FILL)
	self.detail:DockMargin(0, GAP, 0, 0)
	self.detail.Paint = function(_, w, h)
		surface.SetDrawColor(COLOR_SECTION)
		surface.DrawRect(0, 0, w, h)
	end

	-- Name
	self.detailName = self.detail:Add("DLabel")
	self.detailName:Dock(TOP)
	self.detailName:SetTall(Scale(22))
	self.detailName:DockMargin(Scale(14), Scale(12), Scale(14), Scale(8))
	self.detailName:SetFont("ixMediumFont")
	self.detailName:SetTextColor(COLOR_ACCENT)
	self.detailName:SetText("Select a contract to view details.")

	-- Reward
	self.detailReward = self.detail:Add("DLabel")
	self.detailReward:Dock(TOP)
	self.detailReward:SetTall(chatLineH())
	self.detailReward:DockMargin(Scale(14), 0, Scale(14), Scale(8))
	self.detailReward:SetFont("ixChatFont")
	self.detailReward:SetTextColor(COLOR_TEXT)
	self.detailReward:SetText("")

	-- Description
	self.detailDesc = self.detail:Add("DLabel")
	self.detailDesc:Dock(TOP)
	self.detailDesc:SetTall(Scale(18))
	self.detailDesc:DockMargin(Scale(14), 0, Scale(14), Scale(14))
	self.detailDesc:SetFont("ixChatFont")
	self.detailDesc:SetTextColor(COLOR_DIM)
	self.detailDesc:SetWrap(true)
	self.detailDesc:SetText("")

	-- Progress row
	local progressRow = self.detail:Add("DPanel")
	progressRow:Dock(TOP)
	progressRow:SetTall(Scale(24))
	progressRow:DockMargin(Scale(14), 0, Scale(14), Scale(12))
	progressRow.Paint = function() end

	self.progressLabel = progressRow:Add("DLabel")
	self.progressLabel:Dock(RIGHT)
	self.progressLabel:SetWide(Scale(72))
	self.progressLabel:SetFont("ixChatFont")
	self.progressLabel:SetTextColor(COLOR_TEXT)
	self.progressLabel:SetContentAlignment(6)
	self.progressLabel:SetText("")

	self.progressBG = progressRow:Add("DPanel")
	self.progressBG:Dock(FILL)
	self.progressBG:DockMargin(0, Scale(6), Scale(6), Scale(6))
	self.progressBG.fraction = 0
	self.progressBG.Paint = function(pnl, w, h)
		surface.SetDrawColor(COLOR_BAR_BG)
		surface.DrawRect(0, 0, w, h)
		if pnl.fraction > 0 then
			surface.SetDrawColor(COLOR_ACCENT)
			surface.DrawRect(0, 0, math.Round(w * pnl.fraction), h)
		end
	end

	-- Accept / Claim / Bounty action button
	self.actionBtn = self.detail:Add("DButton")
	self.actionBtn:Dock(TOP)
	self.actionBtn:SetTall(Scale(34))
	self.actionBtn:DockMargin(Scale(14), 0, Scale(14), Scale(12))
	self.actionBtn:SetText("")
	self.actionBtn.Paint = function(pnl, w, h)
		if not self.selected and not self.selectedBounty then return end
		local isBountyAction = self.selectedBounty ~= nil
		local baseCol = isBountyAction and COLOR_RED or COLOR_ACCENT
		local col = pnl.disabled and COLOR_BAR_BG
		          or (pnl:IsHovered() and Color(baseCol.r + 20, baseCol.g + 20, baseCol.b + 20, 255) or baseCol)
		surface.SetDrawColor(col)
		surface.DrawRect(0, 0, w, h)
		surface.SetFont("ixMediumFont")
		local tc = pnl.disabled and COLOR_DIM or COLOR_BG
		surface.SetTextColor(tc)
		local tw, th = surface.GetTextSize(pnl.label or "")
		surface.SetTextPos((w - tw) * 0.5, (h - th) * 0.5)
		surface.DrawText(pnl.label or "")
	end
	self.actionBtn.DoClick = function()
		if self.actionBtn.disabled then return end

		if self.selectedBounty then
			-- Bounty action
			if self.hasCompletedBounty then
				net.Start("ixFactionRepBountyClaim")
				net.SendToServer()
			else
				net.Start("ixFactionRepBountyAccept")
					net.WriteString(self.selectedBounty)
				net.SendToServer()
			end
			return
		end

		-- Contract action
		if not self.selected then return end
		local idx      = self.selected
		local contract = self.contracts[idx]
		if not contract then return end
		local qs = self.progress[pkeyFor(self.factionKey, contract)]
		if qs and qs.claimed then return end
		if not qs or not qs.accepted then
			net.Start("ixFactionRepAccept")
				net.WriteUInt(idx, 8)
			net.SendToServer()
		else
			net.Start("ixFactionRepClaim")
				net.WriteUInt(idx, 8)
			net.SendToServer()
		end
	end

	-- Abandon (unclaim) button — shown only for a contract this character holds
	self.unclaimBtn = self.detail:Add("DButton")
	self.unclaimBtn:Dock(TOP)
	self.unclaimBtn:SetTall(Scale(28))
	self.unclaimBtn:DockMargin(Scale(14), 0, Scale(14), Scale(10))
	self.unclaimBtn:SetText("")
	self.unclaimBtn:SetVisible(false)
	self.unclaimBtn.Paint = function(pnl, w, h)
		local col = pnl:IsHovered() and Color(150, 60, 55, 255) or Color(90, 45, 42, 255)
		surface.SetDrawColor(col)
		surface.DrawRect(0, 0, w, h)
		surface.SetFont("ixChatFont")
		surface.SetTextColor(220, 200, 195, 255)
		local label = "Abandon Contract"
		local tw, th = surface.GetTextSize(label)
		surface.SetTextPos((w - tw) * 0.5, (h - th) * 0.5)
		surface.DrawText(label)
	end
	self.unclaimBtn.DoClick = function()
		if not self.selected then return end
		net.Start("ixFactionRepUnclaim")
			net.WriteUInt(self.selected, 8)
		net.SendToServer()
	end

	-- Join / Leave faction button
	self.transferBtn = self.detail:Add("DButton")
	self.transferBtn:Dock(TOP)
	self.transferBtn:SetTall(Scale(32))
	self.transferBtn:DockMargin(Scale(14), 0, Scale(14), Scale(16))
	self.transferBtn:SetText("")
	self.transferBtn:SetVisible(false)
	self.transferBtn.Paint = function(pnl, w, h)
		local isLeave = pnl.mode == "leave"
		local col
		if isLeave then
			col = pnl:IsHovered() and Color(200, 60, 60, 255) or Color(140, 35, 35, 255)
		else
			col = pnl:IsHovered() and Color(60, 160, 60, 255) or Color(35, 110, 35, 255)
		end
		surface.SetDrawColor(col)
		surface.DrawRect(0, 0, w, h)
		surface.SetFont("ixMediumFont")
		surface.SetTextColor(isLeave and Color(255, 200, 200, 255) or Color(200, 240, 200, 255))
		local label = (isLeave and "LEAVE " or "JOIN ") .. (FACTION_NAMES[self.factionKey] or "FACTION")
		local tw, th = surface.GetTextSize(label)
		surface.SetTextPos((w - tw) * 0.5, (h - th) * 0.5)
		surface.DrawText(label)
	end
	self.transferBtn.DoClick = function()
		if self.transferBtn.mode == "leave" then
			net.Start("ixFactionRepLeave")
		else
			net.Start("ixFactionRepTransfer")
		end
		net.SendToServer()
	end

	self.nextRangeCheck = 0
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function estimateDescLines(contracts)
	local maxLines = 1
	local innerW   = PANEL_W - Scale(28)
	for _, c in ipairs(contracts) do
		local text  = string.format(c.desc, c.count)
		local lines = measureLines(text, "ixChatFont", innerW)
		if lines > maxLines then maxLines = lines end
	end
	return maxLines
end

-- ── Setup / UpdateState ───────────────────────────────────────────────────────

function PANEL:Setup(entity, fkey, contracts, progress, rep, bountyList, activeBountyID, hasCompletedBounty)
	self.entity             = entity
	self.factionKey         = fkey
	self.contracts          = contracts
	self.progress           = progress
	self.rep                = rep
	self.bountyList         = bountyList or {}
	self.activeBountyID     = activeBountyID or ""
	self.hasCompletedBounty = hasCompletedBounty or false

	local n         = math.max(1, #contracts)
	local bountyN   = #self.bountyList
	local descLines = estimateDescLines(contracts)
	local listH     = calcListH(n) + (bountyN > 0 and (ROW_H + ROW_GAP + calcListH(bountyN)) or 0)
	self.listPanel:SetTall(listH)

	local totalH = calcPanelH(n, descLines, bountyN)
	self:SetSize(PANEL_W, totalH)
	self:Center()

	self.selected       = nil
	self.selectedBounty = nil
	self:UpdateTransferButton()
	self:RebuildList()
	if #contracts > 0 then self:SelectContract(1) end
end

function PANEL:UpdateState(contracts, progress, rep, bountyList, activeBountyID, hasCompletedBounty)
	self.contracts          = contracts
	self.progress           = progress
	self.rep                = rep
	self.bountyList         = bountyList or {}
	self.activeBountyID     = activeBountyID or ""
	self.hasCompletedBounty = hasCompletedBounty or false
	self:UpdateTransferButton()
	self:RebuildList()
	if self.selected then self:SelectContract(self.selected) end
	if self.selectedBounty then
		-- re-find bounty in updated list
		local found = false
		for _, b in ipairs(self.bountyList) do
			if b.steamID == self.selectedBounty then
				self:SelectBounty(b.steamID, b.charName, b.rep)
				found = true
				break
			end
		end
		if not found then self.selectedBounty = nil end
	end
end

function PANEL:UpdateTransferButton()
	local plugin    = ix.plugin.Get("ixfactionrep")
	local meta      = plugin and plugin.factionMeta[self.factionKey]
	local char      = LocalPlayer():GetCharacter()
	local inFaction = char and meta and char:GetFaction() == meta.faction()
	local threshold = ix.config and ix.config.Get and ix.config.Get("factionRepTransferThreshold", 20) or 20

	if inFaction then
		self.transferBtn:SetVisible(true)
		self.transferBtn.mode = "leave"
	elseif self.rep >= threshold then
		self.transferBtn:SetVisible(true)
		self.transferBtn.mode = "join"
	else
		self.transferBtn:SetVisible(false)
		self.transferBtn.mode = nil
	end
end

-- ── List rebuild ──────────────────────────────────────────────────────────────

function PANEL:RebuildList()
	self.listPanel:Clear()

	-- Contract rows
	for i, contract in ipairs(self.contracts) do
		local qs  = self.progress[pkeyFor(self.factionKey, contract)]
		local sel = self.selected == i

		local row = self.listPanel:Add("DPanel")
		row:SetTall(ROW_H)
		row:Dock(TOP)
		row:DockMargin(0, 0, 0, ROW_GAP)
		row.Paint = function(_, w, h)
			surface.SetDrawColor(sel and COLOR_ROW_SEL or COLOR_ROW)
			surface.DrawRect(0, 0, w, h)
			surface.SetFont("ixChatFont")
			surface.SetTextColor((qs and qs.claimed) and COLOR_DIM or COLOR_TEXT)
			surface.SetTextPos(Scale(14), (h - Scale(16)) * 0.5)
			-- Tier tag + contract name
			local label = contract.name
			if contract.tier then label = "[T" .. contract.tier .. "] " .. label end
			surface.DrawText(label)
			local badge, badgeCol = getBadge(qs, contract)
			surface.SetTextColor(badgeCol)
			local tw = surface.GetTextSize(badge)
			surface.SetTextPos(w - tw - Scale(14), (h - Scale(16)) * 0.5)
			surface.DrawText(badge)
		end
		row:SetCursor("hand")
		row.OnMousePressed = function()
			self.selected       = i
			self.selectedBounty = nil
			self:RebuildList()
			self:SelectContract(i)
		end
	end

	-- Bounty section (only if bounties exist)
	if #self.bountyList > 0 then
		-- Divider
		local divider = self.listPanel:Add("DPanel")
		divider:Dock(TOP)
		divider:SetTall(ROW_H)
		divider:DockMargin(0, ROW_GAP, 0, 0)
		divider.Paint = function(_, w, h)
			surface.SetDrawColor(COLOR_RED_DIM)
			surface.DrawRect(0, 0, w, h)
			surface.SetFont("ixMediumFont")
			surface.SetTextColor(Color(200, 80, 80, 255))
			local txt = "── WANTED ──"
			local tw, th = surface.GetTextSize(txt)
			surface.SetTextPos((w - tw) * 0.5, (h - th) * 0.5)
			surface.DrawText(txt)
		end

		-- Bounty rows
		for _, bounty in ipairs(self.bountyList) do
			local isActive    = self.activeBountyID == bounty.steamID
			local isSel       = self.selectedBounty == bounty.steamID

			local row = self.listPanel:Add("DPanel")
			row:Dock(TOP)
			row:SetTall(ROW_H)
			row:DockMargin(0, ROW_GAP, 0, 0)
			row.Paint = function(_, w, h)
				surface.SetDrawColor(isSel and COLOR_ROW_WANT or COLOR_ROW)
				surface.DrawRect(0, 0, w, h)

				-- Left: name
				surface.SetFont("ixChatFont")
				surface.SetTextColor(Color(220, 120, 120, 255))
				surface.SetTextPos(Scale(14), (h - Scale(16)) * 0.5)
				surface.DrawText(bounty.charName)

				-- Right: status badge
				local badge, badgeCol
				if self.hasCompletedBounty then
					badge = "CLAIM REWARD"; badgeCol = Color(80, 200, 80, 255)
				elseif isActive then
					badge = "TRACKING"; badgeCol = COLOR_ACCENT
				else
					badge = bounty.rep .. " REP  ⚠"; badgeCol = Color(190, 80, 80, 255)
				end
				surface.SetTextColor(badgeCol)
				local tw = surface.GetTextSize(badge)
				surface.SetTextPos(w - tw - Scale(14), (h - Scale(16)) * 0.5)
				surface.DrawText(badge)
			end
			row:SetCursor("hand")
			local sid  = bounty.steamID
			local name = bounty.charName
			local brep = bounty.rep
			row.OnMousePressed = function()
				self.selected       = nil
				self.selectedBounty = sid
				self:RebuildList()
				self:SelectBounty(sid, name, brep)
			end
		end
	end
end

-- ── Detail views ──────────────────────────────────────────────────────────────

function PANEL:SelectContract(idx)
	self.selected       = idx
	self.selectedBounty = nil
	local contract = self.contracts[idx]
	if not contract then return end

	local pkey = pkeyFor(self.factionKey, contract)
	local qs   = self.progress[pkey]

	self.detailName:SetText(contract.name)
	self.detailName:SetTextColor(COLOR_ACCENT)
	local prefix = contract.tier and ("Tier " .. contract.tier .. "  ·  ") or ""
	self.detailReward:SetText(prefix .. rewardText(contract, self.factionKey))

	local descText = string.format(contract.desc, contract.count)
	self.detailDesc:SetText(descText)
	local innerW = PANEL_W - Scale(28)
	local lines  = measureLines(descText, "ixChatFont", innerW)
	self.detailDesc:SetTall(lines * chatLineH() + Scale(8))

	local prog = qs and qs.progress or 0
	local frac = (contract.type == "kill") and math.Clamp(prog / contract.count, 0, 1) or 0
	if qs and qs.claimed then frac = 1 end
	self.progressBG.fraction = frac
	self.progressLabel:SetText(prog .. " / " .. contract.count)

	local accepted = qs and qs.accepted and not qs.claimed
	local btn      = self.actionBtn
	if qs and qs.claimed then
		btn.label = "Completed";    btn.disabled = true
	elseif accepted then
		if contract.type == "kill" and prog < contract.count then
			btn.label = "In Progress";  btn.disabled = true
		else
			btn.label = "Claim Reward"; btn.disabled = false
		end
	else
		btn.label = "Accept Contract"; btn.disabled = false
	end

	-- Abandon button only while this character is actively working the contract
	self.unclaimBtn:SetVisible(accepted == true)
end

function PANEL:SelectBounty(steamID, charName, _)
	self.selected       = nil
	self.selectedBounty = steamID
	self.unclaimBtn:SetVisible(false)
	local fname = FACTION_NAMES[self.factionKey] or self.factionKey
	local reward = ix.config and ix.config.Get and ix.config.Get("factionRepBountyReward", 20) or 20
	local isActive = self.activeBountyID == steamID

	self.detailName:SetText(charName .. " — WANTED")
	self.detailName:SetTextColor(Color(210, 90, 90, 255))
	self.detailReward:SetText("+" .. reward .. " " .. fname .. " reputation on successful elimination")

	local desc = "This individual has made enemies of the " .. fname .. ". Hunt them down and return here to collect your bounty."
	self.detailDesc:SetText(desc)
	local innerW = PANEL_W - Scale(28)
	local lines  = measureLines(desc, "ixChatFont", innerW)
	self.detailDesc:SetTall(lines * chatLineH() + Scale(8))

	self.progressBG.fraction = self.hasCompletedBounty and 1 or (isActive and 0.5 or 0)
	self.progressLabel:SetText(self.hasCompletedBounty and "1 / 1" or (isActive and "..." or "0 / 1"))

	local btn = self.actionBtn
	if self.hasCompletedBounty then
		btn.label = "Claim Bounty Reward"; btn.disabled = false
	elseif isActive then
		btn.label = "Tracking Target";     btn.disabled = true
	elseif self.activeBountyID ~= "" then
		btn.label = "Accept Bounty";       btn.disabled = false  -- server will validate
	else
		btn.label = "Accept Bounty";       btn.disabled = false
	end
end

-- ── Panel lifecycle ───────────────────────────────────────────────────────────

function PANEL:Think()
	if CurTime() > self.nextRangeCheck then
		self.nextRangeCheck = CurTime() + 0.5
		if not IsValid(self.entity) then self:Close() return end
		if LocalPlayer():GetPos():DistToSqr(self.entity:GetPos()) > (96 * 2) ^ 2 then
			self:Close()
		end
	end
end

function PANEL:OnClose()
	ix.gui.factionboard = nil
	net.Start("ixFactionRepClose")
	net.SendToServer()
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(COLOR_BG)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("ixFactionBoard", PANEL, "DFrame")

-- ── Net receivers ─────────────────────────────────────────────────────────────

net.Receive("ixFactionRepOpen", function()
	local entity          = net.ReadEntity()
	local fkey            = net.ReadString()
	local contracts       = net.ReadTable()
	local progress        = net.ReadTable()
	local rep             = net.ReadInt(8)
	local bountyList      = net.ReadTable()
	local activeBountyID  = net.ReadString()
	local hasCompleted    = net.ReadBool()

	if IsValid(ix.gui.factionboard) then ix.gui.factionboard:Remove() end
	ix.gui.factionboard = vgui.Create("ixFactionBoard")
	ix.gui.factionboard:Setup(entity, fkey, contracts, progress, rep, bountyList, activeBountyID, hasCompleted)
end)

net.Receive("ixFactionRepStateUpdate", function()
	local contracts      = net.ReadTable()
	local progress       = net.ReadTable()
	local rep            = net.ReadInt(8)
	local bountyList     = net.ReadTable()
	local activeBountyID = net.ReadString()
	local hasCompleted   = net.ReadBool()

	if table.IsEmpty(contracts) and table.IsEmpty(bountyList) then
		if IsValid(ix.gui.factionboard) then ix.gui.factionboard:Remove() end
		return
	end

	if IsValid(ix.gui.factionboard) then
		ix.gui.factionboard:UpdateState(contracts, progress, rep, bountyList, activeBountyID, hasCompleted)
	end
end)
