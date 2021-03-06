//
//  MainSegmentedViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit
import FirebaseDatabase

let setIndexNotification: Notification.Name = Notification.Name("SetIndexNotification")

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
    var storeKit: StoreKit!
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(notifiedToSetIndex), name: setIndexNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(launchRemoved), name: launchRemovedNotification, object: nil)
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Functions
    private func configureView() {
        service = Service()
        storeKit = StoreKit.shared
        
        let segmentsSize = CGSize(width: 18, height: 18)
        let images: [UIImage] = [UIImage(named: "recentsIcon")!, UIImage(named: "qrBarIcon")!, UIImage(named: "settingsIcon")!]
        let segments = IconSegment.segments(withIcons: images, iconSize: segmentsSize, normalBackgroundColor: .mainBlack, normalIconTintColor: .mainWhite, selectedBackgroundColor: .mainBlue, selectedIconTintColor: .mainWhite)
        
        segmentedControl.segments = segments
        segmentedControl.setIndex(1)
        segmentedControl.addTarget(self, action: #selector(selectionDidChange(_:)), for: .valueChanged)
        
        checkUser()
    }
    
    private func presentOnboarding(with productIDs: Set<ProductID>) {
        if UserDefaults.standard.bool(forKey: kOnboardingStatus) != true {
            onBoardingVC.productIDs = productIDs
            onBoardingVC.delegate = self
            if presentedViewController != onBoardingVC {
                self.presentOverFullScreen(onBoardingVC, animated: true) {
                    UserDefaults.standard.set(true, forKey: kOnboardingStatus)
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
        
        guard user != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                controller.reset(animated: true)
                if !self.cancelled {
                    DispatchQueue.main.after(0.5) {
                        self.segmentedControl.setIndex(0)
                        self.updateView()
                    }
                } else {
                    self.cancelled = false
                }
            }
            return
        }
        
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
    @objc func launchRemoved() {
        print("All Prices = \(allPrices)")
        print("All Products = \(allProducts)")
        print("All Product IDs = \(allProductIDs)")
        print("Purchased = \(purchasedAny)")
        
        notifiedToSetIndex()
        
        if !purchasedAny {//&& service.isConnectedToInternet {
            self.presentOnboarding(with: allProductIDs)
        }
    }
    
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

// MARK: - Upgrade From Onboarding Delegate {
extension MainSegmentedViewController: UpgradeFromOnboardingDelegate {
    func dismissFromUpgrade() {
        print("Dismissed")
        segmentedControl.setIndex(1)
        self.updateView()
    }
    
    func purchased(purchases: [ProductID]) {
        print(purchases)
    }
}
