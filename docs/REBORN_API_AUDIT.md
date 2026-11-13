# Audit FieldKit Reborn — 13 novembre 2026, reborn.8

Les réglages et leur cohérence avec les thèmes sont détaillés dans
[l’audit des paramètres](REBORN_SETTINGS_AUDIT.md), avec un catalogue généré des
18 pages et les limites de la recette. Les paragraphes historiques ci-dessous
conservent la portée de validation propre à chaque version.

## Sources contrôlées

Client installé **0.6.3**, 52 modules FieldKit et 407 fichiers Lua publics du
client. Les huit guides officiels ont été relus, dont
[l’API](https://azreborn.com/guides/addon-api) et
[les parties et zones](https://azreborn.com/guides/runs-and-zones).
[REBORN_API_COVERAGE.json](REBORN_API_COVERAGE.json) conserve les définitions,
références, fichiers, lignes et empreintes des sources : 129 déclarations Lua
AZS, 94 symboles documentés et 79 symboles AZS référencés par l’addon. Une référence statique ne
prouve ni une fonctionnalité active ni une validation en jeu.

Le générateur `tools/build_reborn_creatures.py` lit également les définitions
TOML embarquées dans le PE installé, sans exécuter le binaire ni modifier le
client. Il ne redistribue que les métadonnées de présentation nécessaires.
[REBORN_CREATURE_COVERAGE.json](REBORN_CREATURE_COVERAGE.json) détaille chaque
boss, sa zone, son entrée, son icône et la provenance de celle-ci.

## Correctifs chat et menus reborn.7

- Les descendants des listes déroulantes sont maintenant explicitement au-dessus
  de leur fond : viewport, contenu, boutons et contrôles du template natif.
  Le client ne leur attribuait pas automatiquement le niveau de leur parent.
- Un changement explicite de taille, police ou palette active la personnalisation
  du chat. Le réglage ne reste plus silencieusement ignoré lorsque la case était désactivée.
- L’ancrage TOPLEFT du texte utilise une marge verticale négative vers l’intérieur,
  au lieu de le pousser au-dessus du cadre.
- Le journal de rendu temporaire reste actif lorsque le thème habille le chat,
  même sans personnalisation facultative. Cela permet de redimensionner le vrai
  ChatFrame1 sans perdre ses messages. Le client ne fournit pas GetMessageInfo :
  les messages observés ne doivent donc pas être effacés à chaque tick.
  Ce journal borné reste distinct de la copie opt-in et n’est jamais sauvegardé.
- Après chaque ajout, le journal suit les évictions du tampon natif plein ; il
  conserve aussi exactement les valeurs de retour natives, y compris les valeurs nil.

Recette réelle ciblée : 460×210 → 550×280 → 460×210 via les curseurs du panneau,
avec conservation des deux messages présents ; choix de police visible, sélection
Arial Narrow puis retour à la police d’origine ; long texte natif /help contenu dans le cadre. Les assertions couvrent aussi le
chat sans thème, les limites du texte et le cas de setters natifs destructifs sans
getter de messages et le redimensionnement après éviction dans un tampon plein.
Le diagnostic temporaire ne lit ni n’affiche le contenu du chat
et est retiré avant distribution. Les paragraphes ci-dessous documentent le travail
précédent de reborn.6, sans étendre sa validation en combat.

## Corrections reborn.6

- **Icônes de boss** : la carte Chronicle ne consultait que `AZS_UNITS.entry`,
  souvent absent. Elle utilise maintenant le même résolveur que le compteur,
  avec priorité aux observations natives, puis aux noms du catalogue de la
  zone et aux noms globaux non ambigus. Les identifiants d’instance ne sont
  jamais assimilés à des entrées de créature.
- **Couverture** : 48 cartes, 192 boss planifiés et 684 lignes de créatures.
  Douze boss finaux de Cataclysm n’ont aucune icône déclarée : ils reçoivent
  un remplacement de présentation explicite, identifié comme tel dans le
  rapport. Les 120 chemins distincts utilisés pour les boss et les quatre
  apparences de Sanssaint ont été retrouvés dans les tables de hachage des
  cinq archives MPQ lisibles. Aucun conteneur AZSR chiffré n’a été ouvert.
  Ce contrôle d’existence ne remplace pas une observation visuelle des 192 combats.
- **Créatures saisonnières** : Pumpkin Soldier, Restless Skeleton, Wailing
  Banshee et Hallowed Spirit reçoivent un remplacement visuel, car leurs
  apparences définissent des modèles, mais aucune icône native. Aucun faux
  identifiant d’entrée n’est créé.
- **Antres** : les chaînes vides ne créent plus de lignes anonymes. L’index
  natif commence à 1. Un nom connu est retenu uniquement pour le même gardien
  identifié dans la même partie ; il n’est jamais annoncé comme une future
  apparition après sa disparition. Si l’API n’envoie pas son identité avant
  apparition, la ligne affiche « Gardien · antre N ». Le catalogue des élites
  n’établit pas la prochaine sélection ; aucun nom supposé n’est affiché.
- **Jauges boss/Horde** : cadres du thème, matière sombre et bordure dorée,
  texte serif, hauteur extérieure 30 et remplissage intérieur 16. Chaque
  surface est dimensionnée avant construction et le remplissage est sur un
  enfant au-dessus du matériau. Le pourcentage reste dans sa barre dédiée,
  sans compte à rebours ajouté pour le prochain boss.
- **Liste de sorts** : l’infobulle FieldKit garde nom, rang et bonus explicites,
  mais ne recopie plus la description `AZS_SPELLTIPS`. Les descriptions natives
  de la barre d’actions restent disponibles. Les bonus non transmis restent
  indisponibles ; le texte de base n’est pas transformé en bonus supposés.
  Dans ce client, AZSSPELLS ne transporte que key/spell/rank/cd/cdmax ;
  AZSSPELLTIP donne une description complète aux valeurs actuelles, sans
  ventilation distincte des bonus. La liste peut donc signaler des bonus
  indisponibles même si la puissance effective du sort a augmenté.
- **Modale des dégâts** : niveaux de cadres explicites au-dessus du matériau,
  hauteurs de texte définies, un seul FontString par en-tête, boutons fermer,
  épingler et pagination au-dessus de la fenêtre. L’icône est placée avant
  le calcul du retrait du nom. Les barres utilisent le maximum réel de la
  liste, même après un tri ascendant.
- **Compteur de soins** : une chaîne source vide reçoit « Source non identifiée ».
  Les icônes des sources structurées sont conservées ; Lifesteal a son propre
  pictogramme. La provenance manquante n’est pas remplacée par le nom d’un sort
  déduit uniquement de son icône.

## Compatibilité conservée

TOC 11200 et callbacks Lua legacy du client, dépendance à AzerothSurvivorsAPI,
variables FieldKitRebornDB isolées. Six actions natives restent interactives,
Destrier séparé, compteurs alignés et monnaie événementielle dans la même bande.
Les getters boss/gardiens, loadout structuré, filtres de fraîcheur, couleurs
PV, restitution des cadres natifs et restauration automatique après /reload
restent couverts. Les sources historiques FieldKit et Stats ne sont pas modifiées.

## API utiles encore non intégrées

- `AZS_GetRunSummary` : bilan de fin de partie et historique, utile au futur port Stats.
- `AZS_IsStoringLevels` / `AZS_SetStoringLevels` : état exact et commande manuelle
  de stockage des niveaux. Ne pas déclencher le changement automatiquement.
- `AZS_GetSummons` / `AZS_GetSummonCount` / `AZS_GetTotemCount` : détails et
  compteurs facultatifs ; les groupes d’invocations sont déjà exploités.
- `AZS_GetRunLength` : repère global de campagne, distinct de la progression boss.

Les helpers OnBanner/ParseBanner/OnWorldProjected distribuent des événements
internes ; leur absence d’appel direct ne signifie pas une feature perdue.
Les checkpoints atomiques, fenêtres natives récentes et portraits retenus sont
annoncés non supportés par Meter.lua. Les appeler ne créerait pas ces données.

## Vérification et limites

Contrôles statiques, compilation et suite de comportement complète ; fixtures
Reborn de production avec les sources Api.lua, Meter.lua et Content.lua installées.
Les tests vérifient chaque boss du catalogue, les limites d’icônes, la fraîcheur
des identités, les noms vides, les couches de rendu et les colonnes de la modale.
Le mock associe désormais le FontString d’un bouton comme le client.

Recette réelle partielle via le skill computer-use : jauges Elwynn, quatre
antres numérotés, six cases, retours du thème après /reload et réapparition des
deux sorts après réception des paquets. Une fixture temporaire clairement
étiquetée « TEST RENDU - DONNEES FICTIVES » a exercé le vrai rendu de la modale :
icônes, noms, valeurs, en-têtes uniques, tri Total et fermeture. Cette fixture
n’a modifié aucune table native et a été retirée du TOC et du dossier installé.

Les commandes de déplacement disponibles n’ont pas démarré le combat. Aucun
combat réel, cycle de charges du Destrier, Horde pleine ou transport coop n’est
annoncé validé dans cette recette. Les sources de dégâts réelles restent à
recetter en partie. Les défauts corrigés dans les couches de la modale ont,
eux, été reproduits et vérifiés dans le client avec les données de test.

Pour regenerer le catalogue et verifier les chemins d’icones : installer les
dependances de requirements-dev.txt, puis executer
`python tools/build_reborn_creatures.py --game CHEMIN_DU_JEU --verify-icons`.
