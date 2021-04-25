//
//  PrivacyViewController.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit

class PrivacyViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var bulletedLabel: UILabel!
    
    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    // MARK: - Override properties
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            // Fallback on earlier versions
            return .default
        }
    }
    
    // MARK: - Functions
    private func configureView() {
        acceptButton.cornerRadius(to: 20)
        
        let strings = ["Device-specific information like OS version and hardware model.", "Payment information and optional email, when you purchase a paid plan. We do not keep logs of your online activities and never associate any domains or applications that you use with you, your device, IP address, or email.", "For a better experience, while using our Service, we may require you to provide us with certain personally identifiable information. The information that we request will be retained by us and used as described in privacy policy."]
        
        bulletedLabel.attributedText = bulletedList(strings: strings, textColor: .mainBlack, font: .sfProText(ofSize: 15, style: .regular), bulletColor: .mainBlue, bulletSize: .mainBullet)
        
        // Firebase Analytics
        DispatchQueue.global(qos: .default).async {
            Service().checkUser { (user, error) in
                if let user = user, error == nil {
                    print(user)
                    DispatchQueue.main.async {
                        QRAnalytics.shared.firstOpenedApp(userID: user.uid, success: "1")
                    }
                } else {
                    QRAnalytics.shared.firstOpenedApp(userID: "user.uid", success: "0")
                    print(error!.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - IBActions
    @IBAction func acceptTapped(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: kStatus)
        Switcher.shared.updateRootVC(showLaunch: false)
    }
}
