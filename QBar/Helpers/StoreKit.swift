//
//  StoreKit.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/7/21.
//

import UIKit
import StoreKit
import SwiftyStoreKit

class StoreKit {
    static func getInfo(_ purchases: Set<String>, completion: @escaping (RetrieveResults) -> Void) {

        NetworkActivityIndicatorManager.networkOperationStarted()
        SwiftyStoreKit.retrieveProductsInfo(purchases) { result in
            NetworkActivityIndicatorManager.networkOperationFinished()

            completion(result)
        }
    }

    static func purchase(_ purchase: String, atomically: Bool, completion: @escaping (PurchaseResult) -> Void) {

        NetworkActivityIndicatorManager.networkOperationStarted()
        SwiftyStoreKit.purchaseProduct(purchase, atomically: atomically) { result in
            NetworkActivityIndicatorManager.networkOperationFinished()

            if case .success(let purchase) = result {
                let downloads = purchase.transaction.downloads
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                }
                // Deliver content from server, then:
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            }
            completion(result)
        }
    }
    
    static func restorePurchases(completion: @escaping (RestoreResults) -> Void) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            NetworkActivityIndicatorManager.networkOperationFinished()

            for purchase in results.restoredPurchases {
                let downloads = purchase.transaction.downloads
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                } else if purchase.needsFinishTransaction {
                    // Deliver content from server, then:
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            }
            completion(results)
        }
    }
    
    static func verifyReceipt(completion: @escaping (VerifyReceiptResult) -> Void) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        verifyReceiptFrom { result in
            NetworkActivityIndicatorManager.networkOperationFinished()
            completion(result)
        }
    }
    
    static func verifySubscriptions(_ purchases: Set<ProductID>, completion: @escaping (VerifyReceiptResult?, VerifySubscriptionResult?, Set<String>?) -> Void) {
        
        NetworkActivityIndicatorManager.networkOperationStarted()
        verifyReceiptFrom { result in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            switch result {
            case .success(let receipt):
                let productIds = Set(purchases.map { $0 })
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(productIds: productIds, inReceipt: receipt)
            completion(nil, purchaseResult, productIds)
            case .error:
            completion(result, nil, nil)
            }
        }
    }
    
    private static func verifyReceiptFrom(completion: @escaping (VerifyReceiptResult) -> Void) {
        
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: "your-shared-secret")
        SwiftyStoreKit.verifyReceipt(using: appleValidator, completion: completion)
    }
    
}
