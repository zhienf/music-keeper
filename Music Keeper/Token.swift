//
//  Token.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 29/04/2023.
//

import Foundation

struct Token: Codable {
    
    var accessToken: String?
    var refreshToken: String?
    var error: String?
    var errorDescription: String?
}
