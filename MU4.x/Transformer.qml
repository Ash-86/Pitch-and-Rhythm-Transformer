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
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
    version: "3"
    pluginType: "dialog"
    thumbnailName: "Transformer.jpg"
    categoryCode: ""

    width: 450
    height: 300

    // ---------------------------------------------------------------- state
    property var cur: null          // working cursor
    property int startTick: 0
    property int endTick: 0
    property int startStaff: 0
    property int endStaff: 0
    property bool notesExist: false
    property int rotDir: 1 // 1 forward, -1 backward
    property bool keepTuplets: true // off: always re-notate from the beat grid
    property bool fallbackGrid: true // off: cancel when a broken tuplet can't be regrouped
    readonly property int whole: 201600 // 1920 ticks * 105: whole note in integer units, exact for 3, 5 and 7 tuplets

    property var selectedScale: scaleDefs[0]
    property int selectedMode: 0

    // pitch/tpc1 are relative to C = 0 / 14, starting one octave below
    readonly property var scaleDefs: [
        { group: "Major Modes",             pitch: [-12,-10,-8,-7,-5,-3,-1],    tpc1: [14,16,18,13,15,17,19],       modes: ["Ionian","Dorian","Phrygian","Lydian","Mixolydian","Aeolian","Locrian"] },
        { group: "Melodic Minor Modes",     pitch: [-12,-10,-9,-7,-5,-3,-1],    tpc1: [14,16,11,13,15,17,19],       modes: ["Melodic Minor","Dorian♭2 (Phrygian ♯6)","Lydian augmented","Lydian♭7","Mixolydian♭6","Locrian ♯2 (Aeolian♭5)","Altered scale"] },
        { group: "Harmonic Minor Modes",    pitch: [-12,-10,-9,-7,-5,-4,-1],    tpc1: [14,16,11,13,15,10,19],       modes: ["Harmonic Minor","Locrian ♮6","Ionian ♯5","Dorian ♯4","Mixolydian ♭9","Lydian ♯2","Altered scale ♭♭7"] },
        { group: "Other",                   pitch: [-12,-10,-8,-7,-5,-4,-1],    tpc1: [14,16,18,13,15,10,19],       modes: ["Harmonic Major"] },
        { group: "Other",                   pitch: [-12,-11,-8,-7,-5,-4,-1],    tpc1: [14,9,18,13,15,10,19],        modes: ["Double Harmonic"] },
        { group: "Other",                   pitch: [-12,-11,-9,-8,-6,-5,-3,-2], tpc1: [14,21,23,18,20,15,17,11],    modes: ["Half-Whole"] },
        { group: "Other",                   pitch: [-12,-10,-9,-7,-6,-4,-3,-1], tpc1: [14,16,11,13,20,22,17,19],    modes: ["Whole-Half"] },
        { group: "Other",                   pitch: [-12,-10,-8,-6,-4,-2],       tpc1: [14,16,18,20,22,24],          modes: ["Whole Tone"] },
        { group: "Other",                   pitch: [-12,-10,-8,-5,-3],          tpc1: [14,16,18,15,17],             modes: ["Major Pentatonic"] },
        { group: "Other",                   pitch: [-12,-9,-7,-5,-2],           tpc1: [14,11,13,15,12],             modes: ["Minor Pentatonic"] }
    ]

    // ------------------------------------------------------------ entry point
    function showError(msg) {
        errorDialog.text = msg
        errorDialog.open()
    }

    function applyTransform() {
        cur = curScore.newCursor()
        cur.rewind(1)
        if (!cur.segment) return showError("No valid range selection on current score!")

        cur.rewind(2)                                   // end of selection
        endTick = cur.tick || curScore.lastSegment.tick + 1   // tick 0 = selected to score end
        endStaff = cur.staffIdx + 1
        cur.rewind(1)                                   // start of selection
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
            if (!cur.element) return                    // voice doesn't exist
            switch (bar.currentIndex) {
            case 0:
                if (orderOp.current === 0) rotate(orderTarget.current)
                else reverse(orderTarget.current)
                break
            case 1: invertTrack(invertOpts.current, chromaticBtn.checked); break
            case 2: mapScale(); break
            case 3: mapPitch(); break
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

    function getTrans() {   // instrument transposition (tpc2 - tpc1)
        var t
        forEachNote(function(n) { if (t === undefined) t = n.tpc2 - n.tpc1 })
        return t === undefined ? 0 : t
    }

    function getPivot(noteName, accidental, octave) {   // pitch/tpc from user input
        var trans = getTrans()
        var concert = curScore.style.value('concertPitch')
        var TV = concert ? [0, 0, trans] : [-(trans * 7) % 12, -trans, 0]   // [pitch, tpc1, tpc2]
        var base = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 }[noteName]
        var tpcBase = { C: 14, D: 16, E: 18, F: 13, G: 15, A: 17, B: 19 }[noteName]
        var acc = ["♭", "♮", "♯"].indexOf(accidental) - 1     // -1, 0, +1
        var pivot = {
            pitch: base + TV[0] + acc + (octave + 1) * 12,    // MuseScore octaves start at -1
            tpc1: tpcBase + TV[1] + 7 * acc,                  // a sharp/flat is +/-7 in tpc
            tpc2: tpcBase + TV[2] + 7 * acc
        }
        pivot.tpc = concert ? pivot.tpc1 : pivot.tpc2
        return pivot
    }

    function normalizeTpc() {   // keep tpc within 6..26 (no double sharps/flats)
        var hi = -99, lo = 99
        forEachNote(function(n) { hi = Math.max(hi, n.tpc); lo = Math.min(lo, n.tpc) })
        var shift = hi > 26 ? -Math.ceil((hi - 26) / 12) : (lo < 6 ? Math.ceil((6 - lo) / 12) : 0)
        if (shift)
            forEachNote(function(n) { n.tpc1 += shift * 12; n.tpc2 += shift * 12 })
    }

    // ----------------------------------------------- rotate / retrograde
    function getArrays() { // notes (tied chords merged, each with its written pieces), chords per tied chain, extremes, measure grid
        var leaves = []
        var Hnote = { pitch: 0, tpc: 0, tpc1: 0, tpc2: 0 }
        var Lnote = { pitch: 128, tpc: 128, tpc1: 128, tpc2: 128 }
        var tk = whole / 1920 // score ticks -> whole-note units
        var grid = { start: startTick * tk, measures: [] }

        cur.rewindToTick(startTick)
        while (cur.segment && cur.tick < endTick) {
            var meas = cur.measure
            var mt = meas.firstSegment.tick
            var list = grid.measures
            if (!list.length || list[list.length - 1].tick !== mt) {
                var ts = meas.timesigActual
                var comp = ts.numerator % 3 === 0 && ts.numerator >= 6 && ts.denominator >= 8
                list.push({
                              tick: mt,
                              s: mt * tk,
                              e: mt * tk + whole * ts.numerator / ts.denominator,
                              beat: (comp ? 3 : 1) * whole / ts.denominator,
                              compound: comp
                          })
            }

            var el = cur.element
            var chord = [], tiedOn = false, arts = []
            if (el.type === Element.REST) {
                chord = 'REST'
            } else if (el.type === Element.CHORD) {
                for (var n = 0; n < el.notes.length; n++) {
                    var nt = el.notes[n]
                    var item = { pitch: nt.pitch, tpc: nt.tpc, tpc1: nt.tpc1, tpc2: nt.tpc2 }
                    if (nt.pitch > Hnote.pitch) Hnote = item
                    if (nt.pitch < Lnote.pitch) Lnote = item
                    if (nt.tieForward) tiedOn = true
                    chord.push(item)
                }
                for (var j = 0; j < el.articulations.length; j++) arts.push(el.articulations[j].clone())
            }
            var g = el.globalDuration // real length: dots and tuplets included
            leaves.push({
                            content: chord, tiedOn: tiedOn, arts: arts,
                            len: Math.round(g.numerator * whole / g.denominator),
                            dur: [el.duration.numerator, el.duration.denominator],
                            tups: tupChain(el)
                        })
            cur.next()
        }

        var notes = [], prevTied = false
        leaves.forEach(function(l) { // a tied chain is one note with several pieces
            var piece = { len: l.len, dur: l.dur, tups: l.tups, arts: l.arts }
            if (prevTied && l.content !== 'REST') notes[notes.length - 1].pieces.push(piece)
            else notes.push({ content: l.content, pieces: [piece] })
            prevTied = l.tiedOn
        })

        var chords = notes.filter(function(n) { return n.content !== 'REST' }).map(function(n) { return n.content })
        if (!chords.length && !notesExist) {
            showError("Selection empty. No changes made!")
            return null
        }
        return { notes: notes, chords: chords, Hnote: Hnote, Lnote: Lnote, grid: grid }
    }

    function leafCount(t) { // chordrests inside a tuplet, nested ones included
        var n = 0
        for (var i = 0; i < t.elements.length; i++)
            n += (t.elements[i].type === Element.TUPLET) ? leafCount(t.elements[i]) : 1
        return n
    }

    function tupChain(el) { // outermost -> innermost
        var chain = []
        for (var t = el.tuplet, depth = 0; t && depth < 6; t = parentOf(t), depth++) chain.unshift(t)
        var pn = 1, pd = 1 // product of enclosing ratios
        return chain.map(function(t, d) {
            var g = t.globalDuration
            var num = g.numerator * pn, den = g.denominator * pd // global -> local to parent
            var k = gcd(num, den)
            var info = {
                id: d + "@" + t.fraction.ticks,
                dur: [num / k, den / k],
                ratio: [t.actualNotes, t.normalNotes],
                len: leafCount(t)
            }
            pn *= t.actualNotes
            pd *= t.normalNotes
            return info
        })
    }

    function toFrac(u) { // units of the whole note -> reduced [n, d]
        var g = gcd(u, whole)
        return [u / g, whole / g]
    }

    function gridLayout(notes, grid) { // notes [{content, len}] laid end to end -> { chordRests, rhythm, tied }
        var measures = grid.measures, off0 = grid.start
        var durs = [] // single note / one-dot values, largest first
        for (var b = whole; b >= whole / 128; b /= 2) {
            if ((b * 3) % 2 === 0) durs.push(b * 3 / 2)
            durs.push(b)
        }

        function measureAt(p) {
            var r = measures.filter(function(x) { return x.s <= p && p < x.e })[0]
            if (!r) throw new Error("Cannot notate this rhythm: selection runs past the measures read. No changes made.")
            return r
        }

        var segs = [], pos = off0
        notes.forEach(function(n, idx) { // split every note at barlines
            var left = n.len
            while (left > 0) {
                var l = Math.min(left, measureAt(pos).e - pos)
                segs.push({ idx: idx, content: n.content, s: pos, e: pos + l })
                pos += l
                left -= l
            }
        })
        var end = pos
        var out = []

        function inside(a, b) {
            return segs.filter(function(g) { return g.e > a && g.s < b }).map(function(g) {
                return { idx: g.idx, content: g.content, s: Math.max(g.s, a), e: Math.min(g.e, b) }
            })
        }

        function beatKind(a, mm) { // how to notate the beat window [a, a + beat): natural subdivision or an n:m tuplet
            var B = mm.beat
            var offs = []
            segs.forEach(function(g) {
                [g.s, g.e].forEach(function(t) {
                    if (t > a && t < a + B && t !== off0 && t !== end) offs.push(t - a)
                })
            })
            if (!offs.length) return { n: 0 }
            var u0 = mm.compound ? B / 3 : B // 6/8: eighth; 4/4: quarter
            for (var k = 1; k <= 5 && u0 / Math.pow(2, k) >= whole / 128; k++)
                if (offs.every(function(o) { return (o * Math.pow(2, k)) % u0 === 0 })) return { n: 0 }
            var cands = mm.compound ? [2, 4] : [3, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15]
            for (var c = 0; c < cands.length; c++) {
                var n = cands[c]
                if (offs.every(function(o) { return (o * n) % B === 0 })) {
                    if (a < off0 || a + B > end)
                        throw new Error("Cannot notate this rhythm: a tuplet would be cut by the edge of the selection. No changes made.")
                    return { n: n, m: mm.compound ? 3 : (n < 4 ? 2 : n < 8 ? 4 : 8) }
                }
            }
            throw new Error("Cannot notate this rhythm: a note starts off the beat/tuplet grid. No changes made.")
        }

        function tuplet(a, B, n, m) { // n notes in the time of m, over one beat; a note covers one or more slots
            var slot = B / n, d = B / m // slot: real length, d: notated value
            var pieces = []
            inside(a, a + B).forEach(function(p) {
                var left = Math.round((p.e - p.s) / slot)
                while (left > 0) { // largest representable run of slots, tied
                    var k = left
                    while (k > 1 && durs.indexOf(k * d) < 0) k--
                    pieces.push({ idx: p.idx, content: p.content, dur: toFrac(k * d) })
                    left -= k
                }
            })
            pieces.forEach(function(p) {
                p.tups = [{ dur: toFrac(B), ratio: [n, m], len: pieces.length }]
                out.push(p)
            })
        }

        function binary(a, b) { // dotted/undotted pieces; a piece lies in one beat or starts on a beat
            inside(a, b).forEach(function(p) {
                var s = p.s
                while (s < p.e) {
                    var mm = measureAt(s), rel = s - mm.s, D = 0
                    for (var i = 0; i < durs.length && !D; i++)
                        if (durs[i] <= p.e - s && (rel % mm.beat === 0 || rel % mm.beat + durs[i] <= mm.beat)) D = durs[i]
                    if (!D) throw new Error("Cannot notate this rhythm: duration too short. No changes made.")
                    out.push({ idx: p.idx, content: p.content, dur: toFrac(D), tups: [] })
                    s += D
                }
            })
        }

        var runStart = off0
        measures.forEach(function(mm) {
            for (var w = mm.s; w < mm.e; w += mm.beat) {
                if (w + mm.beat <= off0 || w >= end) continue
                var kd = beatKind(w, mm)
                if (!kd.n) continue
                if (runStart < w) binary(runStart, w) // binary beats before this tuplet
                tuplet(w, mm.beat, kd.n, kd.m)
                runStart = Math.min(w + mm.beat, end)
            }
        })
        if (runStart < end) binary(runStart, end)

        return {
            chordRests: out.map(function(p) { return p.content }),
            rhythm: out.map(function(p) { return { dur: p.dur, tups: p.tups } }),
            tied: out.map(function(p, i) { return i + 1 < out.length && p.idx === out[i + 1].idx && p.content !== 'REST' }),
            idx: out.map(function(p) { return p.idx })
        }
    }

    function gridFromNotes(notes, grid) { // beat-grid layout for the whole selection
        var plain = notes.map(function(n) {
            return { content: n.content, len: n.pieces.reduce(function(s, q) { return s + q.len }, 0) }
        })
        var L = gridLayout(plain, grid), seen = {}
        L.arts = L.idx.map(function(ni) { // articulations of the note's first piece go on its first new piece
            if (seen[ni]) return []
            seen[ni] = true
            return notes[ni].pieces[0].arts
        })
        return L
    }

    function layout(notes, grid) { // keep intact tuplet groups and written binary pieces; regroup broken groups; else beat grid
        var measures = grid.measures
        if (!keepTuplets) return gridFromNotes(notes, grid)
        var durs = [] // single note / one-dot values, largest first
        for (var b = whole; b >= whole / 128; b /= 2) {
            if ((b * 3) % 2 === 0) durs.push(b * 3 / 2)
            durs.push(b)
        }

        function measureAt(p) {
            var r = measures.filter(function(x) { return x.s <= p && p < x.e })[0]
            if (!r) throw new Error("Cannot notate this rhythm: selection runs past the measures read. No changes made.")
            return r
        }

        var seq = [], pos = grid.start // pieces in the new order, with start positions
        notes.forEach(function(n, ni) {
            n.pieces.forEach(function(p) {
                seq.push({ ni: ni, content: n.content, len: p.len, dur: p.dur, tups: p.tups, arts: p.arts, s: pos })
                pos += p.len
            })
        })

        var ids = {} // tuplet id -> positions of its pieces in seq
        seq.forEach(function(p, i) {
            p.tups.forEach(function(t) {
                if (!ids[t.id]) ids[t.id] = { idx: [], len: t.len }
                ids[t.id].idx.push(i)
            })
        })
        function okId(id) { // all pieces present and contiguous
            var g = ids[id]
            return g.idx.length === g.len && g.idx[g.idx.length - 1] - g.idx[0] + 1 === g.len
        }

        var keep = {} // outermost tuplet id -> still intact, inside one measure
        seq.forEach(function(p) {
            if (!p.tups.length || p.tups[0].id in keep) return
            var oid = p.tups[0].id, g = ids[oid], good = okId(oid)
            for (var i = 0; good && i < g.idx.length; i++)
                seq[g.idx[i]].tups.forEach(function(t) { if (!okId(t.id)) good = false })
            if (good) {
                var first = seq[g.idx[0]], last = seq[g.idx[g.idx.length - 1]]
                if (measureAt(first.s).e < last.s + last.len) good = false
            }
            keep[oid] = good
        })

        var out = []

        function emitBinary(p) { // keep as written; split and tie only at barlines
            var e = p.s + p.len
            if (measureAt(p.s).e >= e) {
                out.push({ ni: p.ni, content: p.content, dur: p.dur, len: p.len, tups: [], arts: p.arts })
                return
            }
            var s = p.s, firstChunk = true
            while (s < e) {
                var seg = Math.min(e, measureAt(s).e), left = seg - s
                while (left > 0) {
                    var D = 0
                    for (var i = 0; i < durs.length && !D; i++) if (durs[i] <= left) D = durs[i]
                    if (!D) throw new Error("Cannot notate this rhythm: duration too short. No changes made.")
                    out.push({ ni: p.ni, content: p.content, dur: toFrac(D), len: D, tups: [], arts: firstChunk ? p.arts : [] })
                    firstChunk = false
                    left -= D
                }
                s = seg
            }
        }

        function findTuplet(ps, s, T) { // one new tuplet covering exactly these free pieces
            var mm = measureAt(s)
            if (ps.length < 2 || mm.e < s + T) return null
            var cands = [[3, 2], [5, 4], [6, 4], [7, 4], [9, 8], [10, 8], [12, 8]]
            if (mm.compound) cands = [[2, 3], [4, 3]].concat(cands)
            for (var c = 0; c < cands.length; c++) {
                var n = cands[c][0], m = cands[c][1]
                var u = T / m, sl = T / n // u: notated value, sl: real length of one slot
                if (u !== Math.floor(u) || sl !== Math.floor(sl) || u > whole || u < whole / 128) continue
                var q = whole / u
                if (whole % u !== 0 || (q & (q - 1)) !== 0) continue // u must be an undotted note value
                if (ps.every(function(p) { return p.len % sl === 0 })) return { n: n, m: m, u: u, sl: sl }
            }
            return null
        }

        function emitTuplet(ps, tp, T) {
            var chunks = []
            ps.forEach(function(p) { // a note covering several slots: largest writable runs, tied
                var k = p.len / tp.sl, first = true
                while (k > 0) {
                    var kk = k
                    while (kk > 1 && durs.indexOf(kk * tp.u) < 0) kk--
                    chunks.push({ ni: p.ni, content: p.content, dur: toFrac(kk * tp.u), len: kk * tp.sl, arts: first ? p.arts : [] })
                    first = false
                    k -= kk
                }
            })
            var info = { dur: toFrac(T), ratio: [tp.n, tp.m], len: chunks.length }
            chunks.forEach(function(c) { c.tups = [info]; out.push(c) })
        }

        function regroup(run) { // smallest valid tuplet from the left, repeatedly
            var i = 0
            while (i < run.length) {
                var found = false
                for (var j = i; j < run.length && !found; j++) {
                    var ps = run.slice(i, j + 1), T = 0
                    ps.forEach(function(p) { T += p.len })
                    var tp = findTuplet(ps, run[i].s, T)
                    if (tp) { emitTuplet(ps, tp, T); i = j + 1; found = true }
                }
                if (!found) return false
            }
            return true
        }

        for (var i = 0; i < seq.length; i++) {
            var p = seq[i]
            if (!p.tups.length) { emitBinary(p); continue }
            if (keep[p.tups[0].id]) {
                out.push({ ni: p.ni, content: p.content, dur: p.dur, len: p.len, tups: p.tups, arts: p.arts })
                continue
            }
            var run = [p] // broken group: consecutive free pieces
            while (i + 1 < seq.length && seq[i + 1].tups.length && !keep[seq[i + 1].tups[0].id]) run.push(seq[++i])
            if (!regroup(run)) { // cannot regroup
                if (!fallbackGrid) throw new Error("Cannot regroup a broken tuplet. No changes made.")
                return gridFromNotes(notes, grid)
            }
        }

        return {
            chordRests: out.map(function(p) { return p.content }),
            rhythm: out.map(function(p) { return { dur: p.dur, tups: p.tups } }),
            tied: out.map(function(p, i) { return i + 1 < out.length && p.ni === out[i + 1].ni && p.content !== 'REST' }),
            arts: out.map(function(p) { return p.arts })
        }
    }

    function gcd(a, b) { return b ? gcd(b, a % b) : a }

    function parentOf(t) {
        console.log("PARENT parentTuplet=" + t.parentTuplet + " tuplet=" + t.tuplet)
        return t.parentTuplet || t.tuplet || null
    }

    function hasTieForward(el) {
        for (var n = 0; n < el.notes.length; n++) if (el.notes[n].tieForward) return true
        return false
    }

    function setChord(el, p) { // cursor must be on el; replace its notes with the notes in p
        for (var n = el.notes.length - 1; n >= 1; n--) el.remove(el.notes[n]) // keep lowest note
        el.notes[0].pitch = p[0].pitch
        el.notes[0].tpc1 = p[0].tpc1
        el.notes[0].tpc2 = p[0].tpc2
        for (var k = 1; k < p.length; k++) {
            cur.addNote(p[k].pitch, true)
            cur.prev()
        }
    }

    function rePitch(chords) { // rewrite pitches only, keep rhythm; chords has one entry per tied chain
        var i = 0
        cur.rewindToTick(startTick)
        while (cur.segment && cur.tick < endTick) {
            if (cur.element.type === Element.CHORD) {
                var p = chords[i++]
                for (;;) { // same pitches on every chord in the chain
                    var tied = hasTieForward(cur.element) // check before setChord removes notes
                    setChord(cur.element, p)
                    if (!tied) break
                    cur.next()
                    if (!cur.segment || cur.tick >= endTick || cur.element.type !== Element.CHORD) break
                }
            }
            cur.next()
        }
        curScore.selection.selectRange(startTick, endTick, startStaff, endStaff)
    }

    function reWrite(chordRests, rhythm, tied, arts) { // tied[i]: leaf i tied to i+1; arts[i]: articulation clones for leaf i
        cur.rewindToTick(startTick)
        while (cur.segment && cur.tick < endTick) {
            var el = cur.element
            var guard = 8
            while (el.tuplet && guard-- > 0) { // remove outermost first, repeat until none left
                var t = el.tuplet
                while (parentOf(t)) t = parentOf(t)
                removeElement(t)
            }
            cur.next()
        }
        cur.rewindToTick(startTick)

        var stack = [] // open tuplets, outermost first: { left }
        var marks = [] // per leaf: position, tie, articulations (applied after everything is written)
        for (var i = 0; i < chordRests.length; i++) {
            var r = rhythm[i]
            for (var k = 0; k < r.tups.length; k++) {
                if (stack[k] && stack[k].left > 0) continue
                stack.length = k // new tuplet at level k closes anything deeper
                var tp = r.tups[k]
                cur.addTuplet(fraction(tp.ratio[0], tp.ratio[1]), fraction(tp.dur[0], tp.dur[1]))
                stack[k] = { left: tp.len }
            }

            var at = cur.fraction
            cur.setDuration(r.dur[0], r.dur[1])
            var p = chordRests[i]
            if (p === 'REST') cur.addRest()
            else p.forEach(function(note, j) { cur.addNote(note.pitch, j > 0) })
            marks.push({ at: [at.numerator, at.denominator], tie: !!tied[i] && p !== 'REST', arts: (arts && arts[i]) || [] })

            for (k = 0; k < r.tups.length; k++) stack[k].left--
            while (stack.length && stack[stack.length - 1].left <= 0) stack.pop()
        }

        marks.forEach(function(m) {
            cur.rewindToFraction(fraction(m.at[0], m.at[1]))
            m.arts.forEach(function(a) { cur.add(a) })
        })
        marks.forEach(function(m) { // positions are fractions: tuplet ticks are not always integers
            if (!m.tie) return
            cur.rewindToFraction(fraction(m.at[0], m.at[1]))
            var chord = cur.element
            for (var n = 0; chord && n < chord.notes.length; n++) {
                curScore.selection.select(chord.notes[n])
                cmd("tie")
            }
        })
    }

    function rotate(opt) {
        var a = getArrays()
        if (!a) return
        var step = stepBox.currentValue * rotDir
        applyOpt(opt, a, function(arr) { return rotateArray(arr, step) }, false)
    }

    function reverse(opt) {
        var a = getArrays()
        if (!a) return
        applyOpt(opt, a, function(arr) { return arr.slice().reverse() }, true)
    }

    function tupletGroups(rhythm) { // tuplets as reWrite will open them: { level, start, end }
        var groups = [], stack = []
        rhythm.forEach(function(r, i) {
            for (var k = 0; k < r.tups.length; k++) {
                if (stack[k] && stack[k].left > 0) continue
                stack.length = k
                var g = { level: k, start: i, end: i + r.tups[k].len - 1 }
                groups.push(g)
                stack[k] = { left: r.tups[k].len }
            }
            for (var k2 = 0; k2 < r.tups.length; k2++) stack[k2].left--
            while (stack.length && stack[stack.length - 1].left <= 0) stack.pop()
        })
        return groups
    }

    function simplifyTuplets(L) { // tuplet holding only rests, or only one tied note -> plain rest / note
        var changed = true
        while (changed) {
            changed = false
            var groups = tupletGroups(L.rhythm)
            groups.sort(function(a, b) { return a.level - b.level || a.start - b.start }) // outermost first
            for (var gi = 0; gi < groups.length && !changed; gi++) {
                var g = groups[gi], s = g.start, e = g.end
                var allRest = true, oneNote = true
                for (var i = s; i <= e; i++) {
                    if (L.chordRests[i] !== 'REST') allRest = false
                    if (L.chordRests[i] === 'REST' || (i < e && !L.tied[i])) oneNote = false
                }
                if (!allRest && !oneNote) continue

                var r0 = L.rhythm[s]
                var leaf = { dur: r0.tups[g.level].dur, tups: r0.tups.slice(0, g.level) }
                var content = allRest ? 'REST' : L.chordRests[s]
                var tiedOut = !allRest && !!L.tied[e]
                var arts = (!allRest && L.arts) ? L.arts[s] : []
                L.chordRests.splice(s, e - s + 1, content)
                L.rhythm.splice(s, e - s + 1, leaf)
                L.tied.splice(s, e - s + 1, tiedOut)
                if (L.arts) L.arts.splice(s, e - s + 1, arts)
                groups.forEach(function(a) { // enclosing tuplets lose the removed leaves
                    if (a.level < g.level && a.start <= s && a.end >= e) L.rhythm[a.start].tups[a.level].len -= e - s
                })
                changed = true
            }
        }
        return L
    }

    function applyOpt(opt, a, f, reversed) { // f: array -> array; 0 pitches, 1 rhythm, 2 both
        try {
            if (opt === 0) {
                rePitch(f(a.chords)) // one entry per tied chain
            } else {
                var notes = f(a.notes).map(function(n, i) {
                    var pieces = reversed ? n.pieces.slice().reverse() : n.pieces
                    if (opt === 1) { // rhythm only: content and its articulations stay in slot i
                        var slot = a.notes[i]
                        return { content: slot.content, pieces: pieces.map(function(p, k) {
                            return { len: p.len, dur: p.dur, tups: p.tups, arts: slot.pieces[k] ? slot.pieces[k].arts : [] }
                        }) }
                    }
                    return { content: n.content, pieces: pieces }
                })
                var L = simplifyTuplets(layout(notes, a.grid))
                reWrite(L.chordRests, L.rhythm, L.tied, L.arts)
            }
        } catch (e) {
            showError(e.message)
        }
        curScore.selection.selectRange(startTick, endTick, startStaff, endStaff)
    }

    function rotateArray(arr, step) {
        var len = arr.length
        return arr.map(function(_, i) { return arr[(((i - step) % len) + len) % len] })
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

    function invertTrack(opt, chromatic) {      // 0 outermost, 1 specific pitch, 2 negative harmony
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
            if (up === -down && up !== 0)       // equidistant: decide by spelling
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
        var interval = pivot.pitch - (selectedScale.pitch[selectedMode] + 12)   // +12: scale tables start at -12
        var map = buildScale(selectedScale, interval)
        if (mapMode.current === 0) performMapping(map)
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
        property int current: 0
        spacing: 12
        ButtonGroup { id: grp }
        Repeater {
            model: og.options
            RoundedRadioButton {
                ButtonGroup.group: grp
                text: modelData
                Component.onCompleted: if (index === og.current) checked = true
                onCheckedChanged: if (checked) og.current = index
            }
        }
    }

    StyledTabBar {
        id: bar
        currentIndex: 0
        anchors.left: parent.left
        anchors.leftMargin: 15
        StyledTabButton { text: "Rotate / Retrograde" }
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

        // Rotate / Retrograde
        Item {
            RowLayout {
                spacing: 10
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 12
                    StyledTextLabel { text: "Operation:" }
                    OptionGroup { id: orderOp; options: ["Rotate", "Retrograde"] }
                    ColumnLayout {
                        Layout.topMargin: 18
                        enabled: orderOp.current === 0
                        spacing: 6
                        StyledTextLabel { text: "Steps:" }
                        RowLayout {
                            spacing: 4
                            FlatButton {
                                Layout.preferredWidth: 32
                                text: "◀"
                                accentButton: root.rotDir === -1
                                onClicked: root.rotDir = -1
                            }
                            IncrementalPropertyControl {
                                id: stepBox
                                Layout.preferredWidth: 60
                                step: 1
                                minValue: 1
                                maxValue: 10
                                currentValue: 1
                                onValueEdited: function(newValue) { currentValue = newValue }
                            }
                            FlatButton {
                                Layout.preferredWidth: 32
                                text: "▶"
                                accentButton: root.rotDir === 1
                                onClicked: root.rotDir = 1
                            }
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 12
                    StyledTextLabel { text: "Apply to:" }
                    OptionGroup { id: orderTarget; options: ["Pitches", "Rhythm", "Pitches and Rhythm"] }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 12
                    StyledTextLabel { text: "Tuplets:" }
                    CheckBox {
                        text: "Keep tuplets"
                        checked: root.keepTuplets
                        onClicked: root.keepTuplets = !root.keepTuplets
                        //hoverEnabled: true
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        ToolTip.text: "Keep tuplets that are still intact after the move, even when they land off the beat. \nOff: the rhythm is rewritten on the beat grid, which can create tuplets like 12:8."
                    }
                    CheckBox {
                        text: "Beat-grid fallback"
                        enabled: root.keepTuplets
                        checked: root.fallbackGrid
                        onClicked: root.fallbackGrid = !root.fallbackGrid
                        //hoverEnabled: true
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        ToolTip.text: "If a broken tuplet can't be regrouped, rewrite the whole selection on the beat grid. \nOff: cancel with an error and change nothing."
                    }
                }
            }
        }

        // Invert
        Item {
            RowLayout {
                spacing: 30
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 12
                    StyledTextLabel { text: "Invert Using:" }
                    OptionGroup {
                        id: invertOpts
                        options: ["Outermost Pitches", "Specific Pitch", "Axis (Negative Harmony)"]
                    }
                    StyledTextLabel { Layout.topMargin: 6; text: "Inversion:" }
                    ButtonGroup { id: invertTypeGrp }
                    RowLayout {
                        spacing: 20
                        RoundedRadioButton {
                            text: "Diatonic"
                            ButtonGroup.group: invertTypeGrp
                        }
                        RoundedRadioButton {
                            id: chromaticBtn
                            text: "Chromatic"
                            checked: true
                            ButtonGroup.group: invertTypeGrp
                        }
                    }
                }
                StackLayout {
                    Layout.alignment: Qt.AlignTop
                    currentIndex: invertOpts.current
                    StyledTextLabel { // outermost pitches: nothing to pick
                        Layout.preferredWidth: 180
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignLeft
                        text: "Axis: the midpoint between the lowest and highest notes of the selection."
                    }
                    PitchPicker { id: invertPicker }
                    MyCircle { id: negativeHarmony }
                }
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
                        text: "Ionian"
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
                OptionGroup { id: mapMode; options: ["Map notes to scale", "Color non-scale notes"] }
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
        Timer {
            id: applyTimer
            interval: 500
            onTriggered: applyTransform()
        }
        FlatButton {
            text: qsTr("Apply")
            accentButton: true
            onClicked: {
                // tied notes only kept if musescore gets focus. a temporary hack till a good solution is found
                var w = root.parent && root.parent.Window.window
                var main = w ? w.transientParent : null
                console.log("MAIN WINDOW " + main)
                if (main) main.requestActivate()
                if (bar.currentIndex == 0) applyTimer.start()
                else applyTransform()
            }
        }
        FlatButton {
            text: qsTr("Close")
            onClicked: root.parent.Window.window.close()
        }
    }
}
