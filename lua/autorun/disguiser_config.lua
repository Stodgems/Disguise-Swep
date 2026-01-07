--[[
    Disguiser Configuration
    Configure the disguiser addon settings here
]]--

Disguiser = Disguiser or {}
Disguiser.Config = Disguiser.Config or {}

--[[
    Chat Prefix
    The prefix shown in chat messages
    Default: "Disguiser"
]]--
Disguiser.Config.ChatPrefix = "Disguiser"

--[[
    Target Range
    Maximum distance (in units) a player can be from the target to disguise as them
    Default: 150
]]--
Disguiser.Config.TargetRange = 150

--[[
    Blacklisted Teams
    Add team IDs to this table to prevent players from disguising as members of these teams

    Example for DarkRP:
    Disguiser.Config.BlacklistedTeams = {
        TEAM_POLICE,
        TEAM_MAYOR,
        TEAM_CHIEF,
    }

    To find team IDs, you can use the console command: lua_run PrintTable(RPExtraTeams)
    Or check your DarkRP jobs.lua file
]]--
Disguiser.Config.BlacklistedTeams = {
    -- Add team IDs here
    -- Example: TEAM_POLICE,
    
}

--[[
    Helper function to check if a team is blacklisted
    @param teamID - The team ID to check
    @return boolean - True if team is blacklisted
]]--
function Disguiser.Config:IsTeamBlacklisted(teamID)
    for _, blacklistedTeam in ipairs(self.BlacklistedTeams) do
        if blacklistedTeam == teamID then
            return true
        end
    end
    return false
end

--[[
    Colored Chat Print Function
    Sends a colored message to the player's chat
    @param ply - The player to send the message to
    @param message - The message to send
]]--
function Disguiser:ChatPrint(ply, message)
    if not IsValid(ply) then return end

    if SERVER then
        net.Start("Disguiser_ChatMessage")
            net.WriteString(message)
        net.Send(ply)
    end
end

if CLIENT then
    net.Receive("Disguiser_ChatMessage", function()
        local message = net.ReadString()
        local prefix = Disguiser.Config.ChatPrefix or "Disguiser"

        chat.AddText(
            Color(100, 200, 255), "[" .. prefix .. "] ",
            Color(255, 255, 255), message
        )
    end)
end

if SERVER then
    util.AddNetworkString("Disguiser_ChatMessage")
end

print("[Disguiser] Configuration loaded successfully!")
