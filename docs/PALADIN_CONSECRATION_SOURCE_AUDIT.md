# Paladin Consecration — engine-source audit request (.39)

## What is confirmed from FieldKit source
- `Loadout.SpellEffects` previously missed French `subit N dégâts` periodic descriptions, while extracting range, duration and cadence.
- `MeterLedger.NoteHit` does **not** fabricate critical hits. It records the combat-log / combat-text `critical` flag as supplied; `maxCrit` is only populated for observed critical events.
- `MeterLedger.RowsFromSnap` obtains total damage from the native game snapshot and can receive an absent/unready `source.icon`. `Loadout.Icon` previously only indexed learned spells, not actual equipped jewelry.
- Screenshots of Consecration at rank 40 show 69,330 hits with 0 crits, despite a character stat of 100% crit. This does not prove a gameplay bug.

## Official public documentation consulted
- https://azreborn.com/guides/addon-api — describes `AZS_GetCombatTextEvents(cursor, limit)` and its `critical`, `periodic`, `spellId`, `abilityName`, `meterSource` fields.
- https://azreborn.com/guides/content-reference — documents `no_crit = true` for spells and the periodic damage code paths; its documented use does **not** establish that Consecration uses the flag.
- https://azreborn.com/guides/data-api — publishes spell and legendary *icons*, but omits full spell descriptions and `no_crit`.

## Source audit for a developer or local Claude/Codex agent with a lawful checkout
Use the *exact installed game revision/profile* (not generic WoW or a different Azeroth Survivors fork). Do not change game sources. Read only.

1. Find Consecration's spell key and 3.3.5a spell ID in `crates/survivors-content/packs/**` or equivalent profile overlays. Record source file, line, pack version, shape (`ground` / `totem` / DoT), and the exact `no_crit` value or absence. Follow overrides/mods to the effective final spell definition.
2. Trace damage production through `survivors-sim` ground-field/totem/DoT tick and crit logic (including `Run::tick_dots`, field ticks, damage modifiers). Determine *whether* Consecration's hits roll critical damage, and under what conditions. Quote minimal line references, do not assume all periodic damage crits.
3. Trace server combat-log forwarding and client adapter at `ui/AddOns/AzerothSurvivorsAPI/CombatText.lua` and `Shims.lua`. Check that `critical` is true exactly when the damage event crits, and that `CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE` encodes periodic criticals in text the ledger recognizes.
4. Inspect `AZS_GetMeterSnapshot` source descriptors for `ability:consecration` and amulet `jewel:amulet`: verify `source.icon.status`, `source.icon.path`, `spellIds` and whether missing icons are designed as unavailable. Compare the equipped `AZSGEAR` icon.
5. If a bug is suspected in *game* rather than addon, reproduce in the game's test environment with a fixed RNG seed; verify crit chance and critical flag; create a minimal developer issue rather than altering player stats in an addon.

## Read-only live observation requested (not automatically collected)
In a short solo run, record: player crit chance and cap, Consecration rank/tooltip, 100 consecutive *raw combat events* with `abilityName` / `spellId` / `periodic` / `critical`, and matching native meter totals. Do not log character names, other players or account identifiers; do not upload full chat logs. A `critical=false` event is an observed event, not proof of the source rule.

## Acceptance criteria
- Correct and non-duplicated per-hit record attribution.
- Display the authoritative critical count (including zero); never force crits from the character stat.
- Periodic tooltip shows the original number verbatim, with unchanged range and cadence.
- Equipped amulet meter icon derived from the *actual native equipment record*; unknown/unrelated sources stay unknown, never assigned a guessed icon.
- Lua 5.1 fixtures and CI pass; manual client recipe remains required.
