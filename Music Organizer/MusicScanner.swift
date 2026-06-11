//
//  MusicScanner.swift
//  Music Organizer
//
//  Created by Achintya Yedavalli on 6/10/26.
//

import Foundation

struct MusicScanner {
    
    // Define supported music extensions (mp3 is most common)
    static let supportedExtensions: Set<String> = ["mp3", "wav", "flac"]
    
    // Actual scanning function to find the music and put it into the trackfile list as seen in contentview
    static func scan(folder rootURL: URL) -> [TrackFile] {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        else {
            return[]
        }
        
        // Set up the list of tracks
        var tracks: [TrackFile] = []
        
        // For every track it finds
        for case let fileURL as URL in enumerator {
            
            // convert file extension to lowercase (so that .WAV is converted to .wav)
            let fileExtension = fileURL.pathExtension.lowercased()
            
            // Skip if it has a wrong file extension
            guard supportedExtensions.contains(fileExtension) else { continue }
            
            // declare the track before putting it into the list
            let track = TrackFile(
                sourcePath: fileURL.path,
                filename: fileURL.lastPathComponent,
                title: fileURL.deletingPathExtension().lastPathComponent,
                // TODO change later
                artist: "",
                genreTag: "Unknown Subgenre",
                releaseYear: "Unknown Year"
            )
            
            tracks.append(track)
        }
        
        return tracks.sorted { lhs, rhs in
            lhs.filename.localizedCaseInsensitiveCompare(rhs.filename) == .orderedAscending
        }
    }
}

