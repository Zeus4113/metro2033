local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Workshop Tool Chest"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Uncommon"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Workshop Tool Chest"
ENT.searchText = "Searching... "
ENT.description = [[
A heavy red metal toolbox commonly found in metro workshops and repair stations. 

Mechanics used these to store essential tools and spare parts for keeping the station’s machinery running. 

Even after years of scavenging, forgotten tools and useful components can still turn up inside.
]]

ENT.searchSounds = {
    "doors/door_metal_large_open1.wav"
}

ENT.lootType = "tools"
ENT.respawnTime = 1200
ENT.searchTime = 1.5

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/wick/wrbstalker/nlc7/items/wick_8_art_box_door.mdl")
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

        local entity = ents.Create("ix_loot_tools_workshop")
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
