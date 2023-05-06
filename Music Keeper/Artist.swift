//
//  Artist.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

struct Artist: Codable {
    let external_urls: ExternalURLs
    let genres: [String]    // ["j-rock", "japanese indie pop"]
    let id: String          // 26ZBeXl5Gqr3TAv2itmyCU
    let images: [Image]
    let name: String        // indigo la End
    let popularity: Int     // 61
    let uri: String         // spotify:artist:26ZBeXl5Gqr3TAv2itmyCU
    
    init(dictionary: [String: Any]) {
        external_urls = ExternalURLs(dictionary: dictionary["external_urls"] as? [String: Any] ?? [:])
        genres = dictionary["genres"] as? [String] ?? []
        id = dictionary["id"] as? String ?? ""
        images = (dictionary["images"] as? [[String: Any]])?.map { Image(dictionary: $0) } ?? []
        name = dictionary["name"] as? String ?? ""
        popularity = dictionary["popularity"] as? Int ?? 0
        uri = dictionary["uri"] as? String ?? ""
    }
}
