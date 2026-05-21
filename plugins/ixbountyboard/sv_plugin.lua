local PLUGIN = PLUGIN

-- Load persisted refresh seed so the board doesn't revert after a server restart.
file.CreateDir("ix")
PLUGIN.refreshSeed = tonumber(file.Read("ix/bounty_refresh_seed.txt", "DATA")) or 0

ix.command.Add("BountyRefresh", {
    description = "Refresh the bounty board with a new set of daily quests and reset all player progress.",
    adminOnly   = true,
    OnRun = function(_, client)
        PLUGIN.refreshSeed = PLUGIN.refreshSeed + 1
        file.Write("ix/bounty_refresh_seed.txt", tostring(PLUGIN.refreshSeed))

        local today = os.date("%Y%m%d")
        local count = ix.config.Get("bountyDailyCount", 5)

        for _, ply in ipairs(player.GetAll()) do
            local char = ply:GetCharacter()
            if char then
                local state = { date = today, quests = {} }
                for i = 1, count do
                    state.quests[i] = { accepted = false, progress = 0, claimed = false }
                end
                char:SetData("bountyState", state)
                char:Save()
            end

            if ply.ixBountyEnt then
                ply.ixBountyEnt = nil
                net.Start("ixBountyStateUpdate")
                    net.WriteTable({})
                net.Send(ply)
            end
        end

        client:Notify("Bounty board refreshed — new quests are now available.")
    end,
})

-- Kill tracking: progress only increments on accepted, unclaimed kill quests.
hook.Add("OnNPCKilled", "ixBountyKillTrack", function(npc, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    local char = attacker:GetCharacter()
    if not char then return end

    local state   = PLUGIN:GetOrInitState(char)
    local bounties = PLUGIN:GetDailyBounties()
    local changed = false

    for i, q in ipairs(bounties) do
        local qs = state.quests[i]
        if qs and q.type == "kill" and q.target == npc:GetClass()
            and qs.accepted and not qs.claimed and qs.progress < q.count then
            qs.progress = qs.progress + 1
            changed = true
        end
    end

    if changed then
        char:SetData("bountyState", state)
        net.Start("ixBountyStateUpdate")
            net.WriteTable(state.quests)
        net.Send(attacker)
    end
end)

-- Accept a bounty.
net.Receive("ixBountyAccept", function(_, client)
    local ent = client.ixBountyEnt
    if not IsValid(ent) then return end
    if client:GetPos():DistToSqr(ent:GetPos()) > ix.config.Get("bountyBoardRange", 96) ^ 2 then return end

    local char = client:GetCharacter()
    if not char then return end

    local idx     = net.ReadUInt(8)
    local bounties = PLUGIN:GetDailyBounties()
    if not bounties[idx] then return end

    local state = PLUGIN:GetOrInitState(char)
    local qs    = state.quests[idx]
    if not qs or qs.accepted or qs.claimed then return end

    -- Enforce active limit.
    local active = 0
    for _, q in ipairs(state.quests) do
        if q.accepted and not q.claimed then active = active + 1 end
    end
    if active >= ix.config.Get("bountyActiveLimit", 2) then
        client:Notify("You already have " .. ix.config.Get("bountyActiveLimit", 2) .. " active bounties. Complete one first.")
        return
    end

    qs.accepted = true
    char:SetData("bountyState", state)

    net.Start("ixBountyStateUpdate")
        net.WriteTable(state.quests)
    net.Send(client)
end)

-- Claim a completed bounty.
net.Receive("ixBountyClaim", function(_, client)
    local ent = client.ixBountyEnt
    if not IsValid(ent) then return end
    if client:GetPos():DistToSqr(ent:GetPos()) > ix.config.Get("bountyBoardRange", 96) ^ 2 then return end

    local char = client:GetCharacter()
    if not char then return end

    local idx     = net.ReadUInt(8)
    local bounties = PLUGIN:GetDailyBounties()
    local q       = bounties[idx]
    if not q then return end

    local state = PLUGIN:GetOrInitState(char)
    local qs    = state.quests[idx]
    if not qs or not qs.accepted or qs.claimed then return end

    if q.type == "kill" then
        if qs.progress < q.count then
            client:Notify("You haven't completed this bounty yet. (" .. qs.progress .. "/" .. q.count .. ")")
            return
        end

    elseif q.type == "collect" then
        local inv   = char:GetInventory()
        local items = inv:GetItems()
        local found = {}
        for _, item in pairs(items) do
            if item.uniqueID == q.target and not item:GetData("equip", false) then
                found[#found + 1] = item
                if #found >= q.count then break end
            end
        end
        if #found < q.count then
            local itemDef = ix.item.list[q.target]
            local itemName = (itemDef and itemDef.name) or q.target
            client:Notify("You need " .. q.count .. "x " .. itemName .. " to claim this bounty. (" .. #found .. "/" .. q.count .. ")")
            return
        end
        for _, item in ipairs(found) do
            item:Remove()
        end
    end

    -- Award karma clamped to server limits.
    local karmaMin = ix.config.Get("karmaMin", -300)
    local karmaMax = ix.config.Get("karmaMax", 300)
    char:SetKarma(math.Clamp(char:GetKarma() + q.reward, karmaMin, karmaMax))

    qs.claimed  = true
    qs.progress = q.count
    char:SetData("bountyState", state)
    char:Save()

    client:Notify("Bounty complete! +" .. q.reward .. " karma. Total: " .. char:GetKarma())

    net.Start("ixBountyStateUpdate")
        net.WriteTable(state.quests)
    net.Send(client)
end)

-- Player closed the board.
net.Receive("ixBountyClose", function(_, client)
    client.ixBountyEnt = nil
end)

local function closeBoardFor(ply)
    if not ply.ixBountyEnt then return end
    ply.ixBountyEnt = nil
    net.Start("ixBountyStateUpdate")
        net.WriteTable({})
    net.Send(ply)
end

hook.Add("PlayerDeath", "ixBountyCloseOnDeath", function(ply)
    closeBoardFor(ply)
end)

hook.Add("PlayerDisconnected", "ixBountyCloseOnDisconnect", function(ply)
    closeBoardFor(ply)
end)
