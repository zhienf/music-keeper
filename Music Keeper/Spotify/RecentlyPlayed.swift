//
//  RecentlyPlayed.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 01/05/2023.
//

import Foundation

struct RecentlyPlayed: Codable {
  let played_at: Date
  let context: String
  let track: Track
}
