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
import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.10

import "../controls" as Control


import "../images"

Column {
    id: column
    spacing: 3 * app.scaleFactor

    width: parent.width

    property alias text: aliasText.text
    property alias textFieldValue: textField.text



    RowLayout{
        anchors {
            left: parent.left
            right: parent.right
        }
        height: aliasText.height

        Text {
            id: aliasText
            text: fieldAlias + (nullableValue?"":"*")
            verticalAlignment: Text.AlignBottom
            color: nullableValue? app.textColor:"red"
            font{
                pixelSize: app.subtitleFontSize
                family: app.customTextFont.name
            }
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(textField.focus) textField.focus = false;
                    if(Qt.inputMethod.visible===true) Qt.inputMethod.hide();
                }
            }
        }


        Control.ImageOverlay{
            Layout.preferredHeight: parent.height
            Layout.preferredWidth: parent.height
            fillMode: Image.PreserveAspectFit
            visible: Qt.platform.os==="ios"&&textField.focus
            source: "../images/ic_keyboard_hide_black_48dp.png"
            opacity: 0.6
            showOverlay: app.isDarkMode
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(textField.focus) textField.focus = false;
                    if(Qt.inputMethod.visible===true) Qt.inputMethod.hide();
                }
            }
        }

        Item{
            Layout.fillHeight: true
            Layout.fillWidth: true
        }

        Text{
            id: limitText
            text: maxlength? textField.text.length+"/"+maxlength : ""
            visible: fieldType == Enums.FieldTypeText
            Layout.preferredWidth: parent.width*0.2
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignBottom
            fontSizeMode: Text.HorizontalFit
            color: app.textColor
            font{
                pixelSize: app.subtitleFontSize*0.8
                family: app.customTextFont.name
            }
            opacity: 0.4
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
    }

    Item {

        height: childrenRect.height
        anchors {
            left: parent.left
            right: parent.right
        }

        IntValidator {
            id: smallIntValidator
            bottom: rangeArray[0]
            top: rangeArray[1]
        }

        IntValidator {
            id: defaultIntValidator
            bottom: rangeArray[0]
            top: rangeArray[1]
        }

        DoubleValidator {
            id: doubleValidator
            bottom: rangeArray[0]
            top: rangeArray[1]
            decimals: 6
        }


        Rectangle{
            id: textFieldContainer
            width: parent.width
            height: textField.height
            border.width: app.isDarkMode? 0:1
            border.color: textField.focus? "#8DAAD0":"lightgray"
            color:app.isDarkMode? Qt.lighter(app.pageBackgroundColor, 1.2) : "white"

            TextField {
                id: textField
                height: implicitHeight * 0.9
                width: parent.width-textField.height
                anchors.top: parent.top
                anchors.left: parent.left
                background: null
                padding: 3 * scaleFactor
                topPadding: 10 * scaleFactor
                bottomPadding: 10 * scaleFactor

                color: acceptableInput ? app.textColor : "red"
                font {
                    bold: false
                    pixelSize: app.subtitleFontSize
                    family: app.customTextFont.name

                }

                validator: {
                    if(Enums.FieldTypeInt16 == fieldType) {
                        return smallIntValidator
                    }
                    if(Enums.FieldTypeInt32 == fieldType) {
                        return defaultIntValidator
                    }
                    if(Enums.FieldTypeFloat64 == fieldType) {
                        return doubleValidator
                    }
                    return null
                }


                placeholderTextColor: app.isDarkMode? "white":"gray"
                maximumLength: maxlength? fileType == Enums.FieldTypeDate? Number.MAX_VALUE:maxlength: fieldType == Enums.FieldTypeInt32? 18: Number.MAX_VALUE

                placeholderText: fieldType == Enums.FieldTypeText ? qsTr("Enter some text") : fieldType == Enums.FieldTypeDate ? qsTr("Pick a Date") : (qsTr("Enter a number")+" ("+rangeArray[0]+"~"+rangeArray[1]+")")

                text:  fieldType == Enums.FieldTypeDate ? attributesArray[fieldName] > "" ? new Date (attributesArray[fieldName]).toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate) : "" : (attributesArray[fieldName] || "")

                inputMethodHints: (fieldType == Enums.FieldTypeText || fieldType == Enums.FieldTypeDate) ? Qt.ImhNone : Qt.ImhFormattedNumbersOnly

                enabled: fieldType == Enums.FieldTypeDate ? false : true

                onTextChanged: {
                    if (fieldType != Enums.FieldTypeDate){
                        attributesArray[fieldName] = text;

                        if(text && !acceptableInput)
                            isRangeValidated = false
                        else
                            isRangeValidated = true

                        if(text>"" && text!=null && nullableValue==false && acceptableInput){
                            requiredAttributes[fieldName] = text;
                        } else{
                            delete requiredAttributes[fieldName];
                        }
                        hasAllRequired = numOfRequired==Object.keys(requiredAttributes).length
                    }
                }

                onEditingFinished: {
                    textField.focus = false;
                }

                onFocusChanged: {
                    if(focus){
                        if(fieldType === Enums.FieldTypeText && maximumLength > 249){
                            textField.focus = false;
                        } else if(fieldType === Enums.FieldTypeText && maximumLength > 49){
                            textField.focus = false;
                        }
                    }
                }

                Component.onCompleted: {
                    if(!requiredAttributes)requiredAttributes={};

                    if(app.isFromSaved && JSON.stringify(app.attributesArray[fieldName])!=null&&JSON.stringify(app.attributesArray[fieldName])!=""){
                        text = (fieldType == Enums.FieldTypeDate ? attributesArray[fieldName] > "" ? new Date (attributesArray[fieldName]).toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate) : "" : (attributesArray[fieldName] || ""))
                    }
                    if (fieldType != Enums.FieldTypeDate)
                        attributesArray[fieldName] = text;

                    if(text>"" && text!=null && nullableValue==false && acceptableInput){
                        requiredAttributes[fieldName] = text;
                    } else if(requiredAttributes && requiredAttributes[fieldName]) {
                        delete requiredAttributes[fieldName];
                    }
                    hasAllRequired = numOfRequired==Object.keys(requiredAttributes).length;
                }

                property int requiredNum: numOfRequired

                onRequiredNumChanged: {
                    hasAllRequired = numOfRequired==Object.keys(requiredAttributes).length;
                }
            }
        }
    }
}
