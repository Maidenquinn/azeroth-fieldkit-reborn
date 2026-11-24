# Paladin Consecration: critical-hit audit (.39)

Audit date: 2026-11-24. Installed game: Azeroth Survivors: Reborn **0.7.4** (`.azs/installed.json`, serial 1795141447).
Only the installed client was available: its public Lua API, its generated content tables, and the
SavedVariables that addons on the same account wrote. The Rust engine sources (`engine/benilla/crates/survivors-content`,
`survivors-sim`) are **not** on this machine. Nothing in the game was modified.

## Conclusion

**H4 confirmed (FieldKit + chat shim).** FieldKit counted every hit from the 1.12 chat lines. The game's chat shim
writes periodic damage with no critical form at all. FieldKit could therefore never see a critical Consecration tick,
whatever the engine did. The engine does crit Consecration, and the native combat-text feed delivers the flag.

| Hypothesis | Verdict | Evidence |
|---|---|---|
| H1 Consecration is `no_crit` | **Refuted by observation** | ≥ 48,549 Consecration ticks arrived with `critical == true` (below). The content reference documents `no_crit` only as a spell flag. It does not list Consecration. |
| H2 engine never rolls periodic crits | **Refuted** | Same observation. |
| H3 crit flag lost before addons | **Partly true, chat channel only** | `Shims.lua` drops the flag for periodic chat lines. `AZS_GetCombatTextEvents` keeps it. |
| H4 FieldKit parser | **Confirmed** | `MeterLedger` counted chat lines only and ignored feed hits (`PollCombatText(false)`). |
| H5 source collision | Not observed | Feed hits carry `spellId`. Rank merges and collision guards are covered by tests. |

## Evidence: installed API (read-only)

`Interface/AddOns/AzerothSurvivorsAPI/AzerothSurvivorsAPI.toc` loads `CombatText.lua` before `Shims.lua`.

- `CombatText.lua` lines 49–51 put `SPELL_PERIODIC_DAMAGE` in the damage set with `periodic = true`.
  Lines 130–132 read `critical` at the 3.3.5a position (`select(9, ...)`, then the 10th value) for both
  `SPELL_DAMAGE` and `SPELL_PERIODIC_DAMAGE`, and store `ev.critical = critical and true or false`.
- `Shims.lua` lines 398–408 (`SPELL_DAMAGE`) write `"crits"` when critical. Lines 409–419 (`SPELL_PERIODIC_DAMAGE`)
  read only `spellName, amount, school` and always write
  `"%s suffers %s %s damage from your %s."`. That line has **no critical variant**.
- `Meter.lua` (`AZS_GetMeterSnapshot`) carries totals per source. It has no hit or crit counts.

## Evidence: observed feed data (read-only)

`WTF/Account/<account>/SavedVariables/AzerothStatsReborn.lua`, around line 8277. That addon counts
`AZS_GetCombatTextEvents` events (`V2CombatObserve.lua` lines 170–182: `e.critical == true`, `e.periodic == true`).
One French Paladin run recorded:

- hits 111,562; periodic 79,694; **critical 80,417**; gaps 0; dropped 0
- sources: Consécration 79,694 hits; Flamestrike 30,266; Bouclier du vengeur 1,484; Marteau du vertueux 57; Marteau de la justice 61

Periodic hits equal Consecration hits, so every periodic event was Consecration. The non-Consecration hits total 31,868.
Even if every one of them crit, at least **80,417 − 31,868 = 48,549** Consecration ticks were reported critical.
Limits: the run's exact game build is not stored next to the summary. The proof rests on one aggregate. A direct
event capture during recipe testing (protocol below) closes it.

## Fix (FieldKit only)

- `MeterLedger.lua`: when `AZS_GetCombatTextEvents` exists, the feed is the **only** hit/crit source and chat damage
  lines are ignored (no merge, so nothing is counted twice). The chat parser is now only a fallback for clients without
  the feed. Death lines drain the feed first, so a kill goes to the blow that actually landed last.
- Every feed page is read (≤ 8 × 256 per poll). The cursor survives a book reset. Forward `seq` jumps or a
  `droppedCount` add to `FieldKitMeterLedger.feed.missed`. Lost events are counted and never invented.
- A chat periodic line without `(Critical)` is now **unclassified**, not a non-crit. `Stats().critKnown == false`
  shows the crit rate as `-` instead of `0%` (tooltip, reference HUD, party details).
- Native totals still come only from `AZS_GetMeterSnapshot`. Combat text never replaces them.

## Other .39 findings

- `Loadout.SpellEffects`: French `subit` / `subissent` (from the first .39 commit). Native English tips name the school
  (`takes 198 Frost damage every 1 sec` was observed in installed data), which `N damage` missed. Patterns now cover an
  explicit school list, so "50 % de dégâts en plus" debuffs stay excluded. The tooltip's own number is shown verbatim,
  and no rank multiplier is computed.
- `Loadout.EquippedSourceIcon`: worn items only (`AZS_GEAR`), exact name or legendary head before `:`. Ambiguous
  duplicates and items without an icon stay unknown. It is evaluated live, so a mid-run swap does not leave a stale icon.

## Report for SNX (optional, not a game bug)

The 1.12 chat shim (`Shims.lua` 409–419) cannot express a periodic critical. If 1.12-era addons should see periodic
crits, a `"(Critical)"` suffix or equivalent would be needed. This is a fidelity choice, not a defect. Current addons
should read `AZS_GetCombatTextEvents`.
