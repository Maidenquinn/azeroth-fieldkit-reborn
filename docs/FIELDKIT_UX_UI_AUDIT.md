# FieldKit — audit UX/UI

**Limite principale** : aucune capture d'écran ni session client par l'agent. Ce document distingue :

- ce qui est **prouvé par le code** ;
- ce qui est **couvert par des fixtures** (mocks géométriques dans `tests/`) ;
- ce qui **doit être vérifié visuellement**, listé en §5 avec un protocole de captures.

## 1. Lisibilité et contraste

| ID | Constat | Preuve | Statut |
|---|---|---|---|
| UX-02 | La correction de contraste `.38` est une plaque sombre à 94 % d'opacité, posée sous **les seules fenêtres du compteur** (principale et détachées). Les autres cartes suivent l'opacité de thème réglable par l'utilisateur (`cardOpacity` 0–100, `Config.lua`) : statistiques, équipement, subis, antres, mode, argent, survol groupe (`PartyDetails`), timeline des boss, cartes du thème de référence. | `MeterSuite.lua:115-123` (`EnsureMeterContrast`) ; aucun équivalent dans `PartyDetails.lua`, `TakenDetails.lua`, `ReferenceHUD.lua`, `ThemeHUD.lua` (recherche « Contrast ») | **Probable** : les problèmes de transparence corrigés pour le compteur peuvent subsister ailleurs à faible opacité. **À vérifier par captures.** |
| UX-03 | Le texte des lignes du compteur est forcé en blanc (.97,.97,1) sur des barres colorées à 45–55 % d'alpha. Le contraste est bon sur la plaque sombre. | `MeterSuite.lua` (`Paint`) | Confirmé (code) |
| UX-04 | Les critiques maximales sont en orange (1,.55,.2) et les coups normaux en gris clair. La distinction repose sur la couleur seule. | `MeterLedger.lua` (`AppendStats`), `PartyDetails.lua:344` | Confirmé. Accessibilité : ajouter un repère non chromatique, par exemple « ✦ » ou « (crit) ». |

## 2. Hiérarchie de l'information et retours utilisateur

| ID | Constat | Statut |
|---|---|---|
| UX-05 | Pas d'indication quand l'échantillon de coups est incomplet (compteur masqué, ou trou de plus de 3 s du flux). Les totaux natifs sont complets alors que coups et critiques sont partiels (STAT-03). | Confirmé (code) |
| UX-06 | « Taux critique : - » distingue maintenant « inconnu » de « 0 % » (`.39`). Cohérent dans l'infobulle, le HUD de référence et les détails de groupe. | Confirmé |
| UX-01 | Bascule « soins reçus » refusée silencieusement (perspective non supportée en 0.7.4) | Hypothèse : à vérifier en jeu |
| UX-07 | Le burst sur 1 s peut être surestimé après un réaffichage du compteur (STAT-02) : un chiffre affiché comme record pourrait être faux. | Confirmé (code) |
| UX-08 | Le texte flottant et les pop-ups ne montrent jamais de critique périodique alors que le compteur, lui, les compte (CT-01). L'incohérence est visible pour un Paladin. | Confirmé (code) |

## 3. Textes, langues et troncature

- **I18N-01** (P2) : contresens dans les 12 langues additionnelles sur « Max hit », « Crit rate », « Hits », « No hit sample… ». Détail dans l'audit complet.
- **I18N-02** (P3) : suffixe anglais « (non-crit) » codé en dur (`MeterLedger.lua:714`). Libellé « DPS » littéral (`ReferenceHUD.lua:703`) à côté de « HPS » localisé (`:1838`).
- Les noms natifs restent des noms d'affichage. Le calcul s'appuie sur le `spellId`, le `sourceKey` et les clés de famille (`MeterLedger.lua`, `SourceFamily`, `ResolveBook`) ; le nom ne sert de clé que pour les *books* de coups, normalisé et sans le rang. **Exception : STAT-01** (kills indexés par nom de victime).
- Le contrôle automatique couvre la présence des 1 078 chaînes et le format de leurs placeholders. Il ne couvre **ni le sens, ni la longueur affichée**. Les langues à mots longs (de, ru, pl) risquent la troncature dans les colonnes du compteur (largeur de base 320–340 px, `MeterSuite.lua`, `Paint`). **À vérifier par captures.**
- Polices : couverture des glyphes vérifiée pour les 14 langues (`check_locale_fonts.py`, polices OFL avec empreintes).

## 4. Thèmes, disposition et résolutions

- Couvert par des fixtures : 6 dispositions de thème, 4 tailles d'écran (alignement), 5 tailles de viewport (aperçus), collisions des cartes, restauration de la mini-carte native et de l'échelle native. Voir les en-têtes de `CHANGELOG.md` pour `.36` et `.37`.
- Non couvert visuellement en `.39` : rendu réel de chaque thème × variante × langue ; superposition avec les fenêtres natives 0.7.4 (nouvelles bannières, choix de cartes) ; ultra-large (déjà noté comme non revendiqué en `.36`).

## 5. Protocole de captures (à réaliser en jeu)

Résolutions : 1920×1080 et 2560×1440, plus une capture ultra-large si disponible.

1. Thème standard sans zone, opacité des cartes à 100 %, puis 40 %, puis 0 % : compteur, statistiques, équipement, subis, antres, survol d'un membre de groupe, timeline des boss.
2. Thèmes Elwynn et Naxx, variantes minimal, complete et alternative : mêmes cartes.
3. Langues fr, de, ru, zh : infobulle d'un sort du compteur (vérifie I18N-01 et la troncature).
4. Écran de choix de carte et de niveau ouvert : vérifier qu'aucune carte FieldKit ne passe au-dessus.
5. Après la mort, entre deux parties, après `/reload` : cartes masquées ou vidées correctement, pas de données périmées.
6. Coop à 2 : survol d'un coéquipier, puis départ du coéquipier pendant le survol.

Joindre les captures à l'issue correspondante. Chaque capture valide ou invalide un point « Probable » ou « Hypothèse » ci-dessus.

## 6. Recommandations UX/UI hiérarchisées

| Priorité | Recommandation | Lien |
|---|---|---|
| 1 | Corriger les traductions de combat et ajouter un glossaire de combat | I18N-01 |
| 2 | Plancher de contraste commun à toutes les cartes de données, sans toucher aux réglages du thème (même technique que `EnsureMeterContrast`, plaque allouée une seule fois) | UX-02 |
| 3 | Mention « échantillon partiel » dans l'infobulle quand des événements ont été manqués | UX-05, STAT-03 |
| 4 | Critiques périodiques dans le texte flottant et les pop-ups | CT-01, UX-08 |
| 5 | Repère non chromatique pour les critiques | UX-04 |
| 6 | Retour visible quand une option n'est pas supportée par le jeu (bouton grisé et raison dans l'infobulle) | UX-01 |
