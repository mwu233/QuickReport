import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import ArcGIS.AppFramework 1.0

import QtGraphicalEffects 1.0
import "../controls/"

Rectangle {
    id: settingsTheme
    Layout.fillWidth: true
    Layout.preferredHeight: app.isSmallScreen ? 64 * app.scaleFactor:84*app.scaleFactor
    color: Qt.lighter(app.pageBackgroundColor, factor)
    property string title: ""
    property string subtitle: ""
    property string imagesource:""
    property bool isImageVisible:true
    property bool isAlignmentSet:false
    property string overlayColor:""
    property string parentPage:""


    signal clicked()

    MouseArea {
        anchors.fill: parent
        onClicked: {
            settingsTheme.clicked();
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        anchors.left: parent.left
        anchors.leftMargin: 16*app.scaleFactor

        ImageOverlay{
            Layout.preferredHeight: 25*app.scaleFactor
            Layout.preferredWidth: 25*app.scaleFactor
            Layout.alignment: Qt.AlignVCenter
            source: "../images/ic_theme_light_dark_black_24dp.png"
            fillMode: Image.PreserveAspectFit
            opacity: 0.6
            showOverlay: app.isDarkMode
            visible:parentPage === "settingsPage"?true:false
        }

        Item {
            Layout.fillHeight: true
             Layout.preferredWidth: parentPage === "settingsPage"? 16 * app.scaleFactor:20 * app.scaleFactor
        }
        Item{
             Layout.preferredHeight: 50 * scaleFactor
             Layout.fillWidth: true
             Layout.alignment: Qt.AlignVCenter



        ColumnLayout {
            id: labelTitle
            anchors.fill:parent
            spacing: 0


            Label {
                Layout.fillWidth: true
                text: title
                font.pixelSize: app.textFontSize
                font.family: app.customTitleFont.name
                color: app.subtitleColor
                wrapMode: Label.Wrap
                padding: 0
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter

            }


            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 1 * app.scaleFactor
                visible: subtitle > ""
            }

            Label {
                Layout.fillWidth: true
                text: subtitle
                font.pixelSize: app.subtitleFontSize
                font.family: app.customTitleFont.name
                color: app.subtitleColor
                wrapMode: Label.Wrap
                padding: 0
                visible:text > ""
                height:visible ? implicitHeight:0
            }

        }

        }
        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: 50 * app.scaleFactor
        }

        Item
        {
            id:imageDown
            Layout.preferredWidth: 30 * app.scaleFactor
            Layout.fillHeight: true

            Image{
                id:imageDownArrow
                source: imagesource
                width: 24 * app.scaleFactor
                height: 24 * app.scaleFactor
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                visible:isImageVisible
                }

            ColorOverlay{
                anchors.fill: imageDownArrow
                source:imageDownArrow
                color:overlayColor
                visible:isImageVisible
               }

        }


        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: 14 * app.scaleFactor
        }
    }
}


