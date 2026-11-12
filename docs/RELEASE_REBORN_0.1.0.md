# Azeroth FieldKit Reborn 0.1.0-reborn.1

Premier port indépendant de FieldKit 0.6.0 vers Reborn 0.6.1. L'ancien dépôt
et ses releases restent inchangés ; sauvegardes et partage réseau sont séparés.

Les sorts/classes et bijoux sont lus dans les données Reborn, les boss dans les
calendriers natifs. Le compteur de groupe conserve la bonne identité après tri.
Les anciens multiplicateurs Heroic et les anciens portraits ne sont plus
présentés comme des données Reborn. Les soins reçus indisponibles ne sont plus
remplacés par les soins effectués. Les compteurs de coups suivent les nouvelles
parties, y compris sur la même carte.

Tests hors jeu : audit des 49 modules, suite de non-régression héritée, fixtures
Reborn, vrais modules Api.lua/Meter.lua du client installé, métadonnées des 48
cartes et 241 sorts des 12 classes. Le ZIP est contrôlé par le validateur du
registre officiel. Ces tests ne prouvent pas le rendu ou les performances en jeu.

Préversion à installer manuellement : le registre n'épingle pas les préversions.
Recette native, longues parties et transport coop restent à vérifier. Le jeu
était déjà en partie lors de l'installation locale ; aucun rechargement n'a été
déclenché par l'agent. L'addon sera découvert au prochain lancement normal.

Installation : extraire le dossier AzerothFieldKitReborn dans Interface/AddOns du
client Reborn, activer AzerothSurvivorsAPI et FieldKit Reborn, redémarrer puis
ouvrir /fieldkit. Ne pas activer les deux éditions dans un même client.

Voir README.fr.md, docs/REBORN_PORT.md, NOTICE.md et LICENSE.md pour le périmètre,
les limites, les crédits et le statut des droits. Aucune approbation du jeu
Reborn n'est revendiquée.
