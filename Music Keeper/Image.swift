//
//  Image.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 01/05/2023.
//

import Foundation

struct Image: Codable {
    let url: String
    let width: Int
    let height: Int
    
    init(dictionary: [String: Any]) {
        url = dictionary["url"] as? String ?? ""
        width = dictionary["width"] as? Int ?? 0
        height = dictionary["height"] as? Int ?? 0
    }
}
