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
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Notifications 1.0

import Esri.ArcGISRuntime 100.10

import "../controls"

Rectangle {
    width: parent.width
    height: parent.height
    color: app.pageBackgroundColor

    property bool isBusy: false

    property bool theFeatureEditingSuccess2: false
    property string type: "result"
    signal next(string message)
    signal previous(string message)

    ColumnLayout {
        width: parent.width
        height: parent.height
        spacing: 0

        Rectangle {
            id: resultsPage_headerBar
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

            Text {
                id: resultsPage_titleText
                text: (app.theFeatureEditingAllDone && app.theFeatureEditingSuccess && app.theFeatureAttachmentsSuccess) ? qsTr("Thank You") : ""
                textFormat: Text.StyledText
                anchors.centerIn: parent
                fontSizeMode: Text.Fit
                font.pixelSize: app.titleFontSize
                font.family: app.customTitleFont.name
                color: app.headerTextColor
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.fillHeight: true
            color:"transparent"
            Layout.preferredWidth: parent.width
            Layout.maximumWidth: 600*app.scaleFactor
            Layout.alignment: Qt.AlignHCenter

            Item {
                width: parent.width * 0.8
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter

                ColumnLayout {
                    anchors.fill: parent

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16 * app.scaleFactor
                    }

                    Image {
                        source: "../images/success.png"
                        visible: app.theFeatureEditingSuccess && app.theFeatureAttachmentsSuccess && app.theFeatureEditingAllDone
                        Layout.preferredHeight: 256*app.scaleFactor
                        Layout.preferredWidth: 256*app.scaleFactor
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                   Label {
                        Layout.fillWidth: true
                        font {
                            pixelSize: app.titleFontSize
                            family: app.customTextFont.name
                        }
                        horizontalAlignment: Qt.AlignHCenter
                        color: app.textColor
                        text: app.theFeatureEditingAllDone ? ((app.theFeatureEditingSuccess && app.theFeatureAttachmentsSuccess)? app.reportSuccessMsg : app.errorMsg) : qsTr("Uploading...")
                        onTextChanged: {
                                if(app.theFeatureEditingAllDone && app.isHapticFeedbackSupported) {
                                    if(app.theFeatureEditingSuccess && app.theFeatureAttachmentsSuccess) {
                                        HapticFeedback.send(HapticFeedback.HapticFeedbackTypeSuccess);
                                    } else {
                                        HapticFeedback.send(HapticFeedback.HapticFeedbackTypeError);
                                    }
                                }
                            }
                        }

                    Text{
                        Layout.preferredWidth: parent.width*0.9
                        text: app.isShowCustomText? app.thankyouMessage : ""
                        textFormat: Text.RichText
                        visible: app.theFeatureEditingAllDone && app.theFeatureEditingSuccess && app.theFeatureAttachmentsSuccess && text > ""
                        horizontalAlignment: Text.AlignHCenter
                        font {
                            pixelSize: app.textFontSize
                            family: app.customTextFont.name
                        }
                        color: app.textColor
                        maximumLineCount: 8
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignHCenter
                        onLinkActivated: Qt.openUrlExternally(link)
                        Component.onCompleted: {
                            Qt.inputMethod.hide();
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6 * app.scaleFactor
                    }

                    Repeater {
                        model: app.submitStatusModel
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            visible: !app.theFeatureEditingAllDone || !app.theFeatureEditingSuccess || !app.theFeatureAttachmentsSuccess

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50 * AppFramework.displayScaleFactor
                                spacing: 25 * AppFramework.displayScaleFactor

                                ImageOverlay {
                                    Layout.preferredHeight: 30 * AppFramework.displayScaleFactor
                                    Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                                    Layout.alignment: Qt.AlignVCenter
                                    source: {
                                        var source = "";
                                        switch(type) {
                                        case "attachment":
                                            source = "../images/file-image.png";
                                            break;
                                        case "attachment2":
                                            source = "../images/file-video.png";
                                            break;
                                        case "attachment3":
                                            source = "../images/audiobook.png";
                                            break;
                                        case "attachment4":
                                            source = "../images/fileattachment.png";
                                            break;
                                        case "attachment5":
                                            source = "../images/fileattachment.png";
                                            break;
                                        case "feature":
                                            switch(app.captureType) {
                                            case "point":
                                                source = "../images/location.png"
                                                break;
                                            case "line":
                                                source = "../images/vector-polyline.png"
                                                break;
                                            case "area":
                                                source = "../images/vector-polygon.png"
                                                break;
                                            }
                                            break;
                                        }
                                        return source;
                                    }
                                    overlayColor: app.textColor
                                    showOverlay: true
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                   Label {
                                        padding: 0
                                        Layout.fillWidth: true
                                        text: type === "feature" ? qsTr("Add new feature") : fileName
                                        font.pixelSize: app.textFontSize
                                        font.family: app.customTextFont.name
                                        verticalAlignment: Label.AlignVCenter
                                        color: app.textColor
                                        elide: Label.ElideMiddle
                                        font.bold: true
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Item {
                                            Layout.preferredWidth: statusText.height
                                            Layout.preferredHeight: statusText.height

                                           BusyIndicator {
                                                anchors.fill: parent
                                                visible: running
                                                running: loadStatus === "loading"
                                                padding: 0
                                                Material.accent: Material.Grey
                                            }

                                            ImageOverlay {
                                                anchors.fill: parent
                                                source: loadStatus === "success" ? "../images/done_white.png" : "../images/ic_clear_white_48dp.png"
                                                visible: loadStatus != "loading"
                                                overlayColor: loadStatus === "success" ? "green" : "red"
                                                showOverlay: true
                                            }
                                        }

                                       Label {
                                            id: statusText

                                            Layout.fillWidth: true
                                            padding: 0
                                            text: {
                                                var detail = "";
                                                if(type != "feature") {
                                                    detail = (loadStatus === "loading") ? qsTr("Uploading...") : (loadStatus === "failed" ? qsTr("Failed") : qsTr("Uploaded"));
                                                } else {
                                                    detail = loadStatus === "success"? qsTr("Completed") : qsTr("Failed");
                                                }

                                                return detail;
                                            }
                                            font.pixelSize: app.subtitleFontSize
                                            font.family: app.customTextFont.name
                                            verticalAlignment: Label.AlignVCenter
                                            color: loadStatus === "failed" ? "red" : app.textColor
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: parent.width
                                Layout.preferredHeight: 1
                                Layout.alignment: Qt.AlignHCenter
                                visible: type === "feature" && app.submitStatusModel.count > 1
                                color: Qt.lighter("gray")
                                opacity: app.isDarkMode? 0.5:1.0
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50*app.scaleFactor
            Layout.maximumWidth: Math.min(parent.width*0.95, 600*scaleFactor);
            color: app.pageBackgroundColor
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: 8*app.scaleFactor
            radius: 4*app.scaleFactor
            clip: true
            visible: app.theFeatureEditingAllDone
            Layout.bottomMargin: app.isIPhoneX ? 28 * app.scaleFactor : 8 * app.scaleFactor

            RowLayout {
                anchors.fill: parent
                spacing: 8*app.scaleFactor

                CustomButton {
                    buttonText: (app.theFeatureEditingSuccess && app.theFeatureAttachmentsSuccess)? qsTr("Done"): qsTr("Save")
                    buttonColor: app.buttonColor
                    buttonFill: true
                    buttonWidth: (app.theFeatureEditingSuccess && app.theFeatureAttachmentsSuccess)? parent.width: (parent.width/2 - 4*app.scaleFactor)
                    buttonHeight: 50*app.scaleFactor
                    visible: app.theFeatureEditingAllDone
                    Layout.fillWidth: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if(app.theFeatureEditingSuccess && app.theFeatureAttachmentsSuccess) {
                                next("home")
                            }else{
                                if(!app.isFromSend){
                                    app.saveReport();
                                } else{
                                    app.isFromSend = false;
                                }

                                // delete feature from server if failed to submit
                                if(AppFramework.network.isOnline && app.currentObjectId > 0) {
                                    app.deleteFeature(app.currentObjectId);
                                }

                                next("home")
                            }
                        }
                    }
                }

                CustomButton {
                    buttonText: qsTr("Discard")
                    buttonColor: app.buttonColor
                    buttonFill: false
                    buttonWidth: parent.width/2
                    buttonHeight: 50*app.scaleFactor
                    visible: (!theFeatureEditingSuccess || !theFeatureAttachmentsSuccess)&&(app.theFeatureEditingAllDone)
                    Layout.preferredWidth: parent.width/2 - app.scaleFactor

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            confirmBox.visible = true;
                        }
                    }
                }

            }
        }
    }

    DropShadow {
        source: resultsPage_headerBar
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

    ConfirmBox{
        id: confirmBox
        anchors.fill: parent
        onAccepted: {
            // delete feature from local database
            if(app.isFromSaved){
                deleteReportFromDatabase();
            }

            // delete all attachments
            var attachments = [];
            for(var i=0;i<app.appModel.count;i++){
                temp = app.appModel.get(i).path;
                app.selectedImageFilePath = AppFramework.resolvedPath(temp)
                attachments.push(app.selectedImageFilePath);
            }
            removeAttachments(attachments);

            // delete feature from server if failed to submit
            if(Networking.isOnline && app.currentObjectId > 0 && (!theFeatureEditingSuccess || !theFeatureAttachmentsSuccess)) {
                app.deleteFeature(app.currentObjectId);
            }

            next("home");
        }
    }

    function back(){
        if(confirmBox.visible===true){
            confirmBox.visible = false;
        }
    }
}
