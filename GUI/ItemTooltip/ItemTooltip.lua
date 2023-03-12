-- [[ Namespaces ]] --
local _, addon = ...;
addon.GUI.ItemTooltip = {};
local tooltip = addon.GUI.ItemTooltip;
tooltip.Sections = {};
local sections = tooltip.Sections;

local qualityCache, itemLevelCache;
local validations = {
    function(itemId)
        local result = addon.Options.db.AutoSell.Quality[qualityCache + 1];
        local text = addon.L["Item Quality"] .. ": " .. (result and addon.L["checked"] or addon.L["not checked"]);
        return result, text;
    end,
    function(itemId)
        local result = itemLevelCache <= addon.Options.db.AutoSell.ItemLevel;
        local text = addon.L["Item Level"] .. " " .. (result and addon.L["Below"] or addon.L["Above"]) .. " " .. tostring(addon.Options.db.AutoSell.ItemLevel):SetColorYellow();
        return result, text;
    end
};

local function ProcessItem(tooltip, bag, slot)
    local itemLink = C_Container.GetContainerItemLink(bag, slot);
    if not itemLink then
        return;
    end

    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
    itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
    expacID, setID, isCraftingReagent = GetItemInfo(itemLink);
    local itemId = GetItemInfoInstant(itemLink);
    qualityCache = itemQuality;
    itemLevel = GetDetailedItemLevelInfo(itemLink) or itemLevel;
    itemLevelCache = itemLevel;

    local results = {};
    local doSell;
    if addon.Options.db.AutoSell.Operator == "and" then
        doSell = true;
    elseif addon.Options.db.AutoSell.Operator == "or" then
        doSell = false;
    end
    for i, validation in next, validations do
        local result, text = validation(itemId);
        doSell = doSell and result;
        tinsert(results, {result, text});
    end

    GameTooltip_AddBlankLinesToTooltip(tooltip, 1);
    tooltip:AddLine(addon.MetaData.Title);
    tooltip:AddLine(doSell and addon.L["This item is junk"]:SetColorLightRed() or addon.L["This item is not junk"]:SetColorLightGreen());
    for i, r in next, results do
        local result, text = unpack(r);
        tooltip:AddLine(result and text:SetColorLightRed() or text:SetColorLightGreen());
    end

    tooltip:Show();
end

-- local function ProcessItem100002(tooltip, localData)
--     ProcessItem(tooltip, localData.id);

--     -- for i, v in next, localData do
--     --     print(i, v)
--     -- end
-- end

function tooltip.Load()
    -- TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ProcessItem100002);

    hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
        ProcessItem(self, bag, slot);
    end);
end