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
L["ItemLevel is not a valid item level."] = "'{itemLevel}' is not a valid item level.";

L["Auto Sell Quality Desc"] = "Taking other rules into account, if the item's quality is one of the selected qualities, sell the item.";
L["Auto Sell Item Level Desc"] = "Taking other rules into account, if the item's item level is lower than this value, sell the item.";
L["Rule x"] = "Rule {x}";
L["Condition x"] = "Condition {x}";

L["Auto Repair Is Enabled"] = "Repair all items automatically when you visit a vendor that can do it.";
L["Auto Repair Is Guild Enabled"] = "Prefer guild funds to repair, if available.";
L["Auto Repair Print Chat Message"] = "Enable to print auto repair messages in the chat.";

L["Auto Repair No Guild Funds Use Personal"] = "[KV] Not enough guild funds to repair, trying personal funds.";
L["Auto Repair No Personal"] = "[KV] Not enough personal funds to repair.";
L["Auto Repair Repaired"] = "[KV] Repaired {g}g {s}s {c}c.";