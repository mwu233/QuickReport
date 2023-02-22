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
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

Item {
    id: palette

    //--------------------------------------------------------------------------

    readonly property var kDefaultColors: [
        "black",
        "red",
        "orange",
        "green",
        "#00b2ff",
        "white"
    ]

    property var lineWidths: [
        1,
        3,
        5,
        10,
    ]

    property var textScales: [
        1,
        1.5,
        2,
        2.5
    ]

    //--------------------------------------------------------------------------

    property Settings settings
    property color selectedColor: "red"
    property real selecteWidth: _selectedWidth
    property real _selectedWidth: 3
    property real selectedTextScale: _selectedTextScale
    property real _selectedTextScale: 1.0
    property bool textMode: _selectedTextScale > 0 && _textMode
    property bool _textMode: true
    property bool lineMode: true
    property bool _smartMode: false
    property real buttonSize : 35 * AppFramework.displayScaleFactor
    property bool smartMode: _smartMode
    property bool arrowMode: _arrowMode && !_smartMode && manualMode
    property bool _arrowMode: false
    property bool manualMode: true

    //--------------------------------------------------------------------------

    anchors.fill: parent

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        for (var i = 0; i < kDefaultColors.length; i++) {
            colors.append({
                              color: kDefaultColors[i]
                          });
        }
    }

    //--------------------------------------------------------------------------

    on_SmartModeChanged: {
        if (_smartMode) {
            _arrowMode = false;
        } else {
            if (manualMode) {
                _arrowMode = true;
            } else {
                _arrowMode = false;
            }
        }
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: colors
    }

    //--------------------------------------------------------------------------
}
