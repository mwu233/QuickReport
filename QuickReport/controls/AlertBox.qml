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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

import Esri.ArcGISRuntime 100.10

Item {
    visible: false
    width: parent.width
    height: parent.height

    property string text : "Alert!"
    property color backgroundColor: app.headerBackgroundColor
    property color textColor : "white" //app.textColor
    property variant actionMode : ["quit", "retryService"]
    property string actionRequest: ""
    property alias buttonText : alertButton.buttonText
    property alias buttonVisible: alertButton.visible

    Rectangle {
        anchors.fill: parent
        z:10
        color: "grey"
        opacity: 0.8

        MouseArea {
            anchors.fill: parent
            onClicked: {
                mouse.accepted = true;
            }
        }
    }

    Rectangle {
        anchors {
            centerIn: parent;
            fill: alertContent
            margins: -10
        }
        z:11
        color: backgroundColor
        radius: 5*app.scaleFactor
        //        MouseArea {
        //            anchors.fill: parent
        //            onClicked: {
        //                alertBox.visible = false
        //            }
        //        }
    }


    Column {
        id: alertContent
        //anchors.centerIn: parent
        anchors {
            top: parent.top
            bottom: parent.bottom
            centerIn: parent
        }
        width: Math.min(parent.width, 400*app.scaleFactor)
        spacing: 10
        z:12

        Text {
            id: alertBoxText
            color: textColor
            //fontSizeMode: Text.Fit
            width: parent.width * 0.8
            //maximumLineCount: 4
            textFormat: Text.StyledText

            wrapMode: Text.Wrap
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter

            font {
                pointSize: app.textFontSize
                family: app.customTextFont.name
            }

            text: alertBox.text
        }

        CustomButton {
            id: alertButton
            buttonTextColor: isOnline ? "white" : "lightgrey"
            buttonColor: isOnline ? app.buttonColor : "grey"
            buttonFill: true
            enabled: isOnline
            buttonWidth: 300 * app.scaleFactor
            buttonHeight: buttonWidth/5

            anchors.horizontalCenter: parent.horizontalCenter
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if ( actionRequest === "quit"){
                        Qt.quit();
                    }
                    else if ( actionRequest === "retryService") {
                        serviceInfoTask.fetchFeatureServiceInfo();
                        alertBox.visible = false;
                    }
                }
            }
        }


    }

}
