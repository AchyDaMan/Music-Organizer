# Music Organizer

A native macOS application for scanning, tagging, and reorganizing music libraries into a clean, consistent folder structure based on genre metadata.

> **Disclosure:** A majority of the code in this project, as well as this README, was generated with the assistance of AI tools (ChatGPT and Claude). All AI-generated code has been reviewed and tested by the project author.

---

## Features

- **Recursive folder scanning** — finds MP3, WAV, and FLAC files in any directory
- **Metadata extraction** — reads title, artist, genre, and release year from ID3/iTunes/QuickTime audio tags, with filename-based fallbacks
- **Custom genre mapping** — define rules that map raw genre tags to parent genre and subgenre folder names
- **Live preview** — see exactly where each file will land before committing any changes
- **Copy or move** — choose whether to copy files to the output folder or move them
- **Duplicate handling** — automatically appends a number when a filename already exists at the destination
- **Persistent mappings** — genre rules are saved to disk and restored between sessions
- **Error reporting** — detailed per-file success/failure summary after each organize run

---

## How It Works

Files are organized into the following structure:

```
OutputFolder/
└── ParentGenre/
    └── Subgenre/
        └── Year/
            └── filename.mp3
```

For example, a file tagged as `"dnb"` that you map to parent `Electronic` and subgenre `Drum and Bass` released in 2019 would land at:

```
OutputFolder/Electronic/Drum and Bass/2019/track.mp3
```

---

## Usage

1. Click **Source** and select the folder containing your music files
2. Click **Scan** — the app discovers all audio files and extracts their metadata
3. For each detected genre tag, fill in the **Parent Genre** and **Subgenre** fields in the left panel
4. Review the live preview table on the right — unmapped genres are highlighted in red
5. Click **Copy Clean** to copy the organized files to the output folder (or **Move** to move them)
6. Check the status bar for a success/failure summary

---

## Requirements

- macOS 26.5 or later
- Xcode 26.5 (to build from source)

---

## Installation
1. Download the latest release from GitHub.
2. Run the .pkg and follow its instructions
3. Run the application (Default: Applications folder)

---

## Building from Source

1. Clone the repository
2. Open `Music Organizer.xcodeproj` in Xcode
3. Select the **Music Organizer** scheme and your Mac as the target
4. Press **Cmd+R** to build and run

---

## Architecture

| File | Responsibility |
|---|---|
| `Music_OrganizerApp.swift` | App entry point |
| `ContentView.swift` | Main UI — mapping panel, preview table, toolbar |
| `Models.swift` | Data types: `TrackFile`, `GenreBucketRule` |
| `MusicScanner.swift` | Recursive audio file discovery |
| `AudioTagReader.swift` | AVFoundation-based metadata extraction |
| `FileOrganizer.swift` | Destination path building, copy/move, collision handling |
| `MappingStore.swift` | JSON persistence of genre mapping rules |

Genre mappings are saved to `~/Library/Application Support/Music Organizer/genre_mappings.json`.

---

## License

This project is provided as-is for personal use.
