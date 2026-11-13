# Azeroth FieldKit Reborn 0.1.0-reborn.9

- Difficulté : lit aussi le champ `dt` utilisé par l’interface native Reborn. Un petit contexte d’affichage observé peut rétablir le rang après un reload qui ne rejoue pas AZSZONE. Il est invalidé sur une nouvelle zone, un nouveau départ ou un recul d’horloge ; aucun rang Normal n’est supposé en l’absence de données.
- Sans mode sur la carte carrée Elwynn complète : utilise un cadre fermé autour de la texture de minimap entière. Les boutons +/− sont dessinés sur ce cadre ; aucune texture de carte ne dépasse par le bas.
- Sans compteurs : les trois présentations Elwynn utilisent un dock compact, avec sorts et XP repositionnés dans un bloc fermé. Les décors des personnages sont conservés ; la suppression ne laisse plus l’ancien emplacement du bandeau vide sous les sorts.
- Dégâts subis : la fenêtre rejoint le placement et les collisions du thème, peut être déplacée depuis son fond ou ses lignes, conserve sa position par composition et rend son parent/niveau d’origine à la désactivation du thème.

Régressions synthétiques : contexte de difficulté avec/sans replay, changement de zone et redémarrage ; neuf combinaisons présentation/forme de carte ; déplacement et collisions entre Dégâts et Dégâts subis dans les deux sens ; niveaux de dessin et restauration hors thème. La suite complète et les fixtures de l’API publique du client sont exécutées.

Le rendu des matériaux du dock compact et du cadre a été reconstruit hors jeu pour inspection. Ce rendu utilise des contenus de carte/XP de substitution et n’est pas une capture du client. Cette préversion ne revendique pas une recette visuelle complète ni une validation de coopération réelle.
