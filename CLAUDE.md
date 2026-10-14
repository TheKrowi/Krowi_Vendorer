# CLAUDE.md

Krowi's Vendorer (prefix `KrowiV`, acronym `KV`) is a World of Warcraft addon in Lua 5.1 + WoW XML that adds to the merchant frame: an auto-sell list driven by user rules, a junk list, an ignore list and auto-repair. The workspace-wide rules (tooling traps, the game loop, taint, git, release safety, how Krowi wants choices presented) load from `../CLAUDE.md` and `Krowi_ClaudeKit/WowAddons.md`; this file adds only what is specific to this repo.

There is no build, lint or test step: the game is the test harness. The `krowi` plugin (enabled in `.claude/settings.json`) syntax-checks every edited `.lua` with Lua 5.1 and guards the known tooling traps. The repo is public, but `.claude/settings.json` points at the private kit by absolute path, so the plugin loads only on Krowi's machine; that is intended.

## Clients and loading

- One TOC, `Krowi_Vendorer.toc`, Retail only: `## Interface: 120001, 110207`. No Classic support.
- `## LoadWith: Blizzard_MerchantFrame`; saved variables `KrowiV_Options, KrowiV_SavedData` (account-wide). A new saved variable must be added to that line or it is lost on logout.
- Load order is the TOC: `Libs\Files.xml` (submodules, then bundled Ace libs, then `Libs.lua`), `API.lua`, `Plugins\Files.xml`, `Localization\Files.xml`, `Krowi_Vendorer.lua`, `Globals.lua`, `Objects\Files.xml`, `Options\Files.xml`, `Libs\Krowi_Util\Icon.lua`, `Icon.lua`, `Data\Files.xml`, `GUI\Files.xml`. A file only sees what earlier files defined, and a new `.lua` must be listed in its folder's `Files.xml` or it never loads.
- Boot is a single `ADDON_LOADED` for `Krowi_Vendorer` in `Krowi_Vendorer.lua`: `Objects.ItemType.Load()`, then `addon.Options:Load()` (AceDB, then each options page's `RegisterOptionsTable` and `PostLoad`), then the `KrowiV_SavedData` tables, `addon.Icon:Load()`, `addon.GUI.ItemTooltip.Load()`. The other events it registers do nothing. `MERCHANT_SHOW` is handled only by `Data/AutoRepair.lua`.

## Libraries

- Submodules under `Libs/`: `Krowi_Util`, `Krowi_Menu`, `Krowi_PopupDialog` (develop and release them in `../Krowi_Libraries/<lib>`, never here). Bundled, not submodules: AceConfig, AceDB, AceDBOptions, AceGUI, CallbackHandler, LibDataBroker, LibDBIcon. LibStub and AceLocale come from Krowi_Util.
- `Libs/Libs.lua` calls `KROWI_LIBMAN:NewAddon(...)`, which sets `addon.Util` (Krowi_Util_2), `addon.Metadata` (TOC fields) and `addon.Localization`. Krowi_Util files loaded into this addon's namespace also set `addon.InjectOptions`, `addon.Options` and `addon.Icon`. Krowi_Menu is loaded but unused; `addon.MenuBuilder` is never set.

## Architecture

- `Objects/`: enums and value objects built with `addon.Util.Enum2{...}` (Scope, InstanceType, EqualityOperator, ItemQuality, InventoryType, ItemType, CriteriaType) and `AutoSellRule` (create, modify and validate functions for plain rule tables).
- **Rules are plain tables in saved variables**, never objects (`Objects/AutoSellRule.lua`): account rules in `KrowiV_SavedData.Rules`, character rules in `KrowiV_SavedData.Characters[UnitGUID("player")].Rules`. A rule is `{Guid, Name, IsPreset, IsDisabled, IsInvalid, ItemTypes[], Conditions[]}`; criteria are ItemLevel, Soulbound, Quality and InventoryType (`Objects/CriteriaType.lua`). Presets (Junk, Artifact Relic, Unusable Equipment) are made in `Options/AutoSell.lua` `PostLoad`; Unusable Equipment is rebuilt and force-enabled on every load from `Data/AutoSell.lua`'s class matrix.
- Evaluation (`Data/AutoSell.lua`): a rule matches when its item type matches and every condition passes; an item is sold when any account or character rule matches. The sell list (`GUI/AutoSellListFrame/AutoSellListFrameMixin.lua`) scans the bags, skips `IgnoredItems`, always includes `JunkItems`, and applies the rules otherwise.
- Selling is started only by the player (the Sell All / Sell 12 buttons, or a click on a row): rounds of up to 5 `C_Container.UseContainerItem` calls, re-evaluated every 0.2 s by `C_Timer.After`; unsellable items go through confirmation popups that destroy them.
- Auto-repair (`Data/AutoRepair.lua`) is a coroutine: guild funds first, personal funds when the guild bank cannot pay.
- `GUI/MerchantFrame/MerchantFrame.lua` reshapes Blizzard's merchant frame: `hooksecurefunc` on `MerchantFrame_UpdateMerchantInfo`, `MerchantFrame_UpdateBuybackInfo` and `MerchantFrame:Show`, two extra tabs (`MerchantFrameTab3`/`4`, bumping `MerchantFrame.numTabs`), frame resizing and embedded junk/ignore lists. It yields to Krowi's Extended Vendor UI when `KrowiEVU_MerchantItemsContainer` exists.
- `Options/`: AceConfig pages in Blizzard Settings (Krowi's Vendorer, Auto Sell, Auto Repair, Profiles). `KrowiV_Options` is an AceDB with defaults in `Options/Defaults.lua`; `KrowiV_SavedData` is a raw global with no versioned migrations.

## Taint-sensitive areas

Everything in `GUI/MerchantFrame/`, the sell and destroy loop, `SettingsPanel:SetAttribute` around `OpenAllBags` in `Options/AutoSell.lua`, and the item tooltip post-call touch Blizzard frames or protected actions. Run the `krowi:taint-reviewer` agent after changing any of them. Existing debt there: accidental globals `StartEventDrivenSellLoop`, `ProcessDestroyQueue`, `TriggerSellRound` and `EvaluateSellRound` in `AutoSellListFrameMixin.lua`, and the unprefixed popup keys `CONFIRM_CURSOR_CLEAR` and `CONFIRM_DESTROY_ITEM`; addon code calls `MerchantFrame_UpdateMerchantInfo()` itself.

## Localization

`Localization/enUS.lua`, `deDE.lua` (empty) and `Shared.lua`. In `enUS.lua` the code is above the `AUTOGENTOKEN` marker (line 4) and the CurseForge export below it; 0.29 appended its new string at the end of the file. New strings go below the marker; ask Krowi whether they should also be added on the CurseForge localization page. `Shared.lua` aliases Blizzard global strings and finally sets `addon.L`.

## Code style

Match the file you are editing; this repo's style is older than Krowi_AchievementFilter's and must not be converted to it:

- 4-space indentation (except `GUI/MerchantFrame/MerchantFrame.lua`, which uses tabs, and the mixed `API.lua`).
- Statements end with `;` in the older files (`Krowi_Vendorer.lua`, `Options/`, `Objects/`, `GUI/`); the localization files and the Krowi_Util code do not.
- Double quotes, except `Localization/Shared.lua` (single quotes).
- Line 1 is `-- [[ Namespaces ]] --`, then `local _, addon = ...;`. Sections use `do -- [[ Name ]]` blocks.
- Module tables are PascalCase on `addon.*` with a camelCase local alias; functions PascalCase, locals camelCase; globals, mixins and templates `KrowiV_<Name>`.
- CRLF on disk (LF in git, `core.autocrlf=true`), no BOM, no final newline. `.vscode/settings.json` lists the globals the Lua language server accepts. The Ketho WoW API extension writes the `Lua.runtime.*` and `Lua.workspace.library` keys there and adds or prunes WoW API globals itself, so add only addon and library globals by hand.
- Do not restyle lines you are not otherwise changing.

## Testing in game

`.vscode/settings.json` fsdeploys on every save to `_retail_` and `_ptr_` (`deployWorkspaceOnSave`). Before an in-game check, run the kit's `Deploy.ps1 -WhatIf` and deploy, then `/reload` and `Read-GameErrors.ps1` (see `WowAddons.md`, Closing the loop with the game). Open a merchant to exercise everything; selling and destroying are real actions, so test with junk.

## Git and release

- `dev` is the integration branch: releases 0.24 to 0.28 were cut on `dev` and merged to `main` through PRs. 0.29 was committed directly on `main`; `dev` was fast-forwarded to it on 2026-10-14. Branch new work from `dev`.
- `_Packaging/Changelog.md` has no 0.29 entry although the TOC and tag are at 0.29; the next release needs the 0.29 changes listed (TOC interface bump, library updates, one new string).
- Release only with the plugin's `krowi:release` skill. Its preflight detects the release branch from the last `Release` commit (`main` right now); confirm the branch with Krowi before packaging.
- Branches `master`, `new-rules-window` (unmerged, 2023) and `10-auto-repair-when-visiting-vendor` (merged) are old.

## Known debt (verified 2026-10-14)

- The item tooltip registers only when `addon.IsDragonflightRetail` (major version 10), so it never runs on 11.x or 12.x (`GUI/ItemTooltip/ItemTooltip.lua:194`).
- The sell loop handles `BAG_UPDATE_DELAYED` but never registers it, so only the 0.2 s timer drives it; `itemsToSell` is the data provider's own collection, which `RemoveListItem` changes during the first round.
- `JunkListFrameMixin.lua` and `IgnoreListFrameMixin.lua` keep one file-level `frame` that every frame's `OnLoad` overwrites.
- `README.md` and `_Packaging/Description.md` advertise an "Item name" criterion that does not exist.
- `Options/AutoJunk.lua` is loaded (`Options/Files.xml`) but is an empty stub: its options table is commented out and `RegisterOptionsTable` and `PostLoad` do nothing.
- Not loaded by any manifest: `Data/AutoJunk.lua`, `GUI/MerchantItemsContainer.lua`, `GUI/OptionsButton/`. Several locale keys used in code are missing from `enUS.lua`.