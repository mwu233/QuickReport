import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

Label{
    id: toast
    width: implicitWidth * 1.2
    height: 40*AppFramework.displayScaleFactor
    color: "white"
    verticalAlignment: Label.AlignVCenter
    horizontalAlignment: Label.AlignHCenter
    font.family: app.fontFamily.name
    font.pixelSize: app.captionFontSize
    visible: opacity!==0
    opacity: 0
    padding: 8*AppFramework.displayScaleFactor
    leftPadding: rightPadding
    rightPadding: 16*AppFramework.displayScaleFactor

    property real duration: 1000
    property color backgroundColor: "#616161"

    background: Rectangle{
        anchors.fill: parent
        radius: height/2
        color: toast.backgroundColor
        opacity: 0.5
    }

    function show(text, duration){
        toast.text = text;
        toast.duration = duration;
        showAnimation.stop();
        opacity = 0;
        showAnimation.restart();
    }

    SequentialAnimation {
        id: showAnimation

        NumberAnimation {
            target: toast
            property: "opacity"
            duration: toast.duration*0.1
            from: 0
            to: 1
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: toast
            property: "opacity"
            duration: toast.duration*0.6
            from: 1
            to: 1
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: toast
            property: "opacity"
            duration: toast.duration*0.3
            from: 1
            to: 0
            easing.type: Easing.InOutQuad
        }
    }
}
