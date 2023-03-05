-- [[ Namespaces ]] --
local _, addon = ...;

KrowiV_ScrollableListItemMixin = {};

function KrowiV_ScrollableListItemMixin:Init(elementData)
    self.ElementData = elementData;
    self.Icon:SetTexture(elementData.Icon);
    self.IconBorder:SetVertexColor(elementData.Color:GetRGBA());
    self.Name:SetText(elementData.Name);
    self.Name:SetTextColor(elementData.Color:GetRGBA());
    self:RegisterForClicks(unpack(elementData.MouseButtons));
    self:SetScript("OnClick", elementData.OnClick);
end

function KrowiV_ScrollableListItemMixin:OnEnter(button)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetItemByID(self.ElementData.Id);
    GameTooltip:Show();
end

function KrowiV_ScrollableListItemMixin:OnLeave(button)
    GameTooltip:Hide();
end