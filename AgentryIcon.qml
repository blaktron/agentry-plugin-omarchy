import QtQuick
import QtQuick.Shapes

// The Agentry mark, a shield with an A cut out of it, drawn as a vector path
// so it takes the bar's foreground colour and stays sharp at any size. The
// path is the brand's own, on a 48-unit canvas.
Item {
  id: root

  property real iconSize: 16
  property color color: "white"
  property color badgeColor: "red"
  property color badgeTextColor: "black"
  property bool warning: false

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  Shape {
    width: 48
    height: 48
    preferredRendererType: Shape.CurveRenderer
    transform: Scale { xScale: root.iconSize / 48; yScale: root.iconSize / 48 }

    ShapePath {
      strokeWidth: -1
      fillColor: root.color
      fillRule: ShapePath.OddEvenFill
      PathSvg {
        path: "M24 3 41 10.5 V 23 C 41 34.5 34 42.5 24 46.5 C 14 42.5 7 34.5 7 23 V 10.5 Z "
          + "M24 9.5 L35 38 Q29.5 32 24 32 Q18.5 32 13 38 Z M24 19.2 L27.2 27.4 H20.8 Z"
      }
    }
  }

  // A small badge when something wants the person's attention: the CLI is
  // missing, nobody is signed in, or doctor found a failing check.
  Rectangle {
    visible: root.warning
    width: Math.max(7, root.iconSize * 0.46)
    height: width
    radius: width / 2
    color: root.badgeColor
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: -width * 0.15
    anchors.bottomMargin: -width * 0.15

    Text {
      anchors.centerIn: parent
      text: "!"
      textFormat: Text.PlainText
      color: root.badgeTextColor
      font.pixelSize: Math.max(6, parent.height * 0.8)
      font.bold: true
    }
  }
}
