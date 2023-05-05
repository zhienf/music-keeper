//
//  Player.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 30/04/2023.
//

import Foundation

struct PlayerState: Codable {
//    let device: Device
    let shuffle_state: Bool
    let repeat_state: String
    let timestamp: Int
//    let context: Context
    let progress_ms: Int
    let item: Track
    let currently_playing_type: String
//    let actions: Actions
    let is_playing: Bool
}
