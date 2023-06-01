//
//  Album.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

/**
 A model representing an album.

 This struct conforms to the Codable protocol to provide easy encoding and decoding of album objects from JSON.

 Usage:
 1. Initialize an instance of `Album` by passing a dictionary representing the album's properties.
 2. Access the properties of the album as needed.
 */
struct Album: Codable {
    let external_urls: ExternalURLs
    let id: String
    let images: [Image]
    let name: String
    let release_date: String
    let uri: String
    let artists: [Artist]
    
    init(dictionary: [String: Any]) {
        external_urls = ExternalURLs(dictionary: dictionary["external_urls"] as? [String: Any] ?? [:])
        id = dictionary["id"] as? String ?? ""
        images = (dictionary["images"] as? [[String: Any]])?.map { Image(dictionary: $0) } ?? []
        name = dictionary["name"] as? String ?? ""
        release_date = dictionary["release_date"] as? String ?? ""
        uri = dictionary["uri"] as? String ?? ""
        artists = (dictionary["artists"] as? [[String: Any]])?.map { Artist(dictionary: $0) } ?? []
    }
}
