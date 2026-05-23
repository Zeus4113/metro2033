local PLUGIN = PLUGIN

PLUGIN.name = "Physical Characteristics"
PLUGIN.author = "Kai Stevens"
PLUGIN.description = "Adds height, weight, and eye colour fields to characters."

if SERVER then
	util.AddNetworkString("ix_physchars_setup")
	util.AddNetworkString("ix_physchars_setup_submit")

	local function NeedsPhysSetup(character)
		local h = character:GetHeight(false)
		local w = character:GetWeight(false)
		local e = character:GetEyes(false)
		return not h or h == "" or not w or w == "" or not e or e == ""
	end

	hook.Add("PlayerLoadedCharacter", "physical_chars_setup_check", function(client, character)
		if NeedsPhysSetup(character) then
			net.Start("ix_physchars_setup")
			net.Send(client)
		end
	end)

	net.Receive("ix_physchars_setup_submit", function(_, client)
		local height = string.Trim(net.ReadString())
		local weight = string.Trim(net.ReadString())
		local eyes   = string.Trim(net.ReadString())

		local char = client:GetCharacter()
		if not char then return end

		local hNum = tonumber(height)
		if not hNum or math.floor(hNum) < 170 or math.floor(hNum) > 200 then return end

		local wNum = tonumber(weight)
		if not wNum or math.floor(wNum) < 60 or math.floor(wNum) > 120 then return end

		local validEyes = {brown = true, blue = true, green = true, grey = true}
		if not validEyes[eyes] then return end

		char:SetHeight(tostring(math.floor(hNum)))
		char:SetWeight(tostring(math.floor(wNum)))
		char:SetEyes(eyes)

		client:Notify("Physical characteristics saved.")
	end)

	ix.command.Add("WipePhysChars", {
		description = "Wipes a character's physical characteristics so they are prompted to re-enter them on next load.",
		adminOnly = true,
		arguments = {
			ix.type.player,
		},
		OnRun = function(self, client, target)
			local char = target:GetCharacter()
			if not char then
				client:Notify("That player has no active character.")
				return
			end

			char:SetHeight("")
			char:SetWeight("")
			char:SetEyes("")

			local name = char:GetName()
			client:Notify("Wiped physical characteristics for " .. name .. ".")
			target:Notify("Your physical characteristics have been reset by an admin.")
		end,
	})
end

-- Move the model selector to sort after our fields so its label sits directly
-- above the FILL-docked model grid rather than floating above height/weight.
if ix.char.vars.model then
	ix.char.vars.model.index = 100
end

-- The faction var's OnValidate returns `true` on success, which causes the
-- server validation loop to overwrite payload["faction"] with `true`. The model
-- var (now at index 100) then reads that corrupted value and fails with
-- "needModel". Returning nil instead of true means "valid, no payload change".
if ix.char.vars.faction then
	ix.char.vars.faction.OnValidate = function(self, index, data, client)
		if index and client:HasWhitelist(index) then return end
		return false
	end
end

ix.char.RegisterVar("height", {
	field = "height",
	fieldType = ix.type.string,
	default = "175",
	index = 5,
	OnDisplay = function(self, container, payload)
		payload:Set("height", "175")

		local slider = container:Add("DNumSlider")
		slider:Dock(TOP)
		slider:SetTall(40)
		slider:SetMin(170)
		slider:SetMax(200)
		slider:SetDecimals(0)
		slider:SetValue(175)
		slider.Label:SetVisible(false)
		slider.OnValueChanged = function(_, val)
			payload:Set("height", tostring(math.floor(val)))
		end
		return slider
	end,
	OnValidate = function(self, value, payload, client)
		local num = tonumber(value)
		if not num then return false, "invalid", "height" end
		num = math.floor(num)
		if num < 170 or num > 200 then return false, "invalid", "height" end
		return tostring(num)
	end,
})

ix.char.RegisterVar("weight", {
	field = "weight",
	fieldType = ix.type.string,
	default = "90",
	index = 6,
	OnDisplay = function(self, container, payload)
		payload:Set("weight", "90")

		local slider = container:Add("DNumSlider")
		slider:Dock(TOP)
		slider:SetTall(40)
		slider:SetMin(60)
		slider:SetMax(120)
		slider:SetDecimals(0)
		slider:SetValue(90)
		slider.Label:SetVisible(false)
		slider.OnValueChanged = function(_, val)
			payload:Set("weight", tostring(math.floor(val)))
		end
		return slider
	end,
	OnValidate = function(self, value, payload, client)
		local num = tonumber(value)
		if not num then return false, "invalid", "weight" end
		num = math.floor(num)
		if num < 60 or num > 120 then return false, "invalid", "weight" end
		return tostring(num)
	end,
})

ix.char.RegisterVar("eyes", {
	field = "eyes",
	fieldType = ix.type.string,
	default = "brown",
	index = 7,
	OnDisplay = function(self, container, payload)
		local options = {"brown", "blue", "green", "grey"}
		local optionColors = {
			brown = Color(101, 67, 33),
			blue  = Color(50, 120, 210),
			green = Color(40, 140, 60),
			grey  = Color(110, 110, 120),
		}

		local panel = container:Add("Panel")
		panel:Dock(TOP)
		panel:SetTall(36)

		payload:Set("eyes", "brown")

		for _, name in ipairs(options) do
			local btn = panel:Add("DButton")
			btn:Dock(LEFT)
			btn:SetText(name:sub(1, 1):upper() .. name:sub(2))
			btn:SetFont("ixMenuButtonLabelFont")
			btn:SetTextColor(color_white)

			local col = optionColors[name]
			btn.Paint = function(this, w, h)
				local selected = payload.eyes == name
				surface.SetDrawColor(col.r, col.g, col.b, selected and 210 or 70)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(255, 255, 255, selected and 255 or 80)
				surface.DrawOutlinedRect(0, 0, w, h)
			end
			btn.DoClick = function()
				payload:Set("eyes", name)
			end
		end

		function panel:PerformLayout(w, h)
			local btnW = w / #options
			for _, child in ipairs(self:GetChildren()) do
				child:SetWide(btnW)
			end
		end

		return panel
	end,
	OnValidate = function(self, value, payload, client)
		local valid = {brown = true, blue = true, green = true, grey = true}
		if not valid[value] then return false, "invalid", "eyes" end
		return value
	end,
})
