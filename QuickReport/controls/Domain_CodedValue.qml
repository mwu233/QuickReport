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
import Esri.ArcGISRuntime 100.10

import QtQuick.Controls.Material 2.2

Column {
    id: column

    width: parent.width

    anchors{
        left: parent.left
        right:parent.right
    }

    spacing: 3 * app.scaleFactor

    Text {
        text: fieldAlias + (nullableValue?"":"*")

        anchors {
            left: parent.left
            right: parent.right
        }
        color: nullableValue ? app.textColor:"red"
        font {
            pixelSize: app.subtitleFontSize
            family: app.customTextFont.name
        }
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        maximumLineCount: 2
    }

    ComboBox {
        id: comboBox
        model: codedNameArray
        anchors{
            left: parent.left
            right:parent.right
        }
        height: 50 * scaleFactor
        width: parent.width * 0.6

        Material.accent: app.headerBackgroundColor

        enabled: !isSubTypeField

        contentItem:Text {
            text:comboBox.displayText
            color: app.isDarkMode? "white": app.textColor

            font:comboBox.font
            verticalAlignment: Text.AlignVCenter
            padding: 3 * scaleFactor

        }

        indicator: Canvas {
            id: canvas
            x: comboBox.width - width - comboBox.rightPadding
            y: comboBox.topPadding + (comboBox.availableHeight - height) / 2
            width: 12
            height: 8
            contextType: "2d"


            Connections {
                target: comboBox
                onPressedChanged: canvas.requestPaint()
            }

            onPaint: {
                context.reset();

                context.moveTo(0, 0);
                context.lineTo(width, 0);
                context.lineTo(width / 2, height);
                context.closePath();
                context.fillStyle = app.black_87;
                context.fill();
            }
        }


        background: Rectangle {
            id: rectdomain
            width: comboBox.width
            height: comboBox.height
            border.width: app.isDarkMode? 0:1
            color:Qt.lighter(app.pageBackgroundColor, 1.2)

            border.color: comboBox.focus? "#8DAAD0":"lightgray"

        }


        font: {
            pixelSize: app.textFontSize
            family: app.customTextFont.name
            color:app.black_87
        }

        onActivated: {
            attributesArray[fieldName] = codedCodeArray[comboBox.currentIndex];
            if((codedCodeArray[comboBox.currentIndex]>""||codedCodeArray[comboBox.currentIndex]!=null) && nullableValue==false){
                requiredAttributes[fieldName] = codedCodeArray[comboBox.currentIndex];
            } else{
                delete requiredAttributes[fieldName];
            }
            hasAllRequired = numOfRequired==Object.keys(requiredAttributes).length
        }
    }

    Component.onCompleted: {
        if(app.isFromSaved){
            for(var i=0; i<codedCodeArray.length;i++){
                var name = codedCodeArray[i];
                if(attributesArray[fieldName] === name){
                    comboBox.currentIndex = i;
                    console.log("comboBox.currentIndex", comboBox.currentIndex, name, attributesArray[fieldName])
                    break;
                }
            }
        }
        else if ( isSubTypeField ){
            comboBox.currentIndex = pickListIndex;
        }
        else {
            if ( hasPrototype ) {
                comboBox.currentIndex = codedNameArray.indexOf( codedNameArray[codedCodeArray.indexOf( defaultValue.toString() )]);
            }
            else {
                try {
                    var fieldIndx = parseInt(attributesArray[fieldName])
                    var tempIndex = -1
                    if(fieldIndx >= 0)
                         tempIndex = codedCodeArray.indexOf(attributesArray[fieldName])
                    else
                    {
                     tempIndex = codedCodeArray.indexOf(attributesArray[fieldName])
                    var defaultIndex = codedNameArray.indexOf[codedCodeArray.indexOf(defaultValue)]
                    //comboBox.currentIndex = tempIndex>-1? tempIndex : defaultIndex;

                    }
                     comboBox.currentIndex = tempIndex>-1? tempIndex : defaultIndex;

                } catch(e) {

                }
            }
        }

        if(!requiredAttributes)requiredAttributes={};
        attributesArray[fieldName] = codedCodeArray[comboBox.currentIndex];
        if((codedCodeArray[comboBox.currentIndex]!=null||codedCodeArray[comboBox.currentIndex]>"")&&codedCodeArray[comboBox.currentIndex]!=null && nullableValue==false){
            requiredAttributes[fieldName] = codedCodeArray[comboBox.currentIndex];
        } else{
            delete requiredAttributes[fieldName];
        }
        hasAllRequired = numOfRequired==Object.keys(requiredAttributes).length
    }
}
