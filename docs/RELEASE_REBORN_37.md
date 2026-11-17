# Azeroth FieldKit Reborn .37 — Clear previews and native encounter tracking

Candidate release notes; publication pending final validation.

- **Preview screen repaired:** single text per sample, separated cards, clear boss health/debuffs and accessible controls. Placement examples avoid the toolbar and combat-text handles. Finishing restores the themed HUD; individual boss/health tests open the correct examples.
- **Endless tracking:** read the game's next-encounter state, countdown and stable number. Names stay unknown until supplied by the game. Active bosses show their native identity. Timers freeze while paused and do not masquerade as charge percentages.
- **Consistent boss information:** shared by the header, campaign boss list, reminders, Lairs and unthemed progression card. Rift-driven encounters still use the native percentage. Optional arrival warnings follow the native mechanism.
- **Live stat caps:** shared Statistics tooltips show the caps supplied for the current hero, including the distinct cooldown-reduction and haste caps. Missing values stay absent.
- **Long Endless meters:** retain very large native damage/healing amounts and checkpoint differences as Lua doubles; compact scientific notation keeps their labels short.
- **Fourteen languages retained:** updated help explains progress versus timed arrivals. Existing profiles, layouts and language choices are preserved.

Requires the public Reborn API shipped by the game; verified against the official 0.6.9 distribution. Unsupported crystal positions, spell-upgrade breakdowns, extended encounter/ground-warning feeds and healing/proc/death-summary extensions are not advertised as available. Existing supported debuffs, native castbar, notifications and death-log access remain intact.

Automated checks cover runtime/persistence, 1,008 setting setters, locale formats/fonts, next-encounter states/clocks, themed/unthemed readers, live cap replacement, installed public API, recent windows and large checkpoint totals. These fixtures do not certify live co-op transport or a complete Endless playthrough. See REBORN_ACCEPTANCE.txt for scoped native inspection.
