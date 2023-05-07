//
//  ExternalURLs.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 06/05/2023.
//

import Foundation

struct ExternalURLs: Codable {
    let spotify: String
     
    init(dictionary: [String: Any]) {
        spotify = dictionary["spotify"] as? String ?? ""
    }
}
