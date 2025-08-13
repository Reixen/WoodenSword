--#region Variables
local Mod = ExemplarsBeacon

local AttackHelper = {}
ExemplarsBeacon.AttackHelper = AttackHelper

local Util = Mod.Util

AttackHelper.SUMMON_EFFECT_VARIANT = Isaac.GetEntityVariantByName("Summoning Light")
AttackHelper.ATTACK_RENDER_PATH = "gfx/render_sword_attack.anm2"
--#endregion
--#region Attack Inventory System
---@class AttackHelper
---@field Inventory table @Inventory containing all the alternate attacks
local AttackInventory = {}
AttackInventory.__index = AttackInventory
AttackInventory.Inventory = {}
AttackHelper.Functions = setmetatable({}, AttackInventory)

---@class SwordAttackParams
---@field Name string @The string identifier
---@field TrackEnemy boolean? @Should it rotate towards the enemy when it spawns?
-----@field Capsule Capsule @The area where it should affect the enemies
---@field CapsuleOffset Vector? @Offset away from the center Position

---@param params SwordAttackParams
function AttackInventory:AddAttack(params)
    local attack = {}
    attack.Name = params.Name
    attack.TrackEnemy = params.TrackEnemy or false
    attack.CapsuleOffset = params.CapsuleOffset or nil

    self.Inventory[#self.Inventory+1] = attack
end

AttackHelper.Functions:AddAttack( { Name = "Spin", TrackEnemy = false })

---@return table
function AttackInventory:GetAttackNames()
    local table = {}
    for i, attack in ipairs(self.Inventory) do
        table[attack.Name] = i
    end
    return table
end

---@param position Vector
---@param player EntityPlayer
---@param attackType integer?
---@param repeats integer?
---@return EntityEffect
function AttackInventory:SummonAttack(position, player, attackType, repeats)
    local effect = Util:SpawnEffect(AttackHelper.SUMMON_EFFECT_VARIANT, position, nil, player):ToEffect() ---@cast effect EntityEffect
    effect.DepthOffset = 500
    local data = Util:GetData(effect, "Sword")

    local rng = effect:GetDropRNG()
    local attackName = attackType and self.Inventory[attackType].Name or self.Inventory[rng:RandomInt(1, #self.Inventory)].Name

    local multishotParams = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)
    local numTears = multishotParams:GetNumTears() > 0 and multishotParams:GetNumTears() or nil

    data.attackName = attackName
    data.repeats = repeats or numTears or 1
    data.swordSprite = Sprite()
    data.swordSprite:Load(AttackHelper.ATTACK_RENDER_PATH)
    data.swordSprite.Rotation = math.random(1, 360)

    return effect
end
--#endregion
--#region Summon Effect Callbacks
-----@param effect EntityEffect
--function AttackHelper:OnSummonInit(effect)
    --local data = Util:GetData(effect, "Sword")
--end
--Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, AttackHelper.OnSummonInit, AttackHelper.SUMMON_EFFECT_VARIANT)

---@param effect EntityEffect
function AttackHelper:OnSummonUpdate(effect)
    local sprite = effect:GetSprite()
    local data = Util:GetData(effect, "Sword")

    if sprite:IsFinished("Appear") then
        data.canAttack = true
    end

    if not data.speed then
        data.speed = data.repeats
        sprite.PlaybackSpeed = 1 + data.speed * 0.15
        data.swordSprite.PlaybackSpeed = sprite.PlaybackSpeed
    end

    if not sprite:IsPlaying("Disappear") and data.repeats == 0 then
        sprite:Play("Disappear")
    elseif sprite:IsFinished("Disappear") then
        effect:Remove()
    end

    if data.swordSprite then
        if data.swordSprite:IsFinished(data.attackName) then
            data.repeats = data.repeats - 1
            if data.repeats > 0 then
                data.swordSprite:Play(data.attackName, true)
            end
        end
        data.swordSprite:Update()
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, AttackHelper.OnSummonUpdate, AttackHelper.SUMMON_EFFECT_VARIANT)

---@param effect EntityEffect
---@param offset Vector
function AttackHelper:OnSummonRender(effect, offset)
    local data = Util:GetData(effect, "Sword")
    if not data.canAttack
    or not data.swordSprite
    or not data.repeats then return end

    if not data.swordSprite:IsPlaying(data.attackName) then
        data.swordSprite:Play(data.attackName)
    end

    if data.repeats > 0 then
        local renderMode = Util.Room():GetRenderMode()
        local renderPos = Isaac.WorldToRenderPosition(effect.Position + effect.PositionOffset + offset)

        if renderMode ~= RenderMode.RENDER_WATER_ABOVE and renderMode ~= RenderMode.RENDER_NORMAL then
            data.swordSprite:Render(renderPos)
            return
        end
        data.swordSprite:Render(renderPos)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, AttackHelper.OnSummonRender, AttackHelper.SUMMON_EFFECT_VARIANT)
--#endregion