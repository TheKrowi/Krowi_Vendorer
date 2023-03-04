-- [[ Namespaces ]] --
local _, addon = ...;
addon.ItemList = {};
local itemList = addon.ItemList;

function itemList.Show(title, icon, items)
    KrowiV_ItemListFrame:SetTitle(title);
    KrowiV_ItemListFrame:SetIcon(icon);
    KrowiV_ItemListFrame:SetItems(items);
    KrowiV_ItemListFrame:Show();
end