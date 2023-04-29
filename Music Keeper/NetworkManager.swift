//
//  NetworkManager.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit
import StoreKit
import CoreData

class NetworkManager: DatabaseListener {
    static let shared   = NetworkManager()
    let controller      = SKCloudServiceController()
    let cache           = NSCache<NSString, UIImage>()
    
    private init() { }
    
    private let limit           = "50"
    private let offset          = "0"
    private let clientID        = "***REMOVED***"
    private let clientSecret    = "***REMOVED***"
    
    private let encodedID  = "***REMOVED***"
    // For this you are required to Base64 Encode your Client ID
    // I recomend using this site https://www.base64encode.org/
    
    private let redirectUrl = "https://www.google.com"
    // For example: "https%3A%2F%2Fgoogle.com%2F"
    
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
                    print("accessToken:", accessToken)
                    completion(accessToken)
                }
                
                // get a reference to the database from the appDelegate
                let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
                databaseController = appDelegate?.databaseController
                
                databaseController?.saveAccessToken(token: token.accessToken!)
                
//                PersistenceManager.saveAccessToken(accessToken: token.accessToken!)
//                PersistenceManager.saveRefreshToken(refreshToken: token.refreshToken!)

                return
            } catch {
                print("catch: ", error)
            }
        }.resume()
    }

    
//    func getRefreshToken(completed: @escaping (String?) -> Void)
//    {
//        let refreshToken = PersistenceManager.retrieveRefreshToken()
//        if refreshToken == "" { return }
//
//        let requestHeaders: [String:String] = [HeaderField.authorization : "Basic \(encodedID)",
//                                               HeaderField.contentType : "application/x-www-form-urlencoded"]
//
//        var requestBodyComponents = URLComponents()
//        requestBodyComponents.queryItems = [URLQueryItem(name: HeaderField.grantType, value: "refresh_token"),
//                                            URLQueryItem(name: HeaderField.refreshToken, value: refreshToken)]
//
//        guard let url = URL(string: "\(baseURL.spotify)api/token") else { return }
//        var request                 = URLRequest(url: url)
//        request.httpMethod          = "POST"
//        request.allHTTPHeaderFields = requestHeaders
//        request.httpBody            = requestBodyComponents.query?.data(using: .utf8)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//
//            if let _            = error { print("getRefreshToken: error"); return }
//            guard let response  = response as? HTTPURLResponse, response.statusCode == 200 else { print("getRefreshToken: response"); return }
//            guard let data      = data else { print("getRefreshToken: data"); return }
//
//            do {
//                let decoder                     = JSONDecoder()
//                decoder.keyDecodingStrategy     = .convertFromSnakeCase
//                let token                       = try decoder.decode(Token.self, from: data)
//
//                PersistenceManager.saveAccessToken(accessToken: token.accessToken!)
//                completed(token.accessToken!)
//                return
//            } catch {
//                print("getRefreshToken: catch");
//            }
//        }
//        task.resume()
//    }
//
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
//
    func getArtists(with token: String, completion: @escaping (ArtistResult?) -> Void)
    {
        let type        = "artists"
        let timeRange   = "long_term"

        guard let url = URL(string: "https://api.spotify.com/v1/me/top/\(type)?time_range=\(timeRange)&limit=\(limit)&offset=\(offset)") else { print("getArtistRequest: url"); return }

        var request         = URLRequest(url: url)
        request.httpMethod  = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accpet")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token))", forHTTPHeaderField: "Authorization")

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
                print("data:", data)
                let artists                 = try decoder.decode(ArtistResult.self, from: data)
                print("artists:", artists)
                completion(artists)
            } catch {
                print("getArtistRequest: catch", error);
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
//        guard let url = URL(string: "\(baseURL.spotifyAPI)v1/me/top/\(type)?time_range=\(timeRange)&limit=\(limit)&offset=\(offset)") else { print("getRecentTracks: url"); return }
//
//        var request         = URLRequest(url: url)
//        request.httpMethod  = "GET"
//        request.addValue("application/json", forHTTPHeaderField: HeaderField.accept)
//        request.addValue("application/json", forHTTPHeaderField: HeaderField.contentType)
//        request.addValue("Bearer \(String(OAuthtoken))", forHTTPHeaderField: HeaderField.authorization)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//
//            if let _            = error { print("getRecentTracks: error"); return }
//            guard let response  = response as? HTTPURLResponse, response.statusCode == 200 else { print("getRecentTracks: response"); return }
//            guard let data      = data else { print("getRecentTracks: data"); return }
//
//            do {
//                let decoder                 = JSONDecoder()
//                decoder.keyDecodingStrategy = .convertFromSnakeCase
//                let tracks                  = try decoder.decode(TrackItem.self, from: data)
//
//                completed(tracks); return
//            } catch {
//                print("getRecentTracks: url")
//            }
//        }
//        task.resume()
//    }
//
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