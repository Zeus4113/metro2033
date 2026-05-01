local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Wooden Crate"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Lootables Tier Zero"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Wooden Crate"
ENT.searchText = "Searching... "
ENT.description = "A rough wooden crate bound with rusty nails, the boards are splintered and the lid sits unevenly."

ENT.searchSounds = {
    "physics/wood/wood_strain8.wav"
}

ENT.models = {
    "models/z-o-m-b-i-e/st_wood_item_box.mdl",
    "models/maver1k_xvii/stalker/props/box/box_wood_01.mdl",
    "models/z-o-m-b-i-e/st/box/st_box_wood_01.mdl"
}

ENT.lootTier = 0
ENT.lootType = "scrap"

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

        local entity = ents.Create("ix_loot_wooden_crate")
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
