# EiffageWebView - Application iOS Native

Application iOS native en Swift utilisant WKWebView pour afficher le site web d'Eiffage Concessions Sénégal.

## Fonctionnalités

### ✅ Fonctionnalités Principales
- **WebView Principal** : Charge `https://www.eiffageconcessionssenegal.sn/app3/index.php?page=home`
- **Barre de Progression** : Indicateur de chargement synchronisé avec WKWebView
- **Gestion Offline** : Écran personnalisé "Pas de connexion" avec détection automatique
- **Menu Paramètres** : Options de nettoyage du cache et des cookies
- **Navigation Native** : Boutons retour, actualisation et paramètres

### 🎨 Interface Utilisateur
- Design iOS natif conforme aux guidelines Apple
- Barre de navigation système avec boutons d'action
- Écran offline élégant avec animations
- Menu paramètres complet et intuitif
- Support du mode sombre/clair automatique

### 🔧 Fonctionnalités Techniques
- **WKWebView** avec délégation complète de navigation
- **Network Framework** pour la détection de connectivité
- **Gestion des erreurs** robuste avec alertes utilisateur
- **Liens externes** ouverts dans Safari
- **Cache et cookies** gérés via WKWebsiteDataStore

## Structure du Projet

```
EiffageWebView/
├── EiffageWebView.xcodeproj/     # Projet Xcode
├── EiffageWebView/
│   ├── AppDelegate.swift         # Délégué d'application
│   ├── SceneDelegate.swift       # Délégué de scène
│   ├── WebViewController.swift   # Contrôleur principal WebView
│   ├── SettingsViewController.swift # Menu paramètres
│   ├── OfflineViewController.swift  # Écran offline
│   ├── ConnectivityManager.swift    # Gestionnaire de connectivité
│   ├── Main.storyboard          # Interface utilisateur
│   ├── LaunchScreen.storyboard  # Écran de lancement
│   ├── Assets.xcassets/         # Ressources graphiques
│   └── Info.plist              # Configuration de l'app
└── README.md
```

## Installation et Utilisation

### Prérequis
- macOS avec Xcode 15.0+
- iOS 13.0+ (cible de déploiement)
- Compte développeur Apple (pour déploiement sur appareil)

### Étapes d'Installation

1. **Ouvrir le Projet**
   ```bash
   # Ouvrir le fichier projet dans Xcode
   open EiffageWebView.xcodeproj
   ```

2. **Configuration**
   - Sélectionner votre équipe de développement dans les paramètres du projet
   - Modifier le Bundle Identifier si nécessaire : `com.eiffage.webview`
   - Vérifier les paramètres de signature de code

3. **Compilation et Test**
   - Sélectionner un simulateur iOS ou un appareil connecté
   - Appuyer sur `Cmd + R` pour compiler et lancer l'application

### Déploiement App Store

L'application est conçue pour respecter les guidelines de l'App Store :

- ✅ **Fonctionnalités natives** : Barre de progression, gestion offline, paramètres
- ✅ **Interface utilisateur native** : Design iOS conforme aux HIG
- ✅ **Gestion des erreurs** : Alertes et écrans d'erreur appropriés
- ✅ **Permissions** : Accès réseau uniquement (NSAppTransportSecurity configuré)
- ✅ **Performance** : Optimisations WebView et gestion mémoire

## Configuration Technique

### URL Cible
```swift
private let targetURL = "https://www.eiffageconcessionssenegal.sn/app3/index.php?page=home"
```

### Paramètres WebView
- **User Agent** : Configuré pour iOS Safari
- **Media Playback** : Lecture automatique activée
- **JavaScript** : Activé par défaut
- **Cookies** : Gestion automatique avec options de nettoyage

### Sécurité Réseau
- **ATS (App Transport Security)** : Configuré pour permettre HTTP/HTTPS
- **Domaines autorisés** : Navigation limitée au domaine Eiffage
- **Liens externes** : Redirection automatique vers Safari

## Personnalisation

### Modifier l'URL du Site
```swift
// Dans WebViewController.swift
private let targetURL = "VOTRE_URL_ICI"
```

### Personnaliser l'Interface
- **Couleurs** : Modifier les couleurs dans `Assets.xcassets`
- **Icône** : Remplacer les icônes dans `AppIcon.appiconset`
- **Titre** : Modifier dans `WebViewController.swift` et `Info.plist`

### Ajouter des Fonctionnalités
- **Push Notifications** : Ajouter le framework UserNotifications
- **Analytics** : Intégrer Firebase ou autre solution
- **Partage** : Ajouter UIActivityViewController

## Support et Maintenance

### Logs et Débogage
L'application utilise les logs système iOS. Pour déboguer :
```bash
# Voir les logs en temps réel
xcrun simctl spawn booted log stream --predicate 'process == "EiffageWebView"'
```

### Problèmes Courants
1. **Erreur de chargement** : Vérifier la connectivité et l'URL
2. **Problème de certificat** : Configurer ATS dans Info.plist
3. **Performance** : Optimiser le cache WebView

### Mises à Jour
- Tester régulièrement avec les nouvelles versions d'iOS
- Mettre à jour les dépendances Xcode
- Vérifier la compatibilité du site web

## Licence

MIT License - Voir le fichier LICENSE pour plus de détails.

---

**Développé pour Eiffage Concessions Sénégal**  
Application iOS native optimisée pour l'App Store