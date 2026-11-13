# Réglages et thèmes — audit du 13 novembre 2026

Le catalogue [REBORN_SETTINGS_AUDIT.json](REBORN_SETTINGS_AUDIT.json) est extrait
du schéma réellement construit : 18 pages, 119 entrées (contrôles, notes et
éditeurs spécialisés). `tools/audit_settings.py` appelle les vrais setters et
getters dans quatre contextes : sans thème, minimal, complet et alternatif.
Les 924 cas détectent les exceptions et les incohérences de stockage ; ils ne
prouvent pas, à eux seuls, le résultat visuel de chaque option.

## Corrections

- **Panneau** : taille et opacité dédiées dans Préférences. Son décor thématique
  suit la même opacité que sa version sans thème ; les contrôles et leurs textes
  gardent leur alpha. Les popups suivent son échelle malgré leur parent UIParent.
  Ces deux préférences globales ne changent pas lors d’un chargement de profil HUD.
- **Vie sous le héros** : retirée du masquage systématique du thème. Le portrait
  du HUD et la barre facultative ont des rôles distincts. Avec cette dernière,
  les buffs gardent leur position habituelle ; sans elle, le thème peut les
  présenter au survol du portrait. Les choix de récompenses gardent priorité.
- **Mode et monnaies** : les deux options masquent le décor concerné en plus
  des éléments vivants. Certains cadres et pictogrammes appartenaient à l’atlas
  du HUD. Le moteur de rendu soustrait leurs rectangles des quads, sans réécrire
  les images ni masquer les sorts, l’XP ou le reste de la carte. La carte ronde
  retrouve un segment d’anneau simple à la place de son bandeau inférieur.
  Aucun récapitulatif natif partiel ne remplace le bandeau masqué sous thème.
  Désactiver le thème restitue les réglages d’origine de l’interface native.
- **Cible et groupe** : nombres de PV de cible et format de PV des alliés
  respectés par les surfaces thématiques. Les données de ressource absentes ne
  provoquent plus une comparaison numérique avec false dans une carte de groupe.
- **Compteur** : masquage effectif des onglets ; DPS/part, montant/DPS ou les trois
  valeurs selon la préférence. Dans ce dernier cas, le taux a sa propre ligne
  à côté de la jauge, sans allonger le montant ni recouvrir les noms.
- **Statistiques** : les quatre lignes compactes proviennent de la sélection
  du personnage ; la vue développée continue de montrer toute cette sélection.
  La description ne les confond plus avec l’or et le prix du coffre.
- **Rappels** : calendrier détaillé et rappel séparé restent accessibles avec un
  thème quand activés ; le rappel des niveaux stockés respecte sa case et rend
  le contrôle natif lorsqu’il est désactivé.
- **Navigation** : Monde et les trois pages Chat sont des ids persistants valides
  et ne sont plus remplacés par Accueil à l’initialisation suivante.

## Portée des options

Le mode de jeu renseigne le rang fourni par Reborn, sans réutiliser les anciens
multiplicateurs. « Statistiques » concerne les bonus du personnage. « Or et prix
du coffre » commande le bandeau de compteurs entier du thème, y compris victimes
et monnaie d’événement ; la ligne supplémentaire « Victimes sous l’or » concerne
la présentation classique sans thème.

Les regroupements et dimensions de Disposition concernent les fenêtres classiques
et de détails. La taille des éléments du HUD thématique se règle dans Style et
thèmes. Le choix Décoratif/Classique concerne les cartes sans thème ; le thème
dispose de ses propres illustrations. L’opacité des cartes et celle du panneau
de réglages sont indépendantes. La barre compacte historique demande toujours un
reload et cède au dock du thème lorsqu’il est actif.

Les textes de combat, leurs profils et filtres, les marqueurs du monde et leurs
catégories, les profils HUD, les aperçus, le chat, les interactions natives de la
carte et la restauration des écrans de choix sont des éditeurs ou comportements
spécialisés : leurs fixtures existantes sont exécutées par la suite complète,
en complément du catalogue. Les filtres d’affixes, buffs, avertissements, boss,
effets et coopération restent dépendants des données réellement exposées.

## Vérification et limites

`tests/reborn_settings_audit.lua` teste les setters et des effets concrets :
taille/opacité du panneau, parent/alpha/visibilité de la barre centrale, nombres
de PV de cible, bandeau de compteurs, navigation au reload et indépendance des
profils. `tests/reborn_optional_art.lua` ajoute 3 présentations × 3 formes de carte :
quads et UV valides, absence de décor dans les zones retirées, conservation des
sorts et de l’XP, masquage des pictogrammes et restauration à la réactivation.

Le rendu des quads Elwynn complet a été reconstruit avec les textures du paquet
et inspecté hors jeu : aucun bandeau inférieur ni icône vide après désactivation.
Ce contrôle ne constitue pas une capture du client. La prise de contrôle en jeu
a été interrompue ; il reste à confirmer visuellement l’ensemble des options en
partie et en coopération réelle. La préversion conserve cette limite explicite.
