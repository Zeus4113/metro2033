local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Supply Crate"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Rare"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Supply Crate"
ENT.searchText = "Prying... "
ENT.description = [[
A sturdy wooden crate reinforced with slats and nails. 

It’s packed tight and the lid won’t budge by hand — you’ll need something with leverage to pry it open.
]]

ENT.searchSounds = {
    "doors/door1_stop.wav"
}

ENT.requiredTools = {
    "metal_crowbar"
}

ENT.lootType = "equipment"
ENT.respawnTime = 900
ENT.searchTime = 3

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/z-o-m-b-i-e/st_wood_item_box.mdl")
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

        local entity = ents.Create("ix_loot_equipment_storage_cabinet")
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
