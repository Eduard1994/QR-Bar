//
//  String+extension.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/2/21.
//

import Foundation

extension String {
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MMM-d"
        let date = formatter.date(from: self)
        return date
    }
}
