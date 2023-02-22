import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../controls"

Rectangle {
    id: themelistPage
    objectName: "themelistPage"
    width: app.width
    height:app.height
    color: app.pageBackgroundColor
    signal showNext(string message)
    signal previous(string message)
    signal next(string message)

    function chooseTheme(index,theme){

        list.currentIndex = index
        app.defaultTheme=theme
        app.settings.setValue("appDefaultTheme", app.defaultTheme);
        app.isDarkMode = theme === app.automatic?Platform.systemTheme.mode === SystemTheme.Dark:(defaultTheme === app.light?false:true) //false
        app.settings.setValue("isDarkMode", app.isDarkMode);
    }

    ColumnLayout {
        id: columnLayout
        width:parent.width
        spacing:0

        Rectangle {
            id: createPage_headerBar
            Layout.alignment: Qt.AlignTop
            color: app.headerBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50 * app.scaleFactor
            Layout.topMargin: 0

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
                    settingsstackView.pop()
                }
            }


            Text {
                id: title
                text: qsTr("Theme")
                textFormat: Text.StyledText
                anchors.centerIn: parent
                font.pixelSize: app.titleFontSize
                font.family: app.customTitleFont.name
                color: app.headerTextColor
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }

        ListView {
            id:list
            Layout.fillWidth: true
            topMargin: 0
            Layout.preferredHeight: 600 * scaleFactor
            clip: true
            Component{
                id:themeDelegate
                Item {
                    width:parent.width
                    height: themeCol.height

                    ColumnLayout{
                    id:themeCol
                    width: Math.min(parent.width, app.maximumScreenWidth)
                    anchors.horizontalCenter: parent.horizontalCenter
                    height:app.isSmallScreen ? 64 * app.scaleFactor:84*app.scaleFactor
                    spacing:0

                    Rectangle {
                        Layout.preferredHeight: 1 * app.scaleFactor
                        Layout.fillWidth: true
                        color:Qt.darker(app.pageBackgroundColor, factor)
                        //color:blk_030
                         }

                    SettingsTheme {
                        title: theme
                        imagesource:app.theme_select
                        isImageVisible: app.defaultTheme.toLowerCase() === theme.toLowerCase()
                        isAlignmentSet: false
                        parentPage:"themelistPage"
                        overlayColor: app.blk_140
                        onClicked: {
                            chooseTheme(index,theme)

                        }
                    }

                    Rectangle {

                        Layout.preferredHeight: 1 * app.scaleFactor
                        Layout.fillWidth: true
                        color:Qt.darker(app.pageBackgroundColor, factor)
                        //color:blk_030
                         }
                    }

                }

            }

            model: app.themes
            delegate:themeDelegate

        }

}

}








