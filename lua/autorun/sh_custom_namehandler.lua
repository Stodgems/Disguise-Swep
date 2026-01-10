--[[
    Custom Name Handler
    Allows addons to overlay player names with custom names
    Perfect for disguise systems, roleplay, etc.
]]--

CustomNameHandler = CustomNameHandler or {}
CustomNameHandler.OverlayedNames = CustomNameHandler.OverlayedNames or {}

if SERVER then
    util.AddNetworkString("CustomNameHandler_SetOverlay")
    util.AddNetworkString("CustomNameHandler_RemoveOverlay")
    util.AddNetworkString("CustomNameHandler_SyncAll")
end

--[[
    Set a name overlay for a player
    @param ply - The player to overlay the name for
    @param overlayName - The new name to display (or nil to remove overlay)
]]--
function CustomNameHandler:SetNameOverlay(ply, overlayName)
    if not IsValid(ply) then return end

    if SERVER then
        if overlayName and overlayName ~= "" then
            self.OverlayedNames[ply:SteamID()] = overlayName

            net.Start("CustomNameHandler_SetOverlay")
                net.WriteEntity(ply)
                net.WriteString(overlayName)
            net.Broadcast()
        else
            self:RemoveNameOverlay(ply)
        end
    end
end

--[[
    Remove a name overlay from a player
    @param ply - The player to remove the overlay from
]]--
function CustomNameHandler:RemoveNameOverlay(ply)
    if not IsValid(ply) then return end

    if SERVER then
        local steamID = ply:SteamID()
        if self.OverlayedNames[steamID] then
            self.OverlayedNames[steamID] = nil

            net.Start("CustomNameHandler_RemoveOverlay")
                net.WriteEntity(ply)
            net.Broadcast()
        end
    end
end

--[[
    Get the display name for a player (with overlay if present)
    @param ply - The player to get the name for
    @return string - The overlayed name or original name
]]--
function CustomNameHandler:GetDisplayName(ply)
    if not IsValid(ply) then return "Unknown" end

    local steamID = ply:SteamID()
    if self.OverlayedNames[steamID] then
        return self.OverlayedNames[steamID]
    end

    return ply:Nick()
end

--[[
    Check if a player has a name overlay active
    @param ply - The player to check
    @return boolean - True if overlay is active
]]--
function CustomNameHandler:HasNameOverlay(ply)
    if not IsValid(ply) then return false end
    return self.OverlayedNames[ply:SteamID()] ~= nil
end

-- Store original Nick function for server-side use
CustomNameHandler.OriginalNick = FindMetaTable("Player").Nick

--[[
    Get the original name of a player (bypasses overlay)
    @param ply - The player to get the original name for
    @return string - The player's original name (including VoidFactions faction/rank tags if present)
]]--
function CustomNameHandler:GetOriginalName(ply)
    if not IsValid(ply) then return "Unknown" end

    -- VoidFactions support - VoidFactions modifies DarkRP's rpname with faction/rank tags
    -- The format is: [faction tag] [rank tag] [player name]
    if VoidFactions and DarkRP then
        -- VoidFactions uses DarkRP's setDarkRPVar to set the full name with faction/rank
        -- This includes the faction tag and rank tag prefix
        local darkRPName = ply:getDarkRPVar("rpname")
        if darkRPName and darkRPName ~= "" then
            return darkRPName
        end
    end

    -- Fallback to the original Nick function which may be overridden by VoidFactions/DarkRP
    local nickName = CustomNameHandler.OriginalNick(ply)
    if nickName and nickName ~= "" then
        return nickName
    end

    return "Unknown"
end

if SERVER then
    -- Clean up overlays when players disconnect
    hook.Add("PlayerDisconnected", "CustomNameHandler_Cleanup", function(ply)
        local steamID = ply:SteamID()
        if CustomNameHandler.OverlayedNames[steamID] then
            CustomNameHandler.OverlayedNames[steamID] = nil
        end
    end)

    -- Sync all overlays to newly connected players
    hook.Add("PlayerInitialSpawn", "CustomNameHandler_SyncToNewPlayer", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end

            for steamID, overlayName in pairs(CustomNameHandler.OverlayedNames) do
                local targetPly = player.GetBySteamID(steamID)
                if IsValid(targetPly) then
                    net.Start("CustomNameHandler_SetOverlay")
                        net.WriteEntity(targetPly)
                        net.WriteString(overlayName)
                    net.Send(ply)
                end
            end
        end)
    end)
end

if CLIENT then
    -- Receive overlay updates from server
    net.Receive("CustomNameHandler_SetOverlay", function()
        local ply = net.ReadEntity()
        local overlayName = net.ReadString()

        if IsValid(ply) then
            CustomNameHandler.OverlayedNames[ply:SteamID()] = overlayName
        end
    end)

    net.Receive("CustomNameHandler_RemoveOverlay", function()
        local ply = net.ReadEntity()

        if IsValid(ply) then
            CustomNameHandler.OverlayedNames[ply:SteamID()] = nil
        end
    end)

    -- Hook into the scoreboard name display
    hook.Add("ScoreboardPlayerName", "CustomNameHandler_ScoreboardName", function(ply)
        return CustomNameHandler:GetDisplayName(ply)
    end)

    -- Override player metatable functions after game is fully initialized
    hook.Add("Initialize", "CustomNameHandler_SetupMetatable", function()
        local playerMeta = FindMetaTable("Player")
        if playerMeta then
            local oldNick = playerMeta.Nick
            playerMeta.Nick = function(self)
                if not IsValid(self) then return "Unknown" end
                local steamID = self:SteamID()
                if CustomNameHandler.OverlayedNames[steamID] then
                    return CustomNameHandler.OverlayedNames[steamID]
                end
                return oldNick(self)
            end

            -- Also override GetName which is used in some places
            local oldGetName = playerMeta.GetName
            playerMeta.GetName = function(self)
                if not IsValid(self) then return "Unknown" end
                local steamID = self:SteamID()
                if CustomNameHandler.OverlayedNames[steamID] then
                    return CustomNameHandler.OverlayedNames[steamID]
                end
                return oldGetName(self)
            end

            -- Add Name() alias if it exists
            if playerMeta.Name then
                local oldName = playerMeta.Name
                playerMeta.Name = function(self)
                    if not IsValid(self) then return "Unknown" end
                    local steamID = self:SteamID()
                    if CustomNameHandler.OverlayedNames[steamID] then
                        return CustomNameHandler.OverlayedNames[steamID]
                    end
                    return oldName(self)
                end
            end
        end
    end)
end

--[[
    EXAMPLE USAGE FOR DISGUISE SWEP:

    -- When disguise is activated:
    CustomNameHandler:SetNameOverlay(player, targetPlayer:Nick())

    -- When disguise is deactivated:
    CustomNameHandler:RemoveNameOverlay(player)

    -- To display a player's name in your HUD/scoreboard:
    local displayName = CustomNameHandler:GetDisplayName(player)

    -- To check if a player is disguised:
    if CustomNameHandler:HasNameOverlay(player) then
        -- Player is disguised
    end

    -- To get the original name (for admin checks, etc.):
    local originalName = CustomNameHandler:GetOriginalName(player)
]]--

print("[Custom Name Handler] Loaded successfully!")
