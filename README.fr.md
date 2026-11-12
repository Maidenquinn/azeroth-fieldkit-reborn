# Azeroth FieldKit Reborn

Version indépendante de FieldKit pour **Azeroth Survivors Reborn 0.6.1**.
Le candidat **0.1.0-reborn.4** adapte le HUD et les compteurs au nouveau client.

[Audit du port](docs/REBORN_PORT.md) · [Recette en jeu](docs/REBORN_ACCEPTANCE.txt) ·
[Téléchargements](https://github.com/Maidenquinn/azeroth-fieldkit-reborn/releases)

Le contenu de partie vient des tables Reborn : sorts des nouvelles classes,
bijoux de partie, boss, calendriers et cartes des extensions. Les thèmes illustrés
restent ceux déjà disponibles ; le mode auto réutilise l'habillage Elwynn sur les
autres cartes, en conservant leurs noms et données natives.
Les données non exposées restent inconnues : aucun soin reçu, checkpoint,
multiplicateur ou portrait n'est inventé à partir de l'ancien jeu.

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
