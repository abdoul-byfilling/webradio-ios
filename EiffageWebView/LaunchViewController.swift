import UIKit

class LaunchViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var gradientBackgroundView: UIView!
    @IBOutlet weak var logoContainer: UIView!
    @IBOutlet weak var appIconImageView: UIImageView!
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupLogoContainer()
        setupAppIcon()
        setupInitialState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = gradientBackgroundView.bounds
    }
    
    // MARK: - Setup Methods
    private func setupGradientBackground() {
        gradientLayer = CAGradientLayer()
        
        // Couleurs pastel dégradées
        let topColor = UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0).cgColor      // Bleu très clair
        let middleColor = UIColor(red: 0.98, green: 0.95, blue: 1.0, alpha: 1.0).cgColor  // Lavande très clair
        let bottomColor = UIColor(red: 1.0, green: 0.97, blue: 0.95, alpha: 1.0).cgColor  // Pêche très clair
        
        gradientLayer.colors = [topColor, middleColor, bottomColor]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        gradientBackgroundView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupLogoContainer() {
        // Style du conteneur logo avec ombre
        logoContainer.layer.cornerRadius = 20
        logoContainer.layer.shadowColor = UIColor.black.cgColor
        logoContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        logoContainer.layer.shadowRadius = 20
        logoContainer.layer.shadowOpacity = 0.1
        
        // Effet de glassmorphism subtil
        logoContainer.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        logoContainer.layer.borderWidth = 1
        logoContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
    }
    
    private func setupAppIcon() {
        // Récupérer l'icône de l'application
        if let appIcon = getAppIcon() {
            appIconImageView.image = appIcon
        } else {
            // Fallback vers une icône système si l'icône de l'app n'est pas trouvée
            appIconImageView.image = UIImage(systemName: "building.2")
            appIconImageView.tintColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        }
        
        // Style de l'image
        appIconImageView.contentMode = .scaleAspectFit
        appIconImageView.layer.cornerRadius = 16
        appIconImageView.clipsToBounds = true
        
        // Ombre subtile pour l'icône
        appIconImageView.layer.shadowColor = UIColor.black.cgColor
        appIconImageView.layer.shadowOffset = CGSize(width: 0, y: 2)
        appIconImageView.layer.shadowRadius = 4
        appIconImageView.layer.shadowOpacity = 0.1
        appIconImageView.layer.masksToBounds = false
    }
    
    private func getAppIcon() -> UIImage? {
        // Essayer de récupérer l'icône de l'application depuis le bundle
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String] else {
            return nil
        }
        
        // Chercher la meilleure taille d'icône disponible
        let preferredSizes = ["60x60@3x", "60x60@2x", "40x40@3x", "40x40@2x", "29x29@3x", "29x29@2x"]
        
        for size in preferredSizes {
            for iconFile in iconFiles {
                let iconName = "\(iconFile)\(size)"
                if let icon = UIImage(named: iconName) {
                    return icon
                }
            }
        }
        
        // Essayer sans suffixe de taille
        for iconFile in iconFiles {
            if let icon = UIImage(named: iconFile) {
                return icon
            }
        }
        
        // Dernière tentative avec les noms d'icônes courants
        let commonIconNames = ["AppIcon60x60", "AppIcon", "Icon-60", "Icon"]
        for iconName in commonIconNames {
            if let icon = UIImage(named: iconName) {
                return icon
            }
        }
        
        return nil
    }
    
    private func setupInitialState() {
        // État initial pour l'animation
        mainContainer.alpha = 0
        mainContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        companyLabel.alpha = 0
        companyLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        
        subtitleLabel.alpha = 0
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Animation du conteneur principal
        UIView.animate(withDuration: 1.2, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut], animations: {
            self.mainContainer.alpha = 1
            self.mainContainer.transform = .identity
        })
        
        // Animation du logo avec effet de pulsation
        UIView.animate(withDuration: 0.8, delay: 0.6, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [.curveEaseOut], animations: {
            self.logoContainer.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
                self.logoContainer.transform = .identity
            })
        }
        
        // Animation spéciale pour l'icône de l'app
        UIView.animate(withDuration: 0.6, delay: 0.8, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseOut], animations: {
            self.appIconImageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
                self.appIconImageView.transform = .identity
            })
        }
        
        // Animation du texte principal
        UIView.animate(withDuration: 0.8, delay: 0.9, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
            self.companyLabel.alpha = 1
            self.companyLabel.transform = .identity
        })
        
        // Animation du sous-titre
        UIView.animate(withDuration: 0.8, delay: 1.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
            self.subtitleLabel.alpha = 1
            self.subtitleLabel.transform = .identity
        })
        
        // Animation continue du dégradé
        startGradientAnimation()
        
        // Animation de pulsation subtile continue
        startContinuousPulse()
    }
    
    private func startGradientAnimation() {
        let animation = CABasicAnimation(keyPath: "colors")
        
        let colors1 = [
            UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.98, green: 0.95, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.97, blue: 0.95, alpha: 1.0).cgColor
        ]
        
        let colors2 = [
            UIColor(red: 0.97, green: 0.95, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.97, blue: 0.98, alpha: 1.0).cgColor,
            UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1.0).cgColor
        ]
        
        animation.fromValue = colors1
        animation.toValue = colors2
        animation.duration = 4.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.add(animation, forKey: "gradientAnimation")
    }
    
    private func startContinuousPulse() {
        UIView.animate(withDuration: 2.0, delay: 2.0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.logoContainer.layer.shadowOpacity = 0.2
            self.logoContainer.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        })
    }
}