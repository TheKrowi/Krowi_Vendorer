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

function merchantItemsContainer:HideAll()
    ResetItemSlots();
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

function merchantItemsContainer:DrawItemSlot(index, row, column, offsetX, offsetY)
    local itemSlot = GetItemSlot(index);
    local calculatedOffsetX = self.FirstOffsetX + (column - 1) * (offsetX + self.ItemWidth);
    local calculatedOffsetY = self.FirstOffsetY - (row - 1) * (offsetY + self.ItemHeight);
    itemSlot:ClearAllPoints();
    itemSlot:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", calculatedOffsetX, calculatedOffsetY);
    itemSlot:Show();
end

function merchantItemsContainer:DrawItemSlots(numRows, numColumns, offsetX, offsetY)
    if addon.Options.db.Direction == addon.L["Columns first"] then
        for row = 1, numRows, 1 do
            for column = 1, numColumns, 1 do
                local index = (column - 1) * numRows + row;
                self:DrawItemSlot(index, row, column, offsetX, offsetY);
            end
        end
    else
        for column = 1, numColumns, 1 do
            for row = 1, numRows, 1 do
                local index = (row - 1) * numColumns + column;
                self:DrawItemSlot(index, row, column, offsetX, offsetY);
            end
        end
    end
end

local function DrawMerchantBuyBackItem(show)
    if show then
        MerchantBuyBackItem:ClearAllPoints();
        MerchantBuyBackItem:SetPoint("BOTTOMRIGHT", MerchantFrameBottomRightBorder, "BOTTOMRIGHT", -4, 8);
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

local orgGetMerchantNumItems = GetMerchantNumItems;
local orgGetMerchantItemInfo = GetMerchantItemInfo;
local customItemIndices = {};
GetMerchantNumItems = function()
    -- Uncomment this when we implement custom filters as now the existing ones still work
    -- SetMerchantFilter(LE_LOOT_FILTER_ALL);
	local numItems = orgGetMerchantNumItems();
    customItemIndices = {};
    for i = 1, numItems, 1 do
        -- Add filtering here cause now they're just all added
        -- if (i % 2 == 0) then
            tinsert(customItemIndices, i);
        -- end
    end
    -- print("Total:", numItems, "Shown:", #customItemIndices)
    return #customItemIndices;
end

GetMerchantItemInfo = function(index)
    index = customItemIndices[index];
    local name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID = orgGetMerchantItemInfo(index);

    return name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID;
end