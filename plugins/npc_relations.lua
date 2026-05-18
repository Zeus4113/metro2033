PLUGIN.name        = "NPC Relations"
PLUGIN.author      = "metro2033"
PLUGIN.description = "Keeps neutral SNPC groups from targeting or damaging each other."

if not SERVER then return end

-- Groups of SNPC classnames that should be allied to one another.
local neutralGroups = {
    { "npc_murzik", "npc_krisomutant", "npc_krisomutant_brute", "npc_bibliotekar_redux" },
}

-- Build lookup: classname -> set of classnames it is allied to.
local neutralTo = {}
for _, group in ipairs(neutralGroups) do
    for _, class in ipairs(group) do
        neutralTo[class] = neutralTo[class] or {}
        for _, other in ipairs(group) do
            if other ~= class then
                neutralTo[class][other] = true
            end
        end
    end
end

local function ApplyNeutral(ent)
    if not IsValid(ent) or not ent:IsNPC() then return end
    local blocked = neutralTo[ent:GetClass()]
    if not blocked then return end

    -- lima_metro_base gate: blocks BecomeHostile() for group members.
    local origCanBecomeHostile = ent.CanBecomeHostile
    function ent:CanBecomeHostile(target, tr)
        if IsValid(target) and blocked[target:GetClass()] then return false end
        if origCanBecomeHostile then return origCanBecomeHostile(self, target, tr) end
        return true
    end

    -- lima_metro_base disposition check.
    local origGetRelationshipCustom = ent.GetRelationshipCustom
    function ent:GetRelationshipCustom(target)
        if IsValid(target) and blocked[target:GetClass()] then return D_NU end
        if origGetRelationshipCustom then return origGetRelationshipCustom(self, target) end
    end

    -- Bibliotekar-specific: intercept GetRelationship before it caches D_HT in
    -- RegisteredEnts on first sight. Once D_HT is cached, GetRelationship2 returns
    -- it immediately and nothing downstream can override it.
    local origGetRelationship = ent.GetRelationship
    function ent:GetRelationship(target)
        if IsValid(target) and blocked[target:GetClass()] then
            if self.RegisteredEnts then self.RegisteredEnts[target] = D_NU end
            if self.FullyAggressive then self.FullyAggressive[target] = false end
            return D_NU
        end
        if origGetRelationship then return origGetRelationship(self, target) end
    end

    -- Bibliotekar-specific: DoTouch calls SetEnemy directly, bypassing BecomeHostile
    -- entirely. All 5 hostility paths in Think2 go through DoTouch.
    local origDoTouch = ent.DoTouch
    function ent:DoTouch(target, tr)
        if IsValid(target) and blocked[target:GetClass()] then return end
        if origDoTouch then return origDoTouch(self, target, tr) end
    end

    -- Reduce detection range so the Bibliotekar doesn't see group members at normal
    -- engagement distance. Default is 3500; 500 matches its own eating-mode range.
    if ent:GetClass() == "npc_bibliotekar_redux" then
        ent:SetMaxLookDistance(2000)
    end
end

hook.Add("OnEntityCreated", "metroNPCNeutral", function(ent)
    -- Delay so the SNPC's own Initialize() runs before we override.
    timer.Simple(0.1, function()
        ApplyNeutral(ent)
    end)
end)

-- Hard fallback: block damage regardless of what targeting code ran.
hook.Add("EntityTakeDamage", "metroNPCNeutralDamage", function(target, dmginfo)
    if not target:IsNPC() then return end
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsNPC() then return end
    local blocked = neutralTo[target:GetClass()]
    if blocked and blocked[attacker:GetClass()] then return true end
end)
