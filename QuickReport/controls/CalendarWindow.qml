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

import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

import Esri.ArcGISRuntime 100.10

import "../images"
import "../controls"

//Thanks to
//http://doc.qt.digia.com/qtquick-components-symbian-1.1/demos-symbian-musicplayer-qml-filepickerpage-qml.html

Item {
    id: calendarWindow

    width: app.width
    height: app.height

    //z: 88

    property string title: "Date Picker"

    //visible: false

    property date currentDate : new Date()

    signal select(date dateSelected)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: headerBar
            Layout.alignment: Qt.AlignTop
            Layout.fillHeight: true
            color: app.headerBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50 * app.scaleFactor

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    mouse.accepted = false
                }
            }

            Text {
                id: titleText
                text: title
                textFormat: Text.StyledText
                //anchors.centerIn: parent
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                font {
                    pixelSize: app.titleFontSize
                    family: app.customTitleFont.name
                }
                color: app.headerTextColor
                maximumLineCount: 1
                elide: Text.ElideRight
                anchors.leftMargin: 10
            }

            ImageButton {
                source: "../images/ic_keyboard_arrow_left_white_48dp.png"
                rotation: -90
                height: 30 * app.scaleFactor
                width: 30 * app.scaleFactor
                checkedColor : "transparent"
                pressedColor : "transparent"
                hoverColor : "transparent"
                glowColor : "transparent"
                anchors.rightMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    select(currentDate)
                    calendarWindow.visible = false
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.fillHeight: true
            color: app.pageBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: parent.height - headerBar.height

            Calendar {
                anchors.horizontalCenter: parent.horizontalCenter
                selectedDate: new Date()
                onSelectedDateChanged: {
                    currentDate = selectedDate
                    select(currentDate);
                    calendarWindow.visible = false;
                }
            }
        }


    }

}
