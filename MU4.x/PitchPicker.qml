import QtQuick
import Muse.UiComponents

Row {
    id: root
    property bool withOctave: true
    property bool octaveEnabled: true
    property int boxWidth: 55
    readonly property string note: noteDd.currentValue
    readonly property string accidental: accDd.currentValue
    readonly property int octave: octDd.currentValue
    spacing: 5

    StyledDropdown {
        id: noteDd
        width: root.boxWidth
        currentIndex: 0
        model: ["C", "D", "E", "F", "G", "A", "B"]
        onActivated: function(index, value) { currentIndex = index }
    }
    StyledDropdown {
        id: accDd
        width: root.boxWidth
        currentIndex: 1
        model: ["♭", "♮", "♯"]
        onActivated: function(index, value) { currentIndex = index }
    }
    IncrementalPropertyControl {
        id: octDd
        visible: root.withOctave
        enabled: root.octaveEnabled
        width: root.boxWidth
        step: 1
        minValue: 0
        maxValue: 9
        currentValue: 4
        onValueEdited: function(newValue) { currentValue = newValue }
    }
}