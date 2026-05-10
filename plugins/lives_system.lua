local PLUGIN = PLUGIN or {}
PLUGIN.name = "Lives System"
PLUGIN.author = "BarneytheBandit"
PLUGIN.description = "Adds a lives system to the game, limiting the number of times a character can die before being permanently dead."

ix.config.Add("lifeCost", 100, "How much karma does one life cost?", nil, {
    data = {min = 1, max = 1000},
    category = "Lives System"
})

ix.config.Add("karmaMin", -300, "Minimum karma a character can have.", nil, {
    data = {min = -10000, max = 0},
    category = "Lives System"
})

ix.config.Add("karmaMax", 300, "Maximum karma a character can have.", nil, {
    data = {min = 0, max = 10000},
    category = "Lives System"
})

ix.config.Add("maxLives", 3, "The maximum number of lives a player can have.", nil, {
    data = {min = 1, max = 10},
    category = "Lives System"
})

ix.char.RegisterVar("karma", {
    field = "karma",
    fieldType = ix.type.number,
    default = 0
})

ix.char.RegisterVar("lives", {
    field = "lives",
    fieldType = ix.type.number,
    default = ix.config.Get("maxLives", 3)
})

ix.command.Add("CheckKarma", {
    description = "Check how many karma points your character has.",
    OnRun = function(self, client)
        if not client or not client:GetCharacter() then return end
        client:ChatPrint("You have " .. client:GetCharacter():GetKarma().. " karma points.")
    end
})

ix.command.Add("CheckLives", {
    description = "Check how many lives you have remaining.",
    OnRun = function(self, client)
        if not client or not client:GetCharacter() then return end
        
        local char = client:GetCharacter()
        local lives = char:GetLives()
        client:ChatPrint("You have " .. lives .. " lives remaining.")
    end
})

ix.command.Add("BuyLife",{
    description = "Trade " .. ix.config.Get("lifeCost", 100) .. " karma points for a life.",
    OnRun = function(self, client)
        if not client or not client:GetCharacter() then return end
        local character = client:GetCharacter()

        if character:GetLives() >= ix.config.Get("maxLives", 3) then
            client:ChatPrint("You already have the maximum amount of lives.")
            return
        end

        if character:GetKarma() >= ix.config.Get("lifeCost", 100) then
            character:SetLives(character:GetLives() + 1)
            character:SetKarma(math.Clamp(character:GetKarma() - ix.config.Get("lifeCost", 100), ix.config.Get("karmaMin", -300), ix.config.Get("karmaMax", 300)))
            client:ChatPrint("You now have " .. character:GetLives() .. " lives.")
        else
            client:ChatPrint("You do not have enough karma points.")
        end
    end
})

ix.command.Add("CharGiveKarma", {
    description = "Give karma to a target character. (Admin Only)",
    adminOnly = true,
    arguments = {
        ix.type.string,
        ix.type.number
    },
    OnRun = function(self, client, targetName, amount)
        local target = ix.util.FindPlayer(targetName)

        if not target or not target:GetCharacter() then return end

        local character = target:GetCharacter()
        character:SetKarma(math.Clamp(character:GetKarma() + amount, ix.config.Get("karmaMin", -300), ix.config.Get("karmaMax", 300)))
        client:ChatPrint("You have given out " .. amount .. " karma points.")
        target:ChatPrint("You have recieved " .. amount .. " karma points, your total is now " .. character:GetKarma() .. ".")

    end
})



ix.command.Add("CharCheckKarma", {
    description = "Check how much karma another player has. (Admin Only)",
    adminOnly = true,
    arguments = {
        ix.type.string
    },
    OnRun = function(self, client, targetName)
        local target = ix.util.FindPlayer(targetName)

        if not target or not target:GetCharacter() then
            return client:ChatPrint("Player not found.")
        end

        local char = target:GetCharacter()
        client:ChatPrint(target:Name() .. " has " .. char:GetKarma() .. " karma points.")
    end
})

ix.command.Add("CharCheckLives", {
    description = "Check how many lives another player has. (Admin Only)",
    adminOnly = true,
    arguments = {
        ix.type.string -- target player
    },
    OnRun = function(self, client, targetName)
        local target = ix.util.FindPlayer(targetName)

        if not target or not target:GetCharacter() then
            return client:ChatPrint("Player not found.")
        end

        local char = target:GetCharacter()
        local lives = char:GetLives()
        client:ChatPrint(target:Name() .. " has " .. lives .. " lives remaining.")
    end
})

ix.command.Add("CharSetLives", {
    description = "Set the number of lives for a player. (Admin Only)",
    adminOnly = true,
    arguments = {
        ix.type.string, -- target player
        ix.type.number -- number of lives
    },
    OnRun = function(self, client, targetName, lives)
        local target = ix.util.FindPlayer(targetName)

        if not target or not target:GetCharacter() then
            return client:ChatPrint("Player not found.")
        end

        local char = target:GetCharacter()
        char:SetLives(math.Clamp(lives, 0, ix.config.Get("maxLives")))
        target:ChatPrint("Your lives have been set to " .. char:GetLives() .. ".")
        client:ChatPrint("Set " .. target:Name() .. "'s lives to " .. char:GetLives() .. ".")
    end
})

function PLUGIN:ShouldPermakillCharacter(client, character, inflictor, attacker)

    if client.ixInArea and ix.area.stored[client.ixArea] and ix.area.stored[client.ixArea].type == "safe zone" then
        return false
    end

    local lives = character:GetLives()
    return lives <= 0

end

function PLUGIN:CharacterLoaded(character)
    if not character then return end

    if character:GetData("lives", nil) then
        character:SetLives(character:GetData("lives"))
        character:SetData("lives", nil)
        character:GetPlayer():ChatPrint("You have been given " .. character:GetLives() .. " lives.")
    end

    if not character:GetLives() then
        character:SetLives(ix.config.Get("maxLives"))
        character:GetPlayer():ChatPrint("You have been given " .. character:GetLives() .. " lives.")
    end
end

function PLUGIN:PlayerDeath(client, inflictor, attacker)
    if not client or not client:GetCharacter() then return end

    if client.ixInArea and ix.area.stored[client.ixArea] and ix.area.stored[client.ixArea].type == "safe zone" then
        client:ChatPrint("You have died in a safe zone. Your lives have not been reduced.")
        return
    end

    local char = client:GetCharacter()
    local lives = char:GetLives()

    if lives > 1 then
        char:SetLives(lives - 1)
        client:ChatPrint("You have " .. (lives - 1) .. " lives remaining.")
    elseif lives == 1 then
        char:SetLives(0)
        client:ChatPrint("You have died on your last life. Your character is permanently dead.")
    else
        client:ChatPrint("You have no lives remaining. Your character is permanently dead.")
    end
end

function PLUGIN:OnCharacterCreated(client, character)
    character:SetLives(ix.config.Get("maxLives"))
end