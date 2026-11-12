# Azeroth FieldKit Reborn 0.1.0-reborn.6

- Relie les noms de créatures aux icônes sur les cartes Chronicle et le compteur.
  Catalogue contrôlé sur les 48 cartes : 192 boss, 684 créatures. Douze icônes
  de boss absentes du contenu reçoivent un remplacement de présentation explicite.
- Ajoute les icônes de remplacement de Sanssaint, dont Pumpkin Soldier et Restless Skeleton.
- Habille les jauges boss/Horde avec les cadres Elwynn/Naxx et conserve le pourcentage séparé.
- Affiche uniquement les bonus disponibles dans les infobulles de la liste des sorts.
- Corrige la modale vide, les en-têtes doublés, le retrait des icônes, les commandes
  cachées derrière son fond et l’échelle des barres après tri.
- Conserve les icônes des sources de soins, ajoute Lifesteal et remplace les noms vides.
- Évite les lignes d’antres anonymes et les anciennes identités réutilisées après disparition.

Limite API : le nom du futur gardien n’est pas toujours transmis avant son apparition.
La ligne affiche alors « Gardien · antre N », puis le vrai nom lorsqu’il devient disponible.

Tests API et suite complète ; recette visuelle partielle dans le client 0.6.3,
avec données fictives explicitement indiquées pour la modale. Combats réels,
Horde pleine, charges du Destrier et coop restent à valider. La fixture visuelle
n’est pas incluse dans le paquet. Préversion indépendante, registre officiel inchangé.

Audit : [REBORN_API_AUDIT.md](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/blob/main/docs/REBORN_API_AUDIT.md).
