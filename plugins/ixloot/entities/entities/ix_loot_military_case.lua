local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Military Equipment Case"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Legendary"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Military Equipment Case"
ENT.searchText = "Unlocking... "
ENT.description = [[
A compact steel storage case once issued to military units operating in the metro during the early days of the war. 

Built to protect sensitive equipment and sealed with a reinforced lock, these cases were typically used to transport weapons, ammunition, and tactical gear. 

Without the proper key, opening one is nearly impossible.
]]

ENT.searchSounds = {
    "doors/door_metal_large_open1.wav"
}

ENT.requiredTools = {
    "key"
}

ENT.lootType = "military"
ENT.respawnTime = 1800
ENT.searchTime = 2

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/z-o-m-b-i-e/st_metal_box_04.mdl")
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

        local entity = ents.Create("ix_loot_military_case")
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
