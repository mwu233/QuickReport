import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Switch {
    id: control

    indicator: Rectangle {
        id: switchBackground
        implicitWidth: 32 * AppFramework.displayScaleFactor
        implicitHeight: 10 * AppFramework.displayScaleFactor
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 13

        Component.onCompleted: {
            switchBackground.color = control.checked ? app.headerBackgroundColor : "#212121";
        }

        RoundButton {
            x: control.checked ? parent.width - width : 0
            y: (parent.implicitHeight - height)/2
            width: 20 * AppFramework.displayScaleFactor
            height: 20 * AppFramework.displayScaleFactor

            background: Rectangle{
                anchors.fill: parent
                color: "white"
                radius: parent.width/2
            }

            enabled: false

            Behavior on x {
                NumberAnimation {
                    duration: 80
                    onRunningChanged: {
                        if(!running)switchBackground.color = control.checked ? app.headerBackgroundColor : "212121";
                    }
                }
            }

            Material.elevation: 10

            indicator: Item {
                anchors.fill: parent
                Image {
                    id: smartIcon
                    width: parent.height * 0.6
                    height: parent.height  * 0.6
                    anchors.centerIn: parent
                    source: "./images/auto-fix.png"
                    fillMode: Image.PreserveAspectFit
                    clip: true
                    mipmap: true
                }
                ColorOverlay {
                    visible: control.visible
                    anchors.fill: smartIcon
                    source: smartIcon
                    color: app.headerBackgroundColor
                    smooth: true
                    antialiasing: true
                }
            }
        }
    }

    onCheckedChanged: {
        canvas.smartMode = checked;
    }
}
