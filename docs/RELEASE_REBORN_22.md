FieldKit Reborn 0.1.0-reborn.22

Native spell descriptions already contain current effect values without a heading named Bonus. FieldKit now shows compact values in the loadout card and retains the current native description on hover when explicit bonus sections are absent. That hover also includes the same sampled hits, crits, maximum hits/crits, average and burst statistics as the action-bar tooltip, following the existing combat-tooltip preference.

The native amulet rank is displayed in both themed and unthemed accessory cards and tooltips. The client uses amount as a rank for amulets only; ring/trinket amounts are stat values, so FieldKit does not fabricate ranks from them. An explicit rank field is accepted when supplied.

Regression reproduces the reported French tooltip (9 targets, 35 m, 5364 damage, 0.9 s) with no Bonus heading, preserves English yards without conversion, checks exact cadence precision, live value/rank refresh, native tooltip/stat reuse and themed ranks. Full runtime/settings/theme and installed 0.6.5 public API/content fixtures are checked. No new live client pass is claimed.
