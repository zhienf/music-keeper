//
//  SearchResult.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import Foundation

struct SearchResults {
    var tracks: TrackResult?
    var artists: ArtistResult?
    var albums: AlbumResult?
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
        tracks = try container.decodeIfPresent(TrackResult.self, forKey: .tracks)
        artists = try container.decodeIfPresent(ArtistResult.self, forKey: .artists)
        albums = try container.decodeIfPresent(AlbumResult.self, forKey: .albums)
        // Decode additional search result types as needed
    }
}



