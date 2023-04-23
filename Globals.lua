-- [[ Namespaces ]] --
local _, addon = ...;

function addon.GetPartialItemInfo(id)
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = GetItemInfo(id);
    local hex = select(4, GetItemQualityColor(itemQuality)); -- Error here the first time we open the window, data not yet available?
    local color = CreateColorFromHexString(hex);
    return itemTexture, color, itemName;
end

local function AddCharToSavedData(playerGUID)
    if not KrowiV_SavedData.Characters then
        KrowiV_SavedData.Characters = {};
    end

    local character = KrowiV_SavedData.Characters[playerGUID];
    local rules;
    if character then
        rules = character.Rules;
    end

    KrowiV_SavedData.Characters[playerGUID] = {
        Name = (UnitFullName("player")),
        Realm = (select(2, UnitFullName("player"))),
        Class = (select(2, UnitClass("player"))),
        Faction = (UnitFactionGroup("player")),
        Rules = rules or {}
    };
end

function addon.GetCurrentCharacter()
    local playerGUID = UnitGUID("player");
    if not KrowiV_SavedData.Characters or not KrowiV_SavedData.Characters[playerGUID] then
        AddCharToSavedData(playerGUID);
    end
    return KrowiV_SavedData.Characters[playerGUID], playerGUID;
end