-- [[ Namespaces ]] --
local _, addon = ...;
local autoSell = addon.Data.AutoSell;
local frame;

KrowiV_AutoSellListFrameMixin = {};

local sellingLoopInProgress = false;
local itemsToSell = {};
local maxItemsToSell = nil;
local itemsSoldCount = 0;
local itemsToSellPerRound = 5; -- Number of items to sell per round
local itemRetryCounts = {};
local DestroyQueue = {}; -- Holds items awaiting destruction
local DestroyInProgress = false;

function StartEventDrivenSellLoop(maxNumItems)
    if sellingLoopInProgress then
        print(addon.L["Selling in progress"]);
        return;
    end

    print(addon.L["Selling started"]);
    sellingLoopInProgress = true;
    itemsToSell = frame:GetItems();
    maxItemsToSell = maxNumItems or #itemsToSell;
    itemsSoldCount = 0;

    TriggerSellRound();
end

StaticPopupDialogs["CONFIRM_DESTROY_ITEM"] = {
    text = "Do you want to destroy %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self)
        if CursorHasItem() then
            print("Cannot destroy item while another item is on the cursor. Please clear your hands first.");
            table.insert(DestroyQueue, self.data);
            DestroyInProgress = false;
            ProcessDestroyQueue();
            return;
        end
        C_Container.PickupContainerItem(self.data.Bag, self.data.Slot);
        DeleteCursorItem();
        DestroyInProgress = false;
        ProcessDestroyQueue(); -- Move to next item
    end,
    OnCancel = function()
        DestroyInProgress = false;
        ProcessDestroyQueue(); -- Move to next item anyway
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
};

function ProcessDestroyQueue()
    if DestroyInProgress or #DestroyQueue == 0 then return end;

    DestroyInProgress = true;
    local item = table.remove(DestroyQueue, 1);

    StaticPopup_Show("CONFIRM_DESTROY_ITEM", item.Name, nil, item);
end

function TriggerSellRound()
    if #itemsToSell == 0 or itemsSoldCount >= maxItemsToSell then
        sellingLoopInProgress = false;
        if addon.Options.db.profile.AutoSell.PrintChatMessage then
            print(addon.L["x of y items sold"]:K_ReplaceVars{
                x = itemsSoldCount,
                y = maxItemsToSell
            });
        end
        itemRetryCounts = {};
        return;
    end

    for i = 1, math.min(itemsToSellPerRound, #itemsToSell) do
        local item = itemsToSell[i];
        local info = C_Container.GetContainerItemInfo(item.Bag, item.Slot);
        -- print(item.Link, info and info.hyperlink == item.Link, info and not info.isLocked)
        if not item.IsSellable then
            table.insert(DestroyQueue, item);
            ProcessDestroyQueue();
        end
        if item.IsSellable and info and info.hyperlink == item.Link and not info.isLocked then
            C_Container.UseContainerItem(item.Bag, item.Slot);
        -- elseif info and info.isLocked and addon.Options.db.profile.AutoSell.PrintChatMessage then
        --     print("Item busy, deferring: " .. item.Link)
        end
    end

    -- Add delayed check just in case event doesn't arrive
    C_Timer.After(0.2, function()
        EvaluateSellRound("FORCED_CHECK");
    end);
end

function KrowiV_AutoSellListFrameMixin:OnLoad()
    frame = self;
    self:SetScript("OnEvent", self.OnEvent);
    self:SetTitle(addon.L["Auto Sell List"]);
    self:SetIcon("Interface/Icons/Inv_Gizmo_03");
    self:SetListInfo(addon.L["Auto Sell List Info"]);
    self.Button1:SetText(addon.L["Sell All Items"]);
    self.Button1:SetScript("OnClick", function()
        -- StartSellingThreads(5);
        StartEventDrivenSellLoop();
    end);
    self.Button1:SetScript("OnEnter", function(selfFunc)
        GameTooltip:SetOwner(selfFunc, "ANCHOR_RIGHT");
        GameTooltip:AddLine("Click: Sell all items");
        GameTooltip:AddLine("Shift-Click: Sell max 12 items (safe mode)");
        GameTooltip:AddLine("Lines to show the number of currencies this will give you");
        GameTooltip:Show();
    end);
    self.Button2:SetText(addon.L["Sell 12 Items"]);
    self.Button2:SetScript("OnClick", function()
        StartEventDrivenSellLoop(12);
    end);
end

function EvaluateSellRound(event)
    -- print(event, " - Checking items to sell...");
    local remaining = {};
    local processCount = math.min(itemsToSellPerRound, #itemsToSell);
    for i = 1, processCount do
        local item = itemsToSell[i];
        if item then
            local info = C_Container.GetContainerItemInfo(item.Bag, item.Slot);
            local isGone = not info or info.hyperlink ~= item.Link;
            local isBusy = info and info.isLocked;
            local id = item.Link;

            itemRetryCounts[id] = itemRetryCounts[id] or 0;

            if isGone then
                frame:RemoveListItem(item);
                itemsSoldCount = itemsSoldCount + 1;
                itemRetryCounts[id] = nil;
                if addon.Options.db.profile.AutoSell.PrintChatMessage then
                    print(addon.L["Sold item"]:K_ReplaceVars(item.Link))
                end
            elseif not item.IsSellable then
                if addon.Options.db.profile.AutoSell.PrintChatMessage then
                    print("Skipping unsellable item: " .. item.Link);
                end
            elseif itemRetryCounts[id] >= 10 then
                if addon.Options.db.profile.AutoSell.PrintChatMessage then
                    print("Skipping permanently after 10 failed attempts: " .. item.Link);
                end
            else
                itemRetryCounts[id] = itemRetryCounts[id] + 1;
                table.insert(remaining, item);
                if isBusy and addon.Options.db.profile.AutoSell.PrintChatMessage then
                    print("Retry " .. itemRetryCounts[id] .. " for busy item: " .. item.Link);
                end
            end
        end
    end

    for i = processCount + 1, #itemsToSell do
        table.insert(remaining, itemsToSell[i]);
    end
    itemsToSell = remaining;
    TriggerSellRound();
end

function KrowiV_AutoSellListFrameMixin:OnEvent(event, arg1, arg2)
    if event == "BAG_UPDATE" then
        addon.Util.DelayFunction("MerchantFrame_UpdateBuybackInfo", 0.1, self.Update, self);
    elseif (event == "BAG_UPDATE_DELAYED" or event == "FORCED_CHECK") and sellingLoopInProgress then
        EvaluateSellRound(event);
    end
end

function KrowiV_AutoSellListFrameMixin:OnShow()
    self:RegisterEvent("BAG_UPDATE");
    self:Update();
end

function KrowiV_AutoSellListFrameMixin:OnHide()
    self:UnregisterEvent("BAG_UPDATE");
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
        local sellPrice = select(11, GetItemInfo(itemId));
        frame:AppendListItem(link, icon, color.color, name, nil, bag, slot, sellPrice ~= 0);
        return;
    end

    local itemInfo = addon.GetItemInfo(bag, slot, item);

    if autoSell.CheckRules(itemInfo) then
        local icon = item:GetItemIcon();
        local color = item:GetItemQualityColor();
        local name = item:GetItemName();
        local sellPrice = select(11, GetItemInfo(itemId));
        frame:AppendListItem(link, icon, color.color, name, nil, bag, slot, sellPrice ~= 0);
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

local function ItemOnClick(self, button)
    if button == "LeftButton" then -- Sell item
        C_Container.UseContainerItem(self.ElementData.Bag, self.ElementData.Slot);
        if self.ElementData.IsSellable then
            frame:RemoveListItem(self.ElementData);
        end
    elseif button == "RightButton" then -- Ignore item
        KrowiV_SavedData.IgnoredItems[(GetItemInfoInstant(self.ElementData.Link))] = true;
        KrowiV_SavedData.JunkItems[(GetItemInfoInstant(self.ElementData.Link))] = nil;
        frame:RemoveListItem(self.ElementData);
        KrowiV_EmbeddedIgnoreListFrame:Update();
        KrowiV_EmbeddedJunkListFrame:Update();
        -- Update Ignore List here
    end
end

function KrowiV_AutoSellListFrameMixin:ShowWithMerchantFrame()
    self:ClearAllPoints();
    self:SetParent(MerchantFrame);
    self:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0);
    self:SetPoint("BOTTOM");
    self.Button1:Show();
    self.Button2:Show();
    self:RegisterListItemsForClicks("LeftButtonUp", "RightButtonUp");
    self:SetListItemsOnClick(ItemOnClick);
    self:Show();
end

function KrowiV_AutoSellListFrameMixin:ShowWithSettingsPanel()
    self:ClearAllPoints();
    self:SetParent(SettingsPanel);
    self:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 10, 0);
    self:SetPoint("BOTTOM");
    self:Show();
end

function KrowiV_AutoSellListFrameMixin:Update()
    if not self:IsShown() then
        return;
    end
    self:ClearListItems();
    PopulateListFrame();
end