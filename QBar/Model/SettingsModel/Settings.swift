//
//  Settings.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/28/21.
//

import Foundation

struct Settings {
    var title: String
    var imageName: String
    
    init(title: String, imageName: String) {
        self.title = title
        self.imageName = imageName
    }
    
    static func settings() -> [Settings] {
        return [
            Settings(title: "Restore purchase", imageName: "restoreImage"),
            Settings(title: "Contact support", imageName: "supportImage"),
            Settings(title: "Privacy policy", imageName: "privacyImage"),
            Settings(title: "Terms of use", imageName: "termsImage"),
            Settings(title: "Share App", imageName: "shareImage")
        ]
    }
}
