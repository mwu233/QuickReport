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
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Multimedia 1.0

import "../" as SharedControls

Page {
    id: customizedAudioRecorder

    // timer properties
    property real maxRecordingTime: 120
    property real remainingTime: maxRecordingTime-timer.times

    // color settings
    property color primaryColor: "#424242"
    property color backgroundColor: "white"

    // audio recorder
    property real audioState: 0 // 0 = ready; 1 = recording; 2 = pause; 3 = recorded; 4 = save; 5 = continue

    // audio file url
    property url actualLocation

    // signal
    signal saved(var audioPath)
    signal back()

    //--------------------------------------------------------------------------
    // audio recorder

    AudioRecorder {
        id: audioRecorder

        outputLocation: audioFolder.url

        onErrorChanged: {
            console.log("audioRecorder error:", error, "errorString:", errorString);
        }
    }

    //----------------------------------------------------------------------------

    Timer {
        id: timer

        property int times: 0
        property int count: 0

        repeat: true
        interval: 100
        triggeredOnStart: false

        onTriggered: {
            count+=100;
            if(count % 1000 === 0) {
                timer.times += 1;
                if(audioRecorder.status === AudioRecorder.RecordingStatus && timer.times === maxRecordingTime) {
                    audioRecorder.stop();
                    customizedAudioRecorder.actualLocation = audioRecorder.actualLocation;
                    audioState = 4;
                    timer.stop();
                }
            }
        }

        function reset(){
            timer.stop();
            timer.times = 0;
            timer.count = 0;
        }
    }

    //----------------------------------------------------------------------------

    function timeText(s) {
        if (s < 0) {
            return "--:--";
        }

        var minutes = Math.floor(s / 60);
        var seconds = Math.floor(s - minutes * 60);

        function zNum(n) {
            return n < 10 ? "0" + n.toString() : n.toString();
        }

        return "%1:%2".arg(zNum(minutes)).arg(zNum(seconds));
    }

    onAudioStateChanged: {
        console.log("audioState:", audioState);

        switch(audioState) {
        case 1:
            timer.restart();
            audioRecorder.record();
            break;

        case 2:
            audioRecorder.pause();
            timer.stop();
            break;

        case 3:
            console.log("audio recorder stop")
            audioRecorder.stop();
            customizedAudioRecorder.actualLocation = audioRecorder.actualLocation;
            timer.stop();
            break;

        case 5:
            timer.start();
            audioRecorder.record();
            break;

        default:
            break;
        }
    }

    function discardAudio() {
        if(customizedAudioRecorder.actualLocation>"") {
            try {
                var audioFileInfo = AppFramework.fileInfo(AppFramework.urlInfo(customizedAudioRecorder.actualLocation).localFile);
                var fileName = audioFileInfo.fileName;
                if(audioFolder.fileExists(fileName)) audioFolder.removeFile(fileName);
                customizedAudioRecorder.actualLocation = "";
            } catch (e) {
                console.log("Error: failed to remove audio file.");
            }
        }
    }

    function renameAudio(newName){
        if(customizedAudioRecorder.actualLocation>"" && newName > "") {
            try {
                var audioFileInfo = AppFramework.fileInfo(AppFramework.urlInfo(customizedAudioRecorder.actualLocation).localFile);
                var oldName = audioFileInfo.fileName;
                var arr = newName.split(".");

                var newFileName = "";
                if(arr.length === 2) newFileName = arr[0];

                if(!audioFolder.fileExists(newName) && newFileName > ""){
                    if(audioFolder.fileExists(oldName)) audioFolder.renameFile(oldName, newName);
                    customizedAudioRecorder.actualLocation = audioFolder.fileInfo(newName).url;
                    renameDialog.isNameConflict = false;
                } else {
                    renameDialog.isNameConflict = true;
                    renameDialog.open();
                }
            } catch (e) {
                console.log("Error: failed to rename audio file.");
            }
        }
    }

    //----------------------------------------------------------------------------
    // audio folder

    FileFolder{
        id: audioFolder

        path: "~/ArcGIS/AppStudio/"+ app.itemId +"/Data/Audio"

        Component.onCompleted: {
            makeFolder();
        }
    }

    // header
    header: ToolBar {
        height: 50 * AppFramework.displayScaleFactor
        Material.background: primaryColor
        Material.elevation: 0

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
                enabled: audioState!=1 && audioState!=5

                onClicked: {
                    discardAudio();
                    audioState = 0;
                    timer.times = 0;
                    timer.count = 0;
                    customizedAudioRecorder.actualLocation = "";
                    back();
                }
            }

            Item {
                id: titleControl

                Layout.fillWidth: true
                Layout.fillHeight: true

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
                        source: "./images/ic_edit_white_48dp.png"
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

            CustomizedToolButton {
                Layout.preferredHeight: parent.height
                padding: 0
                imageScale: 0.6
                imageSource: ""
                enabled: false
            }
        }
    }

    //----------------------------------------------------------------------------

    contentItem: Item {
        anchors.fill: parent

        ColumnLayout{
            anchors.fill: parent
            spacing: 0
            //----------------------------------------------------------------------------
            // content

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true

                Rectangle {
                    anchors.fill: parent
                    color: primaryColor//Qt.darker(primaryColor, 1.5)
                }

                CustomizedProgressBar {
                    id: progressBar

                    width: Math.min(parent.width*0.8, 230*AppFramework.displayScaleFactor)
                    height: Math.min(parent.width*0.8, 230*AppFramework.displayScaleFactor)
                    anchors.centerIn: parent

                    backgroundColor: "#212121"
                    accentColor: remainingTime >= Math.min(5, maxRecordingTime/10) ? "white" : "red"
                    labelText: ""//timeText(remainingTime*1000)
                    value: timer.count / maxRecordingTime / 1000
                    weight: 5
                }

                Image {
                    id: sourceImg
                    width: Math.min(parent.width*0.8, 230*AppFramework.displayScaleFactor) * 0.6
                    height: width
                    anchors.centerIn: progressBar

                    source: "./images/mic.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    opacity: 1
                }

                Glow {
                    id: glow

                    anchors.fill: sourceImg
                    visible: audioState === 1 || audioState === 5
                    source: sourceImg
                    radius: 8
                    samples: 17
                    color: Material.color(Material.Indigo)
                }

                SequentialAnimation {
                    loops: Animation.Infinite
                    running: glow.visible

                    NumberAnimation {
                        target: glow
                        property: "radius"
                        duration: 1000
                        from: 0
                        to: 8
                        easing.type: Easing.InOutQuart
                    }

                    NumberAnimation {
                        target: glow
                        property: "radius"
                        duration: 1000
                        from: 8
                        to: 0
                        easing.type: Easing.InOutQuart
                    }
                }

                Label {
                    anchors.top: progressBar.bottom
                    anchors.topMargin: 20*AppFramework.displayScaleFactor
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: timeText(remainingTime)
                    font.pixelSize: 20*AppFramework.displayScaleFactor
                    color: progressBar.accentColor
                }

            }

            //----------------------------------------------------------------------------
            // footer

            ToolBar {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(parent.height/7, 70*AppFramework.displayScaleFactor) + (app.isIPhoneX ? 20 * app.scaleFactor : 0)
                Material.background: primaryColor

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        RowLayout{
                            id: recorderController

                            height: parent.height
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Math.max(30*AppFramework.displayScaleFactor, parent.width*0.15)

                            ToolButton {
                                id: pauseController

                                Layout.preferredHeight: parent.height*0.8

                                property url imageSource: ""
                                property real imageScale: 0.5

                                enabled: false//audioState === 1 || audioState === 5 || audioState === 2

                                padding: 0

                                indicator: Item {
                                    anchors.fill: parent
                                    visible: pauseController.enabled
                                    Rectangle {
                                        width: parent.width
                                        height: width
                                        radius: width/2
                                        color: "white"
                                        anchors.centerIn: parent
                                    }

                                    Rectangle {
                                        width: (audioState === 1 || audioState === 0 || audioState === 5)? parent.width : parent.width * 0.3
                                        height: width
                                        radius: width/2
                                        anchors.centerIn: parent
                                        color: "red"

                                        Behavior on width {
                                            NumberAnimation {duration: 100}
                                        }
                                    }

                                    Image {
                                        width: (audioState === 1 || audioState === 0 || audioState === 5)? parent.width * 0.4 : 0
                                        height: width
                                        anchors.centerIn: parent
                                        source: "./images/pause.png"
                                        fillMode: Image.PreserveAspectFit

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 100
                                            }
                                        }
                                    }
                                }

                                onClicked: {
                                    if(audioState === 1 || audioState === 5) {
                                        audioState = 2; // pause recording
                                    } else if(audioState === 2){
                                        audioState = 5; // resume recording
                                    }
                                }
                            }

                            ToolButton {
                                id: recorder

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
                                        width: (audioState === 1 || audioState === 5 || audioState === 2)? parent.width : parent.width * 0.3
                                        height: width
                                        radius: width/2
                                        anchors.centerIn: parent
                                        color: "red"

                                        Behavior on width {
                                            NumberAnimation {duration: 100}
                                        }
                                    }

                                    Rectangle {
                                        width: (audioState === 1 || audioState === 5 || audioState === 2)? parent.width * 0.3 : 0
                                        height: width
                                        radius: width*0.1
                                        anchors.centerIn: parent
                                        color: "white"

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 100
                                                onRunningChanged: {
                                                    if(audioState === 3 && !running) audioState = 4;
                                                }
                                            }
                                        }
                                    }
                                }

                                onClicked: {
                                    if(audioState === 0) {
                                        audioState = 1; // start recording
                                    } else if(audioState === 1 || audioState === 2 || audioState === 5){
                                        audioState = 3; // stop recording
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
                            height: parent.height
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Math.max(30*AppFramework.displayScaleFactor, parent.width*0.15)
                            visible: audioState === 4

                            CustomizedToolButton {
                                Layout.preferredHeight: parent.height
                                padding: 0
                                imageScale: 0.8
                                imageSource: "./images/file-music.png"

                                onClicked: {
                                    var audioPlayer = audioPlayerComponent.createObject(null);
                                    audioPlayer.loadSource(customizedAudioRecorder.actualLocation);
                                    stackView.push(audioPlayer);
                                }
                            }

                            ToolButton {
                                Layout.preferredHeight: parent.height
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
                                    var filePath = AppFramework.urlInfo(customizedAudioRecorder.actualLocation).localFile;
                                    saved(filePath);
                                    customizedAudioRecorder.actualLocation = "";
                                    audioState = 0;
                                    timer.times = 0;
                                    timer.count = 0;
                                }
                            }

                            CustomizedToolButton {
                                id: discardBtn

                                Layout.preferredHeight: parent.height
                                padding: 0
                                imageScale: 0.8
                                imageSource: "./images/delete.png"

                                onClicked: {
                                    discardAudio();
                                    audioState = 0;
                                    timer.times = 0;
                                    timer.count = 0;
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
        }
    }

    onActualLocationChanged: {
        try {
            var audioFileInfo = AppFramework.fileInfo(AppFramework.urlInfo(customizedAudioRecorder.actualLocation).localFile);
            var fileName = audioFileInfo.fileName;
            titleLabel.text = fileName;
        } catch(e) {
            titleLabel.text = "";
        }
    }

    SharedControls.CustomizedRenameDialog {
        id: renameDialog

        width: Math.min(400*AppFramework.displayScaleFactor, parent.width*0.8)
        x: (parent.width-width) / 2
        y: (parent.height-height) / 2

        onAccepted: {
            renameAudio(renameDialog.newName);
        }

        onRejected: {
            isNameConflict = false;
        }
    }

    Component {
        id: audioPlayerComponent

        CustomizedAudioPlayer {
            isPreviewMode: false
        }
    }
}
