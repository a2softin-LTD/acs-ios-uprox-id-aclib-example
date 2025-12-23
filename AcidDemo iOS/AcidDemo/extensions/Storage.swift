//
//  Storage.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import Foundation

@propertyWrapper
struct Storage<T: Codable> {
    
    enum StorageType {
        case base
        case shared(suite: String)
    }
    
    private let key: String
    private let defaultValue: T
    private let type: StorageType

    //"group.org.a2softin.acid"
    
    init(key: String,
         defaultValue: T,
         shared: StorageType) {
        self.key = key
        self.defaultValue = defaultValue
        self.type = shared
    }

    var wrappedValue: T {
        get {
            switch type {
            case .base:
                guard let data = UserDefaults.standard.object(forKey: key) as? Data else {
                    return defaultValue
                }
                let value = try? JSONDecoder().decode(T.self, from: data)
                return value ?? defaultValue
            case .shared(let suite):
                if let userDefaults = UserDefaults(suiteName: suite) {
                    guard let data = userDefaults.object(forKey: key) as? Data else {
                        return defaultValue
                    }
                    let value = try? JSONDecoder().decode(T.self, from: data)
                    return value ?? defaultValue
                }
                return defaultValue
            }
        }
        nonmutating set {
            
            switch type {
            case .base:
                let data = try? JSONEncoder().encode(newValue)
                UserDefaults.standard.set(data, forKey: key)
            case .shared(let suite):
                if let userDefaults = UserDefaults(suiteName: suite) {
                    let data = try? JSONEncoder().encode(newValue)
                    userDefaults.set(data, forKey: key)
                    userDefaults.synchronize()
                }
            }
        }
    }
}

extension Storage.StorageType: Sendable {}
extension Storage: Sendable where T: Sendable {}
