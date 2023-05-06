//
//  Album.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

struct Album: Codable {
    let external_urls: ExternalURLs
    let id: String
    let images: [Image]
    let name: String
    let release_date: String
    let uri: String
    let genres: [String]
    let popularity: Int
    let artists: [Artist]
    
    init(dictionary: [String: Any]) {
        external_urls = ExternalURLs(dictionary: dictionary["external_urls"] as? [String: Any] ?? [:])
        id = dictionary["id"] as? String ?? ""
        images = (dictionary["images"] as? [[String: Any]])?.map { Image(dictionary: $0) } ?? []
        name = dictionary["name"] as? String ?? ""
        release_date = dictionary["release_date"] as? String ?? ""
        uri = dictionary["uri"] as? String ?? ""
        genres = dictionary["genres"] as? [String] ?? []
        popularity = dictionary["popularity"] as? Int ?? 0
        artists = (dictionary["artists"] as? [[String: Any]])?.map { Artist(dictionary: $0) } ?? []
    }
}
