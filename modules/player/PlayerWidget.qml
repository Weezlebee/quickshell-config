import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

RowLayout {
    id: root
    spacing: 6

    property string songTitle: "Title"
    property string songArtist: "Artist"

    // Process to track Metadata changes (Title and Artist)
    Process {
        id: metadataTracker
        command: ["playerctl", "-p", "spotify", "metadata", "--format", "{{title}} - {{artist}}", "-F"]
        running: true
        
        stdout: SplitParser {
            onRead: (line) => {
                var cleaned = line.trim();
                
                // If Spotify closes or returns empty data, reset to fallback values
                if (cleaned === "") {
                    root.songTitle = "Title";
                    root.songArtist = "Artist";
                    return;
                }

                var parts = cleaned.split(" - ");
                if (parts.length >= 2) {
                    root.songTitle = parts[0].trim();
                    root.songArtist = parts[1].trim();
                } else {
                    root.songTitle = cleaned;
                    root.songArtist = "";
                }
            }
        }
    }

    // Purely Visual Layout (No active control buttons or actions)
    RowLayout {
        spacing: 4
        
        Text {
            text: "󰎆" // Simple music note icon
            color: Theme.rose
            font.bold: true
            font.pixelSize: 14
        }
        
        Text {
            text: root.songTitle
            color: Theme.text
            font.bold: true
            font.pixelSize: 14
            elide: Text.ElideRight
            Layout.maximumWidth: 150
        }
        
        Text {
            text: root.songArtist ? "- " + root.songArtist : ""
            color: Theme.subText
            font.pixelSize: 14
            elide: Text.ElideRight
            Layout.maximumWidth: 100
        }
    }
}