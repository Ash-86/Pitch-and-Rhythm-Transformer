import QtQuick
import Muse.UiComponents
import Muse.Ui

Item {
    id: root
    implicitWidth: 180
    implicitHeight: 180

    // axis i lies between the circle-of-fifths neighbours cycleOfFifths[i] and cycleOfFifths[i + 1]
    readonly property var cycleOfFifths: ["D♮","A♮","E♮","B♮","F♯","D♭","A♭","E♭","B♭","F♮","C♮","G♮"]
    property int selected: 10 // default axis: C–G
    readonly property string lnote: cycleOfFifths[selected]
    readonly property string hnote: cycleOfFifths[(selected + 1) % 12]

    property int hovered: -1
    property bool pressed: false

    readonly property real angle: 2 * Math.PI / 12
    readonly property real outR: Math.min(width, height) / 2
    readonly property real centerR: outR - 15 // middle of the 30px label ring

    onSelectedChanged: canvas.requestPaint()
    onHoveredChanged: canvas.requestPaint()
    onPressedChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        function drawAxis(i, color) {
            var ctx = getContext("2d")
            var dx = root.outR * Math.cos(root.angle * i)
            var dy = root.outR * Math.sin(root.angle * i)
            ctx.strokeStyle = color
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(width / 2 - dx, height / 2 - dy)
            ctx.lineTo(width / 2 + dx, height / 2 + dy)
            ctx.stroke()
        }

        onPaint: {
            getContext("2d").clearRect(0, 0, width, height)
            drawAxis(root.selected, ui.theme.accentColor)
            if (root.hovered >= 0)
                drawAxis(root.hovered, root.pressed ? ui.theme.backgroundSecondaryColor
                                                    : (root.hovered === root.selected ? ui.theme.accentColor : ui.theme.buttonColor))
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            function sliceAt(x, y) { // slice index under the mouse, -1 outside the ring
                var dx = x - width / 2, dy = y - height / 2
                if (Math.sqrt(dx * dx + dy * dy) >= root.centerR) return -1
                var a = Math.atan2(dy, dx)
                if (a < 0) a += 2 * Math.PI
                return Math.floor((a + root.angle / 2) / root.angle) % 12
            }

            onPositionChanged: root.hovered = sliceAt(mouseX, mouseY)
            onExited: root.hovered = -1
            onPressed: root.pressed = true
            onReleased: {
                root.pressed = false
                if (root.hovered >= 0) root.selected = root.hovered
            }
        }
    }

    Repeater {
        model: ["C", "G", "D", "A", "E", "B", "F♯/G♭", "D♭", "A♭", "E♭", "B♭", "F"]
        delegate: Item {
            property int n: (index + 9) % 12
            x: root.width / 2 + Math.cos(n * root.angle + root.angle / 2) * root.centerR
            y: root.height / 2 + Math.sin(n * root.angle + root.angle / 2) * root.centerR
            StyledTextLabel {
                anchors.centerIn: parent
                textFormat: Text.RichText
                text: modelData
                font.family: "Edwin" 
            }
        }
    }
}