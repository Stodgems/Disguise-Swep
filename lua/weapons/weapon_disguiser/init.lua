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
        ply.DisguiseTargetBodygroups = nil
        ply.OriginalModel = nil
        ply.OriginalPlayerColor = nil
        ply.OriginalBodygroups = nil
    end
end)

hook.Add("PlayerDeath", "Disguiser_RemoveOnDeath", function(victim, inflictor, attacker)
    if victim.OriginalModel then
        victim:SetModel(victim.OriginalModel)
    end

    if victim.OriginalPlayerColor then
        victim:SetPlayerColor(victim.OriginalPlayerColor)
    end

    if victim.OriginalBodygroups then
        for i, value in pairs(victim.OriginalBodygroups) do
            victim:SetBodygroup(i, value)
        end
    end

    if victim.DisguiseEnabled then
        CustomNameHandler:RemoveNameOverlay(victim)
    end

    victim.DisguiseEnabled = false
    victim.DisguiseTargetName = nil
    victim.DisguiseTargetModel = nil
    victim.DisguiseTargetColor = nil
    victim.DisguiseTargetBodygroups = nil
    victim.OriginalModel = nil
    victim.OriginalPlayerColor = nil
    victim.OriginalBodygroups = nil

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
            if IsValid(ply) and ply.OriginalBodygroups then
                for i, value in pairs(ply.OriginalBodygroups) do
                    ply:SetBodygroup(i, value)
                end
            end
        end)
    end
end)
