-- [[ Namespaces ]] --
local _, addon = ...;
local itemList = addon.ItemList;
local dualItemListSide = addon.Objects.DualItemListSide;
itemList.JunkListFrame = {};
local junkListFrame = itemList.JunkListFrame;

function junkListFrame.Init()
    KrowiV_SavedData = KrowiV_SavedData or {};
    KrowiV_SavedData.JunkItems = KrowiV_SavedData.JunkItems or {};
end

local function LeftJunkItemOnClick(self, button)
    KrowiV_SavedData.JunkItems[self.ElementData.Id] = true;
    itemList.LeftItemOnClick(self, button);
end

local function RightJunkItemOnClick(self, button)
    KrowiV_SavedData.JunkItems[self.ElementData.Id] = nil;
    itemList.RightItemOnClick(self, button);
end

local function PopulateLeftListFrame()
    for bag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemId = C_Container.GetContainerItemID(bag, slot);
            if itemId and not KrowiV_SavedData.JunkItems[itemId] and not KrowiV_SavedData.IgnoredItems[itemId] then
                local icon, color, name = addon.GetPartialItemInfo(itemId);
                KrowiV_DualItemListFrame:AppendListItem(dualItemListSide.Left, itemId, icon, color, name);
            end
        end
    end
end

local function PopulateRightListFrame()
    for itemId, _ in next, KrowiV_SavedData.JunkItems do
        local icon, color, name = addon.GetPartialItemInfo(itemId);
        KrowiV_DualItemListFrame:AppendListItem(dualItemListSide.Right, itemId, icon, color, name);
    end
end

function junkListFrame.Show()
    KrowiV_DualItemListFrame:ClearAllPoints();
    KrowiV_DualItemListFrame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0);
    KrowiV_DualItemListFrame:SetHeight(MerchantFrame:GetHeight());
    KrowiV_DualItemListFrame:SetTitle(addon.L["Junk List"]);
    KrowiV_DualItemListFrame:SetIcon("Interface/Icons/inv_gizmo_03");
    KrowiV_DualItemListFrame:ClearListItems(dualItemListSide.Left);
    KrowiV_DualItemListFrame:RegisterListItemsForClicks(dualItemListSide.Left, "LeftButtonUp");
    KrowiV_DualItemListFrame:SetListItemsOnClick(dualItemListSide.Left, LeftJunkItemOnClick);
    KrowiV_DualItemListFrame:ClearListItems(dualItemListSide.Right);
    KrowiV_DualItemListFrame:RegisterListItemsForClicks(dualItemListSide.Right, "RightButtonUp");
    KrowiV_DualItemListFrame:SetListItemsOnClick(dualItemListSide.Right, RightJunkItemOnClick);
    PopulateLeftListFrame();
    PopulateRightListFrame();
    KrowiV_DualItemListFrame:SetListInfo(dualItemListSide.Left, addon.L["Left-click an item to add it to the junk list."]);
    KrowiV_DualItemListFrame:SetListInfo(dualItemListSide.Right, addon.L["Right-click an item to remove it from the junk list."]);
    KrowiV_DualItemListFrame:Show();
end