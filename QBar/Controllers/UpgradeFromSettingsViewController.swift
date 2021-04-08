//
//  UpgradeFromSettingsViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/6/21.
//

import UIKit
//import StoreKit

protocol UpgradeFromSettingsDelegate: class {
    func dismissFromUpgrade()
    func purchased(purchases: [ProductID])
}

class UpgradeFromSettingsViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var upgradeView: UIView!
    @IBOutlet weak var premiumLabel: UILabel!
    @IBOutlet weak var enjoyLabel: UILabel!
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var annualLabel1: UILabel!
    @IBOutlet weak var annualLabel2: UILabel!
    @IBOutlet weak var monthlyLabel1: UILabel!
    @IBOutlet weak var monthlyLabel2: UILabel!
    @IBOutlet weak var weeklyLabel1: UILabel!
    @IBOutlet weak var weeklyLabel2: UILabel!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeButton: UIButton!
    
    // MARK: - Properties
    let service = Service()
//    var products: [SKProduct] = []
    var productIDs: Set<ProductID> = []
    var monthlyPrice: String = "$7.99"
    var annualPrice: String = "$32.99"
    var weeklyPrice: String = "$2.49"
    var subscriptions: Subscriptions = Subscriptions()
//    var store: IAPManager!
//    var typeIndex = 2
    
    var tapped: (annual: Bool, monthly: Bool, weekly: Bool) = (true, false, false)
    weak var delegate: UpgradeFromSettingsDelegate?
    
    // MARK: - View LyfeCicle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    // MARK: - Functions
    private func configureView() {
        imageView.cornerRadius(to: 24)
        upgradeView.cornerRadius(to: 16)
        upgradeButton.cornerRadius(to: 20)
        
        tapped.annual = true
        tapped.weekly = false
        tapped.monthly = false
        
        if screenHeight == 780 {
            imageHeightConstraint.constant = 530
        } else if screenHeight >= 812 {
            imageHeightConstraint.constant = 580
        } else if screenHeight >= 844 {
            imageHeightConstraint.constant = 600
        } else {
            imageHeightConstraint.constant = 480
        }
        
//        print(products)
        
        service.getSubscribeTitles(for: PremiumTab.Subscribe.rawValue) { (subscribe, error) in
            if let error = error {
                ErrorHandling.showError(message: error.localizedDescription, controller: self)
                DispatchQueue.main.async {
                    self.configureSubscribeTitles(subscribe: SubscribeTitle(), subscriptions: self.subscriptions)
                }
                return
            }
            if let subscribe = subscribe {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.configureSubscribeTitles(subscribe: subscribe, subscriptions: self.subscriptions)
                }
            }
        }
    }
    
    private func configureSubscribeTitles(subscribe: SubscribeTitle, subscriptions: Subscriptions) {
        self.closeButton.isHidden = !subscribe.closeButton
        self.closeButton.isEnabled = subscribe.closeButton
        self.premiumLabel.text = subscribe.firstTitle
        self.enjoyLabel.text = subscribe.secondTitle
        self.annualLabel1.text = subscribe.annualFirstTitle
//        self.annualLabel2.text = "\(subscribe.annualSecondTitle) $\(subscriptions.annualProductPrice)/year"
        self.annualLabel2.text = "\(subscribe.annualSecondTitle) \(annualPrice)/year"
        self.monthlyLabel1.text = subscribe.monthlyFirstTitle
//        self.monthlyLabel2.text = "\(subscribe.monthlySecondTitle) $\(subscriptions.monthlyProductPrice)/month"
        self.monthlyLabel2.text = "\(subscribe.monthlySecondTitle) \(monthlyPrice)/month"
        self.weeklyLabel1.text = subscribe.weeklyFirstTitle
//        self.weeklyLabel2.text = "\(subscribe.weeklySecondTitle) $\(subscriptions.weeklyProductPrice)/week"
        self.weeklyLabel2.text = "\(subscribe.weeklySecondTitle) \(weeklyPrice)/week"
    }
    
    /// Purchasing product
    private func purchaseItem(productID: String) {
        displayAnimatedActivityIndicatorView()
        StoreKit.shared.purchase(productID, atomically: true) { (result) in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
                StoreKit.shared.finishPurchasing(purchase: purchase)
                self.hideAnimatedActivityIndicatorView()
                purchasedAny = true
                self.alert(title: "Purchase Success", message: "\(purchase.product.localizedTitle), \(purchase.product.localizedPrice ?? "")", preferredStyle: .alert, cancelTitle: nil, cancelHandler: nil, actionTitle: "OK", actionHandler: {
                    self.dismiss(animated: true, completion: nil)
                    self.delegate?.purchased(purchases: [purchase.productId])
                })
            case .error(let error):
                self.hideAnimatedActivityIndicatorView()
                ErrorHandling.showError(title: "Purchase failed", message: error.localizedDescription, controller: self)
                print("Purchase Failed: \(error)")
                switch error.code {
                case .unknown:
                    print("Purchase failed, \(error.localizedDescription)")
                case .clientInvalid: // client is not allowed to issue the request, etc.
                    print("Purchase failed, Not allowed to make the payment")
                case .paymentCancelled: // user cancelled the request, etc.
                    break
                case .paymentInvalid: // purchase identifier was invalid, etc.
                    print("Purchase failed, The purchase identifier was invalid")
                case .paymentNotAllowed: // this device is not allowed to make the payment
                    print("Purchase failed, The device is not allowed to make the payment")
                case .storeProductNotAvailable: // Product is not available in the current storefront
                    print("Purchase failed, The product is not available in the current storefront")
                case .cloudServicePermissionDenied: // user has not allowed access to cloud service information
                    print("Purchase failed, Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: // the device could not connect to the nework
                    print("Purchase failed, Could not connect to the network")
                case .cloudServiceRevoked: // user has revoked permission to use this cloud service
                    print("Purchase failed, Cloud service was revoked")
                default:
                    print("Purchase failed, \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Trying to restore purchases
    private func restorePurchases() {
        displayAnimatedActivityIndicatorView()
        StoreKit.shared.restorePurchases { (results) in
            StoreKit.shared.finishingRestoring(restoreResults: results)
            if results.restoreFailedPurchases.count > 0 {
                self.hideAnimatedActivityIndicatorView()
                ErrorHandling.showError(title: "Restore Failed", message: "Please check Internet Connectivity and try again or Contact Support", controller: self)
                print("Restore Failed: \(results.restoreFailedPurchases), Please contact support")
            } else if results.restoredPurchases.count > 0 {
                self.hideAnimatedActivityIndicatorView()
                purchasedAny = true
                self.alert(title: "Restored Successfully", message: nil, preferredStyle: .alert, cancelTitle: nil, cancelHandler: nil, actionTitle: "OK", actionHandler: {
                    self.dismiss(animated: true, completion: nil)
                    self.delegate?.purchased(purchases: results.restoredPurchases.compactMap{$0.productId})
                })
                print("Restore Success: \(results.restoredPurchases), All purchases have been restored")
            } else {
                print("Nothing to Restore, No previous purchases were found")
                self.hideAnimatedActivityIndicatorView()
                ErrorHandling.showError(title: "Nothing to Restore", message: "No previous purchases were found", controller: self)
            }
        }
    }
    
    // MARK: - Upgrading product
//    private func upgradeProduct(index: Int) {
//        print(products)
//        displayAnimatedActivityIndicatorView()
//        guard !products.isEmpty else {
//            self.hideAnimatedActivityIndicatorView()
//            print("Cannot purchase subscription because products is empty!")
//            return
//        }
//        self.store.buyProduct(products[index]) { [weak self] success, productId in
//            guard let self = self else { return }
//            guard success else {
//                self.hideAnimatedActivityIndicatorView()
//                DispatchQueue.main.async {
//                    self.alert(title: "Failed to purchase product", message: "Check logs for details", preferredStyle: .alert, actionTitle: "OK")
//                }
//                return
//            }
//            print("Purchased")
//            DispatchQueue.main.async {
//                self.hideAnimatedActivityIndicatorView()
//                NotificationCenter.default.post(name: hideSettingsUpgradeNotification, object: nil)
//                self.dismiss(animated: true)
//            }
//        }
//    }
    
    // MARK: - Setting images for buttons
    private func setImagesForButton(tags: [Int]) {
        for i in 1...2 {
            stackView.subviews.forEach { (view) in
                if let button = view.viewWithTag(tags[i]) as? UIButton {
                    button.setImage(nil, for: .normal)
                    button.setBackgroundImage(imageNamed("premiumButtonBackground"), for: .normal)
                }
            }
        }
        stackView.subviews.forEach { (view) in
            if let button = view.viewWithTag(tags[0]) as? UIButton {
                button.setImage(imageNamed("premiumButtonChecked"), for: .normal)
                button.setBackgroundImage(imageNamed("premiumButtonBackgroundBlue"), for: .normal)
            }
        }
    }
    
    // MARK: - IBActions
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        self.delegate?.dismissFromUpgrade()
    }
    
    @IBAction func annualTapped(_ sender: Any) {
//        typeIndex = 2
        setImagesForButton(tags: [100, 110, 120])
        tapped.annual = true
        tapped.monthly = false
        tapped.weekly = false
    }
    
    @IBAction func monthlyTapped(_ sender: Any) {
//        typeIndex = 0
        setImagesForButton(tags: [110, 100, 120])
        tapped.annual = false
        tapped.monthly = true
        tapped.weekly = false
    }
    
    @IBAction func weeklyTapped(_ sender: Any) {
//        typeIndex = 1
        setImagesForButton(tags: [120, 100, 110])
        tapped.annual = false
        tapped.monthly = false
        tapped.weekly = true
    }
    
    @IBAction func upgradeTapped(_ sender: Any) {
//        upgradeProduct(index: typeIndex)
        print("Upgrade tapped")
        print(tapped)
        if service.isConnectedToInternet {
            for productID in productIDs {
                if productID.contains("week") && tapped.weekly {
                    purchaseItem(productID: productID)
                } else if productID.contains("month") && tapped.monthly {
                    purchaseItem(productID: productID)
                } else if productID.contains("year") && tapped.annual {
                    purchaseItem(productID: productID)
                }
            }
        } else {
            ErrorHandling.showError(message: "Check Internet Connection and try again.", controller: self)
        }
    }
    
    @IBAction func termsTapped(_ sender: Any) {
        openURL(path: kTermsURL)
    }
    
    @IBAction func privacyTapped(_ sender: Any) {
        openURL(path: kPolicyURL)
    }
    
    @IBAction func restoreTapped(_ sender: Any) {
        print("Restore tapped")
        restorePurchases()
//        displayAnimatedActivityIndicatorView()
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.store.restorePurchases { (succes, productID) in
//                DispatchQueue.main.async {
//                    guard succes else { return }
//                    self.hideAnimatedActivityIndicatorView()
//                    self.dismiss(animated: true, completion: nil)
//                }
//            }
//        }
    }
}
