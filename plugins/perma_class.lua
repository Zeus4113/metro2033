local PLUGIN = PLUGIN
PLUGIN.name = "Class Manager"
PLUGIN.author = "metro2033"
PLUGIN.description = "Single authority for restoring a character's class on load, validated against class whitelists."

--[[
	Class resolution on character load runs in priority order:

	  1. Forced class  — any plugin may answer the `GetForcedClass` hook to force a
	                     character into a class regardless of whitelist (e.g. the gang
	                     plugin forces a hideout class while a claim is live). Bypasses
	                     whitelist validation by design, but still respects faction.
	  2. Saved choice  — the player's last manually-chosen class (`pclass`), re-applied
	                     via JoinClass so it is validated against the whitelist/faction
	                     and the loadout is applied. A choice the player no longer
	                     qualifies for is dropped.
	  3. Default       — the faction default Helix already applied on load.

	Helix does not persist the class var and resets every character to its faction
	default in GM:PlayerLoadedCharacter (which runs after plugin hooks), so resolution
	is deferred one frame to win.
]]

if (SERVER) then
	-- Records the player's chosen class so it can be restored on next load. Forced
	-- classes use a raw SetClass and never fire this hook, so only genuine choices
	-- (and KickClass → default) are persisted.
	function PLUGIN:PlayerJoinedClass(client, classIndex, previousClass)
		local character = client:GetCharacter()
		if not character then return end
		character:SetData("pclass", classIndex)
	end

	function PLUGIN:ResolveCharacterClass(client, character)
		if not IsValid(client) or not character then return end
		if client:GetCharacter() ~= character then return end   -- still the active character

		-- 1. Forced class (gang claim, etc.) — bypasses whitelist, respects faction.
		local forced = hook.Run("GetForcedClass", client, character)
		if forced then
			local info = ix.class.list[forced]
			if info and client:Team() == info.faction then
				if character:GetClass() ~= forced then
					character:SetClass(forced)
				end
				return
			end
		end

		-- 2. Saved choice — validated via JoinClass (faction + whitelist), applies loadout.
		local pref = character:GetData("pclass")
		if pref and ix.class.list[pref] then
			if character:GetClass() == pref then return end
			if character:JoinClass(pref) then return end
		end

		-- 3. Default already applied by Helix; nothing to do.
	end

	function PLUGIN:PlayerLoadedCharacter(client, character, previousChar)
		-- Defer one frame so we run after Helix resets the class to the faction default.
		timer.Simple(0, function()
			PLUGIN:ResolveCharacterClass(client, character)
		end)
	end

	-- A whitelist change can change the forced class (e.g. admin-assigned faction
	-- Sergeant/Officer), so re-resolve immediately.
	function PLUGIN:OnClassWhitelistChanged(client)
		timer.Simple(0, function()
			if not IsValid(client) then return end
			local character = client:GetCharacter()
			if character then
				PLUGIN:ResolveCharacterClass(client, character)
			end
		end)
	end
end
