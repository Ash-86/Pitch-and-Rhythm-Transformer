import QtQuick 2.9
import QtQuick.Controls 2.2

 RadioButton {
    //color: sysActivePalette.text
    id: btn                
    
    
    font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI"
    font.pointSize: 10
    
    hoverEnabled: true
    
    contentItem: Text {
        text: btn.text
        font: btn.font
        opacity: btn.hovered ? 0.8:1
        color:  (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
        verticalAlignment: Text.AlignVCenter
        leftPadding:btn.indicator.width + btn.spacing
    }
        
    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        //x: rotatePitchesBox.leftPadding
        anchors.verticalCenter: parent.verticalCenter
        radius: 9
        color: (mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#242427"
        border.color: "#c0c0c0"

        Rectangle {
            width: 10
            height: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            
            radius: 5
            color: (mscoreMajorVersion >= 4)? ui.theme.accentColor : "#2093fe"             
            visible: btn.checked
        }                       
    }
}

          
      
