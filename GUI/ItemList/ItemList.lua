-- [[ Namespaces ]] --
local _, addon = ...;
local dualItemListSide = addon.Objects.DualItemListSide;
addon.ItemList = {};
local itemList = addon.ItemList;

function itemList.LeftItemOnClick(self, button)
    KrowiV_DualItemListFrame:AppendListItem(dualItemListSide.Right, self.ElementData.Id, self.ElementData.Icon, self.ElementData.Color, self.ElementData.Name);
    KrowiV_DualItemListFrame:RemoveListItem(dualItemListSide.Left, self.ElementData);
end

function itemList.RightItemOnClick(self, button)
    KrowiV_DualItemListFrame:AppendListItem(dualItemListSide.Left, self.ElementData.Id, self.ElementData.Icon, self.ElementData.Color, self.ElementData.Name);
    KrowiV_DualItemListFrame:RemoveListItem(dualItemListSide.Right, self.ElementData);
end