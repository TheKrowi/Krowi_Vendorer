-- [[ Namespaces ]] --
local _, addon = ...;
addon.Data.AutoSell = {};
local autoSell = addon.Data.AutoSell;
local criteriaType = addon.Objects.CriteriaType;

function autoSell.CheckRule(rule, itemInfo)
    if rule.IsDisabled or rule.IsInvalid then
        return false;
    end

    -- If there are item types, either the type must match or when defined, also the sub type must match
    if rule.QuickItemTypes then
        local itemType = rule.QuickItemTypes[itemInfo.ItemTypeId];
        if not itemType then
            return false;
        end

        if type(itemType) == "table" and not itemType[itemInfo.ItemSubTypeId] then
            return false;
        end
    end

    -- If there are conditions, all conditions must match
    if rule.Conditions then
        for _, condition in next, rule.Conditions do
            local result = criteriaType.Func(condition, itemInfo);
            if not result then
                return false;
            end
        end
    end

    return true;
end

function autoSell.CheckRules(itemInfo)
    for _, rule in next, KrowiV_SavedData.Rules do
        if autoSell.CheckRule(rule, itemInfo) then
            return true;
        end
    end
    local character = addon.GetCurrentCharacter();
    for _, rule in next, character.Rules do
        if autoSell.CheckRule(rule, itemInfo) then
            return true;
        end
    end
end