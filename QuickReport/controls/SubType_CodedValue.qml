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
import QtQuick.Controls.Material 2.12



Column {
    id: column
    spacing: 3 * app.scaleFactor

    width: parent.width

    Text {
        text: fieldAlias+ (nullableValue?"":"*")

        anchors {
            left: parent.left
            right: parent.right
        }
        color: nullableValue?app.textColor:"red"
        font{
            pixelSize: app.subtitleFontSize
            family: app.customTextFont.name
        }
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        maximumLineCount: 2
    }

    ComboBox {
        id: comboBox
        anchors{
            left: parent.left
            right:parent.right
        }
        Material.accent: app.headerBackgroundColor

        Material.foreground: comboBox.enabled ? "Black" : "grey"

        enabled: false

        model: codedNameArray

        onActivated: {
            listView.onAttributeUpdate(objectName, codedCodeArray[comboBox.currentIndex], nullableValue)
        }

        Component.onCompleted: {
            comboBox.currentIndex = pickListIndex;
            console.log("cbx", comboBox.model.count);
            console.log("cbx", codedNameArray);

            listView.onAttributeUpdate(objectName, codedCodeArray[comboBox.currentIndex], nullableValue)

        }
    }
}

