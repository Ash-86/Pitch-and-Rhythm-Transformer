import QtQuick 2.9
import QtQuick.Controls 2.2
Item{
    id: item
    property var modeFamily:0
    property var mockValue:0
    property var modeNumber:[null,null]
    
    Button {
        id: toolButton
        rightPadding: 40
                                    
        text: "Select Mode"
        hoverEnabled: true
        highlighted: hovered
        onClicked: mainMenu.open()

        contentItem: Text {
            text: toolButton.text
            font: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
            color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }             
            
        background: Rectangle {
            width: parent.width
            height: parent.height
            color: (mscoreMajorVersion >= 4)? ui.theme.buttonColor : "#646464"
            opacity: toolButton.hovered ?  (toolButton.down ? 1 : 0.5) : 0.75
            // border.color: "#888"
            radius: 4
        }    

        indicator: Canvas {
            x: toolButton.width - width   -10                                                      
            y:toolButton.topPadding + (toolButton.availableHeight - height) / 2
            width: 8
            height: 5
            contextType: "2d"

            onPaint: {
                context.reset();
                context.moveTo(0, 0);
                context.lineTo(width, 0);
                context.lineTo(width / 2, height);
                context.closePath();
                context.fillStyle = "white";
                context.fill();
            }
        }
    }

    Menu {    
        id: mainMenu       
        width: 200
        x: toolButton.x
        // property var modeFamily:0
        // property var mockValue:0
        // property var modeNumber:[null,null]
        Button {
            id: majorModesBtn
            
            hoverEnabled: true
            highlighted: item.modeFamily=="major"            
            onHoveredChanged: hovered?  item.modeFamily="major": item.mockValue=0
            Text {
                text: "Major Modes"                   
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10
            } 
                        
        }

        Button {
            id: melodicModesBtn
            
            hoverEnabled: true
            highlighted: item.modeFamily=="melodic"
            onHoveredChanged: hovered?  item.modeFamily="melodic": item.mockValue=0
            Text {
                text: "Melodic Minor Modes"                  
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10
            }              
        }

        Button {  
            id: harmonicModesBtn         
            
            hoverEnabled: true
            highlighted: item.modeFamily=="harmonic" 
            onHoveredChanged: hovered?  item.modeFamily="harmonic": item.mockValue=0
            Text {
                text: "Harmonic Minor Modes"                 
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10
            }                
        }        
        Button {       
            id: otherModesBtn    
            
            hoverEnabled: true
            highlighted: item.modeFamily=="other" 
            onHoveredChanged: hovered?  item.modeFamily="other": item.mockValue=0
            Text {
                text: "Other"                 
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10
            }                 
        }        
    }
    Menu {
        id: majorModesMenu
        x: mainMenu.x + mainMenu.width
        y: majorModesBtn.y
        //rightPadding: 20
        //width: 180
        
        visible: (mainMenu.visible && item.modeFamily=="major" ) 
        Repeater{                      
            model: majorModes              
            delegate: Button {
                                            
                Text {
                    //anchors.centerIn: parent                   
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 10
                    text: name
                }
                                
                hoverEnabled: true
                highlighted: hovered  
                onClicked: {
                    toolButton.text=name
                    item.modeNumber=[item.modeFamily, index]                         
                    mainMenu.close()
                    console.log(item.modeNumber)               
                }
                
            }
        }       
    }

    Menu {
        id: melodicModesMenu
        x: mainMenu.x + mainMenu.width
        y: melodicModesBtn.y
        //rightPadding: 20
        //width: 180
        
        visible: mainMenu.visible && item.modeFamily=="melodic" 
        Repeater{            
            model: melodicMinorModes             
            delegate: Button {   
                id: button                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 10
                    
                    text: name
                }
                hoverEnabled: true
                highlighted: hovered 
                onClicked: {
                    toolButton.text=name     
                    item.modeNumber=[item.modeFamily, index]                    
                    mainMenu.close()
                    
                    console.log(item.modeNumber)                                   
                }                
            }
        }       
    }    
                        
    Menu {
        id: harmonicModesMenu
        x: mainMenu.x + mainMenu.width
        y: harmonicModesBtn.y
        //rightPadding: 20
        //width: 180
        
        visible: mainMenu.visible && item.modeFamily=="harmonic" 
        Repeater{            
            model: harmonicMinorModes             
            delegate: Button {   
                id: button                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 10                    
                    text: name
                }
                hoverEnabled: true
                highlighted: hovered 
                onClicked: {
                    toolButton.text=name 
                    item.modeNumber=[item.modeFamily, index]                        
                    mainMenu.close()
                    console.log(item.modeNumber)                                   
                }                
            }
        }       
    }                                                  
    Menu {
        id: otherModesMenu
        x: mainMenu.x + mainMenu.width
        y: otherModesBtn.y
        //rightPadding: 20
        //width: 180
        
        visible: mainMenu.visible && item.modeFamily=="other" 
        Repeater{            
            model: otherModes             
            delegate: Button {   
                id: button                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 10                    
                    text: name
                }
                hoverEnabled: true
                highlighted: hovered 
                onClicked: {
                    toolButton.text=name 
                    item.modeNumber=[name, 0]                        
                    mainMenu.close()
                    console.log(item.modeNumber)                                   
                }                
            }
        }       
    }             

    ListModel {            
        id:  majorModes    
                                    
        ListElement {name: "Ionian" }
        ListElement {name: "Dorian" }
        ListElement {name: "Phrygian"} 
        ListElement {name: "Lydian"} 
        ListElement {name: "Mixolydian"} 
        ListElement {name: "Eolian"} 
        ListElement {name: "Locrian"} 
                                    
    } 
    ListModel{                           
        id: melodicMinorModes          
                            
        ListElement {name: "Melodic Minor" }
        ListElement {name: "Dorian♭2  (Phrygian ♯6)" }
        ListElement {name: "Lydian augmented"}
        ListElement {name: "Lydian♭7"} 
        ListElement {name: "Mixolydian♭6"} 
        ListElement {name: "Locrian ♯2 (Aeolian♭5)"} 
        ListElement {name: "Altered scale"} 
    }
                    
    ListModel { 
        id: harmonicMinorModes

        ListElement {name: "Harmonic Minor" }
        ListElement {name: "Locrian ♮6" }
        ListElement {name: "Ionian ♯5" }
        ListElement {name: "Dorian ♯4" }
        ListElement {name: "Mixolydian ♭9" }
        ListElement {name: "Lydian ♯2" }
        ListElement {name: "Altered scale ♭♭7" }
    }     
        
    ListModel { 
            id: otherModes

            ListElement {name: "Harmonic Manjor" }
            ListElement {name: "Half-Whole" }
            ListElement {name: "Major Pentatonic" }
            ListElement {name: "Harmonic Major" }
            ListElement {name: "Harmonic Major" }
    }
}