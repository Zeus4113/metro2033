local PLUGIN = PLUGIN
PLUGIN.name = "Item Spawner"
PLUGIN.description = "An item spawning system."
PLUGIN.author = "ZeMysticalTaco"
PLUGIN.spawners = PLUGIN.spawners or {}
PLUGIN.items = PLUGIN.items or {}

ix.lang.AddTable("english", {
	itemspawner = "Item Spawner",
})

ix.lang.AddTable("korean", {
	itemspawner = "아이템 스포너",
})

ix.config.Add("ItemSpawnInterval", 300, "The font used to display titles.", nil, {
	category = "itemspawner",
	data = {min = 10, max = 999999999}
})

ix.config.Add("ItemSpawnPerWave", 5, "The font used to display titles.", nil, {
	category = "itemspawner",
	data = {min = 0, max = 1000}
})

ix.config.Add("ItemSpawnMaxItems", 75, "The font used to display titles.", nil, {
	category = "itemspawner",
	data = {min = 0, max = 1000}
})

ix.config.Add("ItemMinimumPlayers", 2, "The font used to display titles.", nil, {
	category = "itemspawner",
	data = {min = 0, max = 64}
})

ix.config.Add("ItemMaxInContainer", 2, "The font used to display titles.", nil, {
	category = "itemspawner",
	data = {min = 0, max = 64}
})
	ix.command.Add("ItemSpawnAdd", {
		description = "Add an item spawner.",
		adminOnly = true,
		OnRun = function(self, client)
			local trace = client:GetEyeTraceNoCursor()
			local hitpos = trace.HitPos
			PLUGIN:AddItemSpawn(client, hitpos)
		end
	})

	ix.command.Add("ItemSpawnRemove", {
		description = "Add an item spawner.",
		adminOnly = true,
		OnRun = function(self, client)
			local trace = client:GetEyeTraceNoCursor()
			local hitpos = trace.HitPos
			PLUGIN:RemoveItemSpawn(client, hitpos)
		end
	})

	ix.command.Add("ItemSpawnForce", {
		description = "Add an item spawner.",
		adminOnly = true,
		arguments = ix.type.number,
		OnRun = function(self, client, amount)
			for i = 1, amount or 1 do
				PLUGIN:SpawnRandomItem()
			end
		end
	})

	ix.command.Add("ItemSpawnRemoveItems", {
		description = "Remove all items spawned by the item spawner this cycle.",
		adminOnly = true,
		OnRun = function(self, client, amount)
			--TODO: figure out why this doesn't work.
			for k, v in pairs(ents.FindByClass("ix_item")) do
				if v.spawnedbyspawner == true then
					v:Remove()
				end
			end
		end
	})

	ix.command.Add("ItemSpawnResetTimer", {
		description = "Remove all items spawned by the item spawner this cycle.",
		adminOnly = true,
		OnRun = function(self, client, amount)
			NextItemSpawn = 0
		end
	})
if SERVER then
	--[[-------------------------------------------------------------------------
	How this works:
	The number is how many "tickets" in the spawn pool it gets, it's then selected completely at random.
	1 in a pool of 100 would be a 1% chance.
	1 in a pool of 1000 would be an 0.01% chance.
	You can print the size of the pool using PrintItemPoolSize()
	Use the unique ID of an item to determine what's selected.
	so, ["itemid"] = tickets
	By default, any item with the category "Crafting" or "Survival" will get added, so this will go well if you use my crafting plugin and my survival plugin, it will automatically be setup.
---------------------------------------------------------------------------]]
	PLUGIN.customitems = {
		["tin_can"] = 200,
		["lead_pipe"] = 100,
		["metal_crowbar"] = 100,
		["worn_knife"] = 100,
		["steel_wrench"] = 100,
		["screwdriver"] = 100,
		["cast_iron_pot"] = 50,
		["kettle"] = 50,
		["dirty_water"] = 25,
		["antique_clock"] = 10,
		["broken_radio"] = 10,
		["old_boot"] = 10,
		["ruined_jacket"] = 10,
		["household_cleaner"] = 10,
		["laundry_detergent"] = 10,
	}

	function PLUGIN:SaveData()
		ix.data.Set("spawners", self.spawners)
	end

	function PLUGIN:LoadData()
		self.spawners = ix.data.Get("spawners", {})
		--[[-------------------------------------------------------------------------
		ONLY populate once.
	---------------------------------------------------------------------------]]
		self:PopulateItems()
	end



	function PLUGIN:AddItemSpawn(ply, pos)
		self.spawners[#self.spawners + 1] = pos
		ply:Notify("You have added an item spawn.")
	end

	function PLUGIN:RemoveItemSpawn(ply, pos)
		local gay = {}

		for k, v in pairs(self.spawners) do
			if v:Distance(pos) <= 512 then
				self.spawners[k] = nil
				gay[#gay + 1] = v
			end
		end

		ply:Notify("You have removed " .. #gay .. " item spawn(s).")
	end

	function PLUGIN:SpawnRandomItem()
		local spawner = table.Random(self.spawners)
		ix.item.Spawn(table.Random(self.items), spawner)
	end

	--This function is used so that we don't populate items in the same spot, or near players, though it will go unused for my purposes, use it how you wish.
	function PLUGIN:SpawnRandomItemSafe()
		local spawner = table.Random(self.spawners)

		for k, v in pairs(ents.FindInSphere(spawner, 64)) do
			if v:GetClass() == "ix_item" or v:IsPlayer() then
				return false
			end
		end

		local item = ix.item.Spawn(table.Random(self.items), spawner)

		if IsValid(item) then
			item.spawnedbyspawner = true
		end

		return true
	end

	function PLUGIN:AddItemToSpawner(id)
		PLUGIN.items[#PLUGIN.items + 1] = id
	end

	function PLUGIN:PopulateItems()
		for k, v in pairs(self.customitems) do
			for i = 1, v do
				PLUGIN:AddItemToSpawner(k)
			end
		end
	end

	function PrintItemPoolSize()
		print(#PLUGIN.items)
	end

	function PrintItemPool()
		PrintTable(PLUGIN.items)
	end

	function PrintSpawnPool()
		PrintTable(PLUGIN.spawners)
	end

	--[[-------------------------------------------------------------------------
	The bread and butter.
---------------------------------------------------------------------------]]
	function PLUGIN:Think()
		if #self.spawners < 1 then return end
		if NextItemSpawn and NextItemSpawn > CurTime() then return end

		local frequency = ix.config.Get("ItemSpawnInterval", 300)
		NextItemSpawn = CurTime() + frequency

		local min_players = ix.config.Get("ItemMinimumPlayers", 2)
		if #player.GetAll() < min_players then return end

		local max_items = ix.config.Get("ItemSpawnMaxItems", 75)
		if #ents.FindByClass("ix_item") >= max_items then return end

		local waves = ix.config.Get("ItemSpawnPerWave", 5)
		for i = 1, waves do
			self:SpawnRandomItemSafe()
		end
	end
end