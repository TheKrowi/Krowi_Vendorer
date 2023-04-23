-- [[ Namespaces ]] --
local _, addon = ...;

function addon.GetPartialItemInfo(id)
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = GetItemInfo(id);
    local hex = select(4, GetItemQualityColor(itemQuality)); -- Error here the first time we open the window, data not yet available?
    local color = CreateColorFromHexString(hex);
    return itemTexture, color, itemName;
end

function addon.AddCharToSavedData()
    if not KrowiV_SavedData.Characters then
        KrowiV_SavedData.Characters = {};
    end
    -- local character = KrowiV_SavedData.Characters[playerGUID];
    -- local excludeFromHeaderTooltip, excludeFromEarnedByAchievementTooltip, excludeFromMostProgressAchievementTooltip, ignore;
    -- if character then
    --     excludeFromHeaderTooltip = character.ExcludeFromHeaderTooltip;
    --     excludeFromEarnedByAchievementTooltip = character.ExcludeFromEarnedByAchievementTooltip;
    --     excludeFromMostProgressAchievementTooltip = character.ExcludeFromMostProgressAchievementTooltip;
    --     ignore = character.Ignore;
    -- end

    local playerGUID = UnitGUID("player");
    KrowiV_SavedData.Characters[playerGUID] = {
        Name = (UnitFullName("player")),
        Realm = (select(2, UnitFullName("player"))),
        Class = (select(2, UnitClass("player"))),
        Faction = (UnitFactionGroup("player")),
        -- CompletedAchievements = {},
        -- NotCompletedAchievements = {},
        -- ExcludeFromHeaderTooltip = excludeFromHeaderTooltip,
        -- ExcludeFromEarnedByAchievementTooltip = excludeFromEarnedByAchievementTooltip,
        -- ExcludeFromMostProgressAchievementTooltip = excludeFromMostProgressAchievementTooltip,
        -- Ignore = ignore
    };
end

function addon.GetCurrentCharacter()
    local playerGUID = UnitGUID("player");
    if not KrowiV_SavedData.Characters[playerGUID] then
        addon.AddCharToSavedData();
    end
    return KrowiV_SavedData.Characters[playerGUID];
end