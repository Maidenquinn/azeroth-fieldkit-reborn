FieldKit Reborn 0.1.0-reborn.24

The themed combat meter places the amount and rate on two explicitly separated text lines, with a readable rate font. The right column is measured against both values so DPS/HPS cannot spill into the percentage column. Single-line meter modes remain single-line.

Waiting or empty guardian lairs no longer display a distance to placeholder coordinates. A live guardian id/state and non-placeholder coordinates are required; valid live distances remain available and equal-distance order is stable.

Themed target health bars, including ordinary and elite targets, explicitly share the card strata and render above its material. Fill alpha/visibility and HP text dimensions are restored on each update after theme transitions.

Validation: regressions cover the three meter-value modes, absent/placeholder versus valid live guardian distance, and elite target HP recovery in all three Elwynn variants. Full offline/runtime/settings/theme and installed 0.6.5 public API/content checks are run. No new live client pass is claimed.
