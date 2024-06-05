//
//  typeBook.swift
//  23234234
//
//  Created by Maria Novikova on 05.07.2022.
//

import Foundation

struct Verse: Hashable, Codable {
    var id: Int
    var text: String
}

struct Chapter: Hashable, Codable, Identifiable {
    var id: Int
    var verses: [Verse]
}

struct Book: Hashable, Codable {
    var fullName: String
    var chapters: [Chapter]
}
