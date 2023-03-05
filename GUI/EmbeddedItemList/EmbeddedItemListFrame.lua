-- [[ Namespaces ]] --
local _, addon = ...;
local dualItemListSide = addon.Objects.DualItemListSide;
addon.EmbeddedItemListFrame = {};
local itemList = addon.EmbeddedItemListFrame;
local frame = KrowiV_EmbeddedDualItemListFrame;

function itemList.LeftItemOnClick(self, button)
    frame:AppendListItem(dualItemListSide.Right, self.ElementData.Id, self.ElementData.Icon, self.ElementData.Color, self.ElementData.Name);
    frame:RemoveListItem(dualItemListSide.Left, self.ElementData);
end

function itemList.RightItemOnClick(self, button)
    frame:AppendListItem(dualItemListSide.Left, self.ElementData.Id, self.ElementData.Icon, self.ElementData.Color, self.ElementData.Name);
    frame:RemoveListItem(dualItemListSide.Right, self.ElementData);
end