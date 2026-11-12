# Audit FieldKit Reborn — 12 novembre 2026, candidat reborn.5

## Périmètre et preuves

Client installé **0.6.1**, 51 modules Lua chargés par le TOC FieldKit,
407 fichiers Lua publics des addons AzerothSurvivors, AzerothSurvivorsAPI et
AzerothSurvivorsUI. Les huit guides officiels ont été relus, dont
[l'API](https://azreborn.com/guides/addon-api),
[les parties et zones](https://azreborn.com/guides/runs-and-zones),
[les classes](https://azreborn.com/guides/classes-and-talents),
[la coopération](https://azreborn.com/guides/co-op) et
[la progression](https://azreborn.com/guides/progression-and-cosmetics).

L'inventaire reproductible [REBORN_API_COVERAGE.json](REBORN_API_COVERAGE.json)
énumère chaque symbole, ses définitions, ses références et ses appels directs,
avec fichier/ligne et empreintes SHA256 des sources. Il recense 129 déclarations
globales de fonctions AZS dans le Lua du client, et 94 symboles AZS mentionnés
dans le guide API (fonctions **et** tables). Ce ne sont pas 129 contrats publics
stables : certains sont des helpers internes de l'interface native. Une référence
statique, notamment dans Diagnostics, ne prouve pas une fonctionnalité active.
Les fonctions exportées par le moteur figurent par leur mention documentaire ;
leur implémentation binaire/serveur n'est pas disponible dans cette installation.

Les modules sont inventoriés et soumis aux contrôles statiques, à la compilation
et à la suite de comportement. La revue ciblée porte sur la compatibilité des
API, la propriété des cadres natifs, les frontières de partie, les données
manquantes et les défauts reproduits dans les captures. Cela ne remplace pas
une recette visuelle en jeu, ni une certification indépendante de chaque chemin.

## Défauts confirmés et corrigés

1. **Carré doré central** : la précédente jauge appliquait une surface texturée
   avant son dimensionnement. Les coins pouvaient recevoir une dimension nulle,
   laissant le client dessiner la taille intrinsèque de l'atlas. La nouvelle
   jauge utilise une texture de barre, un fond uni et quatre traits explicitement
   dimensionnés ; hauteur 22, largeur bornée. La primitive générale Theme.Update
   borne également ses dimensions pendant la résolution initiale des ancrages.
2. **Horde perdue** : l'anneau natif masqué avait une vraie fonction. Une seconde
   jauge fine reprend maintenant `AZS_RUN.en / AZS_RUN.enm`, avec compte et teinte
   ambre/rouge. Une donnée absente reste inconnue ; zéro est une donnée valide.
3. **Septième case fantôme** : la case était incrustée dans les images du dock.
   La rangée entière est recouverte et six sockets sont redessinés à partir de
   l'atlas existant, centrés dans les trois dispositions. Six boutons natifs
   restent interactifs. Le vrai `AZSDashButton` est placé séparément à côté du
   dock ; il conserve sa touche Maj, ses charges et son infobulle.
4. **Compteurs illisibles** : remplacement des anciennes petites étiquettes par
   trois/quatre cellules égales, icônes de même taille et nombres en AzerothSans
   18, alignés verticalement. Les noms et valeurs complètes restent accessibles
   en infobulle. La monnaie d'événement occupe la quatrième cellule de cette
   même bande ; aucune ligne volante au-dessus du dock.
5. **Sorts absents au départ** : Loadout.Update effaçait les données en phase
   `ready`. La disponibilité du loadout inclut désormais cette phase sans
   changer la définition de partie active pour les autres modules. L'adaptateur
   préfère `AZS_GetMeterContext` + `AZS_GetMeterLoadout`, puis le paquet frais
   `AZS_SPELLS` si l'API structurée n'est pas prête. Il lit les noms/icônes via
   GetSpellInfo et garde les descriptions `AZS_SPELLTIPS`. Aucun sort supposé
   appris ni rang 1 inventé. La barrière de fraîcheur reste obligatoire.
6. **Gardiens oubliés par les barres Chronicle** : Reborn ne met volontairement
   aucun gardien dans `AZS_UNITS`, contrairement à l'ancien jeu. Le sélecteur
   utilise maintenant `AZS_GetBosses` et `AZS_GetGuardians`, en réunissant des
   copies pour FieldKit. Le flag éveillé et les PV natifs sont conservés ; aucun
   ajout n'est effectué dans les tables du jeu. Les gardiens endormis restent
   exclus du rendu de combat.
7. **Restauration** : les nouvelles cellules, les deux jauges et la rangée de
   six sockets sont masquées lorsque le thème est désactivé. Les boutons natifs
   retrouvent les parents et propriétés enregistrés.
8. **Thème perdu après /reload** : reproduit dans le vrai client. Le réglage
   était encore activé, mais `AZSZONE` n'était pas renvoyé alors que les paquets
   de partie/sorts étaient présents. Le mode auto utilise maintenant la phase
   de partie pour rétablir l'habillage sans exiger un identifiant de zone. Le
   nom affiché peut provenir de GetRealZoneText/GetZoneText, sans fabriquer un
   identifiant de carte ni une difficulté. Vérifié après rechargements réels.
9. **Flèches du chat en double** : les noms Reborn sont
   ChatFrame1ButtonFrameUpButton/DownButton/BottomButton. Ils sont maintenant
   masqués/restaurés avec les contrôles natifs ; les quatre contrôles FieldKit
   restent disponibles. Les onglets de conversation natifs restent gérés par
   le jeu.
10. **Distances de lairs aberrantes au départ** : les coordonnées 0,0 du paquet
    d'attente donnaient des milliers de yards. Les distances restent absentes
    en phase ready, puis utilisent la pose officielle AZS_GetPlayerPosition.
    Le cas de coordonnées natives non nulles différentes du paquet est testé.

## Couverture par famille de modules

- Runtime, Reborn, RebornPresentation, RebornHUD, GameCompatibility, Diagnostics :
  identité indépendante, adaptateurs, capacités optionnelles et géométrie.
  Interface **11200** et dépendance AzerothSurvivorsAPI conservées pour les shims
  `this/event/argN`, UnitBuff et événements de combat historiques.
- NativeData, NativeTools, Loadout, RunMode, FieldKit : phase, heure, boss,
  gardiens, effets, résurrection, niveaux stockés, bijoux, lairs et statistiques.
  Les données natives remplacées par paquet sont relues ; aucune mutation.
- MeterLedger, MeterSuite, TakenDetails, Coop, GroupHistory, PartySync,
  PartyDetails : snapshots, identité des propriétaires, détails de groupe et
  limites de capacité. Le canal optionnel AFKRDETAIL1 reste désactivé par défaut.
  Le soin effectué n'est jamais présenté comme du soin reçu.
- WorldPins, WorldAnchors, WorldMarkers, CombatText, CombatOptions, LegacyCrits,
  BossTimeline : positions, projections, unités abattues, texte et calendrier.
  Les fonctions optionnelles sont sondées ; les identifiants d'instance ne
  deviennent pas des identifiants de créature. Cache d'icônes observées borné.
- Theme, ThemeHUD, ThemeTarget, ThemeMinimap, ReferenceHUD, ReferenceArt,
  ZoneThemes, ZoneThemeRegistry, HudStack, CardLayout, ScreenLayers : propriété
  du HUD, boutons réels, changement/restauration du thème, limites de rendu.
  Le calendrier fournit la progression boss ; le thème n'invente pas de formule.
- Config, Profiles, Positions, Settings, OptionsSchema, Interface,
  Localization, InterfaceStrings, Preview, PreviewVisibility, CopyLog :
  migrations, profils, préférences, texte et prévisualisations. Les anciennes
  sauvegardes FieldKitDB ne sont pas importées dans FieldKitRebornDB.
- Seed, SpellAssets, PortraitCatalog, Portraits : conservation du patrimoine
  graphique, mais le catalogue natif Reborn et les observations priment sur les
  données de l'ancien jeu. Un portrait inconnu reste explicitement inconnu.

Le catalogue du client contient 48 zones, 12 classes, 241 sorts de classe,
38 bijoux, 20 amulettes, 612 références d'icônes de créatures et 83 hauts faits.
Le test parcourt toutes les zones et tous les sorts de classe générés. Ce sont
des métadonnées lues, pas 48 parties jouées ou un bestiaire serveur exhaustif.

## Fonctionnalités du jeu et choix d'intégration

Les guides distinguent campagne, difficultés héroïques/affixes, chaîne de zones,
continuation sans fin après victoire, défi quotidien, entraînement/simulation
et hub social. La continuation sans fin ne doit pas être confondue avec les
modes encore annoncés « Coming soon ». Les quatre continents/ères n'impliquent
pas quatre contrats API : noms, calendrier et contenu restent fournis par la
partie native. L'habillage automatique Elwynn s'applique aux cartes d'extension,
sans prétendre fournir une nouvelle illustration spécifique à chaque zone.

Le HUD natif reste propriétaire des choix de niveau, portails, avertissements
de mécanique, sélection de bijoux, boutique/événement, talents persistants,
cosmétiques, défis et classements. FieldKit garde les commandes de jeu manuelles
et n'essaie pas de reproduire ou automatiser ces écrans. Les avertissements
natifs ne sont pas supprimés globalement avec les éléments remplacés du HUD.
La Horde et la monnaie d'événement, précédemment perdues, sont intégrées.

## API encore utiles à exploiter davantage

- **AZS_GetRunSummary** : résumé fiable à la fin d'une partie, avec le résultat
  réellement fourni. Utile à l'historique de FieldKit et prioritaire pour le
  futur port Azeroth Stats. Actuellement inutilisé ; aucun résumé persistant
  nouveau n'a été ajouté à ce correctif HUD.
- **AZS_IsStoringLevels / AZS_SetStoringLevels** : afficher l'état exact du
  stockage et proposer un bouton manuel. FieldKit lit déjà le nombre et ouvre
  les niveaux conservés, mais ne fournit pas encore ce sélecteur d'état.
- **AZS_GetRunLength** : repère global vers le dernier boss ou résumé de
  campagne, indépendant de la progression vers le prochain boss. À afficher
  seulement si pertinent pour le mode courant ; pas de compte à rebours ajouté.
- **AZS_GetSummons / AZS_GetSummonCount / AZS_GetTotemCount** : détail individuel
  et compteurs compacts facultatifs. Les groupes d'invocations et totems sont
  déjà exploités ; ce serait un approfondissement, pas une feature absente.
- Le **loadout structuré** et les **getters boss/gardiens** étaient utiles et
  insuffisamment exploités : ils sont maintenant intégrés dans reborn.5.

Les fonctions OnBanner/ParseBanner/OnWorldProjected sont des points de
distribution internes : leur absence d'appel direct n'est pas un défaut.
FieldKit s'abonne déjà aux handlers publics de bannières/projection.
Les checkpoints atomiques, fenêtres récentes natives et portraits retenus sont
annoncés non supportés par le Meter API du client. Les appeler davantage ne
créerait aucune donnée fiable. Les commandes de jeu ne sont pas des données à
collecter automatiquement. La couverture doit se juger par la fonctionnalité,
pas par le pourcentage brut de noms AZS appelés.

## Vérification et limites restantes

Les fixtures de production vérifient le démarrage sans GetPlayerBuff, les trois
dispositions, la restauration native, les vrais callbacks, l'identité des objets,
les couleurs de vie, la fraîcheur entre parties, les six sockets et la Horde.
Une fixture 0×0 remplace les dimensions artificielles du mock pour détecter la
régression de texture. Les fichiers Api.lua, Meter.lua et Generated/Content.lua
du client installé sont aussi exécutés dans le harnais Lua.

Une recette native partielle a ensuite été effectuée avec l'autorisation de
contrôle donnée par le mainteneur : disparition du carré, six cases dans les
trois dispositions, compteurs alignés avec monnaie d'événement, deux sorts de
départ et leur description, puis retours automatiques du thème après /reload.
La Horde a été vue à 0/120 et la progression boss à 0 %. Le thème complet/auto
et l'échelle initiale de 80 % ont été conservés à la fin.

Le compteur de charges `AZS_DASH.seen` peut aussi rester absent après /reload
dans ce client : le bouton natif se cache alors de lui-même. FieldKit montre un
repère grisé « ? » hors des six sorts, avec une infobulle d'attente ; il ne
prétend pas connaître les charges et ne déclenche aucune commande automatique.
Le vrai bouton reprend la place dès que la mise à jour native arrive. La
difficulté reste « ? » si elle n'est plus transmise ; le nom du monde seul ne
permet pas de la déduire.

Cette recette ne valide pas un combat prolongé, une Horde pleine, les cycles
réels de charges du Destrier, un combat de gardien ou le transport coop. Ces
points restent couverts seulement par les fixtures lorsqu'elles existent.
Le journal Lua n'a montré aucune nouvelle erreur pendant cette recette ; les
anciennes erreurs Ace3/issecretvalue du jeu n'ont pas été effacées ni corrigées
en modifiant ses addons. Aucun fichier des addons natifs ni aucune sauvegarde
de compte n'est modifié par le déploiement.
