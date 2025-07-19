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

function TriggerSellRound()
    if #itemsToSell == 0 or itemsSoldCount >= maxItemsToSell then
        sellingLoopInProgress = false;
        if addon.Options.db.profile.AutoSell.PrintChatMessage then
            print(addon.L["x of y items sold"]:K_ReplaceVars{
                x = itemsSoldCount,
                y = maxItemsToSell
            });
        end
        return;
    end

    for i = 1, math.min(itemsToSellPerRound, #itemsToSell) do
        local item = itemsToSell[i];
        local info = C_Container.GetContainerItemInfo(item.Bag, item.Slot);
        -- print(item.Link, info and info.hyperlink == item.Link, info and not info.isLocked)
        if info and info.hyperlink == item.Link and not info.isLocked then
            C_Container.UseContainerItem(item.Bag, item.Slot);
        -- elseif info and info.isLocked and addon.Options.db.profile.AutoSell.PrintChatMessage then
        --     print("Item busy, deferring: " .. item.Link)
        end
    end

    -- Add delayed check just in case event doesn't arrive
    C_Timer.After(0.2, function()
        ProcessSold("FORCED_CHECK");
    end)
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

function ProcessSold(event)
    -- print(event, " - Checking items to sell...");
    local remaining = {};
    local processCount = math.min(itemsToSellPerRound, #itemsToSell);
    for i = 1, processCount do
        local item = itemsToSell[i];
        if item then
            local info = C_Container.GetContainerItemInfo(item.Bag, item.Slot);
            local isGone = not info or info.hyperlink ~= item.Link;
            local isBusy = info and info.isLocked;

            if isGone then
                frame:RemoveListItem(item);
                itemsSoldCount = itemsSoldCount + 1;
                if addon.Options.db.profile.AutoSell.PrintChatMessage then
                    print(addon.L["Sold item"]:K_ReplaceVars(item.Link))
                end
            else
                table.insert(remaining, item);
                if isBusy and addon.Options.db.profile.AutoSell.PrintChatMessage then
                    print("Skipping busy item: " .. item.Link);
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
        ProcessSold(event);
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
        frame:AppendListItem(link, icon, color.color, name, nil, bag, slot);
        return;
    end

    local itemInfo = addon.GetItemInfo(bag, slot, item);

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

local function ItemOnClick(self, button)
    if button == "LeftButton" then -- Sell item
        C_Container.UseContainerItem(self.ElementData.Bag, self.ElementData.Slot);
        frame:RemoveListItem(self.ElementData);
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