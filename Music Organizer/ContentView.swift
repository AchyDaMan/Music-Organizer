//
//  ContentView.swift
//  Music Organizer
//
//  Created by Achintya Yedavalli on 6/10/26.
//
import SwiftUI
import WebKit

struct ContentView: View {
    
    //  Private Variable Declarations
    @State private var sourceFolder: URL?
    @State private var outputFolder: URL?

    @State private var isScanning = false
    @State private var isOrganizing = false
    @State private var lastOrganizeFailures: [OrganizeFailure] = []
    @State private var statusMessage = "Choose a source folder."
    
    // This is dummy data - using it to test if the table showing works
    @State private var tracks: [TrackFile] = []

    @State private var mappings: [String: GenreBucketRule] = [:]

    private var detectedGenreTags: [String] {
        Array(Set(tracks.map { $0.genreTag })).sorted()
    }
    
    var body: some View {
        NavigationSplitView {
            mappingPanel
        } detail: {
            previewTable
        }
        .navigationTitle("Music Organizer")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                VStack(spacing: 2) {
                    Button(action: chooseSourceFolder) {
                        Label("Source", systemImage: "folder")
                    }
                    .help(sourceFolder?.path ?? "Select Source Folder")
                    if let source = sourceFolder {
                        Text(source.lastPathComponent)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 100)
                    }
                }
                VStack(spacing: 2) {
                    Button(action: chooseOutputFolder) {
                        Label("Output", systemImage: "externaldrive")
                    }
                    .help(outputFolder?.path ?? "Select Output Folder")
                    if let output = outputFolder {
                        Text(output.lastPathComponent)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 100)
                    }
                }
                VStack(spacing: 2) {
                    Button(action: scan) {
                        Label("Scan", systemImage: "wand.and.stars")
                    }
                    .help("Scan source folder for tracks")
                    .disabled(sourceFolder == nil || isScanning || isOrganizing)
                }
                VStack(spacing: 2) {
                    Button(action: organizeCopy) {
                        Label(isOrganizing ? "Copying..." : "Copy Clean", systemImage: "square.and.arrow.down.on.square")
                    }
                    .help("Copy tracks into the clean output folder structure")
                    .disabled(
                        tracks.isEmpty ||
                        outputFolder == nil ||
                        isOrganizing ||
                        isScanning
                    )
                }
                VStack(spacing: 2) {
                    Button(action: { tracks.removeAll() }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .help("Clear all scanned tracks")
                    .disabled(tracks.isEmpty)
                }
            }
        }
    }

    private var mappingPanel: some View {
        VStack(alignment: .leading) {
            Text("Genre Tag → Folder Rule")
                .font(.title2)
                .bold()
                .padding([.top, .horizontal])

            List(detectedGenreTags, id: \.self) { genreTag in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tag: \(genreTag)")
                        .font(.headline)

                    TextField(
                        "Parent genre, e.g. House, Techno, Drum & Bass",
                        text: Binding(
                            get: {
                                mappings[genreTag]?.parentGenre ?? ""
                            },
                            set: { newValue in
                                let current = mappings[genreTag] ?? GenreBucketRule(
                                    parentGenre: "",
                                    subgenreFolder: genreTag
                                )

                                mappings[genreTag] = GenreBucketRule(
                                    parentGenre: newValue,
                                    subgenreFolder: current.subgenreFolder
                                )
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)

                    TextField(
                        "Subgenre folder, e.g. Afro House, General House",
                        text: Binding(
                            get: {
                                mappings[genreTag]?.subgenreFolder ?? genreTag
                            },
                            set: { newValue in
                                let current = mappings[genreTag] ?? GenreBucketRule(
                                    parentGenre: "",
                                    subgenreFolder: genreTag
                                )

                                mappings[genreTag] = GenreBucketRule(
                                    parentGenre: current.parentGenre,
                                    subgenreFolder: newValue
                                )
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var previewTable: some View {
        VStack(alignment: .leading) {
            Text("Preview")
                .font(.title2)
                .bold()
                .padding([.top, .horizontal])

            if tracks.isEmpty {
                VStack(spacing: 8) {
                    Text("No tracks yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Choose a Source folder and press Scan.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(tracks) {
                    TableColumn("File") { track in
                        Text(track.filename)
                    }

                    TableColumn("Raw Genre Tag") { track in
                        Text(track.genreTag)
                    }

                    TableColumn("Parent Genre") { track in
                        let rule = mappings[track.genreTag]
                        let parentGenre = rule?.parentGenre ?? ""

                        Text(parentGenre.isEmpty ? "Unmapped" : parentGenre)
                            .foregroundStyle(parentGenre.isEmpty ? .red : .primary)
                    }

                    TableColumn("Subgenre Folder") { track in
                        let rule = mappings[track.genreTag]
                        let subgenreFolder = rule?.subgenreFolder ?? track.genreTag

                        Text(subgenreFolder)
                    }

                    TableColumn("Year") { track in
                        Text(track.releaseYear)
                    }

                    TableColumn("Destination Preview") { track in
                        Text(
                            FileOrganizer.destinationPreview(
                                for: track,
                                mappings: mappings
                            )
                        )
                    }
                }
            }
            Divider()

            HStack {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isScanning {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                
                if isOrganizing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private func chooseSourceFolder() {
        if let folder = chooseFolder(title: "Choose Source Music Folder") {
            sourceFolder = folder
            statusMessage = "Selected source folder: \(folder.lastPathComponent)"
            print("Selected source: \(folder.path)")
        }
    }

    private func chooseOutputFolder() {
        if let folder = chooseFolder(title: "Choose Output Folder") {
            outputFolder = folder
            statusMessage = "Selected output folder: \(folder.lastPathComponent)"
            print("Selected output: \(folder.path)")
        }
    }

    private func chooseFolder(title: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        let response = panel.runModal()

        guard response == .OK else {
            return nil
        }

        return panel.url
    }
    
    private func scan() {
        guard let sourceFolder else {
            statusMessage = "Choose a source folder first."
            return
        }

        statusMessage = "Scanning..."
        isScanning = true
        lastOrganizeFailures = []

        Task {
            let scannedTracks = await MusicScanner.scan(folder: sourceFolder)

            await MainActor.run {
                self.tracks = scannedTracks

                for tag in Set(scannedTracks.map { $0.genreTag }) {
                    if self.mappings[tag] == nil {
                        self.mappings[tag] = GenreBucketRule(
                            parentGenre: "",
                            subgenreFolder: tag == "Unknown Genre Tag" ? "Unknown Subgenre" : tag
                        )
                    }
                }

                self.isScanning = false
                self.statusMessage = "Found \(scannedTracks.count) audio files."
            }
        }
    }
    
    // to organize the copy procedure for output
    private func organizeCopy() {
        guard let outputFolder else {
            statusMessage = "Choose an output folder first."
            return
        }
        
        guard !tracks.isEmpty else {
            statusMessage = "Scan tracks before copying."
            return
        }
        
        isOrganizing = true
        statusMessage = "Copying files..."
        lastOrganizeFailures = []
        
        Task {
            let summary = FileOrganizer.organize(
                tracks: tracks,
                sourceRoot: sourceFolder,
                outputRoot: outputFolder,
                mappings: mappings,
                mode: .copy
            )
            
            await MainActor.run {
                self.isOrganizing = false
                self.lastOrganizeFailures = summary.failures
                
                if summary.failedFiles == 0 {
                    self.statusMessage = "Copied \(summary.successfulFiles) files successfully."
                } else {
                    self.statusMessage = "Copied \(summary.successfulFiles) files. Failed \(summary.failedFiles)."
                }
            }
        }
    }
}

