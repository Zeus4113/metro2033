PLUGIN.name = "Durability"
PLUGIN.author = "STEAM_0:1:29606990" -- AleXXX_007 - original idea.
PLUGIN.description = "Adds durability for all weapons."

-- HL2 Weapons bullet damage is not counted.
-- bullet.Damage = (bullet.Damage / 100) * durability
-- bullet.Damage always 0

ix.config.Add("maxValueDurability", 100, "Maximum value of the durability.", nil, {
	data = {min = 1, max = 9999},
	category = PLUGIN.name
})

ix.config.Add("decDurability", 0.5, "By how many units do reduce the durability with each shot (melee/fallback)?", nil, {
	data = {min = 0.0001, max = 100, decimals = 4},
	category = PLUGIN.name
})

ix.config.Add("decDurabilityMetro", 0.5, "Durability decrease per shot for craftable metro weapons.", nil, {
	data = {min = 0.0001, max = 100, decimals = 4},
	category = PLUGIN.name
})

ix.config.Add("decDurabilityMilitary", 0.25, "Durability decrease per shot for military (non-craftable) weapons.", nil, {
	data = {min = 0.0001, max = 100, decimals = 4},
	category = PLUGIN.name
})

ix.config.Add("decDurabilityEquipment", 0.1, "By how many units do reduce the durability of equipped items when player takes damage?", nil, {
	data = {min = 0.0001, max = 100, decimals = 4},
	category = PLUGIN.name
})

ix.config.Add("unequipItemDurability", false, "Unequip the item if durability is less than zero?", nil, {
	category = PLUGIN.name
})

ix.lang.AddTable("russian", {
	['Repair'] = "Починить",
	['RepairKitWrong'] = 'У вас нет ремкомплекта!',
	['DurabilityUnusableTip'] = 'Оружие теперь полностью сломано!',
	['DurabilityText'] = 'Прочность',
})

ix.lang.AddTable("english", {
	['RepairKitWrong'] = 'You do not have a repair kit!',
	['DurabilityUnusableTip'] = 'Your weapon is now completely broken!',
	['DurabilityText'] = 'Durability',
})

if (SERVER) then
	timer.Create("ixDurabilityTick", 0.1, 0, function()
		for _, v in ipairs(player.GetAll()) do
			if v:Alive() and v:GetCharacter() then
				local weapon = v:GetActiveWeapon()
				if IsValid(weapon) and weapon.ixItem and weapon.ixItem.maxDurability then
					local canShoot = weapon.ixItem:GetData("durability", weapon.ixItem.maxDurability) > 0
					if not v:IsWepRaised() then canShoot = false end
					if canShoot ~= v:CanShootWeapon() then
						v:SetNetVar("canShoot", canShoot)
					end
				end
			end
		end
	end)

	function PLUGIN:EntityFireBullets(entity, bullet)
		if (IsValid(entity) and entity:IsPlayer()) then
			local weapon = entity:GetActiveWeapon()

			if (IsValid(weapon) and weapon.ixItem) then
				local item = weapon.ixItem

				if (item.maxDurability) then
					local durability = item:GetData("durability", item.maxDurability or ix.config.Get("maxValueDurability", 100))
					local oldDurability = durability
					local originalDamage = bullet.Damage

					bullet.Damage = (originalDamage / 100) * durability
					bullet.Spread = bullet.Spread * (1 + (1 - (0.01 * durability)))

					local decRate
					if item.repairType == "gun" then
						if item.ixHasRecipe then
							decRate = ix.config.Get("decDurabilityMetro", 0.5)
						else
							decRate = ix.config.Get("decDurabilityMilitary", 0.25)
						end
					else
						decRate = ix.config.Get("decDurability", 0.5)
					end

					if (originalDamage < 2) then
						durability = math.max(durability - decRate, 0)
					else
						durability = math.max(durability - (originalDamage / 100), 0)
					end

					if (oldDurability ~= durability) then
						item:SetData("durability", durability)
					end

					if (oldDurability > 0 and durability == 0) then
						entity:SetNetVar("canShoot", false)
						if item.Unequip then
							item:Unequip(entity)
						end

					end

					if (ix.config.Get("unequipItemDurability", false) and durability < 1 and item.Unequip) then
						item:Unequip(entity)
					end
				end
			end
		end
	end
end

function PLUGIN:InitializedPlugins()

	for _, v in pairs(ix.item.list) do
		if (!v.maxDurability) then continue end

		local maxDurability = v.maxDurability

		-- Cache recipe existence for firearms so EntityFireBullets can pick the
		-- right decrement rate without iterating recipes on every shot.
		if v.repairType == "gun" then
			local ixcraft = ix.plugin.list["ixcraft"]
			v.ixHasRecipe = false
			if ixcraft and ixcraft.craft and ixcraft.craft.recipes then
				for _, r in pairs(ixcraft.craft.recipes) do
					if r.results and r.results[v.uniqueID] then
						v.ixHasRecipe = true
						break
					end
				end
			end
		end

		if CLIENT then

			local SLOT_LETTERS = { 
				Outfit = "Outfit", 
				Vest = "Vest", 
				Helmet = "Helmet",
				Backpack = "Backpack"
			}

			function v:PaintOver(item, w, h)
				if item.equipSlot then
					if item:GetData("equip") then
						-- Slot banner (full word)
						local label = string.upper(SLOT_LETTERS[item.equipSlot] or "Equipped")

						surface.SetFont("DermaDefaultBold")
						local textW, textH = surface.GetTextSize(label)

						local padding = 6
						local boxW = textW + padding * 2
						local boxH = textH + 4

						-- Draw background
						draw.RoundedBox(
							4,
							w - boxW - 4,
							4,
							boxW,
							boxH,
							Color(20, 120, 20, 220)
						)

						-- Draw text
						draw.SimpleText(
							label,
							"DermaDefaultBold",
							w - boxW/2 - 4,
							4 + boxH/2,
							color_white,
							TEXT_ALIGN_CENTER,
							TEXT_ALIGN_CENTER
						)
					end
				elseif item.weaponCategory ~= nil and item:GetData("equip") then
					local label = string.upper(item.weaponCategory or "WEAPON")

					surface.SetFont("DermaDefaultBold")
					local textW, textH = surface.GetTextSize(label)

					local padding = 6
					local boxW = textW + padding * 2
					local boxH = textH + 4

					draw.RoundedBox(
						4,
						w - boxW - 4,
						4,
						boxW,
						boxH,
						Color(30, 140, 30, 220)
					)

					draw.SimpleText(
						label,
						"DermaDefaultBold",
						w - boxW/2 - 4,
						4 + boxH/2,
						color_white,
						TEXT_ALIGN_CENTER,
						TEXT_ALIGN_CENTER
					)
				end


				local durability = item:GetData("durability", maxDurability)
				local durabilityPercent = math.Clamp(durability / maxDurability, 0, maxDurability)

				if (durabilityPercent > 0) then
					-- 2.55 = (255 / 100)
					local durabilityColor = Color(2.55 * (100 - durability), 2.55 * durability, 0, 255)

					surface.SetDrawColor(durabilityColor)
					surface.DrawRect(0, h - 2, w * durabilityPercent, 2)
				end
			end
		end

		v.functions.Repair = {
			name = "Repair",
			tip = "equipTip",
			icon = "icon16/bullet_wrench.png",
			OnRun = function(item)
				local client = item.player

				-- Must be near any crafting station
				local nearStation = false
				for _, ent in pairs(ents.GetAll()) do
					if ent:GetClass():find("^ix_station_") then
						if client:GetPos():DistToSqr(ent:GetPos()) < 100 * 100 then
							nearStation = true
							break
						end
					end
				end

				if not nearStation then
					client:Notify("You must be near a crafting station to repair this.")
					return false
				end

				-- repairIngredient on the item overrides the recipe lookup
				local bestID = item.repairIngredient

				if not bestID then
					-- Find a recipe that produces this item
					local ixcraft = ix.plugin.list["ixcraft"]
					local recipe = nil
					if ixcraft and ixcraft.craft then
						for _, r in pairs(ixcraft.craft.recipes) do
							if r.results and r.results[item.uniqueID] then
								recipe = r
								break
							end
						end
					end

					if not recipe then
						client:Notify("This item has no repair recipe.")
						return false
					end

					-- Find the most expensive ingredient by price
					local bestPrice = -1
					for ingredientID, _ in pairs(recipe.requirements) do
						local def = ix.item.Get(ingredientID)
						local price = (def and def.price) or 0
						if price > bestPrice then
							bestPrice = price
							bestID = ingredientID
						end
					end

					if not bestID then
						client:Notify("This item has no repair recipe.")
						return false
					end
				end

				-- Check player has 1 of that ingredient
				local ingredientItem = nil
				local repairInv = client:GetCharacter() and client:GetCharacter():GetInventory()
				if not repairInv then return false end
				for _, invItem in pairs(repairInv:GetItems()) do
					if invItem.uniqueID == bestID then
						ingredientItem = invItem
						break
					end
				end

				if not ingredientItem then
					local def = ix.item.Get(bestID)
					local ingredientName = (def and def.name) or bestID
					client:Notify("You need " .. ingredientName .. " to repair this.")
					return false
				end

				-- Consume ingredient and restore 50% durability
				ingredientItem:Remove()
				item:SetData("durability", maxDurability)
				client:Notify("Item fully repaired.")

				return false
			end,

			OnCanRun = function(item)
				local client = item.player
				if not IsValid(client) then return false end
				local char = client:GetCharacter()
				if not char then return false end
				local mainInv = char:GetInventory()
				if not mainInv or item.invID ~= mainInv:GetID() then return false end
				if item.repairIngredient then return true end
				local ixcraft = ix.plugin.list["ixcraft"]
				if not (ixcraft and ixcraft.craft) then return false end
				for _, r in pairs(ixcraft.craft.recipes) do
					if r.results and r.results[item.uniqueID] then
						return true
					end
				end
				return false
			end
		}
	end
end

function PLUGIN:CanPlayerEquipItem(_, itemObj)
	if (ix.config.Get("unequipItemDurability", false)) then
		return itemObj:GetData("durability", ix.config.Get("maxValueDurability", 100)) > 0
	end
end