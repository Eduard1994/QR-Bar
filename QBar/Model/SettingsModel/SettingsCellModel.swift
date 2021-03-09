//
//  SettingsCellModel.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/28/21.
//

import Foundation

class SettingsCellModel {
    let settingsImageName: String
    let settingsTitle: String
    
    init(_ settings: Settings) {
        settingsTitle = settings.title
        settingsImageName = settings.imageName
    }
}
