-- [[ Namespaces ]] --
local _, addon = ...;
local dualItemListSide = addon.Objects.DualItemListSide;

KrowiV_DualItemListFrameMixin = {};

function KrowiV_DualItemListFrameMixin:OnLoad()
    ButtonFrameTemplate_HidePortrait(self);
    -- self.AddButton:RegisterCallback("OnClick", self.RightFrame.ListFrame.AppendListItem, self.RightFrame.ListFrame);
end

function KrowiV_DualItemListFrameMixin:SetIcon(icon)
    ButtonFrameTemplate_ShowPortrait(self);
    self:SetPortraitToAsset(icon)
end

function KrowiV_DualItemListFrameMixin:AppendListItem(side, link, icon, color, name, onClick, ...)
    if side == dualItemListSide.Left then
        self.EmbeddedItemList.LeftList:AppendListItem(link, icon, color, name, onClick, ...);
    elseif side == dualItemListSide.Right then
        self.EmbeddedItemList.RightList:AppendListItem(link, icon, color, name, onClick, ...);
    end
end

function KrowiV_DualItemListFrameMixin:RemoveListItem(side, elementData)
    if side == dualItemListSide.Left then
        self.EmbeddedItemList.LeftList:RemoveListItem(elementData);
    elseif side == dualItemListSide.Right then
        self.EmbeddedItemList.RightList:RemoveListItem(elementData);
    end
end

function KrowiV_DualItemListFrameMixin:SetListItemsOnClick(side, func)
    if side == dualItemListSide.Left then
        self.EmbeddedItemList.LeftList:SetListItemsOnClick(func);
    elseif side == dualItemListSide.Right then
        self.EmbeddedItemList.RightList:SetListItemsOnClick(func);
    end
end

function KrowiV_DualItemListFrameMixin:RegisterListItemsForClicks(side, ...)
    if side == dualItemListSide.Left then
        self.EmbeddedItemList.LeftList:RegisterListItemsForClicks(...);
    elseif side == dualItemListSide.Right then
        self.EmbeddedItemList.RightList:RegisterListItemsForClicks(...);
    end
end

function KrowiV_DualItemListFrameMixin:ClearListItems(side)
    if side == nil or side == dualItemListSide.Left then
        self.EmbeddedItemList.LeftList:ClearListItems();
    end
    if side == nil or side == dualItemListSide.Right then
        self.EmbeddedItemList.RightList:ClearListItems();
    end
end

function KrowiV_DualItemListFrameMixin:SetListInfo(side, text)
    if side == dualItemListSide.Left then
        self.LeftItemListInfo:SetText(text);
    elseif side == dualItemListSide.Right then
        self.RightItemListInfo:SetText(text);
    end
end