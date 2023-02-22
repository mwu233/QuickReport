import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../controls"

Page {
    id:reportGalleryPage
    width: parent.width
    height: parent.height
    objectName: "reportGalleryPage"
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
                var stackitem = stackView.get(stackView.depth - 2) // var stackitem = stackView.get(stackView.depth - 2)
                if (stackitem.objectName === "summaryPage") {
                    app.populateSummaryObject()
                    // app.steps--;
                    previous("")

                }
                else {
                    stackView.pop(); //TO-DO
                }
            }
        }

        Text {
            id: title
            text: qsTr("Report Types")
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
                    text: qsTr("Choose a report type to continue")
                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            model: reportListModel

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
                                text: reportType
                                color: isDarkMode ? "white" : "#323232"
                                font.pixelSize: 20 * scaleFactor  * fontScale
                                font.family: app.customTextFont.name
                                wrapMode: Label.Wrap
                            }

                            Label {
                                Layout.fillWidth: true
                                text: layerDescription
                                color: isDarkMode ? "#CACACA" : "#828282"
                                font.pixelSize: 14 * scaleFactor  * fontScale
                                font.family: app.customTextFont.name
                                wrapMode: Label.Wrap
                                visible: text > ""
                                clip: true
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        galleryListView.currentIndex = index;

                        var reportTypeStrings = ['Damage', 'Request', 'Donation']
                        app.reportTypeString = reportTypeStrings[index]; // TO-DO

                        var stackitem = stackView.get(stackView.depth - 2) // var stackitem = stackView.get(stackView.depth - 2)
                        if (stackitem.objectName === "summaryPage") {
                            app.populateSummaryObject()
                            // app.steps--;
                            previous("")
                        }
                        else {
                            stackView.showDamageTypePage();
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: reportListModel
    }

    Component.onCompleted: {
        reportListModel.clear();

        featureLayerId.sort(function(a, b){return a-b})

        // loop for all report types
        for (var i in app.reportTypeId) {
            var schemaURL = featureServiceURL + "/" + app.featureLayerId[0];
            var json = featureServiceManager.getLocalSchema(schemaURL);
            var name = json.name;

            var geometryType = "esriGeometryPoint";
            var icon = "../images/point.png";
            var reportType = "";
            var description = ""

            if(i === "0"){
                reportType = "Damage Report";
                description = "Report the damage you experienced or witnessed.";
            } else if(i === "1"){
                reportType = "Request Report";
                description = "Send us a request for needed resources.";
            } else if(i === "2"){
                reportType = "Donation Report";
                description = "Tell us what you want to donate.";
            }

            reportListModel.append({
                                       "layerName": name,
                                       "geometryType": geometryType,
                                       "reportType": reportType,
                                       "layerDescription": description,
                                       "layerTypeIcon": icon,
                                       "layerURL": schemaURL
                                   })
        }
    }

    onBack: {
        stackView.pop();
    }
}
