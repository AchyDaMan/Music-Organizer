//
//  MappingStore.swift
//  Music Organizer
//
//  Created by Achintya Yedavalli on 6/12/26.
//

import Foundation

struct MappingStore {
    
    private static let folderName = "Music Organizer"
    private static let fileName = "genre_mappings.json"
    
    static func load() -> [String: GenreBucketRule] {
        do {
            let url = try mappingsFileURL()
            
            guard FileManager.default.fileExists(atPath: url.path) else {
                return [:]
            }
            
            let data = try Data(contentsOf: url)
            
            let decoded = try JSONDecoder().decode(
                [String: GenreBucketRule].self,
                from: data
            )
            
            return decoded
            
        } catch {
            print("Failed to load mappings: \(error.localizedDescription)")
            return [:]
        }
    }
    
    static func save(_ mappings: [String: GenreBucketRule]) {
        do {
            let url = try mappingsFileURL()
            
            let data = try JSONEncoder.prettyPrinted.encode(mappings)
            
            try data.write(to: url, options: [.atomic])
            
            print("Saved mappings to: \(url.path)")
            
        } catch {
            print("Failed to save mappings: \(error.localizedDescription)")
        }
    }
    
    static func mappingsFilePath() -> String {
        do {
            return try mappingsFileURL().path
        } catch {
            return "Could not determine mappings file path."
        }
    }
    
    private static func mappingsFileURL() throws -> URL {
        let fileManager = FileManager.default
        
        guard let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw MappingStoreError.couldNotFindApplicationSupportFolder
        }
        
        let appFolderURL = applicationSupportURL
            .appendingPathComponent(folderName, isDirectory: true)
        
        if !fileManager.fileExists(atPath: appFolderURL.path) {
            try fileManager.createDirectory(
                at: appFolderURL,
                withIntermediateDirectories: true
            )
        }
        
        return appFolderURL
            .appendingPathComponent(fileName, isDirectory: false)
    }
}

enum MappingStoreError: Error {
    case couldNotFindApplicationSupportFolder
}

extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
