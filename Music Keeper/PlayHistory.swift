//
//  PlayHistory.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 01/05/2023.
//

import Foundation

struct PlayHistory: Codable {
    let track: Track
    
    init(dictionary: [String: Any]) {
        if let trackDictionary = dictionary["track"] as? [String: Any] {
            track = Track(dictionary: trackDictionary)
        } else {
            track = Track(dictionary: [:])
        }
    }
}
