//
//  Slide.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/26/21.
//

import UIKit

let dismissNotification: Notification.Name = Notification.Name(rawValue: "DismissNotification")
let subTypeNotificationIndex: Notification.Name = Notification.Name("NotificationIndex")

let screenSize = UIScreen.main.bounds
let screenWidth = screenSize.width
let screenHeight = screenSize.height

class Slide: UIView {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint! // 315 for upgrade
    @IBOutlet weak var topConstraint: NSLayoutConstraint! // 48 for upgrade
    
    @IBOutlet weak var premiumLabel: UILabel!
    @IBOutlet weak var enjoyLabel: UILabel!
    @IBOutlet weak var startFreeLabel: UILabel!
    @IBOutlet weak var thenLabel: UILabel!
    @IBOutlet weak var proceedWithBasicButton: UIButton!
    
    @IBOutlet weak var tryFreeButton: UIButton!
    @IBOutlet weak var startMonthlyView: UIView!
    @IBOutlet weak var startMonthlyButton: UIButton!
    @IBOutlet weak var startMonthlySecondButton: UIButton!
    @IBOutlet weak var eulaStackView: UIStackView!
    @IBOutlet weak var privacyEulaLabel: UILabel!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    @IBOutlet weak var eulaButton: UIButton!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        firstLabel.textAlignment = .center
        secondLabel.textAlignment = .center
    }
    
    // MARK: - Properties
    static var slides: [Slide] {
        print("Screen Height = \(screenHeight)")
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
        if screenHeight > 736 {
            slide1.bottomConstraint.constant = 360
        } else if screenHeight <= 667 {
            slide1.bottomConstraint.constant = 215
        } else {
            slide1.bottomConstraint.constant = 284
        }
        
        slide1.closeButton.isHidden = true
        slide1.closeButton.isEnabled = false
        slide1.startFreeLabel.isHidden = true
        slide1.thenLabel.isHidden = true
        slide1.proceedWithBasicButton.isHidden = true
        slide1.proceedWithBasicButton.isEnabled = false
        slide1.tryFreeButton.isHidden = true
        slide1.tryFreeButton.isEnabled = false
        slide1.startMonthlyButton.isEnabled = false
        slide1.startMonthlySecondButton.isEnabled = false
        slide1.startMonthlyView.isHidden = true
        slide1.eulaStackView.isHidden = true
        slide1.privacyPolicyButton.isEnabled = false
        slide1.eulaButton.isEnabled = false
        
        let slide2: Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide2.imageView.image = UIImage(named: "barCodeOnboarding")
        slide2.firstLabel.attributedText = NSMutableAttributedString(string: "BARCODES", attributes: [NSAttributedString.Key.kern: 1.92, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        slide2.secondLabel.attributedText = NSMutableAttributedString(string: "Easily scan barcodes", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        slide2.premiumLabel.isHidden = true
        slide2.enjoyLabel.isHidden = true
        if screenHeight > 736 {
            slide2.bottomConstraint.constant = 360
        } else if screenHeight <= 667 {
            slide2.bottomConstraint.constant = 215
        } else {
            slide2.bottomConstraint.constant = 284
        }
        
        slide2.closeButton.isHidden = true
        slide2.closeButton.isEnabled = false
        slide2.startFreeLabel.isHidden = true
        slide2.thenLabel.isHidden = true
        slide2.proceedWithBasicButton.isHidden = true
        slide2.proceedWithBasicButton.isEnabled = false
        slide2.tryFreeButton.isHidden = true
        slide2.tryFreeButton.isEnabled = false
        slide2.startMonthlyButton.isEnabled = false
        slide2.startMonthlySecondButton.isEnabled = false
        slide2.startMonthlyView.isHidden = true
        slide2.eulaStackView.isHidden = true
        slide2.privacyPolicyButton.isEnabled = false
        slide2.eulaButton.isEnabled = false
        
        let slide3: Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide3.imageView.image = UIImage(named: "upgradeBackground")
        slide3.firstLabel.text = nil
        slide3.secondLabel.text = nil
        if screenHeight > 736 {
            slide3.bottomConstraint.constant = 400
        } else {
            slide3.bottomConstraint.constant = 315
        }
        
        slide3.topConstraint.constant = 48
        slide3.premiumLabel.isHidden = false
        slide3.enjoyLabel.isHidden = false
        
        slide3.closeButton.isHidden = false
        slide3.closeButton.isEnabled = true
        slide3.startFreeLabel.isHidden = false
        slide3.thenLabel.isHidden = false
        slide3.proceedWithBasicButton.isHidden = false
        slide3.proceedWithBasicButton.isEnabled = true
        slide3.proceedWithBasicButton.addLine(position: .LINE_POSITION_BOTTOM, color: .mainGrayAverage, width: 0.5)
        slide3.tryFreeButton.isHidden = false
        slide3.tryFreeButton.isEnabled = true
        slide3.tryFreeButton.cornerRadius(to: 20)
        slide3.startMonthlyView.cornerRadius(to: 20)
        slide3.startMonthlyView.addBorder(width: 2.0, color: .mainBlack)
        slide3.startMonthlyButton.isEnabled = true
        slide3.startMonthlySecondButton.isEnabled = true
        slide3.startMonthlyView.isHidden = false
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
        let userInfo = ["index": 2]
        NotificationCenter.default.post(name: subTypeNotificationIndex, object: nil, userInfo: userInfo)
    }
    
    @IBAction func startMonthlyTapped(_ sender: Any) {
        print("StartMonthly tapped")
        let userInfo = ["index": 0]
        NotificationCenter.default.post(name: subTypeNotificationIndex, object: nil, userInfo: userInfo)
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
