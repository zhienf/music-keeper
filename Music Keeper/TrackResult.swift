//
//  TrackResult.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

class TrackResult: NSObject, Codable {
    let tracks: [Track]

    enum CodingKeys: String, CodingKey {
        case tracks
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tracks = try container.decode([Track].self, forKey: .tracks)
    }
}

class Track: Codable {
    let name: String
    let id: String
    let uri: String
    let popularity: Int
    let album: Album

    enum CodingKeys: String, CodingKey {
        case name
        case id
        case uri
        case popularity
        case album
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        id = try container.decode(String.self, forKey: .id)
        uri = try container.decode(String.self, forKey: .uri)
        popularity = try container.decode(Int.self, forKey: .popularity)
        album = try container.decode(Album.self, forKey: .album)
    }
}

class Image: Codable {
    let url: String
    let width: Int?
    let height: Int?

    enum CodingKeys: String, CodingKey {
        case url
        case width
        case height
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
    }
}

