//
//  AppDelegate.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/26/21.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var storeKit: StoreKit!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        setupIAP()
        
        Switcher.shared.updateRootVC()
        
        return true
    }
    
    // MARK: - Setup IAP
    func setupIAP() {
        storeKit = StoreKit.shared
        storeKit.setupIAP()
    }
}

