-- [[ Exported at 2023-02-26 15-36-01 ]] --
-- [[ This code is automatically generated as an export from ]] --
-- [[ an SQLite database and is not meant for manual edit. ]] --

-- [[ English texts by Krowi, 2023-01-20 ]] --

-- [[ Namespaces ]] --
local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "enUS", true, true);

local tab = "|T:1:8|t";
L["TAB"] = tab;

-- Load strings into the localization that are already localized by Blizzard
addon.GlobalStrings.Load(L);


L["AutoJunkQualityDesc"] = "These qualities apply to all auto junk rules. If for example Epic quality and The Stockades (Classic - Dungeons) are checked, finding a Rare quality item will not be added to the junk list while an Epic item would be added to the junk list.\n\nCheck all qualities to ignore this rule.";