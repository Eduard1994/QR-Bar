//
//  Functions.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/1/21.
//
import UIKit
import AVFoundation

/**
 Returns image with a given name from the resource bundle.
 - Parameter name: Image name.
 - Returns: An image.
 */
func imageNamed(_ name: String) -> UIImage {
    let cls = QRBarcodeScannerViewController.self
    var bundle = Bundle(for: cls)
    let traitCollection = UITraitCollection(displayScale: 3)
    
    if let resourceBundle = bundle.resourcePath.flatMap({ Bundle(path: $0 + "/QBar.bundle") }) {
        bundle = resourceBundle
    }
    
    guard let image = UIImage(named: name, in: bundle, compatibleWith: traitCollection) else {
        return UIImage()
    }
    
    return image
}

/**
 Returns localized string using localization resource bundle.
 - Parameter name: Image name.
 - Returns: An image.
 */
func localizedString(_ key: String) -> String {
    if let path = Bundle(for: QRBarcodeScannerViewController.self).resourcePath,
       let resourceBundle = Bundle(path: path + "/Localization.bundle") {
        return resourceBundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }
    return key
}

/// Checks if the app is running in Simulator.
var isSimulatorRunning: Bool = {
    #if swift(>=4.1)
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
    #else
    #if (arch(i386) || arch(x86_64)) && os(iOS)
    return true
    #else
    return false
    #endif
    #endif
}()

