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
    
    // Actual Scanning function
    static func scan(folder rootURL: URL) async -> [TrackFile] {
        let didStartAccessing = rootURL.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                rootURL.stopAccessingSecurityScopedResource()
            }
        }

        let audioFileURLs = collectAudioFileURLs(from: rootURL)

        var tracks: [TrackFile] = []

        for fileURL in audioFileURLs {
            let track = await AudioTagReader.read(url: fileURL)
            tracks.append(track)
        }

        return tracks.sorted {
            $0.filename.localizedCaseInsensitiveCompare($1.filename) == .orderedAscending
        }
    }

    // Gets the audio URLs
    private static func collectAudioFileURLs(from rootURL: URL) -> [URL] {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var audioFileURLs: [URL] = []

        for case let fileURL as URL in enumerator {
            let fileExtension = fileURL.pathExtension.lowercased()

            guard supportedExtensions.contains(fileExtension) else {
                continue
            }

            audioFileURLs.append(fileURL)
        }

        return audioFileURLs
    }
}

