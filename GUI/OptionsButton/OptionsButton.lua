-- [[ Namespaces ]] --
local _, addon = ...;

local function UpdateView()
	MerchantFrame_Update();
end

local menu = LibStub("Krowi_Menu-1.0");
function KrowiV_OptionsButton_OnMouseDown(self)
	UIMenuButtonStretchMixin.OnMouseDown(self);
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);

    -- Reset menu
	menu:Clear();

	local rows = addon.Objects.MenuItem:New({Text = addon.L["Rows"]});
	for i = 1, 10, 1 do
		self:AddRadioButton(menu, rows, i, addon.Options.db, {"NumRows"}, UpdateView);
	end
	menu:Add(rows);

	local columns = addon.Objects.MenuItem:New({Text = addon.L["Columns"]});
	for i = 2, 6, 1 do
		self:AddRadioButton(menu, columns, i, addon.Options.db, {"NumColumns"}, UpdateView);
	end
	menu:Add(columns);

	menu:Toggle(self, 96, 15);
end