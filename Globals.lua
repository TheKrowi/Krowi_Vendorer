-- [[ Namespaces ]] --
local _, addon = ...;

function addon.GetPartialItemInfo(id)
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = GetItemInfo(id);
    local hex = select(4, GetItemQualityColor(itemQuality));
    local color = CreateColorFromHexString(hex);
    return itemTexture, color, itemName;
end

addon.Operators = {
    addon.L["and"],
    addon.L["or"]
};