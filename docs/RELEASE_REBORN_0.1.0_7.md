# Azeroth FieldKit Reborn 0.1.0-reborn.7

- Corrige les listes déroulantes vides : choix, clics et contrôles de défilement au-dessus du fond.
- Applique les réglages largeur/hauteur du chat dès leur modification, y compris si la personnalisation était désactivée.
- Replace le texte à l’intérieur du cadre du chat avec la bonne marge verticale.
- Conserve le journal de rendu pendant l’habillage par le thème pour préserver les messages au redimensionnement, sans activer la copie du chat.
- Aligne ce journal sur le tampon natif lorsqu’il est plein pour que le redimensionnement continue de fonctionner après éviction des anciens messages.

Tests de production, suite complète et recette ciblée dans le client 0.6.3 :
largeur/hauteur réellement modifiées puis restaurées, messages conservés,
polices visibles et sélectionnables, long texte /help contenu dans le cadre. Aucun module temporaire de diagnostic dans le paquet.
Le chat sans thème est couvert par les fixtures. Les autres limites de reborn.6 restent documentées dans l’audit.
