# FieldKit — roadmap de développement (après l'audit 0.7.4)

## Prérequis : publier `.39`

`.39` est validée en jeu par le mainteneur et a 2 CI vertes. Avant de la fusionner :

1. Rendre le workflow de publication générique (T4 / REL-01).
2. Puis fusionner et publier, sur ta décision.

Les lots ci-dessous partent de `main` une fois `.39` fusionnée. Chaque lot a sa branche dédiée et sa PR.

Pour chaque lot :

- **Recette auto** : CI verte, `verify.py --lua50` dès que le lot 1 est fait, et le bench comparé à la référence de cet audit.
- **Recette manuelle** : protocole en jeu fourni avec la PR.

## Lot 0 — Correctifs bloquants (données fausses)

Branche : `fix/lot0-kill-attribution`.

| Tâche | Réf. | Complexité |
|---|---|---|
| Kills et dernier coup indexés par GUID ; crédit sur `PARTY_KILL` du héros ou de son familier ; repli sur le nom | STAT-01 / F1 | M |
| Expiration des entrées `lastBlow` (≤ 3 s après le dernier coup) | PERF (§5) | S |

- **Dépendances** : aucune.
- **Bénéfice** : vue Kills exacte, y compris en coop.
- **Tests** : homonymes, kill d'un coéquipier, familier, mort sans coup, `/reload`, très longue partie.
- **Recette en jeu** : partie solo avec deux sorts de zone, puis comparer les kills affichés avec le nombre d'ennemis tués de la partie. Coop à 2 : les kills du coéquipier ne sont pas crédités.

Aucun crash ni perte de configuration n'a été trouvé : le lot 0 ne contient que ce correctif de données.

## Lot 1 — Fiabilité, tests et cas limites

Branche : `fix/lot1-reliability`.

| Tâche | Réf. | Complexité |
|---|---|---|
| Réparer `native50.lua` (liste du TOC, presets neutres) ; mettre à jour `security.lua` et les fixtures ; réintégrer `meter_suite`, `combat_world`, `boss_timeline` dans `test_reborn.py` | QA-01 / T2 | M |
| Job CI Lua 5.0.3 | T3 | M |
| Burst sur `e.at`, fenêtre glissante | STAT-02 / F2 | S |
| Texte flottant et pop-ups de critiques alimentés par le flux, sans double émission | CT-01 / F3 | M |
| Motif « : N dégâts » et libellé total / par tick | LOAD-01 / F4 | S |
| Échantillon partiel signalé ; compteurs du flux dans `/fieldkit diag` | STAT-03 / F5 / N8 | S |

- **Dépendances** : T2 avant toute autre tâche du lot, pour récupérer les tests du compteur.
- **Bénéfice** : statistiques cohérentes sur tous les affichages ; porte qualité réelle.
- **Recette** : Paladin, Consécration visible en critique dans le texte flottant ; burst stable après masquage puis réaffichage du compteur.

## Lot 2 — Performances

Branche : `perf/lot2-meter-cache`.

| Tâche | Réf. | Complexité |
|---|---|---|
| Cache de `MeterLedger.Read` par `(vue, stamp natif, checkpoint, fenêtre)`, partagé par tous les consommateurs | PERF-01 / T1 | M |
| Allocations du flux (`SpellBase` mémoïsé, réutilisation des tables) | PERF-02 / T5 | S |
| Cache `DisplayName` par langue ; parcours des glisser seulement si un glisser est actif | PERF-04/05 | S |

- **Dépendances** : lot 1, pour que les tests du compteur tournent.
- **Bénéfice** : environ −80 % de lectures du compteur, moins de déchets en Endless.
- **Tests** : égalité cache / sans cache sur toutes les vues, invalidation par stamp, reset et changement de fenêtre ; `bench_fieldkit.py` doit montrer la baisse.
- **Recette** : protocole `/fieldkit diag` (Performances §7), passes A et B avant et après.

## Lot 3 — UX/UI

Branche : `ux/lot3-readability-i18n`.

| Tâche | Réf. | Complexité |
|---|---|---|
| Glossaire de combat et correction des clés dans les 12 langues ; règle anti-contresens dans `build_locales.py` | I18N-01 / U1 | M |
| Clés localisées « (non-crit) » et « DPS » | I18N-02 / U3 | S |
| Plancher de contraste commun aux cartes de données (après les captures UX §5) | UX-02 / U2 | S–M |
| Repère non chromatique pour les critiques ; options non supportées grisées | U4, U5 | S |

- **Dépendances** : captures du protocole UX §5 pour U2.
- **Bénéfice** : lisibilité et traductions correctes pour 12 langues.
- **Recette** : captures avant et après dans fr, de, ru et zh, opacité 0, 40 et 100 %.

## Lot 4 — Fonctionnalités (API 0.7.4)

Branche par fonctionnalité : `feat/...`. Ordre recommandé :

1. N1 : critique attendu / observé.
2. N8 : diagnostics du flux.
3. N4 : progression vers le boss final.
4. N2 : records de fin de partie.
5. N3 : capacités complètes avec passifs.
6. N5 / N6 : invocations et totems.
7. N7 : comparaison des rangs.
8. N9 / N10 : interopérabilité.

- **Dépendances** : lot 2 pour N1, N2 et N7, qui s'appuient sur le compteur.
- **Tests** : mocks basés sur les contrats installés, et `test_reborn.py --game`.
- **Recette** : une partie par fonctionnalité.

## Lot 5 — Qualité et maintenance

Branche : `chore/lot5-maintenance`.

| Tâche | Réf. |
|---|---|
| Workflow de publication générique par tag | REL-01 / T4 (à avancer avant la fusion de `.39`) |
| `audit_fieldkit_074.py` et `bench_fieldkit.py` dans le rituel de release ; inventaires `docs/REBORN_*.json` regénérés à chaque version du jeu | T6, DOC-01 |
| Rangement de `docs/` | T7 |
| Découpage de `FieldKit.lua`, une fois les lots 1 et 2 en place | T8 |
| Collecte de textes de sorts réels pour les classes non couvertes (Guerrier, Démoniste, Chaman, Druide, Prêtre, Voleur, Chevalier de la mort, Moine, Chasseur de démons) | limite de LOAD-01 |

## Synthèse des lots

| Lot | Effort | Valeur | Risque | Ordre |
|---|---|---|---|---|
| Prérequis (T4) | S | Débloque la fusion propre de `.39` | Faible | 1 |
| 0 | M | Données de kills justes | Moyen | 2 |
| 1 | M–L | Fiabilité et porte qualité | Faible | 3 |
| 2 | M | Performances en Endless | Faible | 4 |
| 3 | M | Lisibilité et 12 langues | Faible | 5 (en parallèle de 2 possible) |
| 4 | M–L | Nouvelles capacités | Moyen | 6 |
| 5 | continu | Maintenabilité | Faible | En continu |
