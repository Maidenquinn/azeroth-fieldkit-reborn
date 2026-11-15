FieldKit Reborn 0.1.0-reborn.31

New installations receive the maintainer-approved HUD profiles saved on 2026-11-15: profile 1 uses the Elwynn Complete theme; profile 2 uses the native-style FieldKit layout without a zone theme. Profile 1 is active initially. Both retain the approved 70 percent opacity, per-element scales, card positions/sizes and display settings. Slot 3 stays available.

The shipped data contains only bounded profile preferences, not the account database, enemy history, native restoration state or run telemetry. The install language is retained independently. Every slot is deep-copied; editing, deleting or switching profiles never changes the shipped definitions. Existing installations and later reloads retain their settings and saved profiles. First-launch previews now choose the matching shipped profile, then restore the current HUD on cancellation/logout.

Validation: Synthetic fresh-database seeding and existing-player isolation; actual shipped-preset startup, six profile switches, visible live cards, theme on/off default previews, deep-copy checks and preservation of later edits; existing runtime, settings, installed API and locale regressions. Functional regression fixtures explicitly retain their historical neutral preferences; dedicated factory fixtures exercise the real shipped first installation. The maintainer visually approved these layouts in the supplied screenshots; no new live-client visual validation by the agent is claimed.

Stable release accepted by the maintainer on 2026-11-15 after the final gameplay recipe. The runtime ZIP is byte-identical to the validated prerelease. No new agent live-client test, co-op certification or additional-resolution acceptance is implied.
