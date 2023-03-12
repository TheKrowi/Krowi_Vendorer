-- [[ Namespaces ]] --
local addonName, addon = ...;
addon.Data.AutoSell = {};
local autoSell = addon.Data.AutoSell;

local qualityCache;
local validations = {
    function(itemId) return KrowiV_SavedData.IgnoredItems[itemId] end,
    function(itemId) return not qualityCache or not addon.Options.db.AutoJunk.Quality[qualityCache + 1] end
};

local cachedInstanceId;
local function AddToJunkIfComply(loot)
    if not loot then -- Other than gold
        return 1;
    end

    local itemId = GetItemInfoInstant(loot);
    if not itemId then
        return 2;
    end

    local quality = (select(3, GetItemInfo(itemId)));
    qualityCache = quality;
    for i, validation in next, validations do
        if validation(itemId) then -- If true, DO NOT mark item as junk
            return 2 + i; -- Osset from the hardcoded ones
        end
    end

    print("I should junk this", itemId, loot);
    KrowiV_SavedData.JunkItems[itemId] = cachedInstanceId;
    return -1;
end
