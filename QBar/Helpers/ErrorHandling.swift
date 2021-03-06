//
//  ErrorHandling.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/6/21.
//

import UIKit

class ErrorHandling {
    static func showError(title: String? = nil, message: String, controller: UIViewController) {
        controller.alert(title: title, message: message, preferredStyle: .alert, actionTitle: "OK", actionHandler: nil)
    }
}
