//
//  Token.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 29/04/2023.
//

import Foundation

/**
 A model representing a token retrieved after user authorization.
 
 Usage:
 1. Access token is required to make API requests to Spotify.
 2. Refresh token is required to get a new access token after its expiration.
 */
struct Token: Codable {
    var accessToken: String?
    var refreshToken: String?
    var error: String?
    var errorDescription: String?
}
