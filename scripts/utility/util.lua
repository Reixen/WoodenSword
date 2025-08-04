--#region Variables
local Mod = ExemplarsBeacon

local Util = {}
Mod.Util = Util

Util.Game = Game()
Util.SfxMan = SFXManager()
Util.Room = function() return Mod.Game:GetRoom() end
Util.Level = function() return Mod.Game:GetLevel() end
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