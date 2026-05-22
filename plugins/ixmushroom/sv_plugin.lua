local PLUGIN = PLUGIN

function PLUGIN:Tick()
	local curTime = CurTime()
	if curTime < (self.nextMushroomTick or 0) then return end
	self.nextMushroomTick = curTime + 1

	for _, ent in pairs(ents.FindByClass("ix_mushroom")) do
		if not ent.isGrown then
			local elapsed = curTime - (ent.growthStartTime or curTime)
			local duration = ent.growthDuration or ix.config.Get("mushroomGrowthTime", 300)
			if elapsed >= duration then
				ent.isGrown = true
			end
		end
	end
end
