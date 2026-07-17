local COLOR_PAGE    = Color(20, 20, 23, 255)
local COLOR_CARD    = Color(33, 33, 38, 255)
local COLOR_CARD_HD = Color(27, 27, 31, 255)
local COLOR_ROW     = Color(41, 41, 47, 255)
local COLOR_ROW_HOV = Color(52, 52, 60, 255)
local COLOR_BORDER  = Color(58, 58, 66, 255)
local COLOR_TEXT    = Color(228, 228, 224, 255)
local COLOR_DIM     = Color(150, 150, 145, 255)
local COLOR_FAINT   = Color(110, 110, 108, 255)
local COLOR_ONLINE  = Color(95, 200, 110, 255)
local COLOR_OFFLINE = Color(95, 95, 100, 255)
local COLOR_RED     = Color(176, 58, 58, 255)
local COLOR_GREEN   = Color(58, 132, 70, 255)
local COLOR_BLUE    = Color(54, 104, 150, 255)

-- Scales a value authored at 1920x1080 to the player's resolution, matching
-- Helix's ScreenScale (width-proportional); 1920/640 = 3.
local function Scale(n)
	return ScreenScale(n / 3)
end

local function accent()
	return ix.config.Get("color", Color(200, 160, 60))
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function formatDuration(seconds)
	seconds = math.max(0, math.floor(seconds))
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	local m = math.floor((seconds % 3600) / 60)
	if d > 0 then return d .. "d " .. h .. "h" end
	if h > 0 then return h .. "h " .. m .. "m" end
	return m .. "m"
end

local function drawText(text, font, x, y, color, ax, ay)
	surface.SetFont(font)
	local tw, th = surface.GetTextSize(text)
	surface.SetTextColor(color)
	surface.SetTextPos(x - tw * (ax or 0), y - th * (ay or 0))
	surface.DrawText(text)
	return tw, th
end

-- Truncates text with an ellipsis so it never overflows maxW pixels.
local function fitText(text, font, maxW)
	surface.SetFont(font)
	if maxW <= 0 or surface.GetTextSize(text) <= maxW then return text end
	while #text > 1 and surface.GetTextSize(text .. "…") > maxW do
		text = string.sub(text, 1, #text - 1)
	end
	return text .. "…"
end

-- A flat styled button. Returns the DButton.
local function styledButton(parent, text, baseColor, onClick)
	local btn = parent:Add("DButton")
	btn:SetText("")
	btn:SetTall(Scale(38))
	btn.Paint = function(pnl, w, h)
		local c = pnl:IsHovered()
			and Color(math.min(baseColor.r + 28, 255), math.min(baseColor.g + 28, 255), math.min(baseColor.b + 28, 255))
			or baseColor
		draw.RoundedBox(Scale(4), 0, 0, w, h, c)
		drawText(text, "ixGenericFont", w * 0.5, h * 0.5, COLOR_TEXT, 0.5, 0.5)
	end
	btn.DoClick = onClick
	return btn
end

-- ── Panel ─────────────────────────────────────────────────────────────────────

local PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	self:DockPadding(Scale(18), Scale(18), Scale(18), Scale(18))
	self.Paint = function(_, w, h)
		surface.SetDrawColor(COLOR_PAGE)
		surface.DrawRect(0, 0, w, h)
	end

	self.data = nil
	ix.gui.gangPanel = self

	-- Content host (re-populated on every sync)
	self.content = self:Add("DPanel")
	self.content:Dock(FILL)
	self.content.Paint = nil
	self.content.PerformLayout = function(_, w, h)
		if IsValid(self.centerCard) then
			self.centerCard:SetPos((w - self.centerCard:GetWide()) * 0.5,
			                       (h - self.centerCard:GetTall()) * 0.5)
		end
	end

	self:RequestSync()
	self:Rebuild()
end

function PANEL:RequestSync()
	net.Start("ixGangRequestSync")
	net.SendToServer()
end

function PANEL:SetData(payload)
	self.data = payload
	self:Rebuild()
end

function PANEL:Rebuild()
	self.centerCard  = nil
	self.upkeepLabel = nil
	self.content:Clear()

	if not self.data then
		self:BuildNoGroup()
	else
		self:BuildGroup()
	end
end

-- ── No group: centered create card ────────────────────────────────────────────

function PANEL:BuildNoGroup()
	local card = self.content:Add("DPanel")
	card:SetSize(Scale(440), Scale(296))
	card.Paint = function(_, w, h)
		draw.RoundedBox(Scale(6), 0, 0, w, h, COLOR_CARD)
		surface.SetDrawColor(COLOR_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h)
		draw.RoundedBoxEx(Scale(6), 0, 0, w, Scale(56), COLOR_CARD_HD, true, true, false, false)
		drawText("GROUPS & GANGS", "ixMediumFont", Scale(24), Scale(28), accent(), 0, 0.5)
	end
	self.centerCard = card

	local body = card:Add("DPanel")
	body:Dock(FILL)
	body:DockMargin(Scale(24), Scale(56 + 18), Scale(24), Scale(24))
	body.Paint = nil

	local desc = body:Add("DLabel")
	desc:Dock(TOP)
	desc:SetTall(Scale(48))
	desc:SetWrap(true)
	desc:SetFont("ixChatFont")
	desc:SetTextColor(COLOR_DIM)
	desc:SetText("You aren't part of a group yet. Found one to band together, claim a hideout, and share its gang class.")

	local lbl = body:Add("DLabel")
	lbl:Dock(TOP)
	lbl:DockMargin(0, Scale(8), 0, Scale(4))
	lbl:SetTall(Scale(18))
	lbl:SetFont("ixSmallFont")
	lbl:SetTextColor(COLOR_FAINT)
	lbl:SetText("GROUP NAME")

	local entry = body:Add("DTextEntry")
	entry:Dock(TOP)
	entry:SetTall(Scale(34))
	entry:SetFont("ixChatFont")
	entry:SetPlaceholderText("3-32 characters")
	entry:SetUpdateOnType(true)

	local create = styledButton(body, "Create Group", COLOR_GREEN, function()
		local name = string.Trim(entry:GetValue() or "")
		if #name < 3 then
			Derma_Message("Group name must be at least 3 characters.", "Invalid Name", "OK")
			return
		end
		net.Start("ixGangCreate")
			net.WriteString(name)
		net.SendToServer()
	end)
	create:Dock(TOP)
	create:DockMargin(0, Scale(12), 0, 0)
	create:SetTall(Scale(40))

	entry.OnEnter = function() create:DoClick() end

	self.content:InvalidateLayout()
end

-- ── In group: header banner + two-column body ─────────────────────────────────

function PANEL:BuildGroup()
	local data     = self.data
	local lchar    = LocalPlayer():GetCharacter()
	local localID  = lchar and lchar:GetID()
	local isLeader = localID and data.leaderID == localID

	local online = 0
	for _, m in ipairs(data.members) do
		if m.online then online = online + 1 end
	end

	-- ── Header banner ──
	local header = self.content:Add("DPanel")
	header:Dock(TOP)
	header:SetTall(Scale(88))
	header:DockMargin(0, 0, 0, Scale(14))
	header.Paint = function(_, w, h)
		draw.RoundedBox(Scale(6), 0, 0, w, h, COLOR_CARD)
		draw.RoundedBoxEx(Scale(6), 0, 0, Scale(6), h, accent(), true, false, true, false)
		drawText(fitText(string.upper(data.name), "ixBigFont", w - Scale(48)), "ixBigFont", Scale(24), Scale(30), COLOR_TEXT, 0, 0.5)
		local sub = #data.members .. (#data.members == 1 and " member" or " members")
			.. "  ·  " .. online .. " online"
			.. (data.baseName and ("  ·  " .. data.baseName) or "  ·  Unclaimed")
		drawText(fitText(sub, "ixChatFont", w - Scale(48)), "ixChatFont", Scale(24), Scale(62), COLOR_DIM, 0, 0.5)
	end

	-- ── Body split ──
	local body = self.content:Add("DPanel")
	body:Dock(FILL)
	body.Paint = nil

	local left = body:Add("DPanel")
	left:Dock(LEFT)
	left:SetWide(Scale(320))
	left:DockMargin(0, 0, Scale(14), 0)
	left.Paint = nil

	local right = body:Add("DPanel")
	right:Dock(FILL)
	right.Paint = nil

	self:BuildSidebar(left, data, isLeader)
	self:BuildRoster(right, data, isLeader, localID)
end

-- Left column: hideout status + leader/member actions.
function PANEL:BuildSidebar(parent, data, isLeader)
	-- Claimed-base card — height fits its content
	local card = parent:Add("DPanel")
	card:Dock(TOP)
	card:SetTall(Scale(120))
	card.Paint = function(_, w, h)
		draw.RoundedBox(Scale(6), 0, 0, w, h, COLOR_CARD)
		draw.RoundedBoxEx(Scale(6), 0, 0, w, Scale(34), COLOR_CARD_HD, true, true, false, false)
		drawText("CLAIMED BASE", "ixSmallFont", Scale(14), Scale(17), COLOR_FAINT, 0, 0.5)

		if data.baseName then
			drawText(fitText(data.baseName, "ixMediumFont", w - Scale(28)), "ixMediumFont", Scale(14), Scale(60), accent(), 0, 0.5)
			if data.upkeepExpires then
				local remaining = data.upkeepExpires - os.time()
				local txt = remaining <= 0 and "Upkeep EXPIRED"
					or ("Upkeep: " .. formatDuration(remaining) .. " left")
				drawText(txt, "ixChatFont", Scale(14), Scale(92), remaining <= 0 and COLOR_RED or COLOR_DIM, 0, 0.5)
			end
		else
			drawText("No claim", "ixMediumFont", Scale(14), Scale(60), COLOR_DIM, 0, 0.5)
		end
	end

	if data.baseName then
		card:SetTall(data.upkeepExpires and Scale(116) or Scale(86))
	else
		-- Unclaimed: the wrapped help text drives the card height
		local descTop = Scale(82)
		local desc = card:Add("DLabel")
		desc:SetPos(Scale(14), descTop)
		desc:SetWrap(true)
		desc:SetAutoStretchVertical(true)
		desc:SetFont("ixChatFont")
		desc:SetTextColor(COLOR_FAINT)
		desc:SetText("Claim a base entity to grant your group its gang class.")
		card.PerformLayout = function(pnl)
			desc:SetWide(pnl:GetWide() - Scale(28))
			desc:InvalidateLayout(true)         -- recompute wrapped height now
			local needed = descTop + desc:GetTall() + Scale(14)
			if math.abs(pnl:GetTall() - needed) > 1 then
				pnl:SetTall(needed)             -- grow/shrink to fit
				local p = pnl:GetParent()
				if IsValid(p) then p:InvalidateLayout() end
			end
		end
	end

	-- Actions card
	local actions = parent:Add("DPanel")
	actions:Dock(TOP)
	actions:DockMargin(0, Scale(14), 0, 0)
	actions:SetTall(isLeader and Scale(150) or Scale(96))
	actions.Paint = function(_, w, h)
		draw.RoundedBox(Scale(6), 0, 0, w, h, COLOR_CARD)
		draw.RoundedBoxEx(Scale(6), 0, 0, w, Scale(34), COLOR_CARD_HD, true, true, false, false)
		drawText("ACTIONS", "ixSmallFont", Scale(14), Scale(17), COLOR_FAINT, 0, 0.5)
	end

	local pad = actions:Add("DPanel")
	pad:Dock(FILL)
	pad:DockMargin(Scale(14), Scale(34 + 10), Scale(14), Scale(14))
	pad.Paint = nil

	if isLeader then
		local invite = styledButton(pad, "Invite Player", COLOR_BLUE, function() self:OpenInviteMenu() end)
		invite:Dock(TOP)

		local disband = styledButton(pad, "Disband Group", COLOR_RED, function()
			Derma_Query("Disband the entire group? This cannot be undone.", "Confirm Disband",
				"Disband", function()
					net.Start("ixGangDisband")
					net.SendToServer()
				end, "Cancel")
		end)
		disband:Dock(TOP)
		disband:DockMargin(0, Scale(8), 0, 0)
	else
		local leave = styledButton(pad, "Leave Group", COLOR_RED, function()
			Derma_Query("Leave this group?", "Confirm", "Leave", function()
				net.Start("ixGangLeave")
				net.SendToServer()
			end, "Cancel")
		end)
		leave:Dock(TOP)
	end
end

-- Right column: member roster.
function PANEL:BuildRoster(parent, data, isLeader, localID)
	local card = parent:Add("DPanel")
	card:Dock(FILL)
	card.Paint = function(_, w, h)
		draw.RoundedBox(Scale(6), 0, 0, w, h, COLOR_CARD)
		draw.RoundedBoxEx(Scale(6), 0, 0, w, Scale(34), COLOR_CARD_HD, true, true, false, false)
		drawText("MEMBERS", "ixSmallFont", Scale(14), Scale(17), COLOR_FAINT, 0, 0.5)
		drawText(tostring(#data.members), "ixSmallFont", w - Scale(14), Scale(17), COLOR_DIM, 1, 0.5)
	end

	local scroll = card:Add("DScrollPanel")
	scroll:Dock(FILL)
	scroll:DockMargin(Scale(10), Scale(34 + 8), Scale(6), Scale(10))
	local bar = scroll:GetVBar()
	bar:SetWide(Scale(6))
	bar.Paint = function() end
	bar.btnGrip.Paint = function(_, w, h)
		draw.RoundedBox(Scale(3), 0, 0, w, h, COLOR_BORDER)
	end

	for _, member in ipairs(data.members) do
		self:BuildMemberRow(scroll, member, data, isLeader, localID)
	end
end

function PANEL:BuildMemberRow(parent, member, data, isLeader, localID)
	local isLeaderMember = member.id == data.leaderID
	local isSuccessor    = member.id == data.successorID
	local initial        = string.upper(string.sub(member.name, 1, 1))

	local row = parent:Add("DPanel")
	row:Dock(TOP)
	row:DockMargin(0, 0, Scale(4), Scale(6))
	row:SetTall(Scale(66))
	row.Paint = function(pnl, w, h)
		draw.RoundedBox(Scale(5), 0, 0, w, h, pnl:IsHovered() and COLOR_ROW_HOV or COLOR_ROW)

		-- Avatar badge (vertically centred)
		local badgeSize = Scale(34)
		local badgeY    = (h - badgeSize) * 0.5
		local badgeCol  = isLeaderMember and accent() or Color(70, 70, 80)
		draw.RoundedBox(Scale(6), Scale(14), badgeY, badgeSize, badgeSize, badgeCol)
		drawText(initial, "ixMediumFont", Scale(14) + badgeSize * 0.5, badgeY + badgeSize * 0.5,
			isLeaderMember and Color(20, 20, 20) or COLOR_TEXT, 0.5, 0.5)

		-- Online status (right side, leaves room for buttons when leader)
		local statusX  = (isLeader and member.id ~= localID) and (w - Scale(150)) or (w - Scale(16))
		surface.SetDrawColor(member.online and COLOR_ONLINE or COLOR_OFFLINE)
		surface.DrawRect(statusX - Scale(10), h * 0.5 - Scale(4), Scale(8), Scale(8))
		drawText(member.online and "Online" or "Offline", "ixSmallFont",
			statusX - Scale(16), h * 0.5, member.online and COLOR_ONLINE or COLOR_FAINT, 1, 0.5)

		-- Name + role block, vertically centred and capped to avoid the status/buttons
		local textX    = Scale(14) + badgeSize + Scale(12)
		local textMaxW = math.max(Scale(40), statusX - textX - Scale(16))

		local roleParts = {}
		if isLeaderMember then roleParts[#roleParts + 1] = "Leader" end
		if isSuccessor    then roleParts[#roleParts + 1] = "Successor" end
		local roleText = #roleParts > 0 and table.concat(roleParts, "  ·  ") or "Member"

		drawText(fitText(member.name, "ixGenericFont", textMaxW), "ixGenericFont",
			textX, h * 0.5 - Scale(11), COLOR_TEXT, 0, 0.5)
		drawText(fitText(roleText, "ixSmallFont", textMaxW), "ixSmallFont",
			textX, h * 0.5 + Scale(12), isLeaderMember and accent() or COLOR_FAINT, 0, 0.5)
	end

	-- Leader controls
	if isLeader and member.id ~= localID then
		local heir = row:Add("DButton")
		heir:Dock(RIGHT)
		heir:DockMargin(0, Scale(12), Scale(12), Scale(12))
		heir:SetWide(Scale(74))
		heir:SetText("")
		heir.Paint = function(pnl, w, h)
			local on = isSuccessor
			local c = on and accent() or (pnl:IsHovered() and Color(72, 72, 82) or Color(56, 56, 64))
			draw.RoundedBox(Scale(4), 0, 0, w, h, c)
			drawText(on and "Heir ✓" or "Set Heir", "ixSmallFont", w * 0.5, h * 0.5,
				on and Color(20, 20, 20) or COLOR_TEXT, 0.5, 0.5)
		end
		heir.DoClick = function()
			net.Start("ixGangSetSuccessor")
				net.WriteUInt(member.id, 32)
			net.SendToServer()
		end

		local kick = row:Add("DButton")
		kick:Dock(RIGHT)
		kick:DockMargin(0, Scale(12), Scale(6), Scale(12))
		kick:SetWide(Scale(54))
		kick:SetText("")
		kick.Paint = function(pnl, w, h)
			draw.RoundedBox(Scale(4), 0, 0, w, h, pnl:IsHovered() and Color(205, 72, 72) or COLOR_RED)
			drawText("Kick", "ixSmallFont", w * 0.5, h * 0.5, COLOR_TEXT, 0.5, 0.5)
		end
		kick.DoClick = function()
			net.Start("ixGangKick")
				net.WriteUInt(member.id, 32)
			net.SendToServer()
		end
	end
end

-- Leader's invite picker: list online players without a character filter handled server-side.
function PANEL:OpenInviteMenu()
	local menu = DermaMenu()
	local any  = false
	for _, ply in ipairs(player.GetAll()) do
		if ply ~= LocalPlayer() and ply:GetCharacter() then
			any = true
			menu:AddOption(ply:Name(), function()
				net.Start("ixGangInvite")
					net.WriteEntity(ply)
				net.SendToServer()
			end)
		end
	end
	if not any then
		menu:AddOption("No players available"):SetEnabled(false)
	end
	menu:Open()
end

function PANEL:Think()
	if CurTime() < (self.nextUpkeepTick or 0) then return end
	self.nextUpkeepTick = CurTime() + 1
	-- The hideout card paints upkeep live from self.data each frame, so no work
	-- needed here unless the claim lapses entirely (handled by a fresh sync).
end

vgui.Register("ixGangPanel", PANEL, "DPanel")

-- ── Menu tab registration ─────────────────────────────────────────────────────

hook.Add("CreateMenuButtons", "ixGang", function(tabs)
	tabs["groups"] = function(container)
		container:Add("ixGangPanel")
	end
end)

-- ── Net handlers ──────────────────────────────────────────────────────────────

net.Receive("ixGangSync", function()
	local hasGroup = net.ReadBool()
	local payload  = hasGroup and net.ReadTable() or nil

	if IsValid(ix.gui.gangPanel) then
		ix.gui.gangPanel:SetData(payload)
	end
end)

net.Receive("ixGangInvitePrompt", function()
	local groupName = net.ReadString()
	local inviter   = net.ReadString()

	Derma_Query(
		inviter .. " has invited you to join '" .. groupName .. "'.",
		"Group Invitation",
		"Accept", function()
			net.Start("ixGangInviteResponse")
				net.WriteBool(true)
			net.SendToServer()
		end,
		"Decline", function()
			net.Start("ixGangInviteResponse")
				net.WriteBool(false)
			net.SendToServer()
		end
	)
end)
