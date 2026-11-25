# Demandes d’évolution API à SNX

Brouillon technique à relire avant envoi. Les noms et champs proposés ci-dessous restent à définir avec le mainteneur du jeu. Les diagnostics sont fondés sur [le client 0.7.4](API_DISCOVERY_CURRENT.md) et [les objets du monde](WORLD_OBJECTS_DISCOVERY.md).

## P1 · Un instantané public pour les objectifs locaux

**Besoin joueur.** Afficher dans une UI accessible des objets permis par les règles de visibilité. Donner une direction tant que l’objet existe, effacer le repère après collecte/suppression et éviter le doublon avec la mini-carte native.

**Preuve actuelle.** `Rift.lua:108–118` reçoit des points `v/p/o` avec coordonnées normalisées sans ID, carte ou timestamp. `Vault.lua:460–510` reçoit un état de groupe séparé. `Passage.lua:389–406,574–589` reçoit les points 3D et IDs des portes de passage, mais garde la liste locale. `Anchors.lua:252–347` inclut déjà coffres, antres, pings et unités. Les variantes de runes sont décrites par le guide, sans source Lua de présence. [Guide des objets ramassables](https://azreborn.com/guides/runs-and-zones#pickups)

**Contrat proposé.** Étendre `AZS_GetWorldAnchors` pour les objectifs 3D déjà autorisés ou fournir un petit instantané `AZS_GetWorldObjects(filter[,sinceRevision])` si la validation de carte et les coordonnées 2D nécessitent une surface dédiée.

```text
snapshot: apiVersion, runId, spaceId, arenaId, revision, ready, full, entries
entry: id, kind, subtype?, state, position?, ttlSeconds?, icon?, labelKey?
position: { space="map", mapId, mx, my } | { space="world", x, y, z? }
kind: treasuryPortal | riftPortal | passagePortal | pickup | ...
```

- `id` stable dans la durée de l’instance et dans sa génération de contexte. Une nouvelle apparition à la même place reçoit un autre ID. Proposer les variantes des runes comme `subtype` une fois leur identité confirmée.
- `ready=false` pour zone non synchronisée. Une liste complète vide et fraîche confirme l’absence. Une liste complète omet toute instance retirée. Un éventuel delta devrait nommer explicitement les IDs retirés et leur raison si celle-ci est connue.
- `revision` change uniquement quand la liste ou un champ significatif change. Le premier appel après un reload ou un changement d’hôte doit pouvoir relire la liste autorisée sans envoyer de commande de synchronisation à chaque appel. Décrire l’ordre de livraison pendant un changement d’arène.
- Pas de prévisions de spawns ni de positions que le serveur choisit de garder cachées. Pour les runes ou cristaux, respecter le périmètre de visibilité voulu. Une annonce sans coordonnées ou un sous-ensemble d’objets découverts est utile si la localisation globale doit rester secrète. Documenter la différence entre portée de visibilité, portée de collecte et TTL du serveur.
- Clarifier les états `waiting/entering/active/ended` pour la Trésorerie, `sealed/open` pour la faille et `standing/consumed` pour le passage lorsque cela fait partie du contrat. Les noms sont illustratifs.
- Préférer une révision bon marché et des listes filtrées/bornées de points d’intérêt. Cette surface ne devrait pas activer une copie des unités ordinaires. Séparer les coordonnées monde connues des points exprimés en fractions de zone.
- Valider avec une séquence de référence solo et coop normalisée `apparition → mise à jour → retrait`, plus reload, handover et transition d’arène. Une rune collectée doit disparaître au prochain snapshot et l’ID doit rester stable pendant sa vie.

## P1 · Clarifier et documenter Rift, Vault et Gate même sans nouvelle API

- Décrire `AZSRIFT.m`, sa cadence et ses conditions de resynchronisation, `st/got/need`, les nombres et le référentiel des coordonnées, une éventuelle multiplicité de `v` et les messages envoyés à la disparition. Décrire l’ordre des messages face à `AZSZONE`, `AZSEND` et `AZSPASSAGE`.
- Documenter `AZSVAULT.st,left,secs,got,of`, l’horloge à utiliser lors d’une pause ou d’un choix et les états fin/annulation. Préciser si `AZS_GATE` ou un getter public de snapshot est envisageable pour éviter le seul paquet `AZSGATE`. Un lien facultatif entre la séquence et l’identifiant de portail permettrait un état plus utile.
- Exposer un contexte de carte stable donnant `mapId,arenaId,mw,mh` et la pose normalisée du joueur dans le même référentiel, via une lecture sans changement de carte/zoom. Indiquer axe, unité et cadence. Ceci évite de dépendre des effets de bord de `Chests.lua:64–153` pour la distance au portail.

## P2 · Contrôles de visibilité HUD

Les options documentées de `AZS_SetHudShown` traitent déjà `flag` et `revive` (`Hud.lua:1–47`). Pour permettre une apparence personnalisée sans deux marqueurs sur la même surface, proposer des clés indépendantes pour les pions de faille/trésorerie, les coffres et les passages, en distinguant mini-carte et plaques monde. La prise en charge doit rester limitée aux surfaces annoncées par une capacité de l’API. Garder le comportement multi-propriétaire et la restauration après désactivation ou désinstallation. Test attendu avec deux addons qui réclament les mêmes éléments.

## P2 · Identité des événements et ancres ciblées

- Publier un vocabulaire stable de sous-types pour les vagues, dangers et événements saisonniers qui font déjà l’objet d’une annonce. `eventId, kind, subtype, state, runTime` et `relatedAnchorId?` suffisent à rendre une notification. Les noms localisés restent du texte pour l’affichage. La position est facultative et suit le périmètre de visibilité autorisé. Sources `Api.lua:632–681`, `Events.lua:81–94`.
- Filtrer les ancres par GUID et types avant d’énumérer les unités, y compris gardiens et boss confirmés de rang 0. L’appel actuel avec `enemy` déclenche `AZS_WorldUnits(0)` avant tri/pagination (`Anchors.lua:252–360,382–428`). Garder des pages cohérentes au sein d’une même révision. Exposer un signal de disparition explicite si le point retenu pour le combat survit temporairement à l’unité.
- Donner un lien `guid` ou `anchorId` de l’invocation quand sa position fait partie des données autorisées, et séparer l’identité de créature de celle de l’instance. Pour une réanimation, associer `guid,runId,spaceId` et progression au même état afin de limiter les rapprochements par nom après handover. Sources `Api.lua:359–440`, `Anchors.lua:497–519`.

## P3 · Contextes de jeu et provenance de combat

- Un `modeKey` local documenté et stable, plus l’état éventuel `endlessAfterVictory`, aiderait FieldKit à afficher une information contextuelle et à valider les capacités par run. Il devrait distinguer campagne, variantes, Daily, Proving Grounds, hub et contenu moddé. Le guide est actuellement la référence des modes disponibles.
- Pour les diagnostics de critique et d’équipement, demander un identifiant de source fiable (sort, bijou, proc, invocation) par événement lorsque le moteur le possède, et un signal de couverture/perte du flux si la lecture en temps réel en bénéficie. Partager une chance critique effective par source seulement si la règle produit une valeur interprétable et fraîche. Sources `CombatText.lua:9–16,100–145`, `Meter.lua:1230–1264`.
