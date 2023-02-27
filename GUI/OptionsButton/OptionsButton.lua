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

local function UpdateView()
	print(addon.Options.db.Rows, addon.Options.db.Columns);
	-- Based on these numbers, calculate the number of items that can be shown
	-- Pull them from the pool or create new ones if needed
	-- MerchantItemTemplate
end

local menu = LibStub("Krowi_Menu-1.0");
function KrowiV_OptionsButton_OnMouseDown(self)
	UIMenuButtonStretchMixin.OnMouseDown(self);
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);

    -- Reset menu
	menu:Clear();

	local rows = addon.Objects.MenuItem:New({Text = addon.L["Rows"]});
	for i = 1, 10, 1 do
		self:AddRadioButton(menu, rows, i, addon.Options.db, {"Rows"}, UpdateView);
	end
	menu:Add(rows);

	local columns = addon.Objects.MenuItem:New({Text = addon.L["Columns"]});
	for i = 1, 6, 1 do
		self:AddRadioButton(menu, columns, i, addon.Options.db, {"Columns"}, UpdateView);
	end
	menu:Add(columns);

	menu:Toggle(self, 96, 15);
end