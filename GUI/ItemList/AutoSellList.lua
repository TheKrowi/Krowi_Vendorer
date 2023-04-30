-- [[ Namespaces ]] --
local _, addon = ...;
local itemListFrame = addon.GUI.ItemListFrame;
itemListFrame.AutoSellList = {};
local autoSellList = itemListFrame.AutoSellList;
local frame = KrowiV_SingleItemListFrame;
local autoSell = addon.Data.AutoSell;

function autoSellList:Init()
    frame:SetScript("OnEvent", self.OnEvent);
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

    if autoSell.CheckRules(itemInfo) then
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
    local totalNumItems = maxNumItems or #items;
    for i = #items, 1, -1 do
        local item = items[i];
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
                    y = totalNumItems
                });
            end
            return;
        end
        coroutine.yield();
    end

    if addon.Options.db.AutoSell.PrintChatMessage then
        if maxNumItems then
            print(addon.L["x of y items sold in safe mode"]:ReplaceVars{
                x = numItems,
                y = totalNumItems
            });
        else
            print(addon.L["x of y items sold"]:ReplaceVars{
                x = numItems,
                y = totalNumItems
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
        -- Update Ignore List here
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