Update for .22: the current numeric spell effects ARE available in AZS_SPELLTIPS and are now used by FieldKit. The per-spell request below concerns the separate upgrade attribution only; no API change is required to show the existing native effect text.

Hi! I’m adapting FieldKit to Reborn 0.6.5. After checking the official addon API guide and the shipped public Lua addons, could we expose two additional pieces of information?

1. **Per-spell upgrades/bonuses.** AZS_SPELLS provides key, spell, rank and cooldowns, while AZS_SPELLTIPS contains the full current spell description. Could an API return the learned upgrades separately from the base description, per spell key? Ideally: stat/effect key, current value and unit, additive/multiplicative semantics, and a localized display label. This would let an addon show only acquired bonuses without parsing translated prose or guessing from rank. A localized bonus-only text field would also help.

2. **Endless next-boss identity and charge.** Once AZS_SCHEDULE is empty, could the next encounter’s identity and its charge percentage be exposed explicitly, including after /reload? FieldKit can read AZS_RUN.rift when present, but nbn may be empty, so it cannot reliably name the next boss or show the following sequence. An encounter/cycle id would also prevent notifications carrying across endless cycles. If endless uses a different spawn mechanism, an explicit mechanism/charge field would avoid inferring it from timers.

Thanks! I can provide a minimal read-only addon reproduction if useful.
