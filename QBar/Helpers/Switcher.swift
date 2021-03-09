//
//  Switcher.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/26/21.
//

import UIKit

let kStatus = "status"
let kOnboardingStatus = "onboardingStatus"
let kCameraStatus = "cameraStatus"

class Switcher {
    static func updateRootVC(showLaunch: Bool = true) {
        let status = UserDefaults.standard.bool(forKey: kStatus)
        var rootVC: UIViewController?
        
        let launchView: UIView = {
            let views = Bundle.main.loadNibNamed("LaunchView", owner: nil, options: nil)
            let launch = views![0] as! UIView
            launch.translatesAutoresizingMaskIntoConstraints = false
            return launch
        }()
        
        func showLaunchView() {
            rootVC?.view.addSubview(launchView)
            rootVC?.view.pinAllEdges(to: launchView)
        }
        
        func removeLaunchView(animated: Bool) {
            UIView.animate(withDuration: animated ? 0.5 : 0, animations: {
                launchView.alpha = 0
            }, completion: { (completion) in
                launchView.removeFromSuperview()
            })
        }
        
        if status == true {
            rootVC = MainSegmentedViewController.instantiate(from: .Main, with: MainSegmentedViewController.typeName)
        } else {
            rootVC = PrivacyViewController.instantiate(from: .Onboarding, with: PrivacyViewController.typeName)
        }
        
        if showLaunch {
            showLaunchView()
            DispatchQueue.main.after(1.5) {
                removeLaunchView(animated: true)
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = rootVC
        appDelegate.window?.backgroundColor = .mainWhite
        appDelegate.window?.makeKeyAndVisible()
    }
}


