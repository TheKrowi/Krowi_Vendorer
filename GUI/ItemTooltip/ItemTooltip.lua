-- [[ Namespaces ]] --
local _, addon = ...;
addon.GUI.ItemTooltip = {};
local tooltip = addon.GUI.ItemTooltip;
tooltip.Sections = {};
local sections = tooltip.Sections;

local CLOTH = 1
local LEATHER = 2
local MAIL = 3
local PLATE = 4
local COSMETIC = 5

local classArmorTypes = {
    ["DEATHKNIGHT"] = PLATE,
    ["DEMONHUNTER"] = LEATHER,
    ["DRUID"] = LEATHER,
    ["EVOKER"] = MAIL,
    ["HUNTER"] = MAIL,
    ["MAGE"] = CLOTH,
    ["MONK"] = LEATHER,
    ["PALADIN"] = PLATE,
    ["PRIEST"] = CLOTH,
    ["ROGUE"] = LEATHER,
    ["SHAMAN"] = MAIL,
    ["WARLOCK"] = CLOTH,
    ["WARRIOR"] = PLATE,
}

local characterArmorSubclassIdCached;
local function GetCharacterArmorSubclassId()
    characterArmorSubclassIdCached = characterArmorSubclassIdCached or classArmorTypes[select(2, UnitClass("player"))];
    return characterArmorSubclassIdCached;
end

local qualityCache, itemLevelCache;
local validations = {
    function(itemId) -- Item's quality is marked for auto sell
        local result = addon.Options.db.AutoSell.Quality[qualityCache + 1];
        local text = addon.L["Item Quality"] .. ": " .. (result and addon.L["checked"] or addon.L["not checked"]);
        return result, text;
    end,
    function(itemId) -- Item's item level is below the set item level for auto sell
        local result = itemLevelCache <= addon.Options.db.AutoSell.ItemLevel;
        local text = addon.L["Item Level"] .. " " .. (result and addon.L["Below"] or addon.L["Above"]) .. " " .. tostring(addon.Options.db.AutoSell.ItemLevel):SetColorYellow();
        return result, text;
    end,
    function(itemId)
        local characterArmorSubclassId = GetCharacterArmorSubclassId()
        local classId, subclassId  = select(6, GetItemInfoInstant(itemId));
        local result = classId ~= 4 or characterArmorSubclassId ~= subclassId;
        local text = addon.L["Item Wearable"] .. ": " .. (result and addon.L["no"] or addon.L["yes"]);
        return result, text;
    end
};

local function ProcessItem(tooltip, bag, slot)
    local itemLink = C_Container.GetContainerItemLink(bag, slot);
    if not itemLink then
        return;
    end

    local itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
    itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
    expacID, setID, isCraftingReagent = GetItemInfo(itemLink);
    -- classID, subclassID return numerical values, 2 = weapon, sub is tye of weapon, try to link this to class
    local itemId = GetItemInfoInstant(itemLink);
    if not itemId or not itemQuality or not itemLevel then
        return;
    end
    qualityCache = itemQuality;
    itemLevel = GetDetailedItemLevelInfo(itemLink) or itemLevel;
    itemLevelCache = itemLevel;

    local results = {};
    local doSell;
    if addon.Options.db.AutoSell.Operator == 1 then
        doSell = true;
    elseif addon.Options.db.AutoSell.Operator == 2 then
        doSell = false;
    end
    for i, validation in next, validations do
        local result, text = validation(itemId);
        if addon.Options.db.AutoSell.Operator == 1 then
            doSell = doSell and result;
        elseif addon.Options.db.AutoSell.Operator == 2 then
            doSell = doSell or result;
        end
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