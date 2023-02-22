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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import QtMultimedia 5.2
import Qt.labs.folderlistmodel 2.1

import ArcGIS.AppFramework 1.0

import Esri.ArcGISRuntime 100.10

import "../controls"

Rectangle {
    width: parent.width
    height: parent.height
    color: app.pageBackgroundColor
    signal next(string message)
    signal previous(string message)

    property bool isBusy: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: createPage_headerBar
            Layout.alignment: Qt.AlignTop
            //Layout.fillHeight: true
            color: app.headerBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50 * app.scaleFactor

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    mouse.accepted = false
                }
            }

            ImageButton {
                source: "../images/ic_keyboard_arrow_left_white_48dp.png"
                height: 30 * app.scaleFactor
                width: 30 * app.scaleFactor
                checkedColor : "transparent"
                pressedColor : "transparent"
                hoverColor : "transparent"
                glowColor : "transparent"
                anchors.rightMargin: 10
                anchors.leftMargin: 10
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    console.log("Back button from create page clicked")
                    previous("")
                }
            }

            Text {
                id: createPage_titleText
                text: "Select Iss"
                textFormat: Text.StyledText
                anchors.centerIn: parent
                font {
                    pixelSize: app.textFontSize
                    family: app.customTextFont.name
                }
                color: app.headerTextColor
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.fillHeight: true
            //color: app.pageBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: parent.height - createPage_headerBar.height

            BusyIndicator {
                visible: isBusy
                anchors.centerIn: parent

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        isBusy = false
                        next("");
                    }
                }
            }


            Text {
                text: "Thank you for submitting a report."
            }

            CustomButton{
                id:page4_button1
                buttonText: qsTr("Submit")
                buttonColor: app.buttonColor
                buttonWidth: 300 * app.scaleFactor
                buttonHeight: buttonWidth/5
                anchors {
                    left: parent.left
                    right: parent.right
                    //top: previewImage.bottom
                    topMargin: 30*app.scaleFactor
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        isBusy = true
                    }
                }

            }
        }
    }
}
