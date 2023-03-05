-- [[ Namespaces ]] --
local _, addon = ...;
local dualItemListSide = addon.Objects.DualItemListSide;
addon.ItemListFrame = {};
local itemList = addon.ItemListFrame;
local frame = KrowiV_DualItemListFrame;

function itemList.LeftItemOnClick(self, button)
    frame:AppendListItem(dualItemListSide.Right, self.ElementData.Id, self.ElementData.Icon, self.ElementData.Color, self.ElementData.Name);
    frame:RemoveListItem(dualItemListSide.Left, self.ElementData);
end

function itemList.RightItemOnClick(self, button)
    frame:AppendListItem(dualItemListSide.Left, self.ElementData.Id, self.ElementData.Icon, self.ElementData.Color, self.ElementData.Name);
    frame:RemoveListItem(dualItemListSide.Right, self.ElementData);
end