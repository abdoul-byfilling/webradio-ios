import UIKit
import WebKit
import Network

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    // MARK: - Properties
    private var webView: WKWebView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    
    private let targetURL = "https://www.eiffageconcessionssenegal.sn/app3/index.php?page=home"
    private var connectivityManager = ConnectivityManager()
    private var progressObserver: NSKeyValueObservation?
    private var isInitialLoad = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupUI()
        setupConnectivityMonitoring()
        loadWebsite()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        progressObserver?.invalidate()
        connectivityManager.stopMonitoring()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        title = "Eiffage Concessions"
        
        // Navigation bar setup
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = UIColor.systemBlue
        
        // Navigation bar buttons
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshWebView))
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(showSettings))
        
        navigationItem.rightBarButtonItems = [settingsButton, refreshButton]
        
        // Back button (only show when can go back)
        updateNavigationButtons()
        
        // Progress view setup
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
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
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
        connectivityManager.onConnectivityChanged = { [weak self] isConnected in
            DispatchQueue.main.async {
                if isConnected {
                    self?.handleConnectivityRestored()
                } else {
                    self?.handleConnectivityLost()
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
    
    // MARK: - Navigation Management
    private func updateNavigationButtons() {
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
        
        if webView.canGoBack {
            navigationItem.leftBarButtonItem = backButton
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    // MARK: - Connectivity Handling
    private func handleConnectivityLost() {
        let offlineVC = OfflineViewController()
        offlineVC.onRetryTapped = { [weak self] in
            self?.dismiss(animated: true) {
                self?.loadWebsite()
            }
        }
        
        offlineVC.modalPresentationStyle = .fullScreen
        present(offlineVC, animated: true)
    }
    
    private func handleConnectivityRestored() {
        if presentedViewController is OfflineViewController {
            dismiss(animated: true) {
                self.loadWebsite()
            }
        }
    }
    
    // MARK: - Error Handling
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Erreur", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Réessayer", style: .default) { _ in
            self.loadWebsite()
        })
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func refreshWebView() {
        webView.reload()
    }
    
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc private func showSettings() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateProgress()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateProgress()
        updateNavigationButtons()
        isInitialLoad = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateProgress()
        
        if !connectivityManager.isConnected {
            handleConnectivityLost()
        } else {
            showError("Erreur de chargement: \(error.localizedDescription)")
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        updateProgress()
        
        if !connectivityManager.isConnected {
            handleConnectivityLost()
        } else {
            showError("Impossible de charger la page: \(error.localizedDescription)")
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        // Allow navigation within the same domain
        if url.host?.contains("eiffageconcessionssenegal.sn") == true {
            decisionHandler(.allow)
            return
        }
        
        // Handle external links
        if navigationAction.navigationType == .linkActivated {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle target="_blank" links
        if navigationAction.targetFrame == nil {
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
        }
        return nil
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