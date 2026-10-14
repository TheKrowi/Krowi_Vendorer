# Plan: Vendorer breaks on WoW 12.1.5
Spec: [spec.md](spec.md). Status: accepted

## Files that change
- `Objects/ItemType.lua`: `GetItemClassInfo` and `GetItemSubClassInfo` become `C_Item.GetItemClassInfo` and `C_Item.GetItemSubClassInfo` (lines 32, 39; the commented-out lines 13 and 18 stay as they are).
- `Globals.lua`: `GetItemInfo` (5, 41), `GetItemQualityColor` (6) and `IsCosmeticItem` (53) get the `C_Item.` prefix.
- `GUI/AutoSellListFrame/AutoSellListFrameMixin.lua` (219, 230, 255, 256), `GUI/JunkListFrame/JunkListFrameMixin.lua` (29, 30, 37), `GUI/IgnoreListFrame/IgnoreListFrameMixin.lua` (33, 34, 41), `GUI/ItemTooltip/ItemTooltip.lua` (109, 157), `Data/AutoJunk.lua` (46, 51): `GetItemInfo` and `GetItemInfoInstant` get the `C_Item.` prefix. The commented-out calls in `ItemTooltip.lua` (33, 41) stay.
- `_Packaging/Changelog.md`: a `## 0.30` entry with one `### Fixed` line.

Routine plan: a one-to-one rename to the functions the removed globals were aliases of; no hooks, protected actions, saved variables or frames change.

## Order of work
1. Reproduction: recorded in `spec.md` (BugGrabber entries) and `Find-DeprecatedApi.ps1` red on `dev` (done, kit `c451d14`).
2. Rename the 20 calls in the seven files above. The plugin hook syntax-checks each edit.
3. `Find-DeprecatedApi.ps1`: no `removed` use left.
4. Changelog line.
5. `krowi:taint-reviewer` and `/code-review` on the diff.
6. In game (Retail): `Deploy.ps1 -WhatIf` from the worktree, tell Krowi what it replaces and deploy with their approval (another Vendorer session is open), `/reload`, merchant check, `/reload`, `Read-GameErrors.ps1`.
7. Work files to `done`, push, PR against `dev`.

## Risks
- A missed call site: step 3 is tree-wide, not limited to the diff.
- A deploy from the worktree wiped by fsdeploy when the main checkout's VS Code window saves a file: ask Krowi not to save there until the in-game check is done.
- The in-game check passing on a stale install: `-WhatIf` first, and the error counters compared with the 2026-10-14 entries (x1 and x70).

## Proof
- `Find-DeprecatedApi.ps1` prints `No uses found.` without `-IncludeLibs`, or only the deferred AceGUI `deprecated` lines with it.
- `Read-GameErrors.ps1` after the second `/reload`: no Vendorer row newer than the deploy, and the `ItemType.lua:32` and `Globals.lua:41` rows still at x1 and x70.
- Krowi sees the auto-sell list fill at a merchant, the Vendorer pages in Settings and the minimap or compartment icon.