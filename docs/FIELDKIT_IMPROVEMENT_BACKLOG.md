# FieldKit — backlog d'améliorations (jeu 0.7.4)

Ce backlog ne retient que les éléments **réalisables avec ce que le client 0.7.4 expose réellement**. Les disponibilités ont été vérifiées dans le Lua installé ; voir [la couverture API](FIELDKIT_API_COVERAGE_074.md).

Les fonctionnalités déjà couvertes par AzerothStatsReborn (historique de parties), Reborn Build Planner (builds, talents) ou ASR Advisor (conseils de choix) sont exclues.

Échelles utilisées :

- **Complexité** : S (< 1 jour), M (1–3 jours), L (> 3 jours).
- **Coût en performances** : ↓ (diminue), = (neutre), ↑ (ajoute du travail).

## 1. Correctifs fonctionnels (issus du registre d'anomalies)

| # | Élément | Utilité joueur | API / données | Dispo 0.7.4 | Complexité | Perf | Compatibilité architecture | Risques | Priorité |
|---|---|---|---|---|---|---|---|---|---|
| F1 | Kills et dernier coup indexés par GUID (STAT-01) | Kills par sort exacts, coop juste | `AZS_GetCombatTextEvents` (`anchorId`) ; `COMBAT_LOG_EVENT_UNFILTERED` `PARTY_KILL` | Oui (`CombatText.lua:120` du jeu ; `RebornPresentation.lua:117` lit déjà le combat log) | M | = | MeterLedger seul | Les valeurs de la vue Kills changent | **Haute** |
| F2 | Burst horodaté sur `e.at`, fenêtre glissante (STAT-02) | Record de burst fiable | champ `at` du flux | Oui | S | = | MeterLedger | Faible | Haute |
| F3 | Texte flottant et pop-ups de critiques alimentés par le flux (CT-01) | Les critiques de Consécration apparaissent à l'écran | `AZS_GetCombatTextEvents` | Oui | M | = | CombatText, LegacyCrits | Double affichage : tests requis | Haute |
| F4 | Motif FR « : N dégâts » et distinction total / par tick (LOAD-01) | Fiches de DoT de Chasseur complètes | `AZS_SPELLTIPS` | Oui | S | = | Loadout | Faible | Moyenne |
| F5 | « Échantillon partiel » dans l'infobulle (STAT-03) | Comprendre un taux de critique incomplet | `FieldKitMeterLedger.feed` | Oui | S | = | MeterLedger | Nul | Moyenne |

## 2. Techniques et qualité

| # | Élément | Bénéfice | Complexité | Perf | Risques | Priorité |
|---|---|---|---|---|---|---|
| T1 | Cache de `MeterLedger.Read` clé par stamp natif (PERF-01) | Environ −80 % de lectures du compteur, moins de déchets en Endless | M | ↓↓ | Clé de cache incomplète : tests d'égalité requis | **Haute** |
| T2 | Réparer `native50.lua` (liste issue du TOC, fixtures neutres) et réintégrer `meter_suite`, `combat_world`, `boss_timeline` (QA-01) | Une vraie porte Lua 5.0 et des tests du compteur et de la timeline | M | = | Nul en runtime | **Haute** |
| T3 | Job CI Lua 5.0.3 (compilation des sources officielles dans le runner) | Garantit la compatibilité 1.12 à chaque PR | M | = | Durée de la CI | Moyenne |
| T4 | Workflow de publication générique déclenché par tag (REL-01) | Plus de coche rouge à la fusion ; release reproductible | S | = | Garde-fous à conserver | Haute avant la fusion de `.39` |
| T5 | Allocations du flux : mémoïsation de `SpellBase`, réutilisation des tables (PERF-02) | Environ −50 % d'allocations en AoE dense (estimation) | S | ↓ | Faible | Moyenne |
| T6 | Ajouter `tools/audit_fieldkit_074.py` et `bench_fieldkit.py` au rituel de release (déjà dans cette branche) | Matrice API et budget de performance suivis à chaque version du jeu | S | = | Nul | Moyenne |
| T7 | Ranger les ~100 notes de release historiques dans `docs/history/` | Lisibilité du dépôt | S | = | Liens internes à corriger | Basse |
| T8 | Découper `FieldKit.lua` (3 283 lignes) : boucle maître, plaques, cartes héritées | Maintenabilité | L | = | Régressions : uniquement derrière T2 | Basse (après T2) |

## 3. UX/UI

| # | Élément | Bénéfice | Complexité | Priorité |
|---|---|---|---|---|
| U1 | Glossaire de combat × 12 langues, correction d'environ 30 clés (I18N-01), règle anti-contresens dans `build_locales.py` | Libellés corrects pour tous les joueurs non francophones | M | **Haute** |
| U2 | Plancher de contraste commun aux cartes de données (UX-02) | Lisibilité à faible opacité | S–M | Haute (après captures) |
| U3 | Clés localisées « Max hit (non-crit) », « DPS » (I18N-02) | Cohérence | S | Moyenne |
| U4 | Repère non chromatique pour les critiques (UX-04) | Accessibilité (daltonisme) | S | Moyenne |
| U5 | Options non supportées grisées, avec la raison (UX-01) | Moins de confusion | S | Basse |

## 4. Nouvelles fonctionnalités fondées sur l'API 0.7.4

| # | Fonctionnalité | Utilité concrète | API / données | Dispo vérifiée | Complexité | Perf | Architecture | Risques | Priorité |
|---|---|---|---|---|---|---|---|---|---|
| N1 | **Critique attendu / observé** par sort : taux de critique de la fiche, plafond et taux observé sur le flux | Repérer un sort qui ne critique pas, ou un plafond atteint, sans enquête comme celle de `.39` | `AZS_STATS.crit`, `AZS_GetStatCaps().crit`, `MeterLedger.Stats` | Oui (`Api.lua:120-133`) | S | = | Infobulle du compteur | La règle serveur reste inconnue : présenter un écart, pas un verdict | **Haute** |
| N2 | **Records de la partie** (max crit, max non-crit, burst, kills par sort) sur une carte de fin de partie | Retour immédiat sur la partie, sans dupliquer l'historique d'AzerothStatsReborn | `AZS_GetRunSummary` / `AZS_END`, livres de MeterLedger | Oui (`Api.lua:246`) | M | = | Nouveau petit module | Ne rien persister au-delà de la dernière partie (SavedVariables bornées) | Moyenne |
| N3 | **Capacités complètes** : passifs, icônes et textes natifs dans la carte des sorts | Fiche fidèle au jeu, y compris les passifs absents de `AZS_SPELLS` | `AZS_RequestAbilities` + `AZS_ABILITIES` | Oui (`Api.lua:159-172`) | M | = (requête à la demande seulement) | Loadout | Envoie une commande serveur : jamais en boucle | Moyenne |
| N4 | **Progression vers le boss final** dans la timeline | Anticipation en partie normale | `AZS_GetRunLength` | Oui (`Api.lua:241`) | S | = | BossTimeline | Absent en Endless : masquer | Moyenne |
| N5 | **Minuteurs d'invocations individuelles** | Gestion des invocations temporaires (Démoniste, Chaman…) | `AZS_GetSummons`, `AZS_GetSummonCount` | Oui (`Api.lua:359, 384`) | S | = | NativeTools | Faible | Basse |
| N6 | **Alerte « totems au plafond »** | Éviter de poser un totem perdu | `AZS_GetTotemCount` | Oui (`Api.lua:433`) | S | = | NativeTools / alertes | Faible | Basse |
| N7 | **Comparaison entre rangs** d'un même sort (dégâts moyens et critiques par rang dans la partie) | Mesurer le gain d'un rang | Flux (`spellId` par rang) et `AZS_SPELLS.rank` | Oui | M | = | MeterLedger (sous-livres par rang) | Mémoire : borner le nombre de rangs | Basse |
| N8 | **Diagnostics intégrés du flux** : événements, trous, pertes dans `/fieldkit diag` | Support utilisateur ; prouve la complétude des statistiques | `FieldKitMeterLedger.feed` | Oui | S | = | Diagnostics | Nul | Moyenne |
| N9 | **API publique en lecture seule** pour les autres addons (`FieldKitMeterLedger.Stats` documenté et versionné) | Interopérabilité sans dupliquer de travail | interne | Oui | S | = | Contrat à figer | Maintenir la compatibilité ascendante | Basse |
| N10 | **Avertissement de double texte de combat** si ASRCombatText est chargé | Évite deux nombres flottants par coup | `IsAddOnLoaded` | Oui (API client) | S | = | CombatOptions | Hypothèse à confirmer en jeu | Basse |

**Écartées volontairement** :

- Assistant de choix de cartes (`AZS_CARDS`) : domaine d'ASR Advisor.
- Planification de talents (`AZS_TALENT_*`) : domaine de Reborn Build Planner.
- Historique multi-parties : domaine d'AzerothStatsReborn.
- Toute reconstruction de totaux depuis le texte de combat : les totaux natifs font foi.
