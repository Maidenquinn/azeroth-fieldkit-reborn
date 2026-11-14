FieldKit Reborn 0.1.0-reborn.11 — client 0.6.4

Combat meter settings now include Recent damage and healing and a 5–120 second slider (every integer, default 15s). Amounts, DPS/HPS and percentages use the same native window. Titles and details identify the selected period. Other meter views retain their existing basis. Missing/warming history is shown explicitly; lifetime totals never replace a requested recent window. Full-run hit/crit samples are omitted from recent rows and drill-downs.

Jewelry bonus descriptions are split at native bullet separators. The Statistics tooltip exposes supplied g-prefixed jewelry additions, including known zero values; absent fields remain unavailable. Themed statistic rows use the same tooltip. These additions are already in character totals and are never added twice or assigned to individual items. Native DoT stacking values retain three decimals, with DoT haste and damage versus afflicted targets available in Statistics. No target stack count, chance or cap is inferred from the character stat.

Settings: /fieldkit → Interface → Combat meter. Hover the Statistics card background for the jewelry/DoT overview; hover a statistic for its jewelry addition. Show the DoT statistics using the existing Statistics selection. Recent mode is off by default and is saved separately per HUD profile.

Validation: full legacy/runtime suite; actual installed 0.6.4 public Lua executed offline for all 116 window lengths, damage/healing rates and shares, checkpoints and history recovery; both Elwynn/Naxx theme families, all three variants and themes off; production setter matrix, detached views and profile separation. No live client or multiplayer acceptance claimed.
