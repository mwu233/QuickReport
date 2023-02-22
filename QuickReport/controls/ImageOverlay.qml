import QtQuick 2.7
import QtGraphicalEffects 1.0

Item{
    property color overlayColor: "white"
    property bool showOverlay: false
    property alias image: root
    property alias source: root.source
    property alias fillMode: root.fillMode
    Image{
        id: root
        anchors.fill: parent
        mipmap: true
        fillMode: Image.PreserveAspectFit
    }

    ColorOverlay{
        anchors.fill: root
        source: root
        color: overlayColor
        visible: showOverlay && root.visible
    }
}


