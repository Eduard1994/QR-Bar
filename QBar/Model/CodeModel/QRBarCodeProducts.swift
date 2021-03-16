//
//  QRBarCodeProducts.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/3/21.
//

import Foundation
import FirebaseDatabase

var subscriptionPurchases: Set<ProductID> = []

struct Subscriptions {
    var ref: DatabaseReference?
    var key: String?
    let annualProductID: String
//    var annualProductPrice: String
    let monthlyProductID: String
//    var monthlyProductPrice: String
    let weeklyProductID: String
//    var weeklyProductPrice: String
    
    init(annualProductID: String = "", monthlyProductID: String = "", weeklyProductID: String = "") {
        self.ref = nil
        self.key = nil
        self.annualProductID = annualProductID
//        self.annualProductPrice = annualProductPrice
        self.monthlyProductID = monthlyProductID
//        self.monthlyProductPrice = monthlyProductPrice
        self.weeklyProductID = weeklyProductID
//        self.weeklyProductPrice = weeklyProductPrice
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let annualProductID = value["annualProductID"] as? String,
//            let annualProductPrice = value["annualProductPrice"] as? String,
            let monthlyProductID = value["monthlyProductID"] as? String,
//            let monthlyProductPrice = value["monthlyProductPrice"] as? String,
            let weeklyProductID = value["weeklyProductID"] as? String
//            let weeklyProductPrice = value["weeklyProductPrice"] as? String
        else {
            return nil
        }
        
        self.ref = snapshot.ref
        self.key = snapshot.key
        
        self.annualProductID = annualProductID
//        self.annualProductPrice = annualProductPrice
        self.monthlyProductID = monthlyProductID
//        self.monthlyProductPrice = monthlyProductPrice
        self.weeklyProductID = weeklyProductID
//        self.weeklyProductPrice = weeklyProductPrice
    }
}
