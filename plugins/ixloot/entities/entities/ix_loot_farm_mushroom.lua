local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base             = "base_gmodentity"
ENT.Type             = "anim"
ENT.PrintName        = "Metro Mushroom Grow Bed"
ENT.Author            = "Riggs"
ENT.Purpose            = "Allows you to take loot from it."
ENT.Instructions    = "Press E"
ENT.Category         = "Helix Lootables Common"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.displayName = "Metro Mushroom Grow Bed"
ENT.searchText = "Gathering... "
ENT.description = [[
A long cultivation rack used by station farmers to grow edible mushrooms in the dim tunnels of the metro. 

Packed with nutrient-rich soil and carefully tended in the darkness, these beds provide one of the few reliable food sources underground. 

If the crop hasn't already been harvested, a few fresh mushrooms may still be growing here.
]]

ENT.searchSounds = {
    "npc/antlion_grub/agrub_squish1.wav"
}

ENT.lootType = "farm"

ENT.respawnTime = 450
ENT.searchTime = 6

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/props/mushtable1.mdl")
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

        local entity = ents.Create("ix_loot_farm_mushroom")
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
