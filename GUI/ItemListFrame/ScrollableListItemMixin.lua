-- [[ Namespaces ]] --
local _, addon = ...;

KrowiV_ScrollableListItemMixin = {};

function KrowiV_ScrollableListItemMixin:Init(elementData)
    self.ElementData = elementData;
    self.Icon:SetTexture(elementData.Icon);
    self.IconBorder:SetVertexColor(elementData.Color:GetRGBA());
    self.Name:SetText(elementData.Name);
end

function KrowiV_ScrollableListItemMixin:OnClick(button)
    if button == "LeftButton" then
        -- print(self.ElementData.Name);
	elseif button == "RightButton" then
		KrowiV_ItemListFrame.ListFrame:RemoveListItem(self.ElementData);
	end
end