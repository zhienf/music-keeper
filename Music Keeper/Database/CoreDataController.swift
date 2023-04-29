//
//  CoreDataController.swift
//  FIT3178-W05-Lab
//
//  Created by Zhi'en Foo on 29/03/2023.
//

import UIKit
import CoreData

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistentContainer: NSPersistentContainer
//    var allBooksFetchedResultsController: NSFetchedResultsController<Book>?
    
    var token: String?
    
    override init() {
        persistentContainer = NSPersistentContainer(name: "AccessTokenDataModel")
        persistentContainer.loadPersistentStores() { (description, error ) in
            if let error = error {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        } // loads the Core Data stack, triggers a fatal error if stack fails to load
        
        super.init()
    }
    
    func saveAccessToken(token: String) {
        guard let entity = NSEntityDescription.entity(forEntityName: "AccessToken", in: persistentContainer.viewContext) else {
            fatalError("Failed to create entity description")
        }
        
        let accessToken = NSManagedObject(entity: entity, insertInto: persistentContainer.viewContext)
        accessToken.setValue(token, forKey: "token")
        
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("Failed to save access token with error: \(error)")
        }
    }
    
    func fetchAccessToken() -> String {
        // Fetch the AccessToken entity from the Core Data store
        let fetchRequest: NSFetchRequest<AccessToken> = AccessToken.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "token", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let context = persistentContainer.viewContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

        do {
            try fetchedResultsController.performFetch()
            if let tokens = fetchedResultsController.fetchedObjects, let lastToken = tokens.first {
                // Retrieve the token value from the AccessToken entity
                return lastToken.token!
                // Do something with the access token
            }
        } catch {
            print("Failed to fetch access token: \(error)")
        }
        return "no token"
    }

    
//    func fetchAllBooks() -> [Book] {
//        if allBooksFetchedResultsController == nil {
//            let fetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
//            let nameSortDescriptor = NSSortDescriptor(key: "title", ascending: true)
//            fetchRequest.sortDescriptors = [nameSortDescriptor]
//            allBooksFetchedResultsController = NSFetchedResultsController<Book>( fetchRequest:fetchRequest, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
//            allBooksFetchedResultsController?.delegate = self
//            do {
//                try allBooksFetchedResultsController?.performFetch()
//            } catch {
//                print("Fetch Request failed: \(error)")
//            }
//        }
//        if let books = allBooksFetchedResultsController?.fetchedObjects {
//            return books
//        }
//        return [Book]()
//    }
    
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
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
//        listener.onBookListChange(bookList: fetchAllBooks())
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
//    func addBook(bookData: BookData) -> Book {
//        let book = NSEntityDescription.insertNewObject(forEntityName: "Book", into: persistentContainer.viewContext) as! Book
//
//        book.authors = bookData.authors
//        book.bookDescription = bookData.bookDescription
//        book.imageURL = bookData.imageURL
//        book.isbn13 = bookData.isbn13
//        book.publicationDate = bookData.publicationDate
//        book.publisher = bookData.publisher
//        book.title = bookData.title
//
//        return book
//    }
    
//    func removeBook(book: Book) {
//        persistentContainer.viewContext.delete(book)
//    }
    
    // MARK: - Fetched Results Controller Protocol methods
    
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        listeners.invoke() { listener in
//            listener.onBookListChange(bookList: fetchAllBooks())
//        }
//    }
}
