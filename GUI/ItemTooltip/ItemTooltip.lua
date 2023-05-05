-- [[ Namespaces ]] --
local _, addon = ...;
addon.GUI.ItemTooltip = {};
local tooltip = addon.GUI.ItemTooltip;
tooltip.Sections = {};
local sections = tooltip.Sections;

local criteriaType = addon.Objects.CriteriaType;
local equalityOperator = addon.Objects.EqualityOperator;
local autoSell = addon.Data.AutoSell;

-- local characterItemMatrixCached;
-- local function GetCharacterItemMatrix()
--     characterItemMatrixCached = characterItemMatrixCached or itemClassMatrix[select(2, UnitClass("player"))];
--     return characterItemMatrixCached;
-- end

-- local qualityCache, itemLevelCache;
-- local validations = {
--     function(itemId) -- Item's quality is marked for auto sell
--         local result = addon.Options.db.AutoSell.Quality[qualityCache + 1];
--         local text = addon.L["Item Quality"] .. ": " .. (result and addon.L["checked"] or addon.L["not checked"]);
--         return result, text;
--     end,
--     function(itemId) -- Item's item level is below the set item level for auto sell
--         local result = itemLevelCache <= addon.Options.db.AutoSell.ItemLevel;
--         local text = addon.L["Item Level"] .. " " .. (result and addon.L["Below"] or addon.L["Above"]) .. " " .. tostring(addon.Options.db.AutoSell.ItemLevel):SetColorYellow();
--         return result, text;
--     end,
--     function(itemId)
--         local characterItemMatrix = GetCharacterItemMatrix();
--         local classId, subclassId  = select(6, GetItemInfoInstant(itemId));
--         local itemClass = characterItemMatrix[classId];
--         local result = itemClass and not itemClass[subclassId];
--         print(classId, subclassId, itemClass and itemClass[subclassId])
--         local text = addon.L["Item Wearable"] .. ": " .. (result and addon.L["no"] or addon.L["yes"]);
--         return result, text;
--     end,
--     function(itemId) -- This one should overrule the rest so will need to get it out of this one
--         local classId, subclassId  = select(6, GetItemInfoInstant(itemId));
--         local result = classId == Enum.ItemClass.Gem and subclassId == Enum.ItemGemSubclass.Artifactrelic;
--         local text = addon.L["Artifact relic"] .. ": " .. (result and addon.L["yes"] or addon.L["no"]);
--         return result, text;
--     end
-- };

local function IsItemTypeInRule(rule, itemTypeId)
    for _, itemType in next, rule.ItemTypes do
        if itemType.Type == itemTypeId then
            return itemType;
        end
    end
end

local function IsItemSubTypeInRule(itemType, itemSubTypeId)
    if not itemType.CheckSubType then
        return true;
    end
    return itemType.SubTypes[itemSubTypeId];
end

local function CheckRule(doSell, results, rule, itemInfo)
    if #rule.ItemTypes > 0 then
        local itemType = IsItemTypeInRule(rule, itemInfo.ItemTypeId);
        if not itemType then
            doSell = doSell or false;
            return doSell, results;
        end

        if not IsItemSubTypeInRule(itemType, itemInfo.ItemSubTypeId) then
            doSell = doSell or false;
            return doSell, results;
        end
    end

    local ruleResults = {}
    local doSellRule = true;
    for _, condition in next, rule.Conditions do
        if condition.CriteriaType then
            local result, text = criteriaType.Func(condition, itemInfo);
            doSellRule = doSellRule and result;
            tinsert(ruleResults, {result, text});
        end
    end

    tinsert(results, {rule.Name, doSellRule, ruleResults});

    doSell = doSell or doSellRule;
    return doSell, results;
end

local function AddTableToTooltip(_tooltip, table)
    for key, value in pairs(table) do
        if type(value) == "table" then
            AddTableToTooltip(_tooltip, value)
        else
            _tooltip:AddDoubleLine(key, value);
        end
    end
end

local function ProcessItem(_tooltip, bag, slot, item)
    local link = item:GetItemLink();
    local classID, subclassID, bindType = select(12, GetItemInfo(link));
    local itemInfo = {
        Bag = bag,
        Slot = slot,
        Link = link,
        ItemLevel = item:GetCurrentItemLevel(),
        ItemTypeId = classID,
        ItemSubTypeId = subclassID,
        BindType = bindType,
        Quality = item:GetItemQuality(),
        InventoryType = item:GetInventoryType()
    };
    GameTooltip_AddBlankLinesToTooltip(_tooltip, 1);
    local feedback = autoSell.CheckRulesWithFeedback(itemInfo);
    AddTableToTooltip(_tooltip, feedback)

    local itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
    itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
    expacID, setID, isCraftingReagent = GetItemInfo(link);
    -- -- classID, subclassID return numerical values, 2 = weapon, sub is tye of weapon, try to link this to class
    -- local itemId = GetItemInfoInstant(link);
    -- if not itemId or not itemQuality or not itemLevel then
    --     return;
    -- end
    -- itemLevel = GetDetailedItemLevelInfo(link) or itemLevel;

    -- local itemInfo = {
    --     Bag = bag,
    --     Slot = slot,
    --     ItemLevel = itemLevel,
    --     ItemTypeId = classID,
    --     ItemSubTypeId = subclassID,
    --     BindType = bindType,
    --     Quality = itemQuality
    -- };

    -- local doSell, results = false, {};
    -- for _, rule in next, KrowiV_SavedData.Rules do
    --     if rule.IsValid then
    --         doSell, results = CheckRule(doSell, results, rule, itemInfo);
    --     end
    -- end

    -- GameTooltip_AddBlankLinesToTooltip(_tooltip, 1);
    -- _tooltip:AddLine(addon.MetaData.Title);
    -- _tooltip:AddLine(doSell and addon.L["This item is junk"]:SetColorLightRed() or addon.L["This item is not junk"]:SetColorLightGreen());
    -- for i, result in next, feedback do
    --     local ruleName, ruleResults = unpack(result);
    --     local ruleText = addon.L["TAB"] .. "- " .. ruleName;
    --     local doSellRule = false;
    --     _tooltip:AddLine(doSellRule and ruleText:SetColorLightRed() or ruleText:SetColorLightGreen());
    --     for _, _result in next, ruleResults do
    --         local conditionResult, text = unpack(_result);
    --         local conditionText = addon.L["TAB"] .. addon.L["TAB"] .. "- " .. text;
    --         _tooltip:AddLine(conditionResult and conditionText:SetColorLightRed() or conditionText:SetColorLightGreen());
    --     end
    -- end

    GameTooltip_AddBlankLinesToTooltip(_tooltip, 1);
    _tooltip:AddDoubleLine("itemName", itemName);
    _tooltip:AddDoubleLine("itemLink", link);
    _tooltip:AddDoubleLine("itemQuality", itemQuality);
    _tooltip:AddDoubleLine("itemLevel", itemLevel);
    _tooltip:AddDoubleLine("itemMinLevel", itemMinLevel);
    _tooltip:AddDoubleLine("itemType", itemType);
    _tooltip:AddDoubleLine("itemSubType", itemSubType);
    _tooltip:AddDoubleLine("itemStackCount", itemStackCount);
    _tooltip:AddDoubleLine("itemEquipLoc", itemEquipLoc);
    _tooltip:AddDoubleLine("itemTexture", itemTexture);
    _tooltip:AddDoubleLine("sellPrice", sellPrice);
    _tooltip:AddDoubleLine("classID", classID);
    _tooltip:AddDoubleLine("subclassID", subclassID);
    _tooltip:AddDoubleLine("bindType", bindType);
    _tooltip:AddDoubleLine("expacID", expacID);
    _tooltip:AddDoubleLine("setID", setID);
    _tooltip:AddDoubleLine("isCraftingReagent", isCraftingReagent);

    -- local playerKnowsTransmogFromItem, isValidAppearanceForCharacter, playerKnowsTransmog, characterCanLearnTransmog;
    -- local canIMogIt = CanIMogIt; --LibStub("AceAddon-3.0"):GetAddon("CanIMogIt");
    -- if canIMogIt then
    --     playerKnowsTransmogFromItem = canIMogIt:PlayerKnowsTransmogFromItem(itemLink);
    --     isValidAppearanceForCharacter = canIMogIt:IsValidAppearanceForCharacter(itemLink)
    --     playerKnowsTransmog = canIMogIt:PlayerKnowsTransmog(itemLink)
    --     characterCanLearnTransmog = canIMogIt:CharacterCanLearnTransmog(itemLink)
    -- end
    -- GameTooltip_AddBlankLinesToTooltip(_tooltip, 1);
    -- _tooltip:AddDoubleLine("CanIMogIt", canIMogIt and "yes" or "no");
    -- _tooltip:AddDoubleLine("playerKnowsTransmogFromItem", playerKnowsTransmogFromItem and "yes" or "no");
    -- _tooltip:AddDoubleLine("isValidAppearanceForCharacter", isValidAppearanceForCharacter and "yes" or "no");
    -- _tooltip:AddDoubleLine("playerKnowsTransmog", playerKnowsTransmog and "yes" or "no");
    -- _tooltip:AddDoubleLine("characterCanLearnTransmog", characterCanLearnTransmog and "yes" or "no");
    
    _tooltip:Show();
end

local function ProcessItem100002(tooltip, localData)
    if localData.guid and addon.Options.db.Tooltip.ShowAutoSellRules then
        local itemLocation = C_Item.GetItemLocation(localData.guid);
        if not itemLocation or not itemLocation:IsBagAndSlot() then
            return;
        end
        local bag, slot = itemLocation:GetBagAndSlot();
        local item = Item:CreateFromBagAndSlot(bag, slot);
        ProcessItem(tooltip, bag, slot, item);
    end
end

function tooltip.Load()
    if addon.IsDragonflightRetail then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ProcessItem100002);
        return;
    end

    -- -- Enable this again to show tooltip info
    -- hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
    --     if addon.Options.db.Tooltip.ShowAutoSellRules then
    --         ProcessItem(self, bag, slot);
    --     end
    -- end);
end