-- [[ Namespaces ]] --
local _, addon = ...;

function addon.GetPartialItemInfo(id)
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = GetItemInfo(id);
    local hex = select(4, GetItemQualityColor(itemQuality)); -- Error here the first time we open the window, data not yet available?
    local color = CreateColorFromHexString(hex);
    return itemTexture, color, itemName;
end

local function AddCharToSavedData(playerGUID)
    if not KrowiV_SavedData.Characters then
        KrowiV_SavedData.Characters = {};
    end

    local character = KrowiV_SavedData.Characters[playerGUID];
    local rules;
    if character then
        rules = character.Rules;
    end

    KrowiV_SavedData.Characters[playerGUID] = {
        Name = (UnitFullName("player")),
        Realm = (select(2, UnitFullName("player"))),
        Class = (select(2, UnitClass("player"))),
        Faction = (UnitFactionGroup("player")),
        Rules = rules or {}
    };
end

function addon.GetCurrentCharacter()
    local playerGUID = UnitGUID("player");
    if not KrowiV_SavedData.Characters or not KrowiV_SavedData.Characters[playerGUID] then
        AddCharToSavedData(playerGUID);
    end
    return KrowiV_SavedData.Characters[playerGUID], playerGUID;
end

function addon.GetItemInfo(bag, slot, item)
    local link = item:GetItemLink();
    local _, _, _, itemLevel, _, _, _, _, _, _, sellPrice, classID, subclassID, bindType, _, _, _ = GetItemInfo(link);

    -- Händlerpreis: C_Item API ist zuverlässiger als GetItemInfo bei nicht vollständig gecachten Items
    local vendorPrice;
    local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot);
    if C_Item and C_Item.GetCurrentItemLevel and itemLocation:IsValid() then
        local itemID = item:GetItemID();
        if itemID then
            vendorPrice = select(11, GetItemInfo(itemID));  -- Über ItemID statt Link, besserer Cache-Treffer
        end
    end
    -- Fallback auf Link-basierte Abfrage, dann auf sellPrice aus erster Abfrage
    vendorPrice = vendorPrice or sellPrice;

    -- DEBUG: Auskommentieren wenn nicht mehr gebraucht
    --if vendorPrice == nil then
      --  print("[KV DEBUG] VendorPrice NIL für: " .. tostring(link));
   -- else
   --     print("[KV DEBUG] VendorPrice=" .. vendorPrice .. " für " .. tostring(link));
   -- end

    return {
        Bag = bag,
        Slot = slot,
        Link = link,
        ItemLevel = itemLevel,
        ItemTypeId = classID,
        ItemSubTypeId = subclassID,
        BindType = bindType,
        Quality = item:GetItemQuality(),
        InventoryType = item:GetInventoryType(),
        IsCosmetic = IsCosmeticItem(link),
        VendorPrice = vendorPrice,  -- bewusst KEIN "or 0" — nil bedeutet "unbekannt", nicht "kein Preis"
    };
end

-- ← Neue Helper-Funktion: Kupfer formatieren
function addon.GetCopperText(copper)
    local gold = math.floor(copper / 10000);
    local silver = math.floor((copper / 100) % 100);
    local cop = copper % 100;
    
    if gold > 0 then
        return gold .. "g " .. silver .. "s " .. cop .. "c";
    elseif silver > 0 then
        return silver .. "s " .. cop .. "c";
    else
        return cop .. "c";
    end
end