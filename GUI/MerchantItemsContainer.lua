-- [[ Namespaces ]] --
local _, addon = ...;
addon.MerchantItemsContainer = {};
local merchantItemsContainer = addon.MerchantItemsContainer;

merchantItemsContainer.FirstOffsetX = 11;
merchantItemsContainer.FirstOffsetY = -69;
merchantItemsContainer.OffsetX = 12;
merchantItemsContainer.OffsetMerchantInfoY = 8;
merchantItemsContainer.OffsetBuybackInfoY = 15;
merchantItemsContainer.DefaultMerchantInfoNumRows = 5;
merchantItemsContainer.DefaultMerchantInfoNumColumns = 2;
merchantItemsContainer.DefaultBuybackInfoNumRows = 6;
merchantItemsContainer.DefaultBuybackInfoNumColumns = 2;
merchantItemsContainer.ItemWidth, merchantItemsContainer.ItemHeight = MerchantItem1:GetSize();

local infoNumRows, infoNumColumns = 0, 0;
local itemSlotTable = {};
for i = 1, 12, 1 do
	tinsert(itemSlotTable, _G["MerchantItem" .. i]);
end

local function ResetItemSlots()
    for _, itemSlot in next, itemSlotTable do
		itemSlot:Hide();
	end
end

local function GetItemSlot(index)
	if itemSlotTable[index] then
		return itemSlotTable[index];
	end
	local frame = CreateFrame("Frame", "MerchantItem" .. index, MerchantFrame, "MerchantItemTemplate");
	itemSlotTable[index] = frame;
	return frame;
end

function merchantItemsContainer:PrepareMerchantInfo()
    infoNumRows, infoNumColumns = addon.Options.db.NumRows, addon.Options.db.NumColumns;
    SetMerchantFilter(LE_LOOT_FILTER_ALL);
end

function merchantItemsContainer:PrepareBuybackInfo()
    infoNumRows, infoNumColumns = self.DefaultBuybackInfoNumRows, self.DefaultBuybackInfoNumColumns;
end

function merchantItemsContainer.LoadMaxNumItemSlots()
    MERCHANT_ITEMS_PER_PAGE = infoNumRows * infoNumColumns;
    if #itemSlotTable < MERCHANT_ITEMS_PER_PAGE then
        for i = 1, MERCHANT_ITEMS_PER_PAGE, 1 do
            local itemSlot = GetItemSlot(i);
            itemSlot:Hide();
        end
    end
end

function merchantItemsContainer:DrawItemSlots(numRows, numColumns, offsetX, offsetY)
    local calculatedOffsetX, calculatedOffsetY = 0, 0;
	for column = 1, numColumns, 1 do
		for row = 1, numRows, 1 do
			local index = (row - 1) * numColumns + column;
			local itemSlot = GetItemSlot(index);
            calculatedOffsetX = self.FirstOffsetX + (column - 1) * (offsetX + self.ItemWidth);
            calculatedOffsetY = self.FirstOffsetY - (row - 1) * (offsetY + self.ItemHeight);
			itemSlot:ClearAllPoints();
			itemSlot:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", calculatedOffsetX, calculatedOffsetY);
			itemSlot:Show();
		end
	end
end

local function DrawMerchantBuyBackItem(show)
    if show then
        MerchantBuyBackItem:ClearAllPoints();
        MerchantBuyBackItem:SetPoint("BOTTOMRIGHT", MerchantFrameInset, "BOTTOMRIGHT", -1, 6);
	    MerchantBuyBackItem:Show();
    else
        MerchantBuyBackItem:Hide();
    end
end

function merchantItemsContainer:DrawForMerchantInfo()
    ResetItemSlots();
	self:DrawItemSlots(infoNumRows, infoNumColumns, self.OffsetX, self.OffsetMerchantInfoY);
	DrawMerchantBuyBackItem(true);
end
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	merchantItemsContainer:DrawForMerchantInfo();
end);

function merchantItemsContainer:DrawForBuybackInfo()
    ResetItemSlots();
	self:DrawItemSlots(infoNumRows, infoNumColumns, self.OffsetX, self.OffsetBuybackInfoY);
	DrawMerchantBuyBackItem(false);
end
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	merchantItemsContainer:DrawForBuybackInfo();
end);