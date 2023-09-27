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
    
    title: "Transform Pitches and Rhythm"
    description: "Rotate, reverse, or invert pitches, rhythm, or both"
    version: "1.0"
    thumbnailName:"Transformer.jpg"
    categoryCode:"Composition"
    pluginType: "dialog"
    width : 350        
    height : 250
        
    onRun: {
        //window.visible = true            
    }

    
    function applyTransform(){
        
        
        if (!curScore.selection) {
            errorDialog.text="No valid range selection on current score!"
            errorDialog.open()
            return;
        }       
        
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
        var onlyPitches=[]
        var Pitches=[]
        var Rhythm=[]
        var Hnote={pitch:0, tpc1:0, tpc2:0}
        var Lnote={pitch:128, tpc1:128, tpc2:128}
        while (cursor.segment != null && cursor.tick < endTick) {
            var dur= [];
            var tupdur = [];
            var ratio = [];
            var chord=[]
            var atMeasureEnd= false

            var el=cursor.element

            if(el.type == Element.REST) { 
                var chord = 'REST'; 
            }
            if (el.type == Element.CHORD) {
                for (var n in el.notes){
                    var pitch = el.notes[n].pitch 
                    var tpc = el.notes[n].tpc
                    var tpc1 = el.notes[n].tpc1
                    var tpc2 = el.notes[n].tpc2
                    if(pitch>Hnote.pitch){
                        Hnote.pitch=pitch, 
                        Hnote.tpc1=tpc1, 
                        Hnote.tpc2=tpc2
                    }
                    if(pitch<Lnote.pitch){
                        Lnote.pitch=pitch, 
                        Lnote.tpc1=tpc1, 
                        Lnote.tpc2=tpc2
                    }  
                    var chordNote={pitch:pitch, tpc:tpc, tpc1:tpc1, tpc2:tpc2}
                    chord.push(chordNote)
                    //chord.push([pitch,tpc, tpc1,tpc2]) 
                }
                onlyPitches.push(chord)
            } 

            if(el.tuplet) { // tuplets are a special case
                tupdur.push(el.tuplet.globalDuration.numerator);
                tupdur.push(el.tuplet.globalDuration.denominator);
                ratio.push(el.tuplet.actualNotes);
                ratio.push(el.tuplet.normalNotes);
                var tupLength= el.tuplet.elements.length
            }
            if (cursor.tick==cursor.measure.lastSegment.tick){
                atMeasureEnd=true
            }
            dur.push(el.duration.numerator); // numerator of duration
            dur.push(el.duration.denominator); // denominator of duration
            const durations={dur: dur, 
                            tupdur: tupdur, 
                            ratio: ratio , 
                            atMeasureEnd: atMeasureEnd,
                            tupLength: tupLength}
            Rhythm.push(durations)
            Pitches.push(chord) 
            cursor.next();
        }
        /////////////////////////////////////////////////////////////
        console.log(Pitches[0], Pitches[1], Pitches[2],Pitches[3])
        
        if (!Pitches.length) {
            errorDialog.text="No valid range selection on current score!"
            errorDialog.open()
            return;
        }
        
        cursor.rewind(1) 
       
        curScore.startCmd()
        //// if tuplet at ends of selection change step to number of tuplet notes
        if (Rhythm[Rhythm.length-1].ratio[0]>0 && stepBox.val>0){
            var step =Rhythm[Rhythm.length-1].tupLength
        }
        else if (Rhythm[0].ratio[0]>0 && stepBox.val<0){
            var step=-Rhythm[0].tupLength
        }
        else{
            var step= stepBox.val
        }
        
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
        if (invertByPitch.checked){
             var accidental=accidentalBox.currentText
             var octave=octaveBox.value
             var noteIdx=noteBox.currentIndex
             
            var pivot= getPivot(noteIdx,accidental, octave)
            //var invType= "chromatic"
            //console.log(invertType.position)
            var enharmonic= true //false
            invert(pivot, invertType.position)
        
            
        }
        if (invertByOutermostPitchesBox.checked){
            invertUsingOutermostPitches(invertType.position)
        }
        ////////////////////////
        
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
             cursor.rewind(startTick)
             while (cursor.segment && cursor.tick < endTick){
               var el=cursor.element
               if (el.type==Element.CHORD){
                  var dtpc=el.notes[0].tpc2-el.notes[0].tpc1                 
                  return dtpc
               }
                cursor.next()
             }
         }
         
        function getPivot(noteIdx, accidental, octave){ ////calculate pivot pitch and tpc values from user input
             var trans=getTrans()  
             if (curScore.style.value('concertPitch')){ 
                   var TV=[0,0,trans] // Transposition Vector [pitch, tpc1, tpc2]
            }
             else{ 
                   var TV=[-trans,-trans,0]
            }
        
             const C={pitch:0 + TV[0],tpc1:14 + TV[1], tpc2:14 + TV[2]} //12
             const D={pitch:2+ TV[0],tpc1:16 + TV[1], tpc2:16 + TV[2]}// 14
             const E={pitch:4+ TV[0],tpc1:18 + TV[1], tpc2:18 + TV[2]} //16
             const F={pitch:5+ TV[0],tpc1:13 + TV[1], tpc2:13 + TV[2]} //17
             const G={pitch:7+ TV[0],tpc1:15 + TV[1], tpc2:15 + TV[2]} //19
             const A={pitch:9+ TV[0],tpc1:17 + TV[1], tpc2:17 + TV[2]} //21
             const B={pitch:11+ TV[0],tpc1:19 + TV[1], tpc2:19 + TV[2]}//22
             var notes=[C,D,E,F,G,A,B]
             var note= notes[noteIdx] 
            
            
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
         
        function getEnharmonic(tpcValue){ //confine tpc values between 11 and 21 in order to not have double sharps or doulble flats
           if (tpcValue<10){return tpcValue+=12}        
           if (tpcValue>21){return tpcValue-=12}
           else{ return tpcValue} 
        }      
        
        function getDiatonicMap(){
            var trans=getTrans()
            var keySig= curScore.keysig 
            var scale=[0,2,4,5,7,9,11]
            var tpc1s=[14,16,18,13,15,17,19]                                    
            var tpc2s=[14+trans,16+trans,18+trans,13+trans,15+trans,17+trans,19+trans]         
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
                 for (var i=0; i<keySig;i++){                                       
                      scale[(pos)%7]-=1 //minus half step
                      tpc1s[(pos)%7]-=7
                      tpc2s[(pos)%7]-=7
                      pos=(pos+3)%7                                       
                 }                                   
              }
                                   
              //console.log(scale)                     
              var scaleMap=[]
              var tpc1Map=[]
              var tpc2Map=[]
                                   
              for (var j=0; j<11;j++){
                  scaleMap=scaleMap.concat(scale)
                  tpc1Map=tpc1Map.concat(tpc1s)
                  tpc2Map=tpc2Map.concat(tpc2s)
                  for (var i=0;i<scale.length; i++){
                       scale[i]+=12                                          
                  }                                                                                                                        
              }
                                   
             const Map={scale:scaleMap, tpc1:tpc1Map, tpc2:tpc2Map}
             return Map 
         }   
                                
        function invert(pivot, invType){         
            while (cursor.segment && cursor.tick < endTick) {
                var el=cursor.element                                       
                if (el.type == Element.CHORD) {                                   
                        for ( var n=0; n<el.notes.length; n++){                                              
                              if (invType==1){///chromatic
                                    el.notes[n].pitch= pivot.pitch -(el.notes[n].pitch - pivot.pitch)                              
                                     //el.notes[n].tpc=  pivot.tpc -(el.notes[n].tpc-pivot.tpc)
                                    el.notes[n].tpc1=  pivot.tpc1 -(el.notes[n].tpc1 - pivot.tpc1)
                                    el.notes[n].tpc2=  pivot.tpc2 -(el.notes[n].tpc2 - pivot.tpc2)
                                    // if (enharmonic){
                                    // console.log(el.notes[n].tpc1)
                                    //       el.notes[n].tpc1= getEnharmonic(el.notes[n].tpc1)
                                    //       el.notes[n].tpc2= getEnharmonic(el.notes[n].tpc2)
                                    // }
                                    
                              }
                              if(invType==0){///if diatonic
                                   var Map=getDiatonicMap()                                                                                            
                                   
                                    if (Map.scale.includes(el.notes[n].pitch)){ 
                                        var noteDeg=Map.scale.indexOf(el.notes[n].pitch)
                                    }
                                    else{////pivot pitch is not a diatonic note consider the closest diatonic note. ex: c# --> c;  Db--> D
                                        var upNoteDeg=Map.scale.indexOf(el.notes[n].pitch+1) 

                                        if (curScore.style.value('concertPitch')){
                                            var upNoteTpc=Map.tpc1[upNoteDeg]
                                        }
                                        else{
                                            var upNoteTpc=Map.tpc2[upNoteDeg]
                                        }

                                        if (el.notes[n].tpc+7== upNoteTpc){
                                            var noteDeg=upNoteDeg
                                        }
                                        else{
                                            var noteDeg=Map.scale.indexOf(el.notes[n].pitch-1)
                                        }
                                    }
                                   
                                   
                                   
                                    //check if pivot note is diatonic                                                                    
                                    if (Map.scale.includes(pivot.pitch)){ 
                                        var pivotDeg=Map.scale.indexOf(pivot.pitch)
                                    }
                                    else{////pivot pitch is not a diatonic note
                                       var nearestPivot=Map.scale.indexOf(pivot.pitch+1) 
                                       var pivotDeg= nearestPivot-0.5
                                    }
                                    
                                    ///get noteIndex of inverse note
                                    var invNoteDeg=pivotDeg-(noteDeg-pivotDeg)
                                   
                                    ///apply inversion
                                    el.notes[n].pitch= Map.scale[invNoteDeg]
                                    el.notes[n].tpc1= Map.tpc1[invNoteDeg]
                                    el.notes[n].tpc2= Map.tpc2[invNoteDeg]
                               }                                
                        }
                }                              
              cursor.next()             
            } 
        }     
            
        
        function invertUsingOutermostPitches(invType){
           var pivot={pitch:0, tpc1:0, tpc2:0}
           //console.log(Hnote.pitch, Lnote.pitch)
           pivot.pitch = Lnote.pitch+(Hnote.pitch-Lnote.pitch)/2 
           //console.log(pivot.pitch)
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
                                                                                            
                            if (Map.scale.includes(el.notes[n].pitch)){
                                var noteDeg=Map.scale.indexOf(el.notes[n].pitch)
                            }
                            else{////pivot pitch is not a diatonic note
                                var upNoteDeg=Map.scale.indexOf(el.notes[n].pitch+1) 

                                    if (curScore.style.value('concertPitch')){
                                        var upNoteTpc=Map.tpc1[upNoteDeg]
                                    }
                                    else{
                                        var upNoteTpc=Map.tpc2[upNoteDeg]
                                    }

                                    if (el.notes[n].tpc+7== upNoteTpc){
                                        var noteDeg=upNoteDeg
                                    }
                                    else{
                                        var noteDeg=Map.scale.indexOf(el.notes[n].pitch-1)
                                    }
                                   //var noteDeg=Map.scale.indexOf(el.notes[n].pitch + Math.pow(-1, acc))  ///math.pow maps sharp to -1, flat to 1
                            }          
                            
                            
                            //check if pivot note is diatonic                                                                                
                            if (Map.scale.includes(pivot.pitch)){
                                var pivotDeg=Map.scale.indexOf(pivot.pitch)
                            }
                            else{////pivot pitch is not a diatonic note
                                var nearestPivot=Map.scale.indexOf(pivot.pitch+1) 
                                var pivotDeg= nearestPivot-0.5
                            }
                            ///get noteIndex of inverse note
                            var invNoteDeg=pivotDeg-(noteDeg-pivotDeg)
                            
                            ///apply inversion
                            el.notes[n].pitch= Map.scale[invNoteDeg]
                            el.notes[n].tpc1= Map.tpc1[invNoteDeg]
                            el.notes[n].tpc2= Map.tpc2[invNoteDeg]
                        }
                    }
                    
                }  
                cursor.next()  
            } //end while
        }   ///end func
            
            
            
        
        
            
        curScore.endCmd()
        
        curScore.selection.selectRange(startTick, endTick, startStaff, endStaff);
        
      
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
        color : "#363638"//"#2d2d30" //sysActivePalette//"#333"
       
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
                font.family: "segoe UI"
                font.pointSize: 10
                palette.buttonText: "white"
                TabButton {
                    id: rotateTab 
                    text: "Rotate..." 
                    height: parent.height
                    background: Rectangle {
                        implicitWidth: parent.width/3
                        implicitHeight: parent.height

                        color: rotateTab.hovered ? (rotateTab.checked ? "#2b3744" : "#424244") : "#2d2d30" //"#717171" //(btnClose.down ? "#717171" : "#565656") : "#646464"
                        // border.color: "#888"
                        //radius: 4
        
                     }    
                }
                TabButton {
                    id: reverseTab
                    text: "Reverse..." 
                  
                    height: parent.height 
                    background: Rectangle {
                        implicitWidth: parent.width/3
                        implicitHeight: parent.height

                        color: reverseTab.hovered ? (reverseTab.checked ? "#2b3744" : "#424244") : "#2d2d30" //(btnClose.down ? "#717171" : "#565656") : "#646464"
                        // border.color: "#888"
                        //radius: 4
        
                     }              
                }
                TabButton {
                    id: invertTab 
                    text: "Invert..."  
                    height: parent.height
                    background: Rectangle {
                        implicitWidth: parent.width/3
                        implicitHeight: parent.height

                        color: invertTab.hovered ? (invertTab.checked ? "#2b3744" : "#424244") : "#2d2d30" //(btnClose.down ? "#717171" : "#565656") : "#646464"
                        // border.color: "#888"
                        //radius: 4
        
                     }                            
                }
            }  
            Rectangle {
                id : decorator;
                property real targetX: (bar.currentItem.x )%bar.width 
                anchors.top: bar.bottom;
                width: bar.currentItem.width;
                height: 2;
                color: "#2093fe"
                NumberAnimation on x {
                    duration: 100;
                    to: decorator.targetX
                    running: decorator.x != decorator.targetX
                }
                Shortcut {
                    sequence: "Tab"
                    onActivated: {
                    //focus next tab
                    bar.currentIndex = (bar.currentIndex + 1)%3
                }
            }   
            }    
        
            
            ColumnLayout {    /// rotate items
                enabled: rotateTab.checked
                visible: rotateTab.checked
                x: 20////80 
                anchors.top:bar.bottom 
                anchors.topMargin:20
                ButtonGroup {id: options}

                RadioButton {
                    //color: sysActivePalette.text
                    id: rotatePitchesBox
                    ButtonGroup.group: options
                    text: "Rotate Pitches" 
                    
                    font.family: "segoe UI"
                    font.pointSize: 10
                    hoverEnabled: true
                    opacity: hovered ? 0.8:1
                    //palette.button: "white" 
                    indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        //x: rotatePitchesBox.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: "#242427"
                        border.color: "#c0c0c0"

                        Rectangle {
                            width: 10
                            height: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            
                            radius: 5
                            color: rotatePitchesBox.checked ? "#2093fe" : "#242427"
                            //visible: rotatePitchesBox.checked
                        }                       
                    }
                }
                RadioButton {
                    //color: sysActivePalette
                    id: rotateRhythmBox
                    ButtonGroup.group: options
                    text: qsTr("Rotate Rhythm")
                    font.family: "segoe UI"
                    font.pointSize: 10
                    icon.color: "grey"
                    hoverEnabled: true
                    opacity: hovered ? 0.8:1
                    indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        //x: rotatePitchesBox.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: "#242427"
                        border.color: "#c0c0c0"

                        Rectangle {
                            width: 10
                            height: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            
                            radius: 5
                            color: rotateRhythmBox.checked ? "#2093fe" : "#242427"
                            //visible: rotatePitchesBox.checked
                        }                       
                    }
                }
                RadioButton {
                    id: rotateBothBox
                    ButtonGroup.group: options
                    text: qsTr("Rotate Pitches and Rhythm")
                    font.family: "segoe UI"
                    font.pointSize: 10
                    hoverEnabled: true
                    opacity: hovered ? 0.8:1
                    indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        //x: rotatePitchesBox.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: "#242427"
                        border.color: "#c0c0c0"

                        Rectangle {
                            width: 10
                            height: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            
                            radius: 5
                            color: rotateBothBox.checked ? "#2093fe" : "#242427"
                            //visible: rotatePitchesBox.checked
                        }                       
                    }
                }
            
                Row{
                    //x: 30
                    anchors.top: rotateBothBox.bottom
                    anchors.topMargin: 20
                    Label {
                        text: "Select number of steps by which to rotate: "
                        //color: sysActivePalette.text//"#333"   
                        font.family: "segoe UI"
                        font.pointSize: 10        
                    }
            
                    SpinBox {
                        id: stepBox
                        anchors.verticalCenter: text.verticalCenter
                        width: 50  
                        font.pointSize: 10                
                        font.family: "segoe UI"
                        hoverEnabled: true
                        opacity: hovered ? 0.8:1
                        from: -2
                        value: 0
                        to: 2
                        stepSize: 1

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

                RadioButton {
                    id: reversePitchesBox
                    ButtonGroup.group: options
                    text: "Reverse Pitches" // 8
                    font.family: "segoe UI"
                    font.pointSize: 10
                    hoverEnabled: true
                    opacity: hovered ? 0.8:1
                    indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        //x: rotatePitchesBox.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: "#242427"
                        border.color: "#c0c0c0"

                        Rectangle {
                            width: 10
                            height: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            
                            radius: 5
                            color: reversePitchesBox.checked ? "#2093fe" : "#242427"
                            //visible: rotatePitchesBox.checked
                        }                       
                    }
                }
                RadioButton {
                    id: reverseRhythmBox
                    ButtonGroup.group: options
                    text: qsTr("Reverse Rhythm")
                    font.family: "segoe UI"
                    font.pointSize: 10 
                    hoverEnabled: true
                    opacity: hovered ? 0.8:1  
                    indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        //x: rotatePitchesBox.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: "#242427"
                        border.color: "#c0c0c0"

                        Rectangle {
                            width: 10
                            height: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            
                            radius: 5
                            color: reverseRhythmBox.checked ? "#2093fe" : "#242427"
                            //visible: rotatePitchesBox.checked
                        }                       
                    }
                }
                RadioButton {
                    id: reverseBothBox
                    ButtonGroup.group: options           
                    text: qsTr("Reverse Pitches and Rhythm")
                    font.family: "segoe UI"
                    font.pointSize: 10   
                    hoverEnabled: true
                    opacity: hovered ? 0.8:1 
                    indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        //x: rotatePitchesBox.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: "#242427"
                        border.color: "#c0c0c0"

                        Rectangle {
                            width: 10
                            height: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            
                            radius: 5
                            color: reverseBothBox.checked ? "#2093fe" : "#242427"
                            //visible: rotatePitchesBox.checked
                        }                       
                    }
                }
            
            }///end reverse items
                
            // Item{
               
                
                ColumnLayout{                
                    //x: 10////80 
                    enabled: invertTab.checked
                    visible: invertTab.checked
                
                    //anchors.topMargin: 20
                    anchors.top: bar.bottom
                    anchors.topMargin: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    Label{
                        x: 20
                        text: "Invert Using:"
                        font.family: "segoe UI"
                        font.pointSize: 10  
                    }     
                    RadioButton {
                        id: invertByOutermostPitchesBox
                        ButtonGroup.group: options
                        text: "Outermost Pitches" // 8
                        font.family: "segoe UI"
                        font.pointSize: 10 
                        hoverEnabled: true  
                        opacity: hovered ? 0.8:1    
                        indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        //x: rotatePitchesBox.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: "#242427"
                        border.color: "#c0c0c0"

                        Rectangle {
                            width: 10
                            height: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            
                            radius: 5
                            color: invertByOutermostPitchesBox.checked ? "#2093fe" : "#242427"
                            //visible: rotatePitchesBox.checked
                        }                       
                    }                    
                    }
                    RadioButton {
                        id: invertByPitch
                        ButtonGroup.group: options
                        text: qsTr("Specific Pitch:")
                        font.family: "segoe UI"
                        font.pointSize: 10 
                        hoverEnabled: true
                        opacity: hovered ? 0.8:1   
                        indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        //x: rotatePitchesBox.leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: "#242427"
                        border.color: "#c0c0c0"

                        Rectangle {
                            width: 10
                            height: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            
                            radius: 5
                            color: invertByPitch.checked ? "#2093fe" : "#242427"
                            //visible: rotatePitchesBox.checked
                        }                       
                    }
                    }
                    Row{                
                        enabled: invertByPitch.checked
                        visible: invertByPitch.checked
                        //x: 30
                        anchors.left: invertByPitch.right
                        anchors.verticalCenter: invertByPitch.verticalCenter
                        anchors.leftMargin: 20
                         
                        spacing: 5              
                    
                        ComboBox {               
                            id: noteBox
                            width: 40
                            height: parent.height
                            currentIndex: 0    
                            font.pointSize: 10 
                            font.family: "segoe UI" 
                            hoverEnabled: true
                            opacity: hovered ? 0.8:1         
                            model: ListModel {
                                //id: notesList                        
                                ListElement { text: "C" }
                                ListElement { text: "D" }
                                ListElement { text: "E" }
                                ListElement { text: "F" }
                                ListElement { text: "G" }
                                ListElement { text: "A" }
                                ListElement { text: "B" }                    
                            }
                           palette.buttonText: "white"
                           background: Rectangle {
                                color:"#242427"
                                //implicitWidth: parent.width
                               // implicitHeight: parent.height
                                ////border.width: parent && parent.activeFocus ? 2 : 1
                                //border.color: parent && parent.activeFocus ? accidental.palette.highlight : accidental.palette.button
                                radius: 4
                            }
                            // background: Rectangle {
                            //     implicitWidth: parent.width
                            //     implicitHeight: parent.height

                            //     color: notesBox.hovered ? (notesBox.pressed ? "#2b3744" : "#424244") : "#2d2d30" //(btnClose.down ? "#717171" : "#565656") : "#646464"
                            //     // border.color: "#888"
                            //     //radius: 4
        
                            // }    
                        }
                    
                        ComboBox {               
                            id: accidentalBox
                            width: 40
                            height: parent.height
                            currentIndex: 1   
                            palette.buttonText: "white"
                            font.pointSize: 11 
                            font.family: "segoe UI"
                            hoverEnabled: true
                            opacity: hovered ? 0.8:1       
                            model: ListModel {                    
                                ListElement { text: "♭" }
                                ListElement { text: "♮" }
                                ListElement { text: "♯" }
                                                
                            }
                            background: Rectangle {
                                color:"#242427"
                                //implicitWidth: parent.width
                               // implicitHeight: parent.height
                                ////border.width: parent && parent.activeFocus ? 2 : 1
                                //border.color: parent && parent.activeFocus ? accidental.palette.highlight : accidental.palette.button
                                radius: 4
                            }
                        }

                        SpinBox {
                            id: octaveBox
                            width:50
                            
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
                            font.family: "segoe UI"
                           
                            // background: Rectangle {
                            //     color:"#242427"                            
                            // }        
                        }  
                    }//row   
                    Row {  
                        anchors.top: invertByPitch.bottom
                        anchors.topMargin: 30
                        anchors.left: parent.left
                        anchors.leftMargin:20               
                        
                        Label{ 
                            id: diatonic 
                            text: "Diatonic" 
                            font.family: "segoe UI" 
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
                                color: invertType.checked ? "#242427":"#242427"//"#565656" : "#565656"
                               // border.color: "black"

                                Rectangle {
                                    x: invertType.checked ? parent.width - width : 0
                                    width: 20
                                    height: 20
                                    radius: 13
                                    border.color: "#2d2d30"
                                    color: "#277eb9"//"#40acff"//"#265f97"
                                }
                            }
                        }
                        
                        Label{ 
                            text: "Chromatic" 
                            font.family: "segoe UI"
                        }     
                    }       
                }         

            
                
                
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
                    palette.buttonText: "white"
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 25
                        color: btnApply.hovered ?  (btnApply.down ? "#2093fe" : "#265f97") : "#277eb9"
                        // border.color: "#888"
                        radius: 4
        
                     }                   
                    onClicked: {
                        if ( !rotatePitchesBox.checked && !rotateRhythmBox.checked && !rotateBothBox.checked &&  !reversePitchesBox.checked && !reverseRhythmBox.checked && !reverseBothBox.checked && !invertByPitch.checked && !invertByOutermostPitchesBox.checked){
                            errorDialog.text="Please select an option to perform a transformation."
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
                    palette.buttonText: "white"
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 25
                        color: btnClose.hovered ?  (btnClose.down ? "#717171" : "#565656") : "#646464"
                        // border.color: "#888"
                        radius: 4
        
                     }                  
                    onClicked: {
                        //window.close();
                        quit()
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
                sequence: StandardKey.Quit//"Escape"
                enabled: true
                context: Qt.WindowShortcut//Qt.ApplicationShortcut
                onActivated: quit()
                
            } 
            
        }//mouse area
        
    }//end window
}//end ms
