pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The task list on the desktop: ~/.local/share/station/tasks.txt with one
// "[ ] task" or "[x] task" per line. Other lines are kept as they are.
Singleton {
    id: root

    readonly property string path: Theme.dataDir + "/station/tasks.txt"
    property var lines: []
    // { text, done, line }
    readonly property var items: {
        const out = [];
        for (let i = 0; i < lines.length; i++) {
            const m = lines[i].match(/^\s*\[( |x|X)\]\s*(.+)$/);
            if (m)
                out.push({ text: m[2], done: m[1] !== " ", line: i });
        }
        return out;
    }
    readonly property int doneCount: items.filter(t => t.done).length

    function toggle(item) {
        const copy = lines.slice();
        copy[item.line] = (item.done ? "[ ] " : "[x] ") + item.text;
        file.setText(copy.join("\n"));
    }

    function edit() {
        Quickshell.execDetached(["foot", "--app-id=station.editor", "nvim", path]);
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.lines = text().split("\n")
    }
}
