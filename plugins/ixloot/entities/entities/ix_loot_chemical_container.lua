local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Chemical Container"
ENT.Author            = "BarneytheBandit"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Lootables Tier 3"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Chemical Container"
ENT.searchText = "Searching... "
ENT.description = "A study plastic container with a faded warning label, its sides are stained and the contents slosh ominously."

ENT.searchSounds = {
    "physics/plastic/plastic_barrel_break1.wav"
}

ENT.models = {
    "models/spec45as/stalker/quest/safe_container.mdl"
}

ENT.lootTier = 3
ENT.lootType = "chemicals"

ENT.respawnTime = 900
ENT.searchTime = 1

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

        local entity = ents.Create("ix_loot_chemical_container")
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
