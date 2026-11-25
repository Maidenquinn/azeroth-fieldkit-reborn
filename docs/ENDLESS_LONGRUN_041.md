# .41 — Longues parties Endless : diagnostic et correctifs

Candidate `0.1.0-reborn.41`, empilée sur `.40` (attribution des kills inchangée, ses tests sont conservés). Non approuvée.

## Sources utilisées

- **Captures d'écran** : non reçues par l'agent. Elles n'étaient pas jointes au message et aucune n'a été trouvée sur le disque. Les valeurs décrites par le mainteneur servent de référence : environ 756 800 kills, 438 boss, 17 h de partie, dégâts de l'ordre de 10^13 et 3 antres « en combat ».
- **Journal d'erreurs Lua du client** : `UserData/Diagnostics/lua-errors.log`, du 2026-11-25, en lecture seule.
- **Fichiers installés 0.7.4** (lecture seule) :
  - `AzerothSurvivorsAPI/Api.lua` (`AZS_GetLairs`, `AZS_API.GuardianUnits`, `AZS_GetGuardians`, stamps) ;
  - `AzerothSurvivors/Lairs.lua` (ligne `AZSLAIRS`, marques de minicarte) ;
  - `AzerothSurvivors/Core.lua` (`AZS.Short`, `AZS.Fmt`).
- **SavedVariables** de la session : réglages actifs. Thèmes de zone **désactivés**, `cardOpacity` = 70, `meterValues` = 3.

## 1. Gardiens absents et antres bloqués « en combat » (P1) — cause FieldKit confirmée

**Preuve 1 : erreur réelle du client.** `lua-errors.log` (13:11 UTC) contient :

```
runtime error: Min or Max out of range
  [C]: in method 'SetMinMaxValues'
  AzerothFieldKitReborn\FieldKit.lua:614: in upvalue 'ShowBossFrame'
  AzerothFieldKitReborn\FieldKit.lua:767: in upvalue 'UpdateBossFrame'
  AzerothFieldKitReborn\FieldKit.lua:3197: in upvalue 'func'
```

`FieldKit.lua:614` passait les PV max natifs du boss (Endless : bien au-delà de 2^31) à la plage d'une `StatusBar`, que le client refuse.

**Mécanisme.** L'appel est dans la boucle maître (`FieldKit.lua:3197`, étape « scan »). L'erreur interrompait **chaque tick** avant l'étape « données natives » : `RefreshNativeData` (antres, compteurs, épingles), `RunMode`, `Coop`, `NativeTools`, `Loadout`, puis `ZoneThemes.Tick` et `NativeHUD.Update`. La carte des antres gardait donc le **dernier** état affiché, par exemple `awake` (« en combat »), alors que le jeu avait évolué.

**Reproduction sur le code `.40`** (commit `0eb6b74`, client simulé qui refuse les plages supérieures à 2^31) :

- 6 ticks sur 6 en erreur « Min or Max out of range » ;
- **0** rafraîchissement de la carte des antres ;
- un antre passé à `empty` côté natif n'apparaît jamais.

Avec `.41`, le même scénario se rafraîchit et suit l'état natif (`tests/reborn_endless_longrun.lua` §3-4).

**Preuve 2 : second mécanisme, trouvé en reproduisant.** `R.LiveBoss` (`Reborn.lua:52`), `R.HealthColor`, `NativeHUD.lua:98` et la carte des antres (`FieldKit.lua:2210`) lisaient les PV via `FieldKit.Number`, qui rejette toute valeur supérieure à 10^18. Au-delà, un boss ou gardien n'était plus « vivant » pour FieldKit : **son cadre disparaissait** alors que le jeu indiquait toujours son antre `awake`. Sur `.40`, `LiveBoss({hp=3e19, hpm=9e19})` renvoie `false`.

**Contrat natif vérifié** :

- l'état d'un antre est celui de la ligne serveur `AZSLAIRS` (`Lairs.lua`) ;
- `AZS_GetLairs` le marque `active` tant que `state ~= "empty"` ;
- le gardien est `awake` quand l'antre l'est (`Api.lua`, `AZS_API.GuardianUnits`) ;
- la minicarte du jeu marque un antre non vide à l'**emplacement de l'antre** (`mx`, `my`), pas à la position du gardien.

FieldKit affiche l'état natif tel quel et ne masque pas l'affichage natif des antres (le marqueur `"flag"` n'est jamais caché).

**Ce qui n'est pas démontré : une faute du moteur.** Rien sur le disque ne contient l'état natif des antres pendant la session de 17 h. Elle n'est pas encore enregistrée comme partie terminée dans les données disponibles. **Aucun rapport SNX n'est donc émis.** Pour trancher à la prochaine session, utiliser `/fieldkit lairs` (§6) : cette commande affiche ce que le client a réellement reçu et l'âge de la dernière ligne `AZSLAIRS`.

**Correctifs** :

- **Barres en fraction.** `FieldKit.SetBarFraction` (`Runtime.lua`) : toutes les barres alimentées par des valeurs natives tracent une fraction 0..1. Concerne le boss compact et classique, la barre joueur, la bande de boss des antres, l'XP, `ThemeHUD` (santé, ressource, XP) et la cible thématisée. Les montants natifs ne sont jamais modifiés.
- **Boucle maître isolée par étape** (`Step`, `FieldKit.lua`) : une étape en erreur n'arrête plus les autres. Sa première erreur de la session est transmise au gestionnaire d'erreurs du client, donc elle reste visible dans `lua-errors.log`. Elle est comptée dans `FieldKit.stepErrors`.
- **PV au format compteur** (`MeterNumber`, jusqu'à 3,5e38) pour les tests de vie ; les identifiants gardent la validation stricte.
- **Commande `/fieldkit lairs`** : vidage natif en lecture seule.

FieldKit ne masque **jamais** un antre que le jeu déclare en combat. Un gardien absent de `AZS_GetGuardians` est signalé `guardian=not-listed` dans le diagnostic, pas caché.

## 2. Formatage des très grands nombres (P1)

**Causes dans le code** :

- `MeterSuite.lua` (`Short`) : `%.2e` à partir de 10^12, d'où « 7.08e+13 ».
- `ReferenceHUD.lua` (`R.Amount`) : même règle.
- `Settings.lua` (`MeterParts`) : montants et DPS **non abrégés** (`%.0f`, commentaire « displayed unabridged »). Résultat : 14 chiffres dans une colonne de 92 px, d'où les « … » et le débordement.
- `FieldKit.Number` transformait toute valeur supérieure à 10^18 en `?`.
- `PartyDetails.lua` s'arrêtait à « M » (7,08e13 donnait « 70800000.0M »).
- `NativeHUD.lua` et `FieldKit.lua` (`ShortNumber`) : encore d'autres règles.
- `FieldKit_FormatHealth` : PV non abrégés.

**Décision** : un seul format, `FieldKit.Compact` (`Runtime.lua`).

- **Paliers du jeu** (`AzerothSurvivors/Core.lua`, `AZS.Short`) : k, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc. Ce sont les mêmes lettres dans toutes les langues, donc pas d'ambiguïté. Le compteur natif est sur 128 bits et dépasse 2^64 en Endless. Le palier Ud (10^36) ne sert qu'à faire tenir 2^128 dans la colonne.
- **Style FieldKit déjà approuvé** (alpha.34) : valeur exacte et groupée sous 10 000, puis une décimale et l'unité séparée par une espace, avec le séparateur décimal de la langue (« 70,8 T » en français).
- Un nombre juste sous un palier prend ce palier : 999 960 donne « 1.0 M ».
- Jamais de notation scientifique.

**Valeurs exactes** : `FieldKit.Exact` les affiche au survol (total, record non critique, record critique, moyenne, burst, kills), avec tous les chiffres groupés. Au-delà de 2^53, la valeur est préfixée « ~ », car un double ne contient plus chaque unité.

**Bornes testées** :

| Valeur | Affichage |
|---|---|
| 0 | 0 |
| 999 | 999 |
| 1 000 | 1,000 |
| 9 999 | 9,999 |
| 10 000 | 10.0 k |
| 999 949 | 999.9 k |
| 999 999 | 1.0 M |
| 10^9 | 1.0 B |
| 10^12 | 1.0 T |
| 7,08e13 | 70.8 T |
| 10^15 | 1.0 Qa |
| 2^53 | 9.0 Qa |
| 2^64 | 18.4 Qi |
| 10^33 | 1.0 Dc |
| 2^128 | 340.3 Ud |
| nil, NaN, ±infini, texte | ? |
| Négatif | signé |

Les calculs et les valeurs sources sont inchangés ; seule l'écriture change. Les attentes de test qui codaient l'ancien format ont été réécrites via `FieldKit.Compact`, avec un commentaire explicatif. Fichiers concernés : `card_preferences`, `party_details`, `previews`, `tests`, `reborn`.

## 3. Lisibilité et transparence (P1)

Superposition réelle d'une carte FieldKit (thème Chronicle, celui de la session) :

| Calque | Contenu | Opacité |
|---|---|---|
| `BACKGROUND` | `skin.base` et `skin.grain` | `cardOpacity` (0,70 dans la session) |
| `BORDER` | cadre en 9 morceaux | centre à `cardOpacity` |
| Lignes du compteur | `StatusBar` enfants (niveau +1) | remplissage coloré à 45-55 % |
| `OVERLAY` | textes | — |

La plaque de contraste de `.38` (0,94) n'existait que sur les fenêtres du compteur (`MeterSuite.lua`). Les autres cartes de données restaient à 70 % : les effets du jeu transparaissaient.

**Correctifs** :

- **`T.ReadableFloor`** (`Theme.lua`) : une plaque sombre unique (allouée une fois, `BACKGROUND`), dont l'alpha est **calculé** pour porter la couverture totale exactement à 88 %, et seulement quand `cardOpacity` est inférieur à 88 %. La formule est 1-(1-o)(1-p) = 0,88. Au-dessus de 88 %, rien ne change.
  - **Cartes concernées** : cadres de boss, statistiques, équipement, argent, cartes à barres (dégâts subis, antres, compteur classique), détails de groupe, alertes.
  - **Inchangés** : les surfaces décoratives et les cartes des thèmes de zone (leur 0 % « vraiment transparent » est conservé), ainsi que le compteur, qui garde sa plaque de `.38`.
- **Ombre portée** (`FieldKit.TextShadow`) sur les libellés, les colonnes et la colonne des kills du compteur. Elle n'est appliquée que si le client expose la méthode.

**À valider par captures** : le rendu effectif (protocole §5). Ce correctif repose sur l'analyse des calques ; aucune image n'a été vue.

## 4. Colonne des kills (P2)

- Valeur compacte : « 756.8 k » tient dans la colonne de 36 px (l'ancien « 756800 » débordait).
- La clé de mise en page des lignes était le **nombre** de kills : chaque kill recalculait la géométrie de la ligne. C'est maintenant la seule **présence** d'une colonne kills (`Settings.lua`, `killKey`).
- La vue Kills réutilise les mêmes lignes. Les tests couvrent les vues Dégâts, Kills, Boss puis Dégâts, la fenêtre détachée, la fenêtre redimensionnée et un nom long.

## 5. Performances

**Mesures synthétiques** (Lua 5.1, client simulé ; elles ne prouvent pas les performances en jeu) :

| Mesure | Avant | Après |
|---|---|---|
| `FieldKit.Compact` | — | 1,45 µs par appel |
| Mise à jour du compteur (8 sources de 10^13) | 0,17 ms (`.40`) | 0,20 ms (`.41`), même allocation (22,7 Ko) |
| Flux natif, par 256 événements (`tools/bench_fieldkit.py`) | 60 Ko (audit) | 4,3 Ko (`.40`/`.41`) : `.40` a supprimé la table de « dernier coup » allouée à chaque coup |
| Lecture du compteur | — | inchangée : le cache prévu au Lot 2 n'est pas inclus ici |

**Corrigé dans ce lot** : la colonne des kills ne relance plus la mise en page à chaque kill.

**Accumulation entre parties** : livres, kills et GUID crédités sont remis à zéro à chaque changement de partie. Les GUID expirent après 10 s.

**Non mesuré** : la consommation réelle en jeu. Voir le protocole ci-dessous, passe `/fieldkit diag`.

## 6. Protocole de test en longue partie Endless

1. Installer le ZIP `.41` (sauvegarder d'abord le dossier de l'addon et ses SavedVariables).
2. Lancer une partie Endless avec la classe et le build habituels. Vider `UserData/Diagnostics/lua-errors.log` ou noter sa taille de départ.
3. Au début de la partie, lancer `/fieldkit diag on`.
4. Toutes les 2 heures environ, puis dès qu'un antre semble bloqué :
   - `/fieldkit lairs` et capture du chat ;
   - capture du compteur (vues Dégâts, Kills, Boss), de la carte des antres et de la minicarte.
5. Points à vérifier :
   - aucun « e+ » ni « … » dans les colonnes ;
   - kills compacts et alignés ;
   - les PV des boss s'affichent, et les barres des boss et gardiens restent visibles au-delà de 10^18 ;
   - un antre terminé quitte l'état « en combat » au tick suivant ;
   - `FieldKit step errors: none` dans `/fieldkit lairs`.
6. Si un antre reste `awake` dans `/fieldkit lairs` (donc côté natif) **avec un `lastLairLine` récent**, sans gardien visible pendant plusieurs minutes : faute côté jeu probable. Remplir le §7 avec ces sorties.
7. En fin de session :
   - `/fieldkit diag` (opérations, histogramme des frames, pires frames) ;
   - joindre `lua-errors.log`, qui ne doit plus contenir « Min or Max out of range ».
8. **Critère de validation** :
   - lisibilité correcte à `cardOpacity` = 70 ;
   - aucune erreur FieldKit ;
   - antres conformes à `/fieldkit lairs` ;
   - kills cohérents avec `AZS_RUN.kills` (rappel `.40`).

## 7. Modèle de rapport SNX (à n'utiliser que si le §6.6 le confirme)

> **Azeroth Survivors: Reborn 0.7.4 — lair stays `awake` with no guardian in a long endless run**
> - Build: 0.7.4 (serial 1795141447), endless, <class>, run time <hh:mm>, bosses <n>, kills <n>.
> - Native data (from `/fieldkit lairs`, a read-only dump of `AZS_LAIRS` / `AZS_GetGuardians`): lair #<i> `state=awake id=<id> guardian=<listed/not-listed> hp=<hp>/<hpm>`, last `AZSLAIRS` line <s> s ago.
> - Expected: the lair returns to `empty` (with `left`) once its guardian is gone.
> - Observed: `awake` for <minutes> while no guardian is present in the world or on the map.
> - Reproduction: endless run past <hours>; let a lair guardian <die / despawn / leave>; watch `AZS_LAIRS`.
> - Attachments: dumps at T0 and T+5 min, screenshots, `lua-errors.log`.

## 8. Limites

- **Seuil de `SetMinMaxValues`** : la valeur exacte refusée par le client 0.7.4 n'est pas publiée. Le test émule un refus au-delà de 2^31, ce qui est une hypothèse. Le correctif n'en dépend pas, puisque les barres reçoivent toujours [0, 1].
- **Faute moteur sur les antres** : ni démontrée, ni exclue. Il faut un vidage `/fieldkit lairs` en situation.
- **Rendu visuel** : non vérifié par l'agent ; captures nécessaires.
- **Thèmes de zone** : désactivés dans la session. Leurs cartes ont reçu le format compact (`R.Amount`), mais pas le plancher de lisibilité, par choix (leur option 0 % est conservée).

## 9. Changelog Discord (anglais, à publier seulement après validation)

> **Azeroth FieldKit Reborn 0.1.0-reborn.41 — long endless runs (test build)**
> • Huge numbers are readable again: one compact format everywhere using the game's own units (k, M, B, T, Qa, Qi…), no more `7.08e+13`, cut-off digits or overlapping columns. Hover a row for the exact value.
> • Fixed a boss health bar error in very long endless runs that silently froze the rest of the HUD, which is why lairs could stay "in combat" and the meter or map stopped updating.
> • Bosses and guardians with astronomical health no longer vanish from FieldKit's frames.
> • Data cards stay readable over spell effects (minimum 88 % background; your opacity setting still applies above that). Meter text has a subtle shadow.
> • Kill counts are compact and stay aligned.
> • New `/fieldkit lairs` shows exactly what the game reports for each lair and guardian.
> • Kill attribution from .40 is unchanged.
