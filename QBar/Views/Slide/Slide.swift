//
//  Slide.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/26/21.
//

import UIKit

let dismissNotification: Notification.Name = Notification.Name(rawValue: "DismissNotification")
let subTypeNotificationIndex: Notification.Name = Notification.Name("NotificationIndex")

class Slide: UIView {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint! // 251 for custom
    @IBOutlet weak var topConstraint: NSLayoutConstraint! // 92 for custom
    
    @IBOutlet weak var videoView: VideoView!
    
    @IBOutlet weak var premiumLabel: UILabel!
    @IBOutlet weak var enjoyLabel: UILabel!
    @IBOutlet weak var startFreeLabel: UILabel!
    @IBOutlet weak var startFreeLabel2: UILabel!
    @IBOutlet weak var thenLabel: UILabel!
    @IBOutlet weak var thenLabel2: UILabel!
    @IBOutlet weak var proceedWithBasicButton: UIButton!
    
    @IBOutlet weak var tryFreeButton: UIButton!
    @IBOutlet weak var startMonthlyView: UIView!
//    @IBOutlet weak var startMonthlyButton: UIButton!
//    @IBOutlet weak var startMonthlySecondButton: UIButton!
    @IBOutlet weak var startYearlyButton: UIButton!
    @IBOutlet weak var startYearlySecondButton: UIButton!
    @IBOutlet weak var eulaStackView: UIStackView!
    @IBOutlet weak var privacyEulaLabel: UILabel!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    @IBOutlet weak var eulaButton: UIButton!
    
    @IBOutlet weak var closeButtonTop: NSLayoutConstraint! // default 43
    @IBOutlet weak var videoHeightConstraint: NSLayoutConstraint! // default 381
    
    override func layoutSubviews() {
        super.layoutSubviews()
        firstLabel.textAlignment = .center
        secondLabel.textAlignment = .center
    }
    
    // MARK: - Properties
    static var slides: [Slide] {
        print("Screen Height = \(UIScreen.main.bounds.height)")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        // Line height: 32 pt
        // (identical to box height)
        
        let paragraphStyle2 = NSMutableParagraphStyle()
        paragraphStyle2.lineHeightMultiple = 1.26

        // Line height: 24 pt
        // (identical to box height)
        
        let slide1: Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide1.imageView.image = UIImage(named: "qrOnboarding")
        slide1.firstLabel.attributedText = NSMutableAttributedString(string: "QR SCANER", attributes: [NSAttributedString.Key.kern: 1.92, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        slide1.secondLabel.attributedText = NSMutableAttributedString(string: "Instant scanning QR code", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        slide1.premiumLabel.isHidden = true
        slide1.enjoyLabel.isHidden = true
        
        switch type {
        case .iPhone5_5S_5C_SE:
            slide1.bottomConstraint.constant = 284
        case .iPhone6_6S_7_8_SE2:
            slide1.bottomConstraint.constant = 284
        case .iPhone6Plus_6SPlus_7Plus_8Plus:
            slide1.bottomConstraint.constant = 284
        case .iPhone12Mini:
            slide1.bottomConstraint.constant = 314
        case .iPhoneX_XS_11Pro:
            slide1.bottomConstraint.constant = 314
        case .iPhone12_12Pro:
            slide1.bottomConstraint.constant = 314
        case .iPhoneXR_XSMax_11_11ProMax:
            slide1.bottomConstraint.constant = 314
        case .iPhone12ProMax:
            slide1.bottomConstraint.constant = 314
        default:
            break
        }
//        slide1.closeButton.isHidden = true
//        slide1.closeButton.isEnabled = false
        slide1.videoView.isHidden = true
        slide1.startFreeLabel.isHidden = true
        slide1.startFreeLabel2.isHidden = true
        slide1.thenLabel.isHidden = true
        slide1.thenLabel2.isHidden = true
        slide1.proceedWithBasicButton.isHidden = true
        slide1.proceedWithBasicButton.isEnabled = false
        slide1.tryFreeButton.isHidden = true
        slide1.tryFreeButton.isEnabled = false
        slide1.startYearlyButton.isEnabled = false
        slide1.startYearlySecondButton.isEnabled = false
        slide1.startMonthlyView.isHidden = true
        slide1.eulaStackView.isHidden = true
        slide1.privacyPolicyButton.isEnabled = false
        slide1.eulaButton.isEnabled = false
        slide1.imageView.isHidden = false
        slide1.closeButtonTop.constant = 43
        
        let slide2: Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide2.imageView.image = UIImage(named: "barCodeOnboarding")
        slide2.firstLabel.attributedText = NSMutableAttributedString(string: "BARCODES", attributes: [NSAttributedString.Key.kern: 1.92, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        slide2.secondLabel.attributedText = NSMutableAttributedString(string: "Easily scan barcodes", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        slide2.premiumLabel.isHidden = true
        slide2.enjoyLabel.isHidden = true
        
        switch type {
        case .iPhone5_5S_5C_SE:
            slide2.bottomConstraint.constant = 284
        case .iPhone6_6S_7_8_SE2:
            slide2.bottomConstraint.constant = 284
        case .iPhone6Plus_6SPlus_7Plus_8Plus:
            slide2.bottomConstraint.constant = 284
        case .iPhone12Mini:
            slide2.bottomConstraint.constant = 314
        case .iPhoneX_XS_11Pro:
            slide2.bottomConstraint.constant = 314
        case .iPhone12_12Pro:
            slide2.bottomConstraint.constant = 314
        case .iPhoneXR_XSMax_11_11ProMax:
            slide2.bottomConstraint.constant = 314
        case .iPhone12ProMax:
            slide2.bottomConstraint.constant = 314
        default:
            break
        }
        
//        slide2.closeButton.isHidden = true
//        slide2.closeButton.isEnabled = false
        slide2.videoView.isHidden = true
        slide2.startFreeLabel.isHidden = true
        slide2.startFreeLabel2.isHidden = true
        slide2.thenLabel.isHidden = true
        slide2.thenLabel2.isHidden = true
        slide2.proceedWithBasicButton.isHidden = true
        slide2.proceedWithBasicButton.isEnabled = false
        slide2.tryFreeButton.isHidden = true
        slide2.tryFreeButton.isEnabled = false
        slide2.startYearlyButton.isEnabled = false
        slide2.startYearlySecondButton.isEnabled = false
        slide2.startMonthlyView.isHidden = true
        slide2.eulaStackView.isHidden = true
        slide2.privacyPolicyButton.isEnabled = false
        slide2.eulaButton.isEnabled = false
        slide2.imageView.isHidden = false
        slide2.closeButtonTop.constant = 43
        
        let slide3: Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide3.imageView.image = UIImage(named: "upgradeBackground")
        slide3.firstLabel.text = nil
        slide3.secondLabel.text = nil
        
        switch type {
        case .iPhone5_5S_5C_SE:
            slide3.bottomConstraint.constant = 315
            slide3.videoHeightConstraint.constant = 261
        case .iPhone6_6S_7_8_SE2:
            slide3.bottomConstraint.constant = 315
            slide3.videoHeightConstraint.constant = 360
        case .iPhone6Plus_6SPlus_7Plus_8Plus:
            slide3.bottomConstraint.constant = 315
            slide3.videoHeightConstraint.constant = 400
        case .iPhone12Mini:
            slide3.bottomConstraint.constant = 345
            slide3.videoHeightConstraint.constant = 460
        case .iPhoneX_XS_11Pro:
            slide3.bottomConstraint.constant = 345
            slide3.videoHeightConstraint.constant = 490
        case .iPhone12_12Pro:
            slide3.bottomConstraint.constant = 345
            slide3.videoHeightConstraint.constant = 520
        case .iPhoneXR_XSMax_11_11ProMax:
            slide3.bottomConstraint.constant = 345
            slide3.videoHeightConstraint.constant = 560
        case .iPhone12ProMax:
            slide3.bottomConstraint.constant = 345
            slide3.videoHeightConstraint.constant = 560
        default:
            break
        }
        
        slide3.topConstraint.constant = 48
        slide3.premiumLabel.isHidden = true
        slide3.enjoyLabel.isHidden = true
        slide3.imageView.isHidden = true
        slide3.closeButtonTop.constant = 25
        
//        slide3.closeButton.isHidden = false
//        slide3.closeButton.isEnabled = true
        slide3.videoView.isHidden = false
        slide3.startFreeLabel.isHidden = true
        slide3.thenLabel.isHidden = true
        slide3.startFreeLabel2.isHidden = false
        slide3.thenLabel2.isHidden = false
        slide3.proceedWithBasicButton.isHidden = true
        slide3.proceedWithBasicButton.isEnabled = false
        slide3.proceedWithBasicButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
        slide3.tryFreeButton.isHidden = false
        slide3.tryFreeButton.isEnabled = true
        slide3.tryFreeButton.cornerRadius(to: 20)
        slide3.startMonthlyView.cornerRadius(to: 20)
        slide3.startMonthlyView.addBorder(width: 2.0, color: .mainBlack)
        slide3.startYearlyButton.isEnabled = false
        slide3.startYearlyButton.isHidden = true
        slide3.startYearlySecondButton.isEnabled = false
        slide3.startYearlySecondButton.isHidden = true
        slide3.startMonthlyView.isHidden = true
        slide3.eulaStackView.isHidden = false
        slide3.privacyPolicyButton.isEnabled = true
        slide3.privacyPolicyButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
        slide3.eulaButton.isEnabled = true
        slide3.eulaButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
        
        return [slide1, slide2, slide3]
    }
    
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        print("Tapped close")
        NotificationCenter.default.post(name: dismissNotification, object: nil)
    }
    
    @IBAction func proceedWithBasicTapped(_ sender: Any) {
        print("Proceed Tapped")
        NotificationCenter.default.post(name: dismissNotification, object: nil)
    }
    
    @IBAction func tryFreeTapped(_ sender: Any) {
        print("Try free tapped")
        let userInfo = ["index": 0]
        NotificationCenter.default.post(name: subTypeNotificationIndex, object: nil, userInfo: userInfo)
    }
    
    @IBAction func startYearlyTapped(_ sender: Any) {
        print("Start Yearly tapped")
        let userInfo = ["index": 2]
        NotificationCenter.default.post(name: subTypeNotificationIndex, object: nil, userInfo: userInfo)
    }
    
    @IBAction func startMonthlyTapped(_ sender: Any) {
        print("StartMonthly tapped")
    }
    
    @IBAction func privacyPolicyTapped(_ sender: Any) {
        print("privacy tapped")
        openURL(path: kPolicyURL)
    }
    
    @IBAction func eulaTapped(_ sender: Any) {
        print("terms tapped")
        openURL(path: kTermsURL)
    }
}
