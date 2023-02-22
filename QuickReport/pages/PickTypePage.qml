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
import QtQuick.Layouts 1.3
import QtMultimedia 5.2
import Qt.labs.folderlistmodel 2.1
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

import Esri.ArcGISRuntime 100.10
import "../controls/"

Rectangle {
    id: pickTypePage
    width: parent?parent.width:0
    height: parent?parent.height:0
    color: app.pageBackgroundColor
    signal next(string message)
    signal previous(string message)

    property bool isBusy: false
    property bool allDone: false

    property date calendarDate: new Date()

    property string domainFieldName: ""
    property string type: "appview"

    property bool backToPreviousPage: true
    property var webPage

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: createPage_headerBar
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
                    var stackitem = stackView.get(stackView.depth - 2)
                    if(stackitem.objectName === "summaryPage")
                    {
                        var oldAttributesArray = JSON.parse(JSON.stringify(attributesArray));

                        typePicker.getProtoTypeAndSubTypeDomains()
                        Object.keys(oldAttributesArray).forEach(function(key,index) {
                            attributesArray[key] = oldAttributesArray[key]
                        });


                        app.populateSummaryObject()
                        previous("")
                    }
                    else {
                        app.steps--;
                        previous("")
                    }
                }
            }

            CarouselSteps{
                id:carousal
                height: parent.height
                anchors.centerIn: parent
                items: app.numOfSteps
                currentIndex: app.steps
            }

            ImageButton {
                source: "../images/ic_send_white_48dp.png"
                height: 30 * app.scaleFactor
                width: 30 * app.scaleFactor
                visible: false//app.isFromSaved
                enabled: app.isFromSaved && app.isReadyForSubmitReport && app.isOnline
                opacity: enabled? 1:0.3
                checkedColor : "transparent"
                pressedColor : "transparent"
                hoverColor : "transparent"
                glowColor : "transparent"
                anchors.rightMargin: 10
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    console.log("isReady:::", hasAttachment);
                    confirmToSubmit.visible = true;
                }
            }
        }

        RowLayout{
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: createPage_titleText.height
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: 16*app.scaleFactor
            spacing: 5*app.scaleFactor
            Text {
                id: createPage_titleText
                text: qsTr("Select Disaster Type")
                textFormat: Text.StyledText
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: app.titleFontSize
                font.family: app.customTitleFont.name
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: app.textColor
                maximumLineCount: 1
                elide: Text.ElideRight
                fontSizeMode: Text.Fit
            }

            ImageOverlay{
                Layout.preferredHeight: Math.min(36*app.scaleFactor, parent.height)*0.9
                Layout.preferredWidth: Math.min(36*app.scaleFactor, parent.height - (5*app.scaleFactor))*0.9
                source: "../images/ic_info_outline_black_48dp.png"
                overlayColor: app.textColor
                showOverlay: true
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter
                visible: app.isHelpUrlAvailable
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if(app.helpPageUrl && validURL(app.helpPageUrl))
                            app.openWebView(0, {  url: app.helpPageUrl });
                        else
                        {
                            if(app.helpPageUrl && validURL(app.helpPageUrl))
                                app.openWebView(0, {  url: app.helpPageUrl });
                            else
                            {
                                var component = webPageComponent;
                                webPage = component.createObject(pickTypePage);
                                webPage.openSectionID(""+1)
                            }

                            //app.openWebView(1, { pageId: pickTypePage, url: "" + 1 });
                        }
                    }
                }
            }
        }

        SubTypePicker {
            id: typePicker
            Layout.preferredWidth: parent.width
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 600 * app.scaleFactor
        }

        Rectangle {
            id: footer
            Layout.preferredHeight: nextButton.height
            Layout.preferredWidth: parent.width * 0.95
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: app.units(8)
            Layout.maximumWidth: app.units(600)
            color: "transparent"
            Layout.bottomMargin: app.isIPhoneX ? 28 * app.scaleFactor : 8 * scaleFactor

            CustomButton {
                id: nextButton
                buttonText: qsTr("Next")
                buttonColor: app.buttonColor
                buttonFill: typePicker.itemChecked
                buttonWidth: Math.min(parent.width, 600*scaleFactor)
                buttonHeight: visible? 50 * app.scaleFactor : 0
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: typePicker.itemChecked
                visible: typePicker.indexSelected > -1
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        typePicker.getProtoTypeAndSubTypeDomains()
                        next("")
                    }
                    onPressedChanged: {
                        nextButton.buttonColor = pressed? Qt.darker(app.buttonColor, 1.1): app.buttonColor
                    }
                }
            }
        }
    }

    ConfirmBox{
        id: confirmToSubmit
        anchors.fill: parent
        standardButtons: StandardButton.Yes | StandardButton.No
        text: app.titleForSubmitInDraft
        informativeText: app.messageForSubmitInDraft
        onAccepted: {
            pickListIndex = typePicker.indexSelected;
            submitReport();
        }
    }

    DropShadow {
        source: createPage_headerBar
        width: source.width
        height: source.height
        cached: false
        radius: 5.0
        samples: 16
        color: "#80000000"
        smooth: true
        visible: source.visible
    }
    Component.onCompleted: {
      var stackitem = stackView.get(stackView.depth - 2)
        if(stackitem.objectName === "summaryPage")
        {
            nextButton.visible = false
            carousal.visible = false

        }

    }

    function back(){
        if(webPage != null && webPage.visible === true){
            webPage.close();
            app.focus = true;
        } else {
            console.log("Back button from Add Details page clicked")
            app.steps--;
            previous("")
            //stackView.pop(); //TO-DO
        }
    }
}
