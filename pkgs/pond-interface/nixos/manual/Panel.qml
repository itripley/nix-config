pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "." as Manual
import "../information" as Information
import ".." as Settings
import "../.." as Shell

// The manual, drawn from State.qml's blocks.
Settings.Modal {
  id: root
  objectName: "manualPanel"
  title: ""
  implicitWidth: 500
  implicitHeight: Math.min(672, availableHeight)
  bodyTop: 0
  contentHeight: page.height
  roundedContent: true
  closeButtonY: -17
  closeLabel: "Close manual"
  Accessible.role: Accessible.Dialog
  Accessible.name: Manual.State.title
  onBackRequested: Settings.State.back()
  Keys.onEscapePressed: Settings.State.back()
  Keys.onDownPressed: scrollBy(56)
  Keys.onUpPressed: scrollBy(-56)
  Keys.onPressed: event => {
    if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
      scrollBy((scrollItem.height - 40) * (event.key === Qt.Key_PageDown ? 1 : -1));
      event.accepted = true;
    } else if (event.key === Qt.Key_Home) {
      scrollItem.contentY = 0;
      event.accepted = true;
    } else if (event.key === Qt.Key_End) {
      scrollItem.contentY = Math.max(0, contentHeight - scrollItem.height);
      event.accepted = true;
    }
  }

  readonly property color accent: Shell.PanelStyle.accent
  readonly property color line: Qt.alpha(Shell.Theme.colors.text, 0.15)
  // On an accent highlight
  readonly property color ink: "#1d1d1d"

  function scrollBy(distance) {
    scrollItem.contentY = Math.max(0, Math.min(contentHeight - scrollItem.height, scrollItem.contentY + distance));
  }

  Column {
    id: page
    objectName: "manualContent"
    width: 500
    bottomPadding: 60

    Cover {}
    Repeater {
      model: Manual.State.blocks
      delegate: Loader {
        id: block
        required property var modelData
        // In a Repeater over a JS array, the loaded item gets its block as a property
        width: 500
        sourceComponent: ({section: section, part: part, text: paragraph, row: row, tutorial: tutorial})[modelData.type]
        onLoaded: if (item.hasOwnProperty("block")) item.block = modelData
      }
    }
  }

  component Cover: Item {
    id: cover
    width: 500; height: 420
    Image {
      x: 294; y: 26; width: 176; height: 176
      source: Qt.resolvedUrl("../../assets/information/nixos.svg")
      sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
      sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
      layer.enabled: true
      layer.effect: MultiEffect { colorization: 1; colorizationColor: root.accent }
    }
    Repeater {
      id: words
      model: Manual.State.title.split(/\s+/).slice(0, 2)
      delegate: Item {
        id: word
        required property string modelData
        required property int index
        y: 190 + 84 * index
        width: 500; height: 78
        Rectangle { x: 30; width: text.implicitWidth + 12; height: 78; color: root.accent }
        Text {
          id: text
          x: 36; y: 66 - baselineOffset
          text: word.modelData
          color: root.ink
          font.family: Shell.Theme.titleFontFamily
          font.pixelSize: 88
          font.letterSpacing: -1.76
        }
        Hairline { x: 30 + text.implicitWidth + 12; y: word.index === 0 ? 0 : 77; width: 500 - x }
      }
    }
    Rectangle {
      visible: release.text !== ""
      x: 30; y: 382; width: release.implicitWidth + 18; height: 22; radius: 11
      color: "transparent"; border.width: 1; border.color: Qt.alpha(Shell.Theme.colors.text, 0.5)
      Information.Label {
        id: release
        x: 9; capY: 7
        text: Information.State.facts.os || ""
      }
    }
  }
  component Hairline: Rectangle { height: 1; color: root.accent }

  Component {
    id: section
    Item {
      property var block
      implicitHeight: 96
      readonly property bool descends: /[gjpqyQ,;]/.test(title.text)
      Rectangle {
        id: highlight
        x: 29; width: title.implicitWidth + 4
        y: 44; height: parent.descends ? 37 : 31
        color: root.accent
      }
      Text {
        id: title
        x: 31; y: 71 - baselineOffset
        text: parent.block?.text ?? ""
        color: root.ink
        font.family: Shell.Theme.titleFontFamily
        font.pixelSize: 32
        font.letterSpacing: -0.64
      }
      Hairline { x: highlight.x + highlight.width; y: highlight.y + highlight.height - 1; width: 500 - x }
    }
  }
  Component {
    id: part
    Item {
      property var block
      implicitHeight: 46
      Text {
        x: 30; anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        text: parent.block?.text ?? ""
        color: Shell.Theme.colors.text; opacity: 0.4
        font.family: Shell.Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
      }
    }
  }
  Component {
    id: paragraph
    Item {
      property var block
      readonly property bool intro: block?.intro ?? false
      implicitHeight: body.implicitHeight + 18
      Text {
        id: body
        x: 30; width: parent.intro ? 360 : 440
        text: parent.block?.text ?? ""
        textFormat: Text.MarkdownText
        wrapMode: Text.WordWrap
        color: parent.intro ? root.accent : Shell.Theme.colors.text
        linkColor: root.accent
        opacity: parent.intro ? 1 : 0.6
        font.family: Shell.Theme.fontFamily
        font.pixelSize: parent.intro ? 15 : 13
        font.weight: parent.intro ? Font.Medium : Font.Normal
        lineHeight: parent.intro ? 21 : 19; lineHeightMode: Text.FixedHeight
        onLinkActivated: link => { Settings.State.close(); Qt.openUrlExternally(link); }
        HoverHandler { enabled: body.hoveredLink !== ""; cursorShape: Qt.PointingHandCursor }
      }
    }
  }
  Component {
    id: row
    Item {
      id: rowItem
      property var block
      // Beside the label when it fits, under it when it doesn't
      readonly property bool stacked: label.implicitWidth + controls.width + 20 > 440
          && controls.width > 250
      implicitHeight: (stacked ? label.height + 10 + controls.height : Math.max(40, label.height)) + 10
      Text {
        id: label
        x: 30; y: rowItem.stacked ? 4 : (40 - height) / 2
        width: rowItem.stacked ? 440 : 440 - controls.width - 20
        text: rowItem.block?.text ?? ""
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        color: Shell.Theme.colors.text
        font.family: Shell.Theme.fontFamily; font.pixelSize: 15; font.weight: Font.Medium
      }
      Row {
        id: controls
        x: rowItem.stacked ? 30 : 470 - width
        y: rowItem.stacked ? label.y + label.height + 8 : 0
        spacing: 6
        Repeater {
          model: rowItem.block?.keys ?? []
          delegate: Row {
            id: alternative
            required property var modelData
            required property int index
            spacing: 6
            Rectangle {
              visible: alternative.index > 0
              width: 1; height: 24; color: root.line
              anchors.verticalCenter: parent.verticalCenter
            }
            Repeater {
              model: alternative.modelData
              delegate: Keycap { required property string modelData; text: modelData }
            }
          }
        }
        Rectangle {
          visible: !!rowItem.block?.code
          width: code.width + 24; height: Math.max(40, code.implicitHeight + 24); radius: 4
          color: "transparent"; border.width: 1; border.color: root.line
          Text {
            id: code
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 416)
            text: rowItem.block?.code ?? ""
            textFormat: Text.PlainText
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            color: root.accent
            font.family: "JetBrains Mono"; font.pixelSize: 12
            font.features: ({ "calt": 0, "liga": 0 }) // "--" as typed
          }
        }
      }
    }
  }
  Component {
    id: tutorial
    Item {
      id: tutorialItem
      implicitHeight: 400
      NavigationTutorial {
        x: 30; y: 10
        active: tutorialItem.parent !== null
            && tutorialItem.parent.y + tutorialItem.height > root.scrollItem.contentY
            && tutorialItem.parent.y < root.scrollItem.contentY + root.scrollItem.height
      }
    }
  }

  component Keycap: Rectangle {
    id: keycap
    property string text
    width: Math.max(40, cap.implicitWidth + 24); height: 40; radius: 4
    color: "transparent"; border.width: 1; border.color: root.line
    Rectangle {
      anchors.centerIn: parent
      width: parent.width - 8; height: 32; radius: 16
      color: "transparent"; border.width: 1; border.color: root.line
    }
    Text {
      id: cap
      anchors.centerIn: parent
      text: keycap.text
      textFormat: Text.PlainText
      color: Shell.Theme.colors.text
      font.family: Shell.Theme.fontFamily
      font.weight: keycap.text.length === 1 ? Font.Bold : Font.DemiBold
      font.pixelSize: keycap.text.length === 1 ? 12 : 10
    }
  }
}
