
import QtQuick 2.9
import QtQuick.Controls 2.2

Rectangle {
    id: root
    property var value: 1
    property var bypassZero: false
    property var from: -99
    property var to: 99
    property var step: 1
    function increase(){
        if( root.value<root.to){
            root.value=root.value + root.step
            if(root.bypassZero && root.value==0 ){
                root.value+=1
            }
        }
    }
    function decrease(){
        if( root.value>root.from){
            root.value=root.value - root.step
            if(root.bypassZero && root.value==0 ){
                root.value-=1
            }
        }
    }


    width: 50
    height: parent.height

    color:(mscoreMajorVersion >= 4)? ui.theme.textFieldColor : "#242427"
    border.color: (mscoreMajorVersion >= 4)? mouseArea.containsMouse? ui.theme.accentColor : ui.theme.strokeColor : "grey"

    radius: 4
    MouseArea {
        id: mouseArea
        anchors.fill: root
        hoverEnabled: true
    }

    //opacity: containsMouse ? 0.5:1
    /*ToolTip.visible: hovered
    ToolTip.delay: 500
    ToolTip.text: qsTr("8va")

    ToolTip.timeout: 1000   */

    Text{
        anchors{
            right: parent.right
            rightMargin: parent.width*0.5
            verticalCenter: parent.verticalCenter
        }
        font.family: (mscoreMajorVersion >= 4)? ui.theme.bodyFont.family : "segoe UI"
        color:(mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white"
        text: root.value
    }
    Button{
        height: parent.height/2
        width: parent.width*0.4
        hoverEnabled: true
        highlighted: hovered
        anchors{
            right: parent.right
            top: parent.top
        }


        Timer {
            id: uptimer
            interval: 100
            repeat: true
            onTriggered: function () {
                root.increase()
            }
        }
        onClicked: root.increase()
        onPressAndHold: uptimer.start()
        onReleased: uptimer.stop()





        background: Rectangle {
            color:(mscoreMajorVersion >= 4)? ui.theme.buttonColor : "grey"
            opacity: parent.hovered? parent.down ? 0.75:0.5:0
            radius: 1
        }

        Canvas {
            anchors.fill: parent
            contextType: "2d"
            onPaint: {
                context.reset();
                context.moveTo(width / 2, height/3);
                context.lineTo(width/3, height*2/3);
                context.lineTo(width*2/3, height*2/3);
                context.closePath();
                context.fillStyle = (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white";
                context.fill();
            }
        }
    }
    Button {
        height: parent.height/2
        width: parent.width*0.4
        hoverEnabled: true
        highlighted: hovered
        anchors{
            right: parent.right
            bottom: parent.bottom
        }
        Timer {
            id: downTimer
            interval: 100
            repeat: true
            onTriggered: function() {
                root.decrease()
            }
        }
        onClicked: root.decrease()
        onPressAndHold: downTimer.start()
        onReleased: downTimer.stop()

        background: Rectangle {
            color:(mscoreMajorVersion >= 4)? ui.theme.buttonColor : "grey"
            opacity: parent.hovered? parent.down ? 0.75:0.5:0
            radius: 1
        }

        Canvas {
            anchors.fill: parent
            contextType: "2d"
            onPaint: {
                context.reset();
                context.moveTo(width/3, height/3);
                context.lineTo(width*2/3, height/3);
                context.lineTo(width / 2, height*2/3);
                context.closePath();
                context.fillStyle = (mscoreMajorVersion >= 4)? ui.theme.fontPrimaryColor : "white";
                context.fill();
            }
        }
    }
}
