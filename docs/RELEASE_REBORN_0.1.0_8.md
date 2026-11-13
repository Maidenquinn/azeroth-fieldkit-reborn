# Azeroth FieldKit Reborn 0.1.0-reborn.8

- Préférences : taille du panneau FieldKit (60–110 %) et opacité de son décor (0–100 %), indépendantes des cartes du HUD et des profils. Texte et contrôles restent lisibles ; les listes suivent la taille du panneau.
- La barre de vie sous le personnage reste visible avec un thème et conserve sa position, ses buffs, son bouclier et son alerte de vie basse.
- Désactiver le mode retire aussi son bandeau et son information ; désactiver les compteurs retire leur décor, leurs icônes et leurs valeurs. Carte, nom de zone, sorts et XP sont conservés. La réactivation restitue le décor d’origine.
- Descriptions corrigées : les statistiques sont les bonus du personnage ; les compteurs de monnaies sont un module distinct.
- Réglages raccordés aux thèmes : nombres de PV de cible, format de PV des alliés, niveaux stockés, onglets et valeurs du compteur, statistiques choisies et rappels séparés. Les nouveaux onglets restent mémorisés après reload.
- Cartes de groupe protégées contre des fonctions de santé/ressource absentes.

Vérification : 18 pages et 119 entrées inventoriées ; 924 cas de setters sans thème et dans les trois présentations ; matrice des décors sur les trois formes de carte ; suite complète et API publique du client installé. Rendu des quads du décor reconstruit et inspecté hors jeu.

La recette en client a été interrompue ; cette préversion ne revendique pas de validation visuelle complète ni de validation en coopération réelle. Les contrôles de portée limitée (dimensions des fenêtres de détails, style des cartes sans thème, réglages de groupe dépendant des données reçues) sont explicités dans le panneau et l’audit.
