# Lot 0 — attribution des kills par identité de cible (`0.1.0-reborn.40`, candidate)

Statut : développement, non approuvée (`maintainerAcceptedForPublication: false`). Tests automatisés seulement ; recette en jeu à faire.

## 1. Audit ciblé : contrat 0.7.4 (fichiers du jeu en lecture seule)

| Élément | Source installée | Ce qu'il garantit |
|---|---|---|
| `anchorId` | `AzerothSurvivorsAPI/CombatText.lua:120` : `anchorId = dstGuid` | GUID de la cible touchée (identité unique ; noms homonymes distincts) |
| Source des événements | `CombatText.lua:80-87` (`Mine`) et `:117` | Seuls les coups du héros ou de ses unités (affiliation « mine » : familiers, invocations) entrent dans le flux. **Les coups des coéquipiers n'y sont jamais.** |
| `sourceGuid`, `sourceName` | `CombatText.lua:121-122` | Distingue le héros (`UnitGUID("player")`) de ses familiers et invocations |
| `overkill` | `CombatText.lua:126` (mêlée), `:130-131` (sorts, périodiques compris) | Valeur du combat log 3.3.5a |
| `PARTY_KILL` | `Shims.lua:426-430` | Écrit « You have slain X! » seulement si la source est le héros (`fromMe`, pas les familiers). Ligne de chat **par nom**. |
| `UNIT_DIED` | `Shims.lua:431-436` | Écrit « X dies. » pour toute mort hostile non créditée au héros, **y compris les kills des coéquipiers et des familiers**. Ligne de chat **par nom**. |

**Sémantique de `overkill` mesurée** sur des données réelles 0.7.4 (SavedVariables d'AzerothStatsReborn, coups reçus enregistrés) :

- **836 coups non mortels avec `overkill = 0`**, aucun `-1` ;
- les coups mortels enregistrés ont `overkill > 0` (par exemple 3 et 65).

Conséquence : `overkill > 0` signale un coup mortel ; `overkill = 0` ne permet pas de distinguer « non mortel » de « mortel pile à 0 PV ».

*Constat d'interopérabilité, sans modification* : l'heuristique `overkill >= 0` d'AzerothStatsReborn (`Reborn.lua:845`) classerait des coups non mortels comme fatals sur ce serveur.

### Pourquoi pas `PARTY_KILL` ni `UNIT_DIED`

- **`PARTY_KILL`** : crédite le héros mais pas ses familiers, et ne dit pas quel sort a tué.
- **`UNIT_DIED`** : ne dit pas qui a tué. En coop, il ne permet pas de distinguer un kill du héros d'un kill de coéquipier.
- **Lignes de chat** : elles ne portent que des noms.
- **Flux natif** : il donne à la fois le tueur (forcément le héros ou une de ses unités), le sort exact, le GUID de la cible et le caractère mortel du coup. **C'est la seule source où l'identité de la cible et celle du tueur sont toutes deux fiables.**

## 2. Correctif (`MeterLedger.lua` uniquement)

Un kill est crédité **seulement** sur un événement du flux qui remplit trois conditions :

- `overkill` numérique et strictement positif ;
- `anchorId` est une chaîne non vide (cible identifiée) ;
- ce GUID n'a pas déjà été crédité.

Le kill va au livre de l'événement : sort du héros, ou « Familier: Sort » / « Invocation: Melee ». C'est la même clé que les coups, et elle ne fusionne pas avec un sort homonyme du héros.

- **Déduplication** : plusieurs coups mortels sur un même cadavre (ticks de zone dans le même tick serveur) ne comptent qu'une fois. Le premier coup mortel lu possède le kill.
- **Mémoire bornée** : les GUID crédités expirent après 10 s ; balayage au plus une fois par seconde.
- **Réinitialisation** : changement de partie (`AZS_API_RunId`) ou reset du compteur.
- **Lignes de mort du chat** : ignorées tant que le flux existe. Elles servent seulement à vider le flux plus tôt, pour un affichage immédiat.
- **Client sans flux** (héritage) : comportement inchangé, crédit par nom (limite documentée).

## 3. Tests de non-régression

`tests/reborn_kill_attribution.lua`, exécuté sous Lua 5.1 (`test_reborn.py`) et Lua 5.0.3 (`native50.lua`) :

1. Ennemis homonymes : le kill va au sort qui a tué *ce* GUID.
2. `overkill = 0` et lignes « dies » / « You have slain » : aucun kill inventé.
3. Deux coups mortels sur le même cadavre : un seul kill.
4. Coop : le kill d'un coéquipier, avec ligne « dies » après un coup du héros, n'est pas crédité.
5. Familier (« Imp: Firebolt ») et invocation en mêlée (« Infernal: Melee ») : crédités à leur livre, jamais au sort homonyme du héros.
6. Cible inconnue (pas de GUID, GUID vide) ou `overkill` non numérique ou négatif : aucun kill, mais les coups restent comptés.
7. Vue Kills : comptes exacts.
8. Changement de partie : remise à zéro ; un GUID réutilisé dans la partie suivante compte à nouveau.
9. 300 kills puis expiration : mémoire bornée.
10. Client sans flux : repli par nom inchangé.

`reborn_meter_feed.lua` §9 a été adapté : son attente reposait volontairement sur l'ancien crédit par ligne de mort. Elle vérifie désormais le crédit par coup mortel.

**Résultats locaux** : build_locales, locale tokens, runner coverage, fonts, audit, `verify.py --lua50` (Lua 5.0.3), `test_reborn.py` et `test_reborn.py --game` (0.7.4 installée). EXIT 0.

## 4. Risques et limites

| Limite | Effet | Mesure |
|---|---|---|
| Coup mortel exact (`overkill = 0` alors que la cible meurt) | Kill **non** compté : légère sous-estimation, jamais de surestimation | Comparer au compteur natif en recette (§5) |
| Événements perdus du flux (compteur masqué, trou de plus de 3 s de l'anneau) | Kills manqués pendant ce temps, comme les coups | Compteur `FieldKitMeterLedger.feed.missed`. L'affichage « échantillon partiel » est prévu au Lot 1. |
| Sémantique de `overkill` déduite de coups **reçus** par le joueur | Hypothèse : les coups **donnés** suivent la même convention (même paquet 3.3.5a) | **À confirmer en jeu**. Une recette qui montre 0 kill malgré des morts invaliderait le lot. |
| Kills par effets non issus du flux (environnement, explosions sans source « mine ») | Non comptés | Comportement voulu : sans identité du tueur, pas de kill |

## 5. Recette en jeu

1. **Solo**, 5 minutes avec Consécration et Bouclier du vengeur. Fin de partie :
   - total de la vue Kills de FieldKit ≤ `AZS_RUN.kills`, affiché par le jeu (« N kills » dans la barre de partie) ;
   - écart attendu faible (coups mortels exacts, ou kills d'effets sans source).
   - `/run local f=FieldKitMeterLedger.feed print(f.kills,f.events,f.missed,f.gaps)` : `kills` > 0 et `missed` = 0 si le compteur est resté ouvert.
2. **Ennemis homonymes** : dans une zone pleine du même monstre, les kills se répartissent entre les sorts réellement utilisés (pas tout sur le dernier sort lancé).
3. **Coop à 2** : laisser le coéquipier tuer seul pendant une minute. Les kills FieldKit du héros n'augmentent pas.
4. **Familier ou invocation** (Démoniste, Chasseur) : la vue Kills contient « NomDuFamilier: Sort ».
5. **Partie suivante** : la vue Kills repart à zéro.

Critère de validation : 1, 3 et 5 conformes, aucune erreur Lua.
