# Intent: Vendorer breaks on WoW 12.1.5
Author: Krowi (maintainer), from their own in-game errors. Source: in-game error (BugGrabber, Retail, 2026-10-14). Status: accepted

## Problem
Since WoW 12.1.5, Vendorer errors on Retail. One error fires once at login, inside the addon's load (`Objects/ItemType.lua:32: attempt to call a nil value`), and another fires for every bag item each time the auto-sell list fills at a merchant (`Globals.lua:41: attempt to call a nil value`, 70 times in one session). Players get error popups, the auto-sell list stays empty, and whatever the addon sets up after the failing line at login is missing.

## Proposed outcome
On 12.1.5 Vendorer loads without errors and the merchant's auto-sell, junk and ignore lists work as on 12.1.0.

## Affected users and systems
Every Retail player on 12.1.5 (the only client the TOC targets). Involved: the addon's load, the options pages, the minimap and compartment icon, the auto-sell presets, the auto-sell, junk and ignore lists at the merchant, and the item tooltip code.

## Constraints
No change to rule evaluation, selling, saved variables or the merchant frame layout. Must keep working on the 11.2.7 interface the TOC also lists.

## Open questions
None.