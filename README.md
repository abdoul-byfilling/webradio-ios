# Radio de l'Avenir — application iOS

Webview (WKWebView) qui affiche le site de la radio
(https://www.eiffageconcessionssenegal.sn/app3/). Tout le contenu vient du site
(dépôt `webradio-app`) ; les règles entre le site et l'app sont dans son
`docs/app-native.md`.

- App Store : « Radio de l'Avenir - SECAA », id 1669289109, vendeur SENAC SA
- Identifiant : `com.icreo.radiodelavenir` (celui de l'ancienne app RadioKing,
  gardé pour que les utilisateurs passent à cette app par une simple mise à jour)
- Équipe Apple : `39NW638GX5` (SENAC SA) — signature automatique par Xcode
- iOS minimum : 15
- Version publiée : **2 (build 2)**, envoyée le 2025-07-07
- Version dans ce code : **2.1 (build 3)**, pas encore publiée
- Contrat respecté : **aucun pour l'instant**, objectif version 4

## Origine

La source exacte de la 2.0 est introuvable (elle était dans
`/Users/attila/Downloads/project` sur le Mac, d'après l'archive Xcode). Ce dépôt
part du projet Bolt `EiffageWebView` (même nom de projet, mêmes écrans), aligné
sur la 2.0 d'après son archive : identifiant, équipe, nom affiché, version,
iOS 15, micro déclaré, audio en arrière-plan, arm64, icône.

Différences connues avec la 2.0, non reproduites faute de source :

- la 2.0 avait un écran de démarrage animé (`SplashViewController`) ; ici,
  seul l'écran de lancement statique (`LaunchScreen.storyboard`) s'affiche,
  ce que demande justement le contrat (§4) ;
- la 2.0 demandait elle-même l'autorisation du micro (messages « Permission
  microphone accordée / refusée ») ;
- la 2.0 autorisait la page à lire les fichiers locaux
  (`allowFileAccessFromFileURLs`, `allowUniversalAccessFromFileURLs`) : à ne
  pas reprendre.

## Compiler et publier

Sur le Mac : ouvrir `EiffageWebView.xcodeproj` dans Xcode, choisir l'équipe
SENAC SA si Xcode la demande, lancer sur un iPhone. Pour publier :
Product → Archive, puis Distribute App → App Store Connect.

## Écarts avec le contrat

Relevés le 2026-10-21 et corrigés le même jour (vérifiés sur simulateur
iOS 18.5) :

1. User-Agent : celui du système + `WebRadioAvenirApp/<version>` ; le site
   renvoie `data-in-app="1"` (§2).
2. Webview créée en code avec sa configuration : lecture en ligne, données
   du site persistantes (§3).
3. Micro accordé seulement au site ; texte « Le micro sert à enregistrer
   votre dédicace vocale. » (§5).
4. Liens : seul `/app3/` reste dans l'app, tout le reste s'ouvre à
   l'extérieur, clic, redirection ou `target="_blank"` (§1). Adresse
   chargée : `app3/index.php` sans paramètre.
5. Barre de navigation native et écran Réglages supprimés.
6. `NSAllowsArbitraryLoads` retiré (tout est en https, flux radio compris).
7. Portrait seul sur iPhone (l'iPad garde toutes les orientations).
8. Écran hors connexion : affiché seulement si le site ne se charge pas ;
   « Réessayer » et le retour du réseau rechargent le site.

Aussi corrigé : le projet ne compilait pas (`LaunchScreen.storyboard`
utilisait `LaunchViewController`, interdit pour un écran de lancement).

Contrats versions 2 à 4 (2026-10-21), faits et vérifiés sur simulateur :

- Barre d'état à la couleur de `<meta name="theme-color">` du site, y
  compris au changement de thème sans rechargement.
- Écran de démarrage (§4) d'après la maquette « Démarrage » : fond
  `#0B2545` bord à bord, logo, les trois textes du contrat, égaliseur.
  `LaunchScreen.storyboard` en est la première image (textes transparents) ;
  l'app recharge ce storyboard, fait apparaître les textes en fondu et
  anime l'égaliseur (textes d'un coup et égaliseur immobile avec « Réduire
  les animations »), jusqu'au premier chargement du site. Les barres n'ont pas
  de coins arrondis : Xcode refuse les attributs personnalisés dans un
  écran de lancement.

Site déployé le 2026-10-22 : parcours vérifié sur simulateur avec le site
en ligne (écran saisonnier rose, accueil `#F2F5F8`, passage en thème
sombre sans rechargement).

## Recette sur iPhone

Faite le 2026-10-22 sur un iPhone 11, app lancée depuis Xcode :

- Radio en arrière-plan, écran verrouillé, bouton silencieux : OK.
- Commandes de l'écran verrouillé (Media Session du site) : OK.
- Appel entrant, écran déverrouillé (décroché ou non) : la radio se met en
  pause puis reprend seule, sur le direct.
- Appel refusé, écran verrouillé : la radio reste sur l'écran verrouillé,
  ▶ la relance sur le direct.
- **Limite connue**, appel décroché avec l'écran verrouillé : à la fin de
  l'appel, iOS affiche la dernière app de musique (Apple Music) sur l'écran
  verrouillé au lieu de la radio. Il faut ouvrir l'app et appuyer une fois
  sur ▶. C'est WebKit qui déclare la lecture à iOS : ni le site ni l'app
  n'y ont de prise directe. Piste non essayée : que l'app active elle-même
  sa session audio pendant l'écoute pour recevoir les interruptions d'iOS
  (jamais à l'ouverture de l'app, ce qui couperait la musique de
  l'auditeur).

La reprise après un appel est gérée par le site (`global-player.js`,
commits `0bb23ae` et `243e539` de `webradio-app`) : après une pause imposée,
toute reprise recharge le direct ; page cachée, la reprise automatique
d'iOS est remise en pause et l'appui de l'auditeur recharge le direct.

Reste avant de pouvoir annoncer la version 4 du contrat :

- **Recette du §9 sur un iPhone**, pour le reste : démarrage sans saut
  entre l'écran système et l'écran animé, podcast (la barre de progression
  avance), demande du micro et envoi d'une dédicace, `tel:` / `mailto:` /
  WhatsApp et réseaux sociaux hors de l'app, geste retour, mode avion,
  barre d'état en thème sombre.
