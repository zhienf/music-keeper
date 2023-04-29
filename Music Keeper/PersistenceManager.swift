//
//  PersistenceManager.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import Foundation

//enum PersistenceActionType {
//    case add, remove
//}
//
//enum PersistenceManager
//{
//    static private let defaults = UserDefaults.standard
//    
//    static func retrieveAccessToken() -> String
//    {
//        guard let data = defaults.object(forKey: Key.accessToken) as? Data else { return "" }
//        
//        do {
//            let decoder = JSONDecoder()
//            let token = try decoder.decode(String.self, from: data)
//            return token
//        } catch {
//            return ""
//        }
//    }
//    
//    static func retrieveRefreshToken() -> String
//    {
//        guard let data = defaults.object(forKey: Key.refreshToken) as? Data else { return "" }
//        
//        do {
//            let decoder = JSONDecoder()
//            let token = try decoder.decode(String.self, from: data)
//            return token
//        } catch {
//            return ""
//        }
//    }
//    
//    static func saveAccessToken(accessToken: String) -> Void?
//    {
//        do {
//            let encoder = JSONEncoder()
//            let encodedAccessToken = try encoder.encode(accessToken)
//            defaults.set(encodedAccessToken, forKey: Key.accessToken)
//            return nil
//        } catch {
//            return nil
//        }
//    }
//    
//    static func saveRefreshToken(refreshToken: String) -> Void?
//    {
//        do {
//            let encoder = JSONEncoder()
//            let encodedRefreshToken = try encoder.encode(refreshToken)
//            defaults.set(encodedRefreshToken, forKey: Key.refreshToken)
//            return nil
//        } catch {
//            return nil
//        }
//    }
//}
