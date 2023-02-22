/* Copyright 2021 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
import QtQuick 2.7
import QtQuick.Dialogs 1.2
import QtQuick.Controls 2.2
import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.10
import QtQuick.Controls.Material 2.1

Rectangle {
    id: defaultDialog

    property var acceptedCallback
    property var rejectedCallback
    property var yesCallback;
    property var noCallback;
    property var localeForRTL:["ar", "he", "he-IL"]

    property url standardIconSource
    property string text: okButton.opacity != 0.0? qsTr("Saved as draft."):qsTr("Saving...")
    property string type: ""

    signal accepted()
    signal rejected()

    property int standardButtons: StandardButton.Yes + StandardButton.No//StandardButton.Ok//StandardButton.None
    property AppInfo appInfo

    anchors.fill: parent
    color: "#80000000"
    visible: false

    onVisibleChanged: {
        if(visible){
            busyIndicator.running = true;
            timer.restart();
        }
    }

    Timer{
        id: timer
        running: false
        repeat: false
        interval: 1000
        onTriggered: {
            animations.start();
        }
    }

    SequentialAnimation{
        id: animations
        running: false
        alwaysRunToEnd: true

        ParallelAnimation{
            NumberAnimation {
                target: busyIndicator
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 200
                easing.type: Easing.InOutQuad
                onStopped: {
                    busyIndicator.running = false
                }
            }

            NumberAnimation {
                target: icon
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 200
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: okButton
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressAndHold: {

        }
    }

    Rectangle {
        id: content
        color: app.pageBackgroundColor
        radius: 3*app.scaleFactor
        implicitHeight: columnContent.height + 34*AppFramework.displayScaleFactor
        implicitWidth: Math.min(400*AppFramework.displayScaleFactor, app.width*0.8)
        width: implicitWidth
        height: implicitHeight
        clip: true
        anchors.centerIn: parent
        Column{
            id: columnContent
            width: parent.width - 12*AppFramework.displayScaleFactor*2
            height: icon.height+mainText.height + okButton.height + columnContent.spacing*2 + 10*AppFramework.displayScaleFactor
            spacing: 6*AppFramework.displayScaleFactor
            anchors{
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 12*AppFramework.displayScaleFactor
            }

            Image{
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter
                width: height
                height: app.isSmallScreen? 100*AppFramework.displayScaleFactor : 120*AppFramework.displayScaleFactor
                opacity: 0.0
                source: "../images/tick.png"
                fillMode: Image.PreserveAspectFit
            }

            Text {
                id: mainText
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: app.customTextFont.name
                text: defaultDialog.text
                color: app.textColor
                font.weight: Font.Bold
                font.pixelSize: app.textFontSize
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
            }

            Item{
                id: emptySpace
                width: parent.width
                height: 10*AppFramework.displayScaleFactor
            }

            Button {
                id: okButton
                text: qsTr("OK")
                width: 80*AppFramework.displayScaleFactor
                background: Rectangle{
                    radius: 2*AppFramework.displayScaleFactor
                    width: parent.width
                    height: parent.height
                    clip: true
                    color: app.pageBackgroundColor
                    border.width: 1
                    border.color: app.isDarkMode? "white": "#888"
                }
                contentItem: Text{
                    color: app.isDarkMode? "white": "black"
                    text: qsTr("OK")
                    clip: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                opacity: 0.0
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: opacity==1.0
                onClicked: {
                    accepted();
                    defaultDialog.visible = false
                    icon.opacity = 0.0;
                    okButton.opacity = 0.0;
                    busyIndicator.opacity = 1.0
                }
            }

        }

        BusyIndicator{
            id: busyIndicator
            width: 40*app.scaleFactor
            height: 40*app.scaleFactor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 62*AppFramework.displayScaleFactor - busyIndicator.height/2
            running: true
            Material.accent:app.headerBackgroundColor
        }

    }

    Component{
        id: buttonCustomSytle

        Rectangle{
                radius: 2*AppFramework.displayScaleFactor
                width: parent.width
                height: parent.height
                clip: true
                color: app.pageBackgroundColor
                border.width: 1
                border.color: app.isDarkMode? "white": "#888"
                Text{
                    color: app.isDarkMode? "white": "black"
                    text: control.text
                    clip: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }




    }

    Component.onCompleted: {
    }

}
