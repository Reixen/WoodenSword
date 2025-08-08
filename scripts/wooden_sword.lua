--#region Variables
local Mod = ExemplarsBeacon

local Sword = {}
Mod.Sword = Sword

local Util = Mod.Util

Sword.WOODEN_SWORD_ID = Isaac.GetItemIdByName("Wooden Sword")
Sword.EXEMPLARS_BEACON_ID = Isaac.GetItemIdByName("Exemplar's Beacon")
Sword.BLESSING_ID = Isaac.GetNullItemIdByName("Agui's Blessing")

local itemConfig = Isaac.GetItemConfig()
Sword.BEACON_CONFIG = itemConfig:GetCollectible(Sword.EXEMPLARS_BEACON_ID)
Sword.FAMILIAR_VARIANT = Isaac.GetEntityVariantByName("Exemplar's Beacon (Familiar)")

Sword.TEAR_COUNT_BETWEEN_ATTACKS = 5
Sword.POSITION_OFFSET = 40

local ONE_SEC = 30

-- todo:
-- Reeturn sword aftre shooting
-- stop tear spam

--#endregion
--#region Sword Callbacks
---@param player EntityPlayer
function Sword:EvaluateCache(player)
    local fx = player:GetEffects()
    local familiarCount = fx:GetCollectibleEffectNum(Sword.EXEMPLARS_BEACON_ID) + player:GetCollectibleNum(Sword.EXEMPLARS_BEACON_ID)
    local rng = RNG(Random())

    local sword = player:CheckFamiliarEx(Sword.FAMILIAR_VARIANT, familiarCount > 0 and 1 or 0, rng, Sword.BEACON_CONFIG)
    local data = Util:GetData(player, "Sword")
    data.swordCount = familiarCount
    data.swordEntity = sword[1]
end
Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Sword.EvaluateCache, CacheFlag.CACHE_FAMILIARS)

---@param familiar EntityFamiliar
function Sword:OnSwordInit(familiar)
    familiar.Position = familiar.Player.Position
    familiar.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    local data = Util:GetData(familiar.Player, "Sword")
    if data.canStartUp then
        data.canStartUp = false
        familiar:GetSprite():Play("StartUp", true)
    end
end

function Sword:VectorLerp(init, target, strength) return init + (target - init) * strength end

---@param familiar EntityFamiliar
function Sword:OnSwordUpdate(familiar)
    local player = familiar.Player

    local aimDirection = player:GetAimDirection()
    if aimDirection.X < 0 then
        familiar.FlipX = false
    elseif aimDirection.X > 0 then
        familiar.FlipX = true
    end
    local positionOffset = familiar.FlipX and -Sword.POSITION_OFFSET or Sword.POSITION_OFFSET
    local idlePosition = player.Position + Vector(positionOffset, 0)
    local targetVelocity = (idlePosition - familiar.Position):Resized(20)

    familiar.Velocity = Sword:VectorLerp(familiar.Velocity, targetVelocity, 0.2)

    local sprite = familiar:GetSprite()
    local data = Util:GetData(player, "Sword")
    if sprite:IsFinished("StartUp")
    or sprite:IsFinished("Return") then
        sprite:Play("Idle", true)
    end

    local fx = player:GetEffects()
    data.tearsFired = data.tearsFired or 0
    if fx:HasNullEffect(Sword.BLESSING_ID) and player:CanShoot() then
        sprite:Play("Return", true)
        return
    end

    if data.tearsFired % Sword.TEAR_COUNT_BETWEEN_ATTACKS == 0 and not sprite:IsPlaying("Fade") then
        sprite:Play("Fade")
    elseif sprite:IsFinished("Fade") then
        player:AddNullItemEffect(Sword.BLESSING_ID, true)
        player:SetColor(Color(1, 1, 1, 1, 0.3, 0.2, 0), ONE_SEC, 10, true, false)
        Util.SfxMan:Play(SoundEffect.SOUND_BEEP)
    end
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, Sword.OnSwordUpdate, Sword.FAMILIAR_VARIANT)

--function Sword:OnRender(familiar)
    --Isaac.DrawLine(Isaac.WorldToScreen(familiar.Player.Position), Isaac.WorldToScreen(familiar.Position), KColor.Blue, KColor.Transparent, 10)
--end
--Mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_RENDER, Sword.OnRender, Sword.FAMILIAR_VARIANT)
---@param player EntityPlayer
function Sword:OnUseWoodenSword(_, _, player)
    player:RemoveCollectible(Sword.EXEMPLARS_BEACON_ID)
    local data = Util:GetData(player, "Sword")
    data.canStartUp = true
    player:AddCollectible(Sword.EXEMPLARS_BEACON_ID)
    return {
        Remove = true,
        ShowAnim = true
    }
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, Sword.OnUseWoodenSword, Sword.WOODEN_SWORD_ID)

---@param player EntityPlayer
function Sword:OnPlayerUpdate(player)
    local fx = player:GetEffects()

    print(fx:HasNullEffect(Sword.BLESSING_ID) and "i has null" or "no null")
    if not fx:HasNullEffect(Sword.BLESSING_ID) then
        if not player:CanShoot() then
            player:SetCanShoot(true)
        end
        print("return")
        return
    end

    player:SetCanShoot(false)
    player:FireTear(player.Position, player:GetAimDirection() * player.ShotSpeed + player:GetTearMovementInheritance(player:GetAimDirection()), false)
    fx:RemoveNullEffect(Sword.BLESSING_ID)
    print("removing")
end
Mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Sword.OnPlayerUpdate)

---@param entity Entity
function Sword:OnWeaponFire(_, _, entity)
    local player = entity:ToPlayer()
    if not player or entity.Variant ~= PlayerVariant.PLAYER
    or (not player:GetEffects():HasCollectibleEffect(Sword.EXEMPLARS_BEACON_ID) and not player:HasCollectible(Sword.EXEMPLARS_BEACON_ID))
    then return end

    local data = Util:GetData(player, "Sword")
    data.tearsFired = data.tearsFired and data.tearsFired + 1 or 1
end
Mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_WEAPON_FIRED, Sword.OnWeaponFire, WeaponType.WEAPON_TEARS)

---@param tear EntityTear
function Sword:PostFireTear(tear)
    local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer() ---@cast player EntityPlayer | nil
    if not player then return end

    local fx = player:GetEffects()
    if fx:HasNullEffect(Sword.BLESSING_ID) then
        tear.Color = Color(1, 1, 1, 1, 0.4, 0, 0.4)
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_BURN
        fx:RemoveNullEffect(Sword.BLESSING_ID)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, Sword.PostFireTear)
--#endregion