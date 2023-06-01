//
//  Playlist.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 15/05/2023.
//

import Foundation

/**
 A model representing a playlist.

 This struct conforms to the Codable protocol to provide easy encoding and decoding of playlist data from JSON.

 Usage:
 1. Initialize an instance of `Playlist` by passing a dictionary representing the playlist data.
 2. Access the properties to retrieve playlist details such as images, name, tracks, URI, and ID.
 */
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

/*
 A model representing playlist tracks.

 This struct conforms to the Codable protocol to provide easy encoding and decoding of playlist tracks data from JSON.

 Usage:
 1. Initialize an instance of `PlaylistTracks` by passing a dictionary representing the playlist tracks data.
 2. Access the property 'total' to retrieve playlist track count.
 */
struct PlaylistTracks: Codable {
    let total: Int
    
    init(dictionary: [String: Any]) {
        total = dictionary["total"] as? Int ?? 0
    }
}
