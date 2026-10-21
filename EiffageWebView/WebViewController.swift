import UIKit
import WebKit
import Network

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    // MARK: - Properties
    private var webView: WKWebView!
    @IBOutlet weak var progressView: UIProgressView!
    
    // Adresse chargée et partie du site qui reste dans l'app (contrat §1)
    private let targetURL = "https://www.eiffageconcessionssenegal.sn/app3/index.php"
    private let appPrefix = "https://www.eiffageconcessionssenegal.sn/app3/"
    private var connectivityManager = ConnectivityManager()
    private var progressObserver: NSKeyValueObservation?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupUI()
        setupConnectivityMonitoring()
        loadWebsite()
    }
    
    deinit {
        progressObserver?.invalidate()
        connectivityManager.stopMonitoring()
    }

    // MARK: - Setup Methods
    private func setupUI() {
        // Pas de barre native : le site a sa propre navigation
        // Progress view setup
        view.bringSubviewToFront(progressView)
        progressView.progressTintColor = UIColor.systemBlue
        progressView.trackTintColor = UIColor.systemGray5
        progressView.isHidden = true
    }
    
    private func setupWebView() {
        // Réglages de la webview (contrat §3)
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.websiteDataStore = .default()

        // Marqueur ajouté au User-Agent de Safari, sans le remplacer (contrat §2)
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let defaultName = configuration.applicationNameForUserAgent ?? ""
        configuration.applicationNameForUserAgent = "\(defaultName) WebRadioAvenirApp/\(version)"
            .trimmingCharacters(in: .whitespaces)

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        // Progress observation
        progressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateProgress()
            }
        }
    }
    
    private func setupConnectivityMonitoring() {
        // Une coupure pendant l'écoute ne masque pas le site ; le retour du
        // réseau recharge seulement si l'écran « Pas de connexion » est affiché
        connectivityManager.onConnectivityChanged = { [weak self] isConnected in
            DispatchQueue.main.async {
                if isConnected && self?.presentedViewController is OfflineViewController {
                    self?.loadWebsite()
                }
            }
        }
        connectivityManager.startMonitoring()
    }
    
    // MARK: - Web Loading
    private func loadWebsite() {
        guard let url = URL(string: targetURL) else {
            showError("URL invalide")
            return
        }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        webView.load(request)
    }
    
    // MARK: - Progress Management
    private func updateProgress() {
        let progress = Float(webView.estimatedProgress)
        
        if progress >= 1.0 {
            // Loading complete
            UIView.animate(withDuration: 0.3, animations: {
                self.progressView.alpha = 0
            }) { _ in
                self.progressView.isHidden = true
                self.progressView.progress = 0
            }
        } else {
            // Loading in progress
            if progressView.isHidden {
                progressView.isHidden = false
                progressView.alpha = 0
                UIView.animate(withDuration: 0.3) {
                    self.progressView.alpha = 1
                }
            }
            progressView.setProgress(progress, animated: true)
        }
    }
    
    // MARK: - Connectivity Handling
    // Écran « Pas de connexion » quand le site ne se charge pas (contrat §3).
    // Il reste affiché pendant les nouvelles tentatives et se ferme dès que
    // le site répond.
    private func showOffline() {
        guard presentedViewController == nil else { return }
        let offlineVC = OfflineViewController()
        offlineVC.onRetryTapped = { [weak self] in
            self?.loadWebsite()
        }

        offlineVC.modalPresentationStyle = .fullScreen
        present(offlineVC, animated: true)
    }

    private func hideOffline() {
        if presentedViewController is OfflineViewController {
            dismiss(animated: true)
        }
    }

    // MARK: - Error Handling
    private let offlineErrorCodes: Set<Int> = [
        NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost,
        NSURLErrorTimedOut, NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost,
        NSURLErrorDNSLookupFailed, NSURLErrorInternationalRoamingOff, NSURLErrorDataNotAllowed
    ]

    private func handleLoadError(_ error: Error) {
        updateProgress()
        let nsError = error as NSError

        // Chargement interrompu par un autre clic ou par un lien ouvert hors
        // de l'app : rien à signaler
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
        if nsError.domain == WKError.errorDomain && nsError.code == 102 { return }

        if !connectivityManager.isConnected || (nsError.domain == NSURLErrorDomain && offlineErrorCodes.contains(nsError.code)) {
            showOffline()
        } else if presentedViewController == nil {
            showError("Impossible de charger la page : \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Erreur", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Réessayer", style: .default) { _ in
            self.loadWebsite()
        })
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateProgress()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        hideOffline()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateProgress()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadError(error)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // Seule la page principale suit la règle ; les cadres intégrés et
        // about:blank se chargent normalement
        if navigationAction.targetFrame?.isMainFrame == false || url.scheme == "about" || isInApp(url) {
            decisionHandler(.allow)
            return
        }

        // Tout le reste (tel:, mailto:, wa.me, réseaux sociaux, reste du
        // domaine), clic ou redirection, s'ouvre hors de l'app
        UIApplication.shared.open(url)
        decisionHandler(.cancel)
    }

    private func isInApp(_ url: URL) -> Bool {
        return url.absoluteString.hasPrefix(appPrefix)
    }
    
    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // target="_blank" et window.open() : même règle que les liens,
        // jamais de nouvelle fenêtre dans l'app (contrat §1)
        if let url = navigationAction.request.url {
            if isInApp(url) {
                webView.load(navigationAction.request)
            } else {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }
    
    // Micro des dédicaces vocales : accordé seulement au site et seulement
    // pour le micro (contrat §5). iOS demande ensuite l'autorisation système.
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        let isSite = origin.protocol == "https" && origin.host == "www.eiffageconcessionssenegal.sn" && origin.port == 0
        decisionHandler(isSite && type == .microphone ? .grant : .deny)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel) { _ in
            completionHandler(false)
        })
        present(alert, animated: true)
    }
}