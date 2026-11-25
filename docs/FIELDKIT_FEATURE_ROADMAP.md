# Roadmap FieldKit Reborn

Les lots ci-dessous attendent une validation de périmètre avant tout changement Lua. L’audit de découverte est la première livraison. La candidate .41 reste soumise à recette en jeu. Les futurs lots recopient la procédure de validation [du dépôt](TESTING.md) et complètent la recette dans leur PR.

## Lot D0 · Découverte et base Git

Le checkout FieldKit se trouve dans `fieldkit-reborn/`. Sa branche locale `main` était propre à `7f337c3` (.37), un commit derrière `origin/main` après récupération. Le dépôt parent est indépendant et n’a pas servi de base. Aucun autre worktree FieldKit ni commit de branche locale sans équivalent sur un remote parmi les refs inspectées après fetch. La release stable est `.38` sur `bb85ed6`.

- `main` → `fix/paladin-meter-consecration-039` (`5a75939`, PR #4) → `test/qa01-test-harness` (`7f61d7d`, PR #6) → `fix/lot0-kill-attribution` (`0eb6b74`, PR #7) → `fix/endless-longrun-041` (`63453dd`, PR #8). Les têtes successives portent le fix des critiques périodiques et des icônes, le harnais 5.0, le kill au GUID avec coup mortel, et les correctifs Endless/HUD/antres. Le diff `main...#8` sur .38 comporte 38 fichiers, 1562 ajouts et 265 suppressions.
- `ci/generic-publish` (`6df9c5b`, PR #5) part de `main`. La branche `audit/fieldkit-074` est une sœur du harnais, sur la tête .39. Le benchmark est déjà repris dans .41. La branche de découverte `codex/world-api-discovery` part de la tête vérifiée .41 et garde les anciennes conclusions en référence par commit. Les cinq PR étaient ouvertes, état GitHub `CLEAN` à l’inspection.
- Les deux CI de `63453dd` ont réussi, avec vérification Lua 5.0.3 obligatoire et packaging du candidat de revue. Les dernières CI des PR #4–#7 sont également vertes. Ce statut correspond à leurs commits distants. [PR #4](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/pull/4) · [PR #5](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/pull/5) · [PR #6](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/pull/6) · [PR #7](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/pull/7) · [PR #8](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/pull/8) · [CI de branche](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/actions/runs/45626015749) · [CI de PR](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/actions/runs/45626031322)
- Conserver la pile séparée de l’infrastructure #5. Pendant une prochaine revue empilée, ouvrir la PR du lot contre le sommet runtime approuvé ou explicitement choisi et comparer uniquement son delta. Après fusion autorisée par le mainteneur, retargeter le bon parent ou rebaser une branche de travail après vérification d’équivalence des correctifs. Si une fusion est squashée, vérifier les patchs réellement présents avant de retargeter. Aucun forçage des branches existantes n’est requis.
- Les nouveaux rapports sont des fichiers du dépôt distincts des sources Lua. Le JSON de preuves est régénérable et juxtapose les emplacements des symboles à leurs empreintes sans embarquer les sources natives. [Inventaire API](API_DISCOVERY_CURRENT.md) · [Objets du monde](WORLD_OBJECTS_DISCOVERY.md) · [Faisabilité](WORLD_MARKERS_FEASIBILITY.md) · [Backlog](FIELDKIT_NEW_FEATURES_BACKLOG.md) · [Demandes à SNX](DEVELOPER_API_REQUESTS.md)

## Lot R1 · Portail gobelin

**Proposition à valider.** Indicateur contextuel de présence et distance plane facultative, plus notification optionnelle pour une apparition réellement observée. Le jeu conserve son pion doré. Le lot ne dépend pas d’un appel au serveur. Si la preuve de synchronisation ou de contexte n’est disponible que pour certains modes, limiter la fonction aux cas vérifiés.

1. Recueillir une séquence de référence solo et coop. Faire une campagne avec portail visible, relever le type `v` et le point map2D, puis la disparition sans entrée et la séquence de Trésorerie après entrée. Utiliser une observation en lecture seule approuvée. Comparer avec le pion natif et faire un reload en présence du portail.
2. Vérifier mini-carte ronde et carrée et zoom, joueur et point dans la même zone, carte ouverte sur une autre zone, arène, mort/fin et retour au menu. Tester un changement de partie sur la même carte et un handover. Supprimer l’information si la pose ou le snapshot devient indisponible. Une distance absente garde l’alerte de présence lorsque l’état est valide.
3. Brancher le producteur à la voie de rafraîchissement existante et persister les options par profil. Tests Lua 5.0.3 et Lua 5.1 sur absence, snapshot initial, apparition, doublon, plusieurs points, retrait, données mal formées et verrou de contexte. Relevé des appels et allocations sur un Endless de recette. Les [critères des marqueurs](WORLD_MARKERS_FEASIBILITY.md) s’appliquent.

Sortie du lot après captures de référence, CI verte, notes de recette et ZIP candidat.

## Lot R2 · Coffres, passages et événements

- **R2a.** Réutiliser cache/boss/maudit et prix disponible. Vérifier l’ownership de la mini-carte avant d’étendre les pions. Dédupliquer ce que le jeu montre déjà. Proposer la distinction fonctionnelle via filtres, infobulles ou une ligne de navigation.
- **R2b.** Développer le passage d’arène après clarification de `AZSGATE` et du replay. Scénarios de recette dans au moins une transition simple et à la bifurcation d’ICC. Supprimer les informations d’aile au premier changement observé de contexte.
- **R2c.** Proposer une intégration par événement effectivement vérifié, avec une alerte optionnelle désactivable. Valider les types exacts et le comportement du banner natif avant d’ajouter de nouvelles catégories. Le HUD saisonnier existant couvre déjà monnaie et compteur.

## Lot R3 · Réanimation, boss et coût de projection

Prioriser la réanimation et les objectifs à haute valeur si la limite de projection est atteinte. Conserver l’accès aux gardiens de rang 0. Ajouter des mesures ciblées sans modifier le gameplay. Réutiliser les points fixes des antres et distinguer leurs occupants mobiles. Recette Endless longue durée requise pour les hautes valeurs numériques et les renouvellements. Tester baisse de charge, nombre d’allocations, latence d’affichage, nettoyage et réversibilité de toutes les options.

## Lot R4 · Informations de session

Aborder dans des PR distinctes les minuteurs d’invocations, la qualité du compteur (dont pertes et critiques), la fiche de capacités et un bilan compact de fin. Le cache du compteur PERF-01 peut être traité en parallèle de la navigation si on établit son coût en jeu et un contrat de fraîcheur. Les fonctions de chaque lot réutilisent le HUD, les sources et les profils existants.

## Lot dépendant de SNX · Runes et objets sans contrat

Identifier le visuel jaune en partie, puis valider la surface publique convenue. Le premier test fonctionnel doit confronter un objet visible à un snapshot réel avec ID, coordonnées et disparition. Sans cette suite de preuves, garder le repérage en catégorie C. Même règle pour les autres objets non typés, les cristaux volontairement masqués et les dangers seulement graphiques.

## Validation et livraison d’un lot de runtime approuvé

```powershell
python tools/build_locales.py --check
python tests/test_locale_tokens.py
python tests/test_runner_coverage.py
python tools/check_locale_fonts.py
python tools/audit.py
python tools/verify.py --lua50 "<binaire Lua 5.0.3>"
python tools/test_reborn.py --game "<racine du jeu>"
python tools/bench_fieldkit.py
python tools/audit_world_discovery.py --game "<racine du jeu>" --check docs/WORLD_API_EVIDENCE.json
```

Le dernier audit peut diverger légitimement lorsqu’un nouveau client est installé. Requalifier le contexte et les points consommés avant d’actualiser sa référence. Utiliser les tests ciblés de chaque lot et les modes réellement disponibles. Rejouer le set de régression .39/.40/.41 et vérifier SavedVariables, 14 langues, thèmes, profils et affichage natif. Publier dans la PR les résultats effectivement observés et la procédure de recette solo/co-op.

Lancer le workflow de **candidat de revue** et les garde-fous de `tools/package.py` après validation locale. Le ZIP doit commencer par `AzerothFieldKitReborn/`, contenir les licences et données requises, exclure les sources de développement, avoir des versions cohérentes avec le TOC et être reproductible sur deux exécutions du même commit et de son environnement. Contrôler intégrité ZIP et SHA-256. Joindre à la PR le lien de CI, le ZIP ou son artifact de recette, un protocole en jeu et un changelog Discord en anglais. Demander une validation distincte avant fusion, release ou soumission au registre. Aucune archive de nouveau runtime n’est nécessaire pour le lot D0.

## Mesures de référence pour choisir les lots

Le benchmark existant a été rejoué sur .41 sous Lua 5.1 via Lupa, sur l’hôte Windows. À 20/120/512 lignes, la lecture synthétique du compteur a pris 0,370/2,535/18,210 ms et alloué environ 43/250/1061 KiB par lecture (GC suspendu dans le benchmark). Le drain synthétique à 256/1024/2048 événements a pris 7,55/35,60/66,55 ms par poll. Les deux plus grands scénarios dépassent la capacité de l’anneau natif de 512 et servent à éprouver le traitement de pages. Ces mesures portent sur les fixtures et le calcul FieldKit, sans construction d’un snapshot natif, rendu du moteur ni impact FPS mesuré. Elles motivent un lot de navigation sans délai de polling court et sans parcours de l’ensemble des entités. [Audit historique des performances](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/blob/b739f7ba97e3a3c0dfcac546d222385866580e79/docs/FIELDKIT_PERFORMANCE_AUDIT.md)

Pendant R1, viser aucun scan d’unités, une seule lecture de pose au plus par passe d’interface et un décodage uniquement à réception d’un changement. Mesurer les coûts en partie en suivant [le protocole de faisabilité](WORLD_MARKERS_FEASIBILITY.md#charge-et-critères-de-recette).

## Vérifications de la branche d’audit

- Locale, tokens, couverture des suites, polices des 14 langues et audit statique (72 modules Lua, 267 textures TGA) passent. `verify.py` passe en Lua 5.1. `test_reborn.py --game` passe avec exécution de Lua installé dans le harnais et rapporte `liveGameTest=false`.
- Sonde locale hors jeu avec des entrées synthétiques. Le Lua installé valide le décodage du type `v`, l’icône dorée, la pose 2D par le même calcul natif, le bord de la mini-carte et le retrait sur liste vide. Le parseur des passages accepte deux portails avec leurs IDs, positions et boss, et gère une liste vide. Ces tests valident le comportement des consommateurs, pas la réception réelle de ces messages.
- Le harnais natif complet passe avec les 72 modules sous Lua 5.0.3 officiel compilé avec GCC dans un conteneur Linux sans réseau. L’archive source a été vérifiée avec le SHA-256 du workflow. Les compilations MSVC locales ne terminent pas le même harnais. Un essai ciblé Windows se termine par une violation d’accès 0xC0000005. La vérification Linux et les CI Ubuntu de .41 ont toutes réussi.
- Le relevé JSON a été produit deux fois à l’identique. Les liens locaux et les emplacements Lua cités ont été vérifiés. Le runtime, les tests existants et les workflows du dépôt ne sont pas modifiés.
