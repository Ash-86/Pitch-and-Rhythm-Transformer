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

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Pitch and Rhythm Transformer"
    description: "Rotate, reverse, or invert pitches, rhythm, or both"
    version: "1.1"
    pluginType: "dialog"

    id: mainWindow
    
    Component.onCompleted: {
        if (mscoreMajorVersion >= 4) {
            mainWindow.title = "Transform Pitches and Rhythm"
            mainWindow.thumbnailName = "Transformer.jpg"
            mainWindow.categoryCode = "Composition"
            mainWindow.width=350
            mainWindow.height=250
        } else {
            mainWindow.width=550
            mainWindow.height=350
        }
    }    
        
    onRun: {
        //window.visible = true            
    }

    
    function applyTransform(){
        
        
        var cursor = curScore.newCursor(); 

        /////// Get Selection //////////////////////////
        cursor.rewind(2); // go to the end of the selection
		var endTick = cursor.tick;
		// if (endTick == 0) { // dealing with some bug when selecting to end.
   		// 	var endTick = score.lastSegment.tick + 1;
		// }
		var endStaff = cursor.staffIdx +1;
        var endTrack = endStaff * 4;
		//start		
		cursor.rewind(1); // go to the beginning of the selection
		var startSegTick= curScore.selection.startSegment.tick;
		var startTick = cursor.tick;
		var startStaff = cursor.staffIdx;
		var startTrack = startStaff * 4;
        cursor.rewind(1);       // beginning of selection
        ///////////////////////////////////////////////////
    
        ///////////   Get arrays: Pitches, onlyPitches, Rhythm (durations)///////
        var onlyPitches=[]///without rests
        var Pitches=[]
        var Rhythm=[]
        var Hnote={pitch:0, tpc1:0, tpc2:0} ///highest Note
        var Lnote={pitch:128, tpc1:128, tpc2:128} //lowest note
        while (cursor.segment != null && cursor.tick < endTick) {            
            var chord=[]           
            var el=cursor.element

            if(el.type == Element.REST) { 
                var chord = 'REST'; 
            }
            if (el.type == Element.CHORD) {
                for (var n in el.notes){                    
                    if(el.notes[n].pitch > Hnote.pitch){
                        Hnote.pitch = el.notes[n].pitch
                        Hnote.tpc1 = el.notes[n].tpc1
                        Hnote.tpc2 = el.notes[n].tpc2
                    }
                    if(el.notes[n].pitch < Lnote.pitch){
                        Lnote.pitch = el.notes[n].pitch
                        Lnote.tpc1 = el.notes[n].tpc1
                        Lnote.tpc2 = el.notes[n].tpc2
                    }  
                    var chordNote ={ 
                        pitch: el.notes[n].pitch, 
                        tpc: el.notes[n].tpc, 
                        tpc1: el.notes[n].tpc1, 
                        tpc2: el.notes[n].tpc2 
                    }
                                    
                    chord.push(chordNote)
                    //chord.push([pitch,tpc, tpc1,tpc2]) 
                }
                onlyPitches.push(chord)  ///array without rests
            } 
            Pitches.push(chord)

            const durations={ 
                dur: [el.duration.numerator, el.duration.denominator],
                tupdur: 0,
                ratio: 0,
                tuplength: 0,                              
                atMeasureEnd: cursor.tick===cursor.measure.lastSegment.tick 
            }

            if(el.tuplet) { // tuplets are a special case
                durations.tupdur = [el.tuplet.globalDuration.numerator, el.tuplet.globalDuration.denominator]
                durations.ratio = [el.tuplet.actualNotes, el.tuplet.normalNotes]
                durations.tupLength= el.tuplet.elements.length
            }            
            
            Rhythm.push(durations)
             
            cursor.next();
        }
        /////////////////////////////////////////////////////////////
        
        if (!onlyPitches.length) {
            errorDialog.text="Selection empty. No changes made!"            
            errorDialog.open()                       
            return     
        }   
        /////////////////////////////////////////////////////////////
        var scales={                       
            "Major Modes": {   
                  pitch: [-12,-10,-8,-7,-5,-3,-1],
                  tpc1: [14,16,18,13,15,17,19] ,
                  tpc2: null          
            },
            "Melodic Minor Modes": {   
                  pitch: [-12,-10,-9,-7,-5,-3,-1],
                  tpc1: [14,16,11,13,15,17,19],
                  tpc2: null    
            },
            "Harmonic Minor Modes": {
                pitch: [-12,-10,-9,-7,-5,-4,-1],
                tpc1: [14,16,11,13,15,10,19],
                tpc2: null    
            },
            "Harmonic Major": { 
                pitch: [-12,-10,-8,-7,-5,-4,-1],
                tpc1: [14,16,18,13,15,10,19],
                tpc2: null
            },
            "Double Harmonic":{
                pitch: [-12,-11,-8,-7,-5,-4,-1],
                tpc1: [14,9,18,13,15,10,19],
                tpc2: null
            },
            "Half-Whole" :{
                pitch:[-12,-11,-9,-8,-6,-5,-3,-2],
                tpc1:[14,21,23,18,20,15,17,11],
                tpc2: null
            },
            "Whole-Half" :{
                pitch:[-12,-10,-9,-7,-6,-4,-3,-1],
                tpc1:[14,16,11,13,20,22,17,19],
                tpc2: null
            },
            "Whole Tone":{
                pitch: [-12,-10,-8,-6,-4,-2],
                tpc1:  [14,16,18,20,22,24] ,
                tpc2: null
            },
            "Major Pentatonic":{
                pitch: [-12,-10,-8,-5,-3],
                tpc1: [14,16,18,15,17] ,
                tpc2: null
            },
            "Minor Pentatonic":{
                pitch: [-12,-9,-7,-5,-2],
                tpc1: [14,11,13,15,12],
                tpc2: null
            }
            
        }      
        //////////////////////////////////////////////////////////////////////////// 
        cursor.rewind(1) 
       
        curScore.startCmd()
        //// if tuplet at ends of selection change rotation step to number of tuplet notes
        if (Rhythm[Rhythm.length-1].ratio[0]>0 && stepBox.val>0){
            var step =Rhythm[Rhythm.length-1].tupLength
        }
        else if (Rhythm[0].ratio[0]>0 && stepBox.val<0){
            var step=-Rhythm[0].tupLength
        }
        else{
            var step= stepBox.val
        }
        if (rotateTab.checked){
            if (rotatePitchesBox.checked){
                var Pitches= rotateArray(onlyPitches,step) 
                editPitches(Pitches)
            }
            if (rotateRhythmBox.checked){
                var Rhythm= rotateArray(Rhythm,step)
                reWrite(Pitches,Rhythm)
            }
            if (rotateBothBox.checked){
                var Pitches=rotateArray(Pitches,step)
                var Rhythm= rotateArray(Rhythm,step)
                reWrite(Pitches,Rhythm)
            }
        }
        if (reverseTab.checked){
            if (reversePitchesBox.checked){
                var onlyPitches= onlyPitches.reverse()
                editPitches(onlyPitches)
            }
            if (reverseRhythmBox.checked){
                var Rhythm=Rhythm.reverse()
                reWrite(Pitches,Rhythm)
            }
            if (reverseBothBox.checked){
                var Pitches= Pitches.reverse()
                var Rhythm=Rhythm.reverse()
                reWrite(Pitches,Rhythm)
            }
        }
        if(invertTab.checked){
            if (invertByPitch.checked){
            var accidental=accidentalBox.currentText
            var octave=octaveBox.value
            var noteValue=noteBox.currentText
             
            var pivot= getPivot(noteValue,accidental, octave)
            invert(pivot, invertType.position)
            }
            if (invertByOutermostPitchesBox.checked){
                invertUsingOutermostPitches(invertType.position)
            }
        }
        if (mapTab.checked && mainMenu.modeNumber[1]!=null){
            var notename=noteBoxMap.currentText
            var noteacc=accidentalBoxMap.currentText
            var pivot= getPivot(notename,noteacc,-1)
    
            var scale=scales[mainMenu.modeNumber[0]]
            var modeDistance= scale.pitch[mainMenu.modeNumber[1]] +12 //+12 because the modes pitches above start from -12

            var transposedScale=transpose(scale,pivot.pitch-modeDistance ) // ,curScore.keysig)
            console.log("transpsed scale:", transposedScale.pitch, transposedScale.tpc1 ) 
            var Map= getScaleMap(transposedScale) 
            performMapping(Map) 
             //console.log("Map: ",Map.pitch, Map.tpc1)
            // var oldMap= getDiatonicMap()
            // console.log("old diatonicMap", oldMap.pitch,   oldMap.tpc1 )
        }

        curScore.selection.selectRange(startTick, endTick, startStaff, endStaff);
        curScore.endCmd()
        //////////////////////////////////////////////////////////////////////
        
        function editPitches(Pitches){
                      
            var i=0
            while (cursor.segment != null && cursor.tick < endTick) {
                var el=cursor.element              
                if (el.type == Element.CHORD) { 
                    if (el.notes.length>1){
                        for ( var n=el.notes.length-1; n>=1; n--){///delete all notes except lowest note
                            el.remove(el.notes[n])
                        }
                    }                
                    el.notes[0].pitch= Pitches[i][0].pitch  ///change lowest note pitch and tpc
                    el.notes[0].tpc1= Pitches[i][0].tpc1   
                    el.notes[0].tpc2= Pitches[i][0].tpc2                 
                    //  console.log("tick: ", cursor.tick)
                    if (Pitches[i].length>1){
                        for (var n=1; n<Pitches[i].length; n++){  /// add notes on top of lowest note
                            cursor.addNote(Pitches[i][n].pitch, cursor)                        
                            // console.log("add:", Pitches[step][n][0])
                            cursor.prev()
                        }
                    }                
                    i++
                }
                // console.log("tick: ", cursor.tick)        
                cursor.next()
            }  
        }      
    
       
    
        
        function reWrite (Pitches,Rhythm){
            ////////// start delete block /////////////////
            cursor.rewindToTick(startTick);       		
            
            while(cursor.segment && cursor.tick < endTick) {
                var el = cursor.element;
                if(el.tuplet) {
                    removeElement(el.tuplet); // you have to specifically remove tuplets
                }
                // else {
                //     removeElement(e);
                // }
                cursor.next(); // advance cursor
            }
            //////////////////////end delete block ////////////////
			cursor.rewindToTick(startTick)	
				
            var durCum=0 //cumulative sum of note duration values to keep count of triplets
            for(var i = 0; i < Pitches.length; i++) {            
                                
                if(Rhythm[i].ratio[0] && durCum == 0) { // check for tuplet. only on the first tuplet element  create the tuplet
	                cursor.addTuplet( fraction (Rhythm[i].ratio[0], Rhythm[i].ratio[1]), 
                                    fraction (Rhythm[i].tupdur[0], Rhythm[i].tupdur[1]) ); // ratios and durations								
                    var durSum= (Rhythm[i].tupdur[0] / Rhythm[i].tupdur[1]) * ( Rhythm[i].ratio[0] / Rhythm[i].ratio[1])
                }	
                if(Rhythm[i].ratio[0] &&  durCum<durSum) {
                    durCum+=  (Rhythm[i].dur[0] / Rhythm[i].dur[1])	     
                }
                if ( durCum==durSum) {	   
                    durCum=0;
	            }   


                cursor.setDuration(Rhythm[i].dur[0], Rhythm[i].dur[1]);                
                // if there is only a single note
                if(Pitches[i].length == 1) {
                    cursor.addNote(Pitches[i][0].pitch); // add note
                }   
                // if there is a chord or rest
                if(Pitches[i].length > 1) {            
                    // if rest
                    if(Pitches[i] === 'REST') {
                        cursor.addRest () // add rest
                    } 
                    else {                
                        // if chord
                        for(var j = 0; j < Pitches[i].length; j++) {
                            if(j == 0) { // loop through each pitch of chord
                                // write the root note in a new cursor position
                                cursor.addNote(Pitches[i][j].pitch); // root of chord
                            } 
                            else {
                                // write the notes to the same cursor position
                                cursor.addNote(Pitches[i][j].pitch, cursor); // remainder of notes in chord
                            }
                        }
                    }
                }                
            } // end for      
        }//end function        

                
        function rotateArray(Array, stepSize){
            var NewArray=[]                
            for(var i = 0; i < Array.length; i++){
                if (stepSize==0){ 
                    NewArray.push(Array[Array.length-1-i]) /// reverses array. used array.reverse() instead
                }
                else{ 
                    NewArray.push(Array[(-stepSize+i+Array.length)%Array.length ]) 
                }
            }
            return NewArray
        }
                
                
        function getTrans(){ ///get instrument tranposition value
             cursor.rewindToTick(startTick)
             while (cursor.segment && cursor.tick < endTick){
               var el=cursor.element
               if (el.type==Element.CHORD){
                  var dtpc=el.notes[0].tpc2-el.notes[0].tpc1                 
                  return dtpc
               }
                cursor.next()
             }
         }
         
        function getPivot(noteValue, accidental, octave){ ////calculate pivot pitch and tpc values from user input
             var trans=getTrans()  
             if (curScore.style.value('concertPitch')){ 
                   var TV=[0,0,trans] // Transposition Vector [pitch, tpc1, tpc2]
            }
             else{ 
                   var TV=[-(trans*7)%12,-trans,0]
            }

            const notes={
                C:{pitch:0 + TV[0],tpc1:14 + TV[1], tpc2:14 + TV[2]}, 
                E:{pitch:4+ TV[0],tpc1:18 + TV[1], tpc2:18 + TV[2]} ,
                D:{pitch:2+ TV[0],tpc1:16 + TV[1], tpc2:16 + TV[2]},
                F:{pitch:5+ TV[0],tpc1:13 + TV[1], tpc2:13 + TV[2]} ,
                G:{pitch:7+ TV[0],tpc1:15 + TV[1], tpc2:15 + TV[2]} ,
                A:{pitch:9+ TV[0],tpc1:17 + TV[1], tpc2:17 + TV[2]} ,
                B:{pitch:11+ TV[0],tpc1:19 + TV[1], tpc2:19 + TV[2]}
            }            
            var note= notes[noteValue] 
            
            
            //MS starts counting octaves from -1, therefore the need to add 1 to octave
            //tpc distance from natural to flat or sharp is -7 and +7. ex: C, Cb, C#
            //
            
            if(accidental=="♭"){
                var pivot={pitch:(note.pitch-1)+(octave+1)*12, 
                            tpc1:note.tpc1-7, 
                            tpc2:note.tpc2-7} 
            }        
            if(accidental=="♯"){
                var pivot={pitch:(note.pitch+1)+(octave+1)*12, 
                            tpc1:note.tpc1+7, 
                            tpc2:note.tpc2+7}
            }  
            if(accidental=="♮"){
                var pivot={pitch:note.pitch+(octave+1)*12, 
                            tpc1:note.tpc1, 
                            tpc2:note.tpc2}
            }
            return pivot
        }          
         
        function getEnharmonic(){ //confine tpc values between 11 and 21 in order to not have double sharps or doulble flats
            cursor.rewindToTick(startTick)
            var tpcOverflow=0
            var Htpc=26
            var Ltpc=6
            while (cursor.segment && cursor.tick < endTick) {
                var el=cursor.element                                       
                if (el.type == Element.CHORD) {                                   
                    for ( var n=0; n<el.notes.length; n++){   
                        if (el.notes[n].tpc>Htpc){
                            tpcOverflow=1
                            Htpc=el.notes[n].tpc                            
                        }
                        if (el.notes[n].tpc<Ltpc){
                            tpcOverflow=-1
                            Ltpc=el.notes[n].tpc                                                    
                        }
                    }
                }
                cursor.next()
           }
            
            var counter=0
            while (Htpc>26){
                Htpc-=12
                counter++
            }
            while (Ltpc<6){
                Ltpc+=12
                counter++
            }
            if (tpcOverflow!=0){
                cursor.rewindToTick(startTick)
                while (cursor.segment && cursor.tick < endTick) {
                    var el=cursor.element                                       
                    if (el.type == Element.CHORD) {                                   
                        for ( var n=0; n<el.notes.length; n++){                                           
                            if (tpcOverflow==1){
                                el.notes[n].tpc1-= counter*12  
                                el.notes[n].tpc2-= counter*12 
                            }
                            if (tpcOverflow==-1){
                                el.notes[n].tpc1+= counter*12  
                                el.notes[n].tpc2+= counter*12 
                            }
                        }
                    }
                    cursor.next()
                }
            }
            return
        }      
        
        function getDiatonicMap(){
            var trans=getTrans()
            var keySig= curScore.keysig 
            var scale=[0,2,4,5,7,9,11]
            var tpc1s=[14,16,18,13,15,17,19]
            var tpc2s=tpc1s.map(function(x) { return x+trans})                                     
            //var tpc2s=[14+trans,16+trans,18+trans,13+trans,15+trans,17+trans,19+trans]         
            ///adjust map to key signature
            if (keySig>0) {//if sharp signature
                var pos=3  ///start circle of 4th from F                                   
                for (var i=0; i<keySig;i++){                                       
                      scale[(pos)%7]+=1 //plus half step
                      tpc1s[(pos)%7]+=7
                      tpc2s[(pos)%7]+=7
                      pos=(pos+4)%7                                       
                }
            }
            if (keySig<0) {//if flat signature
                var pos=6///start circle of 4th from B
                for (var i=0; i<-keySig;i++){                                       
                    scale[(pos)%7]-=1 //minus half step
                    tpc1s[(pos)%7]-=7
                    tpc2s[(pos)%7]-=7
                    pos=(pos+3)%7                                       
                }                                   
            }
                            
            var scaleMap=[]
            var tpc1Map=[]
            var tpc2Map=[]
                                
            for (var j=0; j<11;j++){
                scaleMap=scaleMap.concat(scale)
                tpc1Map=tpc1Map.concat(tpc1s)
                tpc2Map=tpc2Map.concat(tpc2s)
                scale=scale.map(function(x) { return x+12})                                                                                                        
            }
            
            for(var x=0;x<scaleMap.length;x++) {
                console.log(scaleMap[x]+"-"+tpc1Map[x]+"-"+tpc2Map[x])
            }
            
            const Map={pitch:scaleMap, tpc1:tpc1Map, tpc2:tpc2Map}
            return Map 
        }   
                                
        function invert(pivot, invType){         
            while (cursor.segment && cursor.tick < endTick) {
                var el=cursor.element                                       
                if (el.type == Element.CHORD) {                                   
                    for ( var n=0; n<el.notes.length; n++){                                              
                        if (invType==1){///chromatic
                            el.notes[n].pitch= pivot.pitch -(el.notes[n].pitch - pivot.pitch)   
                            el.notes[n].tpc1=  pivot.tpc1 -(el.notes[n].tpc1 - pivot.tpc1)
                            el.notes[n].tpc2=  pivot.tpc2 -(el.notes[n].tpc2 - pivot.tpc2)                                    
                        }
                        if(invType==0){///if diatonic
                            var Map=getDiatonicMap()                                                                                            
                            
                            var noteDiaIdx=getDiatonicIdx(el.notes[n])
                            
                            //check if pivot note is diatonic                                                                    
                            if (Map.pitch.some(function(x){return x==pivot.pitch})){ 
                            var pivotIdx=Map.pitch.indexOf(pivot.pitch)
                            }
                            else{////pivot pitch is not a diatonic note
                                var nearestPivotIdx=Map.pitch.indexOf(pivot.pitch+1) 
                                var pivotIdx= nearestPivotIdx-0.5
                            }
                            
                            ///get noteIndex of inverse note
                            var invNoteIdx=pivotIdx-(noteDiaIdx-pivotIdx)

                            // console.log(" => invNoteIdx = "+invNoteIdx+" for ranges "+Map.pitch.length+", "+Map.tpc1.length+", "+Map.tpc2.length);
                            
                            ///apply inversion
                            el.notes[n].pitch= Map.pitch[invNoteIdx]
                            el.notes[n].tpc1= Map.tpc1[invNoteIdx]
                            el.notes[n].tpc2= Map.tpc2[invNoteIdx]
                        }                                
                    }
                }                              
              cursor.next()             
            } 
            getEnharmonic()
        }     
            
        
        function invertUsingOutermostPitches(invType){
           var pivot={pitch:0, tpc1:0, tpc2:0}        
           pivot.pitch = Lnote.pitch+(Hnote.pitch-Lnote.pitch)/2            
           pivot.tpc1=Lnote.tpc1+(Hnote.tpc1-Lnote.tpc1)/2 
           pivot.tpc2=Lnote.tpc2+(Hnote.tpc2-Lnote.tpc2)/2  

            while (cursor.segment && cursor.tick < endTick) {
                var el=cursor.element                                       
                if (el.type == Element.CHORD) {                                   
                    for ( var n=0; n<el.notes.length; n++){  

                        if (invType==1){///chromatic 
                            el.notes[n].pitch= pivot.pitch -(el.notes[n].pitch - pivot.pitch)
                            el.notes[n].tpc1= pivot.tpc1 -(el.notes[n].tpc1 - pivot.tpc1)
                            el.notes[n].tpc2= pivot.tpc2 -(el.notes[n].tpc2 - pivot.tpc2)
                        }

                        if (invType==0){///diatonic
                            var Map=getDiatonicMap() 
                            var noteDiaIdx=getDiatonicIdx(el.notes[n])
                            
                            var LnoteDiaIdx=getDiatonicIdx(Lnote)
                            var HnoteDiaIdx=getDiatonicIdx(Hnote)
                            var invNoteDiaIdx= HnoteDiaIdx - (noteDiaIdx - LnoteDiaIdx ) 
                            
                            el.notes[n].pitch= Map.pitch[invNoteDiaIdx]
                            el.notes[n].tpc1= Map.tpc1[invNoteDiaIdx]
                            el.notes[n].tpc2= Map.tpc2[invNoteDiaIdx]
                       
                        }
                    }
                    
                }  
                cursor.next()  
            } //end while
        }   ///end func
            
        function getDiatonicIdx(note){
            var Map=getDiatonicMap()
            
            /// if diatonic note 
            if (Map.pitch.some(function(x){return x==note.pitch})){                        
            var diaNoteIdx=Map.pitch.indexOf(note.pitch)
                return diaNoteIdx
            }
            else{//// if pitch is not a diatonic note
                var nextDiaNoteIdx=Map.pitch.indexOf(note.pitch+1) 

                if (curScore.style.value('concertPitch')){
                    var nextDiaNoteTpc=Map.tpc1[nextDiaNoteIdx]
                }
                else{
                    var nextDiaNoteTpc=Map.tpc2[nextDiaNoteIdx]
                }

                if (note.tpc+7== nextDiaNoteTpc){
                    var diaNoteIdx=nextDiaNoteIdx
                    return diaNoteIdx
                }
                else{
                    var diaNoteIdx=Map.pitch.indexOf(note.pitch-1)
                    return diaNoteIdx
                }
                //var noteDeg=Map.pitch.indexOf(el.notes[n].pitch + Math.pow(-1, acc))  ///math.pow maps sharp to -1, flat to 1
            }
        }    

        //////////////////// Mapping Functions ///////////////////////////
        function transpose(scale, interval){

            //var interval=(12 - 5*keySig)%12
            scale.pitch=scale.pitch.map(function(x){return x+interval})
            scale.tpc1=scale.tpc1.map(function(x){return x+interval*7})
                        
            while(scale.tpc1.some(function(x){return x>26})){
                scale.tpc1=scale.tpc1.map(function(x){return x-12})
            }
            while(scale.tpc1.some(function(x){return x<6})){
                scale.tpc1=scale.tpc1.map(function(x){return x+12})
            }
            return scale
        }//func
        
       function getScaleMap(scale){            
            var trans=getTrans() 
            scale.tpc2=scale.tpc1.map(function(x) { return x+trans})   
            
            var pitchMap=[]
            var tpc1Map=[]
            var tpc2Map=[]
                                
            for (var j=0; j<11;j++){
                pitchMap=pitchMap.concat(scale.pitch)
                tpc1Map=tpc1Map.concat(scale.tpc1)
                tpc2Map=tpc2Map.concat(scale.tpc2)
                scale.pitch=scale.pitch.map(function(x){return x+12})                                                                                                                                        
            }
                                
            const Map={pitch:pitchMap, tpc1:tpc1Map, tpc2:tpc2Map}
            return Map 
        }    
        
        function performMapping(Map){                    
            while (cursor.segment != null && cursor.tick < endTick) {
                var el=cursor.element              
                if (el.type == Element.CHORD) {                     
                    for ( var n=0; n<el.notes.length; n++){
                        var PosD=0
                        var NegD=0
                        var offset=0
                        while (!Map.pitch.some(function(x){return x==el.notes[n].pitch+PosD})){
                            PosD++
                        }
                        while (!Map.pitch.some(function(x){return x==el.notes[n].pitch+NegD})){
                            NegD--
                        }
                        if (PosD+NegD>0){
                            offset=NegD
                        }
                        if (PosD+NegD<0){ 
                            offset=PosD
                        }                            
                        if (PosD!=0 && PosD==-NegD){ //check tpc
                            var noteIdx = Map.pitch.indexOf(el.notes[n].pitch+NegD)
                            
                            if (el.notes[n].tpc1-Map.tpc1[noteIdx] == 7){
                                offset=NegD
                            }
                            else{
                                offset=PosD
                            }                                
                        }
                        //console.log(el.notes[n].pitch,offset, Map.pitch.indexOf(el.notes[n].pitch+offset))
                        var noteIdx = Map.pitch.indexOf(el.notes[n].pitch+offset)                            
                        el.notes[n].pitch = Map.pitch[noteIdx]
                        el.notes[n].tpc1 = Map.tpc1[noteIdx]
                        el.notes[n].tpc2=Map.tpc2[noteIdx]
                    }                    
                }                       
            cursor.next()              
            }                
        }///end performMapping
        //////////////////////////// end Mapping Functions ////////////////////////////
            
    }/// end transfor  


    ////////////////////////////////////////////////////////
    MessageDialog {
        id: errorDialog
        icon: StandardIcon.Information
        standardButtons: StandardButton.Ok
        title: qsTr('Warning')
        text: ""
    }
    SystemPalette {
        id: sysActivePalette;
        colorGroup: SystemPalette.Active
    }
    
    Rectangle {
        id : window
        //title: qsTr("rotate Pitches and Rhythm…")
        anchors.fill: parent
        //minimumWidth :300
        //minimumHeight : 200
        //visible : true
        color : (mscoreMajorVersion >= 4)?ui.theme.backgroundSecondaryColor:"#363638"//"#2d2d30" //sysActivePalette//"#333"
        
       
        MouseArea {
            id: mouseArea
            anchors.rightMargin: 0
            anchors.bottomMargin: 0
            anchors.leftMargin: 0
            anchors.topMargin: 0
            anchors.fill: parent

            TabBar {
                //color : sysActivePalette
                hoverEnabled : true
                id:bar
                width: parent.width
                
                height: parent.height/8
                currentIndex: 0
                font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                font.pointSize: 10
                TabButton {
                    id: rotateTab 
                    text: "Rotate" 
                    height: parent.height
                    contentItem: Text {
                        text: rotateTab.text
                        font: bar.font
                        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                        //opacity: rotateTab.checked ? 1 : 0.8
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        implicitWidth: parent.width/4
                        implicitHeight: parent.height

                        //color: rotateTab.hovered ? (rotateTab.checked ? "#2b3744" : "#424244") : "#2d2d30" //"#717171" //(btnClose.down ? "#717171" : "#565656") : "#646464"
                        color: (mscoreMajorVersion >= 4)? (rotateTab.hovered? ui.theme.buttonColor : ui.theme.backgroundPrimaryColor) : "#2d2d30"
                         opacity: rotateTab.hovered ? (rotateTab.down ? 1:0.5) : 0.75
                        // border.color: "#888"
                        //radius: 4
        
                     }    
                }
                TabButton {
                    id: reverseTab
                    text: "Retrograde" 
                  
                    height: parent.height 
                    contentItem: Text {
                        text: reverseTab.text
                        font: bar.font
                        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                        //opacity: reverseTab.checked ? 1 : 0.8
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        implicitWidth: parent.width/4
                        implicitHeight: parent.height

                        //color: reverseTab.hovered ? (reverseTab.checked ? "#2b3744" : "#424244") : "#2d2d30" //(btnClose.down ? "#717171" : "#565656") : "#646464"
                        color: (mscoreMajorVersion >= 4)? (reverseTab.hovered? ui.theme.buttonColor : ui.theme.backgroundPrimaryColor) : "#2d2d30"
                        opacity: reverseTab.hovered ? (reverseTab.down ? 1:0.5) : 0.75
                        // border.color: "#888"
                        //radius: 4
        
                     }              
                }
                TabButton {
                    id: invertTab 
                    text: "Invert"  
                    height: parent.height
                    contentItem: Text {
                        text: invertTab.text
                        font: bar.font
                        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                        //opacity: invertTab.checked ? 1 : 0.8
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        implicitWidth: parent.width/4
                        implicitHeight: parent.height
                        
                        // color: invertTab.hovered ? (invertTab.checked ? "#2b3744" : "#424244") : "#2d2d30" //(btnClose.down ? "#717171" : "#565656") : "#646464"
                        color: (mscoreMajorVersion >= 4)? (invertTab.hovered? ui.theme.buttonColor : ui.theme.backgroundPrimaryColor) : "#2d2d30"
                        opacity: invertTab.hovered ? (invertTab.down ? 1:0.5) : 0.75
                        // border.color: "#888"
                        //radius: 4
        
                     }                            
                }              
                TabButton {
                    id: mapTab 
                    text: "Map"  
                    height: parent.height
                    contentItem: Text {
                        text: mapTab.text
                        font: bar.font
                        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                        //opacity: mapTab.checked ? 1 : 0.8
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        implicitWidth: parent.width/4
                        implicitHeight: parent.height

                        color: (mscoreMajorVersion >= 4)? (mapTab.hovered? ui.theme.buttonColor : ui.theme.backgroundPrimaryColor) : "#2d2d30"
                        opacity: mapTab.hovered ? (mapTab.down ? 1:0.5) : 0.75
                        //radius: 4
        
                    }                                 
                }
            }
            Rectangle {
                id : decorator;
                property int targetX: (mscoreMajorVersion >= 4)?bar.currentItem.x:bar.currentItem.x+2*invertTab.width  // trick for MU3.6: bar.currentItem.x is negative !!
                anchors.top: bar.bottom;
                width: bar.currentItem.width;
                height: 2;
                color: (mscoreMajorVersion >= 4)? ui.theme.accentColor : "#2093fe"
                NumberAnimation on x {
                    duration: 100;
                    to: decorator.targetX
                    running: decorator.x != decorator.targetX
                }
                Shortcut {
                    sequence: "Tab"
                    onActivated: {
                    //focus next tab
                    bar.currentIndex = (bar.currentIndex + 1)%4
                }
            }   
            }    
        
            
            ColumnLayout {    /// rotate items
                enabled: rotateTab.checked
                visible: rotateTab.checked
                x: 20////80 
                anchors.top:bar.bottom 
                anchors.topMargin:20
                ButtonGroup {id: rotateOptions}

                MyRadioButton {
                    //color: sysActivePalette.text
                    id: rotatePitchesBox
                    ButtonGroup.group: rotateOptions
                    text: "Rotate Pitches" 
                }
                MyRadioButton {
                    //color: sysActivePalette
                    id: rotateRhythmBox
                    ButtonGroup.group: rotateOptions
                    text: qsTr("Rotate Rhythm")
                }
                MyRadioButton {
                    id: rotateBothBox
                    ButtonGroup.group: rotateOptions
                    text: qsTr("Rotate Pitches and Rhythm")
                }
            
                Row{
                    //x: 30
                    anchors.top: rotateBothBox.bottom
                    anchors.topMargin: 15
                    Label {
                        text: "Select number of steps by which to rotate: "
                        //color: sysActivePalette.text//"#333"   
                        font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                        font.pointSize: 10        
                        id: stepBoxText
                        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor :  "white"
                    }
            
                    SpinBox {
                        id: stepBox
                        anchors.verticalCenter: stepBoxText.verticalCenter
                        // width: 50 
                        width: (mscoreMajorVersion >= 4)?50:undefined
                        font.pointSize: 10                
                        font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                        hoverEnabled: true
                        opacity: hovered ? 0.8:1
                        from: -100
                        value: 0
                        to: 99
                        stepSize: 1

                        // background: Rectangle {
                        //     color:(mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#242427"
                        //     border.color: (mscoreMajorVersion >= 4)? ui.theme.strokeColor : "grey"
                        //     radius: 4                           
                        // }                         

                        textFromValue: function (value) {
                            return Number((value < 0) ? value : value + 1); //  bypass 0: -2, -1, 1, 2
                        }
                        property var val: (stepBox.value<0) ? stepBox.value : stepBox.value+1      //get value corresponding to displayed number    
                    } 
                } 
            }
           
        
            ColumnLayout {    //reverse items                  
                enabled: reverseTab.checked
                visible: reverseTab.checked
                x: 20////80 
                anchors.top:bar.bottom 
                anchors.topMargin:20  
                ButtonGroup {id: reverseOptions}
                MyRadioButton {
                    id: reversePitchesBox
                    ButtonGroup.group: reverseOptions
                    text: "Reverse Pitches" // 8
                }
                MyRadioButton {
                    id: reverseRhythmBox
                    ButtonGroup.group: reverseOptions
                    text: qsTr("Reverse Rhythm")
                }
                MyRadioButton {
                    id: reverseBothBox
                    ButtonGroup.group: reverseOptions           
                    text: qsTr("Reverse Pitches and Rhythm")
                }
            
            }///end reverse items
                
            ////////////  Invert TAB ////////////////////
               
                
            ColumnLayout{  
                enabled: invertTab.checked
                visible: invertTab.checked
                ButtonGroup {id: invertOptions}
                //anchors.topMargin: 20
                anchors.top: bar.bottom
                anchors.topMargin: 20
                anchors.left: parent.left
                anchors.leftMargin: 20
                Label{
                    x: 20
                    text: "Invert Using:"
                    font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                    font.pointSize: 10  
                    color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                }     
                MyRadioButton {
                    id: invertByOutermostPitchesBox
                    ButtonGroup.group: invertOptions
                    text: "Outermost Pitches" // 8                                 
                }
                MyRadioButton {
                    id: invertByPitch
                    ButtonGroup.group: invertOptions
                    text: qsTr("Specific Pitch:")                        
                }
                Row{                
                    enabled: invertByPitch.checked
                    visible: invertByPitch.checked
                    //x: 30
                    anchors.left: invertByPitch.right
                    anchors.verticalCenter: invertByPitch.verticalCenter
                    anchors.leftMargin: 20
                        
                    spacing: 5              
                
                    MyComboBox {               
                        id: noteBox                            
                        currentIndex: 0                                  
                        model: ListModel {
                            id: noteList                        
                            ListElement { text: "C" }
                            ListElement { text: "D" }
                            ListElement { text: "E" }
                            ListElement { text: "F" }
                            ListElement { text: "G" }
                            ListElement { text: "A" }
                            ListElement { text: "B" }                    
                        }                              
                    }
                
                    MyComboBox {               
                        id: accidentalBox                            
                        currentIndex: 1                                    
                        model: ListModel {                    
                            ListElement { text: "♭" }
                            ListElement { text: "♮" }
                            ListElement { text: "♯" }                                                
                        }                            
                    }

                    SpinBox {
                        id: octaveBox
                        width: (mscoreMajorVersion >= 4)?50:undefined
                        
                        from: 0
                        value: 4
                        to: 9
                        stepSize: 1
                        hoverEnabled: true
                        opacity: hovered ? 0.8:1 
                        ToolTip.visible: hovered
                        ToolTip.delay: 500                            
                        ToolTip.text: qsTr("8va")
                        
                        ToolTip.timeout: 1000   
                        font.pointSize: 10 
                        font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                        
                        // background: Rectangle {
                        //     color:(mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#242427"
                        //     border.color: (mscoreMajorVersion >= 4)? ui.theme.strokeColor : "grey"
                        //     radius: 4                           
                        // }                                 
                    }  
                }//row   
                Row {  
                    anchors.top: invertByPitch.bottom
                    anchors.topMargin: 20
                    anchors.left: parent.left
                    anchors.leftMargin:20               
                    
                    Label{ 
                        id: diatonic 
                        text: "Diatonic" 
                        font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                    }
                            
                    Switch { 
                        id: invertType
                        anchors.verticalCenter: diatonic.verticalCenter 
                        hoverEnabled: true
                        opacity: hovered ? 0.8:1 
                        checked: true
                        indicator: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 20
                            x: invertType.width - width - invertType.rightPadding
                            y: parent.height / 2 - height / 2
                            radius: 13
                            color: (mscoreMajorVersion >= 4)? ui.theme.textFieldColor :"#242427"//"#565656" : "#565656"
                            border.color: (mscoreMajorVersion >= 4)? ui.theme.strokeColor : "#2d2d30"

                            Rectangle {
                                x: invertType.checked ? parent.width - width : 0
                                width: 20
                                height: 20
                                radius: 13
                                border.color: (mscoreMajorVersion >= 4)? ui.theme.strokeColor:"#2d2d30"
                                color: (mscoreMajorVersion >= 4)? ui.theme.accentColor : "#277eb9"//"#40acff"//"#265f97"
                            }
                        }
                    }
                    
                    Label{ 
                        text: "Chromatic" 
                        font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                    }     
                }       
            }         
            
            
                
                
            
            /////////////////// Map Tab //////////////////
            Item{                
                
                enabled:mapTab.checked
                visible: mapTab.checked                
                
                anchors.top: bar.bottom
                anchors.topMargin: 20
                anchors.left: parent.left
                anchors.leftMargin: 20                

                Label{
                    id: mapUntoLabel                    
                    text: "Map Unto:"
                    font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                    font.pointSize: 10  
                    color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                }       
                Row{
                    height:25
                    anchors.top: mapUntoLabel.bottom                    
                    anchors.topMargin: 10
                    spacing:5
                
                    MyComboBox { 
                        id: noteBoxMap                                      
                        model: ListModel {
                            id: noteListMap                        
                            ListElement { text: "C" }
                            ListElement { text: "D" }
                            ListElement { text: "E" }
                            ListElement { text: "F" }
                            ListElement { text: "G" }
                            ListElement { text: "A" }
                            ListElement { text: "B" }                    
                        }
                    }
                    
                    MyComboBox {               
                        id: accidentalBoxMap
                        currentIndex: 1
                        model: ListModel {                    
                            ListElement { text: "♭" }
                            ListElement { text: "♮" }
                            ListElement { text: "♯" }                                        
                        }
                    }                                

                    MyModesMenu{
                        id: mainMenu
                        anchors.left: accidentalBoxMap.right 
                        anchors.leftMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        height: 30
                    }
                }// RowLayout
            }/// Item
            ////////////// end Map Tab //////////////////////////////



            RowLayout {         
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10                     
                anchors.right: parent.right
                anchors.rightMargin: 10
                spacing: 5          
                
                Button {                 
                    id: btnApply
                    hoverEnabled: true
                    highlighted: clicked
                    text: qsTr("Apply")  
                    contentItem: Text {
                        text: btnApply.text
                        font: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }                    
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 25
                        // color: btnApply.hovered ?  (btnApply.down ? "#2093fe" : "#265f97") : "#277eb9"
                        color: (mscoreMajorVersion >= 4)? ui.theme.accentColor : "#277eb9"
                        opacity: btnApply.hovered ?  (btnApply.down ? 1:0.5) : 0.75
                        // border.color: "#888"
                        radius: 4
        
                     }                   
                    onClicked: {

                        if ( (rotateTab.checked && !rotatePitchesBox.checked && !rotateRhythmBox.checked && !rotateBothBox.checked ) ||
                            (reverseTab.checked && !reversePitchesBox.checked && !reverseRhythmBox.checked && !reverseBothBox.checked) ||
                            (invertTab.checked && !invertByPitch.checked && !invertByOutermostPitchesBox.checked) ||
                            (mapTab.checked && mainMenu.modeNumber[1]==null) ){
                            errorDialog.text="Please select an option to perform a transformation."
                            errorDialog.open()
                        }
                        var cursor=curScore.newCursor()
                        cursor.rewind(1)
                        if (!cursor.segment) {
                            errorDialog.text="No valid range selection on current score!"            
                            errorDialog.open() 
                        }   
                        else{         
                            applyTransform()
                        }
                    }      
                }
            


                Button {
                    
                    id:  btnClose
                    hoverEnabled: true
                    highlighted: clicked
                    text: qsTr("Close")
                    contentItem: Text {
                        text: btnClose.text
                        font: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
                        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }                    
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 25
                        color: (mscoreMajorVersion >= 4)? ui.theme.buttonColor : "#646464"
                        opacity: btnClose.hovered ?  (btnClose.down ? 1 : 0.5) : 0.75
                        // border.color: "#888"
                        radius: 4
        
                     }                  
                    onClicked: {
                        //window.close();
                        mainWindow.parent.Window.window.close() 
                    }
                }        
            }
            //  Item{
            //     id: escapeItem
            //     focus: true
                
            //            keys.onShortcutOverride: (event)=> event.accepted = (event.key === Qt.Key_Escape)
            //         Keys.onEscapePressed: {quit()}      
            // }    

            Shortcut {
                sequence: "Esc"//StandardKey.Quit//"Escape"
                //enabled: true
                //context: Qt.WindowShortcut//Qt.ApplicationShortcut
                onActivated: {mainWindow.parent.Window.window.close()}
                
            } 
            
        }//mouse area
        
    }//end window
}//end ms
