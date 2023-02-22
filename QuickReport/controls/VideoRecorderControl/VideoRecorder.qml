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
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.3
import QtMultimedia 5.8
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../" as SharedControls

Page {
    id: videoRecorder

    // timer properties
    property real maxRecordingTime: 30
    property real remainingTime: maxRecordingTime-timer.times
    property string remainingTimeText: remainingTime > 9 ? remainingTime: ("0" + remainingTime)

    // camera properties
    property real cameraOldZoomScale: 1.0
    property real cameraCurrentZoomScale: 1.0
    property int fixRotation: 0

    // flags
    property bool isBackCamera: true
    property real cameraState: 0 // 0 = ready; 1 = recording; 2 = recorded; 3 = save;

    // video URL + Path
    property var videoUrl
    property var videoPath

    property alias camera: camera

    // signal
    signal saved(var videoSavePath)
    signal back()

    header: ToolBar {
        height: 50 * AppFramework.displayScaleFactor
        Material.elevation: 0
        Material.background: "#202020"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4*AppFramework.displayScaleFactor
            anchors.rightMargin: 4*AppFramework.displayScaleFactor

            CustomizedToolButton {
                id: backBtn

                Layout.preferredHeight: parent.height
                padding: 0
                imageScale: 0.6
                imageSource: enabled? "./images/ic_keyboard_arrow_left_white_48dp.png" : ""
                enabled: cameraState != 1

                onClicked: {
                    camera.stop();
                    discardVideo();
                    cameraState = 0;
                    timer.stop();
                    timer.times = 0;
                    back();
                }
            }

            Label {
                color: remainingTime < 10 ? "red" : "white"
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: !videoPreview.visible ? "00:" + remainingTimeText : ""
                font.pixelSize: 20 * AppFramework.displayScaleFactor
                verticalAlignment: Label.AlignVCenter
                horizontalAlignment: Label.AlignHCenter
                visible: !titleControl.visible
            }

            Item {
                id: titleControl

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: cameraState === 3

                RowLayout {
                    height: parent.height
                    anchors.centerIn: parent
                    visible: titleLabel.text > ""

                    Label {
                        id: titleLabel
                        text: ""
                        Layout.preferredWidth: implicitWidth > titleControl.width*0.7 ? titleControl.width*0.7 : implicitWidth
                        Layout.alignment: Qt.AlignVCenter
                        elide: Label.ElideMiddle
                    }

                    Image {
                        Layout.preferredHeight: titleLabel.height
                        Layout.preferredWidth: titleLabel.height
                        mipmap: true
                        source: "../../images/ic_edit_white_48dp.png"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        renameDialog.openDialog(titleLabel.text);
                        renameDialog.visible = true
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: backBtn.width
            }
        }
    }

    contentItem: Item {
        anchors.fill: parent

        //----------------------------------------------------------------------------
        // Video Recorder

        Camera {
            id: camera

            captureMode: Camera.CaptureVideo
            cameraState: videoRecorder.visible ? Camera.ActiveState : Camera.UnloadedState

            videoRecorder {
                audioEncodingMode: CameraRecorder.AverageBitRateEncoding
                audioBitRate: 64000
                frameRate: 30
                mediaContainer: "mp4"
                outputLocation: videoFolder.path
            }
        }

        VideoOutput {
            id: videoOutput
            source: camera
            autoOrientation: true
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop

            Component.onCompleted: {
                if (Qt.platform.os === "ios") {
                    if (AppFramework.currentCpuArchitecture === "arm64") {
                        autoOrientation = false;
                        orientation = Qt.binding(function () { return (camera.position === Camera.FrontFace) ? ((camera.orientation + 180) % 360) : camera.orientation;} );
                    }
                }
            }

            PinchArea{
                id: pinchArea

                anchors.fill: parent

                property bool isChanging: false

                onPinchStarted: {
                    isChanging = true
                }

                onPinchUpdated: {
                    var cameraCurrentZoomScale1 = pinch.scale*cameraOldZoomScale
                    if(cameraCurrentZoomScale1<1) cameraCurrentZoomScale1=1.0
                    if(cameraCurrentZoomScale1>camera.maximumDigitalZoom) cameraCurrentZoomScale1 = camera.maximumDigitalZoom
                    cameraCurrentZoomScale = cameraCurrentZoomScale1
                    camera.setDigitalZoom(cameraCurrentZoomScale)
                }

                onPinchFinished: {
                    isChanging = false;
                    cameraOldZoomScale = Math.min(Math.max(cameraCurrentZoomScale,1.0),camera.maximumDigitalZoom)
                }
            }
        }

        //----------------------------------------------------------------------------
        // Recorder Controller

        ColumnLayout{
            anchors.fill: parent
            spacing: 0
            opacity: 0.6

            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(parent.height/7, 70*AppFramework.displayScaleFactor)
                color: "transparent"
            }

            RowLayout{
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 0
                Rectangle{
                    Layout.fillHeight: true
                    Layout.preferredWidth: Math.max(30*AppFramework.displayScaleFactor, parent.width*0.15)
                    color: "transparent"
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }

                Rectangle{
                    Layout.fillHeight: true
                    Layout.preferredWidth: Math.max(30*AppFramework.displayScaleFactor, parent.width*0.15)
                    color: "transparent"
                }
            }
        }

        //----------------------------------------------------------------------------
        // Rename Dialog

        SharedControls.CustomizedRenameDialog {
            id: renameDialog

            width: Math.min(400*AppFramework.displayScaleFactor, parent.width*0.8)
            x: (parent.width-width) / 2
            y: (parent.height-height) / 2

            onAccepted: {
                renameVideo(renameDialog.newName);
            }

            onRejected: {
                isNameConflict = false;
            }
        }

        //----------------------------------------------------------------------------
        // Video Playback

        VideoPreview {
            id: videoPreview

            orientation: fixRotation

            width: parent.width
            height: parent.height
            visible: false
        }
    }

    footer: ToolBar {
        height: Math.max(parent.height/7, 70*AppFramework.displayScaleFactor) + (app.isIPhoneX ? 20 * app.scaleFactor : 0)
        Material.elevation: 0
        Material.background: "#424242"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout{
                    id: recorderController

                    anchors.centerIn: parent
                    spacing: Math.max(30*AppFramework.displayScaleFactor, parent.width*0.15)
                    visible: cameraState != 3

                    CustomizedToolButton {
                        Layout.preferredHeight: parent.height
                        padding: 0
                        imageScale: 0.8
                        imageSource: "./images/camera_swtich.png"
                        enabled: QtMultimedia.availableCameras.length>1 && camera.cameraStatus === Camera.ActiveStatus && cameraState!=1

                        onClicked: {
                            switchCamera();
                        }
                    }

                    ToolButton {
                        id: len

                        Layout.alignment: Qt.AlignVCenter

                        property url imageSource: ""
                        property real imageScale: 0.5

                        padding: 0
                        scale: 1.2

                        indicator: Item {
                            anchors.fill: parent

                            Rectangle {
                                width: parent.width
                                height: width
                                radius: width/2
                                color: "white"
                                anchors.centerIn: parent
                            }

                            Rectangle {
                                width: cameraState === 1? parent.width : parent.width * 0.3
                                height: width
                                radius: width/2
                                anchors.centerIn: parent
                                color: "red"
                                Behavior on width {
                                    NumberAnimation {duration: 100}
                                }
                            }

                            Rectangle {
                                width: cameraState === 1? parent.width * 0.3 : 0
                                height: width
                                radius: width*0.1
                                anchors.centerIn: parent
                                color: "white"
                                Behavior on width {
                                    NumberAnimation {
                                        duration: 100
                                        onRunningChanged: {
                                            if(cameraState === 2 && !running) cameraState = 3;
                                        }
                                    }
                                }
                            }
                        }

                        onClicked: {
                            if(cameraState === 0) {
                                startRecordVideo();
                            } else if(cameraState === 1) {
                                stopRecordVideo();
                            }
                        }
                    }

                    CustomizedToolButton {
                        Layout.preferredHeight: parent.height
                        padding: 0
                        imageScale: 0.8
                        imageSource: ""
                        opacity: 0
                        enabled: false
                    }
                }

                RowLayout{
                    id: rowLayout

                    anchors.centerIn: parent
                    spacing: Math.max(30*AppFramework.displayScaleFactor, parent.width*0.15)
                    visible: cameraState === 3

                    CustomizedToolButton {
                        Layout.preferredHeight: parent.height
                        padding: 0
                        imageScale: 0.8
                        imageSource: "./images/ic_local_movies_white_48dp.png"

                        onClicked: {
                            previewVideo();
                        }
                    }

                    ToolButton {
                        Layout.alignment: Qt.AlignVCenter

                        scale: 1.2
                        padding: 0

                        indicator: Item {
                            anchors.fill: parent

                            Rectangle {
                                width: parent.width
                                height: width
                                radius: width/2
                                color: "white"
                                anchors.centerIn: parent
                            }

                            Image{
                                id: doneIcon
                                width: parent.width*0.6
                                height: parent.height*0.6
                                anchors.centerIn: parent
                                source: "./images/done_white.png"
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }

                            ColorOverlay {
                                anchors.fill: doneIcon
                                source: doneIcon
                                smooth: true
                                antialiasing: true
                                color: "red"
                            }
                        }

                        onClicked: {
                            camera.stop();
                            cameraState = 0;
                            timer.times = 0;
                            saved(videoPath);
                        }
                    }

                    CustomizedToolButton {
                        id: discardBtn

                        Layout.preferredHeight: parent.height
                        padding: 0
                        imageScale: 0.8
                        imageSource: "./images/delete.png"

                        onClicked: {
                            discardVideo();
                            cameraState = 0;
                            timer.times = 0;
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: app.isIPhoneX ? 20 * app.scaleFactor : 0
            }
        }
    }

    //----------------------------------------------------------------------------
    // Timer

    Timer {
        id: timer

        property int times: 0

        repeat: true
        interval: 1000
        triggeredOnStart: false

        onTriggered: {
            timer.times += 1;
            if(camera.videoRecorder.recorderState === CameraRecorder.RecordingState && timer.times === maxRecordingTime) {
                stopRecordVideo();
            }
        }
    }



    //----------------------------------------------------------------------------

    function switchCamera() {
        if (QtMultimedia.availableCameras.length > 0) {
            var cameraIndex = 0;

            for (var i = 0; i < QtMultimedia.availableCameras.length; i++)
            {
                if (QtMultimedia.availableCameras[i].deviceId === camera.deviceId) {
                    cameraIndex = i;
                    break;
                }
            }

            cameraIndex = (cameraIndex + 1) % QtMultimedia.availableCameras.length;
            if(QtMultimedia.availableCameras.length>1) isBackCamera = !isBackCamera;

            camera.stop();
            camera.deviceId = QtMultimedia.availableCameras[cameraIndex].deviceId;
            cameraCurrentZoomScale = 1.0
            cameraOldZoomScale = 1.0
            camera.start();
        }
    }

    function startRecordVideo(){
        if (Qt.platform.os === "ios") {
            if (AppFramework.currentCpuArchitecture === "arm64") {
                fixRotation = (camera.position === Camera.FrontFace) ? ((camera.orientation + 180) % 360) : camera.orientation;
            }
        }

        camera.videoRecorder.record();
        timer.times = 0;
        timer.start();
        cameraState = 1;
    }

    function stopRecordVideo(){
        timer.stop();
        cameraState = 2;
        camera.videoRecorder.stop();

        videoUrl = camera.videoRecorder.actualLocation;
        videoPath = AppFramework.urlInfo(videoUrl).localFile;
    }

    function previewVideo(){
        videoPreview.load(videoUrl);
        videoPreview.visible = true;
    }

    function discardVideo(){
        if(camera.videoRecorder.actualLocation>"") {
            try {
                var videoFileInfo = AppFramework.fileInfo(camera.videoRecorder.actualLocation);
                var fileName = videoFileInfo.fileName;
                if(videoFolder.fileExists(fileName)) videoFolder.removeFile(fileName);
            } catch (e) {
                console.log("Error: failed to remove video file.");
            }
        }
    }

    function stopCamera(){
        camera.stop();
    }

    function renameVideo(newName){
        if(videoPath>"" && newName > "") {
            try {
                var videoFileInfo = AppFramework.fileInfo(videoPath);
                var oldName = videoFileInfo.fileName;
                var arr = newName.split(".");

                var newFileName = "";
                if(arr.length === 2) newFileName = arr[0];

                if(!videoFolder.fileExists(newName) && newFileName > ""){
                    if(videoFolder.fileExists(oldName)) videoFolder.renameFile(oldName, newName);
                    videoPath = videoFolder.fileInfo(newName).filePath;
                    videoUrl = videoFolder.fileInfo(newName).url;
                    renameDialog.isNameConflict = false;
                } else {
                    renameDialog.isNameConflict = true;
                    renameDialog.open();
                }
            } catch (e) {
                console.log("Error: failed to rename video file.");
            }
        }
    }

    //----------------------------------------------------------------------------
    // Init of camera

    Component.onCompleted: {
        Screen.orientationUpdateMask = Qt.PortraitOrientation | Qt.InvertedLandscapeOrientation | Qt.InvertedPortraitOrientation | Qt.LandscapeOrientation

        if (QtMultimedia.availableCameras.length > 0) {
            var cameraIndex = 0;

            for (var i = 0; i < QtMultimedia.availableCameras.length; i++) {
                if (QtMultimedia.availableCameras[i].deviceId === camera.deviceId) {
                    cameraIndex = i;
                    console.log("camera device found:", i, camera.deviceId);
                    break;
                }
                if (QtMultimedia.availableCameras[i].position === Camera.BackFace) {
                    cameraIndex = i;
                    break;
                }
            }

            camera.deviceId = QtMultimedia.availableCameras[cameraIndex].deviceId;
            if(Qt.platform.os !== "windows") camera.start();
        }
    }

    onVideoPathChanged: {
        try {
            var videoFileInfo = AppFramework.fileInfo(videoPath);
            var fileName = videoFileInfo.fileName;
            titleLabel.text = fileName;
        } catch(e) {
            titleLabel.text = "";
        }
    }

    onVisibleChanged: {
        try {
            if(visible) camera.start();
            else camera.stop();
        } catch(e) {
            console.log(e);
        }
    }
}

