//
//  AlbumResult.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

class AlbumResult: NSObject, Codable {
    let albums: [Album]
    
    enum CodingKeys: String, CodingKey {
        case albums
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        albums = try container.decode([Album].self, forKey: .albums)
    }
    
//    let id: String
//    let name: String
//    let artistName: String
//    let imageURL: URL?
//
//    init?(dictionary: [String: Any]) {
//        guard let id = dictionary["id"] as? String,
//            let name = dictionary["name"] as? String,
//            let artistDictionary = dictionary["artists"] as? [[String: Any]],
//            let artistName = artistDictionary.first?["name"] as? String
//            else { return nil }
//
//        self.id = id
//        self.name = name
//        self.artistName = artistName
//        if let images = dictionary["images"] as? [[String: Any]],
//            let urlString = images.first?["url"] as? String,
//            let imageURL = URL(string: urlString) {
//            self.imageURL = imageURL
//        } else {
//            self.imageURL = nil
//        }
//    }
}

class Album: Codable {
    let name: String
    let id: String
    let uri: String
    let images: [Image]

    enum CodingKeys: String, CodingKey {
        case name
        case id
        case uri
        case images
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        id = try container.decode(String.self, forKey: .id)
        uri = try container.decode(String.self, forKey: .uri)
        images = try container.decode([Image].self, forKey: .images)
    }
}
