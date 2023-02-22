/* Copyright 2019 Esri
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
import QtQuick.Controls 2.2 as MyControls
import QtQuick.Layouts 1.1
import QtMultimedia 5.2
import Qt.labs.folderlistmodel 2.1
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2
import QtPositioning 5.8

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Multimedia 1.0

import Esri.ArcGISRuntime 100.10
import ArcGIS.AppFramework.Platform 1.0
import ArcGIS.AppFramework.Networking 1.0

import QtQuick.Controls.Material 2.2

import "../controls"
import "../controls/SketchControl"
import "../controls/VideoRecorderControl"
import "../controls/AudioRecorderControl"
import "../"

Rectangle {
    id: rectContainer
    objectName: "addPhotoPage"
     width: parent ? parent.width :0
    height:parent ?parent.height:0
    color: app.pageBackgroundColor

    signal next(string message)
    signal previous(string message)

    property string fileLocation: "../images/placeholder.png"
    property bool photoReady: false
    property int captureResolution: 1024

    property real lat:0
    property real lon:0

    readonly property int halfScreenWidth: (width * 0.5)*app.scaleFactor
    property string type: "appview"

    property int maxbuttonlistItems: app.maximumAttachments
    property var webPage
    property var imageEditor
    property var imageViewer

    property bool hasVideoAttachment: false
    property bool hasAudioAttachment: false
    property int numberOfAttachment: 0
    property string fileSize: ""

    property string selectedFilePath:""
    property url selectedFileUrl:""
    property string selectedFileSuffix:""
    property string selectedFileName:""
    property var iconwidth:getWidth(width)
    property string activeTool:""

    FileInfo {
        id: fileInfo
    }

    File {
        id: file
    }


    PermissionDialog {
        id: permissionDialog
        openSettingsWhenDenied: true


        onAccepted: {
           if(activeTool == "take_audio")
           {
            if (permissionDialog.permission == PermissionDialog.PermissionDialogTypeMicrophone)
                    stackView.push(audioRecorderComponent)
           }
           else if(activeTool == "take_video")
           {
               if((Permission.checkPermission(Permission.PermissionTypeCamera) === Permission.PermissionResultGranted) && (Permission.checkPermission(Permission.PermissionTypeMicrophone) === Permission.PermissionResultGranted))
                     stackView.push(videoRecorderComponent)

           }
           else if(activeTool == "take_picture")
           {
               if (Permission.checkPermission(Permission.PermissionTypeCamera) === Permission.PermissionResultGranted)
                   cameraDialog.open()

           }



        }

        onRejected: {

        }
    }


    DocumentDialog {
        id: doc

        onAccepted: {          
            console.log("***FILE SELECTED***", fileUrl)
            var filePath = AppFramework.resolvedPath(fileUrl)
            var attachmentfileInfo = AppFramework.fileInfo(filePath)
            var suffix = attachmentfileInfo.suffix
            var filesallowed = "7Z, AIF, AVI, BMP, DOC, DOCX, DOT, ECW, EMF, EPA, GIF, GML, GTAR, GZ, IMG, J2K," +
                    "JP2, JPC, JPE, JPEG, JPF, JPG, JSON, MDB, MID, MOV, MP2, MP3, MP4, MPA, MPE, MPEG, MPG, MPV2, PDF, PNG, PPT," +
                    "PPTX, PS, PSD, QT, RA, RAM, RAW, RMI, SID, TAR, TGZ, TIF, TIFF, TXT, VRML, WAV, WMA, WMF, WPS, XLS, XLSX, XLT, XML, ZIP"

            var indx = -1
            if(suffix.length > 0)
                indx = filesallowed.toUpperCase().indexOf(suffix.toUpperCase())

            var size = attachmentfileInfo.size

            if(indx < 0)
            {
                messageDialog.text = qsTr("File not supported.")
                messageDialog.open()
            }
            else
            {
                if (size <= 52428800)// 50MB
                {
                    if(!attachmentsFolder)
                        attachmentsFolder = (AppFramework.fileInfo(attachmentsBasePath)).folder
                    if(!attachmentsFolder.exists)
                        attachmentsFolder.makeFolder()

                    if (!attachmentsFolder.fileExists(".nomedia") && Qt.platform.os === "android") {
                        attachmentsFolder.writeFile(".nomedia", "")
                    }

                    var sourcefolder = attachmentfileInfo.folder
                    var destfilePath = attachmentsFolder.filePath(attachmentfileInfo.displayName);                    
                    var iscopied = sourcefolder.copyFile(attachmentfileInfo.displayName,destfilePath)                    
                    var  attachedFileInfo = attachmentsFolder.fileInfo(attachmentfileInfo.fileName)
                    var filePrefix = Qt.platform.os == "windows"? "file:///": "file://"
                    var attachedFilePath = filePrefix + attachmentsFolder.path + "/"+ attachmentfileInfo.displayName
                    var fsuffix = attachmentfileInfo.suffix.toLowerCase();
                    if(fsuffix === "jpg" || fsuffix === "jpeg" || fsuffix === "png" || fsuffix === "tif" || fsuffix === "tiff" || fsuffix === "gif")
                        appModel.append({path: attachedFilePath, type: "attachment4"})
                    else
                        appModel.append({path: attachedFilePath, type: "attachment5"})

                    visualListModel.initVisualListModel();
                }
                else
                {
                    messageDialog.text = qsTr("Maximum size supported for any file is 50 MB.")
                    messageDialog.open()
                }
            }
        }


        onRejected: {
            console.log("Cancelled by user")
        }
    }

    ExifInfo {
        id: page2_exifInfo
    }

    ImageObject {
        id: imageObject
    }


    function resizeImage(path) {
        console.log("Inside Resize Image: ", path)

        if (!captureResolution) {
            console.log("No image resize:", captureResolution);
            return;
        }

        var fileInfo = AppFramework.fileInfo(path);
        if (!fileInfo.exists) {
            console.error("Image not found:", path);
            return;
        }

        if (!(fileInfo.permissions & FileInfo.WriteUser)) {
            console.log("File is read-only. Setting write permission:", path);
            fileInfo.permissions = fileInfo.permissions | FileInfo.WriteUser;
        }

        if (!imageObject.load(path)) {
            console.error("Unable to load image:", path);
            return;
        }

        if (imageObject.width <= captureResolution) {
            console.log("No resize required:", imageObject.width, "<=", captureResolution);
            return;
        }

        console.log("Rescaling image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);

        imageObject.scaleToWidth(captureResolution);

        if (!imageObject.save(path)) {
            console.error("Unable to save image:", path);
            return;
        }

        fileInfo.refresh();
        console.log("Scaled image:", imageObject.width, "x", imageObject.height, "size:", fileInfo.size);
    }
    function getRotateAngle(){
        var rotate = 0;
        switch(Screen.orientation){
        case 1:
            rotate = 0;
            break;
        case 2:
            rotate = isBackCamera?270:90;
            break;
        case 4:
            rotate = 180;
            break;
        case 8:
            rotate = isBackCamera?90:270
            break;
        }
        return rotate;
    }



    function addGPSParameters(filePath)
    {

        exifInfo.load(filePath);
        exifInfo.setImageValue(ExifInfo.ImageDateTime, new Date());
        exifInfo.setImageValue(ExifInfo.ImageSoftware, app.info.title);
        exifInfo.setExtendedValue(ExifInfo.ExtendedDateTimeOriginal, new Date());
        if(positionSource.position.latitudeValid)exifInfo.gpsLatitude = positionSource.position.coordinate.latitude;
        if(positionSource.position.longitudeValid)exifInfo.gpsLongitude = positionSource.position.coordinate.longitude;
        if(positionSource.position.altitudeValid)exifInfo.gpsAltitude = positionSource.position.coordinate.altitude;
        if (positionSource.position.horizontalAccuracyValid)
        {
            exifInfo.setGpsValue(ExifInfo.GpsHorizontalPositionError, positionSource.position.horizontalAccuracy);
        }

        if (positionSource.position.speedValid) {
            exifInfo.setGpsValue(ExifInfo.GpsSpeed, positionSource.position.speed * 3.6); // Convert M/S to KM/H
            exifInfo.setGpsValue(ExifInfo.GpsSpeedRef, "K");
        }
        if (positionSource.position.directionValid) {
            exifInfo.setGpsValue(ExifInfo.GpsTrack, positionSource.position.direction);
            exifInfo.setGpsValue(ExifInfo.GpsTrackRef, "T");
        }

        exifInfo.save(filePath);


    }

    PositionSource {
        id: positionSource
        updateInterval: 5000
        active: false
    }


    CameraDialog{
        id:cameraDialog

        onAccepted: {
            if(captureMode === CameraDialog.CameraCaptureModeStillImage)
            {
                if(!mypicturesFolder.exists)
                    mypicturesFolder.makeFolder()
                var fileInfo = AppFramework.fileInfo(fileUrl);
                var picfolder = fileInfo.folder
                var iscopied = picfolder.copyFile(fileInfo.fileName,mypicturesFolder.path + "/"+ fileInfo.fileName)

                picfolder.removeFile(fileUrl)

                var  picFileInfo = picfolder.fileInfo(fileInfo.fileName)
                app.selectedImageFilePath = picFileInfo.filePath
                var picturepath = ""

                if(Qt.platform.os === "windows")
                    picturepath = "file:///" + mypicturesFolder.path + "/"+ fileInfo.fileName
                else
                    picturepath = "file://" + mypicturesFolder.path + "/"+ fileInfo.fileName

                if(positionSource.position.coordinate.latitude)
                    addGPSParameters(picturepath)
                resizeImage(picturepath)
                app.selectedImageFilePath = picturepath

                appModel.append(
                            {path: app.selectedImageFilePath.toString(), type: "attachment"}
                            )

                photoReady = true
                visualListModel.initVisualListModel();

                if (Qt.platform.os === "android") {
                    positionSource.stop()
                }
                else
                    positionSource.active = false;


            }
            else
            {


                if(!videoFolder.exists)
                    videoFolder.makeFolder()
                var fileInfo = AppFramework.fileInfo(fileUrl);
                var vfolder = fileInfo.folder
                var iscopied = vfolder.copyFile(fileInfo.fileName,videoFolder.path + "/"+ fileInfo.fileName)

                vfolder.removeFile(fileUrl)
                var  videoFileInfo = videoFolder.fileInfo(fileInfo.fileName)
                app.selectedImageFilePath = videoFileInfo.filePath

                var videopath = "file://" + videoFolder.path + "/"+ fileInfo.fileName //videoFileInfo.filePath//fileUrl


                appModel.append({path: videopath, type: "attachment2"})

                visualListModel.initVisualListModel();
            }
        }
    }



    ColumnLayout {
        anchors.fill: parent
        spacing: 16 * app.scaleFactor
        Layout.alignment: Qt.AlignHCenter

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
                    var stackitem = stackView.get(stackView.depth - 2)
                    if (stackitem.objectName === "summaryPage") {
                        app.steps++;
                    }
                    app.steps--;
                    previous("");
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
                source: "../images/ic_send_white_48dp.png"
                height: 30 * app.scaleFactor
                width: 30 * app.scaleFactor
                visible: false//app.isFromSaved
                enabled: app.isFromSaved && app.isReadyForSubmitReport && app.isOnline
                opacity: enabled? 1:0.3
                checkedColor : "transparent"
                pressedColor : "transparent"
                hoverColor : "transparent"
                glowColor : "transparent"
                anchors.rightMargin: 10
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    confirmToSubmit.visible = true
                }
            }
        }

        ListModel{
            id: visualListModel


            Component.onCompleted: {
                visualListModel.initVisualListModel();
            }

            function initVisualListModel(){
                var temp;
                visualListModel.clear()
                var hasTag;
                var countVideos = 0;
                var countAudio = 0;
                var countAttachment = 0;
                for(var i=0;i<app.maximumAttachments;i++){
                    if(i<app.appModel.count){
                        temp = app.appModel.get(i);
                        var tempPath = temp.path;
                        var tempType = temp.type;
                        page2_exifInfo.load(tempPath.toString().replace(Qt.platform.os == "windows"? "file:///": "file://",""));

                        if(page2_exifInfo.gpsLongitude && page2_exifInfo.gpsLatitude) {
                            hasTag = true;
                        } else {
                            hasTag = false;
                        }
                        if(tempType === "attachment2") countVideos++;
                        if(tempType === "attachment3") countAudio++;
                        visualListModel.append({path: tempPath, type: tempType, hasTag: hasTag});
                        countAttachment++;
                    }else{
                        visualListModel.append({path: "", type:"placehold", hasTag: false})
                    }
                }
                hasVideoAttachment = countVideos > 0;
                hasAudioAttachment = countAudio > 0;
                numberOfAttachment = countAttachment;
            }
        }

        RowLayout{
            Layout.preferredWidth: parent.width * 0.8
            Layout.preferredHeight: createPage_titleText.height
            Layout.alignment: Qt.AlignHCenter
            spacing: 5*app.scaleFactor
            Text {
                id: createPage_titleText
                text: (app.supportMedia || app.supportAudioRecorder) ? qsTr("Add Media") : qsTr("Add Photo")
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
                Layout.preferredWidth: Math.min(36*app.scaleFactor, parent.width- (5*app.scaleFactor))*0.9
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
                            webPage = component.createObject(rectContainer);
                            webPage.openSectionID(""+3)
                        }
                       // app.openWebView(1, { pageId: rectContainer, url: "" + 3 });
                    }
                }
            }
        }

        Rectangle{
            color: "transparent"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(rectContainer.width*0.80, 600*app.scaleFactor)
            Layout.preferredHeight: 3* createPage_titleText.height

            Text {
                text: {
                    var description = "";
                    if(app.supportMedia && app.supportAudioRecorder) {
                        description = qsTr("Add up to %1 attachments.").arg(app.maximumAttachments) + " " + qsTr("Audio and video recordings are limited to one each. Larger images will be resized to %1 pixels.").arg(captureResolution);
                    } else if(!app.supportMedia && !app.supportAudioRecorder) {
                        description = qsTr("Add up to %1 photos.").arg(app.maximumAttachments) + " " + qsTr("Larger images will be resized to %1 pixels.").arg(captureResolution);
                    } else if(app.supportMedia) {
                        description = qsTr("Add up to %1 attachments.").arg(app.maximumAttachments) + " " + qsTr("Video recording is limited to one. Larger images will be resized to %1 pixels.").arg(captureResolution);
                    } else {
                        description = qsTr("Add up to %1 attachments.").arg(app.maximumAttachments) + " " + qsTr("Audio recording is limited to one. Larger images will be resized to %1 pixels.").arg(captureResolution);
                    }
                    return description
                }

                font.pixelSize: app.subtitleFontSize
                font.family: app.customTextFont.name
                visible: app.maximumAttachments > 1
                color: app.textColor
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
            }

        }


        Row{
            Layout.alignment: Qt.AlignHCenter
            width: Math.min(parent.width*0.80, 600*app.scaleFactor)
            spacing: (app.supportAudioRecorder && app.supportVideoRecorder) ? 25*AppFramework.displayScaleFactor : ((!app.supportAudioRecorder && !app.supportVideoRecorder)? 56*AppFramework.displayScaleFactor : 40*AppFramework.displayScaleFactor)

            ColumnLayout{
                width: iconwidth*app.scaleFactor
                opacity: numberOfAttachment < app.maximumAttachments ? 1.0 :0.8
                enabled: opacity === 1.0

                Icon{
                    containerSize: app.units(iconwidth)
                    imageSource: "../images/camera_black.png"
                    color: app.allowPhotoToSkip?"#6e6e6e":(app.appModel.count > 0 ? "#6e6e6e": app.buttonColor)
                    Layout.alignment: Qt.AlignHCenter
                    onIconClicked: {
                        activeTool="take_picture"
                        if (Qt.platform.os === "ios" || Qt.platform.os === "android"){
                            if(Permission.checkPermission(Permission.PermissionTypeLocationAlwaysInUse) === Permission.PermissionResultGranted)
                            {
                                if (Qt.platform.os === "android") {
                                    positionSource.start();
                                }
                                else
                                    positionSource.active = true;
                            }
                        }
                        else
                        {
                            positionSource.start();
                        }

                        if(Qt.platform.os === "android" || Qt.platform.os === "ios")
                        {
                            if(Permission.checkPermission(Permission.PermissionTypeCamera) === Permission.PermissionResultGranted)
                            {
                                cameraDialog.captureMode = CameraDialog.CameraCaptureModeStillImage
                                if(Qt.platform.os !== "ios" && Qt.platform.os !== "android")
                                    cameraDialog.z = 88

                                cameraDialog.open()
                            }
                            else
                            {
                                permissionDialog.permission = PermissionDialog.PermissionDialogTypeCamera;

                                permissionDialog.open()
                            }



                        }
                        else
                        {
                            cameraDialog.z = 88
                            cameraDialog.open()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    font.pixelSize: app.subtitleFontSize
                    font.family: app.customTextFont.name
                    color: app.textColor
                    text: qsTr("Camera")
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    fontSizeMode: Text.Fit
                }
            }

            ColumnLayout{
                width: iconwidth*app.scaleFactor
                visible: app.showAlbum
                opacity: numberOfAttachment < app.maximumAttachments ? 1.0 :0.8
                enabled: opacity === 1.0

                Icon{
                    containerSize: app.units(iconwidth)
                    imageSource: "../images/folder-multiple-image.png"
                    color: app.allowPhotoToSkip?"#6e6e6e":(app.appModel.count > 0 ? "#6e6e6e": app.buttonColor)
                    Layout.alignment: Qt.AlignHCenter
                    onIconClicked: {
                        pictureChooser.open()

                    }
                }

                Text {
                    Layout.fillWidth: true
                    font.pixelSize: app.subtitleFontSize
                    font.family: app.customTextFont.name
                    color: app.textColor
                    text: qsTr("Album ")
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    fontSizeMode: Text.Fit
                }
            }

            ColumnLayout{
                width: iconwidth*app.scaleFactor
                visible: Qt.platform.os != "windows" && app.supportVideoRecorder
                opacity: (!rectContainer.hasVideoAttachment && numberOfAttachment < app.maximumAttachments) ? 1.0 :0.8
                enabled: opacity === 1.0

                Icon{
                    containerSize: app.units(iconwidth)
                    imageSource: "../images/video.png"
                    color: app.allowPhotoToSkip?"#6e6e6e":(app.appModel.count > 0 ? "#6e6e6e": app.buttonColor)
                    Layout.alignment: Qt.AlignHCenter
                    onIconClicked: {
                        activeTool="take_video"
                        if(Qt.platform.os === "android" || Qt.platform.os === "ios")
                        {
                            if((Permission.checkPermission(Permission.PermissionTypeCamera) === Permission.PermissionResultGranted) && (Permission.checkPermission(Permission.PermissionTypeMicrophone) === Permission.PermissionResultGranted))
                            {
                                stackView.push(videoRecorderComponent)
                            }
                            else
                            {
                                if(!(Permission.checkPermission(Permission.PermissionTypeCamera) === Permission.PermissionResultGranted))
                                {
                                    permissionDialog.permission = PermissionDialog.PermissionDialogTypeCamera;
                                    permissionDialog.open()
                                }
                                if(!(Permission.checkPermission(Permission.PermissionTypeMicrophone) === Permission.PermissionResultGranted))
                                {
                                    permissionDialog.permission = PermissionDialog.PermissionDialogTypeMicrophone;
                                    permissionDialog.open()
                                }
                            }
                        }
                        else
                        {
                            stackView.push(videoRecorderComponent)

                        }

                    }
                }

                Text {
                    Layout.fillWidth: true
                    font.pixelSize: app.subtitleFontSize
                    font.family: app.customTextFont.name
                    color: app.textColor
                    text: qsTr("Video")
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    fontSizeMode: Text.Fit
                }
            }

            ColumnLayout{
                width: iconwidth*app.scaleFactor
                visible: app.supportAudioRecorder
                opacity: (!rectContainer.hasAudioAttachment && numberOfAttachment < app.maximumAttachments) ? 1.0 :0.8
                enabled: opacity === 1.0

                Icon{
                    containerSize: app.units(iconwidth)
                    imageSource: "../images/ic_audiotrack_black_48dp.png"
                    color: app.allowPhotoToSkip?"#6e6e6e":(app.appModel.count > 0 ? "#6e6e6e": app.buttonColor)
                    Layout.alignment: Qt.AlignHCenter
                    onIconClicked: {
                        activeTool="take_audio"
                        if(Qt.platform.os === "android" || Qt.platform.os === "ios")
                        {

                            if(Permission.checkPermission(Permission.PermissionTypeMicrophone) === Permission.PermissionResultGranted)
                            {
                                stackView.push(audioRecorderComponent)
                            }
                            else
                            {
                                permissionDialog.permission = PermissionDialog.PermissionDialogTypeMicrophone;

                                permissionDialog.open()
                            }
                        }
                        else
                        {
                            stackView.push(audioRecorderComponent)
                        }



                    }
                }

                Text {
                    Layout.fillWidth: true
                    font.pixelSize: app.subtitleFontSize
                    font.family: app.customTextFont.name
                    color: app.textColor
                    text: qsTr("Audio")
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    fontSizeMode: Text.Fit
                }
            }
            ColumnLayout{
                width: iconwidth*app.scaleFactor
                visible: app.showFileAttachment
                opacity: numberOfAttachment < app.maximumAttachments ? 1.0 :0.8
                enabled: opacity === 1.0

                Icon{
                    containerSize: app.units(iconwidth)
                    imageSource: "../images/fileDialogIcon.png"
                    color: app.allowPhotoToSkip?"#6e6e6e":(app.appModel.count > 0 ? "#6e6e6e": app.buttonColor)
                    Layout.alignment: Qt.AlignHCenter
                    onIconClicked: {
                         doc.open()                     
                    }
                }

                Text {
                    Layout.fillWidth: true
                    font.pixelSize: app.subtitleFontSize
                    font.family: app.customTextFont.name
                    color: app.textColor
                    text: qsTr("File")
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    fontSizeMode: Text.Fit
                }
            }
        }

        Rectangle{
            id:contentRect
            color: "transparent"
            Layout.preferredWidth: Math.min(parent.width*0.80, 600*app.scaleFactor)
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter

            clip:true

            GridView {
                id:grid
                width: parent.width
                height: parent.height
                focus: true
                visible: app.appModel.count>0
                model: visualListModel
                cellWidth: parent.width/3
                cellHeight: cellWidth*0.8

                delegate: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width-16*app.scaleFactor
                        height: parent.height-16*app.scaleFactor
                        color: (type == "attachment2" || type == "attachment3" || type == "attachment4"||type == "attachment5") ? "#6e6e6e" : "transparent"
                        radius: 3*app.scaleFactor
                        border.color: "#80cccccc"
                        border.width: 1*app.scaleFactor

                        Image {
                            id: myIcon
                            source: type == "attachment"|| type == "attachment4" ? path: (type == "attachment2" ? "../images/file-video.png": (type == "attachment3" ? "../images/audiobook.png":
                                                                                                                                                                       (type == "attachment5" ? "../images/fileattachment.png" :  "")))
                            width: (type == "attachment2" || type == "attachment3"|| type == "attachment5") ? parent.width*0.5:parent.width
                            height: (type == "attachment2" || type == "attachment3"|| type == "attachment5") ? parent.height*0.5:parent.height
                            fillMode: Image.PreserveAspectCrop
                            anchors.centerIn: parent
                            autoTransform: true
                            visible: source>""
                            cache: false
                            sourceSize.width: width
                            sourceSize.height: height
                        }

                        Rectangle{
                            width: 16*app.scaleFactor
                            height: 16*app.scaleFactor
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: 4*app.scaleFactor
                            anchors.leftMargin: 4*app.scaleFactor
                            clip: true
                            radius: 2*app.scaleFactor
                            color: "#80ffffff"
                            visible: hasTag
                            Image{
                                id: indicatorImg
                                width: 12*app.scaleFactor
                                height: 12*app.scaleFactor
                                source: "../images/location.png"
                                anchors.centerIn: parent
                            }
                            ColorOverlay{
                                anchors.fill: indicatorImg
                                source: indicatorImg
                                color: "#6E6E6E"
                            }
                        }

                        MouseArea {
                            enabled: type == "attachment" || type == "attachment2" || type == "attachment3"|| type == "attachment4"|| type == "attachment5"
                            anchors.fill: parent
                            onClicked: {
                                if(type == "attachment"){
                                    grid.currentIndex = index;
                                    previewImageRect.source = path;
                                    previewImageRect.visible = true
                                    previewImageRect.init();
                                } else if(type == "attachment2") {
                                    grid.currentIndex = index;
                                    var fileInfo = AppFramework.fileInfo(path)
                                    var tempstring = fileInfo.filePath
                                    if(tempstring.includes(":"))
                                    {
                                        var temparr = tempstring.split(":");
                                        tempstring = temparr[1]
                                    }
                                    var videoUrl = "file:///" + tempstring
                                    var videoPreview = videoPreviewComponent.createObject(null);
                                    videoPreview.load(videoUrl);
                                    stackView.push(videoPreview);
                                } else if(type == "attachment3") {
                                    grid.currentIndex = index;
                                    var fileInfo_audio = AppFramework.fileInfo(path)
                                    var tempstring_audio = fileInfo_audio.filePath
                                    if(tempstring_audio.includes(":"))
                                    {
                                        var temparr1 = tempstring_audio.split(":");
                                        tempstring_audio = temparr1[1]
                                    }
                                    var audioUrl = "file:///" + tempstring_audio

                                    var audioPlayer = audioPlayerComponent.createObject(null);
                                    audioPlayer.loadSource(audioUrl);
                                    stackView.push(audioPlayer);
                                }
                                else if(type == "attachment4"|| type == "attachment5")
                                {

                                    var modPath = path
                                    popupOption.open()
                                    grid.currentIndex = index;
                                    if(path.includes("file:"))
                                    {
                                        if(Qt.platform.os === "windows")
                                        {
                                            var tempPath
                                            if(path.includes("file:///")){
                                            tempPath = path.split("file:///")[1]
                                            }
                                            else
                                                tempPath = path.split("file://")[1]

                                            modPath = tempPath.replace(":/","://")
                                        }
                                        else
                                        modPath = path.split("file://")[1]
                                    }

                                    var fileInfo_attachment = AppFramework.fileInfo(modPath)

                                    if(fileInfo_attachment.size < 1024)
                                        fileSize = `${fileInfo_attachment.size} Bytes`
                                    else
                                        fileSize = app.fileSizeConverter(fileInfo_attachment.size)



                                    selectedFilePath = path
                                    selectedFileUrl = AppFramework.resolvedPathUrl(modPath)
                                    selectedFileSuffix =  fileInfo_attachment.suffix.toUpperCase()
                                    selectedFileName = fileInfo_attachment.baseName.toUpperCase()


                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: footer
            Layout.preferredHeight: nextButton.height
            Layout.preferredWidth: parent.width * 0.95
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: app.units(8)
            Layout.maximumWidth: app.units(600)
            color: "transparent"
            Layout.bottomMargin: app.isIPhoneX ? 28 * app.scaleFactor : 8 * scaleFactor


            CustomButton {
                //Layout.alignment: Qt.AlignHCenter
                //Layout.preferredWidth: Math.min(parent.width*0.80, 600*app.scaleFactor)
                //Layout.bottomMargin: app.isIPhoneX ? 28 * app.scaleFactor : 8 * scaleFactor
                id: nextButton
                buttonText: qsTr("Next")
                buttonColor: app.buttonColor
                buttonFill: app.allowPhotoToSkip? true: (app.appModel.count>0)
                buttonWidth: Math.min(parent.width, 600 * scaleFactor)
                buttonHeight: 50 * app.scaleFactor
                visible: app.allowPhotoToSkip? true: (app.appModel.count>0)

                MouseArea {
                    anchors.fill: parent
                    enabled: app.allowPhotoToSkip? true: (app.appModel.count>0)
                    onClicked: {
                        next("refinelocation")
                    }
                    onPressedChanged: {
                        nextButton.buttonColor = pressed ?
                                    Qt.darker(app.buttonColor, 1.1): app.buttonColor
                    }
                }
            }
        }
    }

    DropShadow {
        source: createPage_headerBar
        //anchors.fill: source
        width: source.width
        height: source.height
        cached: false
        radius: 5.0
        samples: 16
        color: "#80000000"
        smooth: true
        visible: source.visible
    }

    PreviewImage{
        id: previewImageRect

        onDiscarded: {
            console.log("grid.currentIndex", grid.currentIndex);
            app.appModel.remove(grid.currentIndex);
            visualListModel.initVisualListModel();
        }
        onEdited: {
            previewImageRect.infoPanelVisible = false;
            var component = imageEditorComponent;
            imageEditor = component.createObject(rectContainer);
            imageEditor.visible = true;
            imageEditor.workFolder = mypicturesFolder//outputFolder;
            imageEditor.exif_latitude = previewImageRect.copy_latitude;
            imageEditor.exif_longtitude = previewImageRect.copy_longtitude;
            imageEditor.exif_altitude = previewImageRect.copy_altitude;

            //copy
            var pictureUrl = source;
            var pictureUrlInfo = AppFramework.urlInfo(pictureUrl);
            var picturePath = pictureUrlInfo.localFile;
            var assetInfo = AppFramework.urlInfo(picturePath);
            imageEditor.sourceFileName = pictureUrlInfo.fileName
            var outputFileName;

            var suffix = AppFramework.fileInfo(picturePath).suffix;
            var fileName = AppFramework.fileInfo(picturePath).baseName+AppFramework.createUuidString(2);
            var a = suffix.match(/&ext=(.+)/);
            if (Array.isArray(a) && a.length > 1) {
                suffix = a[1];
            }

            if (assetInfo.scheme === "assets-library") {
                pictureUrl = assetInfo.url;
            }

            outputFileName = "draft" + "-" + fileName + "." + suffix;

            var outputFileInfo = mypicturesFolder.fileInfo(outputFileName);

            mypicturesFolder.removeFile(outputFileName);
            mypicturesFolder.copyFile(picturePath, outputFileInfo.filePath);

            pictureUrl = mypicturesFolder.fileUrl(outputFileName);

            fixRotate(pictureUrl)

            imageEditor.pasteImage(pictureUrl);
        }
        onDirty: {
            app.appModel.set(grid.currentIndex, {path: source, type: "attachment"});
            visualListModel.initVisualListModel();
        }
        onRefresh: {
            visualListModel.initVisualListModel();
        }
    }

    Component {
        id: videoPreviewComponent

        VideoPreview {
            isPreviewMode: true

            onDiscard: {
                app.appModel.remove(grid.currentIndex);
                visualListModel.initVisualListModel();
                stackView.pop();
            }

            onDirty: {
                app.appModel.set(grid.currentIndex, {path: videoPath, type: "attachment2"});
                visualListModel.initVisualListModel();
            }
        }
    }
    Component {
        id: videoRecorderComponent

        VideoRecorder {
            onSaved: {
                appModel.append({path: AppFramework.resolvedPath(videoSavePath), type: "attachment2"})
                visualListModel.initVisualListModel();
                stackView.pop();
            }

            onBack: {
                stackView.pop();
            }
        }
    }



    Component {
        id: audioRecorderComponent

        CustomizedAudioRecorder {
            onSaved:  {
                appModel.append({path: AppFramework.resolvedPath(audioPath), type: "attachment3"})
                visualListModel.initVisualListModel();
                stackView.pop();
            }

            onBack: {
                stackView.pop()
            }
        }
    }

    Component {
        id: audioPlayerComponent

        CustomizedAudioPlayer {
            onDiscard: {
                app.appModel.remove(grid.currentIndex);
                visualListModel.initVisualListModel();
                stackView.pop();
            }

            onDirty: {
                app.appModel.set(grid.currentIndex, {path: audioPath, type: "attachment3"});
                visualListModel.initVisualListModel();
            }
        }
    }

    Component {
        id: imageEditorComponent

        ImageEditor {
            anchors.fill: parent
            visible: false


            onSaved: {
                app.appModel.set(grid.currentIndex, {path: saveUrl.toString(), type: "attachment"});
                visualListModel.initVisualListModel();
                previewImageRect.visible = false;
                mypicturesFolder.removeFile(sourceFileName);

            }
        }
    }

    Component{
        id: imageViewerComponent
        ImageViewer{
            anchors.fill: parent
            visible: false

            onSaved: {
                previewImage.source = "../images/placeholder.png";
                previewImage.source = newFileUrl;

                var path = AppFramework.resolvedPath(newFileUrl);
                var filePath = "file:///" + path
                filePath = filePath.replace("////","///");

                app.appModel.set(grid.currentIndex, {path: filePath, type: "attachment"});
                visualListModel.initVisualListModel();

            }
        }
    }

    ConfirmBox{
        id: deleteAlertBox
        anchors.fill: parent
        standardButtons: StandardButton.Yes | StandardButton.No
        onAccepted: {
            var filename =  AppFramework.fileInfo(selectedFilePath).fileName

            if(attachmentsFolder.fileExists(filename)){
                attachmentsFolder.removeFile(filename)
            }
            app.appModel.remove(grid.currentIndex)


            visualListModel.initVisualListModel()
            if(!app.allowPhotoToSkip)
            {
                if(!app.appModel.count > 0)
                    app.isReadyForSubmitReport = false
            }



        }
    }

    MyControls.Popup {
        id: popupOption
        padding: 10
        width:  isSmallScreen?parent.width:grid.width
        height: app.isIPhoneX ?fldialog.height + 16 * scaleFactor:fldialog.height
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) )

        Material.background: app.pageBackgroundColor
        modal: true
        focus: true

        contentItem:Rectangle {

            id:gridpopup
            width:popupOption - 20 * scaleFactor
            height:app.isIPhoneX?fldialog.height + 16 * scaleFactor:fldialog.height
            color: app.pageBackgroundColor

            ColumnLayout{
                id:fldialog
                spacing: 1 * app.scaleFactor

                anchors.leftMargin: 10 * scaleFactor
                anchors.rightMargin: 10 * scaleFactor


                Text{

                    Layout.topMargin: 10 * scaleFactor
                    text:selectedFileName
                    Layout.preferredWidth:gridpopup.width - 20 * scaleFactor
                    elide: Text.ElideRight
                    font.pixelSize: app.subtitleFontSize
                    font.family: app.customTitleFont.name
                    color: app.textColor

                }
                RowLayout{
                    spacing: 8 * app.scaleFactor
                    Text{

                        text:selectedFileSuffix
                        font.pixelSize: app.subtitleFontSize
                        font.family: app.customTextFont.name
                        color: app.subtitleColor

                    }
                    Rectangle {
                        id:icon
                        width: 4
                        height:4
                        radius: 2
                        color: app.textColor
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text{
                        text:fileSize
                        font.pixelSize: app.subtitleFontSize
                        font.family: app.customTextFont.name
                        color: app.textColor
                    }



                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10 * scaleFactor
                    color: "transparent"

                }

                Rectangle {
                    Layout.preferredWidth: gridpopup.width - 20 * scaleFactor

                    Layout.preferredHeight: 1
                    color: blk_030
                    opacity: 0.6
                }
                Rectangle {

                    Layout.fillWidth: true
                    Layout.preferredHeight: 16 * scaleFactor
                    color: "transparent"

                }
                Rectangle {
                    id:buttonbox
                    Layout.preferredWidth: gridpopup.width - 20 * scaleFactor
                    Layout.preferredHeight: 50 * scaleFactor
                    Layout.bottomMargin: app.isIPhoneX?26 * scaleFactor: 16 * scaleFactor


                    color: "transparent"
                    CustomButton {
                        buttonText: qsTr("Delete")
                        buttonColor:"#FF0000" //app.buttonColor
                        buttonFill: false
                        anchors.left:buttonbox.left

                        buttonHeight: parent.height
                        buttonWidth: (buttonbox.width - 20 * scaleFactor)/2



                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                popupOption.close()

                                deleteAlertBox.text = qsTr("Are you sure you want to delete the file?")+"\n";
                                deleteAlertBox.visible = true;
                                return;

                            }
                        }
                    }
                    CustomButton {
                        id: previewBtn
                        anchors.right: buttonbox.right
                        buttonText: qsTr("Preview")
                        buttonColor: app.buttonColor
                        buttonFill: true
                        buttonHeight: parent.height
                        buttonWidth: (buttonbox.width - 20 * scaleFactor)/2

                        visible: Networking.isOnline

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                popupOption.close()
                                AppFramework.openUrlExternally(selectedFileUrl)
                            }
                        }
                    }

                }





                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight:10 * scaleFactor
                    color: "transparent"

                }
            }
        }
    }



    PictureChooser {
        id: pictureChooser
        outputFolder: mypicturesFolder

        copyToOutputFolder: true

        onAccepted: {
            photoReady = true;

            //------ RESIZE IMAGE -----
            var path = AppFramework.resolvedPath(app.selectedImageFilePath)
            resizeImage(path)
            //------ RESIZE IMAGE -----

            var filePath = "file:///" + path
            filePath = filePath.replace("////","///");

            appModel.append(
                        {path: filePath, type: "attachment"}
                        )

            app.selectedImageFilePath = filePath;

            visualListModel.initVisualListModel();
        }
    }
/*
    AndroidPictureChooser {
        id: androidPictureChooser
        title: qsTr("Select Photo")

        outputFolder {
            path: "~/ArcGIS/AppStudio/Data"
        }

        Component.onCompleted: {
            outputFolder.makeFolder();
        }

        onAccepted: {
            console.log(app.selectedImageFilePath)
            photoReady = true;

            //------ RESIZE IMAGE -----
            var path = AppFramework.resolvedPath(app.selectedImageFilePath)
            resizeImage(path)
            //------ RESIZE IMAGE -----

            var filePath = "file:///" + path
            console.log("Android Path::", filePath)

            appModel.append(
                        {path: filePath.toString(), type: "attachment"}
                        )

            app.selectedImageFilePath = filePath;

            visualListModel.initVisualListModel();
        }
    }
*/
    ConfirmBox{
        id: confirmToSubmit
        anchors.fill: parent
        standardButtons: StandardButton.Yes | StandardButton.No
        text: titleForSubmitInDraft
        informativeText: messageForSubmitInDraft
        onAccepted: {
            submitReport();
        }
    }



    Text{
        id:txtPreviewUrl

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

    function getWidth(parentwidth)
    {
        var no = 5
        if(app.showFileAttachment)
            no += 1
        if(app.supportAudioRecorder)
            no += 1
        if(app.supportVideoRecorder)
            no += 1
        if(app.showAlbum)
            no += 1
        var width = parentwidth/no
        if (width > 48)
            width = 48

        return width

    }

    function fixRotate(url){
        page2_exifInfo.load(url);
        var o = page2_exifInfo.imageValue(ExifInfo.ImageOrientation);
        var exifOrientation = o ? o : 1;

        var exifOrientationAngle = 0;
        switch (exifOrientation) {
        case 3:
            exifOrientationAngle = 180;
            break;

        case 6:
            exifOrientationAngle = 270;
            break;

        case 8:
            exifOrientationAngle = 90;
            break;
        }

        var rotateFix = -exifOrientationAngle;

        if (rotateFix !== 0) {
            imageObject.load(url);
            imageObject.rotate(rotateFix);
            imageObject.save(url);
            exifInfo.setImageValue(ExifInfo.ImageOrientation, 1);
            exifInfo.save(url);
        }
    }

    function initModel()
    {
        visualListModel.initVisualListModel();
    }

    function back(){
        if( webPage !== undefined && webPage !== null  && webPage.visible === true){
            webPage.close();
            app.focus = true;
        }
//        else if(imageViewer !== undefined && imageViewer != null  && imageViewer.visible === true){
//            imageViewer.discardConfirmBox.visible = true;
//        }
        else if(pictureChooser.visible === true){
            pictureChooser.close();
        }
//        else if(cameraWindow.visible === true){
//            cameraWindow.visible = false;
//        }
        else if(previewImageRect.visible === true) {
            if(previewImageRect.renameTextField.focus){
                previewImageRect.renameTextField.focus = false;
                app.focus = true;
            }else if(previewImageRect.discardBox.visible){
                previewImageRect.discardBox.visible = false;
            }else{
                previewImageRect.visible = false;
                previewImageRect.infoPanelVisible = false;
            }
        } else {
            var stackitem = stackView.get(stackView.depth - 2)// var stackitem = stackView.get(stackView.depth - 2)
            if(stackitem.objectName === "summaryPage")
            {
                if(!app.allowPhotoToSkip && app.appModel.count === 0)
                    app.hasAllRequired = false

                app.populateSummaryObject()
                app.steps++;

            }
            app.steps--;
            previous("");
        }
    }
}
