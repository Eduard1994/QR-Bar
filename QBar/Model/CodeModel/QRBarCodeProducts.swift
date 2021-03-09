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
    let monthlyProductID: String
    let weeklyProductID: String
    
    init(annualProductID: String = "", monthlyProductID: String = "", weeklyProductID: String = "") {
        self.ref = nil
        self.key = nil
        self.annualProductID = annualProductID
        self.monthlyProductID = monthlyProductID
        self.weeklyProductID = weeklyProductID
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let annualProductID = value["annualProductID"] as? String,
            let monthlyProductID = value["monthlyProductID"] as? String,
            let weeklyProductID = value["weeklyProductID"] as? String
        else {
            return nil
        }
        
        self.ref = snapshot.ref
        self.key = snapshot.key
        
        self.annualProductID = annualProductID
        self.monthlyProductID = monthlyProductID
        self.weeklyProductID = weeklyProductID
    }
}
