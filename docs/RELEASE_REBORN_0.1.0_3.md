# Azeroth FieldKit Reborn 0.1.0-reborn.3

Complète les informations du HUD et corrige les éléments Reborn encore visibles.

- Pourcentage vers le prochain boss ajouté au bandeau FieldKit. La progression
  native des failles est prioritaire ; le calendrier fournit le repli temporel.
- Compteur de monnaie de l'événement actif ajouté au-dessus du dock, avec son
  icône native et son infobulle. Pour la Sanssaint, il s'agit des bonbons récoltés
  dans la partie, comme le compteur Reborn d'origine.
- La jauge centrale SurvivorsBossBar et la jauge RiftBar cèdent désormais la
  place au HUD FieldKit. Elles sont restaurées à la désactivation du thème.
- Le cadre de cible thématique prend le vrai cadre AzerothSurvivorsUnitFrameTarget
  comme source, conserve son clic natif et restaure son parent quand on le ferme.
- Les descriptions actuelles des sorts sont lues dans AZS_SPELLTIPS, avec leurs
  valeurs natives et mises à jour même sans changement de rang. Les descriptions
  indisponibles ne sont pas reconstruites à partir de formules de l'ancien jeu.
- La vie du personnage passe au vert/jaune/orange/rouge selon ses PV restants :
  seuils 75%, 50% et 25%.

Tests automatiques : progression native et repli, progression zéro, absence
de doublon de pourcentage, compteur événementiel et retrait hors événement,
masquage/restauration des cadres natifs, clic de cible, quatre couleurs de vie,
description de sort modifiée sans changement de rang. La recette visuelle en jeu
du correctif reste à confirmer. Les crédits et notices de droits sont conservés.

Après installation : redémarrer le client. Le thème déjà choisi et les positions
enregistrées sont conservés. Version affichée : 0.1.0-reborn.3.
