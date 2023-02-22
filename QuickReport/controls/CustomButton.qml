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
import QtGraphicalEffects 1.0

Item {
    property string buttonText: "Button"
    property real buttonWidth: 200 * app.scaleFactor
    property real buttonHeight: buttonWidth/4
    property color buttonColor: "#165F8C"
    property bool buttonFill: true
    property color buttonTextColor: "#ffffff"
    property int buttonFontSize: 16 * app.scaleFactor
    property int buttonBorderRadius: 4* app.scaleFactor
    property bool seperator: false

    height: buttonHeight
    width: buttonWidth

    Rectangle {
        id: root
        width: buttonWidth
        height: buttonHeight
        color: buttonFill ? buttonColor : "transparent"
        border.color: buttonColor
        border.width: buttonFill ? 0 : 2
        radius:buttonBorderRadius
        //anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
            anchors.fill: parent
            visible: false//buttonFill
            gradient: Gradient {
                GradientStop { position: 1 ; color: "#33000000"}
                GradientStop { position: 0 ; color: "#22000000" }
            }
            radius:buttonBorderRadius
        }
        Text {
            id: text
            height:parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.horizontalCenter: parent.horizontalCenter
            color:buttonFill ? buttonTextColor : buttonColor
            text:buttonText
            font.pixelSize: buttonFontSize
            fontSizeMode: Text.Fit
        }
    }
}
