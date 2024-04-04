//
//  NetworkManager.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//
// References:
// 1) https://developer.spotify.com/documentation/web-api
// 2) https://youtu.be/uyqPBNJ33jw (How To Use Spotify's API In Swift)

import UIKit
import StoreKit
import CoreData

/**
 A class that handles all API requests to Spotify.
 */
class NetworkManager {
    
    // A singleton instance of NetworkManager
    static let shared   = NetworkManager()
    
    private let offset          = "0"
    private let clientID        = Config.getClientID()
    private let clientSecret    = Config.getClientSecret()
    
    // Base64 Encoded Client ID:Client secret
    private let encodedID = Config.getEncodedID()
    
    private let redirectUrl = "https://www.google.com"
    
    weak var databaseController: DatabaseProtocol?
    
    
    private init() {
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
    }
    
    func authoriseUser(with code: String, completion: @escaping (String?) -> Void) {
        /**
         Gets access token after user allows authorisation.
         */
        var bodyComponents = URLComponents()
        let requestHeader: [String: String] = [
            "Authorization": "Basic \(String(describing: encodedID))",
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectUrl)
        ]

        guard let url = URL(string: "https://accounts.spotify.com/api/token") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = requestHeader
        request.httpBody            = bodyComponents.query?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else { print("authoriseUser: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("authoriseUser: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("authoriseUser: BAD RESPONSE: ", response.statusCode, response.description); return }
            guard let data = data else { print("NO DATA"); return }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let token = try decoder.decode(Token.self, from: data)

                if let accessToken = token.accessToken {
                    completion(accessToken)
                }
                
                self.databaseController?.saveTokens(token: token.accessToken!, refreshToken: token.refreshToken!)
                return
            } catch {
                print("authoriseUser catch: ", error)
            }
        }.resume()
    }

    func refreshAccessToken(completion: @escaping (String?) -> Void) {
        /**
         Requests for a new access token using the refresh token after its expiration.
         */
        let refreshToken = databaseController?.fetchRefreshToken()
        if refreshToken == "" {
            print("could not refresh token")
            return
        }
        
        var requestBodyComponents = URLComponents()
        let requestHeader: [String: String] = [
            "Authorization": "Basic \(String(describing: encodedID))",
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        requestBodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else { return }
        var request                 = URLRequest(url: url)
        request.httpMethod          = "POST"
        request.allHTTPHeaderFields = requestHeader
        request.httpBody            = requestBodyComponents.query?.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else { print("refreshAccessToken: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("refreshAccessToken: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("refreshAccessToken: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let token = try decoder.decode(Token.self, from: data)
                
                if let refreshedAccessToken = token.accessToken {
                    completion(refreshedAccessToken)
                }
                
                self.databaseController?.saveTokens(token: token.accessToken!, refreshToken: token.refreshToken!)
                return
            } catch {
                print("getRefreshToken: catch");
            }
        }.resume()
    }
    
    // MARK: - FETCH MUSIC DATA

    func getTopArtists(with token: String, timeRange: String, limit: String, completion: @escaping ([Artist]?) -> Void) {
        /**
         Get top artists of a user within a time range.
         */
        let type = "artists"

        guard let url = URL(string: "https://api.spotify.com/v1/me/top/\(type)?time_range=\(timeRange)&limit=\(limit)&offset=\(offset)") else { print("getTopArtists: url"); return }

        // creates a URLRequest object for this URL, setting the HTTP method to GET and adding the required headers to authenticate the request.
        var request         = URLRequest(url: url)
        request.httpMethod  = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token))", forHTTPHeaderField: "Authorization")

        // creates a URLSessionDataTask object and calls its resume() method to start the network request.
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else { print("getTopArtists: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getTopArtists: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getTopArtists: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let topArtistsArray = json["items"] as? [[String: Any]]
                else { print("Failed to decode JSON"); return }
                
                let topArtists = topArtistsArray.compactMap { Artist(dictionary: $0) }

                completion(topArtists)
            } catch let error {
                print("getTopArtists: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getTopTracks(with token: String, timeRange: String, limit: String, completion: @escaping ([Track]?) -> Void) {
        /**
         Get top tracks of a user within a time range.
         */
        let type = "tracks"

        guard let url = URL(string: "https://api.spotify.com/v1/me/top/\(type)?time_range=\(timeRange)&limit=\(limit)&offset=\(offset)") else { print("getTopTracks: url"); return }

        // creates a URLRequest object for this URL, setting the HTTP method to GET and adding the required headers to authenticate the request.
        var request         = URLRequest(url: url)
        request.httpMethod  = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token))", forHTTPHeaderField: "Authorization")

        // creates a URLSessionDataTask object and calls its resume() method to start the network request.
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else { print("getTopTracks: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getTopTracks: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getTopTracks: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let topTracksArray = json["items"] as? [[String: Any]]
                else { print("Failed to decode JSON"); return }
                
                let topTracks = topTracksArray.compactMap { Track(dictionary: $0) }

                completion(topTracks)
            } catch let error {
                print("getTopTracks: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getCurrentlyPlayingTrack(with token: String, completion: @escaping (Track?) -> Void) {
        /**
         Get currently playing track of a user on Spotify.
         */
        // Set up the request URL
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing") else { print("getCurrentlyPlayingTrack: url"); return }

        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print("getCurrentlyPlayingTrack: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getCurrentlyPlayingTrack: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getCurrentlyPlayingTrack: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let trackObject = json["item"] as? [String: Any]
                else { print("Failed to decode JSON"); return }
                
                let track = Track(dictionary: trackObject)

                completion(track)
            } catch let error {
                print("getCurrentlyPlayingTrack: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getRecentlyPlayedTracks(with token: String, completion: @escaping ([PlayHistory]?) -> Void) {
        /**
         Get recently played tracks of a user.
         */
        // Set up the request URL
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played") else { print("getRecentlyPlayedTracks: url"); return }

        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print("getRecentlyPlayedTracks: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getRecentlyPlayedTracks: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getRecentlyPlayedTracks: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let playHistoryArray = json["items"] as? [[String: Any]]
                else { print("Failed to decode JSON"); return }
                
                let playHistory = playHistoryArray.compactMap { PlayHistory(dictionary: $0) }

                completion(playHistory)
            } catch let error {
                print("getRecentlyPlayedTracks: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getPlaylists(with token: String, limit: Int, offset: Int, completion: @escaping (([Playlist]?, Int?)) -> Void) {
        /**
         Get playlists from the user's library, maximum is 50 per request.
         */
        // Set up the request URL
        guard let url = URL(string: "https://api.spotify.com/v1/me/playlists?limit=\(limit)&offset=\(offset)") else { print("getPlaylists: url"); return }

        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print("getPlaylists: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getPlaylists: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getPlaylists: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let playlistsArray = json["items"] as? [Any]
                else { print("getPlaylists: Failed to decode JSON"); return }
                
                let playlistsCount =  json["total"] as? Int
                let playlists = playlistsArray.compactMap { $0 as? [String: Any] }
                                                .compactMap { Playlist(dictionary: $0) }

                completion((playlists, playlistsCount))
            } catch let error {
                print("getPlaylists: JSON decoding error", error)
                completion((nil, nil))
            }
        }.resume()
    }
    
    func getPlaylistTracks(with token: String, playlistID: String, completion: @escaping ([Track]?) -> Void) {
        /**
         Get all tracks from a playlist based on the playlist ID provided.
         */
        // Set up the request URL
        guard let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)") else { print("getPlaylistTracks: url"); return }

        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print("getPlaylistTracks: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getPlaylistTracks: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getPlaylistTracks: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                else { print("getPlaylistTracks: Failed to decode JSON"); return }

                let tracksObject = json["tracks"] as? [String: Any]
                guard let playlistTrackObjects = tracksObject?["items"] as? [[String: Any]] else { return }
                
                let tracks = playlistTrackObjects.compactMap { playlistTrack -> Track? in
                    guard let track = playlistTrack["track"] as? [String: Any] else { return nil }
                    return Track(dictionary: track)
                }
                
                completion(tracks)
            } catch let error {
                print("getPlaylistTracks: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getSavedTracks(with token: String, limit: Int, offset: Int, completion: @escaping ([Track]?) -> Void) {
        /**
         Get user's liked songs library, maximum is 50 per request.
         */
        // Create the URL for the API endpoint
        guard let url = URL(string: "https://api.spotify.com/v1/me/tracks?limit=\(limit)&offset=\(offset)") else { print("getSavedTracks: url"); return }
        
        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print("getSavedTracks: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getSavedTracks: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getSavedTracks: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                else { print("getSavedTracks: Failed to decode JSON"); return }

                guard let savedTrackObjects = json["items"] as? [[String: Any]] else { return }
                
                let tracks = savedTrackObjects.compactMap { savedTrack -> Track? in
                    guard let track = savedTrack["track"] as? [String: Any] else { return nil }
                    return Track(dictionary: track)
                }
                
                completion(tracks)
            } catch let error {
                print("getSavedTracks: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getArtists(with token: String, ids: String, completion: @escaping ([Artist]?) -> Void) {
        /**
         Get an array of artist objects based on the artist IDs provided.
         */
        // Set up the request URL
        guard let url = URL(string: "https://api.spotify.com/v1/artists?ids=\(ids)") else { print("getArtists: url"); return }

        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print("getArtists: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getArtists: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getArtists: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let artistsArray = json["artists"] as? [[String: Any]]
                else { print("getArtists: Failed to decode JSON"); return }
                
                let artists = artistsArray.compactMap { Artist(dictionary: $0) }

                completion(artists)
            } catch let error {
                print("getArtists: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getRecommendations(with token: String, artistID: String, completion: @escaping ([Track]?) -> Void) {
        /**
         Get recommendations in the form of an array of track objects based on artist IDs provided.
         */
        let limit = 10
        guard let url = URL(string: "https://api.spotify.com/v1/recommendations?limit=\(limit)&seed_artists=\(artistID)") else { print("getRecommendations: url"); return }
        
        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print("getRecommendations: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getRecommendations: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getRecommendations: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let tracksArray = json["tracks"] as? [[String: Any]]
                else { print("getRecommendations: Failed to decode JSON"); return }

                let tracks = tracksArray.compactMap({ Track(dictionary: $0) })
                
                completion(tracks)
            } catch let error {
                print("getRecommendations: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    // MARK: - FETCH MUSICAL ANALYSIS
    
    func getAudioFeatures(with token: String, ids: String, completion: @escaping ([AudioFeatures]?) -> Void) {
        /**
         Get an array of audio features of tracks corresponding to the string of track IDs provided.
         */
        guard let url = URL(string: "https://api.spotify.com/v1/audio-features?ids=\(ids)") else { print("getAudioFeatures: url"); return }
        
        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print("getAudioFeatures: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getAudioFeatures: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getAudioFeatures: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let audioFeaturesArray = json["audio_features"] as? [Any]
                else { print("getAudioFeatures: Failed to decode JSON"); return }

                let audioFeatures = audioFeaturesArray.compactMap { $0 as? [String: Any] }
                                                      .compactMap { AudioFeatures(dictionary: $0) }

                completion(audioFeatures)
            } catch let error {
                print("getAudioFeatures: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    // MARK: - SEARCH ITEM
    
    func searchArtistItems(with token: String, query: String, completion: @escaping ([Artist]?) -> Void) {
        /**
         Get the result from a search in the form of an array of artist objects based on the search query provided to search for artists.
         */
        let modifiedQuery = query.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: "https://api.spotify.com/v1/search?q=\(modifiedQuery)&type=artist&limit=1") else { print("searchArtistItems: url"); return }
        
        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print("searchArtistItems: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("searchArtistItems: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("searchArtistItems: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let searchArtistResult = json["artists"] as? [String: Any], let artistItemsArray = searchArtistResult["items"] as? [[String: Any]]
                else { print("searchArtistItems: Failed to decode JSON"); return }
                
                let artists = artistItemsArray.compactMap({ Artist(dictionary: $0) })

                completion(artists)
            } catch let error {
                print("searchArtistItems: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    // MARK: - DOWNLOAD IMAGES

    func downloadImage(from urlString: String, completed: @escaping (UIImage?) -> Void) {
        /**
         Download and crop image to square.
         */
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                print("Failed to download album image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let croppedImage = self.cropToSquare(image: image)
            completed(croppedImage)
        }.resume()
    }
    
    func cropToSquare(image: UIImage) -> UIImage? {
        /**
         Crop image to square.
         */
        let sideLength = min(image.size.width, image.size.height)
        let originX = (image.size.width - sideLength) / 2
        let originY = (image.size.height - sideLength) / 2
        let cropRect = CGRect(x: originX, y: originY, width: sideLength, height: sideLength)
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - PLAYLIST DATA
    
    func createPlaylist(with token: String, songs: [String], playlistName: String, completion: @escaping (Playlist?) -> Void) {
        /**
         Creates a new playlist with a given list of tracks and provided playlist name.
        Starts by getting the current user's ID, which is used to create a new playlist in the user's Spotify library.
        Then, adds all tracks given into the newly created playlist.
        Returns the newly created playlist with all tracks added in.
         */
        guard let urlUser = URL(string: "https://api.spotify.com/v1/me") else { print("getUserID: url"); return }
        
        // Create the request object
        var requestUser = URLRequest(url: urlUser)
        requestUser.httpMethod = "GET"
        requestUser.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Send the request
        let taskUserID = URLSession.shared.dataTask(with: requestUser) { (data, response, error) in
            guard error == nil else { print("getUserID: error", error!); return }
            guard let response = response as? HTTPURLResponse else { print("getUserID: NO RESPONSE"); return }
            guard response.statusCode == 200 else { print("getUserID: BAD RESPONSE: ", response.statusCode); return }
            guard let data = data else { print("NO DATA"); return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let userID = json["id"] as? String
                else { print("getUserID: Failed to decode JSON"); return }
                
                // create playlist request
                guard let urlPlaylist = URL(string: "https://api.spotify.com/v1/users/\(userID)/playlists") else { print("createPlaylist: url"); return }
                
                // Set the name and description of the playlist
                let playlistDescription = ""
                
                // Create the request body
                let playlistRequestBody: [String: Any] = [
                    "name": playlistName,
                    "description": playlistDescription,
                    "public": false
                ]
                
                // Convert the request body to JSON data
                guard let jsonPlaylistData = try? JSONSerialization.data(withJSONObject: playlistRequestBody) else {
                    print("Failed to serialize request body")
                    return
                }
                
                // Create the request object
                var requestPlaylist = URLRequest(url: urlPlaylist)
                requestPlaylist.httpMethod = "POST"
                requestPlaylist.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                requestPlaylist.addValue("application/json", forHTTPHeaderField: "Content-Type")
                requestPlaylist.httpBody = jsonPlaylistData
                
                let taskCreatePlaylist = URLSession.shared.dataTask(with: requestPlaylist) { data, response, error in
                    guard error == nil else { print("createPlaylist: error", error!); return }
                    guard let response = response as? HTTPURLResponse else { print("createPlaylist: NO RESPONSE"); return }
                    guard response.statusCode == 201 else { print("createPlaylist: BAD RESPONSE: ", response.statusCode); return }
                    guard let data = data else { print("NO DATA"); return }
                    
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let playlistID = json["id"] as? String
                        else { print("createPlaylist: Failed to decode JSON"); return }
                        
                        // add songs to playlist request
                        guard let urlSongs = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)/tracks")
                        else { print("addSongs: url"); return }
                        
                        // Create the request body
                        let songsRequestBody: [String: Any] = ["uris" : songs]
                        
                        // Convert the request body to JSON data
                        guard let jsonSongsData = try? JSONSerialization.data(withJSONObject: songsRequestBody) else { print("Failed to serialize request body"); return }
                        
                        // Create the request object
                        var requestSongs = URLRequest(url: urlSongs)
                        requestSongs.httpMethod = "POST"
                        requestSongs.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        requestSongs.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        requestSongs.httpBody = jsonSongsData
                        
                        let taskAddSongs = URLSession.shared.dataTask(with: requestSongs) { data, response, error in
                            guard error == nil else { print("addSongs: error", error!); return }
                            guard let response = response as? HTTPURLResponse else { print("addSongs: NO RESPONSE"); return }
                            guard response.statusCode == 201 else { print("addSongs: BAD RESPONSE: ", response.statusCode); return }
                            guard let data = data else { print("NO DATA"); return }
                            
                            do {
                                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                                   let _ = json["snapshot_id"] as? String
                                else { print("addSongs: Failed to decode JSON"); return }
                                
                                // get playlist request
                                guard let urlNewPlaylist = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)") else { print("getPlaylistCreated: url"); return }

                                // Create the request object
                                var request = URLRequest(url: urlNewPlaylist)
                                request.httpMethod = "GET"
                                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                                
                                // Send the request
                                let taskGetPlaylist = URLSession.shared.dataTask(with: request) { (data, response, error) in
                                    guard error == nil else { print("getPlaylistCreated: error", error!); return }
                                    guard let response = response as? HTTPURLResponse else { print("getPlaylistCreated: NO RESPONSE"); return }
                                    guard response.statusCode == 200 else { print("getPlaylistCreated: BAD RESPONSE: ", response.statusCode); return }
                                    guard let data = data else { print("NO DATA"); return }
                                    
                                    do {
                                        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                                        else {
                                            print("getPlaylistCreated: Failed to decode JSON")
                                            return
                                        }
                                        let newPlaylist = Playlist(dictionary: json)
                                        
                                        completion(newPlaylist)
                                    } catch let error { print("getPlaylistCreated: JSON decoding error", error); completion(nil) }
                                }
                                taskGetPlaylist.resume()
                            } catch { print("addSongs: JSON decoding error", error) }
                        }
                        taskAddSongs.resume()
                    } catch { print("createPlaylist: JSON decoding error", error) }
                }
                taskCreatePlaylist.resume()
            } catch { print("getUserID: JSON decoding error", error) }
        }
        taskUserID.resume()
    }
}
