import QtQuick 2.7
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.3
import QtMultimedia 5.8
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../" as SharedControls

Rectangle {
    id: videoPreview

    // alias for video orientation, interface for orientation issue
    property alias orientation: video.orientation
    property url videoUrl
    property bool isPreviewMode: false

    // signal
    signal discard()
    signal dirty(var videoPath)

    color: "black"

    Video {
        id: video

        anchors.fill: parent
        focus: true

        // video controller
        MouseArea {
            anchors.fill: parent
            enabled: !playBtn.visible
            onClicked: {
                video.pause();
            }
        }

        ToolButton {
            id: playBtn

            width: 50*AppFramework.displayScaleFactor
            height: width
            anchors.centerIn: parent
            padding: 0
            scale: 1.2
            visible: video.playbackState !== MediaPlayer.PlayingState
            enabled: visible

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
                    id: playIcon
                    width: parent.width*0.6
                    height: parent.height*0.6
                    anchors.centerIn: parent
                    source: video.playbackState === MediaPlayer.PlayingState ? "": video.playbackState === MediaPlayer.PausedState? "./images/ic_pause_white_48dp.png" : "./images/ic_play_arrow_white_48dp.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                ColorOverlay {
                    anchors.fill: playIcon
                    source: playIcon
                    smooth: true
                    antialiasing: true
                    color: "#424242"
                }
            }

            onClicked: {
                video.play();
            }
        }
    }

    //----------------------------------------------------------------------------
    // header

    ToolBar {
        width: parent.width
        height: 50 * AppFramework.displayScaleFactor
        anchors.top: parent.top
        Material.elevation: 0
        Material.background: "#00000000"
        padding: 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4*AppFramework.displayScaleFactor
            anchors.rightMargin: 4*AppFramework.displayScaleFactor

            CustomizedToolButton {
                id: backBtn

                Layout.preferredHeight: parent.height
                padding: 0
                imageScale: 0.5
                imageSource: "./images/ic_close_white_48dp.png"

                onClicked: {
                    video.stop();
                    stackView.pop();
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true

                CustomizedToolButton {
                    id: rotateBtn

                    height: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter

                    padding: 0
                    imageScale: 0.5
                    imageSource: "./images/ic_rotate_90_degrees_ccw_white_48dp.png"

                    visible: isPreviewMode
                    enabled: isPreviewMode

                    onClicked: {
                        video.orientation += 90;
                    }
                }
            }

            CustomizedToolButton {
                id: rotateBtn2

                Layout.preferredHeight: parent.height

                padding: 0
                imageScale: 0.5
                imageSource: "./images/ic_rotate_90_degrees_ccw_white_48dp.png"

                visible: !isPreviewMode
                enabled: !isPreviewMode

                onClicked: {
                    video.orientation += 90;
                }
            }

            CustomizedToolButton {
                id: deleteBtn

                Layout.preferredHeight: parent.height
                padding: 0
                imageScale: 0.5
                imageSource: "./images/delete.png"

                visible: isPreviewMode
                enabled: isPreviewMode

                onClicked: {
                    video.stop();
                    discard();
                }
            }

        }
    }

    //----------------------------------------------------------------------------
    // footer

    ToolBar {
        width: parent.width
        height: 50 * AppFramework.displayScaleFactor + (app.isIPhoneX ? 20 * app.scaleFactor : 0)
        anchors.bottom: parent.bottom
        Material.elevation: 0
        Material.background: "#00000000"
        padding: 0

        Item {
            id: titleControl

            width: parent.width*0.8
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: app.isIPhoneX ? 20 * app.scaleFactor : 0
            visible: isPreviewMode

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
                    video.stop();
                    renameDialog.openDialog(titleLabel.text);
                    renameDialog.visible = true
                }
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


    function load(source) {
        videoUrl = source;
        video.source = source;
        if(video.seekable) video.seek(10);
    }

    function discardVideo(){
        if(videoUrl>"") {
            try {
                var videoFileInfo = AppFramework.fileInfo(videoUrl);
                var fileName = videoFileInfo.fileName;
                if(videoFolder.fileExists(fileName)) videoFolder.removeFile(fileName);
            } catch (e) {
                console.log("Error: failed to remove video file.");
            }
        }
    }

    function renameVideo(newName){
        if(videoUrl>"" && newName > "") {
            try {
                var videoFileInfo = AppFramework.fileInfo(videoUrl);
                var oldName = videoFileInfo.fileName;
                var arr = newName.split(".");

                var newFileName = "";
                if(arr.length === 2) newFileName = arr[0];
                var vfolder = videoFileInfo.folder

                if(!vfolder.fileExists(newName) && newFileName > ""){
                    if(vfolder.fileExists(oldName)) vfolder.renameFile(oldName, newName);
                    videoUrl = vfolder.fileInfo(newName).url;
                    load(videoUrl);
                    renameDialog.isNameConflict = false;
                    var filePath = AppFramework.urlInfo(videoUrl).localFile;
                    dirty(filePath);
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

    onVideoUrlChanged: {
        try {
            var videoFileInfo = AppFramework.fileInfo(videoUrl);
            var fileName = videoFileInfo.fileName;
            titleLabel.text = fileName;
        } catch(e) {
            titleLabel.text = "";
        }
    }
}
