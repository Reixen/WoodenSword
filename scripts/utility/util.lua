--#region Variables
local Mod = ExemplarsBeacon

local Util = {}
ExemplarsBeacon.Util = Util

Util.Game = Game()
Util.SfxMan = SFXManager()
Util.Room = function() return Util.Game:GetRoom() end ---@return Room
Util.Level = function() return Util.Game:GetLevel() end ---@return Level
--#endregion
--#region Helper Functions
---@param table table
---@return table
function Util:CopyTable(table)
    local copy = {}
    for key, val in pairs(table) do
        copy[key] = type(val) ~= "table" and val or Util:CopyTable(val)
    end
    return copy
end

---@param entity Entity
---@param identifier string
---@param default table?
function Util:GetData(entity, identifier, default)
    local data = entity:GetData()
    data._SwordMod = data._SwordMod or {}
    data._SwordMod[identifier] = data._SwordMod[identifier] or default or {}
    return data._SwordMod[identifier]
end

---@param variant EffectVariant
---@param position Vector
---@param subtype integer?
---@param spawner Entity?
---@param velocity Vector?
---@return Entity
function Util:SpawnEffect(variant, position, subtype, spawner, velocity)
    return Isaac.Spawn(EntityType.ENTITY_EFFECT, variant, subtype or 0, position, velocity or Vector.Zero, spawner or nil)
end

---@param variant EffectVariant
---@param subtype integer?
---@param cache boolean?
---@param ignoreFriendly boolean?
---@return Entity[]
function Util:GetEffects(variant, subtype, cache, ignoreFriendly)
    return Isaac.FindByType(EntityType.ENTITY_EFFECT, variant, subtype, cache, ignoreFriendly)
end

-- Entity Identifier
--local PriceTextFontTempesta = Font()
--PriceTextFontTempesta:Load("font/pftempestasevencondensed.fnt")

--local function effectRender(effect)
    --local pos = Isaac.WorldToScreen(effect.Position)
    --PriceTextFontTempesta:DrawStringScaled(
            --effect.Type.."."..effect.Variant.."."..effect.SubType,
            --pos.X,
            --pos.Y,
            --0.75, 0.75, -- scale
            --KColor(1, 1, 1, 1)
        --)
--end

--local function renderEffects(_, effect)
    --if not effect then
        --for index, value in ipairs(Isaac.GetRoomEntities()) do
            --effectRender(value)
        --end
    --else
        --effectRender(effect)
    --end
--end

--Mod:AddCallback(ModCallbacks.MC_POST_RENDER, renderEffects)
--#endregion