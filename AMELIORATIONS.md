# Pistes d'amélioration

Note du 2026-10-23, après la version 2.1 (build 3) et le contrat v12.

L'app reste une webview qui affiche le site : c'est le bon choix pour tout
le contenu (une seule base de code pour le site et les deux apps, mises à
jour sans passer par les stores). Les pistes ci-dessous ne remettent pas ce
choix en cause : elles visent les endroits où la webview montre ses
limites, d'abord l'audio.

Toute piste qui change le comportement commun aux deux apps passe d'abord
par le contrat (`webradio-app/docs/app-native.md`).

| # | Piste | Gain | Taille | Priorité |
|---|---|---|---|---|
| 1 | Lecteur radio natif (pont audio) | Reprise fiable après un appel, écran verrouillé tenu par l'app | Grande | Haute si l'écoute en voiture compte |
| 2 | CarPlay et Android Auto | La radio au volant, sur l'écran de la voiture | Moyenne, après 1 | Haute pour une radio d'autoroute |
| 3 | AirPlay, widgets, Siri | Confort, visibilité | Petite à moyenne, après 1 | Basse |
| 4 | Stabiliser les ponts app ↔ site | Moins de versions du contrat, moins de surprises | Petite | Continue |
| 5 | Taille du texte réglable | Accessibilité, depuis que le zoom est bloqué (contrat v11) | Petite (site) | Moyenne |
| 6 | Points ouverts relevés pendant la 2.1 | Finitions | Petite | À traiter au fil de l'eau |

## 1. Lecteur radio natif

**Constat (recette 2.1).** C'est WebKit, pas l'app, qui joue le son et le
déclare à iOS. Conséquences :

- après un appel décroché, écran verrouillé, iOS affiche Apple Music au
  lieu de la radio (limite acceptée, voir README) ;
- une app en arrière-plan ne peut pas relancer le flux en direct sans geste
  de l'auditeur ; la reprise après un appel repose sur des contournements
  dans le lecteur du site (`global-player.js`, commits `0bb23ae`, `243e539`) ;
- côté Android, il faut un service de premier plan piloté par
  `AudioPlaybackCallback` (contrat §6) pour que la webview continue de jouer.

**Proposition.** Garder la webview pour l'affichage, mais faire jouer le
flux en direct par l'app :

- iOS : `AVPlayer`, session `AVAudioSession` active pendant l'écoute,
  notifications d'interruption (reprise à la fin d'un appel),
  `MPNowPlayingInfoCenter` (titre, pochette) et `MPRemoteCommandCenter`
  (lecture/pause écran verrouillé, casque, voiture) ;
- Android : Media3 (`ExoPlayer` + `MediaSessionService`), qui remplace le
  service de premier plan actuel ;
- le site garde le bouton ▶ et l'affichage : dans l'app, il demande la
  lecture à l'app au lieu de jouer lui-même, et l'app lui renvoie l'état
  (lecture, chargement, pause, erreur) pour qu'il mette son interface à jour.

**À écrire dans le contrat avant de coder** : le pont (noms des messages
dans les deux sens, `window.webkit.messageHandlers` côté iOS,
`@JavascriptInterface` côté Android), ce que le site fait quand le pont est
absent (navigateur, ancienne version de l'app : lecture web comme
aujourd'hui), l'adresse du flux (fournie par le site, jamais écrite dans
l'app), les métadonnées affichées sur l'écran verrouillé.

**Points d'attention.**

- Les podcasts : à garder en lecture web dans un premier temps, ou à passer
  aussi par le pont (avance, retour, barre de progression).
- Une seule source de vérité pour l'état de lecture, sinon le bouton du
  site et l'écran verrouillé se contredisent.
- Recette à refaire en entier (§6 et §10 du contrat), sur un vrai iPhone et
  un vrai téléphone Android.

## 2. CarPlay et Android Auto

Une webview ne peut pas s'afficher dans CarPlay ni dans Android Auto : il
faut le lecteur natif (piste 1).

- iOS : modèle CarPlay « audio » (`CPTemplateApplicationScene`, liste avec
  la radio en direct, éventuellement les derniers podcasts). Demander
  d'abord à Apple l'autorisation CarPlay audio pour le compte SENAC SA
  (formulaire développeur, délai de réponse variable).
- Android : `MediaLibraryService` de Media3, reconnu par Android Auto.

C'est probablement le gain le plus visible pour les auditeurs d'une radio
d'autoroute.

## 3. AirPlay, widgets, Siri

Une fois le lecteur natif en place : AirPlay (presque gratuit avec
`AVPlayer`), widget « Écouter la radio » sur l'écran d'accueil et l'écran
verrouillé, raccourci Siri (« écoute Radio de l'Avenir »).

## 4. Stabiliser les ponts app ↔ site

Ponts en place aujourd'hui : marqueur `WebRadioAvenirApp` dans le
User-Agent (§2), `<meta name="theme-color">` (§4), `window.spa.navigateTo`
(§8), balise viewport (zoom, §3), `api/push-register.php` (§8). Le contrat
a connu 12 versions en trois jours.

- Regrouper ces ponts dans une section du contrat qui en fait la liste
  complète, avec pour chacun ce qui le vérifie (`tests/e2e.sh`, recette).
- N'en ajouter un nouveau que si le web ne peut vraiment pas faire sans.
- Garder chaque pont tolérant : si le site ou l'app ne le connaît pas,
  comportement normal (comme aujourd'hui pour `window.spa`).

## 5. Taille du texte réglable

Le zoom est bloqué dans les apps depuis le contrat v11 (balise viewport
envoyée par le site dans l'app seulement). Pour les personnes malvoyantes,
proposer côté site un réglage de taille du texte (onglet Plus), enregistré
comme le thème. Rien à faire dans l'app.

## 6. Points ouverts relevés pendant la 2.1

- **Couleur de la barre d'état sur l'écran Octobre Rose** : `#FF69B4`
  annoncé par le site, alors que le haut du fond (dégradé en diagonale)
  est plus soutenu ; légère démarcation. À régler côté site
  (`tav_splash_bar_color()` ou dégradé vertical).
- **Toucher une notification dans la seconde qui suit le lancement** : une
  fois, `window.spa.navigateTo` appelé trop tôt (site pas encore initialisé)
  a donné une page incohérente. Pas reproduit ensuite ; à surveiller.
- **Compteur « appareils atteints »** : c'est un maximum, pas un nombre de
  personnes (appareils désinstallés comptés jusqu'à ce que Firebase les
  déclare inconnus, notifications désactivées toujours comptées).
- **Règle 4.2 d'Apple** (« fonctionnalités minimales ») : les fonctions
  natives (démarrage, notifications, audio en arrière-plan, micro) protègent
  l'app d'un refus pour « site emballé ». Les garder en tête à chaque
  version, et ne pas en retirer sans raison.
- **Textes natifs hors liste du contrat (§9)** : écran « Pas de connexion »
  et boîtes d'erreur. À ajouter aux exceptions du contrat.
