//
//  modelBooks.swift
//  23234234
//
//  Created by Maria Novikova on 05.07.2022.
//

import Foundation

var book: Book = loadBook("nrt-mf.json")

var books: [String:Book] = [
                            "SYNO":loadBook("syno-mf.json"),
                            "NRT":loadBook("nrt-mf.json")
                           ]

func loadBook<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle: \n\(error).")
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self): \n\(error).")
    }
    
}
