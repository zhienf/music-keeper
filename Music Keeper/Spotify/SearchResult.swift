//
//  SearchResult.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import Foundation

struct SearchResults {
//    var tracks: TrackItem?
    var artists: ArtistItems?
    var albums: AlbumItem?
    // Add additional search result types as needed
    
    enum CodingKeys: String, CodingKey {
        case tracks
        case artists
        case albums
        // Add additional search result types as needed
    }
}

extension SearchResults: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
//        tracks = try container.decodeIfPresent(TrackItem.self, forKey: .tracks)
        artists = try container.decodeIfPresent(ArtistItems.self, forKey: .artists)
        albums = try container.decodeIfPresent(AlbumItem.self, forKey: .albums)
        // Decode additional search result types as needed
    }
}



