//
//  DatabaseProtocol.swift
//  FIT3178-W05-Lab
//
//  Created by Zhi'en Foo on 29/03/2023.
//

import Foundation

/**
 Defines all the behaviour that a database must have
 */
protocol DatabaseProtocol: AnyObject {
    func cleanup()
    
    func saveTokens(token: String, refreshToken: String)
    func fetchAccessToken() -> String
    func fetchRefreshToken() -> String
}
