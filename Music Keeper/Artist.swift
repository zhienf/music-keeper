//
//  ArtistResult.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

struct ArtistItem: Codable {
    let items: [Artist]
}

struct Artist: Codable {
//    let external_urls: ExternalUrls
//    let followers: Followers
    let genres: [String]    // ["j-rock", "japanese indie pop"]

    let href: String        // https://api.spotify.com/v1/artists/26ZBeXl5Gqr3TAv2itmyCU
    let id: String          // 26ZBeXl5Gqr3TAv2itmyCU
    let images: [Image]
    let name: String        // indigo la End
    let popularity: Int     // 61
    let type: String        // artist
    let uri: String         // spotify:artist:26ZBeXl5Gqr3TAv2itmyCU
}

//class ArtistResult: NSObject, Codable {
//    let artists: [Artist]
//
//    enum CodingKeys: String, CodingKey {
//        case artists
//    }
//
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        artists = try container.decode([Artist].self, forKey: .artists)
//    }
    
//    let id: String
//    let name: String
//    let imageURL: URL?
//
//    init?(dictionary: [String: Any]) {
//        guard let id = dictionary["id"] as? String,
//            let name = dictionary["name"] as? String
//            else { return nil }
//
//        self.id = id
//        self.name = name
//        if let images = dictionary["images"] as? [[String: Any]],
//            let urlString = images.first?["url"] as? String,
//            let imageURL = URL(string: urlString) {
//            self.imageURL = imageURL
//        } else {
//            self.imageURL = nil
//        }
//    }
//}

//class Artist: Codable {
//    let name: String
//    let id: String
//    let uri: String
//    let images: [Image]
//
//    enum CodingKeys: String, CodingKey {
//        case name
//        case id
//        case uri
//        case images
//    }
//
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        name = try container.decode(String.self, forKey: .name)
//        id = try container.decode(String.self, forKey: .id)
//        uri = try container.decode(String.self, forKey: .uri)
//        images = try container.decode([Image].self, forKey: .images)
//    }
//}
