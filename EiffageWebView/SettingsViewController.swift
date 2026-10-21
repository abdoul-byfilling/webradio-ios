import UIKit
import WebKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let sections = ["Cache", "À propos"]
    private let cacheOptions = ["Nettoyer le cache", "Nettoyer les cookies"]
    private let aboutOptions = ["Version de l'app", "Site web"]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Paramètres"
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        
        // Table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
    }
    
    // MARK: - Actions
    @objc private func dismissSettings() {
        dismiss(animated: true)
    }
    
    private func clearCache() {
        let alert = UIAlertController(
            title: "Nettoyer le cache",
            message: "Êtes-vous sûr de vouloir supprimer toutes les données en cache ?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        alert.addAction(UIAlertAction(title: "Nettoyer", style: .destructive) { _ in
            self.performCacheClear()
        })
        
        present(alert, animated: true)
    }
    
    private func clearCookies() {
        let alert = UIAlertController(
            title: "Nettoyer les cookies",
            message: "Êtes-vous sûr de vouloir supprimer tous les cookies ?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        alert.addAction(UIAlertAction(title: "Nettoyer", style: .destructive) { _ in
            self.performCookiesClear()
        })
        
        present(alert, animated: true)
    }
    
    private func performCacheClear() {
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)
        
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date) {
            DispatchQueue.main.async {
                self.showSuccessAlert("Cache nettoyé avec succès")
            }
        }
    }
    
    private func performCookiesClear() {
        let websiteDataTypes = Set([WKWebsiteDataTypeCookies])
        let date = Date(timeIntervalSince1970: 0)
        
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date) {
            DispatchQueue.main.async {
                self.showSuccessAlert("Cookies supprimés avec succès")
            }
        }
    }
    
    private func showSuccessAlert(_ message: String) {
        let alert = UIAlertController(title: "Succès", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func openWebsite() {
        if let url = URL(string: "https://www.eiffageconcessionssenegal.sn") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return cacheOptions.count
        case 1: return aboutOptions.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = cacheOptions[indexPath.row]
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = UIColor.systemRed
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            cell.textLabel?.text = aboutOptions[indexPath.row]
            
            if indexPath.row == 0 {
                // Version de l'app
                cell.detailTextLabel?.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                cell.accessoryType = .none
            } else {
                // Site web
                cell.accessoryType = .disclosureIndicator
            }
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            // Cache section
            if indexPath.row == 0 {
                clearCache()
            } else if indexPath.row == 1 {
                clearCookies()
            }
            
        case 1:
            // About section
            if indexPath.row == 1 {
                openWebsite()
            }
            
        default:
            break
        }
    }
}