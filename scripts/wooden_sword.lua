--#region Variables
local Mod = ExemplarsBeacon

local Sword = {}
Mod.Sword = Sword

local Util = Mod.Util
Sword.WOODEN_SWORD_ID = Isaac.GetItemIdByName("Wooden Sword")
Sword.EXEMPLARS_BEACON_ID = Isaac.GetItemIdByName("Exemplar's Beacon")
Sword.BLESSING_ID = Isaac.GetNullItemIdByName("Agui's Blessing")
--#endregion
--#region Sword Callbacks
---@param player EntityPlayer
function Sword:OnUseWoodenSword(_, _, player)
    Util.SfxMan:Play(SoundEffect.SOUND_FART)
    return true
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, Sword.OnUseWoodenSword, Sword.WOODEN_SWORD_ID)
--#endregion