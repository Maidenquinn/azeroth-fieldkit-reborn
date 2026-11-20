# Azeroth FieldKit Reborn .38 — Accurate hit records and readable combat meters

Stable maintenance release accepted by the maintainer after in-game recipe validation on 2026-11-20.

## Fixed
- Spell records no longer silently jump between abilities that use the same icon (notably Pyroclasm and Pyrotechnic Explosion).
- Exact normalized combat-log spell names and available stable spell IDs take priority over ambiguous texture aliases.
- Shared icons/IDs are treated as ambiguous instead of overwriting the previous ability attribution.
- Native meter snapshot spell IDs are forwarded for more reliable spell-to-record matching.
- Tooltips identify **Max hit (non-crit)** separately from **Max crit**. A tooltip's theoretical ability damage is not an observed record.
- The damage/meter window gains a dark contrast plate and brighter spell names and numeric columns, with less intrusive gold/blue bars. It remains readable over bright combat effects.
- The contrast plate is created once per frame; theme preferences and their existing opacity behavior are preserved.

## Compatibility and QA
- Existing profiles, SavedVariables, character progression, themes, layouts, and localized UI are retained.
- Regression fixtures cover shared icons, spell-ID resolution, critical/noncritical separation and multi-billion damage values.
- The combat log remains the source for counted individual hits; native combat-text events are not double-counted.
- Automated CI audits, runtime fixtures, locale checks and deterministic packaging must pass on the tagged source.
- The maintainer validated the recipe in the game; there is no claim of independent game-team security certification or exhaustive co-op/endless testing.

## Installation
Download `AzerothFieldKitReborn-0.1.0-reborn.38.zip` from this stable release and extract its `AzerothFieldKitReborn` folder into the game's `Interface/AddOns` folder, replacing the previous folder after making a backup. Start the game, ensure the addon is enabled, and use `/fieldkit` for settings.

Package provenance and reproducibility: `MANIFEST.json`, `SHA256SUMS.txt`, and `validation.json` are separate release attachments. Attribution and license notices remain inside the install package.
