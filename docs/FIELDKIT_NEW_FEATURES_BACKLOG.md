# Backlog des fonctionnalités FieldKit

Références jeu sous `Interface/AddOns/`, FieldKit sur .41 (`63453dd`). **A** signifie que les données requises existent, **B** qu’une variante partielle ou une validation de contrat est nécessaire, **C** qu’un contrat manque. L’existence d’une API dans le code ne remplace pas la recette en jeu. Les budgets ci-dessous sont des estimations. Le [plan de lots](FIELDKIT_FEATURE_ROADMAP.md) indique les dépendances et gates.

## Priorité 1 · Repérage

### Portail gobelin, signal de présence et distance · A/B · complexité moyenne

- **Intérêt.** Prévenir discrètement qu’une occasion de trésor est disponible et donner une distance horizontale, en complément du repère natif.
- **Entrées.** `AZS_RIFT.m` et type `v` (`AzerothSurvivors/Rift.lua:68–128`), `GetPlayerMapPosition` et dimensions `AZS_ZONE.mw/mh` (`Chests.lua:102–153,272–288`). État du portail à partir d’une liste synchronisée. L’identifiant, l’altitude, la durée avant entrée et le contexte de carte dans la source manquent.
- **Conception et coût.** Lecture par changement, ligne contextuelle et alerte via la voie existante de `NativeTools.lua:339–354`. Une pose par rafraîchissement actif au maximum, aucune lecture d’unités. Réglages indépendants de l’affichage et de l’alerte. Maintenir le repère natif, qui a déjà le bon style de carte.
- **Risques et tests.** Paquet périmé devant une transition, premier snapshot déjà actif, double annonce, rotation, carte du monde consultée, coordonnées du mauvais espace. Recette positive et négative en campagne, puis coop/reload et fermeture de portail sans entrée.

### Portail gobelin, marqueur FieldKit de remplacement et projection 3D · C · complexité moyenne

- **Intérêt.** Adapter la taille et les couleurs à la mini-carte FieldKit et, si le point existe en 3D, permettre une projection accessible en jeu.
- **Données.** La carte 2D est confirmée. Il manque un contrôle de visibilité officiel du pion natif, un ID d’instance stable et `x/y/z` pour une position monde (`AzerothSurvivors/Rift.lua:68–118`, `AzerothSurvivorsAPI/Hud.lua:1–47`, `Anchors.lua:197–217`).
- **Conception et coût.** Futur adaptateur dans `WorldPins.lua:25–67` ou `WorldMarkers.lua:164–265` selon le contrat. Un remplacement requiert une prise en charge réversible. Pas de scan de créatures. Quelques frames/points maximum.
- **Risques et tests.** Deux marqueurs au même endroit, restauration après désactivation, changement de thème, options et cartes, poses invalides ou indisponibles. Dépend de la [demande à SNX](DEVELOPER_API_REQUESTS.md).

### Progression de la Trésorerie · B · complexité faible

- **Intérêt.** Rendre visibles le temps et le score dans les layouts FieldKit où cette information améliore la lecture.
- **Entrées.** `AZS_VAULT` fournit `enter/open`, `left,secs,got,of,at` (`AzerothSurvivors/Vault.lua:66–70,426–436,460–510`). Association au portail et signification des états terminaux à confirmer.
- **Conception et coût.** Affichage contextuel O(1) dans `NativeTools` uniquement si une surface complémentaire est utile. Pas de duplication du voile ou de la barre native. Actualiser la valeur textuelle à sa seconde affichée.
- **Risques et tests.** Annulation coop, pause, temps qui expire sans message terminal, reset/fin/reload, score en retard. Valider l’horloge réelle avec le jeu.

### Runes actives et cristaux · C pour localisation, B pour progression de la faille · complexité moyenne

- **Intérêt.** Distinguer un bonus accessible d’un simple effet visuel, permettre le filtrage et retirer le repère à la collecte.
- **Données.** Le jeu décrit trois runes ramassables. `AZS_BUFFS` expose le sort et la durée d’un effet, sans provenance (`Units.lua:63–66`). `Rift.lua:1–5,108–117` décrit `got/need` et prévoit un rendu `c` sans points de cristal transmis selon la source. Variantes machine, portée, position, ID et retrait des runes manquent.
- **Conception et coût.** Identifier le visuel en partie, demander un instantané autorisé à SNX. Le futur adaptateur utiliserait les pools existants et les révisions, avec filtres par type. Le texte du compteur de cristaux peut être O(1) sur changement.
- **Risques et tests.** Confondre aura, cristal ou effet de zone avec un bonus. Valider un exemple de chaque variante et l’état exact avant/après collecte, puis vérifier que pause, sortie et changement de contexte vident la vue. [Guide des objets ramassables](https://azreborn.com/guides/runs-and-zones#pickups)

## Priorité 2 · Navigation et instances

### Coffres différenciés et filtre d’objectif · A · complexité moyenne

- **Intérêt.** Distinguer coffre maudit, trésor gratuit et cache payante, avec prix lisible et choix du type de repère.
- **Entrées.** `AZS_CHESTS.boss`, `id,x/y/z,mx/my,spaceId`, stamp et `AZS_RUN.cache/gold` (`Units.lua:89–91`, `Chests.lua:46–60,272–288`, `AzerothSurvivorsAPI/Api.lua:186–195`). Caches présentes, aucune heure d’apparition future.
- **Conception et coût.** Enrichir le rendu existant `WorldPins.lua:25–67,101–109` ou une ligne de navigation si la surface native est occupée. Étiquettes et catégories stables par snapshot, O(n) à réception puis O(k) visible.
- **Risques et tests.** Deux surfaces de même contenu, suppression partielle, ID réutilisé entre parties, prix inconnu, coût par entrée au zoom, options persistantes et thèmes. Tester les trois genres et les paquets vides.

### Objectif de clé en donjon · B · complexité faible

- **Intérêt.** Donner une échéance lisible dans les thèmes où l’objectif natif se perd, sans révéler une porte ou un coffre caché.
- **Entrées.** `AZS_KEYS` et clés d’arène (`Units.lua:59–61`, `Tracker.lua:280–302,452–472`). Temps natif et état du gardien, sans GUID ni point. Disponibilité des modes de donjon à vérifier à la recette.
- **Conception et coût.** Affichage contextuel dans `NativeTools`. Une lecture sur changement de snapshot et un rafraîchissement de seconde par ligne affichée.
- **Risques et tests.** Tester acquisition, temps épuisé, transition d’arène, source absente et duplicata du tracker. Ne pas placer un repère à la position d’un site statique.

### Direction des passages d’arène · B · complexité moyenne

- **Intérêt.** Choisir une aile ou trouver l’entrée via la mini-carte quand des plaques sont déjà affichées dans le monde.
- **Entrées.** `AZSGATE` et `AZSPASSAGE` (`Passage.lua:325–345,389–406,574–589`), `AZS_GetPlayerPosition` (`Api.lua:565–594`). Coordonnées, ID et liste des boss prouvés à réception. Stabilité publique et replay du snapshot à clarifier.
- **Conception et coût.** Adaptateur d’un seul événement et rendu `WorldPins`, en gardant la plaque native. O(n) à réception et O(k) par passe, indépendante du scan d’unités.
- **Risques et tests.** Deux portails dans ICC, message manqué au reload, changement d’arène au sein d’un même run. Vérifier les cas carte identique, aile choisie, liste vide et affichage en pause.

### Alertes d’événements et objectifs partagés · B · complexité faible à moyenne

- **Intérêt.** Remonter une transition de partie ou une alerte locale filtrée sans surcharger le combat.
- **Entrées.** `AZS_RegisterBannerHandler`, `AZS_EVENT`, `AZS_HEXES`, `AZSPING` (`Api.lua:632–681`, `Events.lua:81–94`, `Units.lua:53–60`, `Anchors.lua:150–195`). Présence de la fête, malédiction et ping confirmés. Classification stable des vagues et coordonnées de certains dangers absentes.
- **Conception et coût.** Étendre une catégorie dans `NativeTools.lua:334–354`, réutiliser des filtres natifs, une notification par ID de même contexte. O(1) par événement avec cache borné.
- **Risques et tests.** Bannières déjà natives, notifications répétées ou localisées. Rejouer types connus/inconnus, PvE standard, Warband et co-op/handover, puis vérifier les usages FR/EN. Aucun envoi automatique de ping.

### Antres, gardiens et boss · A pour qualité de l’existant, B pour capacité/coût · complexité moyenne

- **Intérêt.** Afficher les antres et gardiens appropriés avec moins de repères concurrents, progression utile et cohérence pendant les longues parties.
- **Entrées.** `AZS_LAIRS`, `AZS_UNITS`, `AZS_SCHEDULE`, ancres et stamps (`Lairs.lua:50–116`, `Units.lua:29–37`, `Run.lua:448–449`, `Anchors.lua:246–347`). Pas de minuterie individuelle de capacité confirmée pour un boss.
- **Conception et coût.** Adapter les priorités et la fraîcheur dans `WorldAnchors` / `WorldMarkers` / `WorldPins`. Exclure un scan des unités ordinaires uniquement après avoir préservé les gardiens rang 0. Garder le formatage partagé et les barres .41.
- **Risques et tests.** Perte d’ancres par rang, confusion antre et occupant, charge de la pagination, PV extrêmes, ennemi homonyme, récupération d’erreur par module. Inclure les fixtures de `tests/reborn_world_markers_native.lua` et `tests/reborn_endless_longrun.lua`.

### Coop, réanimation et lisibilité · A/B · complexité moyenne

- **Intérêt.** Donner priorité au joueur relevable et indiquer clairement quand sa position reste indisponible.
- **Entrées.** `AZS_REVIVE`, `AZS_GetDownedPartyMembers` et ancres de groupe (`Revive.lua:150–168`, `Anchors.lua:287–309,497–519`). Position 2D ou 3D selon disponibilité, GUID de résolution et progression. Handover et rapprochement par nom à vérifier.
- **Conception et coût.** Améliorer le rendu existant `WorldMarkers.lua:97–110,189–225,293–301`. Partager une pose du joueur par passe, conserver le plafond de projection et les réglages indépendants. Coût proportionnel au groupe.
- **Risques et tests.** Homonymes, membres hors vue, position 2D seule, plusieurs réanimations simultanées, sortie et déconnexion. Coop réelle, raid Warband, thèmes et absence de fuite des anneaux.

## Priorité 3 · Combat et informations de session

### Minuteurs d’invocations et de procs · A/B · complexité moyenne

- **Intérêt.** Visualiser le temps restant d’une invocation temporaire ou d’un effet natif utile sans ouvrir plusieurs panneaux.
- **Entrées.** `AZS_GetSummons`, `AZS_GetSummonGroups`, `AZS_GetTotems`, `AZS_GetTimers`, `AZS_BUFFS` (`Api.lua:359–455`, `Units.lua:63–66`). Durées, ID des invocations et effets présents. Pas de durée d’effet absente ni position d’invocation déduite.
- **Conception et coût.** Étendre la vue existante `NativeTools` par retour détaillé à la demande. Indexer seulement sur changement de liste et rafraîchir les secondes visibles. O(n), limité aux entrées utiles.
- **Risques et tests.** Confondre effet permanent, inconnu, expiré et cap nul, brouiller les buffs existants. Run en pause, choix, changement de profil, run et handover.

### Couverture des coups critiques et dégâts périodiques · A pour observé, C pour taux attendu par sort · complexité moyenne

- **Intérêt.** Interpréter les statistiques lorsqu’un flux lâche des événements et distinguer l’observation du taux global.
- **Entrées.** `AZS_GetCombatTextEvents` avec `critical,periodic,gap,seq,sourceGuid,anchorId`, stats et caps globaux (`CombatText.lua:9–23,100–205`, `Api.lua:120–137`). Aucune règle effective par sort ou cible dans cette surface.
- **Conception et coût.** Un seul lecteur via `MeterLedger.lua:212` et ses fonctions de flux. Élargir le badge de complétude et les détails sur la fenêtre, tableaux bornés, pas de coût d’un nouveau flux. Garder la comptabilisation .39/.40.
- **Risques et tests.** Double attribution chat/flux, buffs temporaires, échantillon perdu ou zéro valide, identité des familiers, critiques périodiques, coup mortel et run long. Utiliser `tests/reborn_meter_feed.lua` et `tests/reborn_kill_attribution.lua`.

### Fiche des capacités et provenance des bijoux · A/B · complexité moyenne

- **Intérêt.** Voir passifs, textes natifs et effets légendaires portés, en distinguant un effet d’équipement d’une source de dégâts non identifiée.
- **Entrées.** `AZS_RequestAbilities` / `AZS_ABILITIES`, `AZS_GEAR`, `AZS_GetMeterLoadout`, `AZS_GEN.amulets` (`Api.lua:155–172`, `Units.lua:72–74`, `Meter.lua:1139–1264`, `Generated/Content.lua:1352`). Identités de build et slots. La provenance de chaque proc ou coup peut manquer.
- **Conception et coût.** Adapter `Loadout.lua:134,257,421`. Demande de snapshot uniquement sur action explicite, cache par run, aucune demande en arrière-plan. Aucun planificateur de build ou recommandation de carte.
- **Risques et tests.** Chargements asynchrones, traductions, talents des pairs indisponibles, légendaires partageant nom/icône, réception après changement de partie. Tester menus, profil, 14 langues, accès sans réseau et retrait du vieux snapshot.

### Bilan compact de la partie et contexte HUD · A/B · complexité faible à moyenne

- **Intérêt.** Faire apparaître seulement les détails FieldKit de la partie qui se termine, avec option pour les lecteurs de sessions longues ou les profils minimalistes.
- **Entrées.** `AZS_GetRunSummary`, `AZS_RUN`, prochains boss et records locaux vérifiés (`Api.lua:233–251,342–354`, `Run.lua:151–185,435–449`). Méthode d’identification commune à tous les modes non établie. Les données perdues restent signalées.
- **Conception et coût.** Réutiliser les cartes/résumés déjà présents, lire le résumé au changement de phase et les métadonnées au stamp. Aucun historique, import, export ou recommandation de build ajoutés.
- **Risques et tests.** Afficher deux bilans natifs, mauvaise perte de score au passage Endless, valeurs hors bornes, changement de langue/zoom/HUD. Mesurer l’impact sur les profils et vérifier fin, reprise et abandons.
