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
- Corrige le mode auto après /reload lorsque AZSZONE n'est pas renvoyé ; le
  nom de carte est repris depuis le monde, la difficulté inconnue reste inconnue.
- Retire les doubles flèches du chat natif Reborn et les fausses distances des
  lairs en phase d'attente ; les distances actives utilisent la pose officielle.
- Si le jeu ne resynchronise pas les charges du Destrier après /reload, affiche
  un repère « ? » séparé, sans inventer de charges ni forcer une action.

Audit : [REBORN_API_AUDIT.md](REBORN_API_AUDIT.md) et inventaire machine
[REBORN_API_COVERAGE.json](REBORN_API_COVERAGE.json).
Tests de production, exécution des sources API installées et recette visuelle
partielle dans le vrai client : trois dispositions, six cases, compteurs,
sorts de départ, détails de sorts et retour du thème après /reload. Combats
prolongés, charges du Destrier et coop restent à valider. Cette préversion
ne vaut pas validation du registre officiel.

Après installation, redémarrer le client une fois la partie terminée.
