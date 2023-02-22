import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

TabButton {
    id: tabButton

    property bool highlighted: checked
    property url imageSource: ""
    property color overlayColor: "#3F51B5"

    indicator: Item{
        anchors.fill: parent
        Image {
            id: tabButtonImage
            width: parent.width * 0.6
            height: parent.height  * 0.6
            anchors.centerIn: parent
            source: imageSource
            fillMode: Image.PreserveAspectFit
            mipmap: true
            opacity: tabButton.enabled? 1.0 : 0.6
        }

        ColorOverlay {
            visible: highlighted
            anchors.fill: tabButtonImage
            source: tabButtonImage
            color: overlayColor
            smooth: true
            antialiasing: true
        }
    }
}
