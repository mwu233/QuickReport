/* Copyright 2019 Esri
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
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../controls"

Rectangle {
    id: disclamerPage

    color: app.pageBackgroundColor
    property string type: "appview"

    ColumnLayout {
        anchors.fill: parent
        spacing: app.units(16)

        Rectangle {
            id: mapPage_headerBar
            Layout.alignment: Qt.AlignTop
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
                    stackView.pop()
                }
            }


            Text {
                id: mapPage_titleText
                text: qsTr("Disclaimer")
                textFormat: Text.StyledText
                anchors.centerIn: parent
                font.pixelSize: app.titleFontSize
                font.family: app.customTitleFont.name
                color: app.headerTextColor
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: 16*app.scaleFactor
            color: "transparent"
            Layout.fillWidth: true
            Layout.maximumWidth: app.units(600)
            Layout.fillHeight: true

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    mouse.accepted = false
                }
            }

            Flickable {
                anchors.fill: parent
                contentHeight: columnContainer.height
                clip: true

                ColumnLayout {
                    id: columnContainer
                    //anchors.fill: parent
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: app.info.licenseInfo
                        textFormat: Text.StyledText
                        color: app.textColor
                        wrapMode: Text.Wrap
                        lineHeight: 1.1
                        linkColor: app.headerBackgroundColor
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        font.pixelSize: app.textFontSize
                        font.family: app.customTextFont.name
                        Layout.margins: 16 * app.scaleFactor
                        onLinkActivated: {
                            app.openWebView(0, { pageId: disclamerPage, url: link });
                        }
                    }
                }
            }
        }

        Rectangle {
            id: footer
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: parent.width * 0.95
            Layout.preferredHeight: 50*app.scaleFactor
            color: app.pageBackgroundColor
            Layout.margins: 8 * app.scaleFactor
            Layout.maximumWidth: app.units(600)
            Layout.bottomMargin: app.isIPhoneX ? 28 * app.scaleFactor : 8 * app.scaleFactor

            CustomButton {
                id: agreeButton
                buttonText: qsTr("Agree")
                buttonColor: app.buttonColor
                buttonFill: true
                buttonWidth: parent.width
                buttonHeight: app.scaleFactor*50
                anchors.horizontalCenter: parent.horizontalCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        stackView.showPickTypePage();
                        // stackView.showDisasterType();
                        if(featureLayerId.length === 1) {
                            app.featureLayerURL = featureServiceURL + "/" + featureLayerId[0];
                            app.featureLayerBeingEdited = "default"
                            app.init();
                        } else {
                            // stackView.showDisasterType();
                            stackView.showPickTypePage();
                        }
                    }
                    onPressedChanged: {
                        agreeButton.buttonColor = pressed ?
                                    Qt.darker(app.buttonColor, 1.1): app.buttonColor
                    }
                }
            }
        }
    }

    DropShadow {
        source: mapPage_headerBar
        //anchors.fill: source
        width: source.width
        height: source.height
        cached: false
        radius: 5.0
        samples: 16
        color: "#80000000"
        smooth: true
        visible: source.visible
    }

    function back(){
        stackView.pop();
    }
}
