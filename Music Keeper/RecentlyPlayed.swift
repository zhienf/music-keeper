//
//  RecentlyPlayed.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 01/05/2023.
//

import Foundation

struct RecentlyPlayedItems: Codable {
    let items: [PlayHistory]
}

struct PlayHistory: Codable {
  let played_at: Date?
//  let context: Context?
  let track: Track
}

