//
//  APIClient.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

class SpotifyAPIClient: NSObject {
    
    var accessToken: String?
    
    func requestAccessToken(completion: @escaping (Error?) -> Void) {
        // code to request access token and set it to the accessToken property
        // call completion handler with any errors
        
        // Create a URL object for the token endpoint URI
        guard let tokenEndpoint = URL(string: "https://accounts.spotify.com/api/token") else {
            return
        }

        // Create a URLRequest object for the token endpoint with the HTTP method set to POST
        var tokenRequest = URLRequest(url: tokenEndpoint)
        tokenRequest.httpMethod = "POST"
        
        // Set the Content-Type header to the application/x-www-form-urlencoded value
        tokenRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Create a String object containing the Client ID and Client Secret, along with the grant_type parameter set to client_credentials
        let clientID = "***REMOVED***"
        let clientSecret = "***REMOVED***"
        let grantType = "client_credentials"
        let authString = "\(clientID):\(clientSecret)"
        let authData = authString.data(using: .ascii)
        let base64AuthString = authData?.base64EncodedString()
        let httpBody = "grant_type=\(grantType)"
        
        // Set the HTTP body of the token request to the auth data and HTTP body string
        tokenRequest.httpBody = "\(httpBody)".data(using: .utf8)
        tokenRequest.addValue("Basic \(base64AuthString!)", forHTTPHeaderField: "Authorization")

        // Send the token request using URLSession
        let session = URLSession.shared
        let task = session.dataTask(with: tokenRequest) { (data, response, error) in
            // parse the JSON response and extract the access token
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                        if let accessToken = json["access_token"] as? String {
                            // Use the access token to make API requests
                            self.accessToken = accessToken
                        }
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
    // other methods for making API requests
    
}
