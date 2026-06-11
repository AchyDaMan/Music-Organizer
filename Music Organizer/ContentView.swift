//
//  ContentView.swift
//  Music Organizer
//
//  Created by Achintya Yedavalli on 6/10/26.
//
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    private enum PickerType {
        case source, output
    }

    //  Private Variable Declarations
    @State private var sourceFolder: URL?
    @State private var outputFolder: URL?

    @State private var pickerToShow: PickerType? = nil
    @State private var isFolderPickerPresented = false

    @State private var statusMessage = "Choose a source folder."
    
    // This is dummy data - using it to test if the table showing works
    @State private var tracks: [TrackFile] = [
        TrackFile(
            sourcePath: "/Users/you/Music/Messy/song1.mp3",
            filename: "song1.mp3",
            title: "Test Track One",
            artist: "Test Artist",
            genreTag: "Afro House",
            releaseYear: "2022"
        ),
        TrackFile(
            sourcePath: "/Users/you/Music/Messy/song2.flac",
            filename: "song2.flac",
            title: "Test Track Two",
            artist: "Another Artist",
            genreTag: "Hardgroove",
            releaseYear: "2023"
        ),
        TrackFile(
            sourcePath: "/Users/you/Music/Messy/song3.wav",
            filename: "song3.wav",
            title: "Test Track Three",
            artist: "Third Artist",
            genreTag: "Liquid DnB",
            releaseYear: "2021"
        )
    ]

    @State private var mappings: [String: GenreBucketRule] = [
        "Afro House": GenreBucketRule(
            parentGenre: "House",
            subgenreFolder: "Afro House"
        ),
        "House": GenreBucketRule(
            parentGenre: "House",
            subgenreFolder: "General House"
        ),
        "Liquid DnB": GenreBucketRule(
            parentGenre: "Drum & Bass",
            subgenreFolder: "Liquid DnB"
        )
    ]

    private var detectedGenreTags: [String] {
        Array(Set(tracks.map { $0.genreTag })).sorted()
    }
    
    var body: some View {
        NavigationSplitView {
            mappingPanel
        } detail: {
            previewTable
        }
        .fileImporter(
            isPresented: $isFolderPickerPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let picker = pickerToShow {
                    switch picker {
                    case .source:
                        sourceFolder = urls.first
                        print("Selected source: \(sourceFolder?.path ?? "nil")")
                    case .output:
                        outputFolder = urls.first
                        print("Selected output: \(outputFolder?.path ?? "nil")")
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
            // reset state
            pickerToShow = nil
            isFolderPickerPresented = false
        }
        .navigationTitle("Music Organizer")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                VStack(spacing: 2) {
                    Button(action: { pickerToShow = .source; isFolderPickerPresented = true }) {
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
                    Button(action: { pickerToShow = .output; isFolderPickerPresented = true }) {
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
                    .disabled(sourceFolder == nil)
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
                        let rule = mappings[track.genreTag]

                        let parentGenre = rule?.parentGenre.isEmpty == false
                            ? rule!.parentGenre
                            : "Unmapped Genre"

                        let subgenreFolder = rule?.subgenreFolder.isEmpty == false
                            ? rule!.subgenreFolder
                            : track.genreTag

                        Text("\(parentGenre)/\(subgenreFolder)/\(track.releaseYear)/\(track.filename)")
                    }
                }
            }
        }
    }
    
    private func scan() {
        guard let sourceFolder else {
            print("Scan aborted: no source folder")
            return
        }

        print("Scanning folder: \(sourceFolder.path)")
        let before = tracks.count

        // Handle security-scoped resource access if needed
        let didAccess = sourceFolder.startAccessingSecurityScopedResource()
        defer { if didAccess { sourceFolder.stopAccessingSecurityScopedResource() } }

        let scanned = MusicScanner.scan(folder: sourceFolder)
        print("Scanner returned \(scanned.count) items")

        // Normalize existing and scanned paths for more reliable de-duplication
        func normalizedPath(_ path: String) -> String {
            URL(fileURLWithPath: path).standardizedFileURL.path
        }

        let existingPaths = Set(tracks.map { normalizedPath($0.sourcePath) })
        let newOnes = scanned.filter { !existingPaths.contains(normalizedPath($0.sourcePath)) }
        print("New items after de-dup: \(newOnes.count)")

        tracks.append(contentsOf: newOnes)
        print("Tracks count before \(before) -> after \(tracks.count)")
    }
}

