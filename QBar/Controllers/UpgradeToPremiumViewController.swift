//
//  UpgradeToPremiumViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/4/21.
//

import UIKit

protocol UpgradeFromRecentsDelegate: class {
    func dismissFromUpgrade()
    func purchased(purchases: [ProductID])
}

class UpgradeToPremiumViewController: UIViewController {
    
    // MARK: - IBOutlets
//    @IBOutlet weak var upgradeLabel: UILabel!
//    @IBOutlet weak var enjoyLabel: UILabel!
    @IBOutlet weak var startFreeLabel: UILabel!
    @IBOutlet weak var thenLabel: UILabel!
//    @IBOutlet weak var proceedWithBasicButton: UIButton!
    @IBOutlet weak var tryFreeButton: UIButton!
//    @IBOutlet weak var startMonthlyView: UIView!
//    @IBOutlet weak var startYearlyButton: UIButton!
//    @IBOutlet weak var priceAYearButton: UIButton!
    @IBOutlet weak var trialLabel: UILabel!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var eulaButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var videoView: VideoView!
    
    // MARK: - Properties
    let service = Service()
    var productIDs: Set<ProductID> = []
    var subscriptions: Subscriptions = Subscriptions()
    
    weak var delegate: UpgradeFromRecentsDelegate?
    
    // MARK: - Override properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            // Fallback on earlier versions
            return .default
        }
    }
    
    // MARK: - View LyfeCicle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// Configuring Video Preview
        videoView.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        /// Configuring Video Preview
        videoView.stop()
    }
    
    // MARK: - Private Functions
    private func configureView() {
//        proceedWithBasicButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
        tryFreeButton.cornerRadius(to: 20)
        privacyButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
        eulaButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
//        startMonthlyView.cornerRadius(to: 20)
//        startMonthlyView.addBorder(width: 2.0, color: .mainBlack)
        
        service.getOnboardingTitles(for: PremiumTab.Onboarding.rawValue) { (onboarding, error) in
            if let error = error {
                ErrorHandling.showError(message: error.localizedDescription, controller: self)
                self.configureSubscribeTitles(for: OnboardingTitle(), subscriptions: self.subscriptions)
                return
            }
            if let onboarding = onboarding {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.configureSubscribeTitles(for: onboarding, subscriptions: self.subscriptions)
                }
            }
        }
        /// Configuring Video Preview
        videoView.configure(resource: "video2")
        videoView.isLoop = true
    }
    
    private func configureSubscribeTitles(for onboarding: OnboardingTitle, subscriptions: Subscriptions) {
        if allPrices.count > 0 {
            for (title, price) in allPrices {
                if title.contains("Monthly") {
                    self.thenLabel.text = "\(onboarding.fourthTitle) \(price) a month"
                } else if title.contains("Yearly") {
//                    self.priceAYearButton.setTitle("\(price) \(onboarding.startYearlySecondTitle)", for: UIControl.State())
                }
            }
        } else {
            self.thenLabel.text = "\(onboarding.fourthTitle) $7.99 a month"
//            self.priceAYearButton.setTitle("$32.99 \(onboarding.startYearlySecondTitle)", for: UIControl.State())
        }
        
        self.closeButton.isHidden = !onboarding.closeButton
        self.closeButton.isEnabled = onboarding.closeButton
//        self.proceedWithBasicButton.isHidden = onboarding.proceedIsHidden
//        self.proceedWithBasicButton.isEnabled = !onboarding.proceedIsHidden
//        self.upgradeLabel.text = onboarding.firstTitle
//        self.enjoyLabel.text = onboarding.secondTitle
        self.startFreeLabel.text = onboarding.thirdTitle
//        self.proceedWithBasicButton.setTitle(onboarding.basicTitle, for: UIControl.State())
        self.tryFreeButton.setTitle(onboarding.tryFreeTitle, for: UIControl.State())
//        self.startYearlyButton.setTitle(onboarding.startYearlyFirstTitle, for: UIControl.State())
        self.trialLabel.text = onboarding.privacyEulaTitle
        
        self.thenLabel.isHidden = onboarding.fourthTitleIsHidden
//        self.priceAYearButton.isHidden = onboarding.startYearlySecondTitleIsHIdden
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
                    /// Firebase Analytics
                    QRAnalytics.shared.purchaseAnalytics(userID: User.currentUser?.uid ?? "", paymentType: purchase.product.localizedTitle, totalPrice: purchase.product.localizedPrice ?? "", success: "1", currency: purchase.product.priceLocale.currencySymbol ?? "USD")
                    self.dismiss(animated: true, completion: nil)
                    self.delegate?.purchased(purchases: [purchase.productId])
                })
            case .error(let error):
                self.hideAnimatedActivityIndicatorView()
                ErrorHandling.showError(title: "Purchase failed", message: error.localizedDescription, controller: self)
                /// Firebase Analytics
                QRAnalytics.shared.purchaseAnalytics(userID: User.currentUser?.uid ?? "", paymentType: error.localizedDescription, totalPrice: "", success: "0", currency: "USD")
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
    
//    // MARK: - IBActions
//    @IBAction func proceedWithBasicTapped(_ sender: Any) {
////        NotificationCenter.default.post(name: dismissNotification, object: nil)
//        dismiss(animated: true, completion: nil)
//        self.delegate?.dismissFromUpgrade()
//    }
    
    @IBAction func tryFreeTapped(_ sender: Any) {
//        purchase(index: 1)
        print("Try free tapped")
        QRAnalytics.shared.tappedToSubscribeButton(userID: User.currentUser?.uid ?? "", button: "Try Free Button")
        if service.isConnectedToInternet {
            for productID in productIDs {
                if productID.contains("month") {
                    purchaseItem(productID: productID)
                }
            }
        } else {
            ErrorHandling.showError(message: "Check Internet Connection and try again.", controller: self)
        }
    }
    
//    @IBAction func startYearlyTapped(_ sender: Any) {
//        print("Start Yearly Tapped")
//        QRAnalytics.shared.tappedToSubscribeButton(userID: User.currentUser?.uid ?? "", button: "Start Yearly Button")
//        if service.isConnectedToInternet {
//            for productID in productIDs {
//                if productID.contains("year") {
//                    purchaseItem(productID: productID)
//                }
//            }
//        } else {
//            ErrorHandling.showError(message: "Check Internet Connection and try again.", controller: self)
//        }
//    }
    
    @IBAction func startMonthlyTapped(_ sender: Any) {
//        purchase(index: 0)
        print("Start Monthly Tapped")
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
//        NotificationCenter.default.post(name: dismissNotification, object: nil)
        dismiss(animated: true, completion: nil)
        self.delegate?.dismissFromUpgrade()
    }
    
    @IBAction func privacyTapped(_ sender: Any) {
        openURL(path: kPolicyURL)
    }
    
    @IBAction func eulaTapped(_ sender: Any) {
        openURL(path: kTermsURL)
    }
}
