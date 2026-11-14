# Azeroth FieldKit Reborn

Adaptation 0.6.5 : catalogue de 240 boss, descriptions complètes des effets de bijoux au survol, barre d'incantation native conservée et accès au journal de mort via `/fieldkit death`. Les états de contrôle utilisent uniquement les informations réellement fournies ; les API manquantes font l'objet d'une demande préparée pour le développeur.

Sans thème illustré, les cartes utilisent désormais l'habillage sombre natif. Les compteurs incluent les bonbons, une horloge affiche le temps écoulé, et chaque remplacement masque uniquement le widget natif correspondant. Désactiver la carte rétablit ce widget.

Pour la 0.6.5 : **/fieldkit → Interface → Compteur de combat → Dégâts et soins récents**, puis choisir **5 à 120 secondes**. Le mode récent est désactivé par défaut et se sauvegarde par profil. Les bonus des bijoux et des DoT sont disponibles au survol de Statistiques ; les valeurs DoT se sélectionnent aussi dans la liste des statistiques.

Version indépendante de FieldKit pour **Azeroth Survivors Reborn 0.6.5**.
Le candidat **0.1.0-reborn.15** adapte le HUD et les compteurs au nouveau client.

[Audit API et correctifs HUD](docs/REBORN_API_AUDIT.md) · [Audit paramètres/thèmes](docs/REBORN_SETTINGS_AUDIT.md) · [Audit du port](docs/REBORN_PORT.md) · [Recette en jeu](docs/REBORN_ACCEPTANCE.txt) ·
[Téléchargements](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/releases)

Le contenu de partie vient des tables Reborn : sorts des nouvelles classes,
bijoux de partie, boss, jauges de progression et cartes des extensions. Les thèmes illustrés
restent ceux déjà disponibles ; le mode auto réutilise l'habillage Elwynn sur les
autres cartes, en conservant leurs noms et données natives.
La 0.6.5 fournit les fenêtres récentes et les points de contrôle natifs du compteur.
Les données non exposées restent inconnues : aucun soin reçu, multiplicateur ou
portrait n’est inventé à partir de l’ancien jeu.

Décompresser le ZIP nommé `AzerothFieldKitReborn-*.zip` dans `Interface/AddOns` du
client Reborn. Vérifier le chemin
`AzerothFieldKitReborn/AzerothFieldKitReborn.toc`, activer l'addon ainsi que
`AzerothSurvivorsAPI` fourni par le jeu, puis redémarrer. Ouvrir `/fieldkit`.
Ne pas activer les deux éditions de FieldKit dans le même client : leurs noms
de fenêtres et commandes restent communs pour la compatibilité du port.

Les réglages sont dans **FieldKitRebornDB**, séparés de **FieldKitDB**. Aucun
import automatique ni changement des sauvegardes de l'ancien jeu. Le partage
optionnel entre joueurs utilise un protocole distinct et reste désactivé.

Les tests hors jeu comprennent les vrais modules API du client installé et les
métadonnées des 12 classes/241 sorts et 48 cartes. Ils ne prouvent pas le rendu,
les performances d'une longue partie ou le réseau coop. Le statut du registre
reste `untested` avant recette native. Une préversion GitHub est installable
manuellement ; le lanceur attend une release éligible et l'index signé par les
mainteneurs du jeu.

Le projet original [azeroth-fieldkit](https://github.com/Maidenquinn/azeroth-fieldkit)
reste indépendant. Crédits : Kevin Radlowski / Maidenhead, MASH par Malk.
Les [notices](NOTICE.md) et le [statut des droits](LICENSE.md) sont conservés.
Les anciens documents du dépôt concernent l'ancien jeu sauf mention Reborn.
