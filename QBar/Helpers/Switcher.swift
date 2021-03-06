//
//  Switcher.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/26/21.
//

import UIKit

let kStatus = "status"
let kOnboardingStatus = "onboardingStatus"
let kCameraStatus = "cameraStatus"

let launchRemovedNotification: Notification.Name = Notification.Name("LaunchRemoved")

class Switcher: NSObject {
    // MARK: - Properties
    /// Shared Singleton
    static let shared = Switcher()
    
    /// RootVC
    var rootVC: UIViewController?
    
    /// In-App Purchase Helper
    var storeKit: StoreKit!
    
    /// LaunchView
    lazy var launchView: UIView = {
        let views = Bundle.main.loadNibNamed("LaunchView", owner: nil, options: nil)
        let launch = views![0] as! UIView
        launch.translatesAutoresizingMaskIntoConstraints = false
        return launch
    }()
    
    // MARK: - Init
    override init() {
        super.init()
        storeKit = StoreKit.shared
    }

    // MARK: - Deinit
    deinit {}
    
    // MARK: - Functions
    func showLaunchView(rootVC: UIViewController?) {
        rootVC?.view.addSubview(launchView)
        rootVC?.view.pinAllEdges(to: launchView)
    }
    
    func removeLaunchView(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.5 : 0, animations: {
            self.launchView.alpha = 0
        }, completion: { (completion) in
            self.launchView.removeFromSuperview()
        })
    }
    
    @objc func removeLaunch() {
        DispatchQueue.main.after(0.1) { [weak self] in
            guard let self = self else { return }
            self.removeLaunchView(animated: true)
            if self.rootVC is MainSegmentedViewController {
                self.rootVC?.hideAnimatedActivityIndicatorView()
            }
            DispatchQueue.main.after(0.1) {
                NotificationCenter.default.post(name: launchRemovedNotification, object: nil)
            }
        }
    }
    
    // MARK: - Checking User
    private func checkUser() {
        Service().checkUser { (user, error) in
            if let user = user, error == nil {
                print(user)
                User.currentUser = user
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    // MARK: - Updating Root VC
    func updateRootVC(showLaunch: Bool = true) {
        /// Status for checking if the app was launched first
        let status = UserDefaults.standard.bool(forKey: kStatus)
        
        checkUser()
        
        if status == true {
            rootVC = MainSegmentedViewController.instantiate(from: .Main, with: MainSegmentedViewController.typeName)
            rootVC?.displayAnimatedActivityIndicatorView()
        } else {
            rootVC = PrivacyViewController.instantiate(from: .Onboarding, with: PrivacyViewController.typeName)
        }
        
        /// If flagged show launchView
        if showLaunch {
            showLaunchView(rootVC: rootVC)
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = rootVC
        appDelegate.window?.backgroundColor = .mainWhite
        appDelegate.window?.makeKeyAndVisible()
        
        getInfoAndVerify()
    }
    
    // MARK: - In-App Getting Info and Verifying
    /// Getting Info about products
    private func getInfoAndVerify() {
        storeKit.getInfo { (productIDs, result, error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    ErrorHandling.showError(message: error.localizedDescription, controller: self.rootVC!)
                    self.removeLaunch()
                }
                return
            }
            
            /// Trying to verify subscriptions
            if let productIDs = productIDs {
                allProductIDs = productIDs
                self.verifySubscriptions(productIDs)
            } else {
                self.removeLaunch()
                print("It should not be here")
            }
            
            if let products = result?.retrievedProducts {
                allProducts = products
                for product in products {
                    if let priceString = product.localizedPrice {
                        allPrices[product.localizedTitle] = priceString
                        print("\(product.localizedTitle), \(product.localizedDescription) - \(priceString)")
                    }
                }
            } else if let invalidProductIds = result?.invalidProductIDs {
                for invalidProductId in invalidProductIds {
                    print("Could not retrieve product info, Invalid product identifier: \(invalidProductId)")
                }
            } else {
                let errorString = result?.error?.localizedDescription ?? "Unknown error. Please contact support"
                print("Could not retrieve product info - \(errorString)")
            }
        }
    }
    
    // MARK: - Verify
    /// Verifying Subscriptions
    private func verifySubscriptions(_ purchases: Set<ProductID>) {
        storeKit.verifySubscriptions(purchases) { (purchaseResult, productIds, verifyReceiptResult) in
            DispatchQueue.main.async {
                if let verifyReceiptResult = verifyReceiptResult {
                    self.removeLaunch()
                    switch verifyReceiptResult {
                    case .success(let receipt):
                        print("Verify receipt Success: \(receipt)")
                    case .error(let error):
                        print("Verify receipt Failed: \(error)")
                        switch error {
                        case .noReceiptData:
                            print("Receipt verification, No receipt data. Try again.")
                        case .networkError(let error):
                            print("Receipt verification, Network error while verifying receipt: \(error)")
                        default:
                            print("Receipt verification, Receipt verification failed: \(error)")
                        }
                    }
                }
                if let purchaseResult = purchaseResult, let productIds = productIds {
                    self.removeLaunch()
                    switch purchaseResult {
                    case .purchased(let expiryDate, let items):
                        print("\(productIds) is valid until \(expiryDate)\n\(items)\n")
                        purchasedAny = true
                    case .expired(let expiryDate, let items):
                        print("\(productIds) is expired since \(expiryDate)\n\(items)\n")
                    case .notPurchased:
                        print("\(productIds) has never been purchased")
                    }
                }
            }
        }
    }
}
