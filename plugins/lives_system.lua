local PLUGIN = PLUGIN or {}
PLUGIN.name = "Lives System"
PLUGIN.author = "BarneytheBandit"
PLUGIN.description = "Adds a lives system to the game, limiting the number of times a character can die before being permanently dead."

ix.config.Add("maxLives", 3, "The maximum number of lives a player can have.", nil, {
    data = {min = 1, max = 10},
    category = "Lives System"
})

ix.command.Add("CheckLives", {
    description = "Check how many lives you have remaining.",
    OnRun = function(self, client)
        if not client or not client:GetCharacter() then return end

        local char = client:GetCharacter()
        local lives = char:GetData("lives", ix.config.Get("maxLives"))
        client:ChatPrint("You have " .. lives .. " lives remaining.")
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
        local lives = char:GetData("lives", ix.config.Get("maxLives"))
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
        char:SetData("lives", math.Clamp(lives, 0, ix.config.Get("maxLives")))
        target:ChatPrint("Your lives have been set to " .. char:GetData("lives") .. ".")
        client:ChatPrint("Set " .. target:Name() .. "'s lives to " .. char:GetData("lives") .. ".")
    end
})

function PLUGIN:ShouldPermakillCharacter(client, character, inflictor, attacker)

    if client.ixInArea and ix.area.stored[client.ixArea].type == "safe zone" then
        return false
    end

    local lives = character:GetData("lives", ix.config.Get("maxLives"))
    return lives <= 0

end

function PLUGIN:CharacterLoaded(character)
    if not character then return end
    if not character:GetData("lives") then
        character:SetData("lives", ix.config.Get("maxLives"))
        character:GetPlayer():ChatPrint("You have been given " .. ix.config.Get("maxLives") .. " lives.")
    end
end

function PLUGIN:PlayerDeath(client, inflictor, attacker)
    if not client or not client:GetCharacter() then return end

    if client.ixInArea and ix.area.stored[client.ixArea].type == "safe zone" then
        client:ChatPrint("You have died in a safe zone. Your lives have not been reduced.")
        return
    end

    local char = client:GetCharacter()
    local lives = char:GetData("lives", ix.config.Get("maxLives"))

    if lives > 0 then
        char:SetData("lives", lives - 1)
        client:ChatPrint("You have " .. (lives - 1) .. " lives remaining.")
    else
        client:ChatPrint("You have no lives remaining. You are permanently dead.")
        -- Here you can add any additional logic for when a player runs out of lives, such as banning them or marking them as permanently dead in the database.
    end
end

function PLUGIN:OnCharacterCreated(client, character)
    character:SetData("lives", ix.config.Get("maxLives"))
end