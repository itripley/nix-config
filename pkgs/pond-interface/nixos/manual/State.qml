pragma Singleton
import QtQuick
import QtCore
import "../information" as Information
import ".." as Settings
import Quickshell
import Quickshell.Io

// What the manual shows: ~/.config/niri/manual.md, with the keys from niri's config (binds.py).
// Both are read each time it opens. The Markdown it knows:
//   # Title         ## Section        ### Part
//   - `command` text        - [Alt+B] text
//   {keys}   {tutorial}     and paragraphs (the first one under a section is the intro)
Singleton {
  id: root
  readonly property bool active: Settings.State.opened && Settings.State.page === "manual"
  readonly property string helper: decodeURIComponent(Qt.resolvedUrl("binds.py").toString().replace(/^file:\/\//, ""))
  property string source: ""
  property var binds: []
  property string bindsError: ""
  readonly property string title: (source.match(/^# +(.+)$/m) || ["", "User Manual"])[1].trim()
  readonly property var blocks: parse(source)

  onActiveChanged: if (active) {
    file.reload();
    query.running = true;
    if (!Information.State.facts.osVersion) Information.State.refresh(false);
  }

  FileView {
    id: file
    path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/niri/manual.md"
    printErrors: false
    onLoaded: root.source = text()
    onLoadFailed: root.source = "## Nothing here yet\nThe manual is ~/.config/niri/manual.md, and it isn't there.\n\n## Keys\n{keys}"
  }
  Process {
    id: query
    command: ["python3", root.helper]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.binds = JSON.parse(text); root.bindsError = ""; }
        catch (e) { root.binds = []; root.bindsError = "Couldn't read the keys from niri's config."; }
      }
    }
  }

  function keyRows() {
    if (bindsError) return [{type: "text", text: bindsError, intro: false}];
    const rows = [];
    for (const section of binds) {
      rows.push({type: "part", text: section.section});
      for (const row of section.rows) rows.push({type: "row", text: row.label, keys: row.keys, code: ""});
    }
    return rows;
  }
  function parse(markdown) {
    let result = [], paragraph = [], intro = false;
    const flush = () => {
      if (paragraph.length) result.push({type: "text", text: paragraph.join(" "), intro: intro});
      if (paragraph.length) intro = false;
      paragraph = [];
    };
    for (const line of markdown.replace(/<!--[\s\S]*?-->/g, "").split("\n").map(l => l.trim())) {
      const heading = line.match(/^(#{1,3}) +(.+)$/);
      const row = line.match(/^- (?:`([^`]+)`|\[([^\]]+)\]) *(.*)$/);
      if (!line || heading || row || line === "{keys}" || line === "{tutorial}") flush();
      if (heading) {
        if (heading[1].length > 1) result.push({type: heading[1].length === 2 ? "section" : "part", text: heading[2]});
        intro = heading[1].length === 2;
      } else if (row) {
        // "+" separates keys; a "+" at the end is the key itself
        const keys = row[2] ? [row[2].toLowerCase().replace(/\+\+$/, "+plus").split("+").map(k => ({plus: "+", super: "spr", mod: "spr"})[k.trim()] ?? k.trim())] : [];
        result.push({type: "row", text: row[3], keys: keys, code: row[1] || ""});
        intro = false;
      } else if (line === "{keys}") result = result.concat(keyRows());
      else if (line === "{tutorial}") result.push({type: "tutorial"});
      else if (line) paragraph.push(line);
    }
    flush();
    return result;
  }
}
