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


Rectangle {
    id: defaultDialog

    property var acceptedCallback
    property var rejectedCallback
    property var yesCallback;
    property var noCallback;
    property var localeForRTL:["ar", "he", "he-IL"]

    property url standardIconSource
    property string text: qsTr("Are you sure you want to discard?")
    property string informativeText: ""
    property string detailedText: ""
    property int isShowDetail: 0
    property string type: ""

    signal accepted()
    signal rejected()
    signal clickOK()

    property int standardButtons: StandardButton.Yes + StandardButton.No//StandardButton.Ok//StandardButton.None
    property AppInfo appInfo

    anchors.fill: parent
    color: "#80000000"
    visible: false



    MouseArea {
        anchors.fill: parent
        onPressAndHold: {

        }
    }

    Rectangle {
        id: content
        color:app.pageBackgroundColor
        radius: 3*app.scaleFactor
        implicitHeight: columnContent.height + 22*AppFramework.displayScaleFactor
        implicitWidth: Math.min(500*AppFramework.displayScaleFactor, app.width*0.8)
        width: implicitWidth
        height: implicitHeight
        clip: true
        anchors.centerIn: parent

        Column{
            id: columnContent
            width: parent.width - 12*AppFramework.displayScaleFactor*2
            height: iconWithText.height + buttons.height
            spacing: 6*AppFramework.displayScaleFactor

            anchors{
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 12*AppFramework.displayScaleFactor

            }

            Rectangle{
                id: iconWithText
                width: parent.width
                height: Math.max(icon.height, mainText.height + infoText.height + 6*AppFramework.displayScaleFactor)
                color: "transparent"

                Image {
                    id: icon
                    width: 0
                    height: 24*AppFramework.displayScaleFactor
                    source: defaultDialog.standardIconSource
                }

                Text {
                    id: mainText
                    width: parent.width-icon.width
                    anchors {
                        left: icon.right
                        leftMargin: 6*AppFramework.displayScaleFactor
                    }
                    font.family: app.customTextFont.name
                    text: defaultDialog.text
                    color: app.textColor
                    font.weight: Font.Bold
                    font.pixelSize: app.textFontSize
                    wrapMode: Text.Wrap
                }

                Text {
                    id: infoText
                    anchors {
                        left: icon.right
                        top: mainText.bottom
                        leftMargin: 6*AppFramework.displayScaleFactor
                        topMargin: 6*AppFramework.displayScaleFactor
                    }
                    font.family: app.customTextFont.name
                    width: parent.width-icon.width
                    text: defaultDialog.informativeText
                    color: app.textColor
                    font.pixelSize: app.subtitleFontSize
                    wrapMode: Text.Wrap
                    height:defaultDialog.informativeText?implicitHeight:0

                }
            }


            Row {
                id: buttons
                spacing: 6*AppFramework.displayScaleFactor
                layoutDirection: Qt.RightToLeft
                width: parent.width
                clip: true

                Button {
                    id: okButton
                    text: qsTr("OK")

                    background: Rectangle{
                        radius: 2*AppFramework.displayScaleFactor
                        width: parent.width
                        height: parent.height
                        clip: true
                        color:app.pageBackgroundColor
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
                    width: 80*AppFramework.displayScaleFactor

                    onClicked: {
                        clickOK();
                        defaultDialog.visible = false
                    }
                    visible: (defaultDialog.standardButtons & StandardButton.Ok)>0
                }


                Button {
                    id: yesButton
                    text: qsTr("Yes")

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
                        text: qsTr("Yes")
                        clip: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    width: 80*AppFramework.displayScaleFactor
                    onClicked:{
                        accepted()
                        defaultDialog.visible = false
                    }
                    visible: (defaultDialog.standardButtons & StandardButton.Yes)>0
                    Component.onCompleted: {
                       if (Qt.platform.os === "ios")
                       {
                           topPadding = 10 * scaleFactor
                           bottomPadding = 10 * scaleFactor
                       }
                    }
                }
                Button {
                    id: noButton
                    text: qsTr("No")

                    background: Rectangle{
                        radius: 2*AppFramework.displayScaleFactor
                        width: parent.width
                        height: parent.height
                        clip: true
                        color: app.pageBackgroundColor
                        border.width: 1
                        border.color: app.isDarkMode? "white": "#888"
                    }
                    contentItem: Text {
                        color: app.isDarkMode? "white": "black"
                        text: qsTr("No")
                        clip: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }


                    width: 80*AppFramework.displayScaleFactor
                    onClicked: {
                        rejected()
                        defaultDialog.visible = false
                    }
                    visible: (defaultDialog.standardButtons & StandardButton.No)>0

                    Component.onCompleted: {
                       if (Qt.platform.os === "ios")
                       {
                           topPadding = 10 * scaleFactor
                           bottomPadding = 10 * scaleFactor
                       }
                    }
                }
            }


        }

    }



    Component.onCompleted: {
        var title = ""
        var onYes = function(){};
        var onNo = function(){};

        defaultDialog.type = "confirm"
        yesCallback = onYes;
        noCallback = onNo;

        defaultDialog.standardIconSource = ""

        if (text) {
            defaultDialog.text = text;
        } else {
            defaultDialog.text = "";
        }
    }

}
