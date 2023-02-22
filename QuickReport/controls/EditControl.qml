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
    property date exampleDate: new Date(272469600000);
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
                    if(textAreaContainer.visible) textArea.resetTextArea();
                    if(textField.focus) textField.focus = false;
                    if(Qt.inputMethod.visible===true) Qt.inputMethod.hide();
                }
            }
        }

        Control.ImageOverlay {
            Layout.preferredHeight: parent.height
            Layout.preferredWidth: parent.height
            fillMode: Image.PreserveAspectFit
            visible: Qt.platform.os==="ios"&&(textAreaContainer.visible || textField.focus)
            source: "../images/ic_keyboard_hide_black_48dp.png"
            opacity: 0.6
            showOverlay: app.isDarkMode
            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(textAreaContainer.visible) textArea.resetTextArea();
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
            text: maxlength? textField.text.trim().length+"/"+maxlength : ""
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
        width:parent.width
        anchors {
            left: parent.left
            right: parent.right
        }

        IntValidator {
            id: smallIntValidator
            bottom: -32768
            top: 32767
        }

        IntValidator {
            id: defaultIntValidator
            bottom: -2147483648
            top: 2147483647
        }

        DoubleValidator {
            id: doubleValidator
            bottom: -2.2E38
            top: 1.8E38
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
               padding:3 * scaleFactor
               topPadding: 10 * scaleFactor
               bottomPadding: 10 * scaleFactor

                height:implicitHeight
                width: parent.width


                font {
                    bold: false
                    pixelSize: app.subtitleFontSize
                    family: app.customTextFont.name

                }

                background: null


                color: acceptableInput ? app.textColor : "red"

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


                maximumLength: maxlength? fieldType == Enums.FieldTypeDate? Number.MAX_VALUE:maxlength: fieldType == Enums.FieldTypeInt32? 18: Number.MAX_VALUE

                placeholderText: fieldType == Enums.FieldTypeText ? qsTr("Enter some text") : fieldType == Enums.FieldTypeDate ? qsTr("Pick a Date") : qsTr("Enter a number")
                placeholderTextColor: app.isDarkMode? "white":"gray"

                text:  fieldType == Enums.FieldTypeDate ?(attributesArray[fieldName] > "" ? new Date (attributesArray[fieldName]).toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate) : "") : (attributesArray[fieldName] || "")

                inputMethodHints: (fieldType == Enums.FieldTypeText || fieldType == Enums.FieldTypeDate) ? Qt.ImhNone : Qt.ImhFormattedNumbersOnly

                enabled: fieldType == Enums.FieldTypeDate ? false : true
                onTextChanged: {
                    if (fieldType != Enums.FieldTypeDate){
                        attributesArray[fieldName] = text;
                        if(text>""&&text!=null&&nullableValue==false){
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
                            textAreaContainer.visible = true;
                            textAreaContainer.height = textField.height*5;
                            textField.focus = false;
                            textArea.focus = true;
                        } else if(fieldType === Enums.FieldTypeText && maximumLength > 49){
                            textAreaContainer.visible = true;
                            textAreaContainer.height = textField.height*2;
                            textField.focus = false;
                            textArea.focus = true;
                        } else {
                            textArea.focus = false;
                        }
                    }
                }

                Component.onCompleted: {
                    //listView.onAttributeUpdate(objectName, text)
                    if(!requiredAttributes)requiredAttributes={};
                    console.log("JSON app.attributesArray::",JSON.stringify(app.attributesArray))
                    if(app.isFromSaved && JSON.stringify(app.attributesArray[fieldName])!=null&&JSON.stringify(app.attributesArray[fieldName])!=""){
                        text = (fieldType == Enums.FieldTypeDate ? attributesArray[fieldName] > "" ? new Date (attributesArray[fieldName]).toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate) : "" : (attributesArray[fieldName] || ""))
                    }
                    if (fieldType != Enums.FieldTypeDate)
                        attributesArray[fieldName] = text;

                    if(text>""&&text!=null&&nullableValue==false){
                        requiredAttributes[fieldName] = text;
                    } else if(requiredAttributes && requiredAttributes[fieldName]) {
                        delete requiredAttributes[fieldName];
                    }
                    hasAllRequired = numOfRequired==Object.keys(requiredAttributes).length
                }

                property int requiredNum: numOfRequired

                onRequiredNumChanged: {
                    hasAllRequired = numOfRequired==Object.keys(requiredAttributes).length;
                }

            }
            MouseArea{
                anchors.fill:parent
                enabled: fieldType === Enums.FieldTypeDate
                onClicked: {
                    if(fieldType === Enums.FieldTypeDate)
                    {
                    app.calendarPicker = app.calendarDialogComponent.createObject(app);
                    calendarPicker.attributesId = fieldName
                    calendarPicker.swipeViewIndex = 0;
                    calendarPicker.selectedDateAndTime = new Date();
                    calendarPicker.updateDateAndTime();
                    calendarPicker.visible = true;
                    }


                }
            }

         Rectangle{

            visible: fieldType == Enums.FieldTypeDate ? true : false
            radius: 2*AppFramework.displayScaleFactor
            width: frame.width
            height: frame.height
            clip: true
            color: Qt.lighter(app.pageBackgroundColor, 1.2)
            border.width: app.isDarkMode? 0:1
            border.color: "#888"
            anchors {
                right: textFieldContainer.right
                top: textField.top
                bottom: textField.bottom
            }

            Button {
                anchors.fill:parent

                background: Rectangle{
                    radius: 2*AppFramework.displayScaleFactor
                    width: parent.width - 50 * scaleFactor
                    height: parent.height
                    clip: true
                    color: Qt.lighter(app.pageBackgroundColor, 1.2)

                }

                visible: fieldType == Enums.FieldTypeDate ? true : false
                enabled: visible
                onClicked: {
                    app.calendarPicker = app.calendarDialogComponent.createObject(app);
                    calendarPicker.attributesId = fieldName
                    calendarPicker.swipeViewIndex = 0;
                    calendarPicker.selectedDateAndTime = new Date();
                    calendarPicker.updateDateAndTime();
                    calendarPicker.visible = true;
                }

                Control.ImageOverlay {
                    anchors.fill: parent
                    anchors.margins: app.scaleFactor
                    fillMode: Image.PreserveAspectFit
                    source: "../images/ic_event_black_48dp.png"
                    opacity: 0.6
                    showOverlay: app.isDarkMode
                }
            }
        }

         Rectangle{
            id:frame
            height: textField.height
            width: textField.height - 5 * scaleFactor
            anchors.right: textFieldContainer.right
            anchors.rightMargin: 1 * scaleFactor
            anchors.top: textField.top

            radius: width/2
            color:"transparent"
            visible: textField.text.length>0 && fieldType != Enums.FieldTypeDate && (textAreaContainer.visible || textField.focus)

            Rectangle{
                height: parent.height*0.6
                width: parent.height*0.6
                anchors.centerIn: parent
                radius: width/2
                color: app.isDarkMode? Qt.lighter(app.pageBackgroundColor, 1.2):Qt.darker(app.pageBackgroundColor, 1.2)
                opacity: 0.8

                Image{
                    anchors.fill: parent
                    source:"../images/ic_clear_white_48dp.png"
                    fillMode: Image.PreserveAspectFit
                }
            }

            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(!textArea.visible)textField.text = ""
                    else textArea.text=""
                }
            }
        }


        }


        Rectangle{
            id: textAreaContainer
            border.width: 1
            border.color: "#8DAAD0"
            color: app.isDarkMode? Qt.lighter(app.pageBackgroundColor, 1.2): "white"
            width: textFieldContainer.width
            height: textField.height

            visible: false

            onVisibleChanged: {
                isShowTextArea = visible
            }

            TextArea {
                id: textArea
                width: parent.width
                height: parent.height
                anchors.left: parent.left
                anchors.top: parent.top
                padding:3 * scaleFactor

                property string previousText: text
                property int maximumLength: maxlength? maxlength: Number.MAX_VALUE

                wrapMode: TextEdit.Wrap
                text:  fieldType == Enums.FieldTypeDate ? attributesArray[fieldName] > "" ? new Date (attributesArray[fieldName]).toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate) : "" : (attributesArray[fieldName] || "")
                focus: false
                background: Rectangle{
                    anchors.fill: parent
                    color:app.isDarkMode? Qt.lighter(app.pageBackgroundColor, 1.2):"transparent"
                }

                color: app.isDarkMode? "white": app.textColor


                font {
                    bold: false
                    pixelSize: app.subtitleFontSize
                    family: app.customTextFont.name
                }

                onEditingFinished: {
                    resetTextArea();
                }

                onTextChanged: {
                    if (text.length > maximumLength) {
                        var cursor = cursorPosition;
                        text = previousText;
                        if (cursor > text.length) {
                            cursorPosition = text.length;
                        } else {
                            cursorPosition = cursor-1;
                        }
                    }
                    previousText = text

                    if (fieldType != Enums.FieldTypeDate){
                        attributesArray[fieldName] = text;
                        if(text>""&&text!=null&&nullableValue==false){
                            requiredAttributes[fieldName] = text;
                        } else{
                            delete requiredAttributes[fieldName];
                        }
                        hasAllRequired = numOfRequired==Object.keys(requiredAttributes).length
                        textField.text = Qt.binding(function(){return fieldType == Enums.FieldTypeDate ? attributesArray[fieldName] > "" ? new Date (attributesArray[fieldName]).toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate) : "" : (attributesArray[fieldName] || "")})

                    }
                }

                Rectangle{
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    width: textField.height-1
                    height: parent.height-2
                    anchors.verticalCenter: parent.verticalCenter
                    color: app.isDarkMode? Qt.lighter(app.pageBackgroundColor, 1.2): "transparent"
                }

                function resetTextArea(){
                    textAreaContainer.height = textField.height
                    textAreaContainer.visible = false;
                }
            }
        }

     /*   Rectangle{
            id:frame
            height: textField.height
            width: textField.height - 5 * scaleFactor
            anchors.right: textFieldContainer.right
            anchors.rightMargin: 1 * scaleFactor
            anchors.top: textField.top

            radius: width/2
            color:"transparent"
            visible: textField.text.length>0 && fieldType != Enums.FieldTypeDate && (textAreaContainer.visible || textField.focus)

            Rectangle{
                height: parent.height*0.6
                width: parent.height*0.6
                anchors.centerIn: parent
                radius: width/2
                color: app.isDarkMode? Qt.lighter(app.pageBackgroundColor, 1.2):Qt.darker(app.pageBackgroundColor, 1.2)
                opacity: 0.8

                Image{
                    anchors.fill: parent
                    source:"../images/ic_clear_white_48dp.png"
                    fillMode: Image.PreserveAspectFit
                }
            }

            MouseArea{
                anchors.fill: parent
                onClicked: {
                    if(!textArea.visible)textField.text = ""
                    else textArea.text=""
                }
            }
        }
*/
       /* Rectangle{

            visible: fieldType == Enums.FieldTypeDate ? true : false
            radius: 2*AppFramework.displayScaleFactor
            width: frame.width
            height: frame.height
            clip: true
            color: Qt.lighter(app.pageBackgroundColor, 1.2)
            border.width: app.isDarkMode? 0:1
            border.color: "#888"
            anchors {
                right: textFieldContainer.right
                top: textField.top
                bottom: textField.bottom
            }

            Button {
                anchors.fill:parent

                background: Rectangle{
                    radius: 2*AppFramework.displayScaleFactor
                    width: parent.width - 50 * scaleFactor
                    height: parent.height
                    clip: true
                    color: Qt.lighter(app.pageBackgroundColor, 1.2)

                }

                visible: fieldType == Enums.FieldTypeDate ? true : false
                enabled: visible
                onClicked: {
                    app.calendarPicker = app.calendarDialogComponent.createObject(app);
                    calendarPicker.attributesId = fieldName
                    calendarPicker.swipeViewIndex = 0;
                    calendarPicker.selectedDateAndTime = new Date();
                    calendarPicker.updateDateAndTime();
                    calendarPicker.visible = true;
                }

                Control.ImageOverlay {
                    anchors.fill: parent
                    anchors.margins: app.scaleFactor
                    fillMode: Image.PreserveAspectFit
                    source: "../images/ic_event_black_48dp.png"
                    opacity: 0.6
                    showOverlay: app.isDarkMode
                }
            }
        }
    */
    }


    Connections {
        target: calendarPicker

        function onAccepted() {
            if(calendarPicker.attributesId === fieldName){
                textField.text = calendarPicker.selectedDateAndTime.toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate);
                attributesArray[fieldName] = calendarPicker.dateMilliseconds;
                console.log("///", textField.text, attributesArray[fieldName]);
                if(calendarPicker.dateMilliseconds>0&&calendarPicker.dateMilliseconds!=null&&nullableValue==false){
                    requiredAttributes[fieldName] = calendarPicker.dateMilliseconds;
                } else{
                    delete requiredAttributes[fieldName];
                }
                hasAllRequired = numOfRequired==Object.keys(requiredAttributes).length
            }
        }
    }
}
