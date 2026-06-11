//
//  AudioTagReader.swift
//  Music Organizer
//
//  Created by Achintya Yedavalli on 6/10/26.
//

import Foundation
import AVFoundation

struct AudioTagReader {
    
    static func read(url: URL) async -> TrackFile {
        let asset = AVURLAsset(url: url)
        do{
            // custom function written below
            let metadataItems = try await loadAllMetadataItems(from: asset)
            
            // define title from tags
            let title = await firstString(
                for: [.commonIdentifierTitle],
                in: metadataItems
            ) ?? url.deletingPathExtension().lastPathComponent

            // define artist from tags
            let artist = await firstString(
                for: [.commonIdentifierArtist],
                in: metadataItems
            ) ?? ""

            // define genre tag from tags
            let genreTag = await firstGenreString(in: metadataItems)
                ?? "Unknown Genre Tag"

            // define release year from year
            let releaseYear =
                await firstYear(in: metadataItems)
                ?? extractYear(from: url.lastPathComponent)
                ?? "Unknown Year"

            // put it all together
            return TrackFile(
                sourcePath: url.path,
                filename: url.lastPathComponent,
                title: title,
                artist: artist,
                genreTag: genreTag,
                releaseYear: releaseYear
            )
            
        } catch {
            return fallbackTrackFile(url: url)
        }
    }
    // This is what runs when the mp3 reading fails - it replaces some of the tags with nothing
    private static func fallbackTrackFile(url: URL) -> TrackFile {
        TrackFile(
            sourcePath: url.path,
            filename: url.lastPathComponent,
            title: url.deletingPathExtension().lastPathComponent,
            artist: "",
            genreTag: "Unknown Genre Tag",
            releaseYear: extractYear(from: url.lastPathComponent) ?? "Unknown Year")
        
    }
    
    
    // helper function to load all metadata items
    private static func loadAllMetadataItems(from asset: AVAsset) async throws -> [AVMetadataItem] {
        var allItems: [AVMetadataItem] = []

        let commonItems = try await asset.load(.commonMetadata)
        allItems.append(contentsOf: commonItems)

        let formats = try await asset.load(.availableMetadataFormats)

        for format in formats {
            let formatItems = try await loadMetadataItems(from: asset, format: format)
            allItems.append(contentsOf: formatItems)
        }

        return allItems
    }

    // this hooks into the AVAsset metadata and handles all errors
    private static func loadMetadataItems(
        from asset: AVAsset,
        format: AVMetadataFormat
    ) async throws -> [AVMetadataItem] {
        try await withCheckedThrowingContinuation { continuation in
            asset.loadMetadata(for: format) { items, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: items ?? [])
                }
            }
        }
    }
    
    // to get the string value from the metadata
    private static func firstString(
        for identifiers: [AVMetadataIdentifier],
        in items: [AVMetadataItem]
    ) async -> String? {
        for identifier in identifiers {
            guard let item = items.first(where: { $0.identifier == identifier }) else {
                continue
            }

            if let value = try? await item.load(.stringValue),
               let cleaned = clean(value) {
                return cleaned
            }
        }

        return nil
    }

    // to clean stuff
    private static func clean(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }
    
    // get the genre string out of the code
    private static func firstGenreString(in items: [AVMetadataItem]) async -> String? {
        let genreIdentifiers: [AVMetadataIdentifier] = [
            .id3MetadataContentType,
            .iTunesMetadataUserGenre,
            .quickTimeMetadataGenre
        ]

        if let explicitGenre = await firstString(for: genreIdentifiers, in: items) {
            return explicitGenre
        }

        // Fallback: look for anything whose identifier/key looks genre-related.
        for item in items {
            let identifierText = item.identifier?.rawValue.lowercased() ?? ""
            let keyText: String = {
                if let key = item.key {
                    if let s = key as? String { return s.lowercased() }
                    if let n = key as? NSNumber { return n.stringValue.lowercased() }
                    return String(describing: key).lowercased()
                } else {
                    return ""
                }
            }()

            let looksLikeGenre =
                identifierText.contains("genre") ||
                identifierText.contains("contenttype") ||
                keyText.contains("genre")

            guard looksLikeGenre else {
                continue
            }

            if let value = try? await item.load(.stringValue),
               let cleaned = clean(value) {
                return cleaned
            }
        }

        return nil
    }
    
    // get the first year out of the code
    private static func firstYear(in items: [AVMetadataItem]) async -> String? {
        let dateIdentifiers: [AVMetadataIdentifier] = [
            .commonIdentifierCreationDate
        ]

        if let dateString = await firstString(for: dateIdentifiers, in: items),
           let year = extractYear(from: dateString) {
            return year
        }

        // Fallback: scan all string metadata for a year.
        for item in items {
            if let value = try? await item.load(.stringValue),
               let year = extractYear(from: value) {
                return year
            }
        }

        return nil
    }

    // get a year out of the code
    private static func extractYear(from text: String) -> String? {
        let pattern = #"(19|20)\d{2}"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        guard let match = regex.firstMatch(in: text, range: range),
              let matchRange = Range(match.range, in: text) else {
            return nil
        }

        return String(text[matchRange])
    }
}
