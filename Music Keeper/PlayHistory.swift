//
//  PlayHistory.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 01/05/2023.
//

import Foundation

/**
 A model representing a play history entry.

 This struct conforms to the Codable protocol to provide easy encoding and decoding of play history objects from JSON.

 Usage:
 1. Initialize an instance of `PlayHistory` by passing a dictionary representing the play history entry.
 2. Access the `track` property to get the associated track information.
 */
struct PlayHistory: Codable {
    // The track the user listened to.
    let track: Track
    
    init(dictionary: [String: Any]) {
        if let trackDictionary = dictionary["track"] as? [String: Any] {
            track = Track(dictionary: trackDictionary)
        } else {
            track = Track(dictionary: [:])
        }
    }
}
