//
//  ArtistResult.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

struct ArtistItems: Codable {
    let items: [Artist]
}

struct Artist: Codable {
//    let external_urls: ExternalUrls
//    let followers: Followers
    let genres: [String]?    // ["j-rock", "japanese indie pop"]
    let href: String        // https://api.spotify.com/v1/artists/26ZBeXl5Gqr3TAv2itmyCU
    let id: String          // 26ZBeXl5Gqr3TAv2itmyCU
    let images: [Image]?
    let name: String        // indigo la End
    let popularity: Int?     // 61
    let type: String        // artist
    let uri: String         // spotify:artist:26ZBeXl5Gqr3TAv2itmyCU
}
