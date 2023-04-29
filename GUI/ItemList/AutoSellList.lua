-- [[ Namespaces ]] --
local _, addon = ...;
local itemListFrame = addon.GUI.ItemListFrame;
itemListFrame.AutoSellList = {};
local autoSellList = itemListFrame.AutoSellList;
local frame = KrowiV_SingleItemListFrame;
local criteriaType = addon.Objects.CriteriaType;

function autoSellList:Init()
    frame:SetScript("OnEvent", self.OnEvent);
end

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
    if not rule.IsEnabled then
        doSell = doSell or false;
        return doSell, results;
    end
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

local function ProcessItem(bag, slot, item)
    local itemId = item:GetItemID();
    if KrowiV_SavedData.IgnoredItems[itemId] then
        return;
    end

    local link = item:GetItemLink();
    if KrowiV_SavedData.JunkItems[itemId] then
        local icon = item:GetItemIcon();
        local color = item:GetItemQualityColor();
        local name = item:GetItemName();
        frame:AppendListItem(link, icon, color.color, name, nil, bag, slot);
        return;
    end

    local classID, subclassID, bindType = select(12, GetItemInfo(link));
    local itemInfo = {
        Bag = bag,
        Slot = slot,
        ItemLevel = item:GetCurrentItemLevel(),
        ItemTypeId = classID,
        ItemSubTypeId = subclassID,
        BindType = bindType,
        Quality = item:GetItemQuality()
    };

    local doSell, results = false, {};
    for _, rule in next, KrowiV_SavedData.Rules do
        if rule.IsValid then
            doSell, results = CheckRule(doSell, results, rule, itemInfo);
        end
    end
    local character = addon.GetCurrentCharacter();
    for _, rule in next, character.Rules do
        if rule.IsValid then
            doSell, results = CheckRule(doSell, results, rule, itemInfo);
        end
    end

    if doSell then
        local icon = item:GetItemIcon();
        local color = item:GetItemQualityColor();
        local name = item:GetItemName();
        frame:AppendListItem(link, icon, color.color, name, nil, bag, slot);
    end
end

local function PopulateListFrame()
    for bag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = Item:CreateFromBagAndSlot(bag, slot);
            if not item:IsItemEmpty() then
                item:ContinueOnItemLoad(function()
                    ProcessItem(bag, slot, item);
                end);
            end
        end
    end
end

local co, maxNumItems;
local function SellItems()
    local numItems = 0;
    local items = frame:GetItems();
    for i = #items, 1, -1 do
        local item = items[i];
        if item.Bag and item.Slot then
            if addon.Options.db.AutoSell.PrintChatMessage then
                print(addon.L["Selling item"]:ReplaceVars(item.Link));
            end
            C_Container.UseContainerItem(item.Bag, item.Slot);
            numItems = numItems + 1;
            frame:RemoveListItem(item);
            if maxNumItems and numItems >= maxNumItems then
                if addon.Options.db.AutoSell.PrintChatMessage then
                    print(addon.L["x of y items sold in safe mode"]:ReplaceVars{
                        x = numItems,
                        y = maxNumItems
                    });
                end
                return;
            end
            coroutine.yield();
        end
    end
    if addon.Options.db.AutoSell.PrintChatMessage then
        if maxNumItems then
            print(addon.L["x of y items sold in safe mode"]:ReplaceVars{
                x = numItems,
                y = maxNumItems
            });
        else
            print(addon.L["x of y items sold"]:ReplaceVars{
                x = numItems,
                y = #items
            });
        end
    end
    co = nil;
end

local function ItemOnClick(self, button)
    if button == "LeftButton" then -- Sell item
        C_Container.UseContainerItem(self.ElementData.Bag, self.ElementData.Slot);
        frame:RemoveListItem(self.ElementData);
    elseif button == "RightButton" then -- Ignore item
        KrowiV_SavedData.IgnoredItems[(GetItemInfoInstant(self.ElementData.Link))] = true;
        KrowiV_SavedData.JunkItems[(GetItemInfoInstant(self.ElementData.Link))] = nil;
        frame:RemoveListItem(self.ElementData);
    end
end

function autoSellList:Show()
    frame:ClearAllPoints();
    frame:SetParent(MerchantFrame);
    frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0);
    frame:SetPoint("BOTTOM");
    frame:SetTitle(addon.L["Auto Sell List"]);
    frame:SetIcon("Interface/Icons/Inv_Gizmo_03");
    frame:SetListInfo(addon.L["Auto Sell List Info"]);
    frame.Button1:SetText(addon.L["Sell All Items"]);
    frame.Button1:Show();
    frame.Button1:SetScript("OnClick", function()
        maxNumItems = nil;
        co = coroutine.create(SellItems);
        coroutine.resume(co);
    end);
    frame.Button2:SetText(addon.L["Sell 12 Items"]);
    frame.Button2:Show();
    frame.Button2:SetScript("OnClick", function()
        maxNumItems = 12;
        co = coroutine.create(SellItems);
        coroutine.resume(co);
    end);
    frame:RegisterEvent("BAG_UPDATE");
    frame:RegisterListItemsForClicks("LeftButtonUp", "RightButtonUp");
    frame:SetListItemsOnClick(ItemOnClick);
    frame:Show();
    self.Update();
end

function autoSellList:ShowStandalone()
    frame:ClearAllPoints();
    frame:SetParent(SettingsPanel);
    frame:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 10, 0);
    frame:SetPoint("BOTTOM");
    frame:SetTitle(addon.L["Auto Sell List"]);
    frame:SetIcon("Interface/Icons/Inv_Gizmo_03");
    frame:SetListInfo(addon.L["Auto Sell List Info"]);
    frame:Show();
    self.Update();
end

function autoSellList.Hide()
    frame:UnregisterEvent("BAG_UPDATE");
    frame:Hide();
end

function autoSellList.Update()
    if not frame:IsShown() then
        return;
    end
    frame:ClearListItems();
    PopulateListFrame();
end

function autoSellList:OnEvent(event, arg1, arg2)
    if event == "BAG_UPDATE" then
        -- print("BAG_UPDATE")
        if co ~= nil then
            coroutine.resume(co);
        else
            autoSellList.Update();
        end
    end
end