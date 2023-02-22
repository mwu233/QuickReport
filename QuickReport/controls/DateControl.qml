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

import "../images"


Column {
    id: column
    spacing: 3
    anchors.horizontalCenter: parent.horizontalCenter

    Text {
        text: fieldAlias+(nullableValue?"":"*")

        anchors {
            left: parent.left
            right: parent.right
        }
        color: nullableValue?app.textColor: "red"
        font{
            pixelSize: app.textFontSize
            family: app.customTextFont.name
        }
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        maximumLineCount: 2
    }

    TextField {

        width: parent.width

        placeholderText: "this will be a calendar picker"

        inputMethodHints: fieldType == "esriFieldTypeInteger" ? Qt.ImhFormattedNumbersOnly : Qt.ImhDigitsOnly
    }
    CalendarWindow {

    }
}
