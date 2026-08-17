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
    "VendorPrice",
    "TransmogKnown",
    "ItemLevelVsEquipped"   -- ← NEU: Vergleich mit ausgerüsteten Items
};

local criteriaTypeList
local function GetCriteriaTypeText(_criteriaType)
    if not criteriaTypeList then
        criteriaTypeList = {
            [criteriaType.Enum.ItemLevel] = addon.L["Item Level"],
            [criteriaType.Enum.Soulbound] = addon.L["Soulbound"],
            [criteriaType.Enum.Quality] = addon.L["Quality"],
            [criteriaType.Enum.InventoryType] = addon.L["Inventory Type"],
            [criteriaType.Enum.VendorPrice] = addon.L["Vendor Price"],
            [criteriaType.Enum.TransmogKnown] = addon.L["Transmog Known"],
            [criteriaType.Enum.ItemLevelVsEquipped] = addon.L["Item Level vs Equipped"],  -- ← NEU
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
    local function VendorPrice_Func(vendorPrice, condition)
        if condition.Operator == nil then
            return false, "Vendor price condition not fully configured";
        end
        
        local value = condition.Value or 0;
        
        if value == 0 then
            return false, "Vendor price not configured";
        end
        
        if vendorPrice == nil then
            -- Preis unbekannt (Item-Cache noch nicht geladen) → sicher: nicht verkaufen
            return false, "Vendor price unknown (item not fully cached)";
        end
        local result = equalityOperator.Func[condition.Operator](vendorPrice, value);
        return result, "Vendor price " .. equalityOperator.List[condition.Operator] .. " " .. addon.GetCopperText(value) .. " (item: " .. addon.GetCopperText(vendorPrice) .. ")";
    end

    local function TransmogKnown_Func(itemLink, bag, slot, condition)
        -- condition.TransmogStatus = 1 (Known) oder 2 (Unknown)
        if not condition.TransmogStatus then
            return false, addon.L["At least one transmog status must be selected"];
        end
        
        -- Prüfe aktuellen Transmog-Lern-Status
        local currentStatus = nil  -- "Known" oder "Unknown" (Partial wird als Unknown behandelt)
        local source = "none"
        
        -- ============================================================
        -- Option A: Nutze TransmogChecker falls vorhanden
        -- ============================================================
        if addon.TransmogChecker and addon.TransmogChecker.HasUnlearnedTransmog then
            local hasUnlearned = addon.TransmogChecker:HasUnlearnedTransmog(itemLink)
            -- Partial wird wie Unknown behandelt (hasUnlearned = true)
            currentStatus = hasUnlearned and "Unknown" or "Known"
            source = "TransmogChecker"
        -- ============================================================
        -- Option B: Fallback zu CanIMogIt
        -- ============================================================
        elseif CanIMogIt and CanIMogIt.CalculateTooltipText then
            local ok, text, unmodifiedText = pcall(
                CanIMogIt.CalculateTooltipText, CanIMogIt, itemLink, bag, slot
            );
            
            if ok and unmodifiedText then
                if unmodifiedText == CanIMogIt.UNKNOWN or unmodifiedText == CanIMogIt.PARTIAL then
                    currentStatus = "Unknown"  -- Partial = Unknown
                else
                    currentStatus = "Known"
                end
                source = "CanIMogIt"
            else
                return false, addon.L["Transmog status unknown"];
            end
        else
            return false, addon.L["CanIMogIt not loaded"];
        end
        
        -- Prüfe gegen eingestellten Status
        local statusIndex = { Known = 1, Unknown = 2 }
        local result = (currentStatus and statusIndex[currentStatus] == condition.TransmogStatus)
        
        return result, currentStatus .. " (" .. source .. ")";
    end

    local function ItemLevelVsEquipped_Func(itemLink, condition)
        if not condition.Operator or condition.Value == nil then
            return false, "Item Level vs Equipped not configured";
        end
        
        local itemLevel = select(4, GetItemInfo(itemLink));
        if not itemLevel then
            return false, "Item level unknown";
        end
        
        local baseEqType = select(10, GetItemInfo(itemLink));
        if not baseEqType then
            return false, "Cannot determine item type";
        end
        
        -- Finde schlechtestes ausgerüstetes Item basierend auf Typ
        local equippedItemLevel = nil;
        local slotDesc = "";
        
        -- ============================================================
        -- WAFFEN: MainHand (16) + OffHand (17) → schlechtestes
        -- ============================================================
        if baseEqType == "INVTYPE_WEAPON" or baseEqType == "INVTYPE_MAINHAND" or 
           baseEqType == "INVTYPE_OFFHAND" or baseEqType == "INVTYPE_2HWEAPON" then
            local mhLink = GetInventoryItemLink("player", 16);
            local ohLink = GetInventoryItemLink("player", 17);
            local mhLevel = mhLink and select(4, GetItemInfo(mhLink)) or 0;
            local ohLevel = ohLink and select(4, GetItemInfo(ohLink)) or 0;
            equippedItemLevel = math.min(mhLevel, ohLevel);
            if equippedItemLevel == 0 then equippedItemLevel = math.max(mhLevel, ohLevel); end
            slotDesc = "Weapon";
        
        -- ============================================================
        -- TRINKETS: Trinket1 (13) + Trinket2 (14) → schlechtestes
        -- ============================================================
        elseif baseEqType == "INVTYPE_TRINKET" then
            local t1Link = GetInventoryItemLink("player", 13);
            local t2Link = GetInventoryItemLink("player", 14);
            local t1Level = t1Link and select(4, GetItemInfo(t1Link)) or 0;
            local t2Level = t2Link and select(4, GetItemInfo(t2Link)) or 0;
            equippedItemLevel = math.min(t1Level, t2Level);
            if equippedItemLevel == 0 then equippedItemLevel = math.max(t1Level, t2Level); end
            slotDesc = "Trinket";
        
        -- ============================================================
        -- RINGE: Finger1 (11) + Finger2 (12) → schlechtestes
        -- ============================================================
        elseif baseEqType == "INVTYPE_FINGER" then
            local f1Link = GetInventoryItemLink("player", 11);
            local f2Link = GetInventoryItemLink("player", 12);
            local f1Level = f1Link and select(4, GetItemInfo(f1Link)) or 0;
            local f2Level = f2Link and select(4, GetItemInfo(f2Link)) or 0;
            equippedItemLevel = math.min(f1Level, f2Level);
            if equippedItemLevel == 0 then equippedItemLevel = math.max(f1Level, f2Level); end
            slotDesc = "Ring";
        
        -- ============================================================
        -- RÜSTUNG: Auto-Slot-Mapping
        -- ============================================================
        else
            local slotMap = {
                INVTYPE_HEAD = 1,
                INVTYPE_NECK = 2,
                INVTYPE_SHOULDER = 3,
                INVTYPE_CHEST = 5,
                INVTYPE_WAIST = 6,
                INVTYPE_LEGS = 7,
                INVTYPE_FEET = 8,
                INVTYPE_WRIST = 9,
                INVTYPE_HAND = 10,
                INVTYPE_BACK = 15
            };
            
            local slot = slotMap[baseEqType];
            if slot then
                local eqLink = GetInventoryItemLink("player", slot);
                equippedItemLevel = eqLink and select(4, GetItemInfo(eqLink)) or 0;
                slotDesc = baseEqType:gsub("INVTYPE_", "");
            else
                return false, "Unsupported item type: " .. baseEqType;
            end
        end
        
        if not equippedItemLevel or equippedItemLevel == 0 then
            return false, "No equipped item in matching slot";
        end
        
        -- Vergleiche: itemLevel OP (equippedItemLevel + value)
        local compareValue = equippedItemLevel + condition.Value;
        local result = equalityOperator.Func[condition.Operator](itemLevel, compareValue);
        
        local opText = equalityOperator.List[condition.Operator];
        local sign = condition.Value >= 0 and "+" or "";
        
        return result, "Item Level " .. itemLevel .. " " .. opText .. " Equipped " .. 
                      equippedItemLevel .. " (" .. sign .. condition.Value .. ") [" .. slotDesc .. "]";
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
        elseif condition.CriteriaType == criteriaType.Enum.VendorPrice then
            return VendorPrice_Func(itemInfo.VendorPrice, condition);
        elseif condition.CriteriaType == criteriaType.Enum.TransmogKnown then
            return TransmogKnown_Func(itemInfo.Link, itemInfo.Bag, itemInfo.Slot, condition);
        elseif condition.CriteriaType == criteriaType.Enum.ItemLevelVsEquipped then
            return ItemLevelVsEquipped_Func(itemInfo.Link, condition);
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
        
        -- Die Setter speichern alles in condition.Value (Copper-Gesamtwert)
        local value = condition.Value or 0;
        
        if value == 0 then
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
            return true, "";
        elseif condition.CriteriaType == criteriaType.Enum.InventoryType then
            if condition.NumSelectedInventoryTypes == 0 then
                return false, addon.L["At least one inventory type must be selected"];
            end
            return true, "";
        -- ← NEU:
        elseif condition.CriteriaType == criteriaType.Enum.VendorPrice then
            local isValid, text = VendorPrice_IsValid(condition)
            return isValid, desc .. text;
        elseif condition.CriteriaType == criteriaType.Enum.TransmogKnown then
            if not condition.TransmogStatus then
                return false, addon.L["At least one transmog status must be selected"];
            end
            return true, "";
        elseif condition.CriteriaType == criteriaType.Enum.ItemLevelVsEquipped then
            local isValid, text = VendorPrice_IsValid(condition);  -- Benutze gleiche Validation wie VendorPrice (Op + Value)
            return isValid, text;
        end
    end
end