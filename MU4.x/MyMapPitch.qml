import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Muse.UiComponents 1.0 

Item {  
    id:root 
    
    property var allOct: allOctaves.checked
    property var noteIn: noteBoxFrom.currentValue;
    property var accIn: accidentalBoxFrom.currentValue;
    property var octIn: octaveBoxFrom.currentValue
    property var enharm: enharmonic.checked
    property var noteOut: noteBoxTo.currentValue;
    property var accOut:accidentalBoxTo.currentValue;
    property var octOut: octaveBoxTo.currentValue 
    property var down: downBtn.checked                         
    property var up:  upBtn.checked                      
    property var filter: mapPitchSwitch.checked 

     
    Column {
        id: pitchMapBoxes    
        spacing: 15    
        RowLayout {                         
            StyledTextLabel { 
                anchors.verticalCenter: parent.verticalCenter
                text: "Map Pitch"                
            }
            ToggleButton {
                id: mapPitchSwitch                
                onToggled: checked = !checked
            }
            StyledTextLabel { 
                anchors.verticalCenter: parent.verticalCenter
                text: "Filter/Select Pitch"                
            }  
        }
        Row { 
            id: mapFromRow  
            spacing: 2
            height: 25
            StyledDropdown {               
                id: noteBoxFrom  
                width: 50                          
                currentIndex: 0 
                model:  ["C", "D", "E", "F", "G", "A", "B" ]  
                onActivated: function(index, value) {currentIndex = index}      
            }
            StyledDropdown {               
                id: accidentalBoxFrom 
                width: 50                           
                currentIndex: 1                                    
                model: ["♭", "♮", "♯" ]     
                onActivated: function(index, value) {currentIndex = index}                           
            }
            IncrementalPropertyControl {
                id: octaveBoxFrom
                enabled: !allOctaves.checked
                width: 50
                step: 1
                minValue: 0
                maxValue: 9                    
                currentValue: 4
                onValueEdited: function(newValue) {currentValue = newValue}                                           
            } 
            FlatButton {
                id: allOctaves
                text: "All Octaves"
                isNarrow: true
                onClicked: accentButton = !accentButton
                property var checked: accentButton 
            }
            FlatButton {
                id: enharmonic  
                //isNarrow: true              
                text: "Enharmonic notes"
                onClicked: accentButton = !accentButton
                property var checked: accentButton 
            } 
            
        }//Row
    }//COlumn
             
    Column {
        id: pitchMapBoxes2
        visible: mapPitchSwitch.checked==0 //!filterOptions.checked
        spacing: 15
        anchors {
            top: pitchMapBoxes.bottom
            left: pitchMapBoxes.left
            topMargin:15
        }
        
        StyledTextLabel {              
            text: "To:"
        }
            
        Row {
        spacing: 2
            StyledDropdown {               
                id: noteBoxTo                    
                width: 50        
                currentIndex: 0                                   
                model:  ["C", "D", "E", "F", "G", "A", "B" ]  
                onActivated: function(index, value) {currentIndex = index}                          
            }
            StyledDropdown {               
                id: accidentalBoxTo
                width: 50
                currentIndex: 1                                    
                model: ["♭", "♮", "♯" ]     
                onActivated: function(index, value) {currentIndex = index}                         
            }
            IncrementalPropertyControl {
                id: octaveBoxTo
                enabled:  !upBtn.checked && !downBtn.checked
                width: 50
                step: 1
                minValue: 0
                maxValue: 9                    
                currentValue: 4
                onValueEdited: function(newValue) {currentValue = newValue}    
            }         
            FlatButton {
                id: upBtn
                width: 50
                property var checked: accentButton 
                onClicked: {
                    accentButton = !accentButton
                    downBtn.accentButton = false
                }
                text: "Up"
            }
            FlatButton {
                id: downBtn
                width: 50
                property var checked: accentButton 
                onClicked: { 
                    accentButton = !accentButton
                    upBtn.accentButton = false  
                }
                text: "Down"            
            }  
        }//row 
    }//column 
}                

 
