import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

ToolButton {
    property url imageSource: ""
    property real imageScale: 0.5
    indicator: Image{
        width: parent.width*imageScale
        height: parent.height*imageScale
        anchors.centerIn: parent
        opacity: enabled? 1:0.4
        source: imageSource
        fillMode: Image.PreserveAspectFit
        mipmap: true
    }
}
