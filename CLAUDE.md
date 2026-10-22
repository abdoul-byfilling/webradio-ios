# Radio de l'Avenir — app iOS

Cette app est une **coquille** : elle affiche le site
https://www.eiffageconcessionssenegal.sn/app3/ dans une WKWebView et apporte
seulement ce que le web ne sait pas faire (micro, audio en arrière-plan,
écran de lancement, notifications push, liens externes, écran hors
connexion).

## Contrat avec le site

La règle commune est le contrat du dépôt du site, `webradio-app` :
`docs/app-native.md` (cloner webradio-app à côté de ce projet, en lecture seule).

- Version du contrat respectée par cette app : **10** (recette du
  2026-10-22, voir README.md).
- Lire le contrat avant toute modification touchant la webview, les liens,
  le User-Agent, les permissions, l'audio, les écrans de démarrage, la
  couleur de la barre d'état ou les notifications.
- Si une demande contredit le contrat, le signaler au lieu de l'appliquer :
  le contrat se modifie d'abord dans le dépôt du site.

## Interdits

- Ne jamais modifier le dépôt du site depuis ce projet.
- Ne pas recopier de contenu du site (textes, listes, couleurs d'écran).
  Seule exception : les trois textes de l'écran de démarrage, recopiés du
  contrat (§4). Les textes des notifications se rédigent dans
  l'administration du site, jamais ici.
- Ne pas appeler les API du site (`api/…`) depuis le code natif. Seule
  exception : l'inscription aux notifications (§8).
- Ne jamais committer de certificat (`*.p12`), profil (`*.mobileprovision`),
  clé App Store Connect ou APNs (`*.p8`) ni `GoogleService-Info.plist` :
  voir .gitignore.

## Projet

- Swift, UIKit + storyboards, projet `EiffageWebView.xcodeproj`.
- Identifiant : `com.icreo.radiodelavenir` — ne JAMAIS le changer (c'est
  l'app installée chez les utilisateurs ; un autre identifiant = une autre app).
- Équipe Apple : `39NW638GX5` (SENAC SA), signature automatique.
- Version publiée sur l'App Store : **2 (build 2)**. Ce code est en
  **2.1 (build 3)**. Chaque envoi doit augmenter le build
  (`CURRENT_PROJECT_VERSION`) et, pour une nouvelle version,
  `MARKETING_VERSION`.
- Compiler et publier : sur le Mac, dans Xcode.

## Travail avec Claude

- Une branche par sujet, messages de commit en français, fusion directe dans
  main (pas de PR), branche supprimée ensuite.
- Avant de publier sur l'App Store : dérouler la recette du contrat (§10).
- Répondre en français.
