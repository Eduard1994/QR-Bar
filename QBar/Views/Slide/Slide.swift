//
//  Slide.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/26/21.
//

import UIKit

let dismissNotification: Notification.Name = Notification.Name(rawValue: "DismissNotification")
let subTypeNotificationIndex: Notification.Name = Notification.Name("NotificationIndex")
let restoreNotification: Notification.Name = Notification.Name("RestoreNotification")

class Slide: UIView {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint! // 187 if upgrade
    
    @IBOutlet weak var premiumLabel: UILabel!
    @IBOutlet weak var enjoyLabel: UILabel!
    
    @IBOutlet weak var upgradeView: UIView!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var annualLabel1: UILabel!
    @IBOutlet weak var annualLabel2: UILabel!
    @IBOutlet weak var annualView: UIView!
    
    @IBOutlet weak var monthlyLabel1: UILabel!
    @IBOutlet weak var monthlyLabel2: UILabel!
    @IBOutlet weak var monthlyView: UIView!
    
    @IBOutlet weak var weeklyLabel1: UILabel!
    @IBOutlet weak var weeklyLabel2: UILabel!
    @IBOutlet weak var weeklyView: UIView!
    
    @IBOutlet weak var annualButton: UIButton!
    @IBOutlet weak var monthlyButton: UIButton!
    @IBOutlet weak var weeklyButton: UIButton!
    
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var termsStackView: UIStackView!
    
    let firstLabels = ["QR SCANER", "BARCODES", nil]
    let secondLabels = ["Instant scanning QR code", "Easily scan barcodes", nil]
    
    lazy var specialOfferLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .sfProDisplay(ofSize: 11, style: .bold)
        label.textColor = .mainWhite
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        firstLabel.textAlignment = .center
        secondLabel.textAlignment = .center
    }
    
    // MARK: - Properties
    static var slides: [Slide] {
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
        slide1.upgradeView.isHidden = true
        slide1.stackView.isHidden = true
        slide1.termsStackView.isHidden = true
        slide1.termsButton.isHidden = true
        slide1.privacyButton.isHidden = true
        slide1.restoreButton.isHidden = true
        slide1.premiumLabel.isHidden = true
        slide1.enjoyLabel.isHidden = true
        
        let slide2: Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide2.imageView.image = UIImage(named: "barCodeOnboarding")
        slide2.firstLabel.attributedText = NSMutableAttributedString(string: "BARCODES", attributes: [NSAttributedString.Key.kern: 1.92, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        slide2.secondLabel.attributedText = NSMutableAttributedString(string: "Easily scan barcodes", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        slide2.upgradeView.isHidden = true
        slide2.stackView.isHidden = true
        slide2.termsStackView.isHidden = true
        slide2.termsButton.isHidden = true
        slide2.privacyButton.isHidden = true
        slide2.restoreButton.isHidden = true
        slide2.premiumLabel.isHidden = true
        slide2.enjoyLabel.isHidden = true
        
        let slide3: Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide3.imageView.image = UIImage(named: "upgradeOnboarding")
        slide3.imageView.backgroundColor = .mainBlue
        slide3.imageView.contentMode = .scaleAspectFill
        slide3.imageView.cornerRadius(to: 24)
        slide3.firstLabel.text = nil
        slide3.secondLabel.text = nil
        slide3.bottomConstraint.constant = 155
        
        slide3.upgradeView.isHidden = false
        slide3.stackView.isHidden = false
        
        slide3.upgradeView.cornerRadius(to: 16)
        
        slide3.annualView.addLine(position: .LINE_POSITION_BOTTOM, color: UIColor.mainWhite.withAlphaComponent(0.2), width: 0.5)
        slide3.monthlyView.addLine(position: .LINE_POSITION_BOTTOM, color: UIColor.mainWhite.withAlphaComponent(0.2), width: 0.5)
        
        slide3.termsStackView.isHidden = false
        slide3.termsButton.isHidden = false
        slide3.privacyButton.isHidden = false
        slide3.restoreButton.isHidden = false
        slide3.premiumLabel.isHidden = false
        slide3.enjoyLabel.isHidden = false
        
        return [slide1, slide2, slide3]
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
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        print("Tapped close")
        NotificationCenter.default.post(name: dismissNotification, object: nil)
    }
    
    @IBAction func annualTapped(_ sender: Any) {
        print("annual tapped")
        setImagesForButton(tags: [10, 11, 12])
        let userInfo = ["index": 2]
        NotificationCenter.default.post(name: subTypeNotificationIndex, object: nil, userInfo: userInfo)
    }
    
    @IBAction func monthlyTapped(_ sender: Any) {
        print("monthly tapped")
        setImagesForButton(tags: [11, 10, 12])
        let userInfo = ["index": 0]
        NotificationCenter.default.post(name: subTypeNotificationIndex, object: nil, userInfo: userInfo)
    }
    
    @IBAction func weeklyTapped(_ sender: Any) {
        print("weekly tapped")
        setImagesForButton(tags: [12, 10, 11])
        let userInfo = ["index": 1]
        NotificationCenter.default.post(name: subTypeNotificationIndex, object: nil, userInfo: userInfo)
    }
    
    @IBAction func termsTapped(_ sender: Any) {
        print("terms tapped")
        openURL(path: kTermsURL)
    }
    
    @IBAction func privacyTapped(_ sender: Any) {
        print("privacy tapped")
        openURL(path: kPolicyURL)
    }
    
    @IBAction func restoreTapped(_ sender: Any) {
        print("restore tapped")
        NotificationCenter.default.post(name: restoreNotification, object: nil)
    }
}
