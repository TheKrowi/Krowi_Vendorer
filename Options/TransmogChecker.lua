--[[
    TransmogChecker für Krowi_Vendorer
    
    Prüft ob ein Item noch Transmog-Appearances bietet die nicht gelernt sind.
    Kann standalone funktionieren ODER CanIMogIt nutzen wenn vorhanden.
    
    Vorteile Standalone:
    - Unabhängig von CanIMogIt
    - ~120 Zeilen statt 1319
    - Keine Exception-Listen nötig (conservative: "im Zweifelsfall nicht verkaufen")
    - Bessere Performance
    
    Nachteil:
    - Weniger robust gegen Blizzard-Änderungen
    - Keine komplexe Armor-Type-Validierung
]]

local _, addon = ...

addon.TransmogChecker = {}
local checker = addon.TransmogChecker

-- ============================================================
-- Konfiguration
-- ============================================================

-- Falls Blizzard APIs ändern/removed werden, graceful fallback
local ENABLE_FALLBACK_TO_CANIMOGIT = true

-- ============================================================
-- Standalone Implementierung
-- ============================================================

local function GetSourceIDFromLink(itemLink)
    -- Extrahiert sourceID aus dem Item-Link oder via C_TransmogCollection API
    if not itemLink then return nil end
    
    local sourceID = select(2, C_TransmogCollection.GetItemInfo(itemLink))
    if sourceID then
        return sourceID
    end
    
    -- Fallback: nil
    return nil
end

local function IsItemEnsemble(itemID)
    -- Prüft ob das Item ein Ensemble (Sammlung) ist
    if not itemID then return false end
    if not C_Item.GetItemLearnTransmogSet then return false end
    
    local setID = C_Item.GetItemLearnTransmogSet(itemID)
    return setID ~= nil
end

local function PlayerHasSourceLearned(sourceID)
    -- Prüft ob eine Source-ID (Appearance) bereits gelernt ist
    if not sourceID then return false end
    if not C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance then
        return false
    end
    
    return C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceID)
end

local function EnsembleHasUnlearnedAppearance(itemID)
    -- Prüft ob ein Ensemble mindestens eine ungelernte Appearance hat
    if not itemID then return false end
    if not C_Item.GetItemLearnTransmogSet then return false end
    if not C_Transmog.GetAllSetAppearancesByID then return false end
    
    local setID = C_Item.GetItemLearnTransmogSet(itemID)
    if not setID then return false end
    
    local setSources = C_Transmog.GetAllSetAppearancesByID(setID)
    if not setSources or #setSources == 0 then return false end
    
    -- Iteriere durch alle Sources im Ensemble
    for _, source in ipairs(setSources) do
        local sourceID = source.itemModifiedAppearanceID
        if sourceID and not PlayerHasSourceLearned(sourceID) then
            return true  -- Mindestens eine ungelern gefunden!
        end
    end
    
    return false  -- Alle gelernt
end

-- ============================================================
-- Hauptfunktion: HasUnlearnedTransmog
-- ============================================================

function checker:HasUnlearnedTransmog(itemLink)
    --[[
        Prüft ob ein Item noch ungelernte Transmog-Appearances bietet.
        
        Returns: (hasUnlearned, statusText, source)
        - hasUnlearned: boolean - true wenn noch ungelernte Appearances vorhanden
        - statusText: string - Beschreibung für Debug
        - source: string - "standalone" oder "CanIMogIt"
    ]]
    
    if not itemLink then
        return false, "Invalid item link", "none"
    end
    
    -- ============================================================
    -- Option 1: CanIMogIt vorhanden → nutzen (robuster)
    -- ============================================================
    if ENABLE_FALLBACK_TO_CANIMOGIT and CanIMogIt and CanIMogIt.CalculateTooltipText then
        local ok, text, unmodifiedText = pcall(
            CanIMogIt.CalculateTooltipText, CanIMogIt, itemLink
        )
        
        if ok and unmodifiedText then
            local hasUnlearned = (
                unmodifiedText == CanIMogIt.UNKNOWN or
                unmodifiedText == CanIMogIt.PARTIAL
            )
            local statusText
            if unmodifiedText == CanIMogIt.UNKNOWN then
                statusText = "Not yet learned (CanIMogIt)"
            elseif unmodifiedText == CanIMogIt.PARTIAL then
                statusText = "Partially learned (CanIMogIt)"
            else
                statusText = "Already known (CanIMogIt)"
            end
            
            return hasUnlearned, statusText, "CanIMogIt"
        end
    end
    
    -- ============================================================
    -- Option 2: Standalone Implementierung (Fallback)
    -- ============================================================
    
    local itemID = addon.GetItemID(itemLink)  -- Nutzt bestehende Util-Funktion
    if not itemID then
        return false, "Could not determine itemID", "standalone"
    end
    
    -- Spezialfall: Ensemble/Sammlung
    if IsItemEnsemble(itemID) then
        local hasUnlearned = EnsembleHasUnlearnedAppearance(itemID)
        if hasUnlearned then
            return true, "Ensemble with unlearned appearances", "standalone"
        else
            return false, "All ensemble appearances known", "standalone"
        end
    end
    
    -- Normales Item: prüfe Source-ID
    local sourceID = GetSourceIDFromLink(itemLink)
    
    -- Falls keine sourceID → kein Transmog-Item
    if not sourceID then
        return false, "Not a transmog item", "standalone"
    end
    
    -- Ist die Source gelernt?
    local hasLearned = PlayerHasSourceLearned(sourceID)
    
    if not hasLearned then
        return true, "Appearance not yet learned", "standalone"
    else
        return false, "Appearance already learned", "standalone"
    end
end

-- ============================================================
-- Convenience-Wrapper für Krowi_Vendorer Integration
-- ============================================================

function checker:GetConditionResult(itemLink, bag, slot)
    --[[
        Wrapper für CriteriaType.Func Format
        
        Returns: (result, statusText)
        - result: boolean - true wenn item KEINE neuen Transmogs hat (can sell)
        - statusText: string - Debug-Information
    ]]
    
    local hasUnlearned, statusText, source = self:HasUnlearnedTransmog(itemLink)
    
    -- Invert: "Transmog Known" condition
    -- hasUnlearned=true → result=false (don't sell)
    -- hasUnlearned=false → result=true (can sell)
    local result = not hasUnlearned
    
    return result, statusText .. " (" .. source .. ")"
end
