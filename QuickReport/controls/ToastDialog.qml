import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

import "../controls" as Controls

Pane {
    id: root

    property int defaultMargin: units(16)
    property color textColor: "#FFFFFF"
    property int intervalTime: 2000
    property int durationTime: 200
    property bool enableBottomPadding: false

    Material.background: "#323232"

    padding: 0
    width: Math.min(parent.width, 600 * scaleFactor)
    height: app.isIPhoneX?message.lineCount * units(56) + units(16):message.lineCount * units(56)
    visible: false
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter

    Behavior on height {
        NumberAnimation { duration: durationTime }
    }

    BaseText {
        id: message

        anchors.fill: parent
        padding: defaultMargin
        color: textColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Timer {
        id: timer

        interval: intervalTime
        running: false
        repeat: false

        onTriggered: {
            close()
        }
    }

    onVisibleChanged: {
        if (!visible) {
            message.text = ""
        }
    }

    Timer {
        id: hide

        repeat: false
        running: false
        interval: 4000//transitionAnimation.duration + 1
        onTriggered: {
            toastMessage.state = "default";
            visible = false
        }
    }

    states: [
        State {
            name: "default"
            PropertyChanges { target: toastMessage; height: 0 }
        },
        State {
            name: "displayToast"
            PropertyChanges { target: toastMessage; height: (58 * scaleFactor + (enableBottomPadding ? 28 * scaleFactor : 0))}
        }
    ]

    function open (pos, duration) {
        visible = true
        timer.interval = duration ? duration : 2000
        if (!pos) pos = parent.height - root.height
        toastMessage.state = "displayToast"
        //   y = pos
    }

    function close (pos) {
        if (!pos) pos = parent.height
        toastMessage.state = "default"
        // y = pos
        hide.start()
    }

    function show (text, pos, duration) {
        message.text = text
        root.open(pos, duration)
        timer.start()
    }

    function hide () {
        close()
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }
}
