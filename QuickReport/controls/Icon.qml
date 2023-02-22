import QtQuick 2.7
import QtQuick.Layouts 1.1
import ArcGIS.AppFramework 1.0
import QtGraphicalEffects 1.0

Rectangle {

    id: root

    function units(num) {
        return num*AppFramework.displayScaleFactor
    }

    property bool isDebug: false
    property int imageSize: units(24)
    property int containerSize: units(48)
    property int sidePadding: 0
    property url imageSource: ""
    property color backgroundColor: "transparent"
    property color iconOverlayColor: "white"
    property alias iconText: iconText
    property int bubbleCount: 0
    property bool showBubble: bubbleCount > 0
    property color bubbleColor: "red"
    property bool enabled: true
    signal iconClicked()

    width: containerSize + sidePadding
    height: containerSize
    Layout.preferredWidth: containerSize
    Layout.preferredHeight: containerSize
    color: backgroundColor
    radius: units(4)

    border.width: isDebug

    Image {
        id: iconImg
        width: imageSize
        height: imageSize
        anchors.centerIn: parent
        source: imageSource
        asynchronous: true
        smooth: true
        mipmap: true
        fillMode: Image.PreserveAspectCrop

        Rectangle {
            anchors.fill: parent
            visible: isDebug
            color: "transparent"
            opacity: 0.5
            border.width: isDebug
            border.color: "green"
        }
    }

    ColorOverlay{
        anchors.fill: iconImg
        source: iconImg
        color: iconOverlayColor
    }

    Rectangle {
        id: bubble
        x: parent.width-width/2
        y: 0-width/2
        width: Math.max(countText.contentWidth, units(24))
        height: units(24)
        radius: height/2
        color: bubbleColor
        z: parent.z + 1
        visible: showBubble

        Text {
            id: countText
            width: parent.width
            height: parent.height
            maximumLineCount: 1
            font.pixelSize: parent.height * 0.5
            font.bold: true
            font.weight: Font.Bold
            fontSizeMode: Text.HorizontalFit
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: bubbleCount
            color: "white"
        }
    }

    DropShadow {
        source: bubble
        anchors.fill: source
        width: source.width
        height: source.height
        cached: false
        radius: 6.0
        samples: 16
        color: "#80000000"
        smooth: true
        visible: source.visible
    }

    Text {
        id: iconText
        anchors.top: iconImg.bottom
        anchors.topMargin: units(24)
        horizontalAlignment: Text.AlignHCenter
        width: parent.width
        wrapMode: Text.Wrap
        maximumLineCount: 2        
        text: ""
        visible: text > ""

        Rectangle {
            anchors.fill: parent
            visible: isDebug
            color: "transparent"
            opacity: 0.5
            border.width: isDebug
            border.color: "pink"
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: {
            iconClicked();
        }
    }

}
