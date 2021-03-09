//
//  User.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/2/21.
//

import Foundation
import Firebase

struct User: Codable {
    let uid: String
    
    init(authData: Firebase.User) {
        uid = authData.uid
    }
    
    enum CodingKeys: String, CodingKey {
        case uid
    }
}

