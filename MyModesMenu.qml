import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

Item{
    height: parent.height
    id: item
    property var modeFamily:0
    property var mockValue:0    
    property var modeNumber:[null,null]
    //Layout.preferredHeight: parent.height  

    Button {
        id: toolButton
        rightPadding: 30        
                                
        text: "Select Mode"
        hoverEnabled: true
        highlighted: hovered
        onClicked: mainMenu.open()

        contentItem: Text {
            text: toolButton.text
            font: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
            color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"            
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 5
            elide: Text.ElideRight
        }             
            
        background: Rectangle {
            width: parent.width
            height: parent.height
            color: (mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#646464"
            opacity: toolButton.hovered ?  (toolButton.down ? 1 : 0.5) : 0.75
            //border.color: (mscoreMajorVersion >= 4)? hovered? ui.theme.accentColor : ui.theme.strokeColor : "grey"                    
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
                context.fillStyle = (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "#646464"
                context.fill();
            }
        }
    }
    Rectangle{
           id: rect
            x: toolButton.x 
            y: toolButton.y 
            width:200
            height: 200
            visible: false
            MouseArea{
                anchors.fill:parent
                hoverEnabled: true
                onHoveredChanged: containsMouse? item.mockValue2=1 : item.mockValue2=0
            }
    }

    // component MyButton:
    //     Button {
    //         id: btn
    //         height: toolButton.height                         
    //         hoverEnabled: true 
    //         highlighted: hovered  
    //         //text: ""
    //         Text {                                      
    //             anchors.verticalCenter: parent.verticalCenter
    //             leftPadding: 5
    //             elide: Text.ElideRight
    //             text: name 
    //             font: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
    //             color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white" 
    //         }
    //         background: Rectangle {                       
    //             anchors.fill: parent
    //             color: (mscoreMajorVersion >= 4)? ui.theme.buttonColor : "#646464"
    //             opacity: hovered ?  (down ? 1 : 0) : 0.5                     
    //         }  
    //     } 
    
    Menu {    
        id: mainMenu              
        x: toolButton.x 
        y: toolButton.y + toolButton.height             
        width: 130 
        background: Rectangle{
            anchors.fill: parent 
            color: (mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#646464"           
            radius: 4            
        }
        Repeater{
            model:modes
            MenuItem{
                text: model.name                
                onHoveredChanged: hovered?  item.modeFamily=text :item.mockValue=0                
            }
        } 
    }
    
    Menu {
        id: majorModesMenu
        x: mainMenu.x + mainMenu.width    
        y: toolButton.y - toolButton.height     
        margins: -1  
        implicitWidth: 60       
        background: Rectangle{
            anchors.fill: parent
            color: (mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#646464"            
            radius: 4            
        }
        visible: mainMenu.visible   && item.modeFamily=="Major Modes"  
        Repeater{                      
            model: majorModes              
            MenuItem{
                text: model.name   
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
        y: toolButton.y - toolButton.height 
        implicitWidth: 110  
        margins: -1
        visible: mainMenu.visible && item.modeFamily=="Melodic Minor Modes" 

        background: Rectangle{
            anchors.fill: parent
            color: (mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#646464"
            radius: 4
        }
        Repeater{            
            model: melodicMinorModes             
            MenuItem{
                text: model.name                         
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
        y: toolButton.y  - toolButton.height 
        margins: -1 
        width: 100       
        visible: mainMenu.visible && item.modeFamily=="Harmonic Minor Modes" 

        background: Rectangle{
            anchors.fill: parent
            color: (mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#646464"
            radius: 4            
        }
        Repeater{            
            model: harmonicMinorModes             
            MenuItem{
                text: model.name                 
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
        y: toolButton.y  - toolButton.height 
        margins: -1
        implicitWidth: 90 
        visible: mainMenu.visible && item.modeFamily=="Other" 

        background: Rectangle{
            anchors.fill: parent
            color: (mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#646464"
            radius: 4            
        }
        Repeater{            
            model: otherModes             
            MenuItem{
                text: model.name 
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
        id:  modes    
                                    
        ListElement {name: "Major Modes" }
        ListElement {name: "Melodic Minor Modes" }
        ListElement {name: "Harmonic Minor Modes"} 
        ListElement {name: "Other"} 
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

            ListElement {name: "Harmonic Major" }
            ListElement {name: "Double Harmonic" }
            ListElement {name: "Half-Whole" }
            ListElement {name: "Whole-Half" }
            ListElement {name: "Whole Tone" }
            ListElement {name: "Major Pentatonic" }
            ListElement {name: "Minor Pentatonic" }            
    }
}