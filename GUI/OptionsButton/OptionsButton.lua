-- [[ Namespaces ]] --
local _, addon = ...;

local originalWidth, originalHeight = MerchantFrame:GetSize();
local xFirstOffset, yFirstOffset = 11, -69;
local xOffset, yOffsetMerchantInfo, yOffsetBuybackInfo = 12, 8, 15;
local itemWidth, itemHeight = MerchantItem1:GetSize();

local itemSlotTable = {};
for i = 1, 12, 1 do
	tinsert(itemSlotTable, _G["MerchantItem" .. i]);
end

local function ResetTable(t)
	for _, v in next, t do
		v:Hide();
	end
end

local function ResetItemSlots()
	ResetTable(itemSlotTable);
end

local function GetItemSlot(index)
	if itemSlotTable[index] then
		return itemSlotTable[index];
	end
	local frame = CreateFrame("Frame", "MerchantItem" .. index, MerchantFrame, "MerchantItemTemplate");
	itemSlotTable[index] = frame;
	return frame;
end

local function DrawItemSlots(rows, columns, yOffset)
	for column = 1, columns, 1 do
		for row = 1, rows, 1 do
			local index = (row - 1) * columns + column;
			local itemSlot = GetItemSlot(index);
			itemSlot:ClearAllPoints();
			itemSlot:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", xFirstOffset + (column - 1) * (xOffset + itemWidth), yFirstOffset - (row - 1) * (yOffset + itemHeight));
			itemSlot:Show();
		end
	end
end

local function DrawMerchantInfo()
	ResetItemSlots();

	local columns = addon.Options.db.Columns;
	local rows = addon.Options.db.Rows;

	DrawItemSlots(rows, columns, yOffsetMerchantInfo);
	MerchantBuyBackItem:ClearAllPoints();
	MerchantBuyBackItem:SetPoint("BOTTOMRIGHT", MerchantFrameInset, "BOTTOMRIGHT", -1, 6);
	MerchantBuyBackItem:Show();
end

local function DrawBuybackInfo()
	ResetItemSlots();

	MerchantFrame:SetSize(originalWidth, originalHeight);

	local columns = 2;
	local rows = 6;

	DrawItemSlots(rows, columns, yOffsetBuybackInfo);
	MerchantBuyBackItem:Hide();
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	DrawMerchantInfo();
end);

hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	DrawBuybackInfo();
end);

local function UpdateView()
	print(addon.Options.db.Rows, addon.Options.db.Columns);
	MerchantFrame_Update();
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