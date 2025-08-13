--#region Variables
local Mod = ExemplarsBeacon

local Sword = {}
ExemplarsBeacon.Sword = Sword

local Util = Mod.Util
local AttackHelper = Mod.AttackHelper.Functions

Sword.WOODEN_SWORD_ID = Isaac.GetItemIdByName("Wooden Sword")
Sword.BLESSING_ID = Isaac.GetNullItemIdByName("Agui's Blessing")
Sword.BLESSED_TEAR_VARIANT = Isaac.GetEntityVariantByName("Blessed Tear")
Sword.SWORD_EFFECT_VARIANT = Isaac.GetEntityVariantByName("Exemplar's Beacon")
Sword.ATTACK_EFFECT_VARIANT = Isaac.GetEntityVariantByName("Sword Attack")

Sword.ATTACKS_BETWEEN_ACTIVATION = 5
Sword.POSITION_OFFSET = 45

local ONE_SEC = 30

-- TODO:
-- Cleanup code pls
-- Cache num of weapon fired when the sword comes back
-- Make the weapon come back when the tear dies
-- Make the capsule thingy!

--#endregion
--#region Sword Callbacks
---@param player EntityPlayer
function Sword:EvaluateCache(player, customCache)
    local fx = player:GetEffects()
    local data = Util:GetData(player, "Sword")
    if (fx:GetCollectibleEffectNum(Sword.WOODEN_SWORD_ID) + player:GetCollectibleNum(Sword.WOODEN_SWORD_ID)) > 0
    and not data.sword then
        data.sword = Util:SpawnEffect(Sword.SWORD_EFFECT_VARIANT, player.Position, 0, player)
    elseif (fx:GetCollectibleEffectNum(Sword.WOODEN_SWORD_ID) + player:GetCollectibleNum(Sword.WOODEN_SWORD_ID)) == 0
    and data.sword then
        data.sword:Remove()
        data.sword = nil
    end
end
Mod:AddCallback(ModCallbacks.MC_EVALUATE_CUSTOM_CACHE, Sword.EvaluateCache, "effectfeedback")

---@param effect EntityEffect
function Sword:OnSwordInit(effect)
    local player = effect.SpawnerEntity and effect.SpawnerEntity:ToPlayer()
    if not player then return end

    local positionOffset =  effect.FlipX and -Sword.POSITION_OFFSET or Sword.POSITION_OFFSET
    local idlePosition = player.Position + Vector(positionOffset, 0)
    effect.Position = idlePosition
    effect:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)
    --local data = Util:GetData(effect, "Sword")
end
Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, Sword.OnSwordInit, Sword.SWORD_EFFECT_VARIANT)

function Sword:VectorLerp(init, target, strength) return init + (target - init) * strength end

---@param effect EntityEffect
function Sword:OnSwordUpdate(effect)
    local player = effect.SpawnerEntity and effect.SpawnerEntity:ToPlayer()
    if not player then return end

    local aimDirection = player:GetAimDirection()
    local movement = player:GetMovementVector()
    if aimDirection.X < 0 then
        effect.FlipX = false
    elseif aimDirection.X > 0 then
        effect.FlipX = true
    elseif movement.X < 0 then
        effect.FlipX = false
    elseif movement.X > 0 then
        effect.FlipX = true
    end

    local positionOffset =  effect.FlipX and -Sword.POSITION_OFFSET or Sword.POSITION_OFFSET
    local idlePosition = player.Position + Vector(positionOffset, 0)
    local distance = idlePosition:DistanceSquared(effect.Position) / 60
    local speed = 10
    local targetVelocity = (idlePosition - effect.Position):Resized(math.min(speed * distance, speed))
    effect.Velocity = Sword:VectorLerp(effect.Velocity, targetVelocity, 0.3)

    local sprite = effect:GetSprite()
    local data = Util:GetData(player, "Sword")
    if not data.fireAmount
    or (data.fireAmount % (Sword.ATTACKS_BETWEEN_ACTIVATION) > 1 or data.fireAmount <= player:GetActiveWeaponNumFired()) then
        data.fireAmount = player:GetActiveWeaponNumFired()
    end

    if sprite:IsFinished("StartUp")
    or sprite:IsFinished("Return") then
        sprite:Play("Idle", true)
    end

    local fx = player:GetEffects()
    if not fx:HasNullEffect(Sword.BLESSING_ID) then
        if not sprite:IsPlaying("Return")
        and data.summonedAttack
        and data.summonedAttack:GetSprite():IsPlaying("Disappear") then
            effect:SetShadowSize(0.11)
            sprite:Play("Return", true)
            data.summonedAttack = nil
        end
    end

    if data.fireAmount % (Sword.ATTACKS_BETWEEN_ACTIVATION) == 0 and sprite:GetAnimation() ~= "Fade" then
        sprite:Play("Fade")
        local shootingCD = ONE_SEC - 7 -- No splitframe head switching
        player:SetShootingCooldown(shootingCD)
    elseif sprite:IsFinished("Fade") and player:CanShoot() and not fx:HasNullEffect(Sword.BLESSING_ID)
    and not data.summonedAttack then
        effect:SetShadowSize(0)
        player:AddNullItemEffect(Sword.BLESSING_ID, true)
        player:SetColor(Color(1, 1, 1, 1, 0.3, 0.2, 0), ONE_SEC, 10, true, false)
        Util.SfxMan:Play(SoundEffect.SOUND_BEEP)
        player:SetCanShoot(false)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, Sword.OnSwordUpdate, Sword.SWORD_EFFECT_VARIANT)

--function Sword:OnRender(familiar)
    --Isaac.DrawLine(Isaac.WorldToScreen(familiar.Player.Position), Isaac.WorldToScreen(familiar.Position), KColor.Blue, KColor.Transparent, 10)
--end
--Mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_RENDER, Sword.OnRender, Sword.FAMILIAR_VARIANT)

---@param player EntityPlayer
function Sword:OnPlayerUpdate(player)
    local fx = player:GetEffects()

    local aimDirection = player:GetAimDirection()
    if (aimDirection.X ~= 0 or aimDirection.Y ~= 0) and fx:HasNullEffect(Sword.BLESSING_ID)
    and player.FireDelay < 1 then
        local tear = player:FireTear(player.Position, player:GetAimDirection() * player.ShotSpeed * 10 + player:GetTearMovementInheritance(player:GetAimDirection()), false)

        tear.TearFlags = TearFlags.TEAR_HOMING | TearFlags.TEAR_BURN
        fx:RemoveNullEffect(Sword.BLESSING_ID, 1)

        local sprite = tear:GetSprite()
        local tearAnim = sprite:GetAnimation()
        tear:ChangeVariant(Sword.BLESSED_TEAR_VARIANT)
        --sprite:Load("gfx/tear_blessed.anm2", true)
        sprite:Play(tearAnim)

        local fireDelay = player.MaxFireDelay // 1
        local fireDirection = player:GetFireDirection()
        player:SetHeadDirection(fireDirection, fireDelay)
        player.HeadFrameDelay = fireDelay
        player.FireDelay = player.MaxFireDelay

        local data = Util:GetData(player, "Sword")
        data.fireAmount = player:GetActiveWeaponNumFired() + 1

        Isaac.CreateTimer(function()
        if Util.Game:GetChallengeParams():CanShoot() then
            player:SetCanShoot(true)
        end
        end, fireDelay, 1, true)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Sword.OnPlayerUpdate)

---@param tear EntityTear
---@param collider Entity
function Sword:OnTearCollision(tear, collider)
    if collider:IsVulnerableEnemy() then
        local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
        if not player then return end

        local data = Util:GetData(player, "Sword")
        data.summonedAttack = AttackHelper:SummonAttack(tear.Position + tear.PositionOffset, player)
        Util.SfxMan:Play(SoundEffect.SOUND_BEAST_BACKGROUND_DIVE)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_TEAR_COLLISION, Sword.OnTearCollision, Sword.BLESSED_TEAR_VARIANT)

function Sword:OnNewRoom()
    for _, sword in ipairs(Util:GetEffects(Sword.SWORD_EFFECT_VARIANT)) do
        local player = sword.SpawnerEntity and sword.SpawnerEntity:ToPlayer()
        if player then
            local positionOffset =  sword.FlipX and -Sword.POSITION_OFFSET or Sword.POSITION_OFFSET
            local idlePosition = player.Position + Vector(positionOffset, 0)
            sword.Position = idlePosition
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Sword.OnNewRoom)
--#endregion