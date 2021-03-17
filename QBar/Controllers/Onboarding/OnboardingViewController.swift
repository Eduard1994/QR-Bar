//
//  OnboardingViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/26/21.
//

import UIKit
import StoreKit

class OnboardingViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var snakePageControl: SnakePageControl!
    @IBOutlet weak var nextButton: UIButton!
    
    // MARK: - Properties
    var slides: [Slide] = []
    var products: [SKProduct] = []
    var subscriptions: Subscriptions = Subscriptions()
    var store: IAPManager!
    var productIndex = 2
    let service = Service()
    
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
        
        print(products)
        
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
    }
    
    private func configureSlideLabels(slide: Slide, onboarding: OnboardingTitle, subscriptions: Subscriptions) {
        slide.closeButton.isHidden = !onboarding.closeButton
        slide.closeButton.isEnabled = onboarding.closeButton
        slide.premiumLabel.text = onboarding.firstTitle
        slide.enjoyLabel.text = onboarding.secondTitle
        slide.startFreeLabel.text = onboarding.thirdTitle
        slide.thenLabel.text = "\(onboarding.fourthTitle) $\(subscriptions.monthlyProductPrice) a month"
        slide.proceedWithBasicButton.setTitle(onboarding.basicTitle, for: UIControl.State())
        slide.tryFreeButton.setTitle(onboarding.tryFreeTitle, for: UIControl.State())
        slide.startMonthlyButton.setTitle(onboarding.startMonthlyFirstTitle, for: UIControl.State())
        slide.startMonthlySecondButton.setTitle("$\(subscriptions.monthlyProductPrice) \(onboarding.startMonthlySecondTitle)", for: UIControl.State())
        slide.privacyEulaLabel.text = onboarding.privacyEulaTitle
    }
    
    private func purchaseItem(index: Int) {
        print(products)
        displayAnimatedActivityIndicatorView()
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
                self.dismiss(animated: true, completion: nil) // Will be updated soon
            }
        }
    }
    
    // MARK: - OBJC Functions
    @objc func notifiedToDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func notifiedForProductIndex(notification: Notification) {
        if let index = notification.userInfo?["index"] as? Int {
            self.productIndex = index
            if snakePageControl.currentPage == 2 {
                guard !products.isEmpty else {
                    print("Cannot purchase subscription because products is empty!")
                    return
                }
                self.purchaseItem(index: productIndex)
            }
        }
    }
    
    
    // MARK: - IBActions
    @IBAction func nextTapped(_ sender: Any) {
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
