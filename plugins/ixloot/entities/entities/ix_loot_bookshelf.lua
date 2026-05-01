local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Bookshelf"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Lootables Tier Four"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Bookshelf"
ENT.searchText = "Searching..."
ENT.description = "A narrow wooden bookshelf with warped shelves and dusty veneer, the back panel is bowed and the finish is scratched."

ENT.searchSounds = {
    "physics/cardboard/cardboard_box_shake1.wav"
}

ENT.models = {
    "models/props/cs_office/bookshelf1.mdl",
    "models/props/cs_office/bookshelf2.mdl",
    "models/props/cs_office/bookshelf3.mdl"
}

ENT.lootTier = 4
ENT.lootType = "library"

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

        local entity = ents.Create("ix_loot_bookshelf")
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
