FieldKit Reborn 0.1.0-reborn.27

French names now share a presentation adapter across meters, detached meters, damage/healing details, tooltips, loadouts, effects, floating combat text, group spell history and killing-blow details. Raw keys and player names retain their identity.

Use the native AZS_SpellName lookup when a spell id is available. A bounded alias cache joins client DBC names to AZS_SPELL_NAMES by id (Freezing Trap / Frost Trap), invalidates on AZSNAMES and refreshes for late packets. Known missing proc names have a French UI fallback. Unknown/custom names remain unchanged.

Translate native miss result labels, compact bonus suffixes and missing option/help text. Refresh cached rank labels immediately on language changes and include late dictionary extensions in reverse language bindings.

Validation: No new live client visual pass. Offline French checks cover 477 literal UI labels/help texts, option descriptors and dropdown choices, 241 installed class spells and 66 jewelry names, both theme families off/minimal/complete/alternative, fresh and persisted French settings, damage/healing/boss/recent/fallback/detached/modal/tooltips, player-name and raw-key preservation, effects/procs, DBC/server aliases and late name updates, floating grouped hits/misses, ranks and language refresh. Full runtime/settings and installed public API checks are run.

Five native spell names are legitimately identical in French and English: Blizzard, Dispersion, Pestilence, Corruption and Rupture. This release does not invent translations for unknown custom game content.
