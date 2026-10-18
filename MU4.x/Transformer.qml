/*========================================================================
Pitch and Rhythm Transformer
https://github.com/Ash-86/Pitch-and-Rhythm-Transformer

Copyright (C)2023 Ashraf El Droubi (Ash-86)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
=========================================================================*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Muse.UiComponents
import MuseScore 3.0

MuseScore {
    id: root
    title: "Transform Pitches and Rhythm"
    description: "Map, rotate, reverse or invert pitches and/or rhythm"
    version: "2"
    pluginType: "dialog"
    thumbnailName: "Transformer.jpg"
    categoryCode: ""

    width: 450
    height: 280

    // ---------------------------------------------------------------- state
    property var cur: null // working cursor
    property int startTick: 0
    property int endTick: 0
    property int startStaff: 0
    property int endStaff: 0
    property bool notesExist: false

    property var selectedScale: null
    property int selectedMode: 0

    // pitch/tpc1 are relative to C = 0 / 14, starting one octave below
    readonly property var scaleDefs: [
        { group: "Major Modes", pitch: [-12,-10,-8,-7,-5,-3,-1], tpc1: [14,16,18,13,15,17,19], modes: ["Ionian","Dorian","Phrygian","Lydian","Mixolydian","Aeolian","Locrian"] },
        { group: "Melodic Minor Modes", pitch: [-12,-10,-9,-7,-5,-3,-1], tpc1: [14,16,11,13,15,17,19], modes: ["Melodic Minor","Dorian♭2 (Phrygian ♯6)","Lydian augmented","Lydian♭7","Mixolydian♭6","Locrian ♯2 (Aeolian♭5)","Altered scale"] },
        { group: "Harmonic Minor Modes", pitch: [-12,-10,-9,-7,-5,-4,-1], tpc1: [14,16,11,13,15,10,19], modes: ["Harmonic Minor","Locrian ♮6","Ionian ♯5","Dorian ♯4","Mixolydian ♭9","Lydian ♯2","Altered scale ♭♭7"] },
        { group: "Other", pitch: [-12,-10,-8,-7,-5,-4,-1], tpc1: [14,16,18,13,15,10,19], modes: ["Harmonic Major"] },
        { group: "Other", pitch: [-12,-11,-8,-7,-5,-4,-1], tpc1: [14,9,18,13,15,10,19], modes: ["Double Harmonic"] },
        { group: "Other", pitch: [-12,-11,-9,-8,-6,-5,-3,-2], tpc1: [14,21,23,18,20,15,17,11], modes: ["Half-Whole"] },
        { group: "Other", pitch: [-12,-10,-9,-7,-6,-4,-3,-1], tpc1: [14,16,11,13,20,22,17,19], modes: ["Whole-Half"] },
        { group: "Other", pitch: [-12,-10,-8,-6,-4,-2], tpc1: [14,16,18,20,22,24], modes: ["Whole Tone"] },
        { group: "Other", pitch: [-12,-10,-8,-5,-3], tpc1: [14,16,18,15,17], modes: ["Major Pentatonic"] },
        { group: "Other", pitch: [-12,-9,-7,-5,-2], tpc1: [14,11,13,15,12], modes: ["Minor Pentatonic"] }
    ]

    // ------------------------------------------------------------ entry point
    function showError(msg) {
        errorDialog.text = msg
        errorDialog.open()
    }

    function validate() {
        var opts = [rotateOpts, reverseOpts, invertOpts]
        var tab = bar.currentIndex
        if (tab < 3 && opts[tab].current < 0) return "Please select an option."
        if (tab === 3) {
            if (!selectedScale) return "Please choose a scale."
            if (!mapScaleBtn.checked && !colorNotesBtn.checked) return "Please select an option."
        }
        return null
    }

    function applyTransform() {
        cur = curScore.newCursor()
        cur.rewind(1)
        if (!cur.segment) return showError("No valid range selection on current score!")

        var err = validate()
        if (err) return showError(err)

        cur.rewind(2) // end of selection
        endTick = cur.tick || curScore.lastSegment.tick + 1 // tick 0 = selected to score end
        endStaff = cur.staffIdx + 1
        cur.rewind(1) // start of selection
        startTick = cur.tick
        startStaff = cur.staffIdx

        var els = curScore.selection.elements
        var tracks = []
        notesExist = false
        for (var i = 0; i < els.length; i++) {
            if (els[i].type === Element.NOTE) notesExist = true
            if (tracks.indexOf(els[i].track) < 0) tracks.push(els[i].track)
        }

        curScore.startCmd()
        tracks.forEach(function(t) {
            cur.track = t
            cur.rewindToTick(startTick)
            if (!cur.element) return // voice doesn't exist
            switch (bar.currentIndex) {
            case 0: rotate(rotateOpts.current); break
            case 1: reverse(reverseOpts.current); break
            case 2: invertTrack(invertOpts.current, invertType.checked); break
            case 3: mapScale(); break
            case 4: mapPitch(); break
            }
        })
        curScore.endCmd()
    }

    // ------------------------------------------------------- shared helpers
    function forEachNote(fn) {
        cur.rewindToTick(startTick)
        while (cur.segment && cur.tick < endTick) {
            var el = cur.element
            if (el && el.type === Element.CHORD)
                for (var n = 0; n < el.notes.length; n++) fn(el.notes[n])
            cur.next()
        }
    }

    function getTrans() { // instrument transposition (tpc2 - tpc1)
        var t
        forEachNote(function(n) { if (t === undefined) t = n.tpc2 - n.tpc1 })
        return t === undefined ? 0 : t
    }

    function getPivot(noteName, accidental, octave) { // pitch/tpc from user input
        var trans = getTrans()
        var concert = curScore.style.value('concertPitch')
        var TV = concert ? [0, 0, trans] : [-(trans * 7) % 12, -trans, 0] // [pitch, tpc1, tpc2]
        var base = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 }[noteName]
        var tpcBase = { C: 14, D: 16, E: 18, F: 13, G: 15, A: 17, B: 19 }[noteName]
        var acc = ["♭", "♮", "♯"].indexOf(accidental) - 1 // -1, 0, +1
        var pivot = {
            pitch: base + TV[0] + acc + (octave + 1) * 12, // MuseScore octaves start at -1
            tpc1: tpcBase + TV[1] + 7 * acc, // a sharp/flat is +/-7 in tpc
            tpc2: tpcBase + TV[2] + 7 * acc
        }
        pivot.tpc = concert ? pivot.tpc1 : pivot.tpc2
        return pivot
    }

    function normalizeTpc() { // keep tpc within 6..26 (no double sharps/flats)
        var hi = -99, lo = 99
        forEachNote(function(n) { hi = Math.max(hi, n.tpc); lo = Math.min(lo, n.tpc) })
        var shift = hi > 26 ? -Math.ceil((hi - 26) / 12) : (lo < 6 ? Math.ceil((6 - lo) / 12) : 0)
        if (shift)
            forEachNote(function(n) { n.tpc1 += shift * 12; n.tpc2 += shift * 12 })
    }

    // ----------------------------------------------- rotate / retrograde
    function getArrays() { // pitches (with rests), onlyPitches (chords), rhythm, highest/lowest note
        var pitches = [], onlyPitches = [], rhythm = []
        var Hnote = { pitch: 0, tpc: 0, tpc1: 0, tpc2: 0 }
        var Lnote = { pitch: 128, tpc: 128, tpc1: 128, tpc2: 128 }

        cur.rewindToTick(startTick)
        while (cur.segment && cur.tick < endTick) {
            var el = cur.element
            var chord = []
            if (el.type === Element.REST) {
                chord = 'REST'
            } else if (el.type === Element.CHORD) {
                for (var n = 0; n < el.notes.length; n++) {
                    var nt = el.notes[n]
                    var item = { pitch: nt.pitch, tpc: nt.tpc, tpc1: nt.tpc1, tpc2: nt.tpc2 }
                    if (nt.pitch > Hnote.pitch) Hnote = item
                    if (nt.pitch < Lnote.pitch) Lnote = item
                    chord.push(item)
                }
                onlyPitches.push(chord)
            }
            pitches.push(chord)

            var d = { dur: [el.duration.numerator, el.duration.denominator], tup: null }
            if (el.tuplet) {
                d.tup = {
                    dur : [el.tuplet.globalDuration.numerator, el.tuplet.globalDuration.denominator],
                    ratio : [el.tuplet.actualNotes, el.tuplet.normalNotes],
                    len : el.tuplet.elements.length
                }
            }
            rhythm.push(d)
            cur.next()
        }

        if (!onlyPitches.length && !notesExist) {
            showError("Selection empty. No changes made!")
            return null
        }
        return { pitches: pitches, onlyPitches: onlyPitches, rhythm: rhythm, Hnote: Hnote, Lnote: Lnote }
    }

    function rePitch(pitches) { // rewrite pitches only, keep rhythm
        var i = 0
        cur.rewindToTick(startTick)
        while (cur.segment && cur.tick < endTick) {
            var el = cur.element
            if (el.type === Element.CHORD) {
                for (var n = el.notes.length - 1; n >= 1; n--) el.remove(el.notes[n]) // keep lowest note
                var p = pitches[i++]
                el.notes[0].pitch = p[0].pitch
                el.notes[0].tpc1 = p[0].tpc1
                el.notes[0].tpc2 = p[0].tpc2
                for (var k = 1; k < p.length; k++) {
                    cur.addNote(p[k].pitch, true)
                    cur.prev()
                }
            }
            cur.next()
        }
        curScore.selection.selectRange(startTick, endTick, startStaff, endStaff)
    }

    function reWrite(pitches, rhythm) { // rewrite pitches and rhythm
        cur.rewindToTick(startTick)
        while (cur.segment && cur.tick < endTick) {
            var el = cur.element
            if (el.tuplet) removeElement(el.tuplet) // tuplets must be removed explicitly
            cur.next()
        }
        cur.rewindToTick(startTick)

        var left = 0 // elements still to enter in the current tuplet
        for (var i = 0; i < pitches.length; i++) {
            var r = rhythm[i]
            if (r.tup && left === 0) {
                cur.addTuplet(fraction(r.tup.ratio[0], r.tup.ratio[1]), fraction(r.tup.dur[0], r.tup.dur[1]))
                left = r.tup.len
            }
            if (left > 0) left--

            cur.setDuration(r.dur[0], r.dur[1])
            var p = pitches[i]
            if (p === 'REST') cur.addRest()
            else p.forEach(function(note, j) { cur.addNote(note.pitch, j > 0) })
        }
    }

    function getStep(rhythm, input) { // tuplet at a selection end: rotate by whole tuplet
        var first = rhythm[0], last = rhythm[rhythm.length - 1]
        if (input > 0 && last.tup) return last.tup.len
        if (input < 0 && first.tup) return -first.tup.len
        return input
    }

    function rotateArray(arr, step) {
        var len = arr.length
        return arr.map(function(_, i) { return arr[(((i - step) % len) + len) % len] })
    }

    function rotate(opt) {
        var a = getArrays()
        if (!a) return
        var step = getStep(a.rhythm, stepBox.currentValue)
        applyOpt(opt, a, function(arr) { return rotateArray(arr, step) })
    }

    function reverse(opt) {
        var a = getArrays()
        if (!a) return
        applyOpt(opt, a, function(arr) { return arr.slice().reverse() })
    }

    function applyOpt(opt, a, f) { // f: array -> array; 0 pitches, 1 rhythm, 2 both
        if (opt === 0) rePitch(f(a.onlyPitches))
        else if (opt === 1) reWrite(a.pitches, f(a.rhythm))
        else reWrite(f(a.pitches), f(a.rhythm))
        curScore.selection.selectRange(startTick, endTick, startStaff, endStaff)
    }

    // ------------------------------------------------------------- invert

    function diatonicIdx(note, map) {
        var i = map.pitch.indexOf(note.pitch)
        if (i >= 0) return i
        var next = map.pitch.indexOf(note.pitch + 1)
        var nextTpc = (curScore.style.value('concertPitch') ? map.tpc1 : map.tpc2)[next]
        return note.tpc + 7 === nextTpc ? next : map.pitch.indexOf(note.pitch - 1)
    }

    function diatonicPivotIdx(pivot, map) {
        var i = map.pitch.indexOf(pivot.pitch)
        return i >= 0 ? i : map.pitch.indexOf(pivot.pitch + 1) - 0.5
    }

    function invertTrack(opt, chromatic) { // 0 outermost, 1 specific pitch, 2 negative harmony
        var L, H, pivot
        if (opt === 1) {
            pivot = getPivot(invertPicker.note, invertPicker.accidental, invertPicker.octave)
        } else {
            var a = getArrays()
            if (!a) return
            L = a.Lnote
            H = a.Hnote
            if (opt === 2) {
                var ln = negativeHarmony.lnote, hn = negativeHarmony.hnote
                var l0 = getPivot(ln[0], ln[1], 0), h0 = getPivot(hn[0], hn[1], 0) // axis in octave 0
                var k = Math.round(((L.pitch + H.pitch) / 2 - (l0.pitch + h0.pitch) / 2) / 12)
                L = getPivot(ln[0], ln[1], k)
                H = getPivot(hn[0], hn[1], k)
            }
            pivot = { pitch: (L.pitch + H.pitch) / 2, tpc1: (L.tpc1 + H.tpc1) / 2, tpc2: (L.tpc2 + H.tpc2) / 2 }
        }

        if (chromatic) {
            forEachNote(function(n) {
                n.pitch = 2 * pivot.pitch - n.pitch
                n.tpc1 = 2 * pivot.tpc1 - n.tpc1
                n.tpc2 = 2 * pivot.tpc2 - n.tpc2
            })
        } else {
            var map = buildScale(scaleDefs[0], (7 * curScore.keysig) % 12) // diatonic scale // JS % keeps sign: -3 flats -> -9, keeps Eb not D#
            var pivotIdx = opt === 1 ? diatonicPivotIdx(pivot, map)
                                     : (diatonicIdx(L, map) + diatonicIdx(H, map)) / 2
            forEachNote(function(n) {
                var idx = 2 * pivotIdx - diatonicIdx(n, map)
                n.pitch = map.pitch[idx]
                n.tpc1 = map.tpc1[idx]
                n.tpc2 = map.tpc2[idx]
            })
        }
        normalizeTpc()
    }

    // -------------------------------------------------------------- map scale
    function buildScale(scale, interval) { // transpose by signed interval (sign keeps spelling), repeat over 11 octaves
        var shift = ((interval % 12) + 12) % 12 // pitch classes only: keeps coverage of 0..127
        var tpc1 = scale.tpc1.map(function(x) { return x + interval * 7 })
        while (tpc1.some(function(x) { return x > 26 })) tpc1 = tpc1.map(function(x) { return x - 12 })
        while (tpc1.some(function(x) { return x < 6 })) tpc1 = tpc1.map(function(x) { return x + 12 })
        var trans = getTrans()
        var map = { pitch: [], tpc1: [], tpc2: [] }
        for (var j = 0; j < 11; j++) {
            scale.pitch.forEach(function(p) { map.pitch.push(p + shift + 12 * j) })
            tpc1.forEach(function(t) { map.tpc1.push(t); map.tpc2.push(t + trans) })
        }
        return map
    }

    function performMapping(map) {
        forEachNote(function(n) {
            var up = 0, down = 0
            while (map.pitch.indexOf(n.pitch + up) < 0) up++
            while (map.pitch.indexOf(n.pitch + down) < 0) down--
            var offset = (up < -down) ? up : down
            if (up === -down && up !== 0) // equidistant: decide by spelling
                offset = (n.tpc1 - map.tpc1[map.pitch.indexOf(n.pitch + down)] === 7) ? down : up
            var idx = map.pitch.indexOf(n.pitch + offset)
            n.pitch = map.pitch[idx]
            n.tpc1 = map.tpc1[idx]
            n.tpc2 = map.tpc2[idx]
        })
    }

    function colorNotes(map) {
        var red = "#e21c48"
        forEachNote(function(n) {
            if (map.pitch.indexOf(n.pitch) >= 0) return
            n.color = red
            if (n.accidental) n.accidental.color = red
            for (var i = 0; n.dots && i < n.dots.length; i++) n.dots[i].color = red
        })
    }

    function mapScale() {
        var pivot = getPivot(mapPicker.note, mapPicker.accidental, -1)
        var interval = pivot.pitch - (selectedScale.pitch[selectedMode] + 12) // +12: scale tables start at -12
        var map = buildScale(selectedScale, interval)
        if (mapScaleBtn.checked) performMapping(map)
        else colorNotes(map)
    }

    function buildModeMenu() {
        var groups = {}, order = []
        scaleDefs.forEach(function(s, si) {
            if (!groups[s.group]) {
                groups[s.group] = { id: String(order.length), title: s.group, subitems: [] }
                order.push(s.group)
            }
            s.modes.forEach(function(m, mi) { groups[s.group].subitems.push({ id: si + ":" + mi, title: m }) })
        })
        return order.map(function(g) { return groups[g] })
    }

    // -------------------------------------------------------------- map pitch
    function mapPitch() {
        var m = myMapPitch
        var oldN = getPivot(m.noteIn, m.accIn, m.octIn)
        var newN = getPivot(m.noteOut, m.accOut, m.octOut)

        function fixPitch(scorePitch, p) {
            if (m.down) {
                while (scorePitch - p <= 0) p -= 12
                while (scorePitch - p > 12) p += 12
            }
            if (m.up) {
                while (p - scorePitch <= 0) p += 12
                while (p - scorePitch > 12) p -= 12
            }
            return p
        }

        forEachNote(function(n) {
            var match = m.allOct ? (n.pitch - oldN.pitch) % 12 == 0 : n.pitch == oldN.pitch
            if (match && !m.enharm) match = (n.tpc == oldN.tpc1 || n.tpc == oldN.tpc2)
            if (!match) return
            if (m.filter) {
                curScore.selection.select(n, true)
            } else {
                n.pitch = fixPitch(n.pitch, newN.pitch)
                n.tpc1 = newN.tpc1
                n.tpc2 = newN.tpc2
            }
        })
    }

    // ================================================================== UI
    MessageDialog {
        id: errorDialog
        title: "Caution"
        text: ""
        onAccepted: errorDialog.close()
    }

    component OptionGroup: Column {
        id: og
        property var options: []
        property int current: -1
        spacing: 12
        ButtonGroup { id: grp }
        Repeater {
            model: og.options
            RoundedRadioButton {
                ButtonGroup.group: grp
                text: modelData
                onCheckedChanged: if (checked) og.current = index
            }
        }
    }

    StyledTabBar {
        id: bar
        currentIndex: 0
        anchors.left: parent.left
        anchors.leftMargin: 15
        StyledTabButton { text: "Rotate" }
        StyledTabButton { text: "Retrograde" }
        StyledTabButton { text: "Invert" }
        StyledTabButton { text: "Map Scale" }
        StyledTabButton { text: "Map Pitch" }
    }
    SeparatorLine {
        id: sep
        anchors.top: bar.bottom
    }

    StackLayout {
        currentIndex: bar.currentIndex
        anchors {
            top: sep.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 20
        }

        // Rotate
        Item {
            ColumnLayout {
                spacing: 35
                OptionGroup {
                    id: rotateOpts
                    options: ["Rotate Pitches", "Rotate Rhythm", "Rotate Pitches and Rhythm"]
                }
                RowLayout {
                    Layout.leftMargin: 25
                    spacing: 5
                    StyledTextLabel { text: "Steps by which to rotate: " }
                    IncrementalPropertyControl {
                        id: stepBox
                        width: 60
                        Layout.preferredWidth: 60
                        step: 1
                        minValue: -10
                        maxValue: 10
                        currentValue: 1
                        onValueEdited: function(newValue) { currentValue = newValue }
                    }
                }
            }
        }

        // Retrograde
        Item {
            OptionGroup {
                id: reverseOpts
                options: ["Reverse Pitches", "Reverse Rhythm", "Reverse Pitches and Rhythm"]
            }
        }

        // Invert
        Item {
            ColumnLayout {
                spacing: 12
                StyledTextLabel { text: "Invert Using:" }
                OptionGroup {
                    id: invertOpts
                    options: ["Outermost Pitches", "Specific Pitch:", "Axis (Negative Harmony):"]
                }
                RowLayout {
                    spacing: 10
                    Layout.topMargin: 18
                    StyledTextLabel { text: "Diatonic" }
                    ToggleButton {
                        id: invertType
                        checked: true
                        onToggled: checked = !checked
                    }
                    StyledTextLabel { text: "Chromatic" }
                }
            }
            PitchPicker {
                id: invertPicker
                visible: invertOpts.current === 1
                x: 190
                y: 68
            }
            MyCircle {
                id: negativeHarmony
                visible: invertOpts.current === 2
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 30
            }
        }

        // Map Scale
        Item {
            ColumnLayout {
                spacing: 15
                StyledTextLabel { text: "Map Unto:" }
                Row {
                    spacing: 5
                    PitchPicker {
                        id: mapPicker
                        withOctave: false
                    }
                    FlatButton {
                        FlatButtonMenuIndicatorTriangle {}
                        id: menuButton
                        text: "select mode"
                        onClicked: menuLoader.toggleOpened(root.buildModeMenu())

                        StyledMenuLoader {
                            id: menuLoader
                            onHandleMenuItem: function(itemId) {
                                var parts = itemId.split(":")
                                root.selectedScale = root.scaleDefs[parseInt(parts[0])]
                                root.selectedMode = parseInt(parts[1])
                                menuButton.text = root.selectedScale.modes[root.selectedMode]
                            }
                        }
                    }
                }
                Column {
                    spacing: 10
                    CheckBox {
                        id: colorNotesBtn
                        text: qsTr("Color non-scale notes")
                        onClicked: checked = !checked
                    }
                    CheckBox {
                        id: mapScaleBtn
                        text: qsTr("Map notes to scale")
                        checked: true
                        onClicked: checked = !checked
                    }
                }
            }
        }

        // Map Pitch
        Item {
            MyMapPitch { id: myMapPitch }
        }
    }

    RowLayout {
        spacing: 5
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 10
        }
        FlatButton {
            text: qsTr("Apply")
            accentButton: true
            onClicked: applyTransform()
        }
        FlatButton {
            text: qsTr("Close")
            onClicked: root.parent.Window.window.close()
        }
    }

    Shortcut {
        sequence: "Esc"
        onActivated: root.parent.Window.window.close()
    }
}
