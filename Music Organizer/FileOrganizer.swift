//
//  FileOrganizer.swift
//  Music Organizer
//
//  Created by Achintya Yedavalli on 6/10/26.
//

import Foundation

// Switch between copy and move mode
enum OrganizeMode {
    case copy
    case move
}

// Grab details for if it fails
struct OrganizeFailure: Identifiable {
    let id = UUID()
    let filename: String
    let reason: String
}

// Get the list of successful and failed to report afterward
struct OrganizeSummary {
    let totalFiles: Int
    let successfulFiles: Int
    let failedFiles: Int
    let failures: [OrganizeFailure]
}

// The actual file organizing tool
struct FileOrganizer {
    
    // to build the real file path you would move to
    static func destinationURL(
            for track: TrackFile,
            outputRoot: URL,
            mappings: [String: GenreBucketRule]
        ) -> URL {
            
            let rule = mappings[track.genreTag]
            
            let rawParentGenre: String = {
                if let parentGenre = rule?.parentGenre,
                   !parentGenre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return parentGenre
                } else {
                    return "Unmapped Genre"
                }
            }()
            
            let rawSubgenreFolder: String = {
                if let subgenreFolder = rule?.subgenreFolder,
                   !subgenreFolder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return subgenreFolder
                } else if track.genreTag == "Unknown Genre Tag" {
                    return "Unknown Subgenre"
                } else {
                    return track.genreTag
                }
            }()
            
            let parentGenre = cleanPathComponent(rawParentGenre)
            let subgenreFolder = cleanPathComponent(rawSubgenreFolder)
            let releaseYear = cleanPathComponent(track.releaseYear)
            let filename = cleanFilename(track.filename)
            
            return outputRoot
                .appendingPathComponent(parentGenre, isDirectory: true)
                .appendingPathComponent(subgenreFolder, isDirectory: true)
                .appendingPathComponent(releaseYear, isDirectory: true)
                .appendingPathComponent(filename, isDirectory: false)
        }
        
    // creates the readable preview string for the file
    static func destinationPreview(
        for track: TrackFile,
        mappings: [String: GenreBucketRule]
    ) -> String {
        let rule = mappings[track.genreTag]
        
        let parentGenre: String = {
            if let parentGenre = rule?.parentGenre,
               !parentGenre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return cleanPathComponent(parentGenre)
            } else {
                return "Unmapped Genre"
            }
        }()
        
        let subgenreFolder: String = {
            if let subgenreFolder = rule?.subgenreFolder,
               !subgenreFolder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return cleanPathComponent(subgenreFolder)
            } else if track.genreTag == "Unknown Genre Tag" {
                return "Unknown Subgenre"
            } else {
                return cleanPathComponent(track.genreTag)
            }
        }()
        
        let releaseYear = cleanPathComponent(track.releaseYear)
        let filename = cleanFilename(track.filename)
        
        return "\(parentGenre)/\(subgenreFolder)/\(releaseYear)/\(filename)"
    }
        
    static func organize(
        tracks: [TrackFile],
        sourceRoot: URL?,
        outputRoot: URL,
        mappings: [String: GenreBucketRule],
        mode: OrganizeMode
    ) -> OrganizeSummary {
        
        let fileManager = FileManager.default
        
        let didAccessSource = sourceRoot?.startAccessingSecurityScopedResource() ?? false
        let didAccessOutput = outputRoot.startAccessingSecurityScopedResource()
        
        defer {
            if didAccessSource {
                sourceRoot?.stopAccessingSecurityScopedResource()
            }
            
            if didAccessOutput {
                outputRoot.stopAccessingSecurityScopedResource()
            }
        }
        
        var successfulFiles = 0
        var failures: [OrganizeFailure] = []
        
        for track in tracks {
            let sourceURL = URL(fileURLWithPath: track.sourcePath)
            let proposedDestinationURL = destinationURL(
                for: track,
                outputRoot: outputRoot,
                mappings: mappings
            )
            
            let destinationFolder = proposedDestinationURL.deletingLastPathComponent()
            
            do {
                guard fileManager.fileExists(atPath: sourceURL.path) else {
                    failures.append(
                        OrganizeFailure(
                            filename: track.filename,
                            reason: "Source file no longer exists."
                        )
                    )
                    continue
                }
                
                try fileManager.createDirectory(
                    at: destinationFolder,
                    withIntermediateDirectories: true
                )
                
                let finalDestinationURL = uniqueDestinationURL(
                    for: proposedDestinationURL,
                    fileManager: fileManager
                )
                
                switch mode {
                case .copy:
                    try fileManager.copyItem(
                        at: sourceURL,
                        to: finalDestinationURL
                    )
                    
                case .move:
                    try fileManager.moveItem(
                        at: sourceURL,
                        to: finalDestinationURL
                    )
                }
                
                successfulFiles += 1
                
            } catch {
                failures.append(
                    OrganizeFailure(
                        filename: track.filename,
                        reason: error.localizedDescription
                    )
                )
            }
        }
        
        return OrganizeSummary(
            totalFiles: tracks.count,
            successfulFiles: successfulFiles,
            failedFiles: failures.count,
            failures: failures
        )
    }
        
    //so that we don't overwrite anything
    private static func uniqueDestinationURL(
        for destinationURL: URL,
        fileManager: FileManager
    ) -> URL {
        
        guard fileManager.fileExists(atPath: destinationURL.path) else {
            return destinationURL
        }
        
        let folder = destinationURL.deletingLastPathComponent()
        let baseName = destinationURL.deletingPathExtension().lastPathComponent
        let fileExtension = destinationURL.pathExtension
        
        var counter = 2
        
        while true {
            let candidateFilename: String
            
            if fileExtension.isEmpty {
                candidateFilename = "\(baseName) \(counter)"
            } else {
                candidateFilename = "\(baseName) \(counter).\(fileExtension)"
            }
            
            let candidateURL = folder.appendingPathComponent(candidateFilename)
            
            if !fileManager.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            
            counter += 1
        }
    }
        
    private static func cleanPathComponent(_ value: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = value
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? "Unknown" : cleaned
    }
    
    private static func cleanFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
        let cleaned = filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? "Unknown File" : cleaned
    }
}
