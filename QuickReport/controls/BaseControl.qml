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

Rectangle {

    //width: parent.width
    width: Math.min(parent.width-20*app.scaleFactor, 400*app.scaleFactor)
    height: 50*app.scaleFactor
    anchors.topMargin: 20 * app.scaleFactor
    anchors.bottomMargin: 20 * app.scaleFactor
    anchors.horizontalCenter: parent.horizontalCenter
    color: "transparent"

    Label {
        id: fieldAliasLabel

        font.italic: true
        opacity: 0.8
        //anchors.margins: 5*app.scaleFactor
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height*0.4
        width: parent.width
        anchors.bottomMargin: 5*app.scaleFactor
        fontSizeMode: Text.HorizontalFit
        //maximumLineCount: 2
        elide: Text.ElideRight
        wrapMode: Text.Wrap
        color: app.textColor        
    }

}

