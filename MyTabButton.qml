import QtQuick 2.2
import QtQuick.Controls 2.2

TabButton {
    id: ctrl     
    height: parent.height
    hoverEnabled : true
    contentItem: Text {
        text: ctrl.text        
        font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
        font.pointSize: 10
        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
        //opacity: ctrl.checked ? 1 : 0.8
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        implicitWidth: parent.width/4
        implicitHeight: parent.height                        
        color: (mscoreMajorVersion >= 4)? (ctrl.hovered? ui.theme.buttonColor : ui.theme.backgroundPrimaryColor) : "#2d2d30"
        opacity: ctrl.hovered ? (ctrl.down ? 1:0.5) : 0.75
    }    
}