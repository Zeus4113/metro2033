if (CLIENT) then
	hook.Add("MessageReceived", "MetroChatSounds", function(client, info)
		if (client == LocalPlayer()) then
			surface.PlaySound("tools/ifm/beep.wav")
		else
			surface.PlaySound("tools/ifm/ifm_denyundo.wav")
		end
	end)
end
