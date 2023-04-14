-- [[ Namespaces ]] --
local _, addon = ...;

function addon.GetPartialItemInfo(id)
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = GetItemInfo(id);
    local hex = select(4, GetItemQualityColor(itemQuality)); -- Error here the first time we open the window, data not yet available?
    local color = CreateColorFromHexString(hex);
    return itemTexture, color, itemName;
end