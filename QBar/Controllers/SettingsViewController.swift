//
//  SettingsViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit
import StoreKit
import MessageUI

class SettingsViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    lazy var upgradeFromSettingsVC: UpgradeFromSettingsViewController = {
        let vc = UpgradeFromSettingsViewController.instantiate(from: .Premium, with: UpgradeFromSettingsViewController.typeName)
        return vc
    }()
    
    var settings: [Settings] = [] {
        didSet {
            self.reloadTableView()
        }
    }
    
    var products: [SKProduct] = []
    var store: IAPManager!
    let service = Service()
    
    // MARK: - Override properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - View LifeSycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getSubscriptions()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateHeaderViewHeight(for: tableView.tableHeaderView)
        updateFooterViewHeight(for: tableView.tableFooterView)
    }
    
    // MARK: - Functions
    private func configureView() {
        NotificationCenter.default.addObserver(self, selector: #selector(notifiedToUpgrade), name: upgradeFromSettings, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notifiedToShowError), name: showErrorForSettings, object: nil)
        
        tableView.register(UINib(nibName: SettingsTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: SettingsTableViewCell.identifier)
        tableView.backgroundColor = .mainWhite
        
        tableView.withoutSeparator()
        
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        
        let headerView = SettingsHeaderView(frame: .zero)
        headerView.configureHeader(text: "Settings")
        
        let footerView = FooterView(frame: .zero)
        footerView.configure(text: "")
        
        self.tableView.tableHeaderView = headerView
        self.tableView.tableFooterView = footerView
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.tintColor = .gray
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        refresh()
    }
    
    // MARK: - Requesting Premium Products
    private func getSubscriptions() {
        displayAnimatedActivityIndicatorView()
        DispatchQueue.global(qos: .userInitiated).async {
            self.service.getSubscriptions() { (productIDs, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self.hideAnimatedActivityIndicatorView()
                        ErrorHandling.showError(message: error.localizedDescription, controller: self)
                        return
                    }
                    if let productIDs = productIDs {
                        self.hideAnimatedActivityIndicatorView()
                        let store = IAPManager(productIDs: productIDs)
                        self.store = store
                        self.requestProducts(store: store, productIDs: productIDs)
                        self.checkProducts(store: store, productIDs: productIDs)
                    }
                }
            }
        }
    }
    
    private func checkProducts(store: IAPManager, productIDs: Set<ProductID>) {
        DispatchQueue.global(qos: .userInitiated).async {
            if store.isProductPurchased(productIDs[productIDs.startIndex]) || store.isProductPurchased(productIDs[productIDs.index(productIDs.startIndex, offsetBy: 1)]) || store.isProductPurchased(productIDs[productIDs.index(productIDs.startIndex, offsetBy: 2)]) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: hideSettingsUpgradeNotification, object: nil)
                    self.updateHeaderViewHeight(for: self.tableView.tableHeaderView)
                    self.refresh()
                }
            } else {
                // TODO
            }
        }
    }
    
    private func requestProducts(store: IAPManager, productIDs: Set<ProductID>) {
        DispatchQueue.global(qos: .userInitiated).async {
            store.requestProducts { [weak self](success, products) in
                guard let self = self else { return }
                guard success else {
                    self.hideAnimatedActivityIndicatorView()
                    DispatchQueue.main.async {
                        self.alert(title: "Failed to load list of products", message: "Check logs for details", preferredStyle: .alert, actionTitle: "OK", actionHandler: nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.hideAnimatedActivityIndicatorView()
                    self.products = products!
                    self.upgradeFromSettingsVC.products = products!
                    self.upgradeFromSettingsVC.store = self.store
                    self.checkProducts(store: store, productIDs: productIDs)
                }
            }
        }
    }
    
    private func updateHeaderViewHeight(for header: UIView?) {
        guard let header = header else { return }
        header.frame.size.height = header.systemLayoutSizeFitting(CGSize(width: view.width, height: 0)).height
    }
    
    private func updateFooterViewHeight(for footer: UIView?) {
        guard let footer = footer else { return }
        footer.frame.size.height = footer.systemLayoutSizeFitting(CGSize(width: view.width, height: 0)).height
    }
    
    private func reloadTableView() {
        DispatchQueue.main.async {
            UIView.transition(with: self.tableView, duration: 0.3, options: .transitionCrossDissolve) {
                self.tableView.reloadData()
            } completion: { (_) in
                self.provideHaptic()
            }
        }
    }
    
    private func reloadCodes() {
        settings = Settings.settings()
        
        DispatchQueue.main.after(1) {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    private func restorePurchase() { // Will be added soon
        displayAnimatedActivityIndicatorView()
        DispatchQueue.global(qos: .userInitiated).async {
            self.store.restorePurchases { (succes, productID) in
                DispatchQueue.main.async {
                    guard succes else { return }
                    self.hideAnimatedActivityIndicatorView()
                    NotificationCenter.default.post(name: hideSettingsUpgradeNotification, object: nil)
                    self.updateHeaderViewHeight(for: self.tableView.tableHeaderView)
                    self.refresh()
                }
            }
        }
    }
    
    private func contactUs() {
        let alert = UIAlertController(title: nil, message: "Do you want to contact us?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Contact via Email", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients([kEmail])
                mail.setCcRecipients([kCCRecipentEmail])
                mail.setSubject("Subject of the Mail.")
                self.present(mail, animated: true)
            } else {
                openURL(path: "mailto:\(kEmail)")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - OBJC Functions
    @objc private func refresh() {
        self.reloadCodes()
    }
    
    @objc private func notifiedToUpgrade() {
        upgradeFromSettingsVC.modalPresentationStyle = .fullScreen
        present(upgradeFromSettingsVC, animated: true, completion: nil)
    }
    
    @objc private func notifiedToShowError() {
        ErrorHandling.showError(message: NetworkError.noInternet.localizedDescription, controller: self)
    }
}

// MARK: - TableView Delegate & DataSource
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.identifier, for: indexPath) as! SettingsTableViewCell
        let setting = settings[indexPath.row]
        cell.settingsModel = SettingsCellModel(setting)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            print("Restoring...")
            self.restorePurchase()
        case 1:
            self.contactUs()
        case 2:
            openURL(path: kPolicyURL)
        case 3:
            openURL(path: kTermsURL)
        default:
            break
        }
    }
}

// MARK: - Mail Delegate
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
