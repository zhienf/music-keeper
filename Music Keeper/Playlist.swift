//
//  Playlist.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 15/05/2023.
//

import Foundation

struct Playlist: Codable {
    let images: [Image]
    let name: String
    let tracks: PlaylistTracks
    let uri: String
    let id: String
    
    init(dictionary: [String: Any]) {
        images = (dictionary["images"] as? [[String: Any]])?.map { Image(dictionary: $0) } ?? []
        name = dictionary["name"] as? String ?? ""
        tracks = PlaylistTracks(dictionary: dictionary["tracks"] as? [String: Any] ?? [:])
        uri = dictionary["uri"] as? String ?? ""
        id = dictionary["id"] as? String ?? ""
    }
}

struct PlaylistTracks: Codable {
    let href: String
    let total: Int
    
    init(dictionary: [String: Any]) {
        href = dictionary["href"] as? String ?? ""
        total = dictionary["total"] as? Int ?? 0
    }
}
