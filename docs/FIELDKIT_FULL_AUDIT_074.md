# Azeroth FieldKit Reborn — audit complet face au jeu 0.7.4

| | |
|---|---|
| Date | 2026-11-24 |
| Code audité | branche `audit/fieldkit-074` créée depuis `5a75939` (tête de la PR #4 `fix/paladin-meter-consecration-039`, candidate `0.1.0-reborn.39`, 2 CI vertes) |
| Dernière stable | `v0.1.0-reborn.38` (Release GitHub « Latest », 2026-11-20) — PR #4 ouverte, non fusionnée |
| Jeu installé | Azeroth Survivors: Reborn **0.7.4** (`.azs/installed.json`), en lecture seule |
| Indisponible | sources Rust du moteur (`survivors-sim`, `survivors-content`) |
| Documents liés | [Couverture API](FIELDKIT_API_COVERAGE_074.md) · [Performances](FIELDKIT_PERFORMANCE_AUDIT.md) · [UX/UI](FIELDKIT_UX_UI_AUDIT.md) · [Backlog](FIELDKIT_IMPROVEMENT_BACKLOG.md) · [Roadmap](FIELDKIT_ROADMAP.md) · [données machine](FIELDKIT_074_STATIC_AUDIT.json) |

## Comment lire cet audit

Chaque conclusion porte un niveau de preuve :

- **Confirmé** : démontré par le code (référence `fichier:ligne`), un test reproductible ou une donnée réelle mesurée.
- **Probable** : lecture de code cohérente, sans exécution dans le client.
- **Hypothèse** : plausible, à vérifier en jeu ; jamais présenté comme un bug.

Types de vérification, distingués :

| Type | Ce qui a été fait |
|---|---|
| Statique | Croisement des 72 modules × 477 fichiers Lua installés (`tools/audit_fieldkit_074.py`, nouveau) ; `audit.py`, `audit_reborn_api.py --game`, `reborn_audit.py --game`, `profile_scope_audit.py` |
| Unitaires / mocks | `build_locales --check`, `test_locale_tokens`, `check_locale_fonts`, `verify.py`, `test_reborn.py`, `audit_settings.py` (1 008 cas de setters), `audit_locale.py` |
| Intégration fichiers réels | `test_reborn.py --game` (exécute le Lua public installé et les catalogues générés) |
| Données réelles (lecture seule) | SavedVariables FieldKit (structure), AzerothStatsReborn (678 textes natifs de sorts, résumés de combat, noms de bijoux), diagnostics client (`lua-errors.log`, `last-context.txt`, `frozen-context.txt`) |
| Mesures synthétiques | `tools/bench_fieldkit.py` (nouveau), Lua 5.1 PUC, coûts Lua de FieldKit seul |
| Lua 5.0.3 natif | `lua50.exe` local : `verify.py --lua50` et exécution dans l'ordre du TOC |
| **Tests dans le client par l'agent** | **Aucun.** Seule validation client : la tienne (critiques périodiques `.39`). Tout point visuel, coop ou mode de jeu non mesuré est marqué « à vérifier en jeu ». |

## A. Synthèse générale

**État de santé : bon, avec une dette de qualité ciblée.** FieldKit est mature, défensif et instrumenté. Aucun P0. Le journal d'erreurs Lua du client (`UserData/Diagnostics/lua-errors.log`) est **vide** (0 ligne depuis le 18/11). Tous les tests officiels passent sur `5a75939`. Les 72 modules se chargent et s'initialisent sous **Lua 5.0.3 réel** dans l'ordre du TOC. Les SavedVariables réelles sont saines : 3 254 nœuds, cache monstres 468/2 048, aucune accumulation.

Les défauts restants sont **silencieux** :

- statistiques biaisées (attribution des kills, burst) ;
- coûts CPU/mémoire évitables (relecture du compteur) ;
- traductions erronées dans 12 langues.

Une **porte qualité est affaiblie** : 3 fichiers de tests jamais exécutés, harnais Lua 5.0 cassé.

**Points forts**

- Frontière stricte avec le jeu : toute entrée native passe par `FieldKit.Number` (fini, borné), `FieldKitNative.Text` (borné) et `pcall` pour les API optionnelles ; les absences d'API sont gérées par `type(...)=="function"`.
- Synchronisation de groupe (`PartySync.lua`) durcie :
  - roster vérifié, canal PARTY uniquement ;
  - ≤ 230 octets imprimables, 24 msg/s par émetteur ;
  - 64 fragments et 12 Ko max, fenêtre d'horloge de 30 s ;
  - nombres stricts, aucun `|` ni caractère de contrôle.
- Migration des SavedVariables (`Config.lua:21-169`) idempotente et bornée : elle élague sans réinitialiser en bloc, et aucun profil n'est supprimé.
- Les totaux restent ceux du compteur natif. Depuis `.39`, coups et critiques viennent d'une seule source, sans double comptage.
- Outillage : profileur intégré opt-in (`/fieldkit diag`, coût nul désactivé), audits API et réglages, manifestes de publication, empreintes SHA-256.
- 14 langues au catalogue complet (1 078 chaînes), placeholders vérifiés, polices OFL avec couverture de glyphes. Aucun `string.match` ni `#` dans le runtime.

**Points faibles**

- Attribution des kills et du « dernier coup » par **nom** de victime (STAT-01).
- Relecture du snapshot du compteur **5 fois par seconde et par consommateur**, alors que le serveur le met à jour une fois par seconde (PERF-01).
- **Traductions de combat** fautives et systématiques dans les 12 langues additionnelles (I18N-01).
- **Dette de tests** (QA-01) : 3 fichiers non exécutés, harnais Lua 5.0 en échec, CI sans `--lua50`.
- Texte flottant et pop-ups de critiques encore alimentés par le chat 1.12 : ils **n'affichent jamais de critique périodique** (CT-01).

**Risques**

1. La fusion de `.39` dans `main` déclenchera `publish-fieldkit-38.yml`, qui échouera sur ses assertions `.38` : coche rouge sur `main` (REL-01).
2. Client observé à **6–14 fps avec ~6 300 entités** et des blocages de 280–313 ms (`last-context.txt`). Rien n'attribue cela à FieldKit, mais le coût du compteur (PERF-01) s'ajoute en Endless long.
3. Une régression du compteur ou de la timeline passerait inaperçue : leurs fixtures dédiées ne tournent pas (QA-01).

**Architecture actuelle**

- Un espace de noms global plat par module (`FieldKitX`), chargé dans l'ordre du TOC, `Runtime.lua` en premier.
- Une boucle maître `OnUpdate` (`FieldKit.lua:3139`) :
  - par frame : diagnostics, fin de glisser, choix, critiques, pulsation ;
  - à 0,05 s : scan ;
  - à 0,2 s : données natives ;
  - à 0,5 s : disposition ;
  - à 0,1 s : plaques.
- Plus 22 `OnUpdate` locaux, temporisés ou actifs seulement quand visibles.
- Le compteur sur trois couches :
  - `MeterLedger` (données) ;
  - `MeterSuite` / `MeterWindow` / `PartyDetails` (présentation) ;
  - `ReferenceHUD` / `ThemeHUD` (rendu thématisé).
- Persistance : une table `FieldKitRebornDB` normalisée par `Config.lua`, avec profils de slots (`Profiles.lua`, 171 préférences sous portée).

**Compatibilité 0.7.4 : compatible.**

- 85 symboles `AZS_*` lus, dont 82 définis par le Lua installé.
- Les 3 autres sont protégés à chaque usage :
  - `AZS_GetCombatTextCapabilities` et `AZS_GetWorldAnchorCapabilities` : API « originale », absentes de Reborn ; FieldKit s'en sert pour détecter Reborn.
  - `AZS_ProjectWorldPoint` : fonction native de l'exécutable, appelée avec la même garde par `Anchors.lua:121` du jeu.
- 90 fonctions et 86 données natives ne sont pas exploitées. La plupart sont internes à l'interface du jeu ; les utiles sont listées dans la [couverture API](FIELDKIT_API_COVERAGE_074.md).

**Dette technique**

| Domaine | Dette |
|---|---|
| Modules monolithiques | `FieldKit.lua` (3 283 lignes), `ReferenceHUD.lua` (2 076), `Interface.lua` (1 372) mélangent données, rendu et disposition |
| Harnais Lua 5.0 | `tests/native50.lua` : liste de modules figée, fixtures antérieures aux presets d'usine |
| Documentation | 100+ fichiers de release historiques dans `docs/` ; inventaires `docs/REBORN_*.json` restés à 0.6.9 (regénérés dans cette branche) |
| Traductions | Assistées par machine ; le glossaire n'a aucun terme de statistique de combat |

**Niveau de confiance**

| Domaine | Confiance |
|---|---|
| Compatibilité API, logique des statistiques, robustesse réseau, SavedVariables, CI | Élevé |
| Coûts côté Lua | Élevé (mesurés) |
| Textes de sorts | Moyen : 678 textes réels, mais Paladin, Mage et Chasseur seulement |
| Visuel, coop, Endless | Faible : non vérifiés dans le client par l'agent |

Les modules inspectés seulement par métriques et tests automatiques sont signalés dans l'inventaire : la couverture n'est **pas exhaustive ligne à ligne**.

## B. Inventaire des modules

\* « Tests exécutés liés » : fichiers de tests exécutés par `test_reborn.py` / `verify.py` qui mentionnent une table globale du module. C'est une heuristique statique, pas une couverture de lignes.

| Module | Lignes | Rôle (en-tête du fichier) | Symboles AZS lus | Événements | OnUpdate | Tests exécutés liés* | Profondeur d'inspection |
|---|---:|---|---|---|---:|---:|---|
| Runtime.lua | 113 | Runtime boundary: validate data and centralize the few native setting writes. | GetPhase, IsOnTopOfScreens, SetHudShown, SetOnTopOfScreens | 0 | 0 | 45 | Lecture complète |
| RebornCreatures.lua | 920 | Generated by tools/build_reborn_creatures.py; names/icons only, installed Reborn packs. | — | 0 | 0 | 1 | Métriques + tests auto ; régénéré à blanc sur 0.7.4 : **identique** (820 entrées) |
| Reborn.lua | 354 | Read Reborn's fresh public globals; never predict content from the old game. | BUFFS, BUFFS_UPDATED, EVENT, EventCurrency, GEAR, GEN … | 0 | 0 | 21 | Lecture ciblée |
| RebornPresentation.lua | 123 | Reborn-only presentation. Native frames keep their scripts and data owners. | API_RunId, GEN, UnitWorldPosition, WorldUnits, ZONE | 1 | 0 | 0 | Lecture ciblée |
| RebornHUD.lua | 134 | Size the outer material before building its slices. | DASH, RUN | 0 | 0 | 0 | Métriques + tests auto |
| NativeHUD.lua | 388 | Per-element visual ownership for the unthemed Reborn HUD. | GetPhase, GetRunTime, IsHudShown, RUN, TARGET, UNITS | 0 | 0 | 5 | Métriques + tests auto |
| NativeLayout.lua | 77 | Independent unthemed cards yield to visible neighbours, not a linked stack. | — | 0 | 0 | 2 | Métriques + tests auto |
| Diagnostics.lua | 361 | Opt-in, read-only runtime diagnostics. | GetBossMeter, GetCombatTextEvents, GetHealing, GetMeter, GetPartyMeter, GetPhase … | 0 | 0 | 2 | Lecture ciblée |
| Positions.lua | 37 | Preserve native anchors after a drag. | — | 0 | 0 | 1 | Métriques + tests auto |
| Alignment.lua | 166 | Screen-space editing of the actual HUD, without suspending its theme. | — | 0 | 1 | 4 | Lecture ciblée |
| Config.lua | 169 | All persisted data belongs to FieldKitRebornDB only. | — | 0 | 0 | 0 | Lecture complète |
| Profiles.lua | 485 | Separate every declared FieldKit display preference by slot. | — | 0 | 0 | 17 | Métriques + tests auto (+ `profile_scope_audit.py`) |
| FactoryPresets.lua | 1580 | Maintainer-approved HUD preference snapshots, saved 2026-11-15. | — | 0 | 0 | 0 | Métriques + tests auto (fixtures factory) |
| Localization.lua | 743 | FieldKit UI labels (FR source catalogue). | — | 0 | 0 | 3 | Métriques + tests auto + échantillonnage |
| InterfaceStrings.lua | 579 | Presentation-only UI additions. | — | 0 | 0 | 0 | Métriques + tests auto |
| International.lua | 139 | Fixed locale metadata and font choices. | LOCALE | 0 | 1 | 0 | Lecture ciblée |
| Theme.lua | 321 | Chroniques d'Azeroth visual family. | — | 0 | 0 | 9 | Métriques + tests auto |
| ZoneThemeRegistry.lua | 7 | Fixed local media and native zone identities. | — | 0 | 0 | 0 | Métriques + tests auto |
| Seed.lua | 158 | Inherited static nameplate classification seed. | GEN | 0 | 0 | 0 | Métriques + tests auto |
| PortraitCatalog.lua | 1080 | Generated from the installed executable, locale tables and DBC appearances. | — | 0 | 0 | 1 | Métriques + tests auto |
| Portraits.lua | 70 | Static portraits rendered from the installed client's M2 skins. | UNITS, UNITS_UPDATED, ZONE | 0 | 0 | 4 | Lecture ciblée |
| Settings.lua | 226 | Lua 5.0 option callbacks. | — | 0 | 0 | 0 | Métriques + tests auto (+ `audit_settings.py`) |
| GameCompatibility.lua | 83 | Read-only original/Reborn rank compatibility. | GetPhase, RUN, ZONE | 0 | 0 | 0 | Métriques + tests auto |
| RebornStats.lua | 68 | Native jewelry additions are deltas, not percentages of the final stat. | GetPhase, GetStatCaps, STATS | 0 | 0 | 3 | Métriques + tests auto |
| Reborn065.lua | 116 | Optional 0.6.5 presentation adapters. | DEATH, GetDebuffs, GetPhase | 0 | 0 | 1 | Métriques + tests auto |
| RunMode.lua | 148 | Live native rank/zone plus the Difficulty UI multiplier chart. | GetPhase, ZONE | 0 | 0 | 5 | Métriques + tests auto |
| NativeData.lua | 105 | Optional native APIs read through a fixed list. | BUFFS, GEAR, GetBossMeter, GetCombatTextEvents, GetFlaggedLair, GetHealing … | 0 | 0 | 16 | Lecture ciblée |
| MeterWindow.lua | 59 | Read-only meter-window presentation; no reconstructed totals. | — | 0 | 0 | 2 | Métriques + tests auto |
| MeterLedger.lua | 801 | Native meter snapshots + local hit/crit/kill books. | API_RunId, CreateMeterCheckpoint, GetCombatTextEvents, GetMeterSnapshot … | 10 | 1 | 11 | **Lecture complète** |
| MeterSuite.lua | 490 | Tabbed combat meter, detached windows, reset, spell tips. | GetPhase | 0 | 0 | 3 | Lecture ciblée (Update/Paint/SetHealDone) |
| BossTimeline.lua | 363 | Boss schedule timeline. | BuildBossChargeBar, GetPhase, GetRunTime, GetUpcomingBosses, RUN, SCHEDULE … | 0 | 0 | 4 | Métriques ; **sa fixture dédiée n'est pas exécutée** (QA-01) |
| HudStack.lua | 174 | Common top-left anchor for the left HUD cards. | — | 0 | 1 | 5 | Lecture ciblée |
| CardLayout.lua | 205 | FieldKit-owned HUD geometry. | — | 0 | 0 | 7 | Métriques + tests auto |
| Coop.lua | 545 | Native party units and AZSPARTY; optional peer snapshots. | GetPartyMeter, GetPhase, PARTY, PARTY_UPDATED, RUN, TAKEN … | 0 | 0 | 6 | Lecture ciblée |
| GroupHistory.lua | 286 | Per-member action history from party combat-log chat events. | — | 0 | 1 | 3 | Lecture ciblée |
| PartySync.lua | 204 | Optional request-driven PARTY-only sharing. | GetMeter, GetPhase, RUN | 0 | 0 | 3 | **Lecture complète** |
| PartyDetails.lua | 414 | Reusable hover card for party members. | — | 0 | 1 | 7 | Lecture ciblée |
| ScreenLayers.lua | 107 | Level-up / jewelry screen layering. | — | 0 | 0 | 5 | Métriques + tests auto |
| NativeTools.lua | 404 | Passive bounded views over native state. | GetPhase, GetRevive, GetStoredLevels, GetSummonGroups, GetTimers, GetTotems … | 0 | 0 | 15 | Métriques + tests auto |
| SpellAssets.lua | 1751 | Generated from local Spell.dbc / SpellIcon.dbc. | — | 0 | 0 | 0 | Métriques + tests auto |
| Loadout.lua | 584 | Read-only native tooltip adapter. | GEAR, GEN, GetMeterContext, GetMeterLoadout, GetPhase, SPELLS … | 0 | 0 | 13 | Lecture ciblée + **678 textes réels** |
| TakenDetails.lua | 92 | Taken categories (no per-creature ledger). | TARGET, TARGET_UPDATED, UNITS, UNITS_UPDATED | 3 | 0 | 1 | Lecture ciblée |
| Preview.lua | 501 | Context-free visual examples. | — | 0 | 1 | 2 | Lecture ciblée |
| PreviewVisibility.lua | 106 | Temporary presentation isolation for placement. | — | 0 | 0 | 1 | Métriques + tests auto |
| OptionsSchema.lua | 233 | Declarative options. | — | 0 | 0 | 0 | Métriques + tests auto (+ `audit_settings.py`) |
| LegacyCrits.lua | 125 | Optional legacy critical display. | — | 0 | 0 | 0 | Lecture ciblée (CT-01) |
| Interface.lua | 1372 | User journey and configuration UI. | — | 0 | 2 | 26 | Lecture ciblée |
| FieldKit.lua | 3283 | HUD/controller derived from MASH by Malk. | GetDebuffs, GetFlaggedLair, GetLairs, GetPhase, GetPlayerPosition, LAIRS … | 15 | 3 | 1 | Lecture ciblée (boucle maître, plaques, antres, stats) |
| WorldPins.lua | 136 | Native world coordinates for pins. | CHESTS, GetPhase, GetPlayerPosition, LAIRS, RUN | 0 | 0 | 0 | Métriques |
| WorldAnchors.lua | 155 | Read-only world anchors (v1 and Reborn). | GetWorldAnchors, ProjectWorldAnchors, ProjectWorldPoint, RegisterWorldAnchorFrameHandler … | 0 | 1 | 2 | **Lecture complète** |
| WorldMarkers.lua | 405 | Visual world markers (opt-in). | GetDownedPartyMembers, GetPlayerPosition | 1 | 3 | 2 | Lecture ciblée |
| CombatText.lua | 683 | FieldKit scrolling text: chat events + healing totals. | GetCombatTextEvents, HEALING, ProjectCombatTextAnchors … | 1 | 1 | 4 | Lecture ciblée (sources) |
| CombatOptions.lua | 399 | Combat text editor. | GetCombatTextEvents | 0 | 2 | 0 | Lecture ciblée |
| CopyLog.lua | 740 | Optional local chat copy. | — | 0 | 1 | 0 | Lecture ciblée |
| ThemeMinimap.lua | 403 | Reversible ownership of the native map geometry. | GetPlayerPosition, RUN | 0 | 1 | 5 | Lecture ciblée |
| ThemeHUD.lua | 447 | Themed rendering of native buttons, unit/XP values. | GetUpcomingBosses, RUN, ZONE | 0 | 0 | 11 | Lecture ciblée |
| ThemeTarget.lua | 142 | Themed target surface. | TARGET | 0 | 0 | 5 | Métriques + tests auto |
| ReferenceArt.lua | 2 | Generated texture geometry. | — | 0 | 0 | 0 | Métriques |
| ReferenceHUD.lua | 2076 | Live widgets inside measured artwork rectangles. | GetLairs, GetStoredLevels, GetUpcomingBosses, OpenStoredLevels, RUN | 0 | 2 | 19 | Lecture ciblée (lectures du compteur, libellés) |
| ZoneThemes.lua | 615 | Opt-in presentation controller. | GetPhase, GetStoredLevels, IsHudShown, OpenStoredLevels, UNITS, ZONE | 0 | 0 | 28 | Lecture ciblée |
| Locale_*.lua (×12) | 1088 chacun | Catalogues générés par `tools/build_locales.py` | — | 0 | 0 | — | Contrôles outillés + échantillonnage de 9 clés du compteur dans les 12 langues |

**Modules non inspectés ligne à ligne** (métriques + tests automatisés seulement) : RebornCreatures, RebornHUD, NativeHUD, NativeLayout, Positions, Profiles, FactoryPresets, InterfaceStrings, Theme, ZoneThemeRegistry, Seed, PortraitCatalog, Settings, GameCompatibility, RebornStats, Reborn065, RunMode, MeterWindow, BossTimeline, CardLayout, ScreenLayers, NativeTools, SpellAssets, PreviewVisibility, OptionsSchema, WorldPins, ThemeTarget, ReferenceArt. Le registre ci-dessous ne prétend donc pas couvrir l'intégralité de leurs chemins.

## C. Registre des anomalies

Gravité :

- **P0** : crash, perte de données ou de configuration.
- **P1** : donnée fausse visible, ou porte qualité inopérante.
- **P2** : défaut fonctionnel limité, ou coût notable.
- **P3** : mineur ou cosmétique.

Aucun P0 n'a été trouvé.

### STAT-01 · P1 · MeterLedger · Kills et dernier coup attribués par nom de victime — Confirmé (code)

- **Attendu** : un kill est crédité au sort qui a porté le coup fatal sur *cette* créature, et seulement si c'est le héros ou son familier qui l'a tuée.
- **Observé** :
  - `RememberBlow` indexe `lastBlow[victim]` par **nom** (`MeterLedger.lua`, fonction `RememberBlow`, appelée par `IngestCombatEvent`).
  - `ParseDeath` crédite sur `"^(.+) dies"` et `"You have slain"` (`L.ParseDeath`).
  - En Survivors, des centaines d'ennemis portent le même nom : un kill est crédité au dernier sort ayant touché *n'importe quel* ennemi de ce nom.
  - En coop, `Shims.lua:425-435` écrit « X dies. » pour les morts non causées par le héros (`UNIT_DIED`) : le kill d'un coéquipier est crédité au héros s'il a touché un homonyme.
- **Preuves** :
  - `IngestCombatEvent` → `RememberBlow(e.targetName, …)` alors que l'événement porte `anchorId` (GUID cible, `CombatText.lua:120` du jeu).
  - Le shim distingue `PARTY_KILL` (« You have slain ») de `UNIT_DIED` (« dies »).
- **Cause** : héritage de l'ère chat 1.12, qui n'expose que des noms.
- **Reproduction (mock)** : deux « Raptor », le sort A touche le premier, le sort B le second, le premier meurt → crédit à B.
- **Correction** : indexer `lastBlow` par `e.anchorId` (GUID), puis créditer :
  - sur `COMBAT_LOG_EVENT_UNFILTERED` `PARTY_KILL` (src = héros) avec `dstGUID` ; c'est faisable, `RebornPresentation.lua:120` lit déjà ce flux ;
  - avec en repli le nom uniquement si aucun GUID n'est disponible ;
  - sans crédit sur `UNIT_DIED` si un autre joueur a tué.
- **Risque de régression** : moyen. La vue Kills change de valeurs, mais vers l'exact.
- **Tests** : homonymes, kill coéquipier, familier, mort sans coup préalable, `/reload`.

### QA-01 · P1 · tests / CI · Porte qualité partiellement inopérante — Confirmé (exécution)

- **Observé** :
  - `tests/meter_suite.lua`, `tests/combat_world.lua` et `tests/boss_timeline.lua` ne sont appelés que par `tests/native50.lua`, lui-même lancé seulement par `verify.py --lua50`, que la CI n'utilise jamais (`.github/workflows/verify.yml`).
  - `verify.py --lua50` échoue : `Config.lua:31: attempt to index global 'FieldKitNativeHUD'` (liste de modules figée dans `native50.lua:5`, sans `NativeHUD.lua`).
  - Avec l'ordre du TOC, les 72 modules se chargent sous Lua 5.0.3. L'échec suivant vient de fixtures obsolètes : `security.lua:2` attend les anciens défauts, puis `security.lua:43` la mise en page du chat.
  - Sous Lua 5.1 : `meter_suite.lua` échoue à `:65` (le mock n'a pas de capacités → la vue soins ne requête pas), `boss_timeline.lua` à `:16`. `combat_world.lua` passe.
- **Impact** : le compteur, la timeline des boss et la compatibilité Lua 5.0 sont annoncés testés, mais ne le sont pas.
- **Correction** :
  - liste de modules dérivée du TOC ;
  - `FieldKitProfiles.factoryPresets=nil` comme `test_reborn.py` ;
  - remettre à jour les fixtures ;
  - ajouter les 3 fichiers à `test_reborn.py` ;
  - job CI `--lua50` (compiler Lua 5.0.3 en CI, ou l'activer localement de façon obligatoire avant release).
- **Risque** : nul côté runtime.

### STAT-02 · P2 · MeterLedger · « Burst (1 s) » horodaté au moment du sondage — Confirmé (code)

- **Observé** :
  - `NoteHit` appelle `BurstAdd(key, amount, GetTime())` au moment du **poll** (toutes les 0,1 s, et rattrapage d'un coup après une période où le compteur était masqué), pas à `e.at`.
  - Fenêtre « tumbling » ancrée au premier coup, et non glissante.
- **Effets** :
  - quantification de 0,1 s ;
  - après réaffichage du compteur ou un trou du flux, jusqu'à 3 s d'événements (rétention de l'anneau, `CombatText.lua:42` du jeu) tombent dans la même fenêtre : burst **surestimé** jusqu'à ~3× ;
  - à l'inverse, un pic à cheval sur deux fenêtres est sous-estimé.
- **Correction** : passer `e.at` à `NoteHit`, et une fenêtre glissante bornée (file circulaire par sort, sans allocation par coup).
- **Tests** : rafale à cheval, rattrapage après trou, horodatages non monotones.

### CT-01 · P2 · CombatText, LegacyCrits · Textes flottants et pop-ups sans critiques périodiques — Confirmé (code)

- **Observé** :
  - Le mode écran du texte de combat s'abonne aux lignes chat (`CombatText.lua:411-414`, dont `CHAT_MSG_SPELL_PERIODIC_*`).
  - `FieldKitCrits.Capture` ne reconnaît que « Your X crits » et « You crit » (`LegacyCrits.lua:114-124`, alimenté par `FieldKit.lua:3072`).
  - Même cause racine que le bug `.39` : le shim 1.12 n'écrit jamais de critique périodique.
  - Le mode « monde » (`combatTextWorld`) lit déjà le flux natif.
- **Correction** : quand `AZS_GetCombatTextEvents` existe, alimenter le texte sortant et les pop-ups depuis le flux. Garder le chat pour l'entrant (le flux ne couvre que les coups du héros) et en repli.
- **Risque** : double affichage si mal découpé. Tests de non-double émission requis.

### PERF-01 · P2 · MeterLedger, MeterSuite, ReferenceHUD, ThemeHUD, NativeData · Snapshot du compteur reconstruit sans cache — Confirmé (mesure)

- **Observé** : `FieldKitMeterLedger.Read` reconstruit un snapshot natif complet à chaque appel :
  - `MeterSuite.Paint` (par fenêtre, y compris détachée) ;
  - `ReferenceHUD.lua:703` et `:1080` ;
  - `ThemeHUD.lua:425` ;
  - `NativeData.lua:89`.
- **Fréquence** : à `DATA_INTERVAL = 0.2 s` (`FieldKit.lua:19`), alors que `Meter.lua` du jeu précise que le serveur rafraîchit les compteurs **une fois par seconde**.
- **Mesure** (Lua 5.1, FieldKit seul, `tools/bench_fieldkit.py`) :
  - 20 sources : 0,25 ms et 43 Ko alloués par lecture ;
  - 120 sources : 1,5 ms et 250 Ko ;
  - 512 sources : 7,9 ms et 1 061 Ko.
- **Coût cumulé** : 5 lectures/s × N consommateurs, sans compter le coût natif de `AZS_GetMeterSnapshot`.
- **Correction** : mémoïser `Read(view)` par `(view, horodatage AZS_METER_UPDATED/AZS_HEALING_UPDATED/AZS_BOSSMETER_UPDATED, checkpoint, fenêtre)`, avec invalidation par stamp. Repeindre seulement si les données ont changé.
- **Risque** : faible si la clé de cache inclut la vue, la fenêtre et le checkpoint.
- **Tests** : égalité du résultat avec et sans cache ; invalidation au stamp, au reset et au changement de vue.

### I18N-01 · P2 · data/locales (12 langues) · Contresens dans les libellés de combat — Confirmé (catalogues)

- « Max hit » est traduit comme « Max a été frappé », en prenant Max pour un nom propre :
  - de « Max geschlagen. »
  - es « Max fue golpeado »
  - pt « Max foi atingido. »
  - pl « Max trafił. »
  - ru « Макс ударил »
  - zh « 马克斯被击中 »
  - ja « マックスが撃たれた »
  - ko « 맥스 쏴 »
- « Crit rate » :
  - es « Taxa de criterio »
  - ru « Критическая ставка » (mise critique)
  - uk « Критеріальна ставка »
  - zh « 关键率 »
  - ja « クリートレート »
  - ko « 비평률 » (taux de critique littéraire)
- « Hits: %d Crits » : de « Kritik » (critique au sens de reproche), es « Éxitos ».
- « No hit sample yet for this spell » : de « Zaubersatz… Erfolgsprobe ».
- **Cause** : traduction assistée ; `data/locale-glossary.json` (146 termes) n'a pas de terminologie de combat (`Max hit`, `Crit rate` absents).
- **Correction** :
  - glossaire de combat par langue, en reprenant les termes natifs des tables `Content_<lang>.lua` du jeu quand ils existent ;
  - corriger les ~30 clés de compteur et tooltip ;
  - relecture humaine recommandée.
- **Test** : ajouter à `build_locales.py` une liste de termes interdits (« Max » isolé en début de « Max hit », etc.).

### I18N-02 · P3 · MeterLedger, ReferenceHUD · Texte anglais codé en dur — Confirmé (code)

- `MeterLedger.lua:714` : `FieldKit_L("Max hit").." (non-crit): "`. Le suffixe est en anglais dans toutes les langues.
- `ReferenceHUD.lua:703` : `"DPS "` (acceptable comme sigle, mais incohérent avec « HPS » localisé à `:1838`).
- **Correction** : clés dédiées (« Max hit (non-crit) ») dans les 14 langues.

### LOAD-01 · P2 · Loadout · Dégâts « : N dégâts de X en T s » non extraits — Confirmé (données réelles)

- **Mesure** : 678 descriptions natives réelles (38 sorts Paladin, Mage, Chasseur), dont 480 avec des dégâts fixes. **478 extraites**.
- **2 manquées**, toutes deux des DoT de Chasseur :
  - `explosive_shot` : « Afflige l'ennemi le plus proche à moins de 30 m : 1458 dégâts de Feu en 2,6 s. »
  - `serpent_sting` : « Afflige jusqu'à 2 ennemis … : 828 dégâts de Nature en 5 s. »
- **Cause** : aucun motif FR pour « : N dégâts » (`Loadout.lua`, `L.SpellEffects`). La forme anglaise équivalente « 336 Fire damage over 2 sec » est couverte.
- **Correction** : ajouter `": "..number.." dégâts"`. Distinguer « total en T s » de « par tick » dans le libellé (ne pas présenter un total comme un tick).
- **Limite** : aucune donnée réelle pour Guerrier, Démoniste et les autres classes. Formulations à collecter.

### REL-01 · P2 · .github/workflows/publish-fieldkit-38.yml · Workflow de publication figé sur `.38` — Confirmé (code)

- **Observé** : déclenché sur `push` vers `main` touchant `data/publication-status.json`, avec `assert p['version']=='0.1.0-reborn.38'`. La PR #4 modifie ce fichier.
- **Effet** : la fusion de `.39` exécutera ce workflow, qui échouera (aucune publication erronée, mais une coche rouge sur `main`).
- **Correction** : workflow générique déclenché sur tag `v*` ou en `workflow_dispatch` avec version en entrée, conservant les garde-fous (version = TOC = Runtime = publication-status, acceptation maintainer, pas d'écrasement d'assets).

### STAT-03 · P3 · MeterLedger · Échantillon incomplet invisible — Confirmé (code)

- Les coups ne sont lus que si `meterFrame` est actif (`driver` `OnUpdate`, `if not FieldKitRebornDB.meterFrame then return end`).
- Les coups pendant une période désactivée, ou au-delà des 3 s de l'anneau, sont perdus : comptés dans `L.feed.missed` / `gaps`, mais **non affichés**. Les totaux natifs, eux, sont complets.
- **Correction** : mention « échantillon partiel (N événements manqués) » dans l'infobulle et dans `/fieldkit diag`. Option : lecture du flux indépendante de la visibilité du compteur, à arbitrer selon PERF-02.

### PERF-02 · P3 · MeterLedger · Allocations par événement du flux — Confirmé (mesure)

- **Mesure** : environ 236 octets et 17 µs (hôte) par événement :
  - 256 événements : 60 Ko et 3,6 ms ;
  - 2 048 événements : 482 Ko et 35 ms.
- **Sources** :
  - nouvelle table `lastBlow[victim]={…}` par coup ;
  - 3 `string.gsub` de `SpellBase` par coup ;
  - `tostring(spellId)` par coup ;
  - `FieldKitNative.Text` sur la cible.
- **Correction** :
  - mémoïser `SpellBase(name)` (cache borné par nom) ;
  - réutiliser l'entrée `lastBlow` ;
  - indexer `byId` par nombre.

### UX-01 · P3 · MeterSuite · Bascule soins « reçus » sans retour visible — Hypothèse

- `S.SetHealDone` refuse la perspective « received », non supportée par 0.7.4 (`Meter.lua:1238` du jeu : `healingPerspectives = { "performed" }`), via `MeterSuite.lua:46`.
- L'absence de retour visuel (bouton grisé, infobulle) est **à vérifier en jeu**.

### LOAD-02 · P3 · Loadout · `string.lower` sur UTF-8 dans `L.Key` — Hypothèse

- `Loadout.lua:12` applique `string.lower` aux noms (« Œil du ciel fendu », « Étoile de Mystaria »), alors que `Loadout.lua:137-138` documente une corruption UTF-8 de `string.lower` sous la locale C Windows.
- La corruption serait symétrique des deux côtés : les comparaisons restent probablement justes. Risque faible.
- Un test avec les noms réels est à ajouter.

### OBS-01 · Observation non attribuée · client · Fréquence d'images basse

- `last-context.txt` : 6–14 fps (pire 4), ~6 300 entités, blocages de 279–313 ms.
- `frozen-context.txt` : gel de 10 s pendant le chargement des addons.
- **Aucune preuve d'attribution à FieldKit.**
- À noter : AzerothStatsReborn a des SavedVariables de 12 Mo, qui pèsent probablement sur le chargement et la déconnexion.
- **Protocole** : voir [Performances §4](FIELDKIT_PERFORMANCE_AUDIT.md).

### DOC-01 · P3 · docs · Inventaires client obsolètes — Confirmé, corrigé dans cette branche

- `docs/REBORN_CLIENT_INVENTORY.json` indiquait les comptes 0.6.9 (612 icônes de créatures, 38 bijoux, 1 boss planifié par zone monde 4).
- Regénérés en 0.7.4 par les outils existants : 816 icônes, 44 bijoux, 22 amulettes, 5 boss.
- Le catalogue runtime `RebornCreatures.lua` est **déjà à jour** : régénération à blanc identique.

### Vérifications sans anomalie (pour mémoire)

- `PartySync` (entrées réseau) : bornes complètes, voir la synthèse.
- `Config.lua` : normalisation non destructive, bornes de toutes les tailles.
- SavedVariables réelles : saines.
- `lua-errors.log` client : vide.
- `WorldAnchors.Available()` sur 0.7.4 : actif via `AZS_ProjectWorldPoint` natif (`Anchors.lua:121` du jeu utilise la même garde).
- Les stamps `AZS_*_UPDATED` lus par FieldKit sont tous posés par `Api.lua` (`Stamp(...)` défini à `Api.lua:49`, appliqué aux listes par `Stamp(global .. "_UPDATED")` à `Api.lua:213`).
- Le catalogue de créatures est à jour.
- Icônes d'équipement : noms réels « Amulette de l'inferno: Consécration » correctement scindés par `EquippedSourceIcon`.
- Workflow de publication : ne peut pas publier une mauvaise version (assertions strictes).

## D. Matrice de couverture des API

Voir [FIELDKIT_API_COVERAGE_074.md](FIELDKIT_API_COVERAGE_074.md) (85 symboles lus, 3 absents protégés, fonctionnalités non exploitées).

## E. Opportunités d'amélioration

Voir [FIELDKIT_IMPROVEMENT_BACKLOG.md](FIELDKIT_IMPROVEMENT_BACKLOG.md).

## F. Performances

Voir [FIELDKIT_PERFORMANCE_AUDIT.md](FIELDKIT_PERFORMANCE_AUDIT.md).

## G. Roadmap

Voir [FIELDKIT_ROADMAP.md](FIELDKIT_ROADMAP.md).

## Comparaison avec les autres addons installés (lecture seule)

| Addon | Constat utile | Interopérabilité / risque |
|---|---|---|
| AzerothStatsReborn | Historique de parties et « combatIntelligence » lus depuis `AZS_GetCombatTextEvents`, comptant `gaps` / `dropped`. Il lit aussi `streamId` / `droppedCount`, champs absents du `CombatText.lua` installé. | Ne pas dupliquer son historique de parties. Ses SavedVariables font 12 Mo (risque de chargement, indépendant de FieldKit). |
| RebornBuildPlanner | Planification de builds, catalogue généré, suivi en direct. | Ne pas dupliquer la planification ni `AZS_TALENT_BUILD`. |
| ASR Advisor | Conseils de choix. | Ne pas dupliquer un assistant de choix de cartes (`AZS_CARDS`). |
| ASRCombatText | Texte de combat. | **Hypothèse** : double affichage si les deux textes sortants sont activés. À vérifier en jeu ; prévoir une note dans les options. |
| AzerothSurvivorsAPI (jeu) | Référence du contrat : `Api.lua`, `Meter.lua`, `CombatText.lua`, `Anchors.lua`, `Shims.lua`. | Source de vérité de cette matrice. |

Licences des autres addons : non auditées. Aucun code n'a été copié.
