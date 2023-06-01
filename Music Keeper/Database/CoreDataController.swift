//
//  CoreDataController.swift
//  FIT3178-W05-Lab
//
//  Created by Zhi'en Foo on 29/03/2023.
//

import UIKit
import CoreData

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    var persistentContainer: NSPersistentContainer
    
    override init() {
        persistentContainer = NSPersistentContainer(name: "AccessTokenDataModel")
        persistentContainer.loadPersistentStores() { (description, error ) in
            if let error = error {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        } // loads the Core Data stack, triggers a fatal error if stack fails to load
        
        super.init()
    }
    
    func saveTokens(token: String, refreshToken: String) {
        /**
         Save tokens retrieved from Spotify API to core data.
         */
        guard let entity = NSEntityDescription.entity(forEntityName: "AccessToken", in: persistentContainer.viewContext) else {
            fatalError("Failed to create entity description")
        }
        
        let accessToken = NSManagedObject(entity: entity, insertInto: persistentContainer.viewContext)
        accessToken.setValue(token, forKey: "token")
        accessToken.setValue(refreshToken, forKey: "refreshToken")
        accessToken.setValue(Date(), forKey: "timestamp") // Set the timestamp property to the current date and time
        
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("Failed to save access token with error: \(error)")
        }
    }
    
    func fetchAccessToken() -> String {
        /**
         Fetch the AccessToken entity from the Core Data store.
         */
        let fetchRequest: NSFetchRequest<AccessToken> = AccessToken.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let context = persistentContainer.viewContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

        do {
            try fetchedResultsController.performFetch()
            if let tokens = fetchedResultsController.fetchedObjects, let lastToken = tokens.first {
                // Retrieve the token value from the AccessToken entity
                return lastToken.token!
            }
        } catch {
            print("Failed to fetch access token: \(error)")
        }
        return "no token"
    }
    
    func fetchRefreshToken() -> String {
        /**
         Fetch the AccessToken entity from the Core Data store.
         */
        let fetchRequest: NSFetchRequest<AccessToken> = AccessToken.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let context = persistentContainer.viewContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

        do {
            try fetchedResultsController.performFetch()
            if let tokens = fetchedResultsController.fetchedObjects, let lastToken = tokens.first {
                // Retrieve the token value from the AccessToken entity
                return lastToken.refreshToken!
            }
        } catch {
            print("Failed to fetch refresh token: \(error)")
        }
        return "no token"
    }
    
    // MARK: - DatabaseProtocol protocol methods
    
    func cleanup() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("Failed to save data to Core Data with error \(error)")
            }
        }
    }
}
