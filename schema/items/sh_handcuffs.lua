ITEM.name = "Handcuffs"
ITEM.description = "Steel restraints. Use on a nearby person to restrain them. Press E on a restrained person to release them."
ITEM.model = "models/props/cs_office/file_box.mdl"

ITEM.width = 1
ITEM.height = 1
ITEM.weight = 0.5
ITEM.price = 80

ITEM.functions.Restrain = {
	name = "Restrain",
	icon = "icon16/lock.png",
	OnRun = function(item)
		local client = item.player
		local trace = util.TraceLine({
			start = client:GetShootPos(),
			endpos = client:GetShootPos() + client:GetAimVector() * 100,
			filter = client
		})
		local target = trace.Entity

		if not IsValid(target) or not target:IsPlayer() then
			client:Notify("No one is in range.")
			return false
		end

		if not target:Alive() then
			client:Notify("You cannot restrain a dead person.")
			return false
		end

		if target:GetNetVar("cuffed") then
			client:Notify("This person is already restrained.")
			return false
		end

		target:SetRestricted(true)
		target:SetNetVar("cuffed", true)

		local targetName = target:GetCharacter():GetName()
		client:Notify("You have restrained " .. targetName .. ".")
		target:Notify("You have been restrained.")

		item:Remove()
		return false
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive()
	end
}
