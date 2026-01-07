include("shared.lua")

SWEP.DisguiseActive = false
SWEP.DisguisedName = ""

surface.CreateFont("DisguiserFont_Title", {
    font = "Roboto",
    size = 24,
    weight = 700,
    antialias = true,
})

surface.CreateFont("DisguiserFont_Status", {
    font = "Roboto",
    size = 20,
    weight = 500,
    antialias = true,
})

surface.CreateFont("DisguiserFont_Name", {
    font = "Roboto",
    size = 22,
    weight = 600,
    antialias = true,
})

net.Receive("Disguiser_UpdateStatus", function()
    local isActive = net.ReadBool()
    local targetName = net.ReadString()

    local wep = LocalPlayer():GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == "weapon_disguiser" then
        wep.DisguiseActive = isActive
        wep.DisguisedName = targetName
    end
end)

function SWEP:DrawHUD()
    local scrW, scrH = ScrW(), ScrH()

    local panelW = 400
    local panelH = 120
    local panelX = scrW - panelW - 20
    local panelY = scrH / 2 - panelH / 2

    draw.RoundedBox(8, panelX, panelY, panelW, panelH, Color(20, 20, 20, 240))
    draw.RoundedBox(8, panelX, panelY, panelW, 40, Color(40, 40, 40, 240))

    draw.SimpleText("DISGUISER", "DisguiserFont_Title", panelX + panelW / 2, panelY + 20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local statusText = "Status: "
    local statusColor
    local statusValue

    if self.DisguiseActive then
        statusValue = "ACTIVE"
        statusColor = Color(50, 255, 50, 255)
    else
        statusValue = "INACTIVE"
        statusColor = Color(255, 50, 50, 255)
    end

    draw.SimpleText(statusText, "DisguiserFont_Status", panelX + 20, panelY + 60, Color(200, 200, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    surface.SetFont("DisguiserFont_Status")
    local statusTextW = surface.GetTextSize(statusText)
    draw.SimpleText(statusValue, "DisguiserFont_Status", panelX + 20 + statusTextW, panelY + 60, statusColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    if self.DisguisedName ~= "" then
        local labelText = self.DisguiseActive and "Disguised as:" or "Target:"
        draw.SimpleText(labelText, "DisguiserFont_Status", panelX + 20, panelY + 85, Color(200, 200, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(self.DisguisedName, "DisguiserFont_Name", panelX + panelW / 2, panelY + 85, Color(100, 200, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("Left-click a player to set target", "DisguiserFont_Status", panelX + panelW / 2, panelY + 90, Color(150, 150, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

