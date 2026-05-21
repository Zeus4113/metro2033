local PLUGIN = PLUGIN

PLUGIN.name        = "Bounty Board"
PLUGIN.author      = "metro2033"
PLUGIN.description = "Daily bounty quests rewarding karma for kills and item delivery."

ix.config.Add("bountyDailyCount",  5, "Number of bounties offered each day.", nil, {
    data = {min = 1, max = 17},
    category = PLUGIN.name,
})

ix.config.Add("bountyActiveLimit", 2, "Max bounties a player can have active at once.", nil, {
    data = {min = 1, max = 5},
    category = PLUGIN.name,
})

ix.config.Add("bountyBoardRange", 96, "Max distance (units) to interact with the bounty board.", nil, {
    data = {min = 32, max = 256},
    category = PLUGIN.name,
})

PLUGIN.bountyPool = {
    -- Kill quests
    { id = "kill_churzik",        type = "kill",    target = "npc_churzik",             count = 3, reward = 3, name = "Pest Control",        desc = "Kill %d Lurkers." },
    { id = "kill_nosach_samec",         type = "kill",    target = "npc_nosach_samec",        count = 3, reward = 5, name = "Mutant Hunt",         desc = "Kill %d Nosalises." },
    { id = "kill_murzik",         type = "kill",    target = "npc_murzik",      count = 4, reward = 8, name = "Surface Tension",         desc = "Kill %d Watchmen." },
    { id = "kill_biblio",        type = "kill",    target = "npc_bibliotekar_redux",  count = 2, reward = 6, name = "Silence at the Library", desc = "Kill %d Librarians." },
    { id = "kill_kristomutant",        type = "kill",    target = "npc_krisomutant",  count = 1, reward = 5, name = "Death from Above", desc = "Kill a Demon." },
    -- Collect / deliver quests
    { id = "col_mushroom",       type = "collect", target = "mushroom",               count = 5, reward = 3, name = "Mushroom Run",        desc = "Deliver %d mushrooms." },
    { id = "col_mutant_meat",    type = "collect", target = "mutant_meat",            count = 3, reward = 4, name = "Butcher's Order",     desc = "Deliver %d mutant meat." },
    { id = "col_watcher_hide",   type = "collect", target = "watcher_hide",           count = 2, reward = 5, name = "Tanner's Request",    desc = "Deliver %d watcher hides." },
    { id = "col_metal_scrap",    type = "collect", target = "metal_scrap",            count = 5, reward = 3, name = "Scrap Run",           desc = "Deliver %d metal scrap." },
    { id = "col_electronics",    type = "collect", target = "electronics",            count = 3, reward = 4, name = "Circuit Salvage",     desc = "Deliver %d electronics." },
    { id = "col_chemicals",      type = "collect", target = "chemicals",              count = 2, reward = 4, name = "Chemical Supply",     desc = "Deliver %d chemicals." },
    { id = "col_cloth",          type = "collect", target = "cloth",                  count = 4, reward = 3, name = "Textile Requisition", desc = "Deliver %d cloth." },
    { id = "col_filter",         type = "collect", target = "filter",                 count = 3, reward = 4, name = "Filter Drive",        desc = "Deliver %d filters." },
    { id = "col_first_aid_kit",  type = "collect", target = "first_aid_kit",          count = 1, reward = 5, name = "Medical Procurement", desc = "Deliver a first aid kit." },
    { id = "col_purified_water", type = "collect", target = "purified_water",         count = 3, reward = 3, name = "Water Collection",    desc = "Deliver %d purified water." },
    { id = "col_organics",       type = "collect", target = "organics",               count = 3, reward = 3, name = "Organic Matter",      desc = "Deliver %d organics." },
    { id = "col_mech_parts",     type = "collect", target = "mechanical_parts",       count = 2, reward = 4, name = "Parts Requisition",   desc = "Deliver %d mechanical parts." },
    { id = "col_medkit",         type = "collect", target = "medkit",                 count = 1, reward = 6, name = "Critical Supplies",   desc = "Deliver a medkit." },
}

-- Deterministic daily selection seeded by date + refresh counter.
function PLUGIN:GetDailyBounties()
    local dateKey = tonumber(os.date("%Y%m%d")) + (self.refreshSeed or 0) * 100003
    local count   = ix.config.Get("bountyDailyCount", 5)
    local pool    = self.bountyPool
    local selected, used = {}, {}
    local state = dateKey
    while #selected < math.min(count, #pool) do
        state = (state * 1664525 + 1013904223) % (2 ^ 32)
        local idx = (state % #pool) + 1
        if not used[idx] then
            used[idx] = true
            selected[#selected + 1] = pool[idx]
        end
    end
    return selected
end

-- Returns the character's quest state for today, resetting if the date changed.
function PLUGIN:GetOrInitState(character)
    local today = os.date("%Y%m%d")
    local saved = character:GetData("bountyState", {})
    if saved.date ~= today then
        saved = { date = today, quests = {} }
        for i = 1, ix.config.Get("bountyDailyCount", 5) do
            saved.quests[i] = { accepted = false, progress = 0, claimed = false }
        end
        character:SetData("bountyState", saved)
    end
    return saved
end

if SERVER then
    util.AddNetworkString("ixBountyOpen")
    util.AddNetworkString("ixBountyClose")
    util.AddNetworkString("ixBountyAccept")
    util.AddNetworkString("ixBountyClaim")
    util.AddNetworkString("ixBountyStateUpdate")

    ix.util.Include("sv_plugin.lua")
end

if CLIENT then
    ix.util.Include("derma/cl_bountyboard.lua")
end
