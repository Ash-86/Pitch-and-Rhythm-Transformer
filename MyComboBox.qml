import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
ComboBox {               
    id: ctrl
    width: (mscoreMajorVersion >= 4)?40:undefined    
    height: parent.height
    //Layout.preferredHeight: parent.height
    currentIndex: 0    
    font.pointSize: 10     
    font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI" ////
    hoverEnabled: true
    // opacity: hovered ? 0.8:1         
    
    contentItem: Text {
        text: ctrl.displayText
        anchors.verticalCenter: parent.verticalCenter
        color: (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
        verticalAlignment: Text.AlignVCenter
        leftPadding: 5
        rightPadding: 10 + ctrl.indicator.width + ctrl.spacing
    }

    indicator: Canvas {
        x: ctrl.width - width - ctrl.rightPadding
        y: ctrl.topPadding + (ctrl.availableHeight - height) / 2
        width: 8
        height: 5
        contextType: "2d"

        onPaint: {
            context.reset();
            context.moveTo(0, 0);
            context.lineTo(width, 0);
            context.lineTo(width / 2, height);
            context.closePath();
            context.fillStyle = (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white";
            context.fill();
        }
    }
    background: Rectangle {
        color:(mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#242427"
        opacity: hovered ? 0.8:1  
        ////border.width: parent && parent.activeFocus ? 2 : 1
        border.color: (mscoreMajorVersion >= 4)? hovered? ui.theme.accentColor : ui.theme.strokeColor : "grey"
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