-- [[ Namespaces ]] --
local addonName, addon = ...;

-- [[ Ace ]] --
addon.L = LibStub(addon.Libs.AceLocale):GetLocale(addonName);

print(addon.MetaData.Title, "loaded");

if MerchantFrame then
    print("already loaded")
end

-- [[ Load addon ]] --
local loadHelper = CreateFrame("Frame");
loadHelper:RegisterEvent("ADDON_LOADED");
loadHelper:RegisterEvent("MERCHANT_UPDATE");
loadHelper:RegisterEvent("GUILDBANK_UPDATE_MONEY");
loadHelper:RegisterEvent("HEIRLOOMS_UPDATED");
loadHelper:RegisterEvent("BAG_UPDATE");
loadHelper:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL");

function loadHelper:OnEvent(event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == "Krowi_Vendorer" then -- This always needs to load
            KrowiV_InjectOptions:SetOptionsTable(addon.Options.OptionsTable);
            KrowiV_InjectOptions:SetOptions(addon.Options.Defaults.profile);

            addon.Data.AutoJunk.Load();

            addon.Options.Load();

            addon.GUI.ItemListFrame.JunkList.Init(true);
            addon.GUI.ItemListFrame.IgnoreList.Init(true);

            addon.Icon.Load();

            addon.GUI.ItemTooltip.Load();
        end
    elseif event == "MERCHANT_UPDATE" then
    --     print("MERCHANT_UPDATE");
    elseif event == "GUILDBANK_UPDATE_MONEY" then
    --     print("GUILDBANK_UPDATE_MONEY");
    elseif event == "HEIRLOOMS_UPDATED" then
    --     print("HEIRLOOMS_UPDATED");
    elseif event == "BAG_UPDATE" then
    --     print("BAG_UPDATE");
    elseif event == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
    --     print("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL");
    end
end
loadHelper:SetScript("OnEvent", loadHelper.OnEvent);