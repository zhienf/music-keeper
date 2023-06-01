//
//  Image.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 01/05/2023.
//

import Foundation

/**
 A model representing an image.

 This struct conforms to the Codable protocol to provide easy encoding and decoding of image objects from JSON.

 Usage:
 1. Initialize an instance of `Image` by passing a dictionary representing the image's properties.
 2. Access the properties of the image as needed.
 */
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
