net.Receive("ixFilterWarning", function()
	local isEmpty = net.ReadBool()
	LocalPlayer():EmitSound("buttons/blip2.wav", 60, isEmpty and 90 or 110, 0.3)
end)
