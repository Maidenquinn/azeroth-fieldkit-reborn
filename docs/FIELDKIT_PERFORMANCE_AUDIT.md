# FieldKit — audit des performances (jeu 0.7.4)

## 1. Méthode et limites

| Source | Nature | Limite |
|---|---|---|
| Lecture de code | Tous les `OnUpdate` (23 sites) et la boucle maître `FieldKit.lua:3139` | Statique |
| `tools/bench_fieldkit.py` (nouveau) | Coût **Lua de FieldKit seul**, Lua 5.1 PUC (lupa), client simulé | N'inclut ni la construction native de `AZS_GetMeterSnapshot`, ni le rendu des frames. Temps dépendants du processeur hôte : comparer les scénarios **entre eux**, pas comme des temps de frame en jeu. |
| Diagnostics client (`UserData/Diagnostics`) | FPS, nombre d'entités, blocages du thread principal | Aucune attribution par addon |
| Profileur FieldKit `/fieldkit diag` | Compteurs et temps par opération, histogramme des frames | **Non exécuté** : nécessite le client (protocole §4) |

## 2. Cartographie des chemins chauds

### Boucle maître (`FieldKit.lua:3139-3220`)

À **chaque frame** :

- `FieldKitDiagnostics.Tick` : retour immédiat si désactivé.
- Fin de glisser de secours : parcours des `movableFrames`.
- `IsChoiceScreen` : `pcall(AZS_GetPhase)`.
- `FieldKitCrits.Animate()` : sort au repos (`LegacyCrits.lua:85-90`).
- `PulsePlayerBar()`.

Puis, par intervalle :

| Intervalle | Travail |
|---|---|
| 0,05 s (`SCAN_INTERVAL`) | `KeepCompactBar`, `UpdateBossFrame`, `UpdatePlayerBuffs`, `UpdatePlayerBar` |
| 0,1 s (`PLATE_INTERVAL`) | Filtre des plaques, si activé |
| 0,2 s (`DATA_INTERVAL`) | `FieldKitNative.Watch`, `RefreshNativeData` (stats, équipement, argent, **compteurs**, épingles, antres), `RunMode`, `Coop`, `NativeTools`, `Loadout` (hors écran de choix), dock, `ScreenLayers`, `HudStack`, `CardLayout` |
| 0,5 s | Remise en pile de sécurité |
| Chaque frame | `PartySync.Tick` (sort tôt si inactif), `ZoneThemes.Tick`, `NativeHUD.Update` |

### OnUpdate locaux

Tous sont temporisés, ou actifs seulement quand leur frame est visible :

| Fréquence | Modules |
|---|---|
| 0,05 s | Alignment, CombatText, aura de WorldMarkers |
| 0,1 s | MeterLedger |
| 0,15 s | Preview, dock de l'interface |
| 0,2 s | CopyLog |
| 0,25 s | Interface |
| 0,4 s | Revive de WorldMarkers |
| 0,5 s | WorldAnchors |
| 1 s | Auto-démarrage de WorldMarkers |
| 0,03 s pendant un glisser seulement | ReferenceHUD |

Sont actifs à chaque frame seulement quand ils sont visibles : `PartyDetails`, survol des buffs de `ReferenceHUD`, observateur d'infobulle de `International`, bouton reset de `CombatOptions`.

**Aucun `OnUpdate` ne fait de travail coûteux à chaque frame quand FieldKit est au repos.**

## 3. Mesures synthétiques (`python tools/bench_fieldkit.py`)

| Scénario | ms / opération (hôte) | Ko alloués / opération |
|---|---:|---:|
| `MeterLedger.Read("damage")`, 20 sources | 0,25 | 43 |
| `MeterLedger.Read("damage")`, 120 sources | 1,53 | 250 |
| `MeterLedger.Read("damage")`, 512 sources (maximum lu) | 7,90 | 1 061 |
| Sondage du flux, 256 événements | 3,55 | 60 |
| Sondage du flux, 1 024 événements | 14,6 | 241 |
| Sondage du flux, 2 048 événements (maximum par sondage : 8 pages de 256) | 35,4 | 482 |

**Lecture** :

- Un compteur Paladin typique (10 à 30 sources) coûte environ 0,3–0,5 ms et 50–70 Ko par lecture.
- À 5 lectures par seconde et par consommateur, il génère **250–350 Ko/s de déchets par fenêtre**, plus le même volume côté natif.
- Avec 3 consommateurs actifs (fenêtre principale, HUD thématisé, carte « Damage » du thème), on approche **1 Mo/s**, alors que les données ne changent qu'une fois par seconde.
- Le flux de combat coûte environ 17 µs et 236 octets par événement.

## 4. Points chauds et recommandations

| ID | Constat (preuve) | Optimisation proposée | Gain attendu | Risque |
|---|---|---|---|---|
| PERF-01 | `Read` reconstruit le snapshot natif à chaque appel. Consommateurs : `MeterSuite.lua:128` (par fenêtre), `ReferenceHUD.lua:703`, `:1080`, `ThemeHUD.lua:425`, `NativeData.lua:89`. Fréquence 0,2 s ; le serveur ne publie qu'à 1 Hz (en-tête de `Meter.lua`). | Cache par `(vue, stamp natif, checkpoint, fenêtre)`. Ne repeindre que si le stamp a changé. Les fenêtres récentes (5–120 s) gardent un rafraîchissement à 1 Hz. | ~80 % des lectures supprimées (5 → 1 par seconde), puis partage entre consommateurs | Faible, avec des tests d'égalité cache / sans cache |
| PERF-02 | Allocations par coup dans le flux : table `lastBlow`, `gsub` × 3, `tostring`. | Mémoïser `SpellBase`, réutiliser les tables, indexer par nombre. | ~50 % des allocations du flux (estimation à confirmer par le bench) | Faible |
| PERF-03 | `AttachKillStats` crée une table `Stats` par ligne à chaque lecture. | Absorbé par le cache PERF-01. | Inclus dans PERF-01 | Faible |
| PERF-04 | `FinishLines` appelle `FieldKitReborn.DisplayName` par ligne à chaque lecture. | Cache par nom et par langue, invalidé au changement de langue. | Modéré | Faible |
| PERF-05 | Le parcours de `movableFrames` (`IsMouseButtonDown`) tourne à chaque frame. | Ne parcourir que si un glisser est en cours (drapeau). | Faible | Nul |

À ne **pas** faire : réduire `DATA_INTERVAL` globalement. Les buffs, timers et débuffs en dépendent ; le cache ciblé suffit.

## 5. Fuites et accumulations

| Élément | Constat | Statut |
|---|---|---|
| `books`, `kills`, `byId`, `byIcon`, `lastBlow` (MeterLedger) | Vidés à chaque changement de partie (`L.Boundary`, `AZS_API_RunId`) et à chaque reset. **`lastBlow` grossit pendant une partie** : une entrée par nom de victime (STAT-01, bornée par le nombre de noms distincts). | Acceptable. Devient une entrée par GUID avec la correction STAT-01 : il faudra une expiration (≤ 3 s après le dernier coup). |
| `DB.known` (cache des monstres) | Plafonné à 2 048 (`Config.lua`). Réel : 468. | Sain |
| `frameAnchors`, `cardSizes`, `pos` | Bornés et validés au chargement | Sain |
| Événements | 31 appels `RegisterEvent` littéraux dans 6 modules, plus des enregistrements en boucle (`CombatText.lua:414`, sonde de `GroupHistory`, qui se désenregistre en fin de sonde). Aucun `UnregisterEvent` littéral. Les frames sont permanentes et les gestionnaires sortent tôt quand la fonction est désactivée. Le gestionnaire de bannières est bien désenregistré (`NativeTools`). | Acceptable ; pas de fuite constatée |
| SavedVariables réelles | 3 254 nœuds au total | Sain |

## 6. Scénarios exigeants (estimation à partir des mesures)

| Scénario | Coût FieldKit estimé | Remarque |
|---|---|---|
| Consécration permanente, 60 ennemis, 1 tick/s | ~60 événements/s : ≈ 1 ms/s et 14 Ko/s | Négligeable |
| AoE dense, 2 000 coups/s | ≈ 35 ms/s (3,5 % d'un cœur) et 480 Ko/s | Notable mais borné. PERF-02 le divise environ par deux. |
| Endless long, 120 sources, 3 consommateurs | ≈ 23 ms/s et 3,7 Mo/s de déchets | **Prioritaire** : PERF-01 le divise environ par cinq |

## 7. Protocole de mesure en jeu (à exécuter par le mainteneur)

1. Même zone, même build, partie de 10 minutes.
2. Passe A : `/fieldkit diag on`, compteur ouvert et thème actif. Au bout de 10 minutes : `/fieldkit diag` pour relever les opérations les plus coûteuses, l'histogramme des frames et les 5 pires frames.
3. Passe B : même chose avec le compteur fermé (`meterFrame` désactivé).
4. Passe C : FieldKit désactivé, les autres addons inchangés. Relever les FPS et le nombre de « frame hitch » dans `UserData/Diagnostics/last-context.txt`.
5. Passe D : seul FieldKit actif (AzerothStatsReborn désactivé). Cette passe isole l'effet des SavedVariables de 12 Mo d'AzerothStatsReborn.
6. Joindre les sorties dans une issue. Ces chiffres permettront d'attribuer (ou non) l'observation OBS-01 (6–14 fps, environ 6 300 entités).
