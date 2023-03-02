-- [[ Namespaces ]] --
local _, addon = ...;
addon.MerchantFrame = {};
local merchantFrame = addon.MerchantFrame;
local merchantItemsContainer = addon.MerchantItemsContainer;

local originalWidth, originalHeight = MerchantFrame:GetSize();

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	local numColumns = addon.Options.db.NumColumns - merchantItemsContainer.DefaultMerchantInfoNumColumns;
	local numRows = addon.Options.db.NumRows - merchantItemsContainer.DefaultMerchantInfoNumRows;
	local itemWidth = merchantItemsContainer.OffsetX + merchantItemsContainer.ItemWidth;
	local itemHeight = merchantItemsContainer.OffsetMerchantInfoY + merchantItemsContainer.ItemHeight;

	local width = originalWidth + numColumns * itemWidth;
	local height = originalHeight + numRows * itemHeight;
	MerchantFrame:SetSize(width, height);
end);

hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	MerchantFrame:SetSize(originalWidth, originalHeight);
end);

local function PrepareMerchantFrame()
    if MerchantFrame.selectedTab == 1 then
		merchantItemsContainer:PrepareMerchantInfo();
	else
		merchantItemsContainer:PrepareBuybackInfo();
	end
    merchantItemsContainer.LoadMaxNumItemSlots(); -- Make sure MerchantFrame_Update can set all items
end
hooksecurefunc("MerchantFrame_UpdateFilterString", PrepareMerchantFrame);