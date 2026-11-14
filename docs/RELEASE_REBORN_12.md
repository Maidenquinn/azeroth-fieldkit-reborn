FieldKit Reborn 0.1.0-reborn.12 — client 0.6.4

Without an illustrated theme, FieldKit now owns only the native elements that its visible cards replace. This removes duplicate resource counters, jewelry, combat meters, boss progression and represented boss/target health. Ordinary targets and bosses outside the replacement pool retain their native health display. Disabling a replacement restores its original native presentation, including a previously disabled native meter. The native spell bar and Divine Steed remain available.

The unthemed counters include event currency, including zero, with evenly spaced icon/value cells. The existing victims option controls the kills cell. An elapsed run clock remains visible even when the optional boss progression card is disabled, and follows the native frozen time when paused. Boss progression stays based on rift percentage, with no estimated spawn countdown.

Default FieldKit cards use Reborn's native dark tooltip border when Azeroth Survivors UI is loaded, or the stock tooltip border otherwise, with the native outlined font. Illustrated theme materials remain separate. Old Chronicle grain and seals are removed from the unthemed default boss/progression cards.

Validation: offline ownership/restore tests, late native frames, resource/candy zero/removal, target instance identity, paused time, saved restoration, both theme families and all variants, production settings matrix, plus existing 0.6.4 recent damage/healing and jewelry/DoT suites using the installed public API. No live game or multiplayer validation for this build. Restart the client to load the added Lua module; no SavedVariables changes are required.
