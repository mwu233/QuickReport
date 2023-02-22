import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Item {
    id: root

    anchors.centerIn: parent

    property alias source: image.source
    property alias indicatorColor: imageColorOverLay.color
    property alias indicatorOpacity: imageColorOverLay.opacity
    property alias status: image.status

    property bool isShowBorder: false

    Image {
        id: image

        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        mipmap: true
        asynchronous: true
        cache: false

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: isShowBorder ? 1 * constants.scaleFactor : 0
            border.color: "grey"
        }
    }

    ColorOverlay {
        id: imageColorOverLay

        anchors.fill: image
        source: image
    }
}
