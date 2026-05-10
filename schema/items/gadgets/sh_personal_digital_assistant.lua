ITEM.name = "Personal Digital Assistant"
ITEM.description = "A small handheld computer constructed using advanced electronic components and display technology. Useful for storing information and monitoring systems."
ITEM.model = "models/spec45as/stalker/items/pda.mdl"

ITEM.width = 1
ITEM.height = 1
ITEM.weight = 1.0
ITEM.price = 177

ITEM.iconCam = {
	pos = Vector(0, 0, 200),
	ang = Angle(90, 0, 0),
	fov = 3.79
}

local function HasPDA(client)
	local char = client:GetCharacter()
	if not char then return false end
	local inv = char:GetInventory()
	if not inv then return false end
	for item in inv:Iter() do
		if item.uniqueID == "personal_digital_assistant" and item:GetData("enabled", false) then
			return true
		end
	end
	return false
end

ITEM.functions.Toggle = {
	name = "Toggle Power",
	icon = "icon16/lightbulb.png",
	OnRun = function(item)
		local enabled = not item:GetData("enabled", false)
		item:SetData("enabled", enabled)
		item.player:EmitSound(enabled and "buttons/button15.wav" or "buttons/button19.wav", 60, 100, 0.5)
		item.player:Notify(enabled and "PDA powered on." or "PDA powered off.")
		return false
	end,
}

if CLIENT then
	function ITEM:PaintOver(item, w, h)
		if item:GetData("enabled", false) then
			surface.SetDrawColor(110, 255, 110, 220)
		else
			surface.SetDrawColor(220, 60, 60, 220)
		end
		surface.DrawRect(w - 14, h - 14, 8, 8)
	end
end

hook.Add("InitializedChatClasses", "PDAChannels", function()
	ix.chat.Register("pdapublic", {
		prefix = {"/PDAP"},
		description = "Broadcast a message to all PDA holders.",
		color = Color(100, 200, 255),
		bNoIndicator = true,
		OnChatAdd = function(_, speaker, text)
			chat.AddText(
				Color(50, 130, 200),  "[PDA] ",
				Color(160, 215, 255), speaker:Name(),
				Color(90, 160, 210),  ": ",
				Color(210, 235, 250), text
			)
		end,
		CanSay = function(_, speaker, _)
			if not HasPDA(speaker) then
				speaker:Notify("You need a PDA to use this channel.")
				return false
			end
			return true
		end,
		CanHear = function(_, _, listener)
			return HasPDA(listener)
		end,
	})

	ix.chat.Register("pdaclass", {
		prefix = {"/PDAC"},
		description = "Broadcast a message to PDA holders in your class.",
		color = Color(100, 255, 150),
		bNoIndicator = true,
		OnChatAdd = function(_, speaker, text)
			local char = IsValid(speaker) and speaker:GetCharacter()
			local classData = char and ix.class.list[char:GetClass()]
			if classData then
				chat.AddText(
					Color(50, 170, 90),   "[PDA-CLASS] ",
					Color(130, 230, 100), "[" .. classData.name .. "] ",
					Color(190, 255, 200), speaker:Name(),
					Color(100, 180, 120), ": ",
					Color(220, 248, 225), text
				)
			else
				chat.AddText(
					Color(50, 170, 90),   "[PDA-CLASS] ",
					Color(190, 255, 200), speaker:Name(),
					Color(100, 180, 120), ": ",
					Color(220, 248, 225), text
				)
			end
		end,
		CanSay = function(self, speaker, text)
			if not HasPDA(speaker) then
				speaker:Notify("You need a PDA to use this channel.")
				return false
			end
			local char = speaker:GetCharacter()
			if not char or char:GetClass() == 0 then
				speaker:Notify("You must be in a class to use this channel.")
				return false
			end
			return true
		end,
		CanHear = function(self, speaker, listener)
			if not HasPDA(listener) then return false end
			local sc = speaker:GetCharacter()
			local lc = listener:GetCharacter()
			if not sc or not lc then return false end
			local speakerClass = sc:GetClass()
			return speakerClass ~= 0 and speakerClass == lc:GetClass()
		end,
	})

	ix.chat.Register("pdafaction", {
		prefix = {"/PDAF"},
		description = "Broadcast a message to PDA holders in your faction.",
		color = Color(180, 100, 255),
		bNoIndicator = true,
		OnChatAdd = function(_, speaker, text)
			local char = IsValid(speaker) and speaker:GetCharacter()
			local factionData = char and ix.faction.indices[char:GetFaction()]
			if factionData then
				chat.AddText(
					Color(120, 60, 200),  "[PDA-FACTION] ",
					Color(180, 120, 255), "[" .. factionData.name .. "] ",
					Color(210, 180, 255), speaker:Name(),
					Color(140, 100, 200), ": ",
					Color(230, 215, 255), text
				)
			else
				chat.AddText(
					Color(120, 60, 200),  "[PDA-FACTION] ",
					Color(210, 180, 255), speaker:Name(),
					Color(140, 100, 200), ": ",
					Color(230, 215, 255), text
				)
			end
		end,
		CanSay = function(self, speaker, text)
			if not HasPDA(speaker) then
				speaker:Notify("You need a PDA to use this channel.")
				return false
			end
			local char = speaker:GetCharacter()
			if not char or not ix.faction.indices[char:GetFaction()] then
				speaker:Notify("You must be in a faction to use this channel.")
				return false
			end
			return true
		end,
		CanHear = function(self, speaker, listener)
			if not HasPDA(listener) then return false end
			local sc = speaker:GetCharacter()
			local lc = listener:GetCharacter()
			if not sc or not lc then return false end
			return sc:GetFaction() == lc:GetFaction()
		end,
	})

	ix.chat.Register("pdadm", {
		color = Color(255, 200, 100),
		bNoIndicator = true,
		OnChatAdd = function(_, speaker, text, _, data)
			local targetName = (data and IsValid(data.target)) and data.target:Name() or "Unknown"
			chat.AddText(
				Color(200, 120, 30),  "[PDA-DM] ",
				Color(255, 210, 120), speaker:Name(),
				Color(180, 150, 70),  " -> ",
				Color(255, 210, 120), targetName,
				Color(180, 150, 70),  ": ",
				Color(255, 238, 195), text
			)
		end,
	})
end)

ix.command.Add("PDADM", {
	description = "Send a direct PDA message to another player.",
	arguments = {ix.type.player, ix.type.text},
	OnRun = function(self, client, target, message)
		if not HasPDA(client) then
			return "You need a PDA to send direct messages."
		end
		if not HasPDA(target) then
			return "That player doesn't have a PDA."
		end
		if target == client then
			return "You can't send a DM to yourself."
		end
		ix.chat.Send(client, "pdadm", message, false, {client, target}, {target = target})
	end
})
