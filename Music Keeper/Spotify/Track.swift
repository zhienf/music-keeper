//
//  Track.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

/**
 A model representing a track.

 This struct conforms to the Codable protocol to provide easy encoding and decoding of track objects from JSON.

 Usage:
 1. Initialize an instance of `Track` by passing a dictionary representing the track's properties.
 2. Access the properties of the track as needed.
 */
struct Track: Codable {
    let album: Album
    let artists: [Artist]
    let external_urls: ExternalURLs
    let id: String
    let name: String
    let popularity: Int
    let preview_url: String
    let uri: String
    let genres: [String]
    
    init(dictionary: [String: Any]) {
        if let albumDictionary = dictionary["album"] as? [String: Any] {
            album = Album(dictionary: albumDictionary)
        } else {
            album = Album(dictionary: [:])
        }

        artists = (dictionary["artists"] as? [[String: Any]])?.compactMap { Artist(dictionary: $0) } ?? []
        external_urls = ExternalURLs(dictionary: dictionary["external_urls"] as? [String: Any] ?? [:])
        id = dictionary["id"] as? String ?? ""
        name = dictionary["name"] as? String ?? ""
        popularity = dictionary["popularity"] as? Int ?? 0
        preview_url = dictionary["preview_url"] as? String ?? ""
        uri = dictionary["uri"] as? String ?? ""
        genres = dictionary["genres"] as? [String] ?? []
    }
}
