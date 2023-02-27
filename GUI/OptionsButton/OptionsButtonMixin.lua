-- hooksecurefunc("MerchantFrame_Update", function()
-- 	if (MerchantFrame.selectedTab == 1) then
-- 		-- Addon:UpdateExtensionPanel();
-- 		MerchantFrameLootFilter:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -35, -28);
-- 		VendorerToggleExtensionFrameButtons:Show();
-- 	else
-- 		MerchantFrame_UpdateBuybackInfo();
-- 		-- Addon:HideExtensionPanel();
-- 		MerchantFrameLootFilter:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", 0, -28);
-- 		VendorerToggleExtensionFrameButtons:Hide();
-- 		-- VendorerStackSplitFrame:Cancel();
-- 	end
-- end);

-- [[ Namespaces ]] --
local _, addon = ...;

KrowiV_OptionsButtonMixin = {};

function KrowiV_OptionsButtonMixin:AddRadioButton(parentMenu, _menu, text, options, keys, func)
    _menu:AddFull({  Text = text,
                    Checked = function() -- Same
                        return addon.Util.ReadNestedKeys(options, keys) == text; -- e.g.: return filters.SortBy.Criteria == addon.L["Default"]
                    end,
                    Func = function()
                        addon.Util.WriteNestedKeys(options, keys, text); -- e.g.: filters.SortBy.Criteria = text;
                        parentMenu:SetSelectedName(text);
                        func();
                    end,
                    NotCheckable = false,
                    KeepShownOnClick = true
                });
end