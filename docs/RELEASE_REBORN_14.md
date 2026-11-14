FieldKit Reborn 0.1.0-reborn.14 — client 0.6.5

Updated presentation catalog: 48 zones, 240 bosses and 816 creatures, including all 60 Cataclysm scheduled bosses. Boss and seasonal icon paths are verified against readable installed archive hash tables. Deathwing's invalid native icon has a documented presentation fallback.

Jewelry tooltips preserve full native proc descriptions even when numeric bonuses are present. All 44 generated accessory definitions are exercised offline. HUD rows remain compact.

The actual native target castbar is retained when a custom frame replaces the native target, preserving its native timing/callbacks. Custom boss/target labels use Stunned, Rooted or Stun immune only if AZS_GetDebuffs supplies that name and remaining time. Missing state is not reconstructed from an assumed eight seconds. Structured control/attack-telegraph APIs remain unconfirmed; the English request is prepared in docs/DEV_REQUEST_REBORN_065.txt and has not been sent.

Open the native last-blows/killing-blow window through /fieldkit death or Interface > Combat meter > Native death log. The optional hover summary reads a guarded native compatibility table only in the dead phase; missing data remains absent. The native window remains responsible for its detailed card and icon.

Addon metadata now supplies the bundled icon and a coloured title. This does not itself publish the addon to the signed in-game registry.

Validation is offline: full legacy/runtime suite, production settings matrix, all boss/icon metadata, 0.6.4+ recent-meter contract, installed 0.6.5 generated content and Api.lua/Meter.lua/Anchors.lua/CombatText.lua, cache limits, expired world positions and projection. No live visual or co-op acceptance for this build. Restart the client to load the added module.
