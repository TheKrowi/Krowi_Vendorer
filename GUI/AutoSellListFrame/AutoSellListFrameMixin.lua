-- [[ Namespaces ]] --
local _, addon = ...;
local autoSell = addon.Data.AutoSell;
local frame;

KrowiV_AutoSellListFrameMixin = {};

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

function KrowiV_AutoSellListFrameMixin:OnLoad()
    frame = self;
    self:SetScript("OnEvent", self.OnEvent);
    self:SetTitle(addon.L["Auto Sell List"]);
    self:SetIcon("Interface/Icons/Inv_Gizmo_03");
    self:SetListInfo(addon.L["Auto Sell List Info"]);
    self.Button1:SetText(addon.L["Sell All Items"]);
    self.Button1:SetScript("OnClick", function()
        maxNumItems = nil;
        co = coroutine.create(SellItems);
        coroutine.resume(co);
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
        maxNumItems = 12;
        co = coroutine.create(SellItems);
        coroutine.resume(co);
    end);
end

function KrowiV_AutoSellListFrameMixin:OnEvent(event, arg1, arg2)
    if event == "BAG_UPDATE" then
        -- print("BAG_UPDATE")
        if co ~= nil then
            coroutine.resume(co);
        else
            addon.Util.DelayFunction("MerchantFrame_UpdateBuybackInfo", 0.1, self.Update, self);
        end
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