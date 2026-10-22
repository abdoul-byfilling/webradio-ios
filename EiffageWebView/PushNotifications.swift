import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

// Notifications push (contrat §8) : les messages se rédigent dans
// l'administration du site et partent par Firebase. L'app inscrit son jeton,
// demande l'autorisation une fois, affiche la bannière et ouvre la page choisie.
class PushNotifications: NSObject {

    static let shared = PushNotifications()

    // Seul appel aux API du site autorisé par le contrat (§9)
    private let registerURL = URL(string: "https://www.eiffageconcessionssenegal.sn/app3/api/push-register.php")!
    private let registeredKey = "pushRegistration"

    // Page à ouvrir après le toucher d'une notification, gardée tant que la
    // webview n'est pas prête (app lancée par la notification)
    private var pendingURL: URL?
    var onOpenURL: ((URL) -> Void)? {
        didSet { deliverPendingURL() }
    }

    private var isEnabled = false

    // MARK: - Start
    func start(application: UIApplication) {
        // Le toucher d'une notification arrive par ce délégué, même app fermée
        UNUserNotificationCenter.current().delegate = self

        // GoogleService-Info.plist n'est pas versionné : sans lui, pas de notifications
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("Notifications désactivées : GoogleService-Info.plist absent de l'app")
            return
        }
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()
        isEnabled = true
    }

    // MARK: - Authorization
    // Une seule demande, après le premier chargement de l'accueil ; un refus
    // est respecté (iOS ne repose plus la question)
    func requestAuthorizationIfNeeded() {
        guard isEnabled else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    // MARK: - Registration
    // Inscription du jeton auprès du site ; refaite si le jeton ou la version
    // de l'app change, et au lancement suivant si le site n'a pas pu répondre
    // (429, 5xx, pas de réseau). Un 400 (requête refusée) n'est pas retenté :
    // la même requête serait refusée encore (contrat §8)
    private func register(token: String) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let registration = "\(token)|\(version)"
        guard UserDefaults.standard.string(forKey: registeredKey) != registration else { return }

        var request = URLRequest(url: registerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "token": token,
            "platform": "ios",
            "app_version": version
        ])
        URLSession.shared.dataTask(with: request) { [registeredKey] _, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 200 {
                UserDefaults.standard.set(registration, forKey: registeredKey)
            } else if status == 400 {
                UserDefaults.standard.set(registration, forKey: registeredKey)
                print("Inscription aux notifications refusée par le site (HTTP 400) : pas de nouvel essai pour ce jeton")
            } else {
                print("Inscription aux notifications échouée (HTTP \(status), \(error?.localizedDescription ?? "")) : nouvel essai au prochain lancement")
            }
        }.resume()
    }

    // MARK: - Open
    private func open(_ address: String?) {
        // Seulement une page de l'app (contrat §1), sinon l'accueil
        let target = address.flatMap { $0.hasPrefix(WebViewController.appPrefix) ? URL(string: $0) : nil }
        pendingURL = target ?? URL(string: WebViewController.targetURL)
        deliverPendingURL()
    }

    private func deliverPendingURL() {
        guard let handler = onOpenURL, let url = pendingURL else { return }
        pendingURL = nil
        handler(url)
    }
}

// MARK: - MessagingDelegate
extension PushNotifications: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        register(token: token)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotifications: UNUserNotificationCenterDelegate {
    // App au premier plan : la bannière s'affiche quand même
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Toucher : ouvrir la page choisie dans l'administration (data.url)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let address = response.notification.request.content.userInfo["url"] as? String
        DispatchQueue.main.async {
            self.open(address)
        }
        completionHandler()
    }
}
