-- [[ Namespaces ]] --
local _, addon = ...;
addon.MerchantFrame = {};
local merchantFrame = addon.MerchantFrame;
local merchantItemsContainer = addon.MerchantItemsContainer;

local originalWidth, originalHeight = MerchantFrame:GetSize();

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	addon.EmbeddedItemListFrame.JunkList.Hide();
	addon.EmbeddedItemListFrame.IgnoreList.Hide();
	local numColumns = addon.Options.db.NumColumns - merchantItemsContainer.DefaultMerchantInfoNumColumns;
	local numRows = addon.Options.db.NumRows - merchantItemsContainer.DefaultMerchantInfoNumRows;
	local itemWidth = merchantItemsContainer.OffsetX + merchantItemsContainer.ItemWidth;
	local itemHeight = merchantItemsContainer.OffsetMerchantInfoY + merchantItemsContainer.ItemHeight;

	local width = originalWidth + numColumns * itemWidth;
	local height = originalHeight + numRows * itemHeight;
	if not MerchantPageText:IsShown() then
		height = height - 36;
	end
	MerchantFrame:SetSize(width, height);
	KrowiV_BottomExtensionRightBorder:Show();
	if numColumns > 0 then
		KrowiV_BottomExtensionLeftBorder:Show();
		KrowiV_BottomExtensionMidBorder:Show();
	else
		MerchantFrameBottomRightBorder:Hide();
		KrowiV_BottomExtensionLeftBorder:Hide();
		KrowiV_BottomExtensionMidBorder:Hide();
	end
end);

hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	addon.EmbeddedItemListFrame.JunkList.Hide();
	addon.EmbeddedItemListFrame.IgnoreList.Hide();
	MerchantFrame:SetSize(originalWidth, originalHeight);
	KrowiV_BottomExtensionRightBorder:Hide();
	KrowiV_BottomExtensionLeftBorder:Hide();
	KrowiV_BottomExtensionMidBorder:Hide();
end);

local function PrepareMerchantFrame()
    if MerchantFrame.selectedTab == 1 then
		merchantItemsContainer:PrepareMerchantInfo();
	else
		merchantItemsContainer:PrepareBuybackInfo();
	end
    merchantItemsContainer.LoadMaxNumItemSlots(); -- Make sure MerchantFrame_Update can set all items
	-- print("I got this many back:", GetMerchantNumItems())
end
hooksecurefunc("MerchantFrame_UpdateFilterString", PrepareMerchantFrame);

hooksecurefunc(MerchantFrame, "Show", function(self)
	SetMerchantFilter(LE_LOOT_FILTER_ALL);
end);

MerchantFrameBottomRightBorder:SetTexCoord(91 / 256, (91 + 76) / 256, 0, 0.4765625);

local bottomExtensionRightBorder = MerchantFrame:CreateTexture("KrowiV_BottomExtensionRightBorder");
bottomExtensionRightBorder:SetSize(76, 61);
bottomExtensionRightBorder:SetTexture("Interface/MerchantFrame/UI-Merchant-BottomBorder");
bottomExtensionRightBorder:SetTexCoord(0, 0.296875, 0.4765625, 0.953125);
bottomExtensionRightBorder:SetPoint("BOTTOMRIGHT", MerchantFrameInset, "BOTTOMRIGHT", 3, 0);

local bottomExtensionLeftBorder = MerchantFrame:CreateTexture("KrowiV_BottomExtensionLeftBorder");
bottomExtensionLeftBorder:SetSize(89, 61);
bottomExtensionLeftBorder:SetTexture("Interface/MerchantFrame/UI-Merchant-BottomBorder");
bottomExtensionLeftBorder:SetTexCoord((91 + 76) / 256, 1, 0, 0.4765625);
bottomExtensionLeftBorder:SetPoint("TOPLEFT", MerchantFrameBottomRightBorder, "TOPRIGHT", 0, 0);

local bottomExtensionMidBorder = MerchantFrame:CreateTexture("KrowiV_BottomExtensionMidBorder");
bottomExtensionMidBorder:SetTexture("Interface/MerchantFrame/UI-Merchant-BottomBorder");
bottomExtensionMidBorder:SetTexCoord(8 / 256, (8 + 151) / 256, 0, 0.4765625);
bottomExtensionMidBorder:SetPoint("TOPLEFT", bottomExtensionLeftBorder, "TOPRIGHT", 0, 0);
bottomExtensionMidBorder:SetPoint("BOTTOMRIGHT", bottomExtensionRightBorder, "BOTTOMLEFT", 0, 0);

MerchantPrevPageButton:SetPoint("BOTTOMLEFT", MerchantFrameBottomLeftBorder, "TOPLEFT", 8, -5);
MerchantNextPageButton:SetPoint("BOTTOMRIGHT", KrowiV_BottomExtensionRightBorder, "TOPRIGHT", -7, -5);

function KrowiV_ShowJunkList_OnLoad(self)
	self:SetText(addon.L["Junk List"]);
end

function KrowiV_ShowJunkList_OnClick()
	addon.ItemListFrame.JunkList.Show();
end

function KrowiV_ShowIgnoreList_OnLoad(self)
	self:SetText(addon.L["Ignore List"]);
	PanelTemplates_SetNumTabs(MerchantFrame, 4);
end

function KrowiV_ShowIgnoreList_OnClick()
	addon.ItemListFrame.IgnoreList.Show();
end

function MerchantFrame_Update()
	if MerchantFrame.lastTab ~= MerchantFrame.selectedTab then
		MerchantFrame_CloseStackSplitFrame();
		MerchantFrame.lastTab = MerchantFrame.selectedTab;
	end
	MerchantFrame_UpdateFilterString()
	if MerchantFrame.selectedTab == 1 then
		MerchantFrame_UpdateMerchantInfo();
	elseif MerchantFrame.selectedTab == 3 then
		merchantFrame.UpdateJunkInfo();
	elseif MerchantFrame.selectedTab == 4 then
		merchantFrame.UpdateIgnoreInfo();
	else
		MerchantFrame_UpdateBuybackInfo();
	end
end

function merchantFrame.UpdateJunkInfo()
	merchantItemsContainer:HideAll();
	MerchantFrameBottomRightBorder:Hide();
	KrowiV_BottomExtensionRightBorder:Hide();
	KrowiV_BottomExtensionLeftBorder:Hide();
	KrowiV_BottomExtensionMidBorder:Hide();
	MerchantRepairAllButton:Hide();
	MerchantRepairItemButton:Hide();
	MerchantBuyBackItem:Hide();
	MerchantPrevPageButton:Hide();
	MerchantNextPageButton:Hide();
	MerchantFrameBottomLeftBorder:Hide();
	MerchantFrameBottomRightBorder:Hide();
	MerchantRepairText:Hide();
	MerchantPageText:Hide();
	MerchantGuildBankRepairButton:Hide();
	MerchantFrame:SetWidth(610);
	addon.EmbeddedItemListFrame.JunkList.Show();
end

function merchantFrame.UpdateIgnoreInfo()
	merchantItemsContainer:HideAll();
	MerchantFrameBottomRightBorder:Hide();
	KrowiV_BottomExtensionRightBorder:Hide();
	KrowiV_BottomExtensionLeftBorder:Hide();
	KrowiV_BottomExtensionMidBorder:Hide();
	MerchantRepairAllButton:Hide();
	MerchantRepairItemButton:Hide();
	MerchantBuyBackItem:Hide();
	MerchantPrevPageButton:Hide();
	MerchantNextPageButton:Hide();
	MerchantFrameBottomLeftBorder:Hide();
	MerchantFrameBottomRightBorder:Hide();
	MerchantRepairText:Hide();
	MerchantPageText:Hide();
	MerchantGuildBankRepairButton:Hide();
	MerchantFrame:SetWidth(610);
	addon.EmbeddedItemListFrame.IgnoreList.Show();
end