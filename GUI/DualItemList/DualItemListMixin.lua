-- [[ Namespaces ]] --
local _, addon = ...;

KrowiV_DualItemListMixin = {};

function KrowiV_DualItemListMixin:OnLoad()
    self.LeftList = self.LeftFrame.ListFrame;
    self.RightList = self.RightFrame.ListFrame;
end

function KrowiV_DualItemListMixin:AppendListItem(side, id, icon, color, name, onClick, ...)
    if side == addon.Objects.DualItemListSide.Left then
        self.LeftList:AppendListItem(id, icon, color, name, onClick, ...);
    elseif side == addon.Objects.DualItemListSide.Right then
        self.RightList:AppendListItem(id, icon, color, name, onClick, ...);
    end
end

function KrowiV_DualItemListMixin:RemoveListItem(side, elementData)
    if side == addon.Objects.DualItemListSide.Left then
        self.LeftList:RemoveListItem(elementData);
    elseif side == addon.Objects.DualItemListSide.Right then
        self.RightList:RemoveListItem(elementData);
    end
end

function KrowiV_DualItemListMixin:SetListItemsOnClick(side, func)
    if side == addon.Objects.DualItemListSide.Left then
        self.LeftList:SetListItemsOnClick(func);
    elseif side == addon.Objects.DualItemListSide.Right then
        self.RightList:SetListItemsOnClick(func);
    end
end

function KrowiV_DualItemListMixin:RegisterListItemsForClicks(side, ...)
    if side == addon.Objects.DualItemListSide.Left then
        self.LeftList:RegisterListItemsForClicks(...);
    elseif side == addon.Objects.DualItemListSide.Right then
        self.RightList:RegisterListItemsForClicks(...);
    end
end

function KrowiV_DualItemListMixin:ClearListItems(side)
    if side == addon.Objects.DualItemListSide.Left then
        self.LeftList:ClearListItems();
    elseif side == addon.Objects.DualItemListSide.Right then
        self.RightList:ClearListItems();
    end
end