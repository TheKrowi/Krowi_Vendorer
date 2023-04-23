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

local function PopulateListFrame()
    for bag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot);
            if itemLink then
                local itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
                itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
                expacID, setID, isCraftingReagent = GetItemInfo(itemLink);

                local itemId = GetItemInfoInstant(itemLink);
                if not itemId or not itemQuality or not itemLevel then
                    return;
                end
                itemLevel = GetDetailedItemLevelInfo(itemLink) or itemLevel;

                local itemInfo = {
                    ItemLevel = itemLevel,
                    ItemTypeId = classID,
                    ItemSubTypeId = subclassID,
                    BindType = bindType,
                    Quality = itemQuality
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
                    local icon, color, name = addon.GetPartialItemInfo(itemLink);
                    frame:AppendListItem(itemLink, icon, color, name, nil, bag, slot);
                end
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
            print(addon.L["Selling item"]:ReplaceVars(item.Link));
            C_Container.UseContainerItem(item.Bag, item.Slot);
            numItems = numItems + 1;
            frame:RemoveListItem(item);
            if maxNumItems and numItems >= maxNumItems then
                print(addon.L["x of y items sold in safe mode"]:ReplaceVars{
                    x = numItems,
                    y = maxNumItems
                });
                return;
            end
            coroutine.yield();
        end
    end
    if maxNumItems then
        print(addon.L["x of y items sold in safe mode"]:ReplaceVars{
            x = numItems,
            y = maxNumItems
        });
    else
        print(addon.L["x of y items sold"]:ReplaceVars{
            x = numItems,
            y = maxNumItems
        });
    end
    co = nil;
end

function autoSellList:Show()
    frame:ClearAllPoints();
    frame:SetParent(MerchantFrame);
    frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0);
    frame:SetPoint("BOTTOM");
    frame:SetTitle(addon.L["Auto Sell List"]);
    frame:SetIcon("Interface/Icons/Inv_Gizmo_03");
    frame:SetListInfo(addon.L["These items will be auto sold."]);
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
        if co ~= nil then
            coroutine.resume(co);
        else
            autoSellList.Update();
        end
    end
end