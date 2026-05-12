local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Medical Crate"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Lootables Tier 4"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Medical Crate"
ENT.searchText = "Searching..."
ENT.description = "A rigid medical crate with faded red markings and a worn molded handle, its surface is scuffed and the edges are dinged."

ENT.searchSounds = {
    "doors/latchunlocked1.wav"
}

ENT.models = {
    "models/illusion/eftcontainers/medscase.mdl"
}

ENT.lootTier = 4
ENT.lootType = "medical"

ENT.respawnTime = 900
ENT.searchTime = 0.5
ENT.rareChance = 5


if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel(self.models[math.random(1, #self.models)])
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

        local entity = ents.Create("ix_loot_medical_crate")
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
