FieldKit Reborn 0.1.0-reborn.28

Adds the Campaign bosses HUD card, enabled by default and available under Interface > HUD cards. It lists the native campaign roster in index order, retaining defeated encounters and marking the active, next and upcoming bosses. Only the first due campaign boss receives the native rift charge; spawn timestamps never determine order/progress.

The card uses native-style material with themes off and the active zone material with themes on. It shares existing drag, width/height, opacity, collapse, profile, collision and reward-screen behaviour. The row pool is fixed at eight, with bounded wheel scrolling for longer native rosters. Full names/statuses remain on hover.

In endless it retains the campaign roster supplied by the game and explicitly notes that the future boss sequence is not provided. Empty or stale schedules are labelled unavailable; no future boss order or kills are fabricated. AZSBOSSES snapshots now participate in native boundary freshness checks.

Validation: Offline campaign boss-card checks: native order/states/next charge, all 48 installed map catalogs, French/English, both theme families off/minimal/complete/alternative, dimensions, drag/save/profile, collapse, bounded scrolling/frame reuse, ready/choosing/paused/dead phases, empty/stale schedule and endless completed roster. Reuses the shared card materials and native layout/collision/scale/profile system. Full runtime/settings and installed public API checks. No new live client visual test is claimed; screenshots supplied by the maintainer show the native campaign roster and lack of future endless sequence.
