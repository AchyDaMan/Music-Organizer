//
//  Models.swift
//  Music Organizer
//
//  Created by Achintya Yedavalli on 6/10/26.
//

import Foundation

struct TrackFile: Identifiable, Hashable {
    let id = UUID()
    let sourcePath: String
    let filename: String

    var title: String
    var artist: String
    var subgenre: String
    var releaseYear: String

}

struct GenreMapping: Codable {
    var subgenreToGenre: [String: String] = [:]
}
