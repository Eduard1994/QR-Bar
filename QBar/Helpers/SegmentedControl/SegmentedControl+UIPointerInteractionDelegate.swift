//
//  SegmentedControl+UIPointerInteractionDelegate.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit

@available(iOS 13.4, *)
extension SegmentedControl: UIPointerInteractionDelegate {
    public func pointerInteraction(_ interaction: UIPointerInteraction,
                                   regionFor request: UIPointerRegionRequest,
                                   defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        let closestIndexToRequestRegion = closestIndex(toPoint: request.location)
        
        let view = (closestIndexToRequestRegion == index) ? indicatorView : pointerInteractionViews[closestIndexToRequestRegion]
        pointerInteractionView = view
        
        return .init(rect: view.frame)
    }

    public func pointerInteraction(_ interaction: UIPointerInteraction,
                                   styleFor region: UIPointerRegion) -> UIPointerStyle? {
        guard let view = pointerInteractionView else {
            return nil
        }

        if view === indicatorView {
            return .init(effect: .lift(.init(view: view)))
        }
        return .init(effect: .highlight(.init(view: view)))
    }
}

