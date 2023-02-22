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
import QtQuick.Window 2.0
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

Page {
    id: sketch

    property var imageUrl

    property var exif_latitude
    property var exif_longtitude
    property var exif_altitude
    property var sourceFileName

    property url defaultImageUrl
    property bool isNull: loaded && canvas.isNull && !imageUrl && pasteImageObject.empty
    property bool loaded: true
    property var saveUrl

    property string discardString: qsTr("Are you sure you want to discard all changes?")
    property string saveString: qsTr("Are you sure you want to save changes and close?")

    property bool useImageObject: true

    readonly property string kTempFileName: "$$canvas-temp.jpg"

    property FileFolder workFolder
    property alias canvas: canvas

    //--------------------------------------------------------------------------

    signal penReleased()
    signal discard()
    signal saved();

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (defaultImageUrl > "")
        {
            console.log("Initialize sketch default:", defaultImageUrl);

            if (!defaultImageObject.load(defaultImageUrl)) {
                console.error("Failed to load:", defaultImageUrl);
                return;
            }

            canvas.requestPaint();
        }
    }

    //--------------------------------------------------------------------------

    header: ToolBar {
        width: parent.width
        height: 50 * AppFramework.displayScaleFactor

        Material.background: "#424242"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4*AppFramework.displayScaleFactor
            anchors.rightMargin: 4*AppFramework.displayScaleFactor

            CustomizedToolButton {
                Layout.preferredHeight: parent.height
                padding: 0
                imageScale: 0.6
                imageSource: "./images/ic_keyboard_arrow_left_white_48dp.png"

                onClicked: {
                    if(!canvas.isNull) confirmDialog.open();
                    else {
                        var filePath = workFolder.filePath(AppFramework.urlInfo(imageUrl).localFile);
                        var fileName = AppFramework.fileInfo(filePath).fileName;
                        workFolder.removeFile(fileName);

                        pasteImageObject.clear();
                        clearVectors();
                        sketch.visible = false;
                    }
                    discard();
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            CustomizedSwitch {
                id: control
                checked: canvas.smartMode
                visible: drawLineBtn.checked
                onCheckedChanged: {
                    canvas.smartMode = checked;
                    var toastString = canvas.smartMode? qsTr("Smart Draw: On"):qsTr("Smart Draw: Off");
                    toast.show(toastString, 1000);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    footer: TabBar {
        width: parent.width
        height: 50 * AppFramework.displayScaleFactor + (app.isIPhoneX ? 20 * app.scaleFactor : 0)
        bottomPadding: app.isIPhoneX ? 20 * app.scaleFactor : 0

        Material.background: "#424242"
        Material.accent: canvas.penColor

        CustomizedTabButton{
            id: drawLineBtn

            height: parent.height

            imageSource: "./images/curve_3.png"
            highlighted: false

            onClicked: {
                canvas.lineMode = true;
                canvas.arrowMode = false;
            }
        }

        CustomizedTabButton{
            id: drawArrowBtn

            height: parent.height

            property bool isSmartBefore: false

            imageSource: "./images/arrow_1.png"
            highlighted: false

            onCheckedChanged: {
                if(!checked) {
                    canvas.smartMode = isSmartBefore;
                }
            }

            onClicked: {
                isSmartBefore = canvas.smartMode;
                canvas.smartMode = false;
                canvas.lineMode = true;
                canvas.arrowMode = true;
            }
        }

        CustomizedTabButton{
            id: addTextBtn

            height: parent.height

            imageSource: "./images/ic_title_white_48dp.png"
            highlighted: false

            onClicked: {
                canvas.lineMode = false;
                canvas.arrowMode = false;
            }
        }

        CustomizedTabButton{
            height: parent.height

            imageSource: "./images/undo-variant.png"
            enabled: !canvas.isNull
            highlighted: false
            checkable: false

            onClicked: {
                canvas.deleteLastSketch();
            }
        }

        CustomizedTabButton{
            height: parent.height

            imageSource: "./images/ic_done_white_48dp.png"
            enabled: !canvas.isNull
            highlighted: false
            checkable: false

            onClicked: {
                saveDialog.open();
            }
        }
    }

    //--------------------------------------------------------------------------

    Item {
        id: content

        anchors.fill: parent

        //--------------------------------------------------------------------------

        SketchCanvas {
            id: canvas

            anchors.fill: parent

            settings: app.settings

            onPressedChanged: {
                if(pressed) colorController.isSelecting = false;
            }

            Component.onDestruction: {
                console.log("Destroying sketch canvas")
                if (imageUrl && isImageLoaded(imageUrl)) {
                    console.log("Unloading:", imageUrl);
                    unloadImage(imageUrl);
                }
            }

            paintBackground: function (ctx) {

                ctx.fillStyle = sketch.color;
                ctx.fillRect(0, 0, canvas.width, canvas.height);

                if (imageUrl && isImageLoaded(imageUrl)) {
                    ctx.drawImage(imageUrl, 0, 0);
                }

                if (!defaultImageObject.empty && currentImageObject.empty && pasteImageObject.empty) {
                    var rect = fitImageObject(defaultImageObject);
                    ctx.drawImage(defaultImageObject.url, rect.x, rect.y, rect.width, rect.height);
                }

                if (!currentImageObject.empty) {
                    ctx.drawImage(currentImageObject.url, 0, 0);
                }

                if (!pasteImageObject.empty) {                   
                    ctx.drawImage(pasteImageObject.url, pasteImageObject.offsetX, pasteImageObject.offsetY);
                }
            }

            onImageLoaded: {
                console.log("onImageLoaded:", imageUrl);
                requestPaint();
            }

        }

        //--------------------------------------------------------------------------

        Toast {
            id: toast
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10*AppFramework.displayScaleFactor
        }

        //--------------------------------------------------------------------------

        // color

        Item {
            width: 40*AppFramework.displayScaleFactor
            height: colorController.isSelecting? colorController.height : 40*AppFramework.displayScaleFactor
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 8*AppFramework.displayScaleFactor

            ColumnLayout{
                id: colorController

                width: 48*AppFramework.displayScaleFactor
                spacing: 0

                property bool isSelecting: false

                Repeater {
                    model: ["#ff0000",
                        "#ffa500",
                        "#ffff00",
                        "#00ff00",
                        "#00b2ff",
                        "#000000",
                        "#ffffff"]

                    delegate: RoundButton {
                        Layout.preferredHeight: parent.width
                        Layout.preferredWidth: parent.width
                        Material.background: modelData
                        visible: (modelData === canvas.penColor.toString() || colorController.isSelecting)

                        indicator: Image {
                            width: parent.width*0.6
                            height: parent.height*0.6
                            anchors.centerIn: parent
                            source: "./images/ic_color_lens_white_48dp.png"
                            mipmap: true
                            fillMode: Image.PreserveAspectFit
                            visible: !colorController.isSelecting
                        }

                        enabled: !canvas.textInput.visible || addTextBtn.checked

                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                if(colorController.isSelecting) {
                                    canvas.penColor = modelData;
                                }
                                if(addTextBtn.checked) {
                                    canvas.textInputColor = modelData;
                                }

                                colorController.isSelecting = !colorController.isSelecting
                            }
                        }
                    }
                }
            }
        }

        //--------------------------------------------------------------------------

        // text

        Item {
            id: textController

            width: parent.width
            height: 40*AppFramework.displayScaleFactor
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4*AppFramework.displayScaleFactor
            visible: addTextBtn.checked

            RowLayout{
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.textScale === 1.0

                    imageSource: "./images/ic_title_white_48dp.png"
                    imageScale: 0.7

                    onClicked: {
                        canvas.textScale = 1.0;
                    }
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.textScale === 1.5
                    imageScale: 1.0

                    imageSource: "./images/ic_title_white_48dp.png"

                    onClicked: {
                        canvas.textScale = 1.5;
                    }
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.textScale === 2.0

                    imageSource: "./images/ic_title_white_48dp.png"
                    imageScale: 1.3

                    onClicked: {
                        canvas.textScale = 2.0;
                    }
                }
            }
        }

        //--------------------------------------------------------------------------

        // line
        Item {
            id: lineController

            width: parent.width
            height: 40*AppFramework.displayScaleFactor
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4*AppFramework.displayScaleFactor
            visible: drawLineBtn.checked

            RowLayout{
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.penWidth === 1.0

                    imageSource: "./images/curve_1.png"

                    onClicked: {
                        canvas.penWidth = 1.0;
                    }
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.penWidth === 3.0

                    imageSource: "./images/curve_3.png"

                    onClicked: {
                        canvas.penWidth = 3.0;
                    }
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.penWidth === 5.0

                    imageSource: "./images/curve_5.png"

                    onClicked: {
                        canvas.penWidth = 5.0;
                    }
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.penWidth === 10.0

                    imageSource: "./images/curve_10.png"

                    onClicked: {
                        canvas.penWidth = 10.0;
                    }
                }
            }
        }

        //--------------------------------------------------------------------------


        // arrow
        Item {
            id: arrowController

            width: parent.width
            height: 40*AppFramework.displayScaleFactor
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4*AppFramework.displayScaleFactor
            visible: drawArrowBtn.checked

            RowLayout{
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.penWidth === 1.0

                    imageSource: "./images/arrow_1.png"

                    onClicked: {
                        canvas.penWidth = 1.0;
                    }
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.penWidth === 3.0

                    imageSource: "./images/arrow_3.png"

                    onClicked: {
                        canvas.penWidth = 3.0;
                    }
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.penWidth === 5.0

                    imageSource: "./images/arrow_5.png"

                    onClicked: {
                        canvas.penWidth = 5.0;
                    }
                }

                CustomizedRoundedButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.height
                    Material.background: "#424242"
                    chosen: canvas.penWidth === 10.0

                    imageSource: "./images/arrow_10.png"

                    onClicked: {
                        canvas.penWidth = 10.0;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    ImageObject {
        id: defaultImageObject

        property int offsetX: 0
        property int offsetY: 0

    }

    ImageObject {
        id: currentImageObject
    }

    //--------------------------------------------------------------------------

    function clear(fill) {

        if (imageUrl) {
            if (canvas.isImageLoaded(imageUrl)) {
                canvas.unloadImage(imageUrl);
            }
            imageUrl = undefined;
        }

        if (fill) {
            currentImageObject.fill("white");
        } else {
            currentImageObject.clear();
        }
        pasteImageObject.clear();
        clearVectors();

        canvas.requestPaint();
    }

    //--------------------------------------------------------------------------

    function clearVectors() {
        canvas.clear();
    }

    //--------------------------------------------------------------------------

    function load(path) {

        imageUrl = AppFramework.resolvedPathUrl(path);

        if (useImageObject) {
            console.log("Loading current image:", imageUrl);

            if (currentImageObject.load(imageUrl)) {
                loaded = false;
            }

            canvas.requestPaint();
            return;
        }

        console.log("Loading canvas image:", imageUrl, canvas.isImageLoaded(imageUrl));

        if (canvas.isImageLoaded(imageUrl)) {
            console.log("Unloading:", imageUrl);
            canvas.unloadImage(imageUrl);
        }

        canvas.loadImage(imageUrl);

        return canvas.isImageLoaded(imageUrl);
    }

    //--------------------------------------------------------------------------

    function loadUrl(url) {

        console.log("Loading canvas url:", url, canvas.isImageLoaded(url));

        if (canvas.isImageLoaded(imageUrl)) {
            canvas.unloadImage(imageUrl);
        }

        imageUrl = url;

        canvas.loadImage(imageUrl);
    }

    //--------------------------------------------------------------------------

    function save(path) {
        console.log("Saving canvas:", path);

        var result = canvas.save(path);

        console.log("Canvas saved:", result);

        return result;
    }

    //--------------------------------------------------------------------------

    function rasterize() {
        if (!useImageObject) {
            console.error("Unable to rasterize: useImageObject not true");
            return;
        }

        if (!workFolder) {
            console.error("Unable to rasterize: workFolder is null");
            return;
        }

        var filePath = workFolder.filePath(AppFramework.urlInfo(imageUrl).localFile);
        var fileName = AppFramework.fileInfo(filePath).fileName;
        var saveFileName = fileName.replace("draft-", "");
        saveUrl = workFolder.fileUrl(saveFileName);
        var savePath = workFolder.filePath(saveFileName);

        console.log("Rasterizing canvas:", filePath);

        if (!save(savePath)) {
            console.error("Error saving canvas to:", filePath);
            return;
        } else {
            try {
                exifInfo.load(savePath);
                exifInfo.gpsLongitude = exif_longtitude;
                exifInfo.gpsLatitude = exif_latitude;
                exifInfo.save(savePath);
            } catch(e) {
                console.log(e)
            }
        }

        workFolder.removeFile(fileName);

        pasteImageObject.clear();
        clearVectors();
        canvas.requestPaint();
    }

    //--------------------------------------------------------------------------

    function pasteImage(image) {
        imageUrl = image;
        if (!pasteImageObject.load(image)) {
            console.error("Failed to load:", image);
            return;
        }

        resizeImageObject(pasteImageObject);

        canvas.requestPaint();
    }

    ImageObject {
        id: pasteImageObject

        property int offsetX: 0
        property int offsetY: 0
    }

    //--------------------------------------------------------------------------


    function fitImageObject(imageObject) {

        var canvasRatio = canvas.width / canvas.height;
        var imageRatio = imageObject.width / imageObject.height;


        var width;
        var height;

        if (imageRatio < canvasRatio) {
            height = canvas.height
            width = height * imageRatio;
        } else {
            width = canvas.width
            height = width / imageRatio;
        }
       var x = (canvas.width - width) / 2;
       var y = (canvas.height - height) / 2;



        return Qt.rect(x, y, width, height);
    }

    //--------------------------------------------------------------------------

    function resizeImageObject(imageObject) {
        console.log("Resize:", imageObject.width, "x", imageObject.height, "=>", canvas.width, canvas.height);

        var canvasRatio = canvas.width / canvas.height;
        var imageRatio = imageObject.width / imageObject.height;

        console.log("canvasRatio:", canvasRatio, "imageRatio:", imageRatio);
        if (imageRatio < canvasRatio) {
            imageObject.scaleToHeight(canvas.height, ImageObject.TransformationModeSmooth);
        } else {
            imageObject.scaleToWidth(canvas.width, ImageObject.TransformationModeSmooth);
        }



        imageObject.offsetX = (canvas.width - imageObject.width / scaleFactor) / 2;
        imageObject.offsetY = (canvas.height - imageObject.height / scaleFactor) / 2;

        console.log("Image resized:", imageObject.width, "x", imageObject.height, "offset:", imageObject.offsetX, imageObject.offsetY);
    }

    //--------------------------------------------------------------------------

    Dialog {
        id: resetSketchDialog

        width: Math.min(0.8 * parent.width, 400*AppFramework.displayScaleFactor)
        x: (parent.width - width)/2
        y: (parent.height - height)/2
        visible: false
        modal: true
        Material.background: "#424242"
        Material.elevation: 8
        Material.accent: "white"
        Material.foreground: "white"
        closePolicy: Popup.NoAutoClose
        clip: true

        standardButtons: Dialog.No | Dialog.Yes

        Label {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            text: discardString
            wrapMode: Label.Wrap
            padding: 0
            maximumLineCount: 3
            elide: Label.ElideRight
            color: "white"
        }

        onAccepted: {
            canvas.clear();
        }
    }

    Dialog {
        id: saveDialog

        width: Math.min(0.8 * parent.width, 400*AppFramework.displayScaleFactor)
        x: (parent.width - width)/2
        y: (parent.height - height)/2
        visible: false
        modal: true
        Material.background: "#424242"
        Material.elevation: 8
        Material.accent: "white"
        Material.foreground: "white"
        closePolicy: Popup.NoAutoClose
        clip: true

        standardButtons: Dialog.Cancel | Dialog.Save

        Label {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            text: saveString
            wrapMode: Label.Wrap
            padding: 0
            maximumLineCount: 3
            elide: Label.ElideRight
            color: "white"
        }

        onAccepted: {
            rasterize();
            saved();
            sketch.visible = false;         
            app.focus = true

        }
    }

    Dialog {
        id: confirmDialog

        width: Math.min(0.8 * parent.width, 400*AppFramework.displayScaleFactor)
        x: (parent.width - width)/2
        y: (parent.height - height)/2
        visible: false
        modal: true
        Material.background: "#424242"
        Material.elevation: 8
        Material.accent: "white"
        Material.foreground: "white"
        closePolicy: Popup.NoAutoClose
        clip: true

        standardButtons: Dialog.No | Dialog.Yes

        Label {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            text: discardString
            wrapMode: Label.Wrap
            padding: 0
            maximumLineCount: 3
            elide: Label.ElideRight
            color: "white"
        }

        onAccepted: {
            var filePath = workFolder.filePath(AppFramework.urlInfo(imageUrl).localFile);
            var fileName = AppFramework.fileInfo(filePath).fileName;
            workFolder.removeFile(fileName);

            pasteImageObject.clear();
            clearVectors();

            sketch.visible = false;
        }
    }
}
