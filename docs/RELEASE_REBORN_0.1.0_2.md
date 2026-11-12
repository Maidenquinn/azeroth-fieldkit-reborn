# Azeroth FieldKit Reborn 0.1.0-reborn.2

Corrige le démarrage incomplet et l'intégration des thèmes au HUD Reborn.

- GetPlayerBuff et sa famille ne sont pas disponibles dans Reborn. Cette erreur
  interrompait l'initialisation après la boussole et la barre de vie. Les buffs
  sont maintenant lus dans AZS_BUFFS/GetSpellInfo, avec un repli UnitBuff sans
  durée inventée. Les tests Reborn suppriment explicitement les anciens appels.
- Le mode Auto accepte désormais les cartes d'extension. Il réutilise l'habillage
  Elwynn pour les trois compositions, tout en conservant le nom et les données
  de Zangarmarsh et des autres cartes. Aucun nouveau thème illustré n'est annoncé.
- La barre de vie, les ressources et le conteneur des actions AzerothSurvivorsUI
  cèdent la place au thème. Les vrais boutons d'action Reborn sont déplacés dans
  le dock FieldKit : leurs scripts, rangs et cooldowns natifs sont conservés.
- Les éléments de suivi/compteurs natifs sont masqués via l'API officielle
  AZS_SetHudShown. La désactivation du thème restaure les cadres natifs et leurs
  boutons. Aucun addon fourni par le jeu n'est désactivé ou modifié.

Tests : démarrage et paramètres sans GetPlayerBuff ; durées, expiration et buffs
permanents ; trois thèmes sur carte d'extension ; maintien des callbacks des
boutons ; restauration des parents, visibilité et préférences natives.

Le défaut initial et le HUD partiellement chargé ont été observés sur les captures
du mainteneur. Les nouveaux correctifs sont testés hors jeu ; leur rendu complet
dans le client reste à confirmer. La coop et les performances longues ne sont
pas certifiées. Les notices de droits et crédits restent jointes.

Après mise à jour : redémarrer le client puis /fieldkit → Interface → Look,
activer les thèmes et sélectionner Auto et la composition souhaitée.
