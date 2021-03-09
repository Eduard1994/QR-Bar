//
//  SegmentedControl+PredefinedStyles.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit

public extension SegmentedControl {
     class func appleStyled(frame: CGRect, titles: [String]) -> SegmentedControl {
        let control = SegmentedControl(
            frame: frame,
            segments: LabelSegment.segments(withTitles: titles),
            options: [.cornerRadius(8)])
        control.indicatorView.layer.shadowColor = UIColor.black.cgColor
        control.indicatorView.layer.shadowOpacity = 0.1
        control.indicatorView.layer.shadowOffset = CGSize(width: 1, height: 1)
        control.indicatorView.layer.shadowRadius = 2
        
        return control
    }
}
