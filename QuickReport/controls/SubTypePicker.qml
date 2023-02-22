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
import QtMultimedia 5.2
import Qt.labs.folderlistmodel 2.1

import ArcGIS.AppFramework 1.0

import Esri.ArcGISRuntime 100.10
import "../"

Item {
    focus: true
    property int indexSelected:app.pickListIndex
    property bool itemChecked: indexSelected  > -1

    ListView {
        id: typeList
        clip: true
        spacing: 0
        width: parent.width - app.units(32)
        height: parent.height
        //anchors.topMargin: 20*app.scaleFactor
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        model: theFeatureTypesModel

        ScrollBar.vertical: ScrollBar {
            width: 8 * app.scaleFactor
        }

        delegate: Component {

            id: issueListViewDelegate

            Rectangle {
                id: item
                width: parent.width * 0.9
                height: 50 * AppFramework.displayScaleFactor
                clip: true
                color: app.pageBackgroundColor
                anchors.horizontalCenter: parent.horizontalCenter
                objectName: value                

                RowLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: parent.height * 0.8
                    spacing: 25 * AppFramework.displayScaleFactor

                    Image {
                        id: typeThumbnail
                        source: imageUrl
                        Layout.preferredHeight: app.units(24)
                        Layout.preferredWidth: height
                        fillMode: Image.PreserveAspectFit
                        enabled: (status == Image.Error || source=="") ? false : true
                        visible: enabled
                    }

                    Text {
                        text: label
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.pixelSize: app.textFontSize
                        font.family: app.customTextFont.name
                        color: app.textColor
                        Layout.fillWidth: true
                        fontSizeMode: Text.VerticalFit
                        verticalAlignment: Text.AlignVCenter                        
                    }

                    Image {
                        Layout.preferredHeight: app.units(20)
                        Layout.preferredWidth: app.units(20)
                        source: "../images/tick.png"
                        horizontalAlignment: Text.AlignRight
                        visible: index == indexSelected
                    }
                }

                Rectangle {
                    width: parent.width
                    height: app.scaleFactor
                    anchors.bottom: parent.bottom
                    color: Qt.lighter("gray")
                    opacity: app.isDarkMode? 0.5:1.0
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        indexSelected = index
                    }
                }
            }
        }
    }

    function getProtoTypeAndSubTypeDomains() {
        console.log("Prototypes length", app.featureTypes.length)
        featureType = app.featureTypes[indexSelected];

        console.log("!!!", JSON.stringify(featureType.templates[0].prototype, undefined, 2));

        var domains = featureType.domains;
        console.log("fields", JSON.stringify(app.fields))

        for ( var j = 0; j < app.fields.length; j++ ) {
            if ( fields[j].name === featureServiceManager.jsonSchema.typeIdField ) {
                theFeatureAttributesModel.setProperty(j, "isSubTypeField", true);
            }
        }
        pickListIndex = indexSelected;
        backToPreviousPage = false;

    }
}
