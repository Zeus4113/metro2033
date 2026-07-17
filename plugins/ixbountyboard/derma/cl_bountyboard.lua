local function getBadge(qs, q)
    if qs.claimed then
        return "Completed", Color(80, 160, 80, 255)
    elseif not qs.accepted then
        return "Available", Color(200, 160, 60, 255)
    elseif (qs.progress or 0) >= q.count then
        return "Ready to Claim", Color(80, 160, 80, 255)
    else
        return "In Progress", Color(130, 130, 120, 255)
    end
end

-- Scales a value authored at 1920x1080 to the player's resolution, matching
-- Helix's ScreenScale (width-proportional); 1920/640 = 3.
local function Scale(n)
    return ScreenScale(n / 3)
end

local COLOR_BG        = Color(20, 20, 20, 240)
local COLOR_HEADER    = Color(35, 35, 35, 255)
local COLOR_ROW       = Color(30, 30, 30, 255)
local COLOR_ROW_SEL   = Color(50, 45, 35, 255)
local COLOR_ACCENT    = Color(200, 160, 60, 255)
local COLOR_TEXT      = Color(220, 220, 210, 255)
local COLOR_DIM       = Color(130, 130, 120, 255)
local COLOR_BAR_BG    = Color(40, 40, 40, 255)
local COLOR_BAR_FILL  = Color(200, 160, 60, 200)

local PANEL = {}

function PANEL:Init()
    self:SetSize(Scale(480), Scale(540))
    self:SetTitle("")
    self:SetDraggable(true)
    self:SetDeleteOnClose(true)
    self:MakePopup()
    self:Center()

    self.quests   = {}
    self.state    = {}
    self.selected = nil

    -- Header
    self.header = self:Add("DPanel")
    self.header:Dock(TOP)
    self.header:SetTall(Scale(40))
    self.header.Paint = function(pnl, w, h)
        surface.SetDrawColor(COLOR_HEADER)
        surface.DrawRect(0, 0, w, h)
        surface.SetTextColor(COLOR_ACCENT)
        surface.SetFont("ixMediumFont")
        local title = "BOUNTY BOARD"
        local tw = surface.GetTextSize(title)
        surface.SetTextPos((w - tw) * 0.5, Scale(10))
        surface.DrawText(title)
    end


    -- Quest list (top half)
    self.listPanel = self:Add("DScrollPanel")
    self.listPanel:Dock(TOP)
    self.listPanel:SetTall(Scale(220))
    self.listPanel:DockMargin(Scale(8), Scale(8), Scale(8), 0)
    self.listPanel:GetVBar():SetWide(Scale(4))

    -- Detail pane (bottom half)
    self.detail = self:Add("DPanel")
    self.detail:Dock(FILL)
    self.detail:DockMargin(Scale(8), Scale(8), Scale(8), Scale(8))
    self.detail.Paint = function(pnl, w, h)
        surface.SetDrawColor(COLOR_ROW)
        surface.DrawRect(0, 0, w, h)
    end

    self.detailName = self.detail:Add("DLabel")
    self.detailName:SetFont("ixMediumFont")
    self.detailName:SetTextColor(COLOR_ACCENT)
    self.detailName:SetPos(Scale(10), Scale(10))
    self.detailName:SetSize(Scale(300), Scale(24))
    self.detailName:SetText("")

    self.detailReward = self.detail:Add("DLabel")
    self.detailReward:SetFont("ixChatFont")
    self.detailReward:SetTextColor(COLOR_TEXT)
    self.detailReward:SetPos(Scale(10), Scale(36))
    self.detailReward:SetSize(Scale(460), Scale(20))
    self.detailReward:SetText("")

    self.detailDesc = self.detail:Add("DLabel")
    self.detailDesc:SetFont("ixChatFont")
    self.detailDesc:SetTextColor(COLOR_DIM)
    self.detailDesc:SetPos(Scale(10), Scale(58))
    self.detailDesc:SetSize(Scale(460), Scale(20))
    self.detailDesc:SetText("")

    -- Progress bar
    self.progressBG = self.detail:Add("DPanel")
    self.progressBG:SetPos(Scale(10), Scale(86))
    self.progressBG:SetSize(Scale(380), Scale(12))
    self.progressBG.Paint = function(pnl, w, h)
        if not self.selected then return end
        surface.SetDrawColor(COLOR_BAR_BG)
        surface.DrawRect(0, 0, w, h)
    end

    self.progressFill = self.progressBG:Add("DPanel")
    self.progressFill:SetPos(0, 0)
    self.progressFill:SetSize(0, Scale(12))
    self.progressFill.Paint = function(pnl, w, h)
        surface.SetDrawColor(COLOR_BAR_FILL)
        surface.DrawRect(0, 0, w, h)
    end

    self.progressLabel = self.detail:Add("DLabel")
    self.progressLabel:SetFont("ixChatFont")
    self.progressLabel:SetTextColor(COLOR_TEXT)
    self.progressLabel:SetPos(Scale(398), Scale(82))
    self.progressLabel:SetSize(Scale(70), Scale(20))
    self.progressLabel:SetText("")

    -- Action button
    self.actionBtn = self.detail:Add("DButton")
    self.actionBtn:SetPos(Scale(10), Scale(108))
    self.actionBtn:SetSize(Scale(460), Scale(34))
    self.actionBtn:SetFont("ixMediumFont")
    self.actionBtn:SetText("")
    self.actionBtn.Paint = function(pnl, w, h)
        if not self.selected then return end
        local col = pnl.disabled and COLOR_DIM or (pnl:IsHovered() and Color(220,180,70,255) or COLOR_ACCENT)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, w, h)
        surface.SetTextColor(COLOR_BG)
        surface.SetFont("ixMediumFont")
        local tw, th = surface.GetTextSize(pnl.label or "")
        surface.SetTextPos((w - tw) * 0.5, (h - th) * 0.5)
        surface.DrawText(pnl.label or "")
    end
    self.actionBtn.DoClick = function()
        if self.actionBtn.disabled or not self.selected then return end
        local idx = self.selected
        local q   = self.quests[idx]
        local qs  = self.state[idx]
        if not q or not qs then return end

        if not qs.accepted then
            net.Start("ixBountyAccept")
                net.WriteUInt(idx, 8)
            net.SendToServer()
        elseif q.type == "collect" or qs.progress >= q.count then
            net.Start("ixBountyClaim")
                net.WriteUInt(idx, 8)
            net.SendToServer()
        end
    end

    -- Range check
    self.nextRangeCheck = 0
end

function PANEL:Setup(entity, quests, state)
    self.entity = entity
    self.quests = quests
    self.state  = state
    self:RebuildList()
    if self.selected then
        self:SelectQuest(self.selected)
    end
end

function PANEL:RebuildList()
    self.listPanel:Clear()
    for i, q in ipairs(self.quests) do
        local qs  = self.state[i] or { accepted = false, progress = 0, claimed = false }
        local row = self.listPanel:Add("DPanel")
        row:SetTall(Scale(40))
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, Scale(2))

        local sel = self.selected == i
        row.Paint = function(pnl, w, h)
            surface.SetDrawColor(sel and COLOR_ROW_SEL or COLOR_ROW)
            surface.DrawRect(0, 0, w, h)
            -- Quest name
            surface.SetFont("ixChatFont")
            surface.SetTextColor(qs.claimed and COLOR_DIM or COLOR_TEXT)
            surface.SetTextPos(Scale(10), Scale(12))
            surface.DrawText(q.name)
            -- Status badge
            local badge, badgeCol = getBadge(qs, q)
            surface.SetFont("ixChatFont")
            surface.SetTextColor(badgeCol)
            local tw = surface.GetTextSize(badge)
            surface.SetTextPos(w - tw - Scale(12), Scale(12))
            surface.DrawText(badge)
        end

        row:SetCursor("hand")
        row.OnMousePressed = function()
            self.selected = i
            self:RebuildList()
            self:SelectQuest(i)
        end
    end
end

function PANEL:SelectQuest(idx)
    local q  = self.quests[idx]
    local qs = self.state[idx]
    if not q or not qs then return end

    self.detailName:SetText(q.name)
    self.detailReward:SetText("Reward: " .. q.reward .. " karma")
    self.detailDesc:SetText(string.format(q.desc, q.count))

    local prog     = qs.progress or 0
    local fraction = math.Clamp(prog / q.count, 0, 1)
    local barW     = self.progressBG:GetWide()
    self.progressFill:SetWide(math.Round(barW * fraction))
    self.progressLabel:SetText(prog .. " / " .. q.count)

    -- Button state
    local btn = self.actionBtn
    if qs.claimed then
        btn.label    = "Completed"
        btn.disabled = true
    elseif not qs.accepted then
        btn.label    = "Accept Bounty"
        btn.disabled = false
    elseif q.type == "kill" and prog < q.count then
        btn.label    = "In Progress"
        btn.disabled = true
    elseif q.type == "collect" then
        btn.label    = "Claim Reward"
        btn.disabled = false
    elseif prog >= q.count then
        btn.label    = "Claim Reward"
        btn.disabled = false
    else
        btn.label    = "In Progress"
        btn.disabled = true
    end
end

function PANEL:Think()
    -- Close if entity gone or player walked away.
    if CurTime() > self.nextRangeCheck then
        self.nextRangeCheck = CurTime() + 0.5
        local ent = self.entity
        if not IsValid(ent) then
            self:Close()
            return
        end
        local range = ix.config.Get("bountyBoardRange", 96)
        if LocalPlayer():GetPos():DistToSqr(ent:GetPos()) > (range * 2) ^ 2 then
            self:Close()
        end
    end
end

function PANEL:OnClose()
    ix.gui.bountyboard = nil
    net.Start("ixBountyClose")
    net.SendToServer()
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(COLOR_BG)
    surface.DrawRect(0, 0, w, h)
end

vgui.Register("ixBountyBoard", PANEL, "DFrame")

-- Open panel.
net.Receive("ixBountyOpen", function()
    local entity = net.ReadEntity()
    local quests = net.ReadTable()
    local state  = net.ReadTable()

    if IsValid(ix.gui.bountyboard) then
        ix.gui.bountyboard:Remove()
    end

    ix.gui.bountyboard = vgui.Create("ixBountyBoard")
    ix.gui.bountyboard:Setup(entity, quests, state)
end)

-- State refresh (after accept / claim / kill progress).
net.Receive("ixBountyStateUpdate", function()
    local state = net.ReadTable()

    -- Empty table signals the board was removed.
    if table.IsEmpty(state) then
        if IsValid(ix.gui.bountyboard) then
            ix.gui.bountyboard:Remove()
        end
        return
    end

    if IsValid(ix.gui.bountyboard) then
        ix.gui.bountyboard.state = state
        ix.gui.bountyboard:RebuildList()
        if ix.gui.bountyboard.selected then
            ix.gui.bountyboard:SelectQuest(ix.gui.bountyboard.selected)
        end
    end
end)
