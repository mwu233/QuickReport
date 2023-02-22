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
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import Esri.ArcGISRuntime 100.10
import QtQuick.Controls.Material 2.1

import "../controls/"


Rectangle {
    id: addDetailsPage
    objectName: "addDetailsPage"
    width: parent ? parent.width :0
    height: parent ?parent.height:0
    color: app.pageBackgroundColor
    signal next(string message)
    signal previous(string message)

    property bool isBusy: false
    property bool allDone: false

    property date calendarDate: new Date()

    property string domainFieldName: ""

    property bool backToPreviousPage: true
    property string type: "appview"
    property var webPage
    property var myFavoriteEntries:({})
    Material.accent:Material.Grey

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        spacing: 16*app.scaleFactor

        Rectangle {
            id: createPage_headerBar
            Layout.alignment: Qt.AlignTop
            color: app.headerBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50 * app.scaleFactor

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    mouse.accepted = false
                }
            }

            ImageButton {
                source: "../images/ic_keyboard_arrow_left_white_48dp.png"
                height: 30 * app.scaleFactor
                width: 30 * app.scaleFactor
                checkedColor : "transparent"
                pressedColor : "transparent"
                hoverColor : "transparent"
                glowColor : "transparent"
                anchors.rightMargin: 10
                anchors.leftMargin: 10
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                onClicked: {
                    var stackitem = stackView.get(stackView.depth - 2) //var stackitem = stackView.get(stackView.depth - 2)
                    if(stackitem.objectName === "summaryPage")
                    {
                        if(attributesPage.isRangeValidated)
                        {
                            app.hasAllRequired = attributesPage.hasAllRequired && attributesPage.isRangeValidated
                            app.populateSummaryObject()
                            // app.steps--;
                            previous("")
                        }
                        else
                        {
                            alertBox.text = qsTr("Error");
                            alertBox.informativeText = qsTr("Range not validated.")+"\n";
                            alertBox.visible = true;
                        }

                    }
                    else
                    {
                        app.steps--;
                        if(stackitem.initModel)
                        stackitem.initModel()
                        previous("")
                    }


                }
            }

            CarouselSteps{
                id:carousal
                height: parent.height
                anchors.centerIn: parent
                items: app.numOfSteps
                currentIndex: app.steps
            }

            ImageButton {
                source: "../images/more.png"
                height: 30 * app.scaleFactor
                width: 30 * app.scaleFactor
                checkedColor : "transparent"
                pressedColor : "transparent"
                hoverColor : "transparent"
                glowColor : "transparent"
                anchors.rightMargin: 10
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    console.log("more onClicked event start")
                    more.updateMenuItemsContent ()
                    more.open()

                }
            }

            PopupMenu{
                id:more
                defaultMargin: app.defaultMargin
                backgroundColor: Qt.lighter(blk_000)//"#FFFFFF"
                highlightColor: Qt.darker(backgroundColor, 1.1)
                textColor: app.textColor
                primaryColor: app.primaryColor
                menuItems: [


                ]
                Material.primary: app.primaryColor
                Material.background: backgroundColor
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                width:defaultContentWidth

                x: parent.width - width - app.baseUnit
                y: 0 + app.baseUnit

                // TO-DO
                onMenuItemSelected: {
                    switch (itemLabel) {
                    case app.clear_entries:
                        clearFavoritesDialog.visible = true

                        break;
                    case app.save_entries:
                        var favoriteObject = {}
                        var categoryObj = {}
                        var editObject = {}
                        for(var i=0; i<theFeatureAttributesModel.count; i++) {
                            var item = theFeatureAttributesModel.get(i);
                            var fieldName = item["fieldName"]
                            var fieldVal = attributesArray[fieldName]
                            //check if empty
                            if(fieldVal !== null && fieldVal !== undefined)
                            {
                                var  modfieldVal = fieldVal.toString().trim()

                                if(modfieldVal > "")
                                    editObject[fieldName] = fieldVal
                            }

                        }


                        favoriteObject.layerName = app.featureLayerBeingEdited
                        favoriteObject.category = "default"
                        if(Object.keys(editObject).length > 0)
                        {

                            favoriteObject.editsJson = JSON.stringify(editObject)
                            app.saveFavorites(favoriteObject)

                            toastMessage.show(app.entries_saved)

                            updateMenuItemsContent()
                            app.loadFavorites()
                        }

                        break;
                    case app.paste_entries:
                        var favoriteObj = favoriteEntries[app.featureLayerBeingEdited]
                        for(var k=0; k<theFeatureAttributesModel.count; k++) {
                            var obj = theFeatureAttributesModel.get(k);
                            var fldName = obj["fieldName"]
                            var entries = favoriteObj["default"]
                            var jsonObj = JSON.parse(entries)
                            var newVal = jsonObj[fldName]


                            if(newVal !== undefined && newVal !== null)
                            {
                                attributesArray[fldName] = newVal
                            }
                        }
                        app.attributesChanged()

                        break;

                    }

                }

                function clearFavoriteEntries()
                {

                }

                function updateMenuItemsContent () {
                    var schemaURL = featureServiceURL + "/" + app.featureLayerId[0];
                    var json = featureServiceManager.getLocalSchema(schemaURL);
                    app.featureLayerBeingEdited = json.name;
                    var layername = app.featureLayerBeingEdited;

                    // layername = ""
                    if(layername > "")
                    {
                        console.log("layername: " + layername)

                        var favorites = null
                        var favoriteCategories = app.favoriteEntries[layername]
                        if(favoriteCategories && favoriteCategories["default"])
                        {
                            var  favorite_cat = JSON.parse(favoriteCategories["default"])
                            if(favorite_cat)
                                favorites = favorite_cat
                        }
                        if(favorites)
                        {
                            console.log("favorites: " + favorites)

                            if(Object.keys(favorites).length > 0)
                            {
                                myFavoriteEntries = favorites
                                more.removeItemFromMenuList({"itemLabel": app.save_entries})
                                more.appendUniqueItemToMenuList({"itemLabel": app.paste_entries})
                                more.appendUniqueItemToMenuList({"itemLabel": app.clear_entries})
                                more.height= app.units(16)  * 4 * scaleFactor + app.units(32) * scaleFactor


                            }
                            else
                            {
                                more.removeItemFromMenuList({"itemLabel": app.paste_entries})
                                more.removeItemFromMenuList({"itemLabel": app.clear_entries})
                                more.appendUniqueItemToMenuList({"itemLabel": app.save_entries})
                                more.height= app.units(16)  * 2 * scaleFactor + app.units(32) * scaleFactor

                            }
                        }
                        else
                        {
                            more.removeItemFromMenuList({"itemLabel": app.paste_entries})
                            more.removeItemFromMenuList({"itemLabel": app.clear_entries})
                            more.appendUniqueItemToMenuList({"itemLabel": app.save_entries})
                            more.height= app.units(16) * 2 * scaleFactor + app.units(32) * scaleFactor
                            console.log("removeItem?")
                        }

                    }

                    console.log("method : more.updateMenu() starts")
                    more.updateMenu()
                }





            }

        }

        RowLayout{
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: createPage_titleText.height
            Layout.alignment: Qt.AlignHCenter
            spacing: 5*app.scaleFactor
            Text {
                id: createPage_titleText
                text: qsTr("Add Details")
                textFormat: Text.StyledText
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: app.titleFontSize
                font.family: app.customTitleFont.name
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: app.textColor
                maximumLineCount: 1
                elide: Text.ElideRight
                fontSizeMode: Text.Fit
            }

            ImageOverlay{
                Layout.preferredHeight: Math.min(36*app.scaleFactor, parent.height)*0.9
                Layout.preferredWidth: Math.min(36*app.scaleFactor, parent.height - (5*app.scaleFactor))*0.9
                source: "../images/ic_info_outline_black_48dp.png"
                visible: app.isHelpUrlAvailable
                overlayColor: app.textColor
                showOverlay: true
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        if(app.helpPageUrl && validURL(app.helpPageUrl))
                            app.openWebView(0, {  url: app.helpPageUrl });
                        else
                        {
                            var component = webPageComponent;
                            webPage = component.createObject(addDetailsPage);
                            webPage.openSectionID(""+4)
                        }
                        //app.openWebView(1, { pageId: addDetailsPage, url: "" + 4 });
                    }
                }
            }
        }

        AttributesPage {
            id: attributesPage
            Layout.preferredWidth: parent.width-32*app.scaleFactor
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.maximumWidth: 600*app.scaleFactor
        }

        Rectangle {
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50*app.scaleFactor
            Layout.maximumWidth: Math.min(parent.width*0.95, 600*scaleFactor);
            Layout.alignment: Qt.AlignHCenter
            color: app.pageBackgroundColor
            Layout.margins: 8*app.scaleFactor
            radius: 4*app.scaleFactor
            clip: true
            visible: !Qt.inputMethod.visible || !attributesPage.isShowTextArea
            Layout.bottomMargin: app.isIPhoneX ? 28 * app.scaleFactor : 8 * scaleFactor

            RowLayout{
                anchors.fill: parent
                spacing: 8 * app.scaleFactor

                CustomButton {

                    id: nextButton
                    buttonText: qsTr("Summary")
                    buttonColor: attributesPage.isRangeValidated? app.buttonColor:"red"//(attributesPage.hasAllRequired && attributesPage.isRangeValidated)? app.buttonColor:"red"
                    buttonFill:attributesPage.isRangeValidated // attributesPage.hasAllRequired && attributesPage.isRangeValidated
                    Layout.fillWidth: true
                    buttonWidth: Math.min(parent.width, 600 * scaleFactor)
                    buttonHeight: 50 * app.scaleFactor
                    visible: app.showSummary


                    MouseArea {
                        anchors.fill: parent
                        enabled: true
                        onClicked: {
                            var isValidGeo = checkGeometry()
                            app.isReadyForSubmit = attributesPage.hasAllRequired && isValidGeo && attributesPage.isRangeValidated;
                            if(attributesPage.isRangeValidated)
                                next("showSummary")
                            else
                            {
                                alertBox.text = qsTr("Error");
                                alertBox.informativeText = qsTr("Range not validated.")+"\n";
                                alertBox.visible = true;
                            }
                        }

                    }
                }

                CustomButton {
                    buttonText: qsTr("Save")
                    buttonColor: app.buttonColor
                    buttonFill: false
                    buttonWidth: submitBtn.visible ? ((parent.width-parent.spacing)/2) : parent.width
                    buttonHeight: 50*app.scaleFactor
                    Layout.fillWidth: true
                    visible:!app.showSummary


                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var isValidGeo = false;
                            if(captureType === "line" && polylineObj && polylineObj.parts.part(0) && polylineObj.parts.part(0).pointCount>=2){
                                isValidGeo = true;
                            }else if(captureType === "area" && polygonObj && polygonObj.parts.part(0) && polygonObj.parts.part(0).pointCount>=3){
                                isValidGeo = true;
                            }else if(captureType === "point") {
                                isValidGeo = true;
                            }
                            console.log("isValidGeo", isValidGeo)
                            isReadyForSubmit = attributesPage.hasAllRequired && isValidGeo && attributesPage.isRangeValidated;
                            next("save")
                        }
                    }
                }

                CustomButton {
                    id: submitBtn

                    buttonText: qsTr("Submit")
                    buttonColor: (attributesPage.hasAllRequired && attributesPage.isRangeValidated)? app.buttonColor:"red"
                    buttonFill: attributesPage.hasAllRequired && attributesPage.isRangeValidated
                    buttonWidth: (parent.width-parent.spacing)/2
                    buttonHeight: 50 * app.scaleFactor
                    Layout.fillWidth: true
                    visible: Networking.isOnline && !app.showSummary
                    MouseArea {
                        anchors.fill: parent
                        enabled: attributesPage.hasAllRequired && attributesPage.isRangeValidated
                        onClicked: {
                            if(captureType === "line" && !(polylineObj.parts.part(0) && polylineObj.parts.part(0).pointCount>=2)){
                                alertBox.text = qsTr("Unable to submit");
                                alertBox.informativeText = qsTr("Add a valid map path.")+"\n";
                                alertBox.visible = true;
                            }else if(captureType === "area" && !(polygonObj.parts.part(0) && polygonObj.parts.part(0).pointCount>=3)){
                                alertBox.text = qsTr("Unable to submit");
                                alertBox.informativeText = qsTr("Add a valid map area.")+"\n";
                                alertBox.visible = true;
                            }else{

                                if (networkConfig.isWIFI || networkConfig.isLAN ){
                                    // on wifi or LAN
                                    next("submit");


                                }else{
                                    //on cellular network
                                    if (checkAttachmentSize()){
                                        attachmentSizeDialog.visible = true;
                                    }else{
                                        next("submit");
                                    }
                                }





                            }
                        }
                    }
                }

            }
        }

    }


    DropShadow {
        source: createPage_headerBar
        width: source.width
        height: source.height
        cached: false
        radius: 5.0
        samples: 16
        color: "#80000000"
        smooth: true
        visible: source.visible
    }


    ConfirmBox{
        id: clearFavoritesDialog
        anchors.fill: parent
        text:app.clear_toast
        onAccepted: {
            app.clearFavorites()
            favoriteEntries[app.featureLayerBeingEdited] = {}
            app.loadFavorites()
            more.updateMenuItemsContent()

        }
    }
    ConfirmBox{
        id: attachmentSizeDialog
        anchors.fill: parent
        text: dataWarningMessage
        onAccepted: {
            next("submit");
        }
    }

    FileInfo{
        id: fileInfo
    }

    Component.onCompleted: {
        var stackitem = stackView.get(stackView.depth - 2)
        if(stackitem.objectName === "summaryPage")
        {
            nextButton.visible = false
            carousal.visible = false

        }

    }

    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            back()
            event.accepted = true;
        }
    }

    function checkAttachmentSize(){
        if (app.appModel.count === 0) return false;
        //console.log("no of attachments " + app.appModel.count);
        var totalAttachmentSize = 0;
        for(var i=0;i<app.appModel.count;i++){
            fileInfo.filePath = app.appModel.get(i).path.replace("file://","");;
            totalAttachmentSize = totalAttachmentSize + fileInfo.size;
        }
        console.log("total Attachment size is " + totalAttachmentSize);
        if (totalAttachmentSize > 10000000) return true;
        return false;
    }


    //================================================================================
    function checkGeometry()
    {
        var isValidGeo = false;
        if(captureType === "line" && polylineObj && polylineObj.parts.part(0) && polylineObj.parts.part(0).pointCount>=2){
            isValidGeo = true;
        }else if(captureType === "area" && polygonObj && polygonObj.parts.part(0) && polygonObj.parts.part(0).pointCount>=3){
            isValidGeo = true;
        }else if(captureType === "point") {
            isValidGeo = true;
        }
        return isValidGeo
    }

    function back(){
        if(webPage !== null && webPage!== undefined && webPage.visible === true){
            webPage.close();
            app.focus = true;
        } else if(Qt.inputMethod.visible === true){
            Qt.inputMethod.hide();
            app.focus = true;
        } else if(app.draftSaveDialog == null || app.draftSaveDialog.visible === false){
            var stackitem = stackView.get(stackView.depth - 2)
            if(stackitem.objectName === "summaryPage")
            {
                if(attributesPage.isRangeValidated)
                {
                    app.hasAllRequired = attributesPage.hasAllRequired && attributesPage.isRangeValidated
                    app.populateSummaryObject()
                    // app.steps--;
                    previous("")
                }
                else
                {
                    alertBox.text = qsTr("Error");
                    alertBox.informativeText = qsTr("Range not validated.")+"\n";
                    alertBox.visible = true;
                }

            }
            else
            {
                app.steps--;
                previous("")
            }
        }
    }
}


