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

//------------------------------------------------------------------------------

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

Item {
    id: pictureChooser

    property string title: qsTr("Pictures")
    property FileFolder outputFolder
    //property alias outputFolder: outputFolder
    property bool copyToOutputFolder: true
    property bool useFileDialog: Qt.platform.os != "ios"

    property url pictureUrl

    signal accepted()
    signal rejected()

    //--------------------------------------------------------------------------

    QtObject {
        id: internal

        property var uiComponent
    }


    //--------------------------------------------------------------------------

    Component {
        id: fileDialogComponent


        FileDialog {
            id: fileDialog
            title: pictureChooser.title
            folder: Qt.platform.os == "ios"
                    ? "file:assets-library://":shortcuts.pictures
            nameFilters: ["Image files (*.jpg *.png *.gif *.jpeg *.tif *.tiff)"]
            onAccepted: {
                // console.log("You chose: " + fileDialog.fileUrl)
                if(fileDialog.fileUrl)
                {
                    pictureUrl = fileDialog.fileUrl
                    var didload = imageObject.load(pictureUrl)
                    if(didload)
                    {
                        pictureChooser.accepted()
                        var fileInfo = AppFramework.fileInfo(fileDialog.fileUrl);
                    }
                }
            }
            onRejected: {
                pictureChooser.rejected();
            }

        }


    }

    //--------------------------------------------------------------------------

    Component {
        id: pictureChooserComponent

        Rectangle {
            property string picturesPath: AppFramework.standardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
            property var picturesModel

            anchors.fill: parent
            color: palette.window

            Component.onCompleted: {
                refreshPictures();
            }

            SystemPalette {
                id: palette

                colorGroup: SystemPalette.Active
            }

            ColumnLayout {
                anchors.fill: parent

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: titleRow.height + 2 * AppFramework.displayScaleFactor

                    color: "darkgrey"

                    RowLayout
                    {
                        id: titleRow

                        anchors {
                            topMargin: 2 * AppFramework.displayScaleFactor
                            left: parent.left
                            right: parent.right
                        }

                        Button {
                            Layout.alignment: Qt.AlignLeft

                            text: qsTr("<")

                            onClicked: {
                                pictureChooser.rejected();
                                close();
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter

                            text: pictureChooser.title
                            color: "white"
                            font {
                                pointSize: 24
                            }
                        }

                    }
                }

                Text {
                    text: testJSON //picturesPath
                    visible: false
                }

                GridView {
                    id: picturesGridView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: picturesModel
                    clip: true

                    cellWidth: 200 * AppFramework.displayScaleFactor
                    cellHeight: 115 * AppFramework.displayScaleFactor

                    delegate: pictureDelegate
                }
            }

            FileFolder {
                id: picturesFolder

                path: picturesPath
            }

            Component {
                id: pictureDelegate

                Item {
                    width: picturesGridView.cellWidth
                    height: picturesGridView.cellHeight

                    Rectangle {
                        anchors {
                            fill: parent
                            margins: 5 * AppFramework.displayScaleFactor
                        }

                        color: "lightgrey"

                        border {
                            color: "black"
                            width: 1
                        }

                        Image {
                            anchors {
                                fill: parent
                                margins: 1
                            }

                            fillMode: Image.PreserveAspectFit
                            source: picturesFolder.fileUrl(modelData)

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }

                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                text: modelData
                                horizontalAlignment: Text.AlignHCenter
                                style: Text.Raised
                                styleColor: "black"
                                color: "white"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                pictureChooser.pictureUrl = picturesFolder.fileUrl(modelData);
                                pictureChooser.accepted();
                                close();
                            }
                        }
                    }
                }
            }

            function open() {
                visible = true;
            }

            function close() {
                visible = false;
            }

            function refreshPictures() {
                picturesModel = picturesFolder.fileNames("*.jpg");

                //console.log(JSON.stringify(picturesModel));
            }
        }
    }

    //--------------------------------------------------------------------------

    ImageObject{
        id: imageObject
    }

    onAccepted: {
        internal.uiComponent = null;
        var pictureUrlInfo = AppFramework.urlInfo(pictureUrl);
        var picturePath = pictureUrlInfo.localFile;
        var assetInfo = AppFramework.urlInfo(picturePath);
        var outputFileName;
        var suffix=""
        if(pictureUrlInfo.fileName)
            suffix = pictureUrlInfo.fileName.split('.')[1]
        if(!suffix)
            suffix="jpg"

        if (assetInfo.scheme === "assets-library") {
            pictureUrl = assetInfo.url;
            outputFileName = assetInfo.queryParameters.id + "." + assetInfo.queryParameters.ext;
        } else {
            outputFileName = AppFramework.createUuidString(2) + "." + suffix
            //console.log("outputFileName", outputFileName);
        }

        photoReady = true;

        if (copyToOutputFolder) {
            var outputFileInfo = outputFolder.fileInfo(outputFileName);

            //workaround for HEIC file format to be converted to jpg
            if (outputFileName.match(/\.hei(c|f)$/i)) {
                imageObject.load(picturePath);

                outputFileName = outputFileName.replace(/\.[a-z]*$/i, ".jpg");
                outputFileInfo = outputFolder.fileInfo(outputFileName);

                outputFolder.removeFile(outputFileName);

                if (!imageObject.save(outputFileInfo.filePath)) {
                    console.error("Unable to save image:", outputFileInfo.filePath);
                    return;
                }
                picturePath = outputFolder.filePath(outputFileName);
            } else {
                //imageObject.load(pictureUrl)
                outputFolder.removeFile(outputFileName);
                var issaved = imageObject.save(outputFileInfo.filePath)
                //outputFolder.copyFile(picturePath, outputFileInfo.filePath);
            }

            picturePath = outputFolder.filePath(outputFileName);
        }

        console.log(pictureUrlInfo, picturePath, assetInfo, outputFileName)

        app.selectedImageFilePath = picturePath;
    }

    onRejected: {
        internal.uiComponent = null;
    }

    //--------------------------------------------------------------------------

    function open() {
        console.log("FileDialog", useFileDialog)
        //        if (useFileDialog) {
        //            internal.uiComponent = fileDialogComponent.createObject(pictureChooser.parent);
        //        } else {
        //            internal.uiComponent = pictureChooserComponent.createObject(pictureChooser.parent);
        //        }
        internal.uiComponent = fileDialogComponent.createObject(pictureChooser.parent);
        internal.uiComponent.open();
    }

    //--------------------------------------------------------------------------

    function close() {
        if (internal.uiComponent) {
            internal.uiComponent.close();
            internal.uiComponent = null;
        }
    }

    //--------------------------------------------------------------------------

    property var testJSON
}

