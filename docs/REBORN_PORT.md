# Port Reborn — 12 novembre 2026

Ce dépôt est un dérivé indépendant de `Maidenquinn/azeroth-fieldkit`, au commit
`d3b80c3`. L'historique est conservé ; aucun push n'est effectué vers le dépôt
original. Azeroth Stats est examiné séparément à partir de son commit `84e3812`
(2.0.4) ; son adaptation vient après FieldKit.

## Références vérifiées

- [API officielle](https://azreborn.com/guides/addon-api), consultée le 12 novembre.
- [Zones et modes](https://azreborn.com/guides/runs-and-zones).
- [Guides](https://azreborn.com/guides).
- [Registre officiel](https://github.com/Syiana/azs-addons).
- Client installé 0.6.1 : modules publics `AzerothSurvivorsAPI`, tables générées
  d'`AzerothSurvivors`. Empreintes et inventaire dans
  [REBORN_CLIENT_INVENTORY.json](REBORN_CLIENT_INVENTORY.json).

L'installation fournie contient un client et des addons Lua publics ; ce n'est
pas le code source complet du moteur/serveur. Aucun exécutable, MPQ, fichier de
sauvegarde, donnée de compte ou ressource extraite du jeu n'est redistribué ici.

## Changements réalisés

- Dossier/TOC `AzerothFieldKitReborn`, sauvegarde `FieldKitRebornDB`, protocole
  optionnel `AFKRDETAIL1`, dépôt et versions propres. Aucun import de FieldKitDB.
- Dépendance obligatoire `AzerothSurvivorsAPI`. Interface **11200** conservée :
  le client applique à ces fichiers ses shims de callbacks `this/event/argN`,
  d'auras et de messages de combat. Passer simplement à 30300 casserait ces appels.
- Métadonnées de sorts lues dans le catalogue Reborn, par classe et clé native ;
  seuls les sorts effectivement appris créent des lignes. Icônes et noms natifs
  remplacent les hypothèses issues du vieux Spell.dbc.
- Bijoux de partie lus dans `AZS_GEAR` (amulette, deux bagues, deux bijoux), avec
  leurs descriptions natives. Les objets persistants de la fiche personnage ne
  sont plus présentés comme les bijoux de la partie.
- Réception des mises à jour sorts/bijoux, invalidation des données entre parties.
- Compteurs de coups réinitialisés à un nouvel identifiant natif de partie,
  y compris sur la même carte. Les checkpoints non supportés ne sont pas simulés.
- Soins effectués par défaut. Les soins reçus ne sont pas remplacés par les soins
  effectués lors du repli vers l'ancienne API. Les deltas du compteur de soins ne
  deviennent plus des événements de soins reçus dans le texte flottant.
- Identités des joueurs conservées après tri du compteur de groupe.
- Anciens multiplicateurs de difficulté retirés des affichages Reborn ; rang et
  affixes explicitement reçus restent affichés. Aucune formule serveur inventée.
- Classification initiale des boss issue des calendriers Reborn, avec traductions
  natives. Les apparences du catalogue de l'ancien jeu ne sont plus affirmées :
  icône native si une entrée de créature explicite est fournie, sinon inconnue.
- Valeurs finies jusqu'à 1e18 et formats d'entiers de combat en virgule flottante
  pour éviter le débordement des entiers C 32 bits sous Windows.
- Automatisations historiques de publication neutralisées dans ce dérivé.

## Couverture et limites

L'inventaire contient **48 zones, 12 classes, 241 sorts de classe, 38 bijoux,
20 amulettes et 612 références d'icônes de créatures**. Les sorts des 12 classes
et les catalogues des 48 cartes sont parcourus par le test contre le client.
Ces nombres décrivent le catalogue, pas des parties jouées ni un bestiaire complet.
Les calendriers, créatures vivantes, rangs et bijoux affichés proviennent des
tables natives ; une nouvelle carte ne nécessite pas une liste codée en dur.

Les thèmes graphiques spécifiques hérités restent limités à leurs compositions
existantes. Une carte d'extension utilise le HUD générique ; elle n'a pas reçu
magiquement un nouveau thème illustré. Les portraits 3D/statistiques de soins
reçus/fenêtres récentes/checkpoints ne sont pas fabriqués lorsque l'API les refuse.
Les fonctions optionnelles sont vérifiées avant appel. Le partage coop reste
désactivé par défaut et nécessite deux clients consentants.

## Vérification

`python tools/audit.py`, `python tools/verify.py`, `python tools/test_reborn.py`.
La suite héritée utilise explicitement le mode de fixtures historiques pour
conserver ses tests de non-régression ; les tests Reborn l'interdisent et testent
le comportement de production. `test_reborn.py --game <client>` charge directement
les vrais `Api.lua`, `Meter.lua` et `Generated/Content.lua` locaux en Lua 5.1,
sans modifier le client. Il vérifie les dégâts, soins, refus des checkpoints et
les métadonnées de chaque classe/sort. La recette native est dans
[REBORN_ACCEPTANCE.txt](REBORN_ACCEPTANCE.txt).

Une exécution avec mocks ne prouve ni le rendu natif, ni les performances en
partie longue, ni la livraison réseau coop. Le statut du registre reste
`untested` tant que cette recette n'a pas été exécutée et consignée en jeu.

## Distribution

Le paquet est un ZIP reproductible contenant uniquement le dossier
`AzerothFieldKitReborn`, son TOC et ses ressources déclarées. Les empreintes,
manifestes et validations sont des pièces jointes séparées. Le candidat doit
passer `check_zip` du registre avant publication.

L'entrée préparée est `distribution/azeroth-fieldkit-reborn.toml`. Une PR doit
ajouter cette entrée puis régénérer `index.json` avec `python tools/pin.py pin
--offline`. Une préversion GitHub n'est pas épinglée : une publication éligible,
la PR d'épinglage fusionnée et la signature des mainteneurs du jeu restent
nécessaires pour apparaître dans le lanceur. Créer notre dépôt ne réalise pas
ces opérations côté Syiana.

Les crédits Malk/MASH et les notices de droits restent joints. La permission
rapportée pour l'ancien jeu ne constitue pas une validation du paquet Reborn.

## Audit initial Azeroth Stats — à traiter ensuite

Le dépôt original est resté intact. Il utilise Interface 11200 et trois racines
de sauvegarde (`AzerothStatsDB`, `AzerothStatsBackup`, `AzerothStatsAutoBackup`).
Le dérivé Reborn devra isoler les trois, les imports/exportations et la provenance
des historiques, afin de ne jamais mélanger des parties des deux jeux.
Les priorités sont les limites des compteurs, les fins de partie, les bijoux
`AZSGEAR`, les catalogues/classes/races des extensions, les événements de mort et
la vérification des données de progression. Aucun port Stats n'est annoncé terminé.
