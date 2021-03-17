//
//  MainSegmentedViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit
import FirebaseDatabase
import StoreKit
import SwiftyStoreKit

class MainSegmentedViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    // MARK: - Properties
    private lazy var recentsVC: RecentsViewController = {
        let vc = RecentsViewController.instantiate(from: .Main, with: RecentsViewController.typeName)
        return vc
    }()
    
    private lazy var scanVC: QRBarcodeScannerViewController = {
        let vc = QRBarcodeScannerViewController()
        vc.codeDelegate = self
        vc.errorDelegate = self
        vc.dismissalDelegate = self
        return vc
    }()
    
    private lazy var settingsVC: SettingsViewController = {
        let vc = SettingsViewController.instantiate(from: .Main, with: SettingsViewController.typeName)
        return vc
    }()
    
    private lazy var onBoardingVC: OnboardingViewController = {
        let vc = OnboardingViewController.instantiate(from: .Onboarding, with: OnboardingViewController.typeName)
        return vc
    }()
    
    var user: User!
    var service: Service!
    var products: [SKProduct] = []
    var store: IAPManager!
    var subscriptions: Subscriptions!
    
    var cancelled = false
    
    lazy var code: Code = {
        let code = Code()
        return code
    }()
    
    // MARK: - Override properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            // Fallback on earlier versions
            return .default
        }
    }
    
    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(notifiedToSetIndex), name: dismissNotification, object: nil)
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Functions
    private func configureView() {
        service = Service()
        
        let segmentsSize = CGSize(width: 18, height: 18)
        let images: [UIImage] = [UIImage(named: "recentsIcon")!, UIImage(named: "qrBarIcon")!, UIImage(named: "settingsIcon")!]
        let segments = IconSegment.segments(withIcons: images, iconSize: segmentsSize, normalBackgroundColor: .mainBlack, normalIconTintColor: .mainWhite, selectedBackgroundColor: .mainBlue, selectedIconTintColor: .mainWhite)
        
        segmentedControl.segments = segments
        segmentedControl.setIndex(1)
        segmentedControl.addTarget(self, action: #selector(selectionDidChange(_:)), for: .valueChanged)
        
        getSubscriptions()
        
        checkUser()
    }
    
    private func presentOnboarding() {
        if UserDefaults.standard.bool(forKey: kOnboardingStatus) != true {
            onBoardingVC.modalPresentationStyle = .fullScreen
            onBoardingVC.store = self.store
            if presentedViewController != onBoardingVC {
                self.present(onBoardingVC, animated: true) {
                    UserDefaults.standard.set(true, forKey: kOnboardingStatus)
                }
            }
        }
    }
    
    private func getSubscriptions() {
        displayAnimatedActivityIndicatorView()
        DispatchQueue.global(qos: .userInitiated).async {
            self.service.getSubscriptions { (purchases, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self.hideAnimatedActivityIndicatorView()
                        ErrorHandling.showError(message: error.localizedDescription, controller: self)
                        return
                    }
                    if let purchases = purchases {
                        self.hideAnimatedActivityIndicatorView()
                        let store = IAPManager(productIDs: purchases)
                        self.store = store
                        self.requestProducts(store: store, productIDs: purchases)
                        self.checkProducts(store: store, productIDs: purchases)
                    }
                }
            }
        }
    }
    
    private func checkProducts(store: IAPManager, productIDs: Set<ProductID>) {
        DispatchQueue.global(qos: .userInitiated).async {
            if store.isProductPurchased(productIDs[productIDs.startIndex]) || store.isProductPurchased(productIDs[productIDs.index(productIDs.startIndex, offsetBy: 1)]) || store.isProductPurchased(productIDs[productIDs.index(productIDs.startIndex, offsetBy: 2)]){
                DispatchQueue.main.async {
                    self.segmentedControl.setIndex(0)
                    self.updateView()
                }
            } else {
                DispatchQueue.main.async {
                    self.segmentedControl.setIndex(1)
                    self.presentOnboarding()
                    self.updateView()
                }
            }
        }
    }
    
    private func requestProducts(store: IAPManager, productIDs: Set<ProductID>) {
        displayAnimatedActivityIndicatorView()
        DispatchQueue.global(qos: .userInitiated).async {
            store.requestProducts { [weak self](success, products) in
                guard let self = self else { return }
                guard success else {
                    self.hideAnimatedActivityIndicatorView()
                    DispatchQueue.main.async {
                        self.alert(title: "Failed to load list of products", message: "Check logs for details", preferredStyle: .alert, actionTitle: "OK")
                    }
                    return
                }
                if let products = products {
                    DispatchQueue.main.async {
                        self.addPrice(from: products)
                        self.hideAnimatedActivityIndicatorView()
                        print(products as Any)
                        self.products = products
                        self.onBoardingVC.products = products
                        print("Product ids are = \(productIDs)")
                        self.checkProducts(store: store, productIDs: productIDs)
                    }
                }
            }
        }
    }
    
    private func addPrice(from products: [SKProduct]) {
        let annualProductID = products[2].productIdentifier
        let annualProductPrice = products[2].price.floatValue
        let monthlyProductID = products[0].productIdentifier
        let monthlyProductPrice = products[0].price.floatValue
        let weeklyProductID = products[1].productIdentifier
        let weeklyProductPrice = products[1].price.floatValue
        let subscriptions = Subscriptions(annualProductID: annualProductID, annualProductPrice: Double(annualProductPrice).rounded(toPlaces: 2), monthlyProductID: monthlyProductID, monthlyProductPrice: Double(monthlyProductPrice).rounded(toPlaces: 2), weeklyProductID: weeklyProductID, weeklyProductPrice: Double(weeklyProductPrice).rounded(toPlaces: 2))
        DispatchQueue.global(qos: .userInitiated).async {
            self.service.addPrice(for: subscriptions) { (childUpdates, error) in
                DispatchQueue.main.async {
                    if error == nil {
                        print("Succeeded")
                        self.onBoardingVC.subscriptions = subscriptions
                        self.recentsVC.subscriptions = subscriptions
                        self.settingsVC.subscriptions = subscriptions
                    }
                }
            }
        }
    }
    
    private func checkUser() {
        service.checkUser { (user, error) in
            if let user = user, error == nil {
                self.user = user
            } else {
                self.user = nil
                print(error!.localizedDescription)
            }
        }
    }
    
    private func updateView() {
        print("Updated")
        switch segmentedControl.index {
        case 0:
            removeAllChildren()
            addChild(controller: recentsVC)
        case 1:
            removeAllChildren()
            addChild(controller: scanVC)
        case 2:
            removeAllChildren()
            addChild(controller: settingsVC)
        default:
        break
        }
    }
    
    private func addNewCode(_ controller: QRBarcodeScannerViewController, code: String, type: String) {
        print("Data: \(code)")
        print("Symbology Type: \(type)")
        
        self.code.title = code
        self.code.code = code
        self.code.type = type
        self.code.tab = Tab.History.rawValue
        self.code.userID = user.uid
        self.code.date = Date().dateTimeString()
        
        if type.contains("QR") {
            print("Type on Mainsegmentec controller = \(type)")
            self.code.imageName = "qrCodeImage"
        } else {
            self.code.imageName = "barCodeImage"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            controller.reset(animated: true)
            if !self.cancelled {
                self.service.addNewCode(code: self.code, at: self.code.tab) { [weak self](childUpdates, error) in
                    guard let self = self else { return }
                    DispatchQueue.main.after(0.5) {
                        self.segmentedControl.setIndex(0)
                        self.updateView()
                    }
                    if let error = error {
                        ErrorHandling.showError(message: error.localizedDescription, controller: self)
                        return
                    }
                }
            } else {
                self.cancelled = false
            }
        }
    }
    
    // MARK: - OBJC Functions
    @objc private func notifiedToSetIndex() {
        segmentedControl.setIndex(1)
        self.updateView()
    }
    
    // MARK: - OBJC Functions
    @objc func selectionDidChange(_ sender: SegmentedControl) {
        self.updateView()
    }
}

// MARK: - QRBarcodeScannerCodeDelegate
extension MainSegmentedViewController: QRBarcodeScannerCodeDelegate {
    func scanner(_ controller: QRBarcodeScannerViewController, didNotFind result: String) {
        DispatchQueue.main.after(2) {
            controller.resetWithError(message: result)
        }
    }
    
    func scanner(_ controller: QRBarcodeScannerViewController, didCaptureCode code: String, type: String) {
        addNewCode(controller, code: code, type: type)
    }
}

// MARK: - QRBarcodeScannerErrorDelegate
extension MainSegmentedViewController: QRBarcodeScannerErrorDelegate {
    func scanner(_ controller: QRBarcodeScannerViewController, didReceiveError error: Error) {
        print(error.localizedDescription)
        DispatchQueue.main.after(2) {
            controller.resetWithError(message: error.localizedDescription)
        }
    }
}

// MARK: - QRBarcodeScannerDismissalDelegate
extension MainSegmentedViewController: QRBarcodeScannerDismissalDelegate {
    func scannerDidDismiss(_ controller: QRBarcodeScannerViewController) {
        controller.reset(animated: true)
        cancelled = true
        DispatchQueue.main.after(0.5) {
            self.segmentedControl.setIndex(0)
            self.updateView()
        }
    }
}

