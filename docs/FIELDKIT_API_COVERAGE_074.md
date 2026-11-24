# FieldKit — matrice de couverture des API (jeu 0.7.4)

Source : `tools/audit_fieldkit_074.py --game "<racine du jeu>"` (statique, lecture seule) → `docs/FIELDKIT_074_STATIC_AUDIT.json`, puis annotation manuelle des contrats à partir des en-têtes installés (`AzerothSurvivorsAPI/Api.lua`, `Meter.lua`, `CombatText.lua`, `Anchors.lua`, `AzerothSurvivors/*.lua`). La version installée prime sur la documentation web ; la page addon-api ne documente pas `streamId` / `droppedCount` (absents du `CombatText.lua` installé).

**Limite** : un scan Lua ne voit pas les fonctions enregistrées par l'exécutable (ex. `AZS_ProjectWorldPoint`, `AZS_UnitWorldPosition`, `AZS_WorldUnits`) ; elles sont classées d'après les usages gardés du jeu. Les règles serveur (ex. quels sorts critiquent) ne sont pas visibles côté client.

## Résumé

- Symboles `AZS_*` lus par FieldKit : **85** — fonctions installées 46, données installées 34, documentées/natives 2, absentes du Lua installé 3 (toutes protégées par `type(...)=='function'`).
- Fonctions natives non utilisées : 90 ; données non utilisées : 86 — en majorité internes à l'UI du jeu (éditeur, amis, voix, émotes, spectateur).
- Incompatibilités : **aucune** constatée. Obsolètes : les 2 points d'entrée « capabilities » de l'API originale (branches inactives conservées pour compatibilité, coût nul).
- API remplacées depuis .39 : lignes chat `CHAT_MSG_SPELL_*` → `AZS_GetCombatTextEvents` pour coups/critiques du compteur (le chat reste en repli ; CT-01 pour le texte flottant).

## Matrice des API exploitées

| Symbole | Disponibilité 0.7.4 | Défini à | Modules FieldKit | Contrat (paramètres → retour) | Gestion erreurs / absences |
|---|---|---|---|---|---|
| `AZS_API_RunId` | Fonction installée | AzerothSurvivorsAPI/Api.lua:65 | MeterLedger, RebornPresentation | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_BUFFS` | Donnée installée | AzerothSurvivors/Run.lua:18 | NativeData, Reborn | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_BUFFS_UPDATED` | Donnée installée | AzerothSurvivorsAPI/Api.lua:175 (by name) | Reborn | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_BuildBossChargeBar` | Fonction installée | AzerothSurvivorsUI/Components/Misc/SurvivorsBossBar.lua:272 | BossTimeline | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_CHESTS` | Donnée installée | AzerothSurvivors/Chests.lua:6 | WorldPins | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_CreateMeterCheckpoint` | Fonction installée | AzerothSurvivorsAPI/Meter.lua:1324 | MeterLedger | (runId) → {checkpointId}; 64 max | pcall ; libération du précédent |
| `AZS_DASH` | Donnée installée | AzerothSurvivors/Dash.lua:104 | RebornHUD | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_DEATH` | Donnée installée | AzerothSurvivors/DeathLog.lua:13 | Reborn065 | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_EVENT` | Donnée installée | AzerothSurvivors/Events.lua:24 | Reborn | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_EventCurrency` | Fonction installée | AzerothSurvivors/Events.lua:28 | Reborn | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GEAR` | Donnée installée | AzerothSurvivors/Units.lua:73 | Loadout, NativeData, Reborn | AZS_List {slot,rarity,bonus,amount,icon,name,text} (Units.lua:73) | Loadout ; EquippedSourceIcon |
| `AZS_GEN` | Donnée installée | AzerothSurvivors/Generated/Content.lua:6 | Loadout, Reborn, RebornPresentation, Seed | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GetBossMeter` | Fonction installée | AzerothSurvivorsAPI/Api.lua:488 | Diagnostics, MeterLedger, NativeData | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GetBosses` | Fonction installée | AzerothSurvivorsAPI/Api.lua:301 | Reborn | () → {id,name,hp,hpm,final,enraged,debuffs} | lecture bornée |
| `AZS_GetCombatTextCapabilities` | Absente du Lua installé | — | CombatText | Absente en 0.7.4 (API originale) | type-check ; branche inactive |
| `AZS_GetCombatTextEvents` | Fonction installée | AzerothSurvivorsAPI/CombatText.lua:258 | CombatOptions, CombatText, Diagnostics, MeterLedger, NativeData | (cursor, limit≤256) → {apiVersion,cursor,events,hasMore,gap}; anneau 512 / 3 s (CombatText.lua:9-16, 40-45) | pcall ; STREAM_CHANGED géré ; pagination complète et comptage des pertes depuis .39 (MeterLedger) |
| `AZS_GetDebuffs` | Fonction installée | AzerothSurvivorsAPI/Api.lua:262 | FieldKit, Reborn065 | (id) → {spell,name,icon,stacks,duration,remaining,permanent,dispelType} | lecture bornée |
| `AZS_GetDownedPartyMembers` | Fonction installée | AzerothSurvivorsAPI/Anchors.lua:611 | WorldMarkers | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GetFlaggedLair` | Fonction installée | AzerothSurvivorsAPI/Api.lua:526 | FieldKit, NativeData | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GetGuardians` | Fonction installée | AzerothSurvivorsAPI/Api.lua:330 | Reborn | () → {id,name,hp,hpm,awake,debuffs} | lecture bornée |
| `AZS_GetHealing` | Fonction installée | AzerothSurvivorsAPI/Api.lua:484 | Diagnostics, MeterLedger, NativeData | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GetLairs` | Fonction installée | AzerothSurvivorsAPI/Api.lua:500 | FieldKit, NativeData, ReferenceHUD | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GetLocalTime` | Fonction installée | AzerothSurvivorsAPI/Api.lua:596 | NativeData | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GetMeter` | Fonction installée | AzerothSurvivorsAPI/Api.lua:462 | Diagnostics, MeterLedger, NativeData, PartySync | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GetMeterCapabilities` | Fonction installée | AzerothSurvivorsAPI/Meter.lua:1230 | Reborn | () → {features, healingPerspectives={"performed"}, periods={"run","encounter"}…} (Meter.lua:1236-1241) | pcall ; SupportsHealing |
| `AZS_GetMeterContext` | Fonction installée | AzerothSurvivorsAPI/Meter.lua:1245 | Loadout, MeterLedger | () → {runId,…} | pcall ; runId requis |
| `AZS_GetMeterLoadout` | Fonction installée | AzerothSurvivorsAPI/Meter.lua:1262 | Loadout | (query) → loadout (AZSSPELLS, AZSGEAR, talents) | pcall (Loadout) |
| `AZS_GetMeterSnapshot` | Fonction installée | AzerothSurvivorsAPI/Meter.lua:1258 | MeterLedger | (query) → snapshot ou nil,err {code,retryable…}; ne lève jamais (Meter.lua:12-15) | pcall ; statuts ready/ready_empty ; voir PERF-01 (pas de cache) |
| `AZS_GetPartyMeter` | Fonction installée | AzerothSurvivorsAPI/Api.lua:493 | Coop, Diagnostics, MeterLedger | () → {name,class,dmg,dps,share,top,topdps} | repli de la vue Groupe |
| `AZS_GetPhase` | Fonction installée | AzerothSurvivorsAPI/Api.lua:233 | BossTimeline, CombatText, Coop, Diagnostics, FieldKit, GameCompatibility, Loadout, MeterLedger, MeterSuite, NativeData, NativeHUD, NativeTools, PartySync, Reborn, Reborn065, RebornStats, RunMode, Runtime, WorldAnchors, WorldPins, ZoneThemes | () → ready/playing/choosing/paused/dead/victory ; nil hors partie ou hub (Api.lua) | type-check ; appel direct (ne lève pas) |
| `AZS_GetPlayerPosition` | Fonction installée | AzerothSurvivorsAPI/Api.lua:565 | FieldKit, ThemeMinimap, WorldMarkers, WorldPins | () → {apiVersion,mapId,spaceId,runId,x,y,z,facing} ou nil,err | pcall |
| `AZS_GetRevive` | Fonction installée | AzerothSurvivorsAPI/Api.lua:254 | NativeData, NativeTools | () → {down,share,by,reviving,rshare,friends} | NativeData |
| `AZS_GetRunTime` | Fonction installée | AzerothSurvivors/Run.lua:51 | BossTimeline, Diagnostics, MeterLedger, NativeData, NativeHUD, Reborn | () → secondes de partie | tonumber + repli AZS_RUN.t |
| `AZS_GetStatCaps` | Fonction installée | AzerothSurvivorsAPI/Api.lua:136 | Diagnostics, RebornStats | () → AZS_CAPS {cdr,crit,red,echo,haste} en % | RebornStats |
| `AZS_GetStoredLevels` | Fonction installée | AzerothSurvivorsAPI/Api.lua:610 | NativeData, NativeTools, ReferenceHUD, ZoneThemes | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_GetSummonGroups` | Fonction installée | AzerothSurvivorsAPI/Api.lua:390 | NativeData, NativeTools | () → {key,kind,name,icon,count,permanent,temporary,remaining}, total | NativeTools |
| `AZS_GetTimers` | Fonction installée | AzerothSurvivorsAPI/Api.lua:444 | NativeData, NativeTools | (name) → {name,icon,kind,duration,remaining,ready} | NativeTools |
| `AZS_GetTotems` | Fonction installée | AzerothSurvivorsAPI/Api.lua:420 | NativeData, NativeTools | (which) → {key,spell,name,icon,count,cap,duration,remaining} | NativeTools |
| `AZS_GetUpcomingBosses` | Fonction installée | AzerothSurvivorsAPI/Api.lua:342 | BossTimeline, Diagnostics, NativeData, NativeTools, ReferenceHUD, ThemeHUD | () → {index,name,at,left,final} | lecture bornée |
| `AZS_GetWorldAnchorCapabilities` | Absente du Lua installé | — | Diagnostics, WorldAnchors | Absente en 0.7.4 (API originale) | type-check ; son absence sélectionne le mode Reborn |
| `AZS_GetWorldAnchors` | Fonction installée | AzerothSurvivorsAPI/Anchors.lua:595 | Diagnostics, WorldAnchors | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_HEALING` | Donnée installée | AzerothSurvivorsAPI/Api.lua:29 | CombatText | liste AZSHEAL + stamp | CombatText (soins) |
| `AZS_HEALING_UPDATED` | Donnée installée | AzerothSurvivorsAPI/Api.lua:204 (dynamic stamp) | CombatText | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_IsHudShown` | Fonction installée | AzerothSurvivorsAPI/Hud.lua:102 | NativeHUD, NativeTools, ZoneThemes | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_IsOnTopOfScreens` | Fonction installée | AzerothSurvivorsAPI/Hud.lua:329 | Runtime | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_L` | Donnée installée | AzerothSurvivors/Locale.lua:37 | Reborn | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_LAIRS` | Donnée installée | AzerothSurvivors/Lairs.lua:7 | FieldKit, WorldPins | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_LOCALE` | Donnée installée | AzerothSurvivors/Locale.lua:31 | International | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_OpenStoredLevels` | Fonction installée | AzerothSurvivorsAPI/Api.lua:614 | ReferenceHUD, ZoneThemes | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_PARTY` | Donnée installée | AzerothSurvivorsAPI/Api.lua:31 | Coop | liste AZSPARTY + stamp dynamique (Api.lua:198-215) | identité + stamp |
| `AZS_PARTY_UPDATED` | Donnée installée | AzerothSurvivorsAPI/Api.lua:206 (dynamic stamp) | Coop | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_PETS` | Donnée installée | AzerothSurvivorsAPI/Api.lua:26 | NativeData | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_ProjectCombatTextAnchors` | Fonction installée | AzerothSurvivorsAPI/CombatText.lua:262 | CombatText | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_ProjectWorldAnchors` | Fonction installée | AzerothSurvivorsAPI/Anchors.lua:599 | Diagnostics, WorldAnchors | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_ProjectWorldPoint` | Absente du Lua installé | — | WorldAnchors | Fonction NATIVE de l'exécutable (Anchors.lua:121 du jeu) | type-check ; présence = mode Reborn de WorldAnchors |
| `AZS_REVIVE` | Donnée installée | AzerothSurvivors/Revive.lua:8 | NativeData | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_RUN` | Donnée installée | AzerothSurvivors/Run.lua:10 | BossTimeline, CombatText, Coop, FieldKit, GameCompatibility, MeterLedger, NativeData, NativeHUD, NativeTools, PartySync, Reborn, RebornHUD, ReferenceHUD, ThemeHUD, ThemeMinimap, WorldPins | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_RUN_UPDATED` | Donnée installée | AzerothSurvivors/Run.lua:437 | NativeTools, Reborn | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_RegisterBannerHandler` | Fonction installée | AzerothSurvivorsAPI/Api.lua:638 | NativeTools | (fn) → appels {id,kind,boss,name,text,time} | NativeTools ; désenregistré |
| `AZS_RegisterCombatTextFrameHandler` | Fonction installée | AzerothSurvivorsAPI/CombatText.lua:266 | CombatText | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_RegisterWorldAnchorFrameHandler` | Fonction installée | AzerothSurvivorsAPI/Anchors.lua:603 | WorldAnchors | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_ReleaseMeterCheckpoint` | Fonction installée | AzerothSurvivorsAPI/Meter.lua:1328 | MeterLedger | (checkpointId) | pcall |
| `AZS_SCHEDULE` | Donnée installée | AzerothSurvivors/Run.lua:12 | BossTimeline, NativeData, NativeTools, Reborn | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_SPELLS` | Donnée installée | AzerothSurvivors/Run.lua:14 | Loadout, NativeData | AZS_List {key,spell,rank,cd,cdmax} (Spells.lua:124) | Loadout |
| `AZS_SPELLTIPS` | Donnée installée | AzerothSurvivors/Spells.lua:9 | Loadout, NativeData | {[key]=texte natif localisé} (Spells.lua:9) | Loadout.SpellEffects ; 478/480 sur données réelles |
| `AZS_SPELL_NAMES` | Donnée installée | AzerothSurvivors/Locale.lua:47 | Reborn | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_STATS` | Donnée installée | AzerothSurvivorsAPI/Api.lua:122 | FieldKit, RebornStats | table remplacée à chaque ligne "AZS" + AZS_STATS_UPDATED (Api.lua:120-124) | identité + stamp |
| `AZS_STATS_UPDATED` | Donnée installée | AzerothSurvivorsAPI/Api.lua:123 (by name) | FieldKit | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_SetHudShown` | Fonction installée | AzerothSurvivorsAPI/Hud.lua:89 | FieldKit, Runtime | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_SetOnTopOfScreens` | Fonction installée | AzerothSurvivorsAPI/Hud.lua:310 | Diagnostics, Runtime | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_SpellName` | Fonction installée | AzerothSurvivors/Locale.lua:56 | Reborn | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_TAKEN` | Donnée installée | AzerothSurvivorsAPI/Api.lua:32 | Coop, MeterLedger | liste AZSTAKEN {source,dmg} + stamp | identité + stamp |
| `AZS_TAKEN_UPDATED` | Donnée installée | AzerothSurvivorsAPI/Api.lua:207 (dynamic stamp) | Coop | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_TARGET` | Donnée installée | AzerothSurvivorsAPI/Api.lua:24 | NativeHUD, TakenDetails, ThemeTarget | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_TARGET_UPDATED` | Donnée installée | AzerothSurvivorsAPI/Api.lua:222 (by name) | TakenDetails | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_TIMERS` | Donnée installée | AzerothSurvivorsAPI/Api.lua:25 | NativeData | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_TOTEMS` | Donnée installée | AzerothSurvivorsAPI/Api.lua:27 | NativeData | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_UNITS` | Donnée installée | AzerothSurvivors/Run.lua:13 | FieldKit, NativeHUD, Portraits, Reborn, TakenDetails, ZoneThemes | remplacée à chaque AZSUNITS + stamp | identité + stamp |
| `AZS_UNITS_UPDATED` | Donnée installée | AzerothSurvivorsAPI/Api.lua:145 (by name) | FieldKit, Portraits, TakenDetails | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_UnitKind` | Fonction installée | AzerothSurvivorsAPI/Api.lua:687 | FieldKit | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_UnitWorldPosition` | Documentée (en-tête) / native | — | RebornPresentation, WorldAnchors | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_UnregisterBannerHandler` | Fonction installée | AzerothSurvivorsAPI/Api.lua:647 | NativeTools | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_UnregisterWorldAnchorFrameHandler` | Fonction installée | AzerothSurvivorsAPI/Anchors.lua:607 | WorldAnchors | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_WorldUnits` | Documentée (en-tête) / native | — | RebornPresentation | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |
| `AZS_ZONE` | Donnée installée | AzerothSurvivors/Run.lua:9 | BossTimeline, CombatText, FieldKit, GameCompatibility, MeterLedger, NativeData, NativeTools, Portraits, Reborn, RebornPresentation, RunMode, ThemeHUD, ZoneThemes | voir en-tête du fichier natif | lecture typée (type-check / FieldKit.Number) |

## API disponibles non exploitées et utiles

| API / donnée | Où | Ce qu'elle fournit | Usage proposé |
|---|---|---|---|
| AZS_RequestAbilities + AZS_ABILITIES (+_UPDATED) | `Api.lua:159-172` | {key,spell,rank,passive,kind,cd,cdmax,name,icon,text} incluant **passifs** et choix de race ; réinitialisé à chaque AZSZONE | Fiche des capacités complète (passifs, icônes et textes natifs) ; réduirait la dépendance au catalogue statique SpellAssets. Envoie une commande serveur : à n'appeler qu'à la demande. |
| AZS_GetRunSummary / AZS_END (+_UPDATED, AZS_END_*) | `Api.lua:246-251` | résumé de fin de partie tel que l'écran de fin le montre | Carte de fin de partie FieldKit (records de la partie : max crit, burst, kills par sort). Ne pas dupliquer l'historique d'AzerothStatsReborn. |
| AZS_GetRunLength | `Api.lua:241-243` | seconde d'arrivée du boss final | Barre de progression vers le boss final dans la timeline |
| AZS_GetSummons / AZS_GetSummonCount | `Api.lua:359, 384` | {id,entry,key,kind,name,icon,permanent,duration,remaining} par invocation | Minuteurs individuels des invocations temporaires ; FieldKit n'utilise que les groupes |
| AZS_GetTotemCount | `Api.lua:433` | compte et plafond | Alerte « totems au plafond » |
| AZS_IsStoringLevels | `Api.lua:620` | booléen | État visible du stockage des niveaux à côté du compteur déjà affiché |
| AZS_METER_UPDATED / AZS_HEALING_UPDATED / AZS_BOSSMETER_UPDATED | `Api.lua:213` | horodatage de la dernière ligne serveur | **Clé de cache pour PERF-01** |
| AZS_CAPS_UPDATED | `Api.lua:133` | stamp des plafonds | Rafraîchir les plafonds seulement au changement |
| AZS_DEBUFFS (+_AT, _UPDATED) | `Api.lua:148-153` | débuffs bruts du serveur | Déjà couvert par AZS_GetDebuffs ; pas d'intérêt |
| AZS_TALENT_BUILD / AZS_TALENT_TREES / AZS_CARDS | `AzerothSurvivors` | build et choix | **Ne pas exploiter** : domaine de Reborn Build Planner / ASR Advisor |

## Liste brute des symboles installés non utilisés

Fonctions : `AZS_ApplyForcedCVars`, `AZS_ApplyLinkInfo`, `AZS_ApplyMeterSettings`, `AZS_ApplyPlace`, `AZS_ApplyPlaces`, `AZS_ApplyPlayerHealthColor`, `AZS_ApplyRunStatsSettings`, `AZS_ApplyStockText`, `AZS_ApplyStoreLevels`, `AZS_ApplyTrackerSettings`, `AZS_ApplyUpgradeSettings`, `AZS_ApplyVoiceAutoJoin`, `AZS_BossHorn`, `AZS_BuildBossStyleBar`, `AZS_CreateProvingBuild`, `AZS_Darkness`, `AZS_DarknessState`, `AZS_Dash`, `AZS_DashCard`, `AZS_FontName`, `AZS_FrameName`, `AZS_FriendsChanged`, `AZS_FriendsCommand`, `AZS_GetRunLength`, `AZS_GetRunSummary`, `AZS_GetSummonCount`, `AZS_GetSummons`, `AZS_GetTotemCount`, `AZS_GetVoiceVolume`, `AZS_GroupPanelLink`, `AZS_InspectUnit`, `AZS_InviteFriend`, `AZS_IsEditing`, `AZS_IsStoringLevels`, `AZS_LocaleStrings`, `AZS_LowerMeter`, `AZS_MeterTotals`, `AZS_MinimapOffset`, `AZS_MinimapView`, `AZS_Mount`, `AZS_NextBossProgress`, `AZS_OnBanner`, `AZS_OnWorldProjected`, `AZS_OpenHubLooks`, `AZS_OpenLevels`, `AZS_OpenRun`, `AZS_PadCardKeys`, `AZS_Parse`, `AZS_ParseBanner`, `AZS_PickCard`, `AZS_PingKey`, `AZS_PlayChestOpen`, `AZS_PushToTalk`, `AZS_ReadSpellNames`, `AZS_RequestAbilities`, `AZS_RunLobbyChanged`, `AZS_SendCrashReportsOption`, `AZS_SendLanguage`, `AZS_SetClassIcon`, `AZS_SetEditorActionBarsHidden`, `AZS_SetEditorHud`, `AZS_SetFont`, `AZS_SetLanguage`, `AZS_SetMeterPortrait`, `AZS_SetPeer`, `AZS_SetStoringLevels`, `AZS_SetVoiceVolume`, `AZS_ShiftName`, `AZS_ShowHubDps`, `AZS_SpaceOf`, `AZS_SpectateNext`, `AZS_SpectatePrev`, `AZS_SpectateSwitch`, `AZS_StockStrings`, `AZS_StockText`, `AZS_TagSpace`, `AZS_ToggleEditMode`, `AZS_ToggleEmoteWheel`, `AZS_ToggleFriends`, `AZS_ToggleInspect`, `AZS_ToggleProving`, `AZS_ToggleVoiceMute`, `AZS_TrackerShown`, `AZS_TurnArrow`, `AZS_UpdateChestPins`, `AZS_UpdateEnd`, `AZS_UpdateGearRow`, `AZS_UpdateLairMarks`, `AZS_UpdateRiftMarks`, `AZS_ZoneTitle`

Données : `AZS_ABILITIES`, `AZS_ABILITIES_UPDATED`, `AZS_API`, `AZS_API_HUD`, `AZS_ARMOR`, `AZS_ApiWorld`, `AZS_BANNER`, `AZS_BANNERS`, `AZS_BANNERS_KEPT`, `AZS_BANNER_HANDLERS`, `AZS_BANNER_UPDATED`, `AZS_BOSSMETER`, `AZS_BOSSMETER_UPDATED`, `AZS_CAPS`, `AZS_CAPS_UPDATED`, `AZS_CARDS`, `AZS_CHESTS_UPDATED`, `AZS_COOP_STATE`, `AZS_DARKNESS`, `AZS_DEBUFFS`, `AZS_DEBUFFS_AT`, `AZS_DEBUFFS_UPDATED`, `AZS_EMOTES`, `AZS_EMOTEWHEEL`, `AZS_END`, `AZS_END_HEROES`, `AZS_END_LOOT`, `AZS_END_OWN_RUN`, `AZS_END_RUN`, `AZS_END_RUN_ALL`, `AZS_END_UPDATED`, `AZS_FONT`, `AZS_FONTS`, `AZS_FRIENDS`, `AZS_Fields`, `AZS_GEAR_RARITY`, `AZS_GX_API`, `AZS_HEXES`, `AZS_HUB_ASK`, `AZS_HUD_CVARS`, `AZS_ICON_GROW`, `AZS_INSPECT`, `AZS_IconRim`, `AZS_JOIN_ASK`, `AZS_KEYS`, `AZS_KICK`, `AZS_LAIRS_UPDATED`, `AZS_LANGUAGES`, `AZS_List`, `AZS_METER`, `AZS_METER_UPDATED`, `AZS_MOUNT`, `AZS_ON_TOP`, `AZS_ON_TOP_FRAMES`, `AZS_OPENLEVELS`, `AZS_PASSAGE`, `AZS_PEERS`, `AZS_PETS_UPDATED`, `AZS_PG`, `AZS_PING`, `AZS_POWER`, `AZS_PUSHTOTALK`, `AZS_PlaceTracker`, `AZS_REMOVE_FRIEND`, `AZS_REVIVE_UPDATED`, `AZS_RIFT`, `AZS_RUNSTATS`, `AZS_SCHEDULE_UPDATED`, `AZS_SETTINGS`, `AZS_SPECTATE`, `AZS_SPECTATE_NEXT`, `AZS_SPECTATE_PREV`, `AZS_SPELLS_AT`, `AZS_SPELLS_UPDATED`, `AZS_SendCommand`, `AZS_Setting`, `AZS_SkinSlider`, `AZS_TALENT_BUILD`, `AZS_TALENT_TREES`, `AZS_TIMERS_UPDATED`, `AZS_TOMBS`, `AZS_TOTEMS_UPDATED`, `AZS_VAULT`, `AZS_VICTORY`, `AZS_WATCH`, `AZS_ZONE_UPDATED`

## Catalogues de données client vs FieldKit

| Catalogue | Client 0.7.4 | FieldKit | Statut |
|---|---|---|---|
| Créatures (icônes/noms par zone) | 48 zones, 240 boss, 816 créatures (`build_reborn_creatures.py --game`) | `RebornCreatures.lua` 820 entrées | **Identique** (régénération à blanc, 0 différence) |
| Classes / sorts | 12 classes, 241 sorts (`reborn_audit.py --game`) | lus à l'exécution (`AZS_GEN`, `AZS_SPELLS`) | À jour par construction |
| Bijoux / amulettes | 44 / 22 | lus à l'exécution (`AZS_GEAR`, `AZS_GEN`) | À jour par construction ; catalogue français natif vérifié (`test_reborn --game` : 241 sorts, 66 noms de bijoux) |
| Zones / boss planifiés | 48 zones ; monde 4 : 5 boss planifiés | lus à l'exécution (`AZS_SCHEDULE`, `AZS_GetUpcomingBosses`) | Vérifié contre les 48 catalogues de cartes (`test_reborn --game`) |
| Textes de sorts | serveur (`AZSSPELLTIP`) | `Loadout.SpellEffects` | 478/480 extraits sur données réelles (LOAD-01) |
| `docs/REBORN_CLIENT_INVENTORY.json` | — | comptes 0.6.9 | Regénéré dans cette branche (DOC-01) |
