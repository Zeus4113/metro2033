local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Field Medic Satchel"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Rare"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Field Medic Satchel"
ENT.searchText = "Searching... "
ENT.description = [[
A worn leather satchel carried by medics and volunteer caregivers throughout the metro. 

These bags were often packed with basic treatment supplies for wounds, radiation sickness, and infections. 

Though time has taken its toll, careful scavengers may still find useful medicine or bandaging materials tucked inside.
]]

ENT.searchSounds = {
    "doors/door_latch1.wav"
}

ENT.lootType = "medical"
ENT.respawnTime = 1200
ENT.searchTime = 1.5

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/gorka/stalker/items/medbag_1.mdl")
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

        local entity = ents.Create("ix_loot_medical_satchel")
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
