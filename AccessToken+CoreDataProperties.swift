//
//  AccessToken+CoreDataProperties.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 30/04/2023.
//
//

import Foundation
import CoreData


extension AccessToken {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccessToken> {
        return NSFetchRequest<AccessToken>(entityName: "AccessToken")
    }

    @NSManaged public var refreshToken: String?
    @NSManaged public var token: String?
    @NSManaged public var timestamp: Date?

}

extension AccessToken : Identifiable {

}
