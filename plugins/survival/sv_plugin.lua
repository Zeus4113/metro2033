local NEXT_TICK = 0

hook.Add("PlayerDeath", "ResetHungerThirst",  function( victim, inflictor, attacker )
    if not victim then return end
    local character = victim:GetCharacter()
    if not character then return end
    character:SetHunger(math.min(character:GetHunger() + 25, 100))
    character:SetThirst(math.min(character:GetThirst() + 25, 100))
end)

function PLUGIN:Think()
	if CurTime() < NEXT_TICK then return end
	NEXT_TICK = CurTime() + ix.config.Get("DrainTick") or 1

	for k, client in ipairs(player.GetAll()) do
		if not client:Alive() then continue end
		local character = client:GetCharacter()
		if not character then continue end
		if character:GetData("BlockingRadiation") then continue end

		local hunger = character:GetHunger()
		local thirst = character:GetThirst()

		local survival = character:GetAttribute("survival", 0)

		hunger = math.max(hunger - (ix.config.Get("HungerDrain") - (ix.config.Get("survivalHungerResist", 1) * survival)), 0)
		thirst = math.max(thirst - (ix.config.Get("ThirstDrain") - (ix.config.Get("survivalThirstResist", 1) * survival)), 0)

		character:SetHunger(hunger)
		character:SetThirst(thirst)

		if hunger <= 0 then
			client:Notify("You are starving, find some food immediately.")
			local dmg = DamageInfo()
			dmg:SetDamage(ix.config.Get("StarvationDamage"))
			dmg:SetDamageType(DMG_RADIATION)
			dmg:SetAttacker(game.GetWorld())
			dmg:SetInflictor(game.GetWorld())
			client:TakeDamageInfo(dmg)
			character:SetStaminaMultiplier(2)

		elseif hunger <= 25 then
			client:Notify("You are very hungry.")
			character:SetStaminaMultiplier(1.5)

		elseif hunger <= 50 then
			client:Notify("You are hungry.")
			character:SetStaminaMultiplier(1.25)

		else
			character:SetStaminaMultiplier(1)

		end

		if thirst <= 0 then
			client:Notify("You are dehydrated, find some water immediately.")

			local dmg = DamageInfo()
			dmg:SetDamage(ix.config.Get("DehydrationDamage"))
			dmg:SetDamageType(DMG_RADIATION)
			dmg:SetAttacker(game.GetWorld())
			dmg:SetInflictor(game.GetWorld())
			client:TakeDamageInfo(dmg)
			character:SetStaminaMultiplier(2)

		elseif thirst <= 25 then
			client:Notify("You are very thirsty.")
			character:SetStaminaMultiplier(1.5)

		elseif thirst <= 50 then
			client:Notify("You are thirsty.")
			character:SetStaminaMultiplier(1.25)

		else
			character:SetStaminaMultiplier(1)

		end
	end
end