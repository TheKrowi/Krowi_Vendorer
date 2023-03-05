-- [[ Namespaces ]] --
local _, addon = ...;
local itemList = addon.ItemList;
local dualItemListSide = addon.Objects.DualItemListSide;
itemList.IgnoreListFrame = {};
local ignoreListFrame = itemList.IgnoreListFrame;

function ignoreListFrame.Init()
    KrowiV_SavedData = KrowiV_SavedData or {};
    KrowiV_SavedData.IgnoredItems = KrowiV_SavedData.IgnoredItems or {};
end

local function LeftJunkItemOnClick(self, button)
    KrowiV_SavedData.IgnoredItems[self.ElementData.Id] = true;
    itemList.LeftItemOnClick(self, button);
end

local function RightJunkItemOnClick(self, button)
    KrowiV_SavedData.IgnoredItems[self.ElementData.Id] = nil;
    itemList.RightItemOnClick(self, button);
end

local function PopulateLeftListFrame()
    for bag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemId = C_Container.GetContainerItemID(bag, slot);
            if itemId and not KrowiV_SavedData.IgnoredItems[itemId] then
                local icon, color, name = addon.GetPartialItemInfo(itemId);
                KrowiV_DualItemListFrame:AppendListItem(dualItemListSide.Left, itemId, icon, color, name);
            end
        end
    end
end

local function PopulateRightListFrame()
    for itemId, _ in next, KrowiV_SavedData.IgnoredItems do
        local icon, color, name = addon.GetPartialItemInfo(itemId);
        KrowiV_DualItemListFrame:AppendListItem(dualItemListSide.Right, itemId, icon, color, name);
    end
end

function ignoreListFrame.Show()
    KrowiV_DualItemListFrame:ClearAllPoints();
    KrowiV_DualItemListFrame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0);
    KrowiV_DualItemListFrame:SetHeight(MerchantFrame:GetHeight());
    KrowiV_DualItemListFrame:SetTitle(addon.L["Ignore List"]);
    KrowiV_DualItemListFrame:SetIcon("Interface/Icons/inv_shield_1h_newplayer_a_02");
    KrowiV_DualItemListFrame:ClearListItems(dualItemListSide.Left);
    KrowiV_DualItemListFrame:RegisterListItemsForClicks(dualItemListSide.Left, "LeftButtonUp");
    KrowiV_DualItemListFrame:SetListItemsOnClick(dualItemListSide.Left, LeftJunkItemOnClick);
    KrowiV_DualItemListFrame:ClearListItems(dualItemListSide.Right);
    KrowiV_DualItemListFrame:RegisterListItemsForClicks(dualItemListSide.Right, "RightButtonUp");
    KrowiV_DualItemListFrame:SetListItemsOnClick(dualItemListSide.Right, RightJunkItemOnClick);
    PopulateLeftListFrame();
    PopulateRightListFrame();
    KrowiV_DualItemListFrame:SetListInfo(dualItemListSide.Left, addon.L["Left-click an item to add it to the ignore list."]);
    KrowiV_DualItemListFrame:SetListInfo(dualItemListSide.Right, addon.L["Right-click an item to remove it from the ignore list."]);
    KrowiV_DualItemListFrame:Show();
end