# Lot R1 · Portail de la Trésorerie gobeline

Candidat `0.1.0-reborn.42` pour Reborn 0.7.4, basé sur `.41`. La carte et l’alerte FieldKit sont deux réglages de profil, désactivés par défaut. L’icône dorée et la flèche natives continuent de fonctionner. La carte FieldKit est déplaçable dans le HUD et utilise les surfaces et polices existantes.

## Recette obligatoire dans le client

1. Sauvegarder les SavedVariables puis installer le dossier `AzerothFieldKitReborn/` du ZIP dans les AddOns du client et redémarrer. Vérifier `/fieldkit version`. Dans **Monde → Mini-carte**, activer l’indicateur. Dans la page des avertissements, activer **Alertes de portail gobelin** indépendamment des notifications générales.
2. Commencer une campagne sans portail. Vérifier l’absence de carte et d’alerte. Lancer `/fieldkit portal` et noter l’état et le compteur `packets`. Un état `unsynced` indique qu’aucune liste complète n’a été reçue. `absent` signifie qu’une liste valide a été reçue sans point `v`. Une faille scellée ou ouverte de type `p/o` doit laisser la carte invisible.
3. Attendre l’ouverture d’un portail doré, sans forcer l’événement. Capturer la carte, le pion/flèche du jeu et la sortie du diagnostic. Si une liste valide sans portail a précédé celle avec `v` dans le même contexte, il doit y avoir une seule alerte. Enchaîner les diagnostics pendant que le portail reste présent pour vérifier l’absence de répétition.
4. Ouvrir la carte du monde, consulter une autre région puis la fermer. L’indicateur de présence reste possible, la distance est masquée lorsque le référentiel ne correspond pas. Si une distance est disponible, s’approcher du portail et vérifier que la mesure horizontale en yards décroît. Tester le zoom et la rotation de la mini-carte, puis le passage en intérieur ou un changement d’étage si le scénario le permet. La position et le zoom de la carte doivent suivre les actions du joueur et le comportement natif.
5. Pendant un portail ouvert, effectuer un `/reload`. La carte peut revenir après les paquets natifs du nouveau contexte. Elle ne doit pas rejouer l’alerte d’ouverture. Tester la fermeture sans entrée, puis lors d’une autre apparition l’entrée dans la Trésorerie. Une liste valide retirant les points `v` doit faire disparaître la carte et l’alerte en cours.
6. Tester un changement de partie sur la même carte, un passage d’arène et un changement d’hôte coop si possible. Capturer les diagnostics avant/après. Pendant la transition, aucune donnée de l’ancien contexte ne doit rester visible. La reprise attend une ligne de partie et une nouvelle liste. Tester une victoire suivie d’une reprise Endless.
7. Tester les deux réglages séparément et changer de profil pendant que le portail est visible. Vérifier qu’une option d’alerte activée à ce moment ne rejoue pas l’événement. Vérifier la carte 240 × 32 ou 44, le glisser et les polices en FR/EN et dans une langue CJK. Tester sans thème, Elwynn et Naxx à la résolution habituelle et à une taille/échelle plus réduite.

Le diagnostic affiche les états `unsynced`, `absent`, `present`, `disappeared` et `invalid_context`, la raison, la phase, la carte, quatre points normalisés au maximum et les compteurs. Il ne diffuse rien au groupe et ne change ni réglage ni état natif. Les distances `missing_reference`, `different_map` ou `map_open` sont volontairement omises du HUD.

## Contrat et limites

- `NativeData.Packet` transmet les événements au lecteur borné. Le lecteur réagit à une nouvelle table `AZS_RIFT` après traitement natif de `AZSRIFT`. Un champ `m=""` ou une liste bien formée sans `v` est un état négatif confirmé. Un champ absent ou une liste illisible rend la source inconnue. Le premier snapshot actif après entrée ou resynchronisation affiche la présence sans alerte. Une alerte suit seulement une transition confirmée absent → présent, en phase de jeu. La file de notifications existante applique également son délai anti-spam de 5 s.
- Le contrat de portail ne livre aucun identifiant d’instance, altitude, TTL ni identifiant d’arène. Le contexte est lié au run natif `azs:r…` et à la carte après une ligne de partie. Les transitions d’arène, le changement d’hôte, l’entrée monde et la fin effacent les observations. Des paquets de rétablissement manquants laissent l’état inconnu. La fréquence et l’ordre de `AZSRIFT`, et son replay au reload/handover, doivent être observés en partie.
- Les points identiques sont dédoublonnés par paire de coordonnées dans le snapshot, sans identité persistée. La carte montre la présence de la catégorie et, si possible, la plus petite distance parmi les points reçus. Un changement de position, d’ordre ou de nombre de points pendant une présence continue ne déclenche pas de nouvelle alerte.
- Le calcul `sqrt(((mx-px)*mw)^2+((my-py)*mh)^2)` suit la métrique du jeu. Pour accepter la pose de carte, FieldKit utilise une référence coffre ou antre reçue dans le contexte courant avec coordonnées monde et carte. Il exige un accord à un yard par axe avec la pose monde directe, le même sélecteur de carte/étage après calibration et masque la mesure quand la carte du monde est ouverte. La mesure est horizontale, en yards, indépendante des obstacles et du trajet. Une référence ou une pose absente ne retire pas la présence confirmée. Aucune fonction ne force la carte ni ne sonde le zoom.

## Coût

Le lecteur garde un seul décodage en cache et borne une liste à 4 096 octets et 32 lignes. La déduplication n’opère que lors d’un changement de contenu. Par paquet coffre/antre, 16 lignes au plus sont examinées pour retenir une référence par source. La pose est lue seulement pour une carte active à afficher, au rythme de rafraîchissement de `NativeTools` (0,2 s en jeu), sans ticker propre. Un seul cadre réutilisable est créé à la première apparition affichée. Un test synthétique expédie 500 remplacements identiques, compte zéro nouveau décodage et zéro lecture de pose supplémentaire. Aucune mesure FPS en partie n’est incluse.

## Discord changelog

**FieldKit Reborn .42 — Goblin Treasury portal test build**

- Added an optional HUD indicator for the Goblin Treasury portal, with horizontal distance when the native map context can be verified.
- Added an independent alert for a confirmed opening. Reloading with an existing portal does not replay the alert.
- The game's gold minimap pin and direction arrow remain available. Both options are saved per profile and translated into all 14 FieldKit languages.
- Candidate for in-game testing. Use `/fieldkit portal` to include the native observation state in a bug report.
