ExemplarsBeacon = RegisterMod("Exemplar's Beacon", 1)

if not REPENTOGON then return end

ExemplarsBeacon.Util = {}
ExemplarsBeacon.SaveManager = include("scripts.utility.save_manager")
ExemplarsBeacon.SaveManager.Init(ExemplarsBeacon)

ExemplarsBeacon.Sword = {}
ExemplarsBeacon.Compatibility ={}

include("scripts.utility.util")
include("scripts.wooden_sword")