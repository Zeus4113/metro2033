if not CLIENT then return end

-- HUNGER
ix.bar.Add(function()
    local client = LocalPlayer()
    local char = client:GetCharacter()

    if not char then return 0 end

    return math.Clamp(char:GetHunger() / 100, 0, 1)
end, Color(101, 156, 86), nil, "hunger")

-- THIRST
ix.bar.Add(function()
    local client = LocalPlayer()
    local char = client:GetCharacter()

    if not char then return 0 end

    return math.Clamp(char:GetThirst() / 100, 0, 1)
end, Color(86, 142, 156), nil, "thirst")