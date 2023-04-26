-- [[ Namespaces ]] --
local _, addon = ...;
local itemListFrame = addon.GUI.ItemListFrame;
local dualItemListSide = addon.Objects.DualItemListSide;
itemListFrame.JunkList = {};
local junkList = itemListFrame.JunkList;
local frame = KrowiV_DualItemListFrame;
local isEmbedded = false;

function junkList.Init(_isEmbedded)
    KrowiV_SavedData = KrowiV_SavedData or {};
    KrowiV_SavedData.JunkItems = KrowiV_SavedData.JunkItems or {};

    isEmbedded = _isEmbedded;
    if isEmbedded then
        frame = KrowiV_EmbeddedDualItemListFrame
    end
end

local function LeftJunkItemOnClick(self)
    KrowiV_SavedData.JunkItems[self.ElementData.Id] = -1;
    itemListFrame.LeftItemOnClick(self, frame);
end

local function RightJunkItemOnClick(self)
    KrowiV_SavedData.JunkItems[self.ElementData.Id] = nil;
    itemListFrame.RightItemOnClick(self, frame);
end

local function PopulateLeftListFrame()
    for bag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = Item:CreateFromBagAndSlot(bag, slot);
            if not item:IsItemEmpty() then
                item:ContinueOnItemLoad(function()
                    local link = item:GetItemLink();
                    local icon = item:GetItemIcon();
                    local color = item:GetItemQualityColor();
                    local name = item:GetItemName();
                    frame:AppendListItem(link, icon, color.color, name, nil, bag, slot);
                end);
            end
        end
    end
end

local function PopulateRightListFrame()
    -- for itemId, _ in next, KrowiV_SavedData.JunkItems do
    --     local icon, color, name = addon.GetPartialItemInfo(itemId);
    --     frame:AppendListItem(dualItemListSide.Right, itemId, icon, color, name);
    -- end
end

function junkList.Show()
    if not isEmbedded then
        frame:ClearAllPoints();
        frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0);
        frame:SetHeight(MerchantFrame:GetHeight());
        frame:SetTitle(addon.L["Junk List"]);
        frame:SetIcon("Interface/Icons/Inv_Gizmo_03");
        frame:SetListInfo(dualItemListSide.Left, addon.L["Left-click an item to add it to the junk list."]);
        frame:SetListInfo(dualItemListSide.Right, addon.L["Right-click an item to remove it from the junk list."]);
    end
    frame:ClearListItems(dualItemListSide.Left);
    frame:RegisterListItemsForClicks(dualItemListSide.Left, "LeftButtonUp");
    frame:SetListItemsOnClick(dualItemListSide.Left, LeftJunkItemOnClick);
    frame:ClearListItems(dualItemListSide.Right);
    frame:RegisterListItemsForClicks(dualItemListSide.Right, "RightButtonUp");
    frame:SetListItemsOnClick(dualItemListSide.Right, RightJunkItemOnClick);
    PopulateLeftListFrame();
    PopulateRightListFrame();
    frame:Show();
end

function junkList.Hide()
    if isEmbedded then
        frame:Hide();
    end
end