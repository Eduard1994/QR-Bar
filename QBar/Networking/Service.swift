//
//  Service.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 3/1/21.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Alamofire

enum PremiumSubscriptionType: String {
    case annual = "annualProduct"
    case monthly = "monthlyProduct"
    case weekly = "weeklyProduct"
}

enum FirebaasePath: String {
    case codes = "codes"
    case users = "users"
    case premiumTitles = "premiumTitles"
    case premiumSubscriptions = "premiumSubscriptions"
}

enum NetworkError: Error {
    case unowned(description: String)
    case noInternet
    
    var localizedDescription: String {
        switch self {
        case .unowned(description: let description): return description
        case .noInternet: return "Check internet connectivity and try again!"
        }
    }
}

let kUserDataKey = "current_user"

class Service {
    // MARK: - Properties
    let reference = Database.database().reference(withPath: FirebaasePath.codes.rawValue)
    let premiumTitlesReference = Database.database().reference(withPath: FirebaasePath.premiumTitles.rawValue)
    let premiumSubscriptionsReference = Database.database().reference(withPath: FirebaasePath.premiumSubscriptions.rawValue)
    let usersReference = Database.database().reference(withPath: FirebaasePath.users.rawValue)
    
    let path = URL(fileURLWithPath: NSTemporaryDirectory())
    
    let queue = DispatchQueue.global(qos: .userInitiated)
    let group = DispatchGroup()
    
    var isConnectedToInternet: Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
    // MARK: - Check Firebase User
    func checkUser(completion: @escaping (User?, NetworkError?) -> Void) {
        if isConnectedToInternet {
            let disk = DiskStorage(path: path)
            let storage = CodableStorage(storage: disk)
            
            Auth.auth().signInAnonymously { (authResult, error) in
                if let error = error {
                    completion(nil, .unowned(description: error.localizedDescription))
                    return
                }
                
                guard let user = authResult?.user else {
                    return
                }
                
                let currentUser = User(authData: user)
                
                do {
                    try storage.save(currentUser, for: kUserDataKey)
                } catch {
                    print(error.localizedDescription)
                }
                
                let uniqueDeviceID = UIDevice.current.identifierForVendor!.uuidString
                
                let currentUserReference = self.usersReference.child(user.uid)
                currentUserReference.setValue(uniqueDeviceID)
                
                print("User is = \(uniqueDeviceID), \(currentUser.uid)")
                
                completion(currentUser, nil)
            }
        } else {
            completion(nil, .noInternet)
        }
    }
    
    // MARK: - Getting Subscriptions
    func getSubscriptions(completion: @escaping (Set<ProductID>?, NetworkError?) -> Void) {
        if isConnectedToInternet {
            premiumSubscriptionsReference.observe(.value) { (snapshot) in
                if let subscriptions = Subscriptions(snapshot: snapshot) {
                    let annualProductID = subscriptions.annualProductID
                    let monthlyProductID = subscriptions.monthlyProductID
                    let weeklyProductID = subscriptions.weeklyProductID
                    
                    let productIDs: Set<ProductID> = [annualProductID, monthlyProductID, weeklyProductID]
                    
                    completion(productIDs, nil)
                }
            }
        } else {
            completion(nil, .noInternet)
        }
    }
    
    // MARK: - Getting Onboarding Titles
    func getOnboardingTitles(for premium: PremiumTab.RawValue, completion: @escaping(OnboardingTitle?, NetworkError?) -> Void) {
        if isConnectedToInternet {
            premiumTitlesReference.child(premium).observe(.value) { (snapshot) in
                if let title = OnboardingTitle(snapshot: snapshot) {
                    completion(title, nil)
                }
            }
        } else {
            completion(nil, .noInternet)
        }
    }
    
    // MARK: - Getting Subscribe Titles
    func getSubscribeTitles(for premium: PremiumTab.RawValue, completion: @escaping(SubscribeTitle?, NetworkError?) -> Void) {
        if isConnectedToInternet {
            premiumTitlesReference.child(premium).observe(.value) { (snapshot) in
                if let title = SubscribeTitle(snapshot: snapshot) {
                    completion(title, nil)
                }
            }
        } else {
            completion(nil, .noInternet)
        }
    }
    
    // MARK: - Getting Settings Titles
    func getSettingsTitles(for premium: PremiumTab.RawValue, completion: @escaping(SettingsTitle?, NetworkError?) -> Void) {
        if isConnectedToInternet {
            premiumTitlesReference.child(premium).observe(.value) { (snapshot) in
                if let title = SettingsTitle(snapshot: snapshot) {
                    completion(title, nil)
                }
            }
        } else {
            completion(nil, .noInternet)
        }
    }
    
    // MARK: - Getting codes from Firebase
    func getCodes(for tab: Tab.RawValue, userID: String, completion: @escaping ([Code]?, NetworkError?) ->()) {
        if isConnectedToInternet {
            reference.child(userID).child(tab).observe(.value) { (snapshot) in
                var newCodes: [Code] = []
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot {
                        if let code = Code(snapshot: snapshot) {
                            newCodes.insert(code, at: 0)
                        }
                    }
                }
                completion(newCodes, nil)
            }
        } else {
            completion(nil, .noInternet)
        }
    }
    
    func tabbedCodes(for tabs: [Tab.RawValue], userID: String, completion: @escaping ([TabbedCodes<Code>]) -> ()) {} // Will be updated soon
    
    // MARK: - Adding code to Firebase
    func addNewCode(code: Code, at tab: Tab.RawValue, completion: @escaping (([String : [String : Any]]?, NetworkError?) -> Void)) {
        if isConnectedToInternet {
            guard  let key = reference.childByAutoId().key else { return }
            let post = [
                "id": key,
                "userID": code.userID,
                "title": code.title,
                "code": code.code,
                "type": code.type,
                "tab": tab,
                "date": code.date,
                "imageName": code.imageName
            ] as [String: Any]
            let childUpdates = [key: post]
            updateValues(at: tab, userID: code.userID, childUpdates)
            completion(childUpdates, nil)
        } else {
            completion(nil, .noInternet)
        }
    }
    
    func updateValue(at tab: Tab.RawValue, code: Code, userID: String, completion: @escaping ((NetworkError?) -> ())) {
        if isConnectedToInternet {
            let values = [
                "id": code.id,
                "userID": code.userID,
                "title": code.title,
                "code": code.code,
                "type": code.type,
                "tab": code.tab,
                "date": code.date,
                "imageName": code.imageName
            ] as [String: Any]
            reference.child(userID).child(tab).child(code.id).updateChildValues(values) { (error, reference) in
                if error == nil {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        } else {
            completion(.noInternet)
        }
    }
    
    private func updateValues(at tab: Tab.RawValue, userID: String, _ values: [String : [String : Any]]) {
        reference.child(userID).child(tab).updateChildValues(values)
    }
    
    // MARK: - Removing code from Firebase
    func removeCode(at tab: Tab.RawValue, withID: String, userID: String, imageName: String?, completion: @escaping (NetworkError?) -> Void) {
        if isConnectedToInternet {
            reference.child(userID).child(tab).child(withID).removeValue { (error, reference) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                print(reference)
                if let imageName = imageName {
                    print(imageName)
                    completion(nil)
                    //                self.storageReference.child(imageName).delete { (error) in
                    //                    if let error = error {
                    //                        print(error.localizedDescription)
                    //                    }
                    //                }
                }
            }
        } else {
            completion(.noInternet)
        }
    }
    
    // MARK: - Uploading Image to Firebase
    func uploadImage(with data: Data, fileName: String, completion: @escaping (URL?, NetworkError?) -> Void) {} // Will be updated soon
}

