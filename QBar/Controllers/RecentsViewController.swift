//
//  RecentsViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit
import StoreKit

class RecentsViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var recentCodes: [Code] = [] {
        didSet {
            self.reloadTableView()
        }
    }
    
    var bookmarkedCodes: [Code] = [] {
        didSet {
            self.reloadTableView()
        }
    }
    
    private lazy var onBoardingVC: OnboardingViewController = {
        let vc = OnboardingViewController.instantiate(from: .Onboarding, with: OnboardingViewController.typeName)
        return vc
    }()
    
    private lazy var upgradeToPremiumVC: UpgradeToPremiumViewController = {
        let vc = UpgradeToPremiumViewController.instantiate(from: .Premium, with: UpgradeToPremiumViewController.typeName)
        
        return vc
    }()
    
    var tab: Tab = .History {
        didSet {
            self.refresh()
        }
    }
    
    var user: User!
    var service: Service!
    var store: IAPManager!
    var products: [SKProduct] = []
    
    // MARK: - Override properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            // Fallback on earlier versions
            return .default
        }
    }
    
    // MARK: - View LyfeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        requestProducts()
        getSubscriptions()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateHeaderViewHeight(for: tableView.tableHeaderView)
        updateFooterViewHeight(for: tableView.tableFooterView)
    }
    
    // MARK: - Functions
    private func configureView() {
        service = Service()
        
        tableView.register(UINib(nibName: RecentsTableViewCell  .identifier, bundle: nil), forCellReuseIdentifier: RecentsTableViewCell.identifier)
        tableView.backgroundColor = .mainWhite
        
        tableView.separatorColor = .mainGrayAverage
        
        tableView.estimatedRowHeight = 88
        tableView.rowHeight = UITableView.automaticDimension
        
        let headerView = RecentsHeaderView(frame: .zero)
        headerView.configureHeader(text: "Recents")
        headerView.delegate = self
        
        let footerView = FooterView(frame: .zero)
        footerView.configure(text: "")
        
        tableView.tableHeaderView = headerView

        tableView.tableFooterView = footerView
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.tintColor = .gray
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        checkUser {
            self.refresh()
        }
    }
    // MARK - Presenting Upgrade VC
    private func presentUpgradeVC() {
        upgradeToPremiumVC.modalPresentationStyle = .fullScreen
        upgradeToPremiumVC.products = self.products
        upgradeToPremiumVC.store = self.store
        if presentedViewController != upgradeToPremiumVC {
            present(upgradeToPremiumVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Presenting Edit VC
    private func presentEditScreen(with code: Code) {
        let vc = RecentsDetailViewController.instantiate(from: .Main, with: RecentsDetailViewController.typeName)
        vc.code = code
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
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
            } else {
                DispatchQueue.main.async {
                    self.presentUpgradeVC()
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
                        let ac = UIAlertController(title: "Failed to load list of products", message: "Check logs for details", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true, completion: nil)
                        
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.hideAnimatedActivityIndicatorView()
                    self.products = products!
                    self.checkProducts(store: store, productIDs: productIDs)
                }
            }
        }
    }
    
    private func updateHeaderViewHeight(for header: UIView?) {
        guard let header = header else { return }
        header.frame.size.height = header.systemLayoutSizeFitting(CGSize(width: view.width, height: 0)).height + 5
    }
    
    private func updateFooterViewHeight(for footer: UIView?) {
        guard let footer = footer else { return }
        footer.frame.size.height = footer.systemLayoutSizeFitting(CGSize(width: view.width, height: 0)).height + 5
    }
    
    private func reloadTableView() {
        switch tab {
        case .History:
            tableView.reload(for: recentCodes, emptyLabeltext: "No History Found")
        case .Bookmarks:
            tableView.reload(for: bookmarkedCodes, emptyLabeltext: "No Bookmarks Found")
        }
        
        print("User is = \(String(describing: self.user))")
        
        DispatchQueue.main.async {
            UIView.transition(with: self.tableView, duration: 0.3, options: .transitionCrossDissolve) {
                self.tableView.reloadData()
            } completion: { (_) in
                self.provideHaptic()
            }
        }
    }
    
    private func checkUser(completion: @escaping (() -> Void)) {
        let path = URL(fileURLWithPath: NSTemporaryDirectory())
        let disk = DiskStorage(path: path)
        let storage = CodableStorage(storage: disk)
        
        tableView.refreshControl?.beginRefreshing()
        do {
            self.user = try storage.fetch(for: kUserDataKey)
            completion()
        } catch {
            self.user = nil
            print(error.localizedDescription)
        }
    }
    
    private func reloadCodes() {
        service.getCodes(for: tab.rawValue, userID: user.uid) { (codes, error) in
            if let error = error {
                ErrorHandling.showError(message: error.localizedDescription, controller: self)
                self.tableView.refreshControl?.endRefreshing()
                return
            }
            if let codes = codes {
                switch self.tab {
                case .History:
                    self.recentCodes = codes
                case .Bookmarks:
                    self.bookmarkedCodes = codes
                }
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func bookmark(code: Code) {
        service.addNewCode(code: code, at: Tab.Bookmarks.rawValue) { (childUpdates, error) in
            if let error = error {
                ErrorHandling.showError(message: error.localizedDescription, controller: self)
                return
            }
            if let childUpdates = childUpdates {
                print("Added = \(childUpdates) to bookmark")
                DispatchQueue.main.async {
                    self.alert(title: nil, message: "'\(code.title.capitalized)' added to Bookmarks", preferredStyle: .alert, actionTitle: "OK") {
                    }
                }
            }
        }
    }
    
    // MARK: - Override Functions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = RecentsDetailViewController.instantiate(from: .Main, with: RecentsDetailViewController.typeName)
        if segue.identifier == "showDetail" {
            if let cell = tableView.visibleCells.last as? RecentsTableViewCell {
                if let indexPath = tableView.indexPath(for: cell) {
                    let code = self.recentCodes[indexPath.row]
                    vc.code = code
                }
            }
        }
    }
    
    // MARK: - Removing code
    private func removeCode(code: Code) {
        service.removeCode(at: code.tab, withID: code.id, userID: user.uid, imageName: nil) { (error) in
            if let error = error {
                ErrorHandling.showError(message: error.localizedDescription, controller: self)
                return
            }
        }
    }
    
    // MARK: - OBJC Functions
    @objc private func refresh() {
        self.reloadCodes()
    }
}

// MARK: - TableView Delegate & DataSource
extension RecentsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tab {
        case .History:
            return recentCodes.count
        case .Bookmarks:
            return bookmarkedCodes.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentsTableViewCell.identifier, for: indexPath) as! RecentsTableViewCell
        var code: Code!
        switch tab {
        case .History:
            code = recentCodes[indexPath.row]
        case .Bookmarks:
            code = bookmarkedCodes[indexPath.row]
        }
        
        cell.codeModel = CodeCellModel(code)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var code: Code!
        switch tab {
        case .History:
            code = recentCodes[indexPath.row]
        case .Bookmarks:
            code = bookmarkedCodes[indexPath.row]
        }
        self.presentEditScreen(with: code)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var code: Code!
        switch tab {
        case .History:
            code = recentCodes[indexPath.row]
        case .Bookmarks:
            code = bookmarkedCodes[indexPath.row]
        }
        print(code as Any)
        
        let deleteAction: UIContextualAction.Handler = { action, view, completion in
            self.alert(title: nil, message: "Are you sure, you want to delete '\(code.title)'?", preferredStyle: .alert, cancelTitle: "No", cancelHandler: nil, actionTitle: "Yes, sure", actionHandler: {
                self.removeCode(code: code)
            })
            completion(true)
        }
        
        let bookmarkAction: UIContextualAction.Handler = { action, view, completion in
            self.bookmark(code: code)
            completion(true)
        }
        
        let actionHandler: UIContextualAction.Handler = { action, view, completion in
            self.presentEditScreen(with: code)
            completion(true)
        }

        let delete = UIContextualAction(style: .destructive, title: "Delete", handler: deleteAction)
        let bookmark = UIContextualAction(style: .normal, title: "Bookmark", handler: bookmarkAction)
        let edit = UIContextualAction(style: .normal, title: "", handler: actionHandler)
        
        delete.image = UIGraphicsImageRenderer(size: CGSize(width: 14, height: 14)).image { _ in
            UIImage(named: "deleteActionImage")?.draw(in: CGRect(x: 0, y: 0, width: 14, height: 14))
        }
        
        bookmark.image = UIGraphicsImageRenderer(size: CGSize(width: 14, height: 14)).image { _ in
            UIImage(named: "bookmarkActionImage")?.draw(in: CGRect(x: 0, y: 0, width: 14, height: 14))
        }
        
        edit.image = UIGraphicsImageRenderer(size: CGSize(width: 14, height: 14)).image { _ in
            UIImage(named: "editActionImage")?.draw(in: CGRect(x: 0, y: 0, width: 14, height: 14))
        }
        
        delete.backgroundColor = .mainRed
        bookmark.backgroundColor = .mainActionGray
        edit.backgroundColor = .mainWhite
        
        return UISwipeActionsConfiguration(actions: [delete, bookmark, edit])
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
}

// MARK: - Tab Delegate
extension RecentsViewController: TabDelegate {
    func didChoose(tab: Tab) {
        self.tab = tab
    }
}
