AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("Disguiser_UpdateStatus")

hook.Add("PlayerDisconnected", "Disguiser_Cleanup", function(ply)
    if ply.DisguiseEnabled then
        ply.DisguiseEnabled = false
        ply.DisguiseTargetName = nil
        ply.DisguiseTargetModel = nil
        ply.DisguiseTargetColor = nil
        ply.OriginalModel = nil
        ply.OriginalPlayerColor = nil
    end
end)

hook.Add("PlayerDeath", "Disguiser_RemoveOnDeath", function(victim, inflictor, attacker)
    if victim.OriginalModel then
        victim:SetModel(victim.OriginalModel)
    end

    if victim.OriginalPlayerColor then
        victim:SetPlayerColor(victim.OriginalPlayerColor)
    end

    if victim.DisguiseEnabled then
        CustomNameHandler:RemoveNameOverlay(victim)
    end

    victim.DisguiseEnabled = false
    victim.DisguiseTargetName = nil
    victim.DisguiseTargetModel = nil
    victim.DisguiseTargetColor = nil
    victim.OriginalModel = nil
    victim.OriginalPlayerColor = nil

    net.Start("Disguiser_UpdateStatus")
        net.WriteBool(false)
        net.WriteString("")
    net.Send(victim)
end)

hook.Add("PlayerSpawn", "Disguiser_RestoreOriginalModel", function(ply)
    if ply.OriginalModel then
        timer.Simple(0.1, function()
            if IsValid(ply) and ply.OriginalModel then
                ply:SetModel(ply.OriginalModel)
            end
            if IsValid(ply) and ply.OriginalPlayerColor then
                ply:SetPlayerColor(ply.OriginalPlayerColor)
            end
        end)
    end
end)
