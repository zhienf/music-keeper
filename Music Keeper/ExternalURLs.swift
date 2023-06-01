//
//  ExternalURLs.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 06/05/2023.
//

import Foundation

/**
 A model representing external URLs.

 This struct conforms to the Codable protocol to provide easy encoding and decoding of external URLs from JSON.

 Usage:
 1. Initialize an instance of `ExternalURLs` by passing a dictionary representing the external URLs.
 2. Access the `spotify` property to retrieve the Spotify URL.
 */
struct ExternalURLs: Codable {
    let spotify: String
     
    init(dictionary: [String: Any]) {
        spotify = dictionary["spotify"] as? String ?? ""
    }
}
