-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;
objects.CriteriaType = {};
local criteriaType = objects.CriteriaType;

criteriaType.List = {
    addon.L["Item level"],
    addon.L["Soulbound"]
};

criteriaType.Enum = addon.Util.Enum2{
    "ItemLevel",
    "Soulbound"
};