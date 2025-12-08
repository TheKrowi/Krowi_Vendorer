-- [[ Namespaces ]] --
local _, addon = ...;
local itemListFrame = addon.GUI.ItemListFrame;
local dualItemListSide = addon.Objects.DualItemListSide;
local frame;

KrowiV_JunkListFrameMixin = {};

function KrowiV_JunkListFrameMixin_OnLoad(self)
    frame = self;
end

function KrowiV_JunkListFrameMixin:OnEvent(event, arg1, arg2)
    if event == "BAG_UPDATE" then
        self:Update();
    end
end

function KrowiV_JunkListFrameMixin:OnShow()
    self:RegisterEvent("BAG_UPDATE");
    self:Update();
end

function KrowiV_JunkListFrameMixin:OnHide()
    self:UnregisterEvent("BAG_UPDATE");
end

local function LeftItemOnClick(self)
    KrowiV_SavedData.JunkItems[(GetItemInfoInstant(self.ElementData.Link))] = true;
    KrowiV_SavedData.IgnoredItems[(GetItemInfoInstant(self.ElementData.Link))] = nil;
    itemListFrame.LeftItemOnClick(self, frame);
    KrowiV_EmbeddedIgnoreListFrame:Update();
    KrowiV_AutoSellListFrame:Update();
end

local function RightItemOnClick(self)
    KrowiV_SavedData.JunkItems[(GetItemInfoInstant(self.ElementData.Link))] = nil;
    itemListFrame.RightItemOnClick(self, frame);
    KrowiV_EmbeddedIgnoreListFrame:Update();
    KrowiV_AutoSellListFrame:Update();
end

local function PopulateLeftListFrame()
    for bag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = Item:CreateFromBagAndSlot(bag, slot);
            if not item:IsItemEmpty() then
                item:ContinueOnItemLoad(function()
                    local itemId = item:GetItemID();
                    if KrowiV_SavedData.JunkItems[itemId] then
                        return;
                    end
                    -- make this an option later
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
    for itemId, _ in next, KrowiV_SavedData.JunkItems do
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

function KrowiV_JunkListFrameMixin:ShowWithMerchantFrame()
    if not self.IsEmbedded then
        self:ClearAllPoints();
        self:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0);
        self:SetHeight(MerchantFrame:GetHeight());
        self:SetTitle(addon.L["Junk List"]);
        self:SetIcon("Interface/Icons/Inv_Gizmo_03");
        self:SetListInfo(dualItemListSide.Left, addon.L["Left-click an item to add it to the junk list."]);
        self:SetListInfo(dualItemListSide.Right, addon.L["Right-click an item to remove it from the junk list."]);
    end
    self:RegisterListItemsForClicks(dualItemListSide.Left, "LeftButtonUp");
    self:SetListItemsOnClick(dualItemListSide.Left, LeftItemOnClick);
    self:RegisterListItemsForClicks(dualItemListSide.Right, "RightButtonUp");
    self:SetListItemsOnClick(dualItemListSide.Right, RightItemOnClick);
    self:Show();
end

function KrowiV_JunkListFrameMixin:Update()
    if not self:IsShown() then
        return;
    end
    self:ClearListItems();
    PopulateLeftListFrame();
    PopulateRightListFrame();
end