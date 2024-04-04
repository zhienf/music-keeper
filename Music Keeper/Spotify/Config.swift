//
//  Config.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 04/04/2024.
//

import Foundation

class Config {
    private let clientID        = "***REMOVED***"
    private let clientSecret    = "***REMOVED***"
    private let encodedID  = "***REMOVED***"
    
    func getClientID() -> String {
        return clientID
    }
    
    func getClientSecret() -> String {
        return clientSecret
    }
    
    func getEncodedID() -> String {
        return encodedID
    }
}
