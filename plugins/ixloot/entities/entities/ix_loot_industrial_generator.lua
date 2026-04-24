local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Workshop Generator Rig"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Rare"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Workshop Generator Rig"
ENT.searchText = "Scavenging... "
ENT.description = [[
A portable generator assembly mounted on a crude metal frame. 

These rigs once powered workshops and maintenance equipment deep in the tunnels. 

Though the unit itself is long dead, it still contains useful electrical components, wiring, and mechanical parts worth salvaging.
]]

ENT.searchSounds = {
    "doors/door_metal_medium_open1.wav"
}

ENT.requiredTools = {
    "steel_wrench"
}

ENT.lootType = "industrial"

ENT.respawnTime = 900
ENT.searchTime = 3


if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/spec45as/stalker/tech/generator-anim.mdl")
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

        local entity = ents.Create("ix_loot_industrial_generator")
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
