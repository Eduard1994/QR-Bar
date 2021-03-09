//
//  Code.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import Foundation
import FirebaseDatabase

struct TabbedCodes<T> {
    var tab: Tab.RawValue
    var codes: [T]
    var collapsed: Bool
    
    init(tab: Tab.RawValue, codes: [T], collapsed: Bool = false) {
        self.tab = tab
        self.codes = codes
        self.collapsed = collapsed
    }
}

struct Code {
    let ref: DatabaseReference?
    let key: String?
    var id: String
    var userID: String
    var title: String
    var code: String
    var type: String
    var tab: Tab.RawValue
    var date: String
    var imageName: String
    
    init(id: String = "", userID: String = "", title: String = "", code: String = "", type: String = "", tab: Tab.RawValue = Tab.History.rawValue, date: String = "", imageName: String = "") {
        self.ref = nil
        self.key = nil
        self.id = id
        self.userID = userID
        self.title = title
        self.code = code
        self.type = type
        self.tab = tab
        self.date = date
        self.imageName = imageName
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let id = value["id"] as? String,
            let userID = value["userID"] as? String,
            let title = value["title"] as? String,
            let code = value["code"] as? String,
            let type = value["type"] as? String,
            let tab = value["tab"] as? Tab.RawValue,
            let date = value["date"] as? String,
            let imageName = value["imageName"] as? String
        else {
            return nil
        }
        
        self.ref = snapshot.ref
        self.key = snapshot.key
        
        self.id = id
        self.userID = userID
        self.title = title
        self.code = code
        self.type = type
        self.tab = tab
        self.date = date
        self.imageName = imageName
    }
    
    func toAnyObject() -> Any {
        return [
            "id": id,
            "userID": userID,
            "title": title,
            "code": code,
            "type": type,
            "tab": tab,
            "date": date,
            "imageName": imageName
        ]
    }
}
