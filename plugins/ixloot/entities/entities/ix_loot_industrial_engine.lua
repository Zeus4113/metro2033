local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Loot Industrial Engine Block"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Rare"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Industrial Engine Block"
ENT.searchText = "Scavenging... "

ENT.description = [[
A heavy, rusted engine block salvaged from old metro maintenance machinery. 

Most of its useful parts have long since been stripped, but determined scavengers can still recover gears, valves, and other mechanical components buried within the corroded frame.

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
        self:SetModel("models/spec45as/stalker/tech/generator_engine.mdl")
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

        local entity = ents.Create("ix_loot_industrial_engine")
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
