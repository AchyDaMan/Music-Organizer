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
    // Just what's in the genre tag
    var genreTag: String
    var releaseYear: String

}

struct GenreBucketRule: Codable {
    var parentGenre: String
    var subgenreFolder: String
}
