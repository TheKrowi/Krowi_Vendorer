-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;
objects.CriteriaType = {};
local criteriaType = objects.CriteriaType;
local equalityOperator = addon.Objects.EqualityOperator;
local itemQuality = addon.Objects.ItemQuality;
local inventoryType = addon.Objects.InventoryType;
local itemLocation = ItemLocation:CreateEmpty();

criteriaType.Enum = addon.Util.Enum2{
    "ItemLevel",
    "Soulbound",
    "Quality",
    "InventoryType",
    "VendorPrice"     -- ← NEU (StackHeight entfernt)
};

local criteriaTypeList
local function GetCriteriaTypeText(_criteriaType)
    if not criteriaTypeList then
        criteriaTypeList = {
            [criteriaType.Enum.ItemLevel] = addon.L["Item Level"],
            [criteriaType.Enum.Soulbound] = addon.L["Soulbound"],
            [criteriaType.Enum.Quality] = addon.L["Quality"],
            [criteriaType.Enum.InventoryType] = addon.L["Inventory Type"],
            [criteriaType.Enum.VendorPrice] = addon.L["Vendor Price"],      -- ← NEU
        };
    end
    return criteriaTypeList[_criteriaType];
end

function criteriaType.GetCriteriaTypeList()
    if not criteriaTypeList then
        GetCriteriaTypeText(nil);
    end
    return criteriaTypeList;
end

do --[[ Rule evaluation functions ]]
    local function ItemLevel_Func(itemLevel, operator, value)
        local result = equalityOperator.Func[operator](itemLevel, value);
        return result, "Item level is " .. equalityOperator.List[operator] .. " " .. value;
    end

    local function Soulbound_Func(bag, slot)
        itemLocation:SetBagAndSlot(bag, slot);
        local result = C_Item.IsBound(itemLocation);
        return result, "Is soulbound";
    end

    local function Quality_Func(quality, qualities)
        local result = qualities[quality];
        return result, "Quality is " .. itemQuality.List[quality];
    end

    local function InventoryType_Func(_inventoryType, inventoryTypes)
        local result = inventoryTypes[_inventoryType];
        return result, "Inventory type is " .. inventoryType.List[_inventoryType];
    end

    -- ← NEUE FUNKTIONEN:
    local function VendorPrice_Func(vendorPrice, operator, value)
        if operator == nil or value == nil then
            return false, "Vendor price condition not fully configured";
        end
        if vendorPrice == nil then
            -- Preis unbekannt (Item-Cache noch nicht geladen) → sicher: nicht verkaufen
            return false, "Vendor price unknown (item not fully cached)";
        end
        local result = equalityOperator.Func[operator](vendorPrice, value);
        return result, "Vendor price " .. equalityOperator.List[operator] .. " " .. addon.GetCopperText(value) .. " (item: " .. addon.GetCopperText(vendorPrice) .. ")";
    end

    function criteriaType.Func(condition, itemInfo)
        if condition.CriteriaType == criteriaType.Enum.ItemLevel then
            return ItemLevel_Func(itemInfo.ItemLevel, condition.Operator, condition.Value);
        elseif condition.CriteriaType == criteriaType.Enum.Soulbound then
            return Soulbound_Func(itemInfo.Bag, itemInfo.Slot);
        elseif condition.CriteriaType == criteriaType.Enum.Quality then
            return Quality_Func(itemInfo.Quality, condition.Qualities);
        elseif condition.CriteriaType == criteriaType.Enum.InventoryType then
            return InventoryType_Func(itemInfo.InventoryType, condition.InventoryTypes)
        -- ← NEU:
        elseif condition.CriteriaType == criteriaType.Enum.VendorPrice then
            return VendorPrice_Func(itemInfo.VendorPrice, condition.Operator, condition.Value);
        end
    end
end

do --[[ Rule validity checking ]]
    local function ItemLevel_IsValid(condition)
        if not condition.Operator then
            return false, addon.L["No equality operator selected"];
        end
        if not equalityOperator.List[condition.Operator] then
            return false, addon.L["No valid equality operator selected"];
        end
        if not condition.Value then
            return false, addon.L["No item level value entered"];
        end
        return true, "";
    end

    -- ← NEUE VALIDIERUNGSFUNKTIONEN:
    local function VendorPrice_IsValid(condition)
        if not condition.Operator then
            return false, addon.L["No equality operator selected"];
        end
        if not equalityOperator.List[condition.Operator] then
            return false, addon.L["No valid equality operator selected"];
        end
        if condition.Value == nil then
            return false, addon.L["No vendor price value entered"];
        end
        return true, "";
    end

    function criteriaType.CheckIfValid(condition)
        local desc = addon.L["Invalid condition"] .. " - ";
        if not condition.CriteriaType then
            return false, desc .. addon.L["No criteria type selected"];
        end
        if not GetCriteriaTypeText(condition.CriteriaType) then
            return false, desc .. addon.L["No valid criteria type selected"];
        end
        if condition.CriteriaType == criteriaType.Enum.ItemLevel then
            local isValid, text = ItemLevel_IsValid(condition)
            return isValid, desc .. text;
        elseif condition.CriteriaType == criteriaType.Enum.Soulbound then
            return true, "";
        elseif condition.CriteriaType == criteriaType.Enum.Quality then
            if condition.NumSelectedQualities == 0 then
                return false, addon.L["At least one quality must be selected"];
            end
        elseif condition.CriteriaType == criteriaType.Enum.InventoryType then
            if condition.NumSelectedInventoryTypes == 0 then
                return false, addon.L["At least one inventory type must be selected"];
            end
        -- ← NEU:
        elseif condition.CriteriaType == criteriaType.Enum.VendorPrice then
            local isValid, text = VendorPrice_IsValid(condition)
            return isValid, desc .. text;
        end
        return true, "";
    end
end