//
//  Image.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 01/05/2023.
//

import Foundation

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
