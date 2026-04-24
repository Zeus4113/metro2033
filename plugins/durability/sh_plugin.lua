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

ix.config.Add("decDurability", 0.5, "By how many units do reduce the durability with each shot?", nil, {
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
	function PLUGIN:Tick()
		local curTime = CurTime()

		for _, v in ipairs(player.GetAll()) do
			if (curTime >= (v.ixNextTickDurability or 0) and v:Alive() and v:GetCharacter()) then
				local weapon = v:GetActiveWeapon()

				if (IsValid(weapon) and weapon.ixItem and weapon.ixItem.maxDurability) then
					local canShoot = weapon.ixItem:GetData("durability", weapon.ixItem.maxDurability or ix.config.Get("maxValueDurability", 100)) > 0

					if (!v:IsWepRaised()) then
						canShoot = false
					end

					if (canShoot ~= v:CanShootWeapon()) then
						v:SetNetVar("canShoot", canShoot)
					end
				end

				v.ixNextTickDurability = curTime + 0.1
			end
		end
	end

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

					if (originalDamage < 1) then
						durability = math.max(durability - ix.config.Get("decDurability", 1), 0)
					else
						durability = math.max(durability - (originalDamage / 100), 0) -- 100 = drainScale
					end

					if (oldDurability ~= durability) then
						item:SetData("durability", durability)
					end

					if (oldDurability > 0 and durability == 0) then
						entity:SetNetVar("canShoot", false)
						if item.Unequip then
							item:Unequip(item.player)
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

		if CLIENT then

			local SLOT_LETTERS = { 
				Outfit = "Outfit", 
				Vest = "Vest", 
				Helmet = "Helmet",
				Backpack = "Backpack"
			}

			function v:PaintOver(item, w, h)
				local client = LocalPlayer()
				local char = client:GetCharacter()

				if not char then return end

				if item.equipSlot then
					local equipment = char:GetData("equipment", {})
					local isEquipped = equipment[item.equipSlot] == item:GetID()
					if isEquipped then
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
				local itemKit = client:GetCharacter():GetInventory():HasItemOfBase("base_repair_kit")

				if not itemKit then return false end

				if(item.repairType) then

					for k, v in pairs(client:GetCharacter():GetInventory():GetItemsByBase("base_repair_kit")) do

						if v.repairType and v.repairType == item.repairType then

							local quantity = itemKit:GetData("quantity", v.quantity or 1) - 1

							if (quantity < 1) then
								v:Remove()
							else
								v:SetData("quantity", quantity)
							end

							if (v.UseRepair) then
								v:UseRepair(item, client)
							end

							if (v.useSound) then
								client:EmitSound(v.useSound, 110)
							end

							v = nil
							return false
						end
					end

					client:NotifyLocalized('You do not have the required repair kit.')
				end

				return false
			end,

			OnCanRun = function(item)
				if (item:GetData("durability", maxDurability) >= maxDurability) then
					return false
				end

				if (!item.player:GetCharacter():GetInventory():HasItemOfBase("base_repair_kit")) then
					return false
				end

				return true
			end
		}
	end
end

function PLUGIN:CanPlayerEquipItem(_, itemObj)
	if (ix.config.Get("unequipItemDurability", false)) then
		return itemObj:GetData("durability", ix.config.Get("maxValueDurability", 100)) > 0
	end
end