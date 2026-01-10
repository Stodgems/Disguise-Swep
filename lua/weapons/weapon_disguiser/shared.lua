SWEP.PrintName = "Disguiser"
SWEP.Author = "Charlie"
SWEP.Instructions = "Left Click: Change disguise to target player\nRight Click: Toggle disguise on/off"
SWEP.Category = "Disguiser"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/v_hands.mdl"
SWEP.WorldModel = ""

SWEP.UseHands = false

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    self:SetNextPrimaryFire(CurTime() + 0.5)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local maxRange = Disguiser.Config and Disguiser.Config.TargetRange or 150
    local maxFOV = Disguiser.Config and Disguiser.Config.TargetFOV or 15

    -- Find the closest player within FOV cone
    local aimDir = owner:GetAimVector()
    local eyePos = owner:EyePos()
    local closestTarget = nil
    local closestDist = maxRange + 1

    for _, ply in ipairs(player.GetAll()) do
        if ply ~= owner and IsValid(ply) and ply:Alive() then
            local targetPos = ply:EyePos()
            local distance = eyePos:Distance(targetPos)

            -- Check if within range
            if distance <= maxRange then
                -- Calculate angle between aim direction and direction to target
                local dirToTarget = (targetPos - eyePos):GetNormalized()
                local dotProduct = aimDir:Dot(dirToTarget)
                local angle = math.deg(math.acos(dotProduct))

                -- Check if within FOV cone
                if angle <= maxFOV then
                    -- Keep track of closest valid target
                    if distance < closestDist then
                        closestDist = distance
                        closestTarget = ply
                    end
                end
            end
        end
    end

    if IsValid(closestTarget) then
        if Disguiser.Config and Disguiser.Config:IsTeamBlacklisted(closestTarget:Team()) then
            Disguiser:ChatPrint(owner, "You cannot disguise as this player's team!")
            return
        end

        self:SetDisguiseTarget(owner, closestTarget)
    else
        Disguiser:ChatPrint(owner, "No valid player in range! Get closer or aim at a player.")
    end
end

function SWEP:SecondaryAttack()
    if CLIENT then return end

    self:SetNextSecondaryFire(CurTime() + 0.5)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:ToggleDisguise(owner)
end

function SWEP:SetDisguiseTarget(ply, target)
    if CLIENT then return end

    if not ply.OriginalModel then
        ply.OriginalModel = ply:GetModel()
    end

    if not ply.OriginalPlayerColor then
        ply.OriginalPlayerColor = ply:GetPlayerColor()
    end

    if not ply.OriginalBodygroups then
        ply.OriginalBodygroups = self:GetBodygroups(ply)
    end

    local targetModel = target:GetModel()
    local targetName = CustomNameHandler:GetOriginalName(target)
    local targetColor = target:GetPlayerColor()
    local targetBodygroups = self:GetBodygroups(target)

    ply.DisguiseTargetModel = targetModel
    ply.DisguiseTargetName = targetName
    ply.DisguiseTargetColor = targetColor
    ply.DisguiseTargetBodygroups = targetBodygroups

    if ply.DisguiseEnabled then
        ply:SetModel(targetModel)
        ply:SetPlayerColor(targetColor)
        self:SetBodygroups(ply, targetBodygroups)
        CustomNameHandler:SetNameOverlay(ply, targetName)
        Disguiser:ChatPrint(ply, "Disguise changed to " .. targetName)
    else
        Disguiser:ChatPrint(ply, "Disguise target set to " .. targetName .. ". Right-click to activate!")
    end

    net.Start("Disguiser_UpdateStatus")
        net.WriteBool(ply.DisguiseEnabled or false)
        net.WriteString(targetName)
    net.Send(ply)
end

function SWEP:ToggleDisguise(ply)
    if CLIENT then return end

    if not ply.DisguiseTargetName then
        Disguiser:ChatPrint(ply, "You must aim at a player and left-click to set a disguise target first!")
        return
    end

    if ply.DisguiseEnabled then
        if ply.OriginalModel then
            ply:SetModel(ply.OriginalModel)
        end

        if ply.OriginalPlayerColor then
            ply:SetPlayerColor(ply.OriginalPlayerColor)
        end

        if ply.OriginalBodygroups then
            self:SetBodygroups(ply, ply.OriginalBodygroups)
        end

        CustomNameHandler:RemoveNameOverlay(ply)

        ply.DisguiseEnabled = false

        net.Start("Disguiser_UpdateStatus")
            net.WriteBool(false)
            net.WriteString(ply.DisguiseTargetName or "")
        net.Send(ply)

        Disguiser:ChatPrint(ply, "Disguise deactivated!")
    else
        if ply.DisguiseTargetModel then
            ply:SetModel(ply.DisguiseTargetModel)
        end

        if ply.DisguiseTargetColor then
            ply:SetPlayerColor(ply.DisguiseTargetColor)
        end

        if ply.DisguiseTargetBodygroups then
            self:SetBodygroups(ply, ply.DisguiseTargetBodygroups)
        end

        CustomNameHandler:SetNameOverlay(ply, ply.DisguiseTargetName)

        ply.DisguiseEnabled = true

        net.Start("Disguiser_UpdateStatus")
            net.WriteBool(true)
            net.WriteString(ply.DisguiseTargetName)
        net.Send(ply)

        Disguiser:ChatPrint(ply, "Disguise activated as " .. ply.DisguiseTargetName .. "!")
    end
end

function SWEP:OnRemove()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) and owner.DisguiseEnabled then
            if owner.OriginalModel then
                owner:SetModel(owner.OriginalModel)
            end

            if owner.OriginalPlayerColor then
                owner:SetPlayerColor(owner.OriginalPlayerColor)
            end

            if owner.OriginalBodygroups then
                self:SetBodygroups(owner, owner.OriginalBodygroups)
            end

            CustomNameHandler:RemoveNameOverlay(owner)

            owner.DisguiseEnabled = false
            owner.DisguiseTargetName = nil
            owner.DisguiseTargetModel = nil
            owner.DisguiseTargetColor = nil
            owner.DisguiseTargetBodygroups = nil
        end
    end
end

function SWEP:Deploy()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            -- Sync current disguise state to client when weapon is deployed
            local isActive = owner.DisguiseEnabled or false
            local targetName = owner.DisguiseTargetName or ""

            net.Start("Disguiser_UpdateStatus")
                net.WriteBool(isActive)
                net.WriteString(targetName)
            net.Send(owner)
        end
    end
    return true
end

function SWEP:Holster()
    return true
end

-- Bodygroup helper functions
function SWEP:GetBodygroups(ply)
    if not IsValid(ply) then return {} end

    local bodygroups = {}
    local numBodygroups = ply:GetNumBodyGroups()

    for i = 0, numBodygroups - 1 do
        bodygroups[i] = ply:GetBodygroup(i)
    end

    return bodygroups
end

function SWEP:SetBodygroups(ply, bodygroups)
    if not IsValid(ply) then return end
    if not bodygroups then return end

    for i, value in pairs(bodygroups) do
        ply:SetBodygroup(i, value)
    end
end
