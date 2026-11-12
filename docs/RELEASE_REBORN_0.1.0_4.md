# Azeroth FieldKit Reborn 0.1.0-reborn.4

- Icônes de bijoux de partie corrigées : la carte thématique utilise AZS_GEAR,
  pas les textures de l'équipement permanent de la fiche du personnage.
- Icônes de sorts carrées : les anciens fonds/bordures circulaires sont masqués
  et une texture carrée reprend l'icône native vivante. Les clics, rangs,
  cooldowns et mises à jour des boutons d'origine restent actifs.
- Six sorts Reborn ; le septième emplacement reçoit le vrai bouton Destrier/Maj
  (ou Dash selon le mode), avec ses charges, son infobulle et sa disponibilité.
- Bonbons intégrés à la barre victimes/or/cache, avec une quatrième colonne.
- Jauge distincte de progression vers le boss sous le bandeau. Le bandeau
  affiche le nom du prochain boss, sans compte à rebours ni pourcentage collé.
- Anneau Horde natif sur la minimap et nom de zone redondant retirés du thème.
- Icônes des sources de dégâts reçus à partir des entrées de créatures natives
  observées. Elles sont gardées après la disparition du mob durant la partie.
  Les sources inconnues/ambiguës affichent ? et ne reçoivent pas d'icône inventée.

Les éléments et boutons natifs sont restaurés quand le thème est désactivé.
Aucun fichier des addons fournis avec le jeu n'est modifié. Les tests vérifient
ces restaurations, l'identité des objets, les callbacks du Destrier, la disparition
du faux septième sort et l'isolation du cache de créatures entre les parties.
La validation visuelle du correctif en jeu reste à confirmer.

Après mise à jour : redémarrer le client. Version affichée : 0.1.0-reborn.4.
