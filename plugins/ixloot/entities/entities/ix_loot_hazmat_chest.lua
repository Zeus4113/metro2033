local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Contaminated Equipment Chest"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Uncommon"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Contaminated Equipment Chest"
ENT.searchText = "Searching... "
ENT.description = [[
A heavy steel storage chest marked with faded radiation warning symbols. 

These containers were once used by maintenance crews and hazard teams operating in highly irradiated sections of the metro. 

The contents were meant for handling contaminated machinery and materials—protective gear, specialized tools, and sealed components. 

Most of these chests have been looted over the years, but occasionally something valuable still remains inside.
]]

ENT.searchSounds = {
    "doors/door_metal_large_open1.wav"
}

ENT.lootType = "hazmat"
ENT.respawnTime = 1200
ENT.searchTime = 2.5

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/wick/wrbstalker/nlc7/items/wick_art_box8.mdl")
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

        local entity = ents.Create("ix_loot_hazmat_chest")
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
