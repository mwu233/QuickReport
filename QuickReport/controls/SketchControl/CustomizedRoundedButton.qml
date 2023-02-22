import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

RoundButton {
    id: roundedButton

    property bool chosen: false
    property url imageSource: ""
    property color overlayColor: "#3F51B5"
    property alias imageScale: roundedButtonImage.scale

    background: Rectangle{
        anchors.fill: parent
        color: chosen ? "#808080": "#424242"
        radius: parent.width/2
    }

    indicator: Image {
        id: roundedButtonImage
        width: parent.height * 0.6
        height: parent.height  * 0.6
        anchors.centerIn: parent
        source: imageSource
        fillMode: Image.PreserveAspectFit
        clip: true
        scale: 1.0
        mipmap: true
        opacity: roundedButton.enabled? 1.0 : 0.6
    }
}
