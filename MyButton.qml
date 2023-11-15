import QtQuick 2.2
import QtQuick.Controls 2.2

Button {                    
    id:  ctrl
    property var accented: false
    checkable: false
    hoverEnabled: true
    highlighted: clicked    
    contentItem: Text {
        text: ctrl.text
        font: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" 
        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }                    
    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 25
        //color: (mscoreMajorVersion >= 4)? (accented? ui.theme.accentColor : ui.theme.buttonColor) : "#646464"
        opacity: ctrl.hovered ?  (ctrl.down ? 1 : 0.5) : 0.75        
        radius: 4
        color:{
            if (checkable){
                if(mscoreMajorVersion >= 4){
                    if(ctrl.checked){ ui.theme.accentColor}
                    else{ ui.theme.buttonColor}
                }
                else{
                    if(ctrl.checked){"#277eb9"}
                    else {"#646464"}
                }
            }
            else{
                if (mscoreMajorVersion >= 4){
                    if (accented){
                        ui.theme.accentColor
                    }
                    else{ 
                        ui.theme.buttonColor
                    }
                } 
                else{
                    "#646464"  
                }
            }
        }
    }
}        