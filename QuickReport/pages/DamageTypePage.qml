import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../controls"

Page {
    id: damageTypePage
    width: parent.width
    height: parent.height
    objectName: "damageTypePage"
    parentPage:objectName

    signal next(string message)
    signal previous(string message)

    header: Rectangle {
        id: header

        color: app.headerBackgroundColor
        width: parent.width
        height: 50 * app.scaleFactor

        MouseArea {
            anchors.fill: parent
            onClicked: {
                mouse.accepted = true;
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
                // stackView.pop();
                var stackitem = stackView.get(stackView.depth - 2) //var stackitem = stackView.get(stackView.depth - 2)
                if (stackitem.objectName === "summaryPage") {
                    app.populateSummaryObject()
                    //app.steps--;
                    previous("")
                }
                else {
                    stackView.pop();
                }
            }
        }

        Text {
            id: title
            text: qsTr("Damage Types")
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

    footer.visible: false

    content: Rectangle {
        anchors.fill: parent
        color: app.pageBackgroundColor

        ListView {
            id: galleryListView

            width: Math.min(parent.width, 600 * scaleFactor) - 32 * scaleFactor
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter

            clip: true

            spacing: 16 * scaleFactor

            currentIndex: - 1

            header: Item {
                width: parent.width
                height: 52 * scaleFactor

                Label {
                    anchors.fill: parent
                    font.pixelSize: 16 * app.scaleFactor *  fontScale
                    font.family: app.customTitleFont.name
                    color: isDarkMode ? "white" : "#828282"
                    text: qsTr("Choose a damage type to continue")
                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            model: damageListModel

            delegate: Rectangle {
                width: parent.width
                height: contentLayout.height + 48 * scaleFactor
                radius: 2 * scaleFactor

                color: isDarkMode ? "#4D4D4D" : "#ffffff"
                border.width: 1
                border.color: galleryListView.currentIndex === index ? app.headerBackgroundColor : "#0F000000"

                RowLayout {
                    id: contentLayout

                    width: parent.width - 32 * scaleFactor
                    anchors.centerIn: parent
                    spacing: 16 * scaleFactor

                    Rectangle {
                        id: layerIcon

                        Layout.preferredWidth: 32 * scaleFactor
                        Layout.preferredHeight: 32 * scaleFactor
                        Layout.alignment: Qt.AlignTop

                        radius: 16 * scaleFactor

                        color: app.headerBackgroundColor

                        ImageOverlay {
                            anchors.fill: parent
                            anchors.margins: 4 * scaleFactor

                            source: layerTypeIcon

                            overlayColor: "#ffffff"
                            showOverlay: true
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: layerLabelsLayout.height

                        ColumnLayout {
                            id: layerLabelsLayout

                            width: parent.width
                            spacing: 8 * scaleFactor

                            Label {
                                Layout.fillWidth: true
                                text: damageType
                                color: isDarkMode ? "white" : "#323232"
                                font.pixelSize: 20 * scaleFactor  * fontScale
                                font.family: app.customTextFont.name
                                wrapMode: Label.Wrap
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        galleryListView.currentIndex = index;

                        var damageTypeStrings = ['Casualties', 'Roads', 'Buildings', 'Others']
                        app.damageTypeString = damageTypeStrings[index]; // TO-DO

                        // app.init();
                        var stackitem = stackView.get(stackView.depth - 2) //var stackitem = stackView.get(stackView.depth - 2)
                        if (stackitem.objectName === "summaryPage") {
                            app.populateSummaryObject()
                            // app.steps--;
                            previous("")
                        }
                        else {
                            stackView.showRefineLocationPage();
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: damageListModel
    }

    Component.onCompleted: {
        damageListModel.clear();

        // featureLayerId.sort(function(a, b){return a-b})

        // loop for all report types
        for (var i in app.damageTypeId) {
            var damageType = "";
            if(i === "0"){
                damageType = "Casualties";
            } else if(i === "1"){
                damageType = "Road damage";
            } else if(i === "2"){
                damageType = "Building damage";
            } else if(i === "3"){
                damageType = "Others";
            }

            damageListModel.append({
                                       "damageType": damageType
                                   })
        }
    }

    onBack: {
        stackView.pop();
    }
}
