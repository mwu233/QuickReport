import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../controls"


Item {

    property alias color: imageColorOverLay.color

    Image {
        id: image
        source:"../images/appstudio.png"
        anchors.fill: parent
        mipmap: true
        asynchronous: true
    }

    ColorOverlay {
        id: imageColorOverLay

        anchors.fill: image
        source: image
    }
}

