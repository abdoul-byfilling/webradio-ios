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
  ce que demande justement le contrat (§4). `LaunchViewController.swift`
  n'est utilisé nulle part (code mort) ;
- la 2.0 demandait elle-même l'autorisation du micro (messages « Permission
  microphone accordée / refusée ») ;
- la 2.0 autorisait la page à lire les fichiers locaux
  (`allowFileAccessFromFileURLs`, `allowUniversalAccessFromFileURLs`) : à ne
  pas reprendre.

## Compiler et publier

Sur le Mac : ouvrir `EiffageWebView.xcodeproj` dans Xcode, choisir l'équipe
SENAC SA si Xcode la demande, lancer sur un iPhone. Pour publier :
Product → Archive, puis Distribute App → App Store Connect.

## Écarts avec le contrat (relevés le 2026-10-21)

1. **User-Agent** : `customUserAgent` remplace tout par un faux Safari iOS 15,
   sans marqueur. Contrat §2 : garder le User-Agent du système et ajouter
   `WebRadioAvenirApp/<version>` (`configuration.applicationNameForUserAgent`).
2. **Configuration de la webview** : `setupWebView()` crée une
   `WKWebViewConfiguration` qui n'est jamais utilisée (la webview vient du
   storyboard) : créer la webview en code avec sa configuration (lecture en
   ligne, User-Agent, données du site persistantes).
3. **Micro** : aucune réponse à `requestMediaCapturePermissionFor` (iOS 15+) :
   accorder le micro seulement pour `https://www.eiffageconcessionssenegal.sn`.
   Texte de la demande à simplifier (contrat §5 : « Le micro sert à
   enregistrer votre dédicace vocale. »).
4. **Liens** : tout le domaine reste dans l'app, y compris le site WordPress
   d'Eiffage ; les redirections hors domaine qui ne sont pas des clics
   restent aussi dans l'app. Contrat §1 : seulement `/app3/` dans l'app.
5. **Interface native en trop** : barre de navigation « Eiffage Concessions »
   (titre, retour, actualiser, réglages) au-dessus du site, qui a déjà sa
   propre navigation ; écran Réglages (vider le cache / les cookies) inutile.
6. **`NSAllowsArbitraryLoads`** : autorise les connexions non chiffrées sans
   raison (le site est en https) ; à retirer.
7. **Orientation** : paysage autorisé sur iPhone ; le site est conçu en
   portrait.
8. **Écran hors connexion** : présent (bien) ; vérifier qu'il recharge le site.

À vérifier sur un iPhone : radio écran verrouillé (contrat §6), commandes de
l'écran verrouillé (Media Session du site).
