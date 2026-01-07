SWEP.PrintName = "Disguiser"
SWEP.Author = "Charlie"
SWEP.Instructions = "Left Click: Change disguise to target player\nRight Click: Toggle disguise on/off"
SWEP.Category = "Disuiser"

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

    local trace = owner:GetEyeTrace()
    local target = trace.Entity

    if IsValid(target) and target:IsPlayer() and target ~= owner then
        local maxRange = Disguiser.Config and Disguiser.Config.TargetRange or 150

        if owner:GetPos():Distance(target:GetPos()) <= maxRange then
            if Disguiser.Config and Disguiser.Config:IsTeamBlacklisted(target:Team()) then
                Disguiser:ChatPrint(owner, "You cannot disguise as this player's team!")
                return
            end

            self:SetDisguiseTarget(owner, target)
        else
            if SERVER then
                Disguiser:ChatPrint(owner, "Target too far away! Get closer.")
            end
        end
    else
        if SERVER then
            Disguiser:ChatPrint(owner, "You must aim at a player to change disguise!")
        end
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

    local targetModel = target:GetModel()
    local targetName = CustomNameHandler:GetOriginalName(target)
    local targetColor = target:GetPlayerColor()

    ply.DisguiseTargetModel = targetModel
    ply.DisguiseTargetName = targetName
    ply.DisguiseTargetColor = targetColor

    if ply.DisguiseEnabled then
        ply:SetModel(targetModel)
        ply:SetPlayerColor(targetColor)
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

            CustomNameHandler:RemoveNameOverlay(owner)

            owner.DisguiseEnabled = false
            owner.DisguiseTargetName = nil
            owner.DisguiseTargetModel = nil
            owner.DisguiseTargetColor = nil
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
