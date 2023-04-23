-- [[ Exported at 2023-04-23 09-04-34 ]] --
-- [[ This code is automatically generated as an export from ]] --
-- [[ an SQLite database and is not meant for manual edit. ]] --

-- [[ English texts by Krowi, 2023-01-20 ]] --

-- [[ Namespaces ]] --
local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "enUS", true, true);

local tab = "|T:1:8|t";
L["TAB"] = tab;

-- Load strings into the localization that are already localized by Blizzard
addon.PluginStrings.enUS.Load(L);
addon.GlobalStrings.Load(L);
addon.Plugins:LoadLocalization(L);


L["Rows first"] = "Rows first";
L["Columns first"] = "Columns first";
L["Rows"] = "Rows";
L["Columns"] = "Columns";
L["Build"] = "Build";
L["Author"] = "Author";
L["Discord"] = "Discord";
L["Discord Desc"] = "Open a popup dialog with a link to the {serverName} Discord server. Here you can post comments, reports, remarks, ideas or anything else related.";
L["CurseForge"] = "CurseForge";
L["CurseForge Desc"] = "Open a popup dialog with a link to the {addonName} {curseForge} page.";
L["Wago"] = "Wago";
L["Wago Desc"] = "Open a popup dialog with a link to the {addonName} {wago} page.";
L["WoWInterface"] = "WoWInterface";
L["WoWInterface Desc"] = "Open a popup dialog with a link to the {addonName} {woWInterface} page.";
L["Show minimap icon"] = "Show minimap icon";
L["Show minimap icon Desc"] = "Show / hide the minimap icon.";
L["Default value"] = "Default value";
L["Checked"] = "Checked";
L["Unchecked"] = "Unchecked";
L["Auto Sell"] = "Auto Sell";
L["Rules"] = "Rules";
L["Add new rule"] = "Add new rule";
L["Add new rule Desc"] = "Add a new rule. These are evaluated as OR. This means that an item will be sold if it applies to at least 1 rule.";
L["Open inventory"] = "Open inventory";
L["Open inventory Desc"] = "Opens your inventory.";
L["Open auto sell list"] = "Open auto sell list";
L["Open auto sell list Desc"] = "Open the auto sell list. Changes made to the rules will be directly visible.";
L["Delete rule"] = "Delete rule";
L["Invalid Rule"] = "This rule is not valid. Check the errors below.";
L["Item types and sub types"] = "Item types and sub types";
L["Add new item type"] = "Add new item type";
L["Add new item type Desc"] = "Add a new item type with the option to add sub types to this rule. These are evaluated as OR. This means that an item will be sold if it applies to at least 1 item type or sub type.";
L["Conditions"] = "Conditions";
L["Add new condition"] = "Add new condition";
L["Add new condition Desc"] = "Add a new condition to this rule. These are evaluated as AND. This means that an item only will be sold if it applies to all conditions.";
L["AutoJunkQualityDesc"] = "These qualities apply to all auto junk rules. If for example Epic quality and The Stockades (Classic - Dungeons) are checked, finding a Rare quality item will not be added to the junk list while an Epic item would be added to the junk list.\n\nCheck all qualities to ignore this rule.";
L["ItemLevel is not a valid item level."] = "{itemLevel}' is not a valid item level.";
L["Auto Sell Quality Desc"] = "Taking other rules into account, if the item's quality is one of the selected qualities, sell the item.";
L["Auto Sell Item Level Desc"] = "Taking other rules into account, if the item's item level is lower than this value, sell the item.";
L["Rule x"] = "Rule {x}";
L["Condition x"] = "Condition {x}";
L["Auto Repair"] = "Auto Repair";
L["Auto Repair Is Enabled"] = "Repair all items automatically when you visit a vendor that can do it.";
L["Auto Repair Is Guild Enabled"] = "Prefer guild funds to repair, if available.";
L["Auto Repair Print Chat Message"] = "Enable to print auto repair messages in the chat.";
L["Auto Repair No Guild Funds Use Personal"] = "[KV] Not enough guild funds to repair, trying personal funds.";
L["Auto Repair No Personal"] = "[KV] Not enough personal funds to repair.";
L["Auto Repair Repaired"] = "[KV] Repaired {g}g {s}s {c}c.";

