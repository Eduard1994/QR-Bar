//
//  QRAnalytics.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 4/25/21.
//

import Foundation
import FirebaseAnalytics

class QRAnalytics {
    static let shared = QRAnalytics()
    
    // MARK: - First Opened
    public func firstOpenedApp(userID: String, success: String) {
        FirebaseAnalytics.Analytics.logEvent("first_opened_app", parameters: [
            "qr_user_id": userID,
            "opened_app_first_time": success
        ])
    }
    
    // MARK: - Onboarding Began
    public func onboardingBegan(userID: String, success: String) {
        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventTutorialBegin, parameters: [
            "qr_user_id": userID,
            "onboarding_began": success
        ])
    }
    
    // MARK: - Onboarding End
    public func onboardingEnd(userID: String, success: String) {
        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventTutorialBegin, parameters: [
            "qr_user_id": userID,
            "onboarding_ended": success
        ])
    }
    
    // MARK: - Next Tapped
    public func nextTapped(userID: String, slidePage: String) {
        FirebaseAnalytics.Analytics.logEvent("next_tapped", parameters: [
            "qr_user_id": userID,
            "next_tapped_on_slide": slidePage
        ])
    }
    
    // MARK: - Tapped to subscribe buttons
    public func tappedToSubscribeButton(userID: String, button: String) {
        FirebaseAnalytics.Analytics.logEvent("subscribe_button_tapped", parameters: [
            "qr_user_id": userID,
            "subscribe_button": button
        ])
    }
    
    // MARK: - Purchase Analytics
    public func purchaseAnalytics(userID: String, paymentType: String, totalPrice: String, success: String, currency: String) {
        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            "qr_user_id": userID,
            AnalyticsParameterPaymentType: paymentType,
            AnalyticsParameterPrice: totalPrice,
            AnalyticsParameterSuccess: "1",
            AnalyticsParameterCurrency: "USD"
        ])
    }
}

