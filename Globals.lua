-- [[ Namespaces ]] --
local _, addon = ...;

function addon.GetPartialItemInfo(id)
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = GetItemInfo(id);
    local hex = select(4, GetItemQualityColor(itemQuality));
    local color = CreateColorFromHexString(hex);
    return itemTexture, color, itemName;
end

addon.Operators = {
    "<",
    "<=",
    "==",
    ">=",
    ">"
};

addon.OperatorsEnum = addon.Util.Enum2{
    "<",
    "<=",
    "==",
    ">=",
    ">"
};

addon.Operators = {
    "<",
    "<=",
    "==",
    ">=",
    ">"
};

addon.CriteriaType = {
    addon.L["Item level"],
    addon.L["Soulbound"]
};

addon.CriteriaTypeEnum = addon.Util.Enum2{
    "ItemLevel",
    "Soulbound"
};

addon.ItemClass = tInvert(Enum.ItemClass);
local obsoleteIds = {5, 6, 10, 11, 13, 14};
for _, id in next, obsoleteIds do
    addon.ItemClass[id] = nil;
end
for id, _ in next, addon.ItemClass do
    addon.ItemClass[id] = GetItemClassInfo(id);
end