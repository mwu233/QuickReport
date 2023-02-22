import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import Esri.ArcGISRuntime 100.10
import ArcGIS.AppFramework.Devices 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../controls"

Page {
    width: parent.width
    height: parent.height

    signal next(string message)
    signal previous(string message)

    property int hitFeatureId
    property variant attrValue
    property var tempId
    property int tempIndex

    header: Rectangle {
        id: header

        color: app.headerBackgroundColor
        width: parent.width
        height: 50 * app.scaleFactor

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
                app.updateSavedReportsCount();
                previous("")
            }
        }

        Text {
            id: title
            text: qsTr("Drafts")
            textFormat: Text.StyledText
            anchors.centerIn: parent
            font.pixelSize: app.titleFontSize
            font.family: app.customTitleFont.name
            color: app.headerTextColor
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 1
            elide: Text.ElideRight
        }
    }

    footer.visible: false

    content: Rectangle {
        anchors.fill: parent
        color: app.pageBackgroundColor

        Image {
            id: placeHolderImage
            visible: app.savedReportsModel.count < 1
            source: "../images/inbox_empty.png"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: (parent.height-placeHolderImage.height-placeHolderText.height)/2
            fillMode: Image.PreserveAspectFit
            width: parent.width * 0.6
            height: parent.width * 0.6
        }

        Label {
            id: placeHolderText
            width: parent.width * 0.6
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: placeHolderImage.bottom
            font.pixelSize: app.subtitleFontSize
            font.family: app.customTextFont.name
            color: app.textColor
            opacity: 0.75
            visible: app.savedReportsModel.count < 1
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("You do not have any saved drafts right now.")
        }

        //---------------------------------------------------------------------------

        ListView {
            id: listView

            width: Math.min(parent.width, 600 * scaleFactor)
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true

            currentIndex: -1

            spacing: 0

            model: app.savedReportsModel

            delegate: Item {
                width: parent.width
                height: isVisible ? delegateLayout.height : 0

                property bool isOpenButtons: false

                property bool isVisible: app.savedReportsSectionModel[draftFeatureLayerURL].sectionVisible

                Behavior on height {
                    NumberAnimation { duration: 200 }
                }

                clip: true

                ColumnLayout {
                    id: delegateLayout
                    width: parent.width
                    spacing: 0

                    // delegate content
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72 * scaleFactor
                        color: app.isDarkMode ? "#4D4D4D" : "white"
                        clip: true
                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: contentLayout.height
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 24 * scaleFactor

                                ColumnLayout {
                                    id: contentLayout
                                    width: parent.width
                                    spacing: 6 * scaleFactor

                                    Label {
                                        Layout.fillWidth: true
                                        text: type
                                        color: isDarkMode ? "white" : "#323232"
                                        font.pixelSize: 16 * scaleFactor  * fontScale
                                        font.family: app.customTextFont.name
                                        maximumLineCount: 1
                                        clip: true
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: detailText(hasAttachments, numberOfAttachment, size, date)
                                        color: isDarkMode ? "white" : "#828282"
                                        font.pixelSize: 14 * scaleFactor  * fontScale
                                        clip: true
                                        font.family: app.customTextFont.name
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        edit(index)
                                        //
                                    }
                                }
                            }

                            Rectangle {
                                id:openPopup
                                Layout.fillHeight: true
                                Layout.preferredWidth: 32 * scaleFactor //Math.floor((parent.width - 4 * scaleFactor) / 4)
                                color:"transparent"

                                ImageOverlay{
                                    width: 20 * scaleFactor
                                    height: 20 * scaleFactor
                                    anchors.centerIn: parent
                                    source: "../images/more.png"
                                    showOverlay: true
                                    overlayColor: app.isDarkMode ? "white" : "#595959"

                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        more.updateMenuItemsContent()
                                        more.open()
                                    }
                                }
                            }


                            Item {
                                Layout.fillHeight: true
                                Layout.preferredWidth: 16 * scaleFactor
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: app.isDarkMode ? "#404040" : "#dddddd"
                            anchors.bottom: parent.bottom
                        }
                    }

                }

                //popup Menu
                PopupMenu{
                    id:more
                    defaultMargin: app.defaultMargin
                    backgroundColor: Qt.lighter(blk_000)//"#FFFFFF"
                    highlightColor: Qt.darker(app.backgroundColor, 1.1)
                    textColor: app.textColor
                    primaryColor: app.primaryColor
                    menuItems: [


                    ]
                    height:app.units(16)  * 2 * scaleFactor + app.units(32) * scaleFactor
                    Material.primary: app.primaryColor
                    Material.background: backgroundColor
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                    width:defaultContentWidth
                    x: parent.width - width - app.baseUnit
                    y: 0 + app.baseUnit

                    onMenuItemSelected: {
                        switch (itemLabel) {
                        case app.delete_app:
                            confirmBox.visible = true;
                            tempIndex = index;
                            tempId = id;
                            break;
                        }

                    }

                    function updateMenuItemsContent()
                    {
                        more.appendUniqueItemToMenuList({"itemLabel": app.delete_app})
                    }

                }

            }

            //---------------------------------------------------------------------------

            section.property: featureLayerId.length === 1 ? "" : "draftFeatureLayerURL"
            section.delegate: Rectangle {
                width: parent.width
                height: 48 * scaleFactor

                color: app.isDarkMode ? "#606060" : "#EFEFEF"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var temp = listView.currentIndex;
                        app.savedReportsSectionModel[section].sectionVisible = !(app.savedReportsSectionModel[section].sectionVisible)
                        app.initSavedReportsData(-1, false)
                        if(temp < listView.model.count) listView.currentIndex = temp;
                        else listView.currentIndex = -1;
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 16 * scaleFactor
                    }

                    Rectangle {
                        Layout.preferredWidth: 24 * scaleFactor
                        Layout.preferredHeight: 24 * scaleFactor
                        Layout.alignment: Qt.AlignVCenter

                        radius: 12 * scaleFactor

                        color: app.headerBackgroundColor

                        ImageOverlay {
                            anchors.fill: parent
                            anchors.margins: 3 * scaleFactor

                            source: app.savedReportsSectionModel[section].sectionIcon

                            overlayColor: "#ffffff"
                            showOverlay: true
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 32 * scaleFactor
                    }

                    Label {
                        Layout.fillWidth: true
                        text: app.savedReportsSectionModel[section].sectionTitle
                        color: isDarkMode ? "white" : "#323232"
                        font.pixelSize: 14 * scaleFactor  * fontScale
                        font.family: app.customTextFont.name
                        maximumLineCount: 1
                        clip: true
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 8 * scaleFactor
                    }

                    Label {
                        text: app.savedReportsSectionModel[section].count
                        color: isDarkMode ? "white" : "#323232"
                        font.pixelSize: 14 * scaleFactor  * fontScale
                        font.family: app.customTextFont.name
                        maximumLineCount: 1
                        clip: true
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 8 * scaleFactor
                    }

                    ImageOverlay {
                        Layout.preferredWidth: 24 * scaleFactor
                        Layout.preferredHeight: 24 * scaleFactor

                        source: "../images/ic_keyboard_arrow_left_white_48dp.png"
                        rotation: app.savedReportsSectionModel[section].sectionVisible ? 270 : 90

                        overlayColor: isDarkMode ? "white" : "#323232"
                        showOverlay: true
                        fillMode: Image.PreserveAspectFit
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 16 * scaleFactor
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    visible: !app.savedReportsSectionModel[section].sectionVisible
                    anchors.bottom: parent.bottom
                    color: app.isDarkMode ? "#404040" : "#dddddd"
                }
            }
        }
    }




    //---------------------------------------------------------------------------

    function detailText(hasAttachments, numberOfAttachment, size, date){
        var resText = "";
        if(hasAttachments){
            resText += numberOfAttachment + (numberOfAttachment===1?qsTr(" file"):qsTr(" files"));
            resText += numberOfAttachment>0? (" · "+(size < 0.0001 ? "0.01" : size) + " MB"):"";
            resText += " · "
        }
        resText += date;
        return resText;
    }


    File {
        id: file
    }

    function sendReportUsingAttachmentFirst(index)
    {
        app.sentAttachmentCount1 = 0;
        app.featureLayerURL = app.savedReportsModel.get(index).draftFeatureLayerURL;

        app.isFromSaved = true
        app.isFromSend = true
        app.isShowCustomText = true;

        var featureattributes = {}
        var mailpayload = {
            "meta":{},
            "reportInfo":{},
            "attachmentInfo":[]

        }
        stackView.showResultsPage()

        var metaObjInfo = {}
        metaObjInfo.os = Qt.platform.os
        metaObjInfo.appVersion = app.info.version
        metaObjInfo.appName = app.info.title
        metaObjInfo.deviceLocale = Qt.locale().name
        metaObjInfo.appStudioVersion = AppFramework.version

        var currentdate =  new Date().toLocaleString();

        metaObjInfo.submitDate = currentdate

        metaObjInfo.systemInfo  = AppFramework.systemInformation
        mailpayload.meta = metaObjInfo

        var featureUid = AppFramework.createUuidString(0)
        if(submitStatusModel.count > 0) submitStatusModel.clear();
        var attachments = [];
        var finalJSONEdits = JSON.parse(app.savedReportsModel.get(index).editsJson);

        finalJSONEdits[0]["attributes"]["GlobalID"] = featureUid
        var featureattachements = JSON.parse(app.savedReportsModel.get(index).attachements);
        featureServiceManager.url = app.savedReportsModel.get(index).draftFeatureLayerURL;
        app.submittedAttachments = []
        if(featureattachements.length > 0)
        {
            for(var i=0;i<featureattachements.length;i++){
                temp = featureattachements[i] + "";
                var tempstring = featureattachements[i]+"";

                var fileName = AppFramework.fileInfo(tempstring).fileName;
                var fileInfo = AppFramework.fileInfo(tempstring);
                var sizeOfAttachment = app.getFileSize((tempstring))

                var arr = fileName.split(".");
                var suffix = arr[1];
                var type = "";
                if(suffix === "jpg" || suffix === "jpeg" || suffix === "png" || suffix === "tif" || suffix === "tiff" || suffix === "gif") type = "attachment";

                else  {
                    var fileFolderName = fileInfo.folder.folderName;
                    if(fileFolderName === "Video") type = "attachment2"
                    if(fileFolderName === "Audio") type = "attachment3"
                    if(fileFolderName === "Attachments")
                    {
                        if(suffix === "jpg" || suffix === "jpeg" || suffix === "png" || suffix === "tif" || suffix === "tiff" || suffix === "gif")
                            type = "attachment4";

                        else
                            type = "attachment5"


                    }



                }

                app.submitStatusModel.append({"type": type, "loadStatus": "loading", "objectId": "", "fileName": fileName});
                fileInfo.filePath = tempstring
                tempstring = fileInfo.filePath
                if(tempstring.includes(":"))
                {
                    var temparr = tempstring.split(":");
                    tempstring = temparr[1]
                }

                attachments[i] = {"type":suffix,"size":sizeOfAttachment,"name":fileInfo.fileName,"filePath":tempstring}
                featureServiceManager.uploadAttachment(tempstring, featureUid, function(errorcode, responseJson, fileIndex){

                    if(errorcode===0){
                        app.sentAttachmentCount1++
                        mailpayload.attachmentInfo.push({type:attachments[app.sentAttachmentCount1 - 1].type,size:attachments[app.sentAttachmentCount1 - 1].size,name:attachments[app.sentAttachmentCount1 - 1].name})

                        var attach = {}
                        //generate a globalid for the attachment
                        var attachmentUid = AppFramework.createUuidString(0)
                        //get the suffix
                        var filesuffix = responseJson.item.itemName.split('.')[1]
                        var contentType = app.kContentTypes[filesuffix]
                        if(!contentType)
                            contentType = app.kDefaultContentType

                        var item = {
                            "uploadId":responseJson.item.itemID,
                            "name":responseJson.item.itemName,
                            "globalId":attachmentUid,
                            "parentGlobalId":featureUid,
                            "contentType":contentType
                        }
                        app.submittedAttachments.push(item)
                        submitStatusModel.setProperty(fileIndex+1, "loadStatus", "success");

                        //add the feature after uploading all the attachments
                        if(app.sentAttachmentCount1 === featureattachements.length)
                        {
                            //now upload the feature
                            submitFeature(featureUid,mailpayload,attachments,finalJSONEdits)

                        }

                    }
                    else
                    {
                        submitStatusModel.setProperty(fileIndex+1, "loadStatus", "failed");
                        app.theFeatureAttachmentsSuccess = false;

                    }

                }, i);

            }
        }
        else
        {
            submitFeature(featureUid,mailpayload,attachments,finalJSONEdits)
        }
    }

    function submitFeature(featureUid,mailpayload,attachments,finalJSONEdits)
    {
        app.focus = true;

        var featureattributes = {}

        var geometryForFeatureToEdit;
        if(captureType === "point")geometryForFeatureToEdit = app.theNewPoint;
        else if(captureType === "line")geometryForFeatureToEdit = app.polylineObj;
        else geometryForFeatureToEdit = app.polygonObj;

        var attributesToEdit = {};

        for ( var field in attributesArray) {
            if ( attributesArray[field] === "" || attributesArray[field] === null) {
                attributesToEdit[field] = null;
            } else {
                attributesToEdit[field] = attributesArray[field];
            }
        }

        if(theFeatureTypesModel.count>0)
        {

            if(app.typeIdField && pickListIndex >= 0)
                attributesToEdit[app.typeIdField] =  theFeatureTypesModel.get(pickListIndex).value;
        }

        attributesToEdit["GlobalID"] = featureUid
        // var finalJSONEdits = [{"attributes": attributesToEdit, "geometry":geometryForFeatureToEdit.json}]
        console.log("JSON for save feature json", JSON.stringify(finalJSONEdits))


        mailpayload.reportInfo.attributes = finalJSONEdits
        mailpayload.reportInfo.featureServiceUrl = (featureServiceManager.url).toString()

        app.theFeatureAttachmentsSuccess = true;
        app.theFeatureEditingAllDone = false;
        app.theFeatureEditingSuccess = false;
        var featureToSubmit = {}
        var featureAttachments = {"adds":app.submittedAttachments}

        featureToSubmit = {"f":"json","adds":JSON.stringify(finalJSONEdits),"useGlobalIds":true,"attachments":JSON.stringify(featureAttachments)}

        featureServiceManager.applyEditsUsingAttachmentFirst(featureToSubmit, function(objectId){

            console.log("success")
            mailpayload.reportInfo.objectId = objectId
            app.theFeatureEditingAllDone = true
            removeAttachments(attachments)

            if(app.theFeatureEditingSuccess === true && app.isFromSaved){
                var delete_query = db.query();
                delete_query.prepare("DELETE FROM DRAFTS WHERE id =:id;")
                db.query("BEGIN TRANSACTION");
                delete_query.executePrepared({id: app.currentEditedSavedIndex});
                delete_query.finish();
                db.query("END TRANSACTION");

            }
            app.theFeatureEditingAllDone = true;
            app.theFeatureAttachmentsSuccess = true;
            app.theFeatureEditingSuccess = true

            app.removeItemFromSavedReportPage(tempId, tempIndex, attachments);

            //send email
            if(app.payloadUrl)
                featureServiceManager.sendEmail(mailpayload)








        })

    }



    function sendReportUsingFeatureFirst(index){
        app.featureLayerURL = app.savedReportsModel.get(index).draftFeatureLayerURL;

        app.isFromSaved = true
        app.isFromSend = true
        app.isShowCustomText = true;

        var featureattributes = {}
        var mailpayload = {
            "meta":{},
            "reportInfo":{},
            "attachmentInfo":[]

        }
        var attachments={}
        var metaObjInfo = {}
        metaObjInfo.os = Qt.platform.os
        metaObjInfo.systemInfo  = AppFramework.systemInformation
        metaObjInfo.appVersion = app.info.version
        metaObjInfo.appName = app.info.title
        metaObjInfo.deviceLocale = Qt.locale().name
        metaObjInfo.appStudioVersion = AppFramework.version

        var currentdate =  new Date().toLocaleString();
        metaObjInfo.submitDate = currentdate

        mailpayload.meta = metaObjInfo


        if(app.submitStatusModel.count > 0) app.submitStatusModel.clear();
        app.theFeatureAttachmentsSuccess = true;
        app.theFeatureEditingAllDone = false;
        app.theFeatureEditingSuccess = false;

        app.currentEditedSavedIndex = app.savedReportsModel.get(index).id;
        app.currentObjectId = -1;

        var finalJSONEdits = JSON.parse(app.savedReportsModel.get(index).editsJson);
        var attachements = JSON.parse(app.savedReportsModel.get(index).attachements);
        featureServiceManager.url = app.savedReportsModel.get(index).draftFeatureLayerURL;
        featureServiceManager.applyEditsUsingFeatureFirst(finalJSONEdits, function(objectId, errorCode){
            if(errorCode===-1){
                stackView.showResultsPage();
                app.theFeatureEditingAllDone = true
                app.theFeatureEditingSuccess = false
                app.theFeatureAttachmentsSuccess = false

                app.submitStatusModel.append({"type": "feature", "loadStatus": "failed", "objectId": objectId, "fileName": ""});
            } else if(errorCode === -498){
                if(app.isNeedGenerateToken){
                    serverDialog.isReportSubmit = true;
                    serverDialog.submitFunction = submitReport;
                    serverDialog.handleGenerateToken();
                    app.isNeedGenerateToken = false;
                } else {
                    featureServiceManager.token = app.token;
                    app.isNeedGenerateToken = true;
                    send(index)
                }
            } else{
                mailpayload.reportInfo.objectId = objectId
                mailpayload.reportInfo.attributes = finalJSONEdits
                mailpayload.reportInfo.featureServiceUrl = (featureServiceManager.url).toString()

                stackView.showResultsPage();

                app.submitStatusModel.append({"type": "feature", "loadStatus": "success", "objectId": objectId, "fileName": ""});
                app.currentObjectId = objectId;
                app.theFeatureEditingSuccess = true;

                if(attachements.length>0){
                    var sentAttachmentCount = 0;

                    for(var i=0;i<attachements.length;i++){
                        temp = attachements[i] + "";
                        var tempstring = attachements[i]+"";

                        var fileName = AppFramework.fileInfo(tempstring).fileName;
                        var fileInfo = AppFramework.fileInfo(tempstring);

                        var filePath = tempstring
                        if(Qt.platform.os === "windows")
                        {
                            var res = tempstring.charAt(0)
                            if(res === "/")
                                filePath = tempstring.substring(1)
                        }
                        var sizeOfAttachment = app.getFileSize(filePath)




                        var arr = fileName.split(".");
                        var suffix = arr[1];
                        var type = "";
                        if(suffix == "jpg" || suffix == "jpeg" || suffix == "png" || suffix == "tif" || suffix == "tiff" || suffix == "gif") type = "attachment";

                        else  {
                            var fileFolderName = fileInfo.folder.folderName;
                            if(fileFolderName === "Video") type = "attachment2"
                            if(fileFolderName === "Audio") type = "attachment3"
                            if(fileFolderName === "Attachments")
                            {
                                if(suffix == "jpg" || suffix == "jpeg" || suffix == "png" || suffix == "tif" || suffix == "tiff" || suffix == "gif")
                                    type = "attachment4";

                                else
                                    type = "attachment5"


                            }



                        }

                        app.submitStatusModel.append({"type": type, "loadStatus": "loading", "objectId": "", "fileName": fileName});
                        fileInfo.filePath = tempstring
                        tempstring = fileInfo.filePath
                        if(tempstring.includes(":"))
                        {
                            var temparr = tempstring.split(":");
                            tempstring = temparr[1]
                        }

                        attachments[i] = {"type":suffix,"size":sizeOfAttachment,"name":fileInfo.fileName,"filePath":filePath}

                        featureServiceManager.addAttachment(tempstring, objectId, function(errorcode, attachmentObjectId, fileIndex){
                            if(errorcode===0){
                                sentAttachmentCount++;
                                var attachmentUrl = featureServiceManager.url + "/"+ objectId + "/attachments/" + attachmentObjectId

                                mailpayload.attachmentInfo.push({url:attachmentUrl,type:attachments[sentAttachmentCount - 1].type,size:attachments[sentAttachmentCount - 1].size,name:attachments[sentAttachmentCount - 1].name})



                                app.submitStatusModel.setProperty(fileIndex+1, "loadStatus", "success");

                                if(sentAttachmentCount==attachements.length)
                                {
                                    app.theFeatureEditingAllDone = true
                                    if(app.theFeatureEditingSuccess === true){
                                        app.removeItemFromSavedReportPage(tempId, tempIndex, attachements);
                                    }
                                    if(app.payloadUrl)
                                        featureServiceManager.sendEmail(mailpayload)

                                }
                            }else{

                                app.submitStatusModel.setProperty(fileIndex+1, "loadStatus", "failed");
                                app.theFeatureAttachmentsSuccess = false;

                                sentAttachmentCount++;
                                if(sentAttachmentCount==attachements.length){
                                    app.theFeatureEditingAllDone = true

                                    //send email with attachment info
                                    if(app.payloadUrl)
                                        featureServiceManager.sendEmail(mailpayload)

                                }
                            }
                        }, i);
                    }


                } else{
                    app.theFeatureEditingAllDone = true;
                    app.theFeatureAttachmentsSuccess = true;
                    if(app.theFeatureEditingSuccess === true){
                        app.removeItemFromSavedReportPage(tempId, tempIndex, attachements);
                    }
                    //send email
                    if(app.payloadUrl)
                        featureServiceManager.sendEmail(mailpayload)
                }


            }

        });

    }

    function send(index)
    {
        if(app.useGlobalIDForEditing)
            sendReportUsingAttachmentFirst(index)
        else
            sendReportUsingFeatureFirst(index)
    }

    function edit(index){
        app.featureLayerURL = app.savedReportsModel.get(index).draftFeatureLayerURL;

        app.isFromSaved = true
        app.currentEditedSavedIndex = app.savedReportsModel.get(index).id;
        clearData()
        var attachements = JSON.parse(app.savedReportsModel.get(index).attachements);
        var attributes = JSON.parse(app.savedReportsModel.get(index).attributes);
        var pickListIndex = JSON.parse(app.savedReportsModel.get(index).pickListIndex);

        app.pickListIndex = pickListIndex;

        app.reportTypeString = app.savedReportsModel.get(index).reportType;
        app.damageTypeString = app.savedReportsModel.get(index).damageType;

        for(var i=0;i<attachements.length;i++){
            var tempAttachment = attachements[i];
            var array = tempAttachment.split(".");
            var suffix = array[array.length-1].toLowerCase();
            var fileInfo = AppFramework.fileInfo(attachements[i]);
            var fileFolderName = fileInfo.folder.folderName;


            if((fileFolderName !== "Attachments") && (suffix === "jpg" || suffix === "jpeg" || suffix === "png" || suffix === "tif" || suffix === "tiff" || suffix === "gif")) app.appModel.append({path: "file:///" + attachements[i], type: "attachment"});

            else {

                if(fileFolderName === "Video") app.appModel.append({path: attachements[i], type: "attachment2"});
                if(fileFolderName === "Audio") app.appModel.append({path: attachements[i], type: "attachment3"});
                if(fileFolderName === "Attachments")
                {


                    if(suffix === "jpg" || suffix === "jpeg" || suffix === "png" || suffix === "tif" || suffix === "tiff" || suffix === "gif")
                        app.appModel.append({path: "file:///" + attachements[i], type: "attachment4"});

                    else
                        app.appModel.append({path: attachements[i], type: "attachment5"});
                }

            }
        }

        app.attributesArray = attributes;
        var editsJson = JSON.parse(app.savedReportsModel.get(index).editsJson)
        app.featureLayerBeingEdited = editsJson[0].featureLayerName
        app.locationDisplayText = editsJson[0].geometryDescription

        if(app.savedReportsModel.get(index).xmax){
            console.log(JSON.stringify(app.savedReportsModel.get(index)));
            var spatialReference //= ArcGISRuntimeEnvironment.createObject("SpatialReference", {wkid:wkid});
            if(editsJson[0].geometry)
            {
                var spartialJsonForEnvelope = editsJson[0].geometry.spatialReference;
                var wkid = spartialJsonForEnvelope.wkid;
                spatialReference = ArcGISRuntimeEnvironment.createObject("SpatialReference", {wkid:wkid});
            }
            else
                spatialReference = ArcGISRuntimeEnvironment.createObject("SpatialReference");
            var xMax = app.savedReportsModel.get(index).xmax;
            var xMin = app.savedReportsModel.get(index).xmin;
            var yMax = app.savedReportsModel.get(index).ymax;
            var yMin = app.savedReportsModel.get(index).ymin;

            var ext = ArcGISRuntimeEnvironment.createObject("Envelope", {xMax:xMax, xMin:xMin, yMax:yMax, yMin:yMin, spatialReference: spatialReference});

            console.log("Extent", JSON.stringify(ext.json))
            app.centerExtent = ext;
        } else {
            app.centerExtent = null;
        }

        if(app.savedReportsModel.get(index).realValue){
            app.measureValue = app.savedReportsModel.get(index).realValue;
        } else {
            app.measureValue = 0;
        }

        app.savedReportLocationJson = editsJson[0].geometry;
        app.init()

    }

    function isValidGeometry(index){
        var editsJson = JSON.parse(app.savedReportsModel.get(index).editsJson);
        if(editsJson[0].geometry.paths){
            if(editsJson[0].geometry.paths[0])return editsJson[0].geometry.paths[0].length>1;
            else return false;
        } else if(editsJson[0].geometry.rings){
            if(editsJson[0].geometry.rings[0]) return editsJson[0].geometry.rings[0].length>3;
            else return false;
        } else {
            return true;
        }
    }

    //---------------------------------------------------------------------------

    ConfirmBox{
        id: confirmBox
        anchors.fill: parent
        onAccepted: {
            var attachments = JSON.parse(app.savedReportsModel.get(tempIndex).attachements);
            listView.currentIndex = -1;
            app.removeItemFromSavedReportPage(tempId, tempIndex, attachments);
        }
    }

    //---------------------------------------------------------------------------

    onBack: {
        if(confirmBox.visible === true){
            confirmBox.visible = false
        } else {
            app.updateSavedReportsCount();
            previous("")
        }
    }
}
