-- [[ Namespaces ]] --
local _, addon = ...;
local itemListFrame = addon.GUI.ItemListFrame;
local dualItemListSide = addon.Objects.DualItemListSide;
itemListFrame.IgnoreList = {};
local ignoreList = itemListFrame.IgnoreList;
local frame;

-- function ignoreList.Init()
--     KrowiV_SavedData = KrowiV_SavedData or {};
--     KrowiV_SavedData.IgnoredItems = KrowiV_SavedData.IgnoredItems or {};
--     KrowiV_SavedData.JunkItems = KrowiV_SavedData.JunkItems or {};
-- end

local function LeftItemOnClick(self)
    KrowiV_SavedData.IgnoredItems[(GetItemInfoInstant(self.ElementData.Link))] = true;
    KrowiV_SavedData.JunkItems[(GetItemInfoInstant(self.ElementData.Link))] = nil;
    itemListFrame.LeftItemOnClick(self, frame);
    -- addon.GUI.ItemListFrame.JunkList.Update();
    KrowiV_AutoSellListFrame:Update();
end

local function RightItemOnClick(self)
    KrowiV_SavedData.IgnoredItems[(GetItemInfoInstant(self.ElementData.Link))] = nil;
    itemListFrame.RightItemOnClick(self, frame);
    -- addon.GUI.ItemListFrame.JunkList.Update();
    KrowiV_AutoSellListFrame:Update();
end

local function PopulateLeftListFrame()
    for bag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = Item:CreateFromBagAndSlot(bag, slot);
            if not item:IsItemEmpty() then
                item:ContinueOnItemLoad(function()
                    local itemId = item:GetItemID();
                    if KrowiV_SavedData.IgnoredItems[itemId] then
                        return;
                    end
                    local link = item:GetItemLink();
                    local icon = item:GetItemIcon();
                    local color = item:GetItemQualityColor();
                    local name = item:GetItemName();
                    frame:AppendListItem(dualItemListSide.Left, link, icon, color.color, name, nil, bag, slot);
                end);
            end
        end
    end
end

local function PopulateRightListFrame()
    for itemId, _ in next, KrowiV_SavedData.IgnoredItems do
        local item = Item:CreateFromItemID(itemId);
        item:ContinueOnItemLoad(function()
            local link = item:GetItemLink();
            local icon = item:GetItemIcon();
            local color = item:GetItemQualityColor();
            local name = item:GetItemName();
            frame:AppendListItem(dualItemListSide.Right, link, icon, color.color, name);
        end);
    end
end

function ignoreList:Show(isEmbedded)
    self.IsEmbedded = isEmbedded;
    if isEmbedded then
        frame = KrowiV_EmbeddedIgnoreListFrame;
    else
        frame = KrowiV_IgnoreListFrame;
        frame:ClearAllPoints();
        frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0);
        frame:SetHeight(MerchantFrame:GetHeight());
        frame:SetTitle(addon.L["Ignore List"]);
        frame:SetIcon("Interface/Icons/Inv_Shield_1h_NewPlayer_a_02");
        frame:SetListInfo(dualItemListSide.Left, addon.L["Left-click an item to add it to the ignore list."]);
        frame:SetListInfo(dualItemListSide.Right, addon.L["Right-click an item to remove it from the ignore list."]);
    end
    frame:ClearListItems(dualItemListSide.Left);
    frame:RegisterListItemsForClicks(dualItemListSide.Left, "LeftButtonUp");
    frame:SetListItemsOnClick(dualItemListSide.Left, LeftItemOnClick);
    frame:ClearListItems(dualItemListSide.Right);
    frame:RegisterListItemsForClicks(dualItemListSide.Right, "RightButtonUp");
    frame:SetListItemsOnClick(dualItemListSide.Right, RightItemOnClick);
    PopulateLeftListFrame();
    PopulateRightListFrame();
    frame:Show();
end

function ignoreList:Hide()
    if self.IsEmbedded then
        frame:Hide();
    end
end

function ignoreList.Update()
    if not frame or not frame:IsShown() then
        return;
    end
    frame:ClearListItems();
    PopulateLeftListFrame();
    PopulateRightListFrame();
end