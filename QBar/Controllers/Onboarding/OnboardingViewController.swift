//
//  OnboardingViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/26/21.
//

import UIKit

protocol UpgradeFromOnboardingDelegate: class {
    func dismissFromUpgrade()
    func purchased(purchases: [ProductID])
}

class OnboardingViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var snakePageControl: SnakePageControl!
    @IBOutlet weak var nextButton: UIButton!
    
    // MARK: - Properties
    var slides: [Slide] = []
    var subscriptions: Subscriptions = Subscriptions()
    let service = Service()
    var productIDs: Set<ProductID> = []
    
    weak var delegate: UpgradeFromOnboardingDelegate?
    
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
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: dismissNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: subTypeNotificationIndex, object: nil)
    }
    
    // MARK: - Functions
    /// Setting up Slide Scroll View
    func setupSlideScrollView(slides: [Slide]) {
        let viewWidth = view.frame.width
        let viewHeight = view.frame.height
        let slidesCount = slides.count
        
        scrollView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        scrollView.contentSize = CGSize(width: viewWidth * CGFloat(slidesCount), height: viewHeight)
        scrollView.isPagingEnabled = true
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: viewWidth * CGFloat(i), y: 0, width: viewWidth, height: viewHeight)
            scrollView.addSubview(slides[i])
        }
    }
    
    func setupScrollViewDidScroll(scrollView: UIScrollView, pageIndex: CGFloat) {
        snakePageControl.progress = pageIndex
        
        let maximumHorizontalOffset: CGFloat = scrollView.contentSize.width - scrollView.frame.width
        let currentHorizontalOffset: CGFloat = scrollView.contentOffset.x
        
        // vertical
        let maximumVerticalOffset: CGFloat = scrollView.contentSize.height - scrollView.frame.height
        let currentVerticalOffset: CGFloat = scrollView.contentOffset.y
        
        let percentageHorizontalOffset: CGFloat = currentHorizontalOffset / maximumHorizontalOffset
        let percentageVerticalOffset: CGFloat = currentVerticalOffset / maximumVerticalOffset
        
        
        /*
         * below code changes the background color of view on paging the scrollview
         */
        //        self.scrollView(scrollView, didScrollToPercentageOffset: percentageHorizontalOffset)
        
        
        /*
         * below code scales the imageview on paging the scrollview
         */
        let percentOffset: CGPoint = CGPoint(x: percentageHorizontalOffset, y: percentageVerticalOffset)
        
        
        
        if(percentOffset.x > 0 && percentOffset.x <= 0.25) {
            snakePageControl.previousTint = .mainGray
        } else if(percentOffset.x > 0.25 && percentOffset.x <= 0.50) {
            snakePageControl.previousTint = .black
        }
        
        if percentOffset.x > 0.7 {
            snakePageControl.isHidden = true
            nextButton.isHidden = true
            nextButton.isEnabled = false
        } else {
            nextButton.isHidden = false
            nextButton.isEnabled = true
            snakePageControl.isHidden = false
            nextButton.setImage(UIImage(named: "arrowRight"), for: .normal)
            nextButton.setTitle(nil, for: .normal)
        }
    }
    
    // MARK: - Configuring View
    private func configureView() {
        NotificationCenter.default.addObserver(self, selector: #selector(notifiedToDismiss), name: dismissNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notifiedForProductIndex(notification:)), name: subTypeNotificationIndex, object: nil)
        
        slides = Slide.slides
        
//        print(products)
        
        setupSlideScrollView(slides: slides)
        
        service.getOnboardingTitles(for: PremiumTab.Onboarding.rawValue) { (onboarding, error) in
            if let error = error {
                ErrorHandling.showError(message: error.localizedDescription, controller: self)
                for slide in self.slides {
                    DispatchQueue.main.async {
                        self.configureSlideLabels(slide: slide, onboarding: OnboardingTitle(), subscriptions: self.subscriptions)
                    }
                }
                return
            }
            if let onboarding = onboarding {
                for slide in self.slides {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.configureSlideLabels(slide: slide, onboarding: onboarding, subscriptions: self.subscriptions)
                    }
                }
            }
        }
        
        nextButton.isEnabled = true
        nextButton.isHidden = false
        nextButton.cornerRadius(to: 20)
        
        snakePageControl.pageCount = slides.count
        snakePageControl.progress = 0
        snakePageControl.previousTint = .mainGray
        
        view.bringSubviewToFront(snakePageControl)
        
        // Firebase Analytics
        DispatchQueue.global(qos: .default).async {
            Service().checkUser { (user, error) in
                if let user = user, error == nil {
                    print(user)
                    DispatchQueue.main.async {
                        QRAnalytics.shared.onboardingBegan(userID: user.uid, success: "1")
                    }
                } else {
                    QRAnalytics.shared.onboardingBegan(userID: "user.uid", success: "0")
                    print(error!.localizedDescription)
                }
            }
        }
    }
    
    private func configureSlideLabels(slide: Slide, onboarding: OnboardingTitle, subscriptions: Subscriptions) {
        if allPrices.count > 0 {
            for (title, price) in allPrices {
                if title.contains("Monthly") {
                    slide.thenLabel.text = "\(onboarding.fourthTitle) \(price) a month"
                } else if title.contains("Yearly") {
                    slide.startYearlySecondButton.setTitle("\(price) \(onboarding.startYearlySecondTitle)", for: UIControl.State())
                }
            }
        } else {
            slide.thenLabel.text = "\(onboarding.fourthTitle) $7.99 a month"
            slide.startYearlySecondButton.setTitle("$32.99 \(onboarding.startYearlySecondTitle)", for: UIControl.State())
        }
        
        slide.closeButton.isHidden = !onboarding.closeButton
        slide.closeButton.isEnabled = onboarding.closeButton
        slide.proceedWithBasicButton.isHidden = onboarding.proceedIsHidden
        slide.proceedWithBasicButton.isEnabled = !onboarding.proceedIsHidden
        slide.premiumLabel.text = onboarding.firstTitle
        slide.enjoyLabel.text = onboarding.secondTitle
        slide.startFreeLabel.text = onboarding.thirdTitle
        slide.proceedWithBasicButton.setTitle(onboarding.basicTitle, for: UIControl.State())
        slide.tryFreeButton.setTitle(onboarding.tryFreeTitle, for: UIControl.State())
        slide.startYearlyButton.setTitle(onboarding.startYearlyFirstTitle, for: UIControl.State())
        slide.privacyEulaLabel.text = onboarding.privacyEulaTitle
        
        slides.last?.thenLabel.isHidden = onboarding.fourthTitleIsHidden
        slides.last?.startYearlySecondButton.isHidden = onboarding.startYearlySecondTitleIsHIdden
        slides[0].closeButton.isHidden = true
        slides[0].closeButton.isEnabled = false
        slides[1].closeButton.isHidden = true
        slides[1].closeButton.isEnabled = false
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
    
    // MARK: - OBJC Functions
    @objc func notifiedToDismiss() {
        dismiss(animated: true, completion: nil)
        self.delegate?.dismissFromUpgrade()
    }
    
    @objc private func notifiedForProductIndex(notification: Notification) {
        if let index = notification.userInfo?["index"] as? Int {
            if snakePageControl.currentPage == 2 {
                if service.isConnectedToInternet {
                    for productID in productIDs {
                        if productID.contains("month") && index == 0 {
                            QRAnalytics.shared.tappedToSubscribeButton(userID: User.currentUser?.uid ?? "", button: "Try Free Button")
                            purchaseItem(productID: productID)
                        } else if productID.contains("year") && index == 2 {
                            QRAnalytics.shared.tappedToSubscribeButton(userID: User.currentUser?.uid ?? "", button: "Start Yearly Button")
                            purchaseItem(productID: productID)
                        }
                    }
                } else {
                    ErrorHandling.showError(message: "Check Internet Connection and try again.", controller: self)
                }
            }
        }
    }
    
    
    // MARK: - IBActions
    @IBAction func nextTapped(_ sender: Any) {
        QRAnalytics.shared.nextTapped(userID: User.currentUser?.uid ?? "", slidePage: "\(snakePageControl.currentPage + 1)")
        var frame = scrollView.frame
        frame.origin.x = frame.size.width * CGFloat((snakePageControl.currentPage + 1))
        frame.origin.y = 0
        scrollView.scrollRectToVisible(frame, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension OnboardingViewController: UIScrollViewDelegate {
    /*
     * default function called when view is scrolled. In order to enable callback
     * when scrollview is scrolled, the below code needs to be called:
     * slideScrollView.delegate = self or
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setupScrollViewDidScroll(scrollView: scrollView, pageIndex: scrollView.contentOffset.x/view.frame.width)
    }
    
    func scrollView(_ scrollView: UIScrollView, didScrollToPercentageOffset percentageHorizontalOffset: CGFloat) {
        print("here")
    }
}
