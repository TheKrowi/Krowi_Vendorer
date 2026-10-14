# Spec: Vendorer breaks on WoW 12.1.5
Intent: [intent.md](intent.md). Status: done

## Requirements
1. Vendorer reads no Blizzard global that 12.1.5 removed: `Find-DeprecatedApi.ps1` reports no `removed` use outside `Libs/`.
2. After a `/reload` on Retail 12.1.5, `Read-GameErrors.ps1` shows no new Vendorer error and no bumped count on the two errors below.
3. At a merchant, the auto-sell list fills, and right-click ignore, the junk list and the ignore list still work.
4. Behaviour is otherwise unchanged: every replacement is the function the removed global pointed to.
5. The TOC lists the live client: `## Interface: 120105` (added at the follow-up gate, see Decision).

## Root cause
12.1.5 deleted `Blizzard_DeprecatedItemScript` together with nine other deprecation addons (present in `wow-ui-source\ptr` at 12.1.0 (69587), absent in `wow-ui-source\live` at 12.1.5 (70391)). Its `Deprecated_ItemScript.lua:9-54` was a list of plain aliases, such as `GetItemInfo = C_Item.GetItemInfo;`, which loaded only while the `loadDeprecationFallbacks` CVar was on (line 4). Vendorer still called six of those names, 20 times in seven files:

- `Objects/ItemType.lua:32,39`: `GetItemClassInfo`, `GetItemSubClassInfo`, called from the `ADDON_LOADED` handler (`Krowi_Vendorer.lua:29`). The error ends the handler, so `Krowi_Vendorer.lua:31-39` never run: no AceDB options (`addon.Options:Load()`, which also builds the auto-sell presets), no `KrowiV_SavedData` table defaults, no icon, no tooltip registration.
- `Globals.lua:5,6,41,53`: `GetItemInfo`, `GetItemQualityColor`, `IsCosmeticItem`. Line 41 runs for every bag item through `AutoSellListFrameMixin.lua:224` in an `Item:ContinueOnItemLoad` callback, hence the 70 repeats.
- `GUI/AutoSellListFrame/AutoSellListFrameMixin.lua:219,230,255,256`, `GUI/JunkListFrame/JunkListFrameMixin.lua:29,30,37`, `GUI/IgnoreListFrame/IgnoreListFrameMixin.lua:33,34,41`: `GetItemInfo` (sell price) and `GetItemInfoInstant` (item id on the junk/ignore clicks).
- `GUI/ItemTooltip/ItemTooltip.lua:109,157` (registered only on 10.x, `ItemTooltip.lua:194`) and `Data/AutoJunk.lua:46,51` (not loaded by any `Files.xml`): same names, not reached today.

Reproduction, recorded before the fix:
- BugGrabber, Retail, 2026-10-14: `Objects/ItemType.lua:32: attempt to call a nil value` (x1, 06:52:51, from `Krowi_Vendorer.lua:29`) and `Globals.lua:41: attempt to call a nil value` (x70, last 08:45:37, from `AutoSellListFrameMixin.lua:224` via `ContinueOnItemLoad`).
- `Find-DeprecatedApi.ps1` on `dev` at `3a7aa6f`: 20 uses of 6 names in 7 files, all `removed`.

## Design
Call the `C_Item` function at every one of the 20 call sites: `C_Item.GetItemInfo`, `C_Item.GetItemInfoInstant`, `C_Item.GetItemClassInfo`, `C_Item.GetItemSubClassInfo`, `C_Item.GetItemQualityColor`, `C_Item.IsCosmeticItem`. These are the exact functions the aliases pointed to, so arguments and returns are unchanged (`Blizzard_APIDocumentationGenerated/ItemDocumentation.lua`), and they exist on both TOC interfaces (11.2.7 and 12.x). Add a changelog line under 0.30.

## Options considered
1. **Every call site (recommended, chosen).** Also covers the tooltip code and `Data/AutoJunk.lua`, which do not run today. A search for the old names comes back clean, so reviving the tooltip gate or AutoJunk later does not bring the error back.
2. **Only code that runs.** The 16 calls in the five loaded, active files. Same in-game result today; leaves four broken calls in code that would fail as soon as it is switched back on.
3. **File-local aliases** (`local GetItemInfo = C_Item.GetItemInfo;` at the top of each file). Fewer changed lines, but it keeps the old names alive in the code and hides from a reader which API is called. Not chosen.

## Areas of concern
- Taint and secret values: no Blizzard frame, hook or protected action changes; the calls are the same C functions as before (`SecretArguments = "AllowedWhenUntainted"` in the docs, unchanged). The auto-sell list file is on the repo's taint-sensitive list, so `krowi:taint-reviewer` reviews the diff.
- Clients: Retail only (`## Interface: 120001, 110207`); `C_Item` has all six functions on both. The interface numbers predated 12.1.5; requirement 5 replaces them with `120105` (11.2.7 no longer exists).
- Blizzard API changes: this is one. The other nine deleted deprecation addons are not used by Vendorer (`Find-DeprecatedApi.ps1` shows nothing else removed, and nothing deprecated outside `Libs/`).
- Other addons and skins: none; no frame changes.
- Saved variables and migrations: none. The aborted load never wrote `KrowiV_Options` or `KrowiV_SavedData`, so players' settings and lists are intact and load normally once the handler runs to the end.
- Localization: none.
- Embedded libraries: none changed. The bundled AceGUI-3.0 (`Libs/AceGUI-3.0/widgets/AceGUIWidget-EditBox.lua:24`, `AceGUIWidget-MultiLineEditBox.lua:21`) is upstream's current widget (EditBox version 29): it hooks `ChatFrameUtil.InsertLink` and reads `ChatEdit_InsertLink` only in an `elseif` for clients without it. Nothing to change.
- Player-facing text: two changelog lines under `## 0.30` in `_Packaging/Changelog.md` (the fix, and 12.1.5 support), dated on release day.

## Verification
- Permanent test: `Krowi_ClaudeKit\tools\Find-DeprecatedApi.ps1` (kit `c451d14`), red before the fix (20 removed uses), clean after.
- Plugin hooks: Lua 5.1 syntax check on every edited file.
- `krowi:taint-reviewer` and `/code-review` on the diff.
- In game, Retail 12.1.5: `Deploy.ps1 -WhatIf`, deploy, `/reload`, open a merchant with junk in the bags, check the auto-sell list fills and the options pages and minimap icon exist, `/reload` again, `Read-GameErrors.ps1` with no new Vendorer error and no bumped count.

## Decision
Option 1, every call site: chosen by Krowi on 2026-10-14 (the intent gate folded into this question).

Follow-up, 2026-10-14: after the in-game check Krowi asked to fix the other findings too. For Vendorer that is the TOC: `120105` only, chosen over `120105, 110207` (requirement 5).