//
//  UpgradeFromSettingsViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/6/21.
//

import UIKit
import StoreKit

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
    var products: [SKProduct] = []
    var store: IAPManager!
    var typeIndex = 2
    
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
        
        if screenHeight == 780 {
            imageHeightConstraint.constant = 530
        } else if screenHeight >= 812 {
            imageHeightConstraint.constant = 580
        } else if screenHeight >= 844 {
            imageHeightConstraint.constant = 600
        } else {
            imageHeightConstraint.constant = 480
        }
        
        print(products)
        
        service.getSubscribeTitles(for: PremiumTab.Subscribe.rawValue) { (subscribe, error) in
            if let error = error {
                ErrorHandling.showError(message: error.localizedDescription, controller: self)
                DispatchQueue.main.async {
                    self.configureSlideLabels(subscribe: SubscribeTitle())
                }
                return
            }
            if let subscribe = subscribe {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.configureSlideLabels(subscribe: subscribe)
                }
            }
        }
    }
    
    private func configureSlideLabels(subscribe: SubscribeTitle) {
        self.closeButton.isHidden = !subscribe.closeButton
        self.closeButton.isEnabled = subscribe.closeButton
        self.premiumLabel.text = subscribe.firstTitle
        self.enjoyLabel.text = subscribe.secondTitle
        self.annualLabel1.text = subscribe.annualFirstTitle
        self.annualLabel2.text = subscribe.annualSecondTitle
        self.monthlyLabel1.text = subscribe.monthlyFirstTitle
        self.monthlyLabel2.text = subscribe.monthlySecondTitle
        self.weeklyLabel1.text = subscribe.weeklyFirstTitle
        self.weeklyLabel2.text = subscribe.weeklySecondTitle
    }
    
    // MARK: - Upgrading product
    private func upgradeProduct(index: Int) {
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
                NotificationCenter.default.post(name: hideSettingsUpgradeNotification, object: nil)
                self.dismiss(animated: true)
            }
        }
    }
    
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
    }
    
    @IBAction func annualTapped(_ sender: Any) {
        typeIndex = 2
        setImagesForButton(tags: [100, 110, 120])
    }
    
    @IBAction func monthlyTapped(_ sender: Any) {
        typeIndex = 0
        setImagesForButton(tags: [110, 100, 120])
    }
    
    @IBAction func weeklyTapped(_ sender: Any) {
        typeIndex = 1
        setImagesForButton(tags: [120, 100, 110])
    }
    
    @IBAction func upgradeTapped(_ sender: Any) {
        upgradeProduct(index: typeIndex)
    }
    
    @IBAction func termsTapped(_ sender: Any) {
        openURL(path: kTermsURL)
    }
    
    @IBAction func privacyTapped(_ sender: Any) {
        openURL(path: kPolicyURL)
    }
    
    @IBAction func restoreTapped(_ sender: Any) {
        displayAnimatedActivityIndicatorView()
        DispatchQueue.global(qos: .userInitiated).async {
            self.store.restorePurchases { (succes, productID) in
                DispatchQueue.main.async {
                    guard succes else { return }
                    self.hideAnimatedActivityIndicatorView()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
