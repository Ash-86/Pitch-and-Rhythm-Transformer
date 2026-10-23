import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Muse.UiComponents

Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    readonly property string noteIn: fromPicker.note
    readonly property string accIn: fromPicker.accidental
    readonly property int octIn: fromPicker.octave
    readonly property string noteOut: toPicker.note
    readonly property string accOut: toPicker.accidental
    readonly property int octOut: toPicker.octave
    readonly property bool allOct: allOctaves.checked
    readonly property bool enharm: enharmonic.checked
    readonly property bool up: upBtn.checked
    readonly property bool down: downBtn.checked
    readonly property bool filter: selectRadio.checked

    component ToggleFlat: FlatButton {
        property bool checked: accentButton
        onClicked: accentButton = !accentButton
    }

    ButtonGroup { id: modeGroup }

    Column {
        id: col
        spacing: 15

        RowLayout {
            spacing: 20
            RoundedRadioButton {
                id: mapRadio
                text: "Map Pitch"
                checked: true
                ButtonGroup.group: modeGroup
            }
            RoundedRadioButton {
                id: selectRadio
                text: "Filter/Select Pitch"
                ButtonGroup.group: modeGroup
            }
        }

        Row {
            spacing: 2
            PitchPicker {
                id: fromPicker
                boxWidth: 50
                spacing: 2
                octaveEnabled: !allOctaves.checked
            }
            ToggleFlat { id: allOctaves; text: "All Octaves"; isNarrow: true }
            ToggleFlat { id: enharmonic; text: "Enharmonic notes" }
        }

        Column {
            enabled: !selectRadio.checked
            opacity: enabled ? 1 : 0.4
            spacing: 15
            StyledTextLabel { text: "To:" }
            Row {
                spacing: 2
                PitchPicker {
                    id: toPicker
                    boxWidth: 50
                    spacing: 2
                    octaveEnabled: !upBtn.checked && !downBtn.checked
                }
                ToggleFlat {
                    id: upBtn
                    text: "Up"
                    width: 50
                    onAccentButtonChanged: if (accentButton) downBtn.accentButton = false
                }
                ToggleFlat {
                    id: downBtn
                    text: "Down"
                    width: 50
                    onAccentButtonChanged: if (accentButton) upBtn.accentButton = false
                }
            }
        }
    }
}