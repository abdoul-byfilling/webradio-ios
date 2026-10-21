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
    private var themeColorObserver: NSKeyValueObservation?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupUI()
        showLaunchCover()
        setupConnectivityMonitoring()
        loadWebsite()
    }
    
    deinit {
        progressObserver?.invalidate()
        themeColorObserver?.invalidate()
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
        // Sous la barre d'état, qui garde la couleur annoncée par le site
        // (contrat §4) ; en bas, WebKit prolonge la page sous la barre d'accueil
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        
        // Couleur de la barre d'état : <meta name="theme-color"> du site, suivie
        // même quand elle change sans rechargement (contrat §4)
        themeColorObserver = webView.observe(\.themeColor, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                if let color = webView.themeColor {
                    self?.setStatusBarColor(color)
                }
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
    
    // MARK: - Status Bar
    // La vue derrière la barre d'état prend la couleur du site ; les icônes
    // sont foncées sur fond clair, claires sur fond foncé
    override var preferredStatusBarStyle: UIStatusBarStyle {
        guard let color = launchCover?.backgroundColor ?? view.backgroundColor else { return .default }
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.6 ? .darkContent : .lightContent
    }
    
    private func setStatusBarColor(_ color: UIColor) {
        view.backgroundColor = color
        setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: - Launch Screen
    // L'écran de lancement prend vie : même storyboard, textes en fondu,
    // égaliseur animé, jusqu'au premier chargement du site, sans durée
    // minimale (contrat §4)
    private var launchCoverController: UIViewController?
    private var launchCover: UIView? { return launchCoverController?.view }
    
    // Décalage de chaque barre dans son cycle d'une seconde, comme la maquette
    // « Démarrage » ; les hauteurs du storyboard sont celles de l'instant 0
    private let equalizerPhases: [CFTimeInterval] = [0, 0.45, 0.2, 0.7, 0.1]
    
    // Textes du storyboard, transparents sur l'écran système
    private let launchTextTags = [10, 11, 12]

    private func showLaunchCover() {
        // Contrôleur enfant : la vue garde la même zone sûre que l'écran système
        guard let coverController = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() else { return }
        addChild(coverController)
        let cover = coverController.view!
        cover.frame = view.bounds
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(cover)
        coverController.didMove(toParent: self)
        launchCoverController = coverController
        if let color = cover.backgroundColor {
            setStatusBarColor(color)
        }
        cover.layoutIfNeeded()
        showLaunchTexts(in: cover)
        animateEqualizer(in: cover)
    }
    
    // Fondu des textes l'un après l'autre ; d'un coup si « Réduire les
    // animations » est activé
    private func showLaunchTexts(in cover: UIView) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        for (index, tag) in launchTextTags.enumerated() {
            guard let label = cover.viewWithTag(tag) else { continue }
            if reduceMotion {
                label.alpha = 1
            } else {
                UIView.animate(withDuration: 0.8, delay: 0.2 * Double(index), options: [.curveEaseOut], animations: {
                    label.alpha = 1
                })
            }
        }
    }
    
    // Les barres du storyboard (tags 1 à 5) sont remplacées par des calques
    // animés partant de la même hauteur, donc sans saut ; immobiles si
    // « Réduire les animations » est activé
    private func animateEqualizer(in cover: UIView) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        
        for (index, phase) in equalizerPhases.enumerated() {
            guard let bar = cover.viewWithTag(index + 1), let container = bar.superview else { continue }
            let fullHeight = container.bounds.height
            
            let barLayer = CALayer()
            barLayer.backgroundColor = bar.backgroundColor?.cgColor
            barLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
            barLayer.bounds = CGRect(x: 0, y: 0, width: bar.bounds.width, height: fullHeight)
            barLayer.position = CGPoint(x: bar.frame.midX, y: fullHeight)
            barLayer.transform = CATransform3DMakeScale(1, bar.bounds.height / fullHeight, 1)
            container.layer.addSublayer(barLayer)
            bar.isHidden = true
            
            let animation = CAKeyframeAnimation(keyPath: "transform.scale.y")
            animation.values = [0.3, 1, 0.3]
            animation.keyTimes = [0, 0.5, 1]
            animation.timingFunctions = [CAMediaTimingFunction(name: .easeInEaseOut), CAMediaTimingFunction(name: .easeInEaseOut)]
            animation.duration = 1
            animation.repeatCount = .infinity
            animation.timeOffset = phase
            barLayer.add(animation, forKey: "egaliseur")
        }
    }

    private func hideLaunchCover() {
        guard let coverController = launchCoverController else { return }
        launchCoverController = nil
        setNeedsStatusBarAppearanceUpdate()
        coverController.willMove(toParent: nil)
        UIView.animate(withDuration: 0.25, animations: {
            coverController.view.alpha = 0
        }) { _ in
            coverController.view.removeFromSuperview()
            coverController.removeFromParent()
        }
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
        hideLaunchCover()
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