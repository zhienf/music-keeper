//
//  DatabaseProtocol.swift
//  FIT3178-W05-Lab
//
//  Created by Zhi'en Foo on 29/03/2023.
//

import Foundation

protocol DatabaseListener: AnyObject {  // defines the delegate used for receiving messages from the database
//    func onBookListChange(bookList: [Book])
}

protocol DatabaseProtocol: AnyObject {  // defines all the behaviour that a database must have
    func cleanup()
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    func saveAccessToken(token: String)
    func fetchAccessToken() -> String
    
//    func addBook(bookData: BookData) -> Book
//    func removeBook(book: Book)
}
