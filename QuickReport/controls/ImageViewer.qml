
import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import QtPositioning 5.8
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0

Rectangle {
    id: imageViewer
    anchors.fill: parent

    color: "black"

    property string currentOperation: ""

    property url imageSourceUrl
    property url imageTempUrl: imageViewer.imageSourceUrl
    property string tempFileName
    property string extension
    property string newName

    property int imageSourceWidth: imageObject.width
    property int imageSourceHeight: imageObject.height
    property int imageOriginWidth: imageSourceWidth
    property int imageOriginHeight: imageSourceHeight
    property int imageCurrentWidth: imageSourceWidth
    property int imageCurrentHeight: imageSourceHeight

    property string saveButtonString: Qt.qsTr("SAVE")

    property real rotateDegree: 0
    property real offset: 0
    property real xOffset: 0
    property real yOffset: 0

    property var sourceRatio
    property var discardConfirmBox: discardConfirmBox

    property var colorsModel: ["#ff0000","#ff4000","#ff8000","#ffbf00",
                          "#ffff00","#bfff00","#80ff00","#40ff00",
                          "#00ff00","#00ff40","#00ff80","#00ffbf",
                          "#00ffff","#00bfff","#0080ff","#0040ff",
                          "#0000ff","#4000ff","#8000ff","#bf00ff",
                          "#ff00ff","#ff00bf","#ff0080","#ff0040","#ff0000"]

    property bool hasGeoExif: false

    signal discarded()
    signal saved(url newFileUrl)

    Component.onCompleted: {

    }

    function init(){
        fileInfo.url = imageViewer.imageSourceUrl;
        fileFolder.url = fileInfo.url.toString().replace(fileInfo.fileName,"")
        var fileName = fileInfo.fileName.split(".");
        newName = fileInfo.fileName;
        extension = fileName[1];
        tempFileName = "temp_"+Date.now()+"."+extension;
        imageTempUrl = fileFolder.url+"/"+tempFileName
        if(fileFolder.fileExists(tempFileName)){
            fileFolder.removeFile(tempFileName);
        }

        fileFolder.copyFile(fileInfo.fileName, fileFolder.path+"/"+tempFileName)
        imageObject.load(imageTempUrl.toString().replace(Qt.platform.os == "windows"? "file:///": "file://",""));
        exifInfo.load(imageTempUrl.toString().replace(Qt.platform.os == "windows"? "file:///": "file://",""));
        var gpsLongValue = exifInfo.gpsLongitude;
        if(gpsLongValue) hasGeoExif = true;
        else hasGeoExif = false;


        sourceRatio = imageSourceHeight/imageSourceWidth;
        var canvasRatio = canvas.height/canvas.width;
        if(canvasRatio > sourceRatio){
            imageCurrentWidth = canvas.width;
            imageCurrentHeight = canvas.width*imageSourceHeight/imageSourceWidth;
        } else {
            imageCurrentWidth = canvas.height*imageSourceWidth/imageSourceHeight;
            imageCurrentHeight = canvas.height;
        }
        imageOriginWidth = imageCurrentWidth;
        imageOriginHeight = imageCurrentHeight;

        canvas.loadImage(imageViewer.imageTempUrl);
    }

    ImageObject{
        id: imageObject
    }

    FileInfo {
        id: fileInfo
    }

    FileFolder{
        id: fileFolder
    }

    ExifInfo {
        id: exifInfo
    }

    PositionSource {
        id: positionSource
        updateInterval: 5000
        active: imageViewer.visible
    }

    MouseArea{
        anchors.fill: parent
        onClicked: {}
    }

    ColumnLayout{
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: header
            Layout.alignment: Qt.AlignTop
            color: "#212121"
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50 * AppFramework.displayScaleFactor
            RowLayout{
                width: parent.width
                height: 45*AppFramework.displayScaleFactor
                anchors.centerIn: parent
                Icon{
                    backgroundColor: "#212121"
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: parent.height
                    imageSource: "../images/ic_arrow_back_white_48dp.png"
                    radius: width/2
                    onIconClicked: {
                        discardConfirmBox.visible = true;
                    }
                }
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
                Icon{
                    backgroundColor: "#212121"
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: parent.height
                    imageSource: "../images/ic_save_white_48dp.png"
                    radius: width/2
                    onIconClicked: {
                        fileFolder.removeFile(fileInfo.fileName);
                        fileFolder.renameFile(tempFileName, newName);
                        var newFileUrl = fileFolder.url+"/"+newName;
                        imageViewer.visible = false;
                        saved(newFileUrl);
                    }
                }
                Item{
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: parent.height*2
                    Text{
                        anchors.fill: parent
                        text: saveButtonString
                        fontSizeMode: Text.Fit
                        font.family: app.customTextFont.name
                        opacity: 0.6
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        Canvas{
            id: canvas

            Layout.fillWidth: true
            Layout.fillHeight: true

            property var ctx
            property real offset: 0
            property real rotateDegree: 0
            property real xOffset: 0
            property real yOffset: 0
            property var drawList

            property int currentTextIndex: -1
            property var currentColor: colorsModel[0];

            onImageLoaded: {
                ctx = getContext('2d');
                ctx.clearRect(0, 0);
                requestPaint();
            }

            onPaint: {
                if(ctx!==null){
                    ctx.save();
                    ctx.clearRect(0, 0, canvas.width, canvas.height);
                    imageCurrentWidth = imageOriginWidth + canvas.offset;
                    imageCurrentHeight = imageOriginHeight + canvas.offset*sourceRatio;
                    ctx.translate(canvas.width/2 + canvas.xOffset , canvas.height/2 + canvas.yOffset);
                    ctx.rotate(canvas.rotateDegree * Math.PI / 180);
                    ctx.drawImage(imageViewer.imageTempUrl, -imageCurrentWidth/2 , -imageCurrentHeight/2, imageCurrentWidth, imageCurrentHeight)
                    ctx.restore();

                    if(drawList && drawList.length >= 1){
                        ctx.beginPath();
                        for(var i = 0; i<drawList.length; i++){
                            var element = drawList[i];
                            if(element.type === 0){
                                if (element.x < 0 && element.y < 0) {
                                    if(i > 0){
                                        ctx.stroke();
                                        ctx.beginPath();
                                    }
                                    ctx.lineWidth = 10*AppFramework.displayScaleFactor;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    ctx.strokeStyle = element.color;
                                    ctx.moveTo(-element.x, -element.y);
                                } else {
                                    ctx.lineTo(element.x, element.y);
                                }
                            }else{
                                ctx.font = element.fontSize+'px sans-serif';
                                ctx.fillStyle = element.color
                                ctx.textAlign = "left"
                                ctx.moveTo(0,0);
                                ctx.fillText(element.text, element.x, element.y)
                            }
                        }
                        ctx.stroke();
                    }
                }
            }

            onPainted: {

            }

            function rotateAndScale(offset, degree, xOffset, yOffset){
                canvas.offset = offset;
                canvas.rotateDegree = degree;
                canvas.xOffset = xOffset;
                canvas.yOffset = yOffset;
                requestPaint();
            }

            function crop(x,y,width,height){
                canvas.canvasWindow.x = x
                canvas.canvasWindow.y = y
                canvas.canvasWindow.width = width
                canvas.canvasWindow.height = height
                canvas.save(imageTempUrl.toString().replace(Qt.platform.os == "windows"? "file:///": "file://",""))
                canvas.canvasWindow.x = 0
                canvas.canvasWindow.y = 0
                canvas.canvasWindow.width = canvas.width
                canvas.canvasWindow.height = canvas.height
                canvas.requestPaint()
            }

            function addVertex(x, y, color) {
                if(!Array.isArray(drawList)){
                    drawList = []
                }
                drawList.push({"x": x, "y": y, "color": color, "type": 0});
                canvas.requestPaint();
            }

            function addText(textX, textY, text, color, fontSize) {
                if (!Array.isArray(drawList)) {
                    drawList = [];
                }
                drawList.push({"x": textX, "y": textY, "text": text, "color": color, "type": 1, "fontSize": fontSize});
                currentTextIndex = drawList.length-1;
                canvas.requestPaint();
                details.visible = true;
            }

            function updateText(index, textX, textY, text, color, fontSize){
                if (!Array.isArray(drawList)) {
                    drawList = [];
                }
                if(textX!==null)drawList[index].x = textX;
                if(textY!==null)drawList[index].y = textY;
                if(text!==null)drawList[index].text = text;
                if(color!==null)drawList[index].color = color;
                if(fontSize!==null)drawList[index].fontSize = fontSize;
                canvas.requestPaint();
            }

            function undo(){
                if(canvas.drawList.length>0){
                    if(canvas.drawList[canvas.drawList.length-1].type === 1) canvas.drawList.pop();
                    else{
                        while(canvas.drawList[canvas.drawList.length-1].x>=0){
                            canvas.drawList.pop();
                        }
                        canvas.drawList.pop();
                    }
                }

                canvas.requestPaint();
            }

            MultiPointTouchArea {
                id: multiPointTouchArea
                maximumTouchPoints: 2
                minimumTouchPoints: 1
                mouseEnabled: currentOperation==="rotate"||currentOperation==="scale"||currentOperation==="move"

                property int sx1
                property int sy1
                property int sx2
                property int sy2

                property int ex1
                property int ey1
                property int ex2
                property int ey2

                property var tempRotateDegree
                property var tempOffset

                anchors.fill: parent
                touchPoints: [
                    TouchPoint { id: point1 },
                    TouchPoint { id: point2 }
                ]

                onPressed: {
                    if(currentOperation === "rotate" || currentOperation === "scale"){
                        sx1 = point1.x;
                        sy1 = point1.y;
                        sx2 = point2.x;
                        sy2 = point2.y;
                    } else if(currentOperation === "move"){
                        sx1 = point1.x;
                        sy1 = point1.y;
                    }
                }

                onUpdated: {
                    if(currentOperation === "rotate" || currentOperation === "scale"){
                        ex1 = point1.x;
                        ey1 = point1.y;
                        ex2 = point2.x;
                        ey2 = point2.y;

                        var distance1 = getDistance(sx1, sy1, sx2, sy2);
                        var distance2 = getDistance(ex1, ey1, ex2, ey2);
                        var degree1 = getDegree(sx1, sy1, sx2, sy2);
                        var degree2 = getDegree(ex1, ey1, ex2, ey2);

                        tempOffset = offset + (distance2 - distance1)*Math.abs(Math.cos(degree1));
                        tempRotateDegree = rotateDegree + degree2 - degree1;

                        if(currentOperation === "rotate" )canvas.rotateAndScale(offset, tempRotateDegree, 0, 0);
                        else canvas.rotateAndScale(tempOffset, rotateDegree, 0, 0);
                    } else if(currentOperation === "move") {
                        ex1 = point1.x;
                        ey1 = point1.y;
                        canvas.rotateAndScale(offset, rotateDegree, xOffset+ex1-sx1, yOffset+ey1-sy1);
                    }
                }

                onReleased: {
                    if(currentOperation === "rotate" || currentOperation === "scale"){
                        if(currentOperation === "rotate") rotateDegree = tempRotateDegree;
                        else offset = tempOffset;
                    } else if(currentOperation === "move"){
                        xOffset = canvas.xOffset;
                        yOffset = canvas.yOffset
                    }
                }

                function getDistance(x1, y1, x2, y2){
                    return Math.sqrt((x2-=x1)*x2 + (y2-=y1)*y2);
                }

                function getDegree(x1, y1, x2, y2){
                    return Math.atan2(y2 - y1, x2 - x1) * 180 / Math.PI
                }
            }

            Item{
                anchors.fill: parent

                Rectangle{
                    id: topMask
                    anchors.top: parent.top
                    anchors.bottom: selComp.top
                    width: parent.width
                    color: "#dd212121"
                }

                Rectangle{
                    id: bottomMask
                    anchors.top: selComp.bottom
                    anchors.bottom: parent.bottom
                    width: parent.width
                    color: "#dd212121"
                }

                Rectangle{
                    anchors.top: topMask.bottom
                    anchors.bottom: bottomMask.top
                    anchors.left: parent.left
                    anchors.right: selComp.left
                    color: "#dd212121"
                }

                Rectangle{
                    anchors.top: topMask.bottom
                    anchors.bottom: bottomMask.top
                    anchors.right: parent.right
                    anchors.left: selComp.right
                    color: "#dd212121"
                }

                Rectangle {
                    id: selComp
                    border {
                        width: currentOperation==="rotate"||currentOperation==="scale"||currentOperation==="move"? 2: 0
                        color: "#0079C1"
                    }
                    color: "transparent"

                    x: (canvas.width-imageOriginWidth)/2
                    y: (canvas.height-imageOriginHeight)/2
                    width: imageOriginWidth
                    height: imageOriginHeight

                    property int rulersSize: 18

                    Rectangle {
                        width: selComp.rulersSize
                        height: selComp.rulersSize
                        radius: selComp.rulersSize
                        visible: currentOperation === "move"
                        color: "#0079C1"
                        anchors.horizontalCenter: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            enabled: currentOperation === "move"
                            drag{ target: parent; axis: Drag.XAxis }
                            onMouseXChanged: {
                                if(drag.active){
                                    selComp.width = selComp.width - mouseX
                                    selComp.x = selComp.x + mouseX
                                    if(selComp.width < 30)
                                        selComp.width = 30
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: selComp.rulersSize
                        height: selComp.rulersSize
                        radius: selComp.rulersSize
                        visible: currentOperation === "move"
                        color: "#0079C1"
                        anchors.horizontalCenter: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            enabled: currentOperation === "move"
                            drag{ target: parent; axis: Drag.XAxis }
                            onMouseXChanged: {
                                if(drag.active){
                                    selComp.width = selComp.width + mouseX
                                    if(selComp.width < 50)
                                        selComp.width = 50
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: selComp.rulersSize
                        height: selComp.rulersSize
                        radius: selComp.rulersSize
                        visible: currentOperation === "move"
                        x: parent.x / 2
                        y: 0
                        color: "#0079C1"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.top

                        MouseArea {
                            anchors.fill: parent
                            enabled: currentOperation === "move"
                            drag{ target: parent; axis: Drag.YAxis }
                            onMouseYChanged: {
                                if(drag.active){
                                    selComp.height = selComp.height - mouseY
                                    selComp.y = selComp.y + mouseY
                                    if(selComp.height < 50)
                                        selComp.height = 50
                                }
                            }
                        }
                    }


                    Rectangle {
                        width: selComp.rulersSize
                        height: selComp.rulersSize
                        radius: selComp.rulersSize
                        visible: currentOperation === "move"
                        x: parent.x / 2
                        y: parent.y
                        color: "#0079C1"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.bottom

                        MouseArea {
                            anchors.fill: parent
                            enabled: currentOperation === "move"
                            drag{ target: parent; axis: Drag.YAxis }
                            onMouseYChanged: {
                                if(drag.active){
                                    selComp.height = selComp.height + mouseY
                                    if(selComp.height < 50)
                                        selComp.height = 50
                                }
                            }
                        }
                    }
                }
            }

            MouseArea{
                anchors.fill: parent
                enabled: currentOperation === "line" || currentOperation === "text"
                onPressed: {
                    if(currentOperation === "line")canvas.addVertex(-mouseX, -mouseY, canvas.currentColor);
                }

                onPositionChanged: {
                    if(currentOperation === "line")canvas.addVertex(mouseX, mouseY, canvas.currentColor);
                }

                onClicked: {
                    if(currentOperation === "text"){
                        if(canvas.currentTextIndex === -1) canvas.addText(mouseX, mouseY, "{TEXT}", canvas.currentColor, 15*AppFramework.displayScaleFactor);
                        else canvas.updateText(canvas.currentTextIndex, mouseX, mouseY, "{TEXT}", canvas.currentColor, 15*AppFramework.displayScaleFactor)
                    }
                }
            }

            Rectangle{
                id: panels
                width: parent.width
                height: panels.type != "info"? 50 * AppFramework.displayScaleFactor: infoPanel.height
                anchors.bottom: parent.bottom
                color: "#212121"
                visible: type>""

                property string type: ""

                Item{
                    id: sizePanel
                    anchors.centerIn: parent
                    width: 160*AppFramework.displayScaleFactor
                    height: 40*AppFramework.displayScaleFactor
                    visible: panels.type === "size"

                    RowLayout{
                        anchors.fill: parent
                        spacing: 20*AppFramework.displayScaleFactor
                        Icon{
                            id: rotateButton
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: parent.height
                            imageSource: "../images/ic_cached_white_48dp.png"
                            iconOverlayColor: currentOperation === "rotate"? "#0079C1":"#888888"
                            backgroundColor: "#323232"
                            radius: width/2
                            onIconClicked: {
                                currentOperation = "rotate";
                            }
                        }

                        Icon{
                            id: scaleButton
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: parent.height
                            imageSource: "../images/resize.png"
                            iconOverlayColor: currentOperation === "scale"? "#0079C1":"#888888"
                            backgroundColor: "#323232"
                            radius: width/2
                            onIconClicked: {
                                currentOperation = "scale";
                            }
                        }

                        Icon{
                            id: cropButton
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: parent.height
                            imageSource: "../images/ic_crop_white_48dp.png"
                            iconOverlayColor: currentOperation === "move"? "#0079C1":"#888888"
                            backgroundColor: "#323232"
                            radius: width/2
                            onIconClicked: {
                                currentOperation = "move";
                            }
                        }
                    }
                }

                Item{
                    id: drawPanel
                    anchors.centerIn: parent
                    width: 160*AppFramework.displayScaleFactor
                    height: 40*AppFramework.displayScaleFactor
                    visible: panels.type === "draw"

                    RowLayout{
                        anchors.fill: parent
                        spacing: 20*AppFramework.displayScaleFactor
                        Icon{
                            id: undoButton
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: parent.height
                            imageSource: "../images/ic_undo_white_48dp.png"
                            backgroundColor: "#323232"
                            iconOverlayColor: "#888888"
                            radius: width/2
                            onIconClicked: {
                                canvas.undo();
                            }
                        }

                        Icon{
                            id: lineButton
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: parent.height
                            imageSource: "../images/ic_border_color_white_48dp.png"
                            iconOverlayColor: currentOperation === "line"? "#0079C1":"#888888"
                            backgroundColor: "#323232"
                            radius: width/2
                            onIconClicked: {
                                currentOperation = "line";
                            }
                        }

                        Icon{
                            id: textButton
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: parent.height
                            imageSource: "../images/text_field.png"
                            iconOverlayColor: currentOperation === "text"? "#0079C1":"#888888"
                            backgroundColor: "#323232"
                            radius: width/2
                            onIconClicked: {
                                currentOperation = "text";
                            }
                        }
                    }
                }

                Item{
                    id: infoPanel
                    anchors.centerIn: parent
                    width: Math.min(parent.width, 600*AppFramework.displayScaleFactor)
                    height: 168*AppFramework.displayScaleFactor
                    visible: panels.type === "info"

                    ColumnLayout{
                        anchors.fill: parent
                        anchors.margins: 10*AppFramework.displayScaleFactor
                        anchors.leftMargin: 20*AppFramework.displayScaleFactor
                        anchors.rightMargin: 20*AppFramework.displayScaleFactor
                        spacing: 10*AppFramework.displayScaleFactor

                        RowLayout{
                            Layout.preferredHeight: (parent.height-parent.spacing - 20*AppFramework.displayScaleFactor)/2
                            Layout.fillWidth: true
                            spacing: 20*AppFramework.displayScaleFactor
                            ColumnLayout{
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 0

                                Text{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20*AppFramework.displayScaleFactor
                                    text: qsTr("NAME")
                                    color: "#80ffffff"
                                    font.family: app.customTextFont.name
                                }

                                Rectangle{
                                    Layout.preferredHeight: 44*AppFramework.displayScaleFactor
                                    Layout.fillWidth: true
                                    radius: 3*AppFramework.displayScaleFactor
                                    color: renameField.focus? "white" : "transparent"
                                    TextInput{
                                        id: renameField
                                        anchors.fill: parent
                                        anchors.leftMargin: focus? 5*AppFramework.displayScaleFactor:0
                                        color: focus? "black": "white"
                                        text: newName? newName: fileInfo.fileName
                                        verticalAlignment: Text.AlignVCenter
                                        onFocusChanged: {
                                            if(focus) currentOperation = "rename"
                                        }
                                    }
                                }
                            }

                            Icon{
                                id: renameButton
                                Layout.preferredHeight: 30*AppFramework.displayScaleFactor
                                Layout.preferredWidth: 30*AppFramework.displayScaleFactor
                                imageSize: 16*AppFramework.displayScaleFactor
                                anchors.verticalCenter: parent.verticalCenter
                                iconOverlayColor: currentOperation === "rename"? "#0079C1":"#888888"
                                backgroundColor: "#323232"
                                imageSource: currentOperation === "rename"?"../images/done_white.png":"../images/ic_edit_white_48dp.png"
                                radius: width/2
                                onIconClicked: {
                                    if(currentOperation==="rename"){
                                        newName = renameField.text;
                                        currentOperation = "";
                                        renameField.focus = false;
                                    } else {
                                        currentOperation = "rename";
                                        renameField.focus = true;
                                    }
                                }
                            }
                        }

                        RowLayout{
                            Layout.preferredHeight: (parent.height-parent.spacing)/2
                            Layout.fillWidth: true
                            spacing: 20*AppFramework.displayScaleFactor
                            ColumnLayout{
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 0

                                Text{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20*AppFramework.displayScaleFactor
                                    text: qsTr("LOCATION")
                                    color: "#80ffffff"
                                    font.family: app.customTextFont.name
                                }

                                Text{
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 44*AppFramework.displayScaleFactor
                                    text: hasGeoExif? "("+exifInfo.gpsLatitude.toFixed(2)+","+exifInfo.gpsLongitude.toFixed(2)+")" : qsTr("Not Set")
                                    color: "white"
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: app.customTextFont.name
                                }
                            }

                            Icon{
                                id: locationButton
                                Layout.preferredHeight: 30*AppFramework.displayScaleFactor
                                Layout.preferredWidth: 30*AppFramework.displayScaleFactor
                                imageSize: 16*AppFramework.displayScaleFactor
                                imageSource: hasGeoExif? "../images/delete.png":"../images/add_location.png"
                                iconOverlayColor: "#888888"
                                backgroundColor: "#323232"
                                radius: width/2
                                enabled: positionSource.valid
                                onIconClicked: {
                                    if(hasGeoExif){
                                        exifInfo.removeGpsValue(ExifInfo.GpsLatitude);
                                        exifInfo.removeGpsValue(ExifInfo.GpsLongitude);
                                        exifInfo.save(exifInfo.filePath);
                                        hasGeoExif = false;
                                    } else {
                                        exifInfo.gpsLatitude = positionSource.position.coordinate.latitude;
                                        exifInfo.gpsLongitude = positionSource.position.coordinate.longitude;
                                        exifInfo.save(exifInfo.filePath);
                                        hasGeoExif = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle{
                id: details
                width: parent.width
                height: 50 * AppFramework.displayScaleFactor
                anchors.bottom: parent.bottom
                color: "#212121"
                visible: false

                Item{
                    id: textDetails
                    width: Math.min(600*AppFramework.displayScaleFactor, parent.width)
                    height: parent.height
                    visible: currentOperation==="text"
                    anchors.horizontalCenter: parent.horizontalCenter

                    RowLayout{
                        anchors.fill: parent
                        anchors.margins: 5*AppFramework.displayScaleFactor
                        Icon{
                            backgroundColor: "#212121"
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: parent.height
                            imageSource: "../images/ic_clear_white_48dp.png"
                            radius: width/2
                            onIconClicked: {
                                canvas.drawList.splice(canvas.currentTextIndex, 1);
                                canvas.requestPaint();
                                canvas.currentTextIndex = -1;
                                textField.text = "";
                                details.visible = false;
                            }
                        }

                        TextField{
                            id: textField
                            anchors.verticalCenter: parent.verticalCenter
                            Layout.preferredHeight: parent.height*0.8
                            Layout.fillWidth: true
                        }

                        Icon{
                            backgroundColor: "#212121"
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: parent.height
                            imageSource: "../images/done_white.png"
                            radius: width/2
                            onIconClicked: {
                                if(textField.text>"" && textField!=null){
                                    canvas.updateText(canvas.currentTextIndex,null,null,textField.text, canvas.currentColor, 15*AppFramework.displayScaleFactor)
                                }
                                canvas.currentTextIndex = -1;
                                textField.text = ""
                                details.visible = false;
                            }
                        }
                    }
                }

            }

            Rectangle{
                width: parent.width
                height: 50 * AppFramework.displayScaleFactor
                anchors.bottom: panels.top
                color: "#212121"
                visible: currentOperation==="line"||currentOperation==="text"
                Item{
                    id: colorDetails
                    width: parent.width
                    height: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    ListView{
                        id: colorListView
                        anchors.fill: parent
                        orientation: ListView.Horizontal
                        model: imageViewer.colorsModel.length
                        delegate: Rectangle{
                            border.width: index===colorListView.currentIndex? 1:0
                            border.color: "white"
                            color: imageViewer.colorsModel[index]
                            height: parent.height
                            width: height

                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    colorListView.currentIndex = index;
                                    colorListView.positionViewAtIndex(index, ListView.Center);
                                    canvas.currentColor = colorsModel[index];
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: footer
            Layout.alignment: Qt.AlignTop
            color: "#212121"
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50 * AppFramework.displayScaleFactor
            property string type: "tool"

            Item{
                id: toolbar
                anchors.centerIn: parent
                width: 160*AppFramework.displayScaleFactor
                height: 40*AppFramework.displayScaleFactor
                visible: footer.type === "tool"

                RowLayout{
                    anchors.fill: parent
                    spacing: 20*AppFramework.displayScaleFactor
                    Icon{
                        id: sizeButton
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height
                        imageSource: "../images/ic_crop_rotate_white_48dp.png"
                        backgroundColor: "#323232"
                        radius: width/2
                        onIconClicked: {
                            panels.type = "size";
                            footer.type = "confirm";
                        }
                    }

                    Icon{
                        id: drawButton
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height
                        imageSource: "../images/ic_edit_white_48dp.png"
                        backgroundColor: "#323232"
                        radius: width/2
                        onIconClicked: {
                            panels.type = "draw";
                            footer.type = "confirm";
                        }
                    }

                    Icon{
                        id: infoButton
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height
                        imageSource: "../images/ic_info_outline_white_48dp.png"
                        backgroundColor: "#323232"
                        radius: width/2
                        onIconClicked: {
                            panels.type = "info";
                            footer.type = "confirm";
                        }
                    }
                }
            }

            Item{
                id: confirmBar
                anchors.centerIn: parent
                width: 100*AppFramework.displayScaleFactor
                height: 40*AppFramework.displayScaleFactor
                visible: footer.type === "confirm"

                RowLayout{
                    anchors.fill: parent
                    spacing: 20*AppFramework.displayScaleFactor
                    Icon{
                        id: cancelButton
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height
                        color: "red"
                        imageSource: "../images/ic_clear_white_48dp.png"
                        backgroundColor: "#323232"
                        radius: width/2
                        onIconClicked: {
                            xOffset = 0;
                            yOffset = 0;
                            offset = 0;
                            rotateDegree = 0;
                            selComp.x = (canvas.width-imageOriginWidth)/2;
                            selComp.y = (canvas.height-imageOriginHeight)/2;
                            selComp.width = imageOriginWidth;
                            selComp.height = imageOriginHeight;
                            canvas.drawList = [];
                            canvas.currentTextIndex = -1;

                            canvas.rotateAndScale(offset, rotateDegree, xOffset, yOffset);

                            details.visible = false;
                            currentOperation  = ""      //disable edit
                            panels.type = "";           //remove panels
                            footer.type = "tool";       //recover the tool bar
                        }
                    }

                    Icon{
                        id: acceptButton
                        Layout.preferredHeight: parent.height
                        Layout.preferredWidth: parent.height
                        color: "green"
                        imageSource: "../images/done_white.png"
                        backgroundColor: "#323232"
                        radius: width/2
                        onIconClicked: {
                            if(panels.type === "size" || panels.type === "draw"){
                                canvas.crop(selComp.x, selComp.y, selComp.width, selComp.height);

                                xOffset = 0;
                                yOffset = 0;
                                offset = 0;
                                rotateDegree = 0;
                                canvas.xOffset = 0;
                                canvas.yOffset = 0;
                                canvas.offset = 0;
                                canvas.rotateDegree = 0;
                                canvas.drawList = [];

                                imageObject.load(imageViewer.imageTempUrl.toString().replace(Qt.platform.os == "windows"? "file:///": "file://",""));
                                sourceRatio = imageSourceHeight/imageSourceWidth;
                                var canvasRatio = canvas.height/canvas.width;
                                if(canvasRatio > sourceRatio){
                                    imageCurrentWidth = canvas.width;
                                    imageCurrentHeight = canvas.width*imageSourceHeight/imageSourceWidth;
                                } else {
                                    imageCurrentWidth = canvas.height*imageSourceWidth/imageSourceHeight;
                                    imageCurrentHeight = canvas.height;
                                }
                                imageOriginWidth = imageCurrentWidth;
                                imageOriginHeight = imageCurrentHeight;

                                selComp.x = (canvas.width-imageOriginWidth)/2;
                                selComp.y = (canvas.height-imageOriginHeight)/2;
                                selComp.width = imageOriginWidth;
                                selComp.height = imageOriginHeight;

                                var newTempFileName = "temp_"+Date.now()+"."+extension;
                                imageTempUrl = fileFolder.url+"/"+newTempFileName
                                fileFolder.renameFile(tempFileName, newTempFileName);
                                tempFileName = newTempFileName;
                                canvas.loadImage(imageViewer.imageTempUrl);
                            }
                            currentOperation  = ""
                            panels.type = "";
                            footer.type = "tool";
                        }
                    }
                }
            }
        }
    }

    ConfirmBox{
        id: exifInfoDetails
        visible: false
        anchors.fill: parent
        standardButtons: StandardButton.Ok
    }

    ConfirmBox{
        id: discardConfirmBox
        anchors.fill: parent
        text: qsTr("Are you sure you want to discard the changes?")
        onAccepted: {
            if(fileFolder.fileExists(tempFileName))fileFolder.removeFile(tempFileName);
            imageViewer.visible = false;
            discarded();
        }
    }

    Component.onDestruction: {
        if(fileFolder.fileExists(tempFileName))fileFolder.removeFile(tempFileName);
    }
}
