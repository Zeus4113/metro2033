local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Dragged Victim"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Corpses"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Dragged Victim"
ENT.searchText = "Searching... "
ENT.description = [[
A trail of dried blood leads to this corpse, limbs twisted unnaturally. It looks like they were dragged here… still alive..
]]

ENT.searchSounds = {
    "npc/combine_soldier/zipline_clothing2.wav"
}

ENT.lootType = "corpse"
ENT.respawnTime = 1200
ENT.searchTime = 2

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/metro/props/deadbodies/redux_corpse04.mdl")
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

        local entity = ents.Create("ix_loot_corpse_dragged_victim")
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
