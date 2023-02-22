import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Private 1.0
import QtQuick.Layouts 1.3
import QtQuick.Extras 1.4

import QtQuick.Controls 2.1 as NewControls
import QtQuick.Controls.Material 2.1 as MaterialStyle

import QtGraphicalEffects 1.12
import ArcGIS.AppFramework 1.0

Calendar {
    id: calendar

    property int yearStart: new Date().getFullYear() - 75;
    property int yearEnd: yearStart + 100
    property bool yearPickerVisible: true
    property bool monthPickerVisible: true
    property int barHeight: isMiniMode? Math.round(TextSingleton.implicitHeight*1.25):Math.round(TextSingleton.implicitHeight * 2.5)
    property int barTextSize: TextSingleton.implicitHeight * 1.1
    readonly property int monthRepeatInterval: 100
    readonly property int yearRepeatInterval: 50

    property color primaryColor: "#009688"

    property var __locale: Qt.locale()

    property bool isMiniMode: false

    style: CalendarStyle {
        gridVisible: false
        gridColor: "transparent"
        padding.bottom: 0
        padding.top: 0
        padding.left: 0
        padding.right: 0

        background: Rectangle{
            color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#424242":"transparent"
        }

        dayOfWeekDelegate: Item {
            id: dayOfWeekDelegateItem
            height: Math.round(TextSingleton.implicitHeight*1.25)

            Label {
                text: control.__locale.dayName(styleData.dayOfWeek, control.dayOfWeekFormat)
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#ededed":"#444"
                elide: Text.ElideRight
                font {
                    pixelSize: Math.min(parent.height/1.75, parent.width/1.75)
                }

                minimumPixelSize: 21 * AppFramework.displayScaleFactor
            }
        }

        dayDelegate: Item {
            anchors.fill: parent
            anchors.leftMargin: (!addExtraMargin || control.weekNumbersVisible) && styleData.index % CalendarUtils.daysInAWeek === 0 ? 1 : 0
            anchors.rightMargin: !addExtraMargin && styleData.index % CalendarUtils.daysInAWeek === CalendarUtils.daysInAWeek - 1 ? 1 : 0
            anchors.bottomMargin: !addExtraMargin && styleData.index >= CalendarUtils.daysInAWeek * (CalendarUtils.weeksOnACalendarMonth - 1) ? 1 : 0
            anchors.topMargin: styleData.selected ? 0 : 1

            Rectangle{
                width: Math.min(parent.width, parent.height)
                anchors.centerIn: parent
                height: width
                color: styleData.date !== undefined && styleData.selected ? (MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#00675b":primaryColor) : "transparent"
                radius: width/2
            }

            readonly property bool addExtraMargin: control.frameVisible && styleData.selected
            readonly property color sameMonthDateTextColor: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#ededed":"#444"
            readonly property color selectedDateColor: Qt.platform.os === "osx" ? "#3778d0" : SystemPaletteSingleton.highlight(control.enabled)
            readonly property color selectedDateTextColor: "#ededed"
            readonly property color differentMonthDateTextColor: "#bbb"
            readonly property color invalidDateColor: "#414141"

            Label {
                id: dayDelegateText
                text: styleData.date.getDate()
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignRight
                font {
                    pixelSize: Math.min(parent.height / 2, parent.width / 2)
                }
                color: {
                    var theColor = invalidDateColor;
                    if (styleData.valid) {
                        // Date is within the valid range.
                        theColor = styleData.visibleMonth ? sameMonthDateTextColor : differentMonthDateTextColor;
                        if (styleData.selected)
                            theColor = selectedDateTextColor;

                    }
                    theColor;
                }
            }
        }

        navigationBar: Item {
            width: parent.width
            height: barHeight

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    id: prevYearButtonWrapper
                    Layout.preferredHeight: AppFramework.systemInformation.family === "phone" ? parent.height * 0.75 : parent.height
                    Layout.preferredWidth: AppFramework.systemInformation.family === "phone" ? parent.height * 0.75 : parent.height

                    NewControls.ToolButton {
                        anchors.fill: parent

                        onClicked: control.showPreviousYear()
                        flat: true
                        indicator: Image{
                            id: doubleLeftArrow
                            width: AppFramework.systemInformation.family === "phone" ? parent.width * 0.5 : parent.width * 0.4
                            height: AppFramework.systemInformation.family === "phone" ? parent.height * 0.5 : parent.height * 0.4
                            anchors.centerIn: parent
                            source: "../images/Double_Left_4x.png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }

                        ColorOverlay {
                            anchors.fill: doubleLeftArrow
                            source: doubleLeftArrow
                            color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark ? "#fff" : "#000"
                        }
                    }
                }

                Item {
                    id: centerRowLayoutWrapper
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    RowLayout {
                        id: centerRowLayout
                        anchors.centerIn: parent
                        height: barHeight
                        spacing: 0

                        NewControls.ToolButton {
                            Layout.maximumHeight: AppFramework.systemInformation.family === "phone" ? parent.height * 0.75 : parent.height
                            Layout.maximumWidth: AppFramework.systemInformation.family === "phone" ? parent.height * 0.75: parent.height

                            onClicked: {
                                control.showPreviousMonth()
                            }

                            flat: true
                            indicator: Image{
                                id: singleLeftArrow
                                width: AppFramework.systemInformation.family === "phone" ? parent.width * 0.5 : parent.width * 0.4
                                height: AppFramework.systemInformation.family === "phone" ? parent.height * 0.5 : parent.height * 0.4
                                anchors.centerIn: parent
                                source: "../images/Single_left_4x.png"
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }

                            ColorOverlay {
                                anchors.fill: singleLeftArrow
                                source: singleLeftArrow
                                color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#fff" : "000"
                            }
                        }

                        Label {
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            text: control.__locale.standaloneMonthName(control.visibleMonth, Locale.ShortFormat) + " " + control.visibleYear
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#ededed":"#444"
                            font {
                                pixelSize: AppFramework.systemInformation.family === "phone" ? parent.height * 0.30 : parent.height * 0.35
                                bold: true
                            }
                        }

                        NewControls.ToolButton {
                            Layout.maximumHeight: AppFramework.systemInformation.family === "phone" ? parent.height * 0.75 : parent.height
                            Layout.maximumWidth: AppFramework.systemInformation.family === "phone" ? parent.height * 0.75 : parent.height

                            onClicked: control.showNextMonth()
                            flat: true
                            indicator: Image{
                                id: singleRightArrow
                                width: AppFramework.systemInformation.family === "phone" ? parent.width * 0.5 : parent.width * 0.4
                                height: AppFramework.systemInformation.family === "phone" ? parent.height * 0.5 : parent.height * 0.4
                                anchors.centerIn: parent
                                source: "../images/Single_Right_4x.png"
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }

                            ColorOverlay {
                                anchors.fill: singleRightArrow
                                source: singleRightArrow
                                color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark ? "#fff" : "#000"
                            }
                        }
                    }
                }

                Item {
                    id: nextYearButtonWrapper
                    Layout.preferredHeight: AppFramework.systemInformation.family === "phone" ? parent.height * 0.75 : parent.height
                    Layout.preferredWidth: AppFramework.systemInformation.family === "phone" ? parent.height * 0.75 : parent.height

                    NewControls.ToolButton {
                        anchors.fill: parent

                        onClicked: control.showNextYear()
                        flat: true
                        indicator: Image{
                            id: doubleRightArrow
                            width: AppFramework.systemInformation.family === "phone" ? parent.width * 0.5 : parent.width * 0.4
                            height: AppFramework.systemInformation.family === "phone" ? parent.height * 0.5 : parent.height * 0.4
                            anchors.centerIn: parent
                            source: "../images/Double_Right_4x.png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }

                        ColorOverlay {
                            anchors.fill: doubleRightArrow
                            source: doubleRightArrow
                            color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark ? "#fff" : "#000"
                        }
                    }
                }
            }
        }
    }
}
