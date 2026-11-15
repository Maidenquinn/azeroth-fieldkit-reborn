FieldKit Reborn 0.1.0-reborn.27

French names now share a presentation adapter across meters, detached meters, damage/healing details, tooltips, loadouts, effects, floating combat text, group spell history and killing-blow details. Raw keys and player names retain their identity.

Use the native AZS_SpellName lookup when a spell id is available. A bounded alias cache joins client DBC names to AZS_SPELL_NAMES by id (Freezing Trap / Frost Trap), invalidates on AZSNAMES and refreshes for late packets. Known missing proc names have a French UI fallback. Unknown/custom names remain unchanged.

Translate native miss result labels, compact bonus suffixes and missing option/help text. Refresh cached rank labels immediately on language changes and include late dictionary extensions in reverse language bindings.

Validation: No new live client visual pass. Offline French checks cover 479 literal UI labels/help texts, option descriptors and dropdown choices, 241 installed class spells and 66 jewelry names, both theme families off/minimal/complete/alternative, fresh and persisted French settings, damage/healing/boss/recent/fallback/detached/modal/tooltips, player-name and raw-key preservation, effects/procs, DBC/server aliases and late name updates, floating grouped hits/misses, ranks and language refresh. Full runtime/settings and installed public API checks are run.

Five native spell names are legitimately identical in French and English: Blizzard, Dispersion, Pestilence, Corruption and Rupture. This release does not invent translations for unknown custom game content.

Native displays and endless:
- FieldKit combat text now suppresses native player/pet damage numbers automatically. Combat text > Game exposes "Also show native damage numbers". The existing native damage checkbox edits the same preference. Save the pre-takeover CVar baseline across reload and restore it on disable/logout.
- Alerts expose "FieldKit notifications" and "Also show native notifications". The subscribed movable panel can replace the native banners, filter boss/mechanic/party/other announcements and suppress duplicate events. A missing or rejected banner subscription leaves the native display intact; previous visibility returns on disable/logout.
- Endless keeps its progress panel visible when the API omits charge, showing "Progress not provided". Native zero and nonzero charge remain authoritative; no countdown, spawn time or percentage is inferred. Boolean/nonzero endless flags are accepted. Future boss identity still requires the game's nbn field.
- Added themed/off ownership, mixed CVar baseline, reload/release, banner failure and explicit missing-progress regressions. Client observed at the hero menu; no live endless-state validation is claimed.
