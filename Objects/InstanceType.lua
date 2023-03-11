-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;

objects.InstanceType = addon.Util.Enum{
    "Dungeon",
    "Raid"
};