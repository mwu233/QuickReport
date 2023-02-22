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
import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4

import ArcGIS.AppFramework 1.0

import QtQuick.Controls 2.1 as NewControls
import QtQuick.Controls.Material 2.1 as MaterialStyle

import "../widgets"

NewControls.Dialog {
    id: calendarAndTimeDialog

    width: app.width*0.8
    height: Math.min(app.height*0.8, 400)
    x: (app.width - width)/2 - parent.x
    y: (app.height - height)/2 - parent.y
    visible: false
    padding: 0
    topPadding: 0
    bottomPadding: 0
    property int theme: MaterialStyle.Material.Light

    MaterialStyle.Material.theme: theme

    //    standardButtons: NewControls.Dialog.Ok | NewControls.Dialog.Cancel
    modal: true
    closePolicy: NewControls.Dialog.NoAutoClose
    MaterialStyle.Material.accent: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#E0E0E0" : primaryColor

    property bool isMiniMode: calendarAndTimeDialog.height < 399
    property var selectedDateAndTime: { return new Date() }
    property real dateMilliseconds: selectedDateAndTime.valueOf()

    property color primaryColor: "#009688"

    property alias swipeViewIndex: swipeView.currentIndex

    spacing: 0

    header: Rectangle {
        width: parent.width
        height: calendarAndTimeDialog.height/6
        color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? Qt.lighter(app.pageBackgroundColor, 1.2) : primaryColor
        clip: true

        RowLayout{
            anchors.fill: parent
            anchors.margins: 8 * AppFramework.displayScaleFactor
            Item{
                Layout.preferredWidth: parent.width/5*3
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    opacity: swipeView.currentIndex == 0 ? 1 : 0.7
                    clip: true
                    spacing: 0
                    NewControls.Label {
                        Layout.preferredHeight: parent.height/2.5
                        Layout.fillWidth: true

                        text: calendar.selectedDate.toLocaleDateString(calendar.__locale, "yyyy")
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        color: "white"
                        padding: 0
                        font {
                            pixelSize: (parent.height/2.5)*0.7
                        }
                    }

                    NewControls.Label {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        fontSizeMode: Label.Fit
                        text: calendar.selectedDate.toLocaleDateString(calendar.__locale, "ddd, MMM d")
                        verticalAlignment: Text.AlignVCenter
                        padding: 0
                        font {
                            pixelSize: (1.5 * parent.height/2.5) * 0.7
                            bold: true
                        }
                        color: "white"
                    }
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if(swipeView.currentIndex === 1) swipeView.decrementCurrentIndex();
                    }
                }
            }

            Item{
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout{
                    anchors.fill: parent
                    opacity: swipeView.currentIndex === 1 ? 1 : 0.7
                    clip: true
                    spacing: 0
                    NewControls.Label {

                        Layout.preferredHeight: parent.height / 2.5
                        Layout.fillWidth: true
                        text: timePicker.apString
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        color: "white"
                        padding: 0
                        font {
                            pixelSize: (parent.height / 2.5) * 0.7
                        }
                    }

                    NewControls.Label {

                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        fontSizeMode: Label.Fit
                        text: timePicker.hourString + ":" + timePicker.minString
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        padding: 0
                        font {
                            pixelSize: (1.5 * parent.height / 2.5) * 0.7
                            bold: true
                        }

                        color: "white"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if(swipeView.currentIndex === 0) swipeView.incrementCurrentIndex();
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        NewControls.SwipeView{
            id: swipeView

            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0
            padding: 0
            clip: true
            spacing: 0

            XCalendar{
                id: calendar
                isMiniMode: calendarAndTimeDialog.isMiniMode
                selectedDate: calendarAndTimeDialog.selectedDateAndTime
                primaryColor: calendarAndTimeDialog.primaryColor
                onSelectedDateChanged: {
                    calendarAndTimeDialog.selectedDateAndTime.setFullYear(selectedDate.getFullYear());
                    calendarAndTimeDialog.selectedDateAndTime.setDate(selectedDate.getDate());
                    calendarAndTimeDialog.selectedDateAndTime.setMonth(selectedDate.getMonth());
                    dateMilliseconds = selectedDateAndTime.valueOf();
                }
            }

            XTimePicker {
                id: timePicker
                selectedTime: calendarAndTimeDialog.selectedDateAndTime
                primaryColor: calendarAndTimeDialog.primaryColor
                onTimeChanged: {
                    calendarAndTimeDialog.selectedDateAndTime.setHours(selectedTime.getHours());
                    calendarAndTimeDialog.selectedDateAndTime.setMinutes(selectedTime.getMinutes());
                    dateMilliseconds = selectedDateAndTime.valueOf();
                }
            }
        }

        NewControls.PageIndicator {
            id: indicator

            count: swipeView.count
            currentIndex: swipeView.currentIndex
            scale: calendarAndTimeDialog.isMiniMode? 0.5 : 1
            Layout.alignment: Qt.AlignHCenter
        }
    }


    footer: Rectangle {
        id: item
        width: parent.width
        height: calendarAndTimeDialog.height / 8
        color: "transparent"
        clip: true
        anchors.bottom: parent.Bottom
        radius: 5 * AppFramework.displayScaleFactor

        RowLayout {
            id: footerRow
            anchors.fill: parent

            CustomDialogButton {
                id: todayButton
                primaryColor: calendarAndTimeDialog.primaryColor

                Layout.preferredHeight: parent.height
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 10 * AppFramework.displayScaleFactor
                visible: swipeView.currentIndex === 0
                customText: app.today_string
                onClicked: {
                    calendar.selectedDate = new Date();
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            CustomDialogButton {
                id: cancelButton

                Layout.preferredHeight: parent.height
                Layout.preferredWidth: implicitWidth

                primaryColor: calendarAndTimeDialog.primaryColor
                customText: app.cancel_string
                onClicked: {
                    calendarAndTimeDialog.reject();
                }
            }

            CustomDialogButton {
                id: okayButton

                Layout.preferredHeight: parent.height
                Layout.preferredWidth: implicitWidth
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 10 * AppFramework.displayScaleFactor
                primaryColor: calendarAndTimeDialog.primaryColor
                customText: app.ok_String
                onClicked: {
                    calendarAndTimeDialog.accept();
                }
            }
        }
    }

    function updateDateAndTime(){
        calendar.selectedDate = selectedDateAndTime;
        timePicker.selectedTime = selectedDateAndTime;
    }
}

