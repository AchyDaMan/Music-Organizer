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

    @State private var activePicker: PickerType? = nil

    @State private var statusMessage = "Choose a source folder."
    
    // This is dummy data - using it to test if the table showing works
    @State private var tracks: [TrackFile] = [
        TrackFile(
            sourcePath: "/Users/you/Music/Messy/song1.mp3",
            filename: "song1.mp3",
            title: "Test Track One",
            artist: "Test Artist",
            subgenre: "Afro House",
            releaseYear: "2022"
        ),
        TrackFile(
            sourcePath: "/Users/you/Music/Messy/song2.flac",
            filename: "song2.flac",
            title: "Test Track Two",
            artist: "Another Artist",
            subgenre: "Hardgroove",
            releaseYear: "2023"
        ),
        TrackFile(
            sourcePath: "/Users/you/Music/Messy/song3.wav",
            filename: "song3.wav",
            title: "Test Track Three",
            artist: "Third Artist",
            subgenre: "Liquid DnB",
            releaseYear: "2021"
        )
    ]

    @State private var mappings: [String: String] = [
        "Afro House": "",
        "Hardgroove": "",
        "Liquid DnB": ""
    ]

    private var detectedSubgenres: [String] {
        Array(Set(tracks.map { $0.subgenre })).sorted()
    }

    var body: some View {
        NavigationSplitView {
            subgenreMappingPanel
        } detail: {
            previewTable
        }
        .fileImporter(
            isPresented: Binding(
                get: { activePicker != nil },
                set: { if !$0 { activePicker = nil } }
            ),
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let picker = activePicker {
                    switch picker {
                    case .source:
                        sourceFolder = urls.first
                    case .output:
                        outputFolder = urls.first
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
            activePicker = nil
        }
        .navigationTitle("Music Organizer")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                VStack(spacing: 2) {
                    Button(action: { activePicker = .source }) {
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
                    Button(action: { activePicker = .output }) {
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
            }
        }
    }

    private var subgenreMappingPanel: some View {
        VStack(alignment: .leading) {
            Text("Subgenre → Genre")
                .font(.title2)
                .bold()
                .padding([.top, .horizontal])

            List(detectedSubgenres, id: \.self) { subgenre in
                VStack(alignment: .leading, spacing: 6) {
                    Text(subgenre)
                        .font(.headline)

                    TextField(
                        "Parent genre, e.g. House, Techno",
                        text: Binding(
                            get: {
                                mappings[subgenre, default: ""]
                            },
                            set: {
                                mappings[subgenre] = $0
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                }
                .padding(.vertical, 3)
            }
        }
    }

    private var previewTable: some View {
        VStack(alignment: .leading) {
            Text("Preview")
                .font(.title2)
                .bold()
                .padding([.top, .horizontal])

            Table(tracks) {
                TableColumn("File") { track in
                    Text(track.filename)
                }

                TableColumn("Subgenre") { track in
                    Text(track.subgenre)
                }

                TableColumn("Genre") { track in
                    let genre = mappings[track.subgenre, default: ""]
                    Text(genre.isEmpty ? "Unmapped" : genre)
                        .foregroundStyle(genre.isEmpty ? .red : .primary)
                }

                TableColumn("Year") { track in
                    Text(track.releaseYear)
                }

                TableColumn("Destination Preview") { track in
                    let genre = mappings[track.subgenre, default: ""]
                    let parentGenre = genre.isEmpty ? "Unmapped Genre" : genre

                    Text("\(parentGenre)/\(track.subgenre)/\(track.releaseYear)/\(track.filename)")
                }
            }
        }
    }
}

