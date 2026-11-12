# Azeroth FieldKit Reborn 0.1.0-reborn.5

- Remplace la jauge provoquant le grand carré doré par une barre fine bornée.
- Rétablit la Horde dans une jauge dédiée avec compte/max et teinte de charge.
- Redessine six emplacements de sorts ; Destrier/Maj séparé de la rangée.
- Aligne les compteurs dans trois/quatre cellules avec icônes et nombres lisibles.
- Affiche les sorts de départ dès « Bouge pour commencer », via l'API loadout
  structurée et le repli sur les paquets frais.
- Intègre les getters natifs boss/gardiens : Reborn garde ses gardiens hors
  d'AZS_UNITS, ce qui empêchait les barres Chronicle héritées de les afficher.
- Renforce le dimensionnement initial des surfaces et la restauration native.

Audit : [REBORN_API_AUDIT.md](REBORN_API_AUDIT.md) et inventaire machine
[REBORN_API_COVERAGE.json](REBORN_API_COVERAGE.json).
Tests de production et exécution des sources API installées ; recette visuelle
en jeu encore requise. Cette préversion ne vaut pas validation du registre officiel.

Après installation, redémarrer le client une fois la partie terminée.
