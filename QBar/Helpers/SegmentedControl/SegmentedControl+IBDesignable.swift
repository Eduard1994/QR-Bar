//
//  SegmentedControl+IBDesignable.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit

extension SegmentedControl {
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setDefaultColorsIfNeeded()
    }
    open override func awakeFromNib() {
        super.awakeFromNib()
        setDefaultColorsIfNeeded()
    }
    
    private func setDefaultColorsIfNeeded() {
        if #available(iOS 13.0, *) {
            if backgroundColor == UIColor.systemBackground || backgroundColor == nil {
                backgroundColor = .mainBlack
            }
            if indicatorViewBackgroundColor == UIColor.systemBackground || indicatorViewBackgroundColor == nil {
                indicatorViewBackgroundColor = .clear
            }
        } else {
            if backgroundColor == nil {
                backgroundColor = .mainBlack
            }
            if indicatorViewBackgroundColor == nil {
                indicatorViewBackgroundColor = .mainBlue
            }
        }
    }
}
