-- [[ Namespaces ]] --
local _, addon = ...;

KrowiV_ItemListFrameMixin = {};

function KrowiV_ItemListFrameMixin:OnLoad()
    ButtonFrameTemplate_HidePortrait(self);
    self.AddButton:RegisterCallback("OnClick", self.ListFrame.AppendListItem, self.ListFrame);
end

function KrowiV_ItemListFrameMixin:SetIcon(icon)
    ButtonFrameTemplate_ShowPortrait(self);
    SetPortraitToTexture(self.PortraitContainer.portrait, icon);
end

function KrowiV_ItemListFrameMixin:SetItems(items)
    local itemIds = {111676, 109142, 110274, 110290, 152015, 151952, 109143, 152048, 109223, 78384, 151953, 110291, 152017, 152113, 109144, 152018, 152178, 151987};
    for _, itemId in next, itemIds do
        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
        itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
        expacID, setID, isCraftingReagent
            = GetItemInfo(itemId);
        local hex = select(4, GetItemQualityColor(itemQuality));
        local color = CreateColorFromHexString(hex);
        self.ListFrame:AppendListItem(itemId, itemTexture, color, itemName);
    end
end