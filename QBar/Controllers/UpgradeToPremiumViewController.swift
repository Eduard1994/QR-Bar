//
//  UpgradeToPremiumViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/4/21.
//

import UIKit
import StoreKit

class UpgradeToPremiumViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var upgradeLabel: UILabel!
    @IBOutlet weak var enjoyLabel: UILabel!
    @IBOutlet weak var startFreeLabel: UILabel!
    @IBOutlet weak var thenLabel: UILabel!
    @IBOutlet weak var proceedWithBasicButton: UIButton!
    @IBOutlet weak var tryFreeButton: UIButton!
    @IBOutlet weak var startMonthlyView: UIView!
    @IBOutlet weak var startMonthlyButton: UIButton!
    @IBOutlet weak var priceAMonthButton: UIButton!
    @IBOutlet weak var trialLabel: UILabel!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var eulaButton: UIButton!
    
    
    // MARK: - Properties
    var products: [SKProduct] = []
    let service = Service()
    var store: IAPManager!
    
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
    
    
    // MARK: - Private Functions
    private func configureView() {
        proceedWithBasicButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
        tryFreeButton.cornerRadius(to: 20)
        privacyButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
        eulaButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
        startMonthlyView.cornerRadius(to: 20)
        startMonthlyView.addBorder(width: 2.0, color: .mainBlack)
        
        print(products)
        
        service.getSubscribeTitles(for: PremiumTab.Subscribe.rawValue) { (subscribe, error) in
            if let error = error {
                ErrorHandling.showError(message: error.localizedDescription, controller: self)
                self.configureSubscribeTitles(for: SubscribeTitle())
                return
            }
            if let subscribe = subscribe {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.configureSubscribeTitles(for: subscribe)
                }
            }
        }
    }
    
    private func configureSubscribeTitles(for subscribe: SubscribeTitle) {
        self.upgradeLabel.text = subscribe.firstTitle
        self.enjoyLabel.text = subscribe.secondTitle
        self.startFreeLabel.text = subscribe.thirdTitle
        self.thenLabel.text = subscribe.fourthTitle
        self.proceedWithBasicButton.setTitle(subscribe.basicTitle, for: UIControl.State())
        self.tryFreeButton.setTitle(subscribe.tryFreeTitle, for: UIControl.State())
        self.startMonthlyButton.setTitle(subscribe.startMonthlyFirstTitle, for: UIControl.State())
        self.priceAMonthButton.setTitle(subscribe.startMonthlySecondTitle, for: UIControl.State())
        self.trialLabel.text = subscribe.privacyEulaTitle
    }
    
    private func purchase(index: Int) {
        print(products)
        displayAnimatedActivityIndicatorView()
        guard !products.isEmpty else {
            self.hideAnimatedActivityIndicatorView()
            print("Cannot purchase subscription because products is empty!")
            return
        }
        self.store.buyProduct(products[index]) { [weak self] success, productId in
            guard let self = self else { return }
            guard success else {
                self.hideAnimatedActivityIndicatorView()
                DispatchQueue.main.async {
                    self.alert(title: "Failed to purchase product", message: "Check logs for details", preferredStyle: .alert, actionTitle: "OK")
                }
                return
            }
            print("Purchased")
            DispatchQueue.main.async {
                self.hideAnimatedActivityIndicatorView()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - IBActions
    @IBAction func proceedWithBasicTapped(_ sender: Any) {
        NotificationCenter.default.post(name: dismissNotification, object: nil)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tryFreeTapped(_ sender: Any) {
        purchase(index: 1)
    }
    
    @IBAction func startMonthlyTapped(_ sender: Any) {
        purchase(index: 0)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        NotificationCenter.default.post(name: dismissNotification, object: nil)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func privacyTapped(_ sender: Any) {
        openURL(path: kPolicyURL)
    }
    
    @IBAction func eulaTapped(_ sender: Any) {
        openURL(path: kTermsURL)
    }
}