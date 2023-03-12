-- [[ Namespaces ]] --
local _, addon = ...;
local dualItemListSide = addon.Objects.DualItemListSide;
addon.GUI.ItemListFrame = {};
local itemList = addon.GUI.ItemListFrame;

function itemList.LeftItemOnClick(self, frame)
    frame:AppendListItem(dualItemListSide.Right, self.ElementData.Id, self.ElementData.Icon, self.ElementData.Color, self.ElementData.Name);
    frame:RemoveListItem(dualItemListSide.Left, self.ElementData);
end

function itemList.RightItemOnClick(self, frame)
    frame:AppendListItem(dualItemListSide.Left, self.ElementData.Id, self.ElementData.Icon, self.ElementData.Color, self.ElementData.Name);
    frame:RemoveListItem(dualItemListSide.Right, self.ElementData);
end