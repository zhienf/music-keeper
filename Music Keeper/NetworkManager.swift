//
//  NetworkManager.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit
import StoreKit
import CoreData

class NetworkManager {
    static let shared   = NetworkManager()
    let cache           = NSCache<NSString, UIImage>()
    
    private init() {
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
    }
    
//    private let limit           = "50"
    private let offset          = "0"
    private let clientID        = "***REMOVED***"
    private let clientSecret    = "***REMOVED***"
    
    private let encodedID  = "***REMOVED***"
    // Base64 Encoded Client ID:Client secret

    
    private let redirectUrl = "https://www.google.com"
    
    weak var databaseController: DatabaseProtocol?
    
    func authoriseUser(with code: String, completion: @escaping (String?) -> Void) {
        var bodyComponents = URLComponents()
        let requestHeader: [String: String] = [
            "Authorization": "Basic \(encodedID)",
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
            guard error == nil else {
                print("getArtistRequest: error")
                return
            }

            guard let response = response as? HTTPURLResponse else {
                print("NO RESPONSE")
                return
            }

            guard response.statusCode == 200 else {
                print("BAD RESPONSE: ", response.statusCode)
                return
            }

            guard let data = data else {
                print("NO DATA")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let token = try decoder.decode(Token.self, from: data)

                if let accessToken = token.accessToken {
                    print("decoded access token:", accessToken)
                    completion(accessToken)
                }
                print("network access token:", token.accessToken!)
                print("network refresh token:", token.refreshToken!)
                self.databaseController?.saveTokens(token: token.accessToken!, refreshToken: token.refreshToken!)
                
                return
            } catch {
                print("catch: ", error)
            }
        }.resume()
    }

    func refreshAccessToken(completion: @escaping (String?) -> Void) {
        let refreshToken = databaseController?.fetchRefreshToken()
        print("current refresh token:",refreshToken)
        if refreshToken == "" {
            print("could not refresh token")
            return
        }
        
        var requestBodyComponents = URLComponents()
        let requestHeader: [String: String] = [
            "Authorization": "Basic \(encodedID)",
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
            if let _ = error { print("getRefreshToken: error"); return }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { print("getRefreshToken: bad/no response"); return }
            guard let data = data else { print("getRefreshToken: no data"); return }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let token = try decoder.decode(Token.self, from: data)
                
                if let refreshedAccessToken = token.accessToken {
                    print("decoded refreshed token:", refreshedAccessToken)
                    completion(refreshedAccessToken)
                }
                
                self.databaseController?.saveTokens(token: token.accessToken!, refreshToken: token.refreshToken!)
                                
                return
            } catch {
                print("getRefreshToken: catch");
            }
        }.resume()
    }
    
    // MARK: - PLAYLIST DATA
    
//    func createPlaylist(OAuthtoken: String, playlistName: String, playlistDescription: String, songs: [String], isPublic: String, completed: @escaping (String?) -> Void)
//    {
//        guard let urlUser = URL(string: "\(baseURL.spotifyAPI)v1/me") else { print("urlUser"); return }
//
//        var requestUser         = URLRequest(url: urlUser)
//        requestUser.httpMethod  = "GET"
//        requestUser.addValue("application/json", forHTTPHeaderField: HeaderField.accept)
//        requestUser.addValue("application/json", forHTTPHeaderField: HeaderField.contentType)
//        requestUser.addValue("Bearer \(String(OAuthtoken))", forHTTPHeaderField: HeaderField.authorization)
//
//        let taskUserID = URLSession.shared.dataTask(with: requestUser) { data, response, error in
//
//            if let _            = error { print("taskUserID: error"); return }
//            guard let response  = response as? HTTPURLResponse, response.statusCode == 200 else { print("taskUserID: response"); return }
//            guard let data      = data else { print("taskUserIDL: data"); return }
//
//            do {
//                let decoder                 = JSONDecoder()
//                decoder.keyDecodingStrategy = .convertFromSnakeCase
//                let user                    = try decoder.decode(UserProfile.self, from: data)
//
//                guard let uid = user.id else { return }
//                guard let urlPlaylist = URL(string: "\(baseURL.spotifyAPI)v1/users/\(uid)/playlists") else { print("urlPlaylist"); return }
//
//                let requestPlaylistHeaders: [String:String] = [HeaderField.accept : "application/json",
//                                                               HeaderField.contentType : "application/json",
//                                                               HeaderField.authorization : "Bearer \(OAuthtoken)"]
//
//                let parametersPlaylist: [String: Any] = [
//                    "name" : playlistName,
//                    "description" : playlistDescription,
//                    "public": false
//                ]
//
//                let jsonPlaylistData = try? JSONSerialization.data(withJSONObject: parametersPlaylist)
//
//                var requestPlaylist                 = URLRequest(url: urlPlaylist)
//                requestPlaylist.httpMethod          = "POST"
//                requestPlaylist.allHTTPHeaderFields = requestPlaylistHeaders
//                requestPlaylist.httpBody            = jsonPlaylistData
//
//                let taskPlaylist = URLSession.shared.dataTask(with: requestPlaylist) { data, response, error in
//
//                    if let _        = error { return }
//                    guard let data  = data else { return } /// no error code, bc returns error object
//
//                    do {
//                        let decoder                 = JSONDecoder()
//                        decoder.keyDecodingStrategy = .convertFromSnakeCase
//                        let playlist                = try decoder.decode(Playlist.self, from: data)
//
//                        guard let playlistID = playlist.id else { return }
//                        guard let urlSongs = URL(string: "\(baseURL.spotifyAPI)v1/playlists/\(playlistID)/tracks") else { print("urlSongs"); return }
//
//                        let requestSongsHeaders: [String:String] = [HeaderField.accept : "application/json",
//                                                                    HeaderField.contentType : "application/json",
//                                                                    HeaderField.authorization : "Bearer \(OAuthtoken)"]
//
//                        let parametersSongs: [String: Any] = ["uris" : songs]
//                        let jsonSongsData = try? JSONSerialization.data(withJSONObject: parametersSongs)
//
//                        var requestSongs                 = URLRequest(url: urlSongs)
//                        requestSongs.httpMethod          = "POST"
//                        requestSongs.allHTTPHeaderFields = requestSongsHeaders
//                        requestSongs.httpBody            = jsonSongsData
//
//                        let taskSongs = URLSession.shared.dataTask(with: requestSongs) { data, response, error in
//
//                            if let _        = error { print("taskSongs: error"); return }
//                            guard let data  = data else { print("taskSongs: data"); return }
//
//                            do {
//                                let decoder                 = JSONDecoder()
//                                decoder.keyDecodingStrategy = .convertFromSnakeCase
//                                let snapshot                = try decoder.decode(Snapshot.self, from: data)
//                                completed(snapshot.snapshotId); return
//                            } catch { print("taskSongs: catch") }
//                        }
//                        taskSongs.resume()
//                    } catch { print("taskPlaylist: catch") }
//                }
//                taskPlaylist.resume()
//            } catch { print("taskUserID: catch") }
//        }
//        taskUserID.resume()
//    }
//
    // MARK: - FETCH MUSIC DATA

    func getArtists(with token: String, timeRange: String, limit: String, completion: @escaping (ArtistItems?) -> Void) {
        let type        = "artists"
//        let timeRange   = "short_term" // last 4 weeks
//        let limit       = "5"

        guard let url = URL(string: "https://api.spotify.com/v1/me/top/\(type)?time_range=\(timeRange)&limit=\(limit)&offset=\(offset)") else { print("getArtistRequest: url"); return }

        // creates a URLRequest object for this URL, setting the HTTP method to GET and adding the required headers to authenticate the request.
        var request         = URLRequest(url: url)
        request.httpMethod  = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token))", forHTTPHeaderField: "Authorization")

        // creates a URLSessionDataTask object and calls its resume() method to start the network request.
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("getArtistRequest: error", error!)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print("NO RESPONSE")
                return
            }
            
            guard response.statusCode == 200 else {
                print("BAD RESPONSE: ", response.statusCode)
                return
            }
            
            guard let data = data else {
                print("NO DATA")
                return
            }

            do {
                let decoder                 = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let artists                 = try decoder.decode(ArtistItems.self, from: data)
                print("artists:", artists)
                completion(artists)
            } catch {
                print("getArtistRequest: catch", error);
            }
        }.resume()
    }
    
    func getTopTracks(with token: String, timeRange: String, limit: String, completion: @escaping (TrackItems?) -> Void) {
        let type        = "tracks"

        guard let url = URL(string: "https://api.spotify.com/v1/me/top/\(type)?time_range=\(timeRange)&limit=\(limit)&offset=\(offset)") else { print("getTopTracksRequest: url"); return }

        // creates a URLRequest object for this URL, setting the HTTP method to GET and adding the required headers to authenticate the request.
        var request         = URLRequest(url: url)
        request.httpMethod  = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token))", forHTTPHeaderField: "Authorization")

        // creates a URLSessionDataTask object and calls its resume() method to start the network request.
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("getTopTracksRequest: error", error!)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print("NO RESPONSE")
                return
            }
            
            guard response.statusCode == 200 else {
                print("BAD RESPONSE: ", response.statusCode)
                return
            }
            
            guard let data = data else {
                print("NO DATA")
                return
            }

            do {
                let decoder                 = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let tracks                  = try decoder.decode(TrackItems.self, from: data)
                print("tracks:", tracks)
                completion(tracks)
            } catch {
                print("getTopTracksRequest: catch", error);
            }
        }.resume()
    }
    
    func getCurrentlyPlayingTrack(with token: String, completion: @escaping (Track?) -> Void) {
        // Set up the request URL
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing") else { print("getCurrentlyPlayingTrack: url"); return }

        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("getCurrentlyPlayingTrack: error", error!)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print("NO RESPONSE")
                return
            }
            
            guard response.statusCode == 200 else {
                print("BAD RESPONSE: ", response.statusCode)
                return
            }
            
            guard let data = data else {
                print("NO DATA")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let trackItem = try decoder.decode(TrackItem.self, from: data)
                completion(trackItem.item)
            } catch let error {
                print("getCurrentlyPlayingTrack: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getRecentlyPlayedTracks(with token: String, completion: @escaping (RecentlyPlayedItems?) -> Void) {
        // Set up the request URL
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played") else { print("getRecentlyPlayedTracks: url"); return }

        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("getRecentlyPlayedTracks: error", error!)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print("NO RESPONSE")
                return
            }
            
            guard response.statusCode == 200 else {
                print("BAD RESPONSE: ", response.statusCode)
                return
            }
            
            guard let data = data else {
                print("NO DATA")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let recentlyPlayedItems = try decoder.decode(RecentlyPlayedItems.self, from: data)
                completion(recentlyPlayedItems)
            } catch let error {
                print("getRecentlyPlayedTracks: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getLibrary(with token: String, completion: @escaping (RecentlyPlayedItems?) -> Void) {
        // Set up the request URL
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played") else { print("getRecentlyPlayedTracks: url"); return }

        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send the request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("getRecentlyPlayedTracks: error", error!)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print("NO RESPONSE")
                return
            }
            
            guard response.statusCode == 200 else {
                print("BAD RESPONSE: ", response.statusCode)
                return
            }
            
            guard let data = data else {
                print("NO DATA")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let recentlyPlayedItems = try decoder.decode(RecentlyPlayedItems.self, from: data)
                completion(recentlyPlayedItems)
            } catch let error {
                print("getRecentlyPlayedTracks: JSON decoding error", error)
                completion(nil)
            }
        }.resume()
    }

//    func getTrackRequest(OAuthtoken: String, completed: @escaping (TrackItem?) -> Void)
//    {
//        let type        = "tracks"
//        let timeRange   = "long_term"
//
//        guard let url = URL(string: "\(baseURL.spotifyAPI)v1/me/top/\(type)?time_range=\(timeRange)&limit=\(limit)&offset=\(offset)") else { print("getTrackRequest: url"); return }
//
//        var request         = URLRequest(url: url)
//        request.httpMethod  = "GET"
//        request.addValue("application/json", forHTTPHeaderField: HeaderField.accept)
//        request.addValue("application/json", forHTTPHeaderField: HeaderField.contentType)
//        request.addValue("Bearer \(String(OAuthtoken))", forHTTPHeaderField: HeaderField.authorization)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//
//            if let _            = error { print("getTrackRequest: error:"); return }
//            guard let response  = response as? HTTPURLResponse, response.statusCode == 200 else { print("getTrackRequest: response:"); return }
//            guard let data      = data else { print("getTrackRequest: data:"); return }
//
//            do {
//                let decoder                 = JSONDecoder()
//                decoder.keyDecodingStrategy = .convertFromSnakeCase
//                let tracks                  = try decoder.decode(TrackItem.self, from: data)
//
//                completed(tracks); return
//            } catch {
//                print("getTrackRequest: catch")
//            }
//        }
//        task.resume()
//    }
//
//    func getRecentTracks(OAuthtoken: String, completed: @escaping (TrackItem?) -> Void)
//    {
//        let type        = "tracks"
//        let timeRange   = "short_term" /// 4 weeks
//        let limit       = "50"
//
//        guard let url = URL(string: "https://api.spotify.com/v1/me/top/\(type)?time_range=\(timeRange)&limit=\(limit)&offset=\(offset)") else { print("getRecentTracks: url"); return }
//
//        var request         = URLRequest(url: url)
//        request.httpMethod  = "GET"
//        request.addValue("application/json", forHTTPHeaderField: "Accept")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("Bearer \(String(OAuthtoken))", forHTTPHeaderField: "Authorization")
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//
//            if let _            = error { print("getRecentTracks: error"); return }
//            guard let response  = response as? HTTPURLResponse, response.statusCode == 200 else { print("getRecentTracks: bad/no response"); return }
//            guard let data      = data else { print("getRecentTracks: no data"); return }
//
//            do {
//                let decoder                 = JSONDecoder()
//                decoder.keyDecodingStrategy = .convertFromSnakeCase
//                let tracks                  = try decoder.decode(TrackItem.self, from: data)
//                print("tracks:", tracks)
//                completed(tracks); return
//            } catch {
//                print("getRecentTracks: url")
//            }
//        }
//        task.resume()
//    }

//    func getNewTrackRequest(OAuthtoken: String, completed: @escaping (NewReleases?) -> Void)
//    {
//        guard let url = URL(string: "\(baseURL.spotifyAPI)v1/browse/new-releases?country=US") else { print("getNewTrackRequest: url"); return }
//
//        var request         = URLRequest(url: url)
//        request.httpMethod  = "GET"
//        request.addValue("application/json", forHTTPHeaderField: HeaderField.accept)
//        request.addValue("application/json", forHTTPHeaderField: HeaderField.contentType)
//        request.addValue("Bearer \(String(OAuthtoken))", forHTTPHeaderField: HeaderField.authorization)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//
//            if let _            = error { print("getNewTrackRequest: error"); return }
//            guard let response  = response as? HTTPURLResponse, response.statusCode == 200 else { print("getNewTrackRequest: response"); return }
//            guard let data      = data else { print("getNewTrackRequest: data"); return }
//
//            do {
//                let decoder                 = JSONDecoder()
//                decoder.keyDecodingStrategy = .convertFromSnakeCase
//                let tracks                  = try decoder.decode(NewReleases.self, from: data)
//
//                completed(tracks); return
//            } catch {
//                print("getNewTrackRequest: catch")
//            }
//        }
//        task.resume()
//    }
//
//    // MARK: - DOWNLOAD IMAGES
//
//    func downloadImage(from urlString: String, completed: @escaping (UIImage?) -> Void)
//    {
//        let cacheKey    = NSString(string: urlString)
//        if let image    = cache.object(forKey: cacheKey) { completed(image); return }
//        guard let url   = URL(string: urlString) else { return }
//
//        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
//
//            guard let self = self,
//                error == nil,
//                let response    = response as? HTTPURLResponse, response.statusCode == 200,
//                let data        = data,
//                let image       = UIImage(data: data) else { return }
//
//            self.cache.setObject(image, forKey: cacheKey)
//            completed(image)
//        }
//        task.resume()
//    }
}
