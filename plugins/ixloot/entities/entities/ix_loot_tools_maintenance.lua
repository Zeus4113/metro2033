local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Station Maintenance Toolbox"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Uncommon"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Station Maintenance Toolbox"
ENT.searchText = "Searching... "
ENT.description = [[
A standard toolbox once used by metro maintenance crews responsible for keeping generators, pumps, and rail systems running. 

Though battered from years of use, these boxes often still hold practical tools and mechanical parts valuable to anyone trying to keep their gear functioning underground.
]]

ENT.searchSounds = {
    "doors/door_metal_large_open1.wav"
}

ENT.lootType = "tools"
ENT.respawnTime = 1200
ENT.searchTime = 1.5

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/sal/fallout4/toolbox.mdl")
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

        local entity = ents.Create("ix_loot_tools_maintenance")
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
