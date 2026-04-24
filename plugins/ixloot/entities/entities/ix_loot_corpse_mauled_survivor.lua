local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Mauled Survivor"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Corpses"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Mauled Survivor"
ENT.searchText = "Searching... "
ENT.description = [[
The body has been partially buried beneath debris and filth, as if stored for later. The smell alone is enough to make your stomach turn.
]]

ENT.searchSounds = {
    "npc/combine_soldier/zipline_clothing2.wav"
}

ENT.lootType = "corpse"
ENT.respawnTime = 1200
ENT.searchTime = 2

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/metro/props/deadbodies/redux_corpse08.mdl")
        self:PhysicsInit(SOLID_VPHYSICS) 
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
    
        local phys = self:GetPhysicsObject()
        if (phys:IsValid()) then
            phys:Wake()
            phys:EnableMotion(false)
        end
    end

    function ENT:SpawnFunction(client, trace)
        local angles = client:GetAngles()

        local entity = ents.Create("ix_loot_corpse_mauled_survivor")
        entity:SetPos(trace.HitPos)
        entity:SetAngles(Angle(0, (entity:GetPos() - client:GetPos()):Angle().y - 180, 0))
        entity:Spawn()
        entity:Activate()

        return entity
    end
    
    function ENT:OnTakeDamage()
        return false
    end
    
    function ENT:AcceptInput(Name, Activator, Caller)
        if (Name == "Use" and Caller:IsPlayer()) then
            PLUGIN:SearchLootContainer(self, Caller)
        end
    end
end
