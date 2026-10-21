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
- Contrat respecté : **aucun pour l'instant**, objectif version 1

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

Reste avant de pouvoir annoncer la version 1 du contrat :

- **Écran de lancement (§4)** : il affiche un cadre vide et « Eiffage
  Concessions / Sénégal » ; le contrat demande le logo seul, à redessiner
  ensemble (maquette « Démarrage »). Il disparaît aussi avant que la
  première page soit chargée (écran blanc pendant le chargement).
- **Recette du §9 sur un iPhone**, en particulier : radio écran verrouillé
  et commandes de l'écran verrouillé (Media Session du site), demande du
  micro et envoi d'une dédicace, `tel:` / `mailto:` / WhatsApp, geste
  retour, mode avion. Sur simulateur, la radio continue app en
  arrière-plan.
