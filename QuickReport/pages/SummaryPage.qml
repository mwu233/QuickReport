import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import ArcGIS.AppFramework.Networking 1.0

import ArcGIS.AppFramework 1.0

import "../controls"



Rectangle {

    id: summaryPage
    objectName: "summaryPage"
    width: parent ? parent.width :0
    height:parent ?parent.height:0
    color: app.pageBackgroundColor

    signal showNext(string message)
    signal previous(string message)
    signal next(string message)

    Material.accent:Material.Grey
    QtObject{
        id:summaryPageSettings
        property var rowItemWidth:Math.min(summaryPage.width - app.units(48),600*app.scaleFactor)


    }

    ColumnLayout {
        id: columnLayout
        anchors.fill:parent
        //width:parent.width

        Rectangle {
            id: createPage_headerBar
            Layout.alignment: Qt.AlignTop
            color: app.headerBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50 * app.scaleFactor
            Layout.topMargin: 0

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
                    // app.steps--;
                    previous("")
                }
            }


            Text {
                id: title
                text: qsTr("Summary")
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

        Rectangle{
            id:detailsContent
            Layout.preferredWidth: app.width - 48  * app.scaleFactor

            Layout.preferredHeight:app.height - createPage_headerBar.height - buttonbar.height - app.units(20)
            clip:true
            color:"transparent"

            Layout.alignment: Qt.AlignHCenter

            Layout.maximumWidth: 600*app.scaleFactor

            Flickable{
                id:flickable
                interactive:true
                boundsBehavior: Flickable.StopAtBounds

                height:app.height - createPage_headerBar.height - buttonbar.height
                width:parent.width

                contentHeight:col1.height + app.units(40)

                ColumnLayout{
                    id:col1
                    spacing:0
                    width:app.width

                    Repeater {
                        model: app.summaryModel
                        delegate:
                            Rectangle{
                            Layout.preferredWidth:app.width
                            Layout.preferredHeight:content.height
                            color:"transparent"
                            ColumnLayout {
                                id:content
                                width:parent.width
                                spacing: 0

                                Rectangle{
                                    Layout.preferredWidth:parent.width
                                    Layout.preferredHeight:50 * app.scaleFactor
                                    color:"transparent"

                                    RowLayout{
                                        height:parent.height

                                        Text {
                                            id: headingText
                                            text: modelData.heading//app.summaryModel[index].heading
                                            textFormat: Text.StyledText
                                            verticalAlignment: Text.AlignBottom
                                            color: app.textColor
                                            font{
                                                pixelSize: app.titleFontSize * 0.9
                                                family: app.customTitleFont.name
                                                bold: true
                                            }
                                            elide: Text.ElideRight
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 1
                                            fontSizeMode: Text.Fit

                                        }

                                        ImageOverlay {
                                            Layout.preferredHeight:16 * scaleFactor
                                            Layout.preferredWidth:16 * scaleFactor
                                            showOverlay: true

                                            visible: headingText.text !== app.report
                                            source: "../images/ic_mode_edit_black_48dp.png"

                                            overlayColor: app.textColor

                                            MouseArea{
                                                anchors.fill: parent
                                                onClicked: {
                                                    showNext(headingText.text)
                                                }
                                            }
                                        }

                                    }

                                }

                                Repeater{
                                    model:modelData.content
                                    delegate:
                                        ColumnLayout{
                                        spacing: 4 * app.scaleFactor
                                        Layout.preferredWidth:summaryPage.width - app.units(100)


                                        RowLayout{
                                            id:rowitem
                                            spacing: 8 * app.scaleFactor
                                            // width:parent.width
                                            Layout.preferredWidth:summaryPageSettings.rowItemWidth


                                            Item{
                                                Layout.preferredWidth:16 * scaleFactor
                                                Layout.preferredHeight: 16 * scaleFactor
                                                visible:modelData.hasIcon


                                                Rectangle {
                                                    id: layerIcon
                                                    width:16 * scaleFactor
                                                    height:16 * scaleFactor

                                                    //visible:modelData.hasIcon

                                                    radius: 16 * scaleFactor

                                                    color: app.headerBackgroundColor

                                                    ImageOverlay {
                                                        anchors.fill: parent
                                                        anchors.margins: 4 * scaleFactor

                                                        source: modelData.icon?modelData.icon:""

                                                        overlayColor: "#ffffff"
                                                        showOverlay: true
                                                        fillMode: Image.PreserveAspectFit
                                                    }
                                                }
                                            }
                                            Item{
                                                id:keyfield
                                                Layout.preferredWidth:modelData.description?keyfielddata.width:app.width //Math.min(width,app.width - app.units(90))

                                                Layout.preferredHeight:keyfielddata.height

                                                Text {
                                                    id:keyfielddata

                                                    text:modelData.isDotIconVisible? modelData.title : (headingText.text === app.details ?modelData.title + ":":modelData.title)

                                                    color: app.textColor
                                                    font{
                                                        pixelSize: app.subtitleFontSize
                                                        family: app.customTextFont.name
                                                    }
                                                    width:modelData.description?(headingText.text === app.details?app.width:Math.min(implicitWidth,app.width - units(150))):app.width

                                                    elide: Text.ElideRight
                                                    wrapMode: Text.NoWrap
                                                    maximumLineCount: 1

                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth:app.units(4)

                                                Layout.preferredHeight: icon1.height

                                                Rectangle {
                                                    id:icon1
                                                    width: 3
                                                    height:3
                                                    anchors.centerIn: parent
                                                    radius: 2
                                                    color: app.textColor
                                                    Layout.alignment: Qt.AlignVCenter
                                                    visible:modelData.isDotIconVisible
                                                }

                                            }
                                            Item{
                                                Layout.fillWidth:true
                                                //Layout.preferredWidth:parent.width  - keyfield.width - app.units(16)
                                                Layout.preferredHeight: desc.height
                                                visible:headingText.text !== app.details

                                                Text {
                                                    id:desc
                                                    width:parent.width
                                                    text:modelData.description?modelData.description:""
                                                    verticalAlignment: Text.AlignBottom
                                                    color: app.textColor

                                                    font{
                                                        pixelSize: app.subtitleFontSize
                                                        family: app.customTextFont.name
                                                    }
                                                    elide: Text.ElideRight
                                                    wrapMode: Text.Wrap
                                                    maximumLineCount: 2

                                                }
                                            }
                                        }

                                        RowLayout{
                                            id:rowitem2
                                            spacing: 8 * app.scaleFactor
                                            visible:headingText.text === app.details
                                            Layout.preferredWidth:summaryPage.width - app.units(48)

                                            Text {
                                                id:desc1
                                                Layout.fillWidth:true
                                                //Layout.preferredWidth:Math.min(parent.width - app.units(2),600*app.scaleFactor)

                                                visible:headingText.text === app.details

                                                text: modelData.description? modelData.description:""
                                                verticalAlignment: Text.AlignBottom
                                                color: app.textColor

                                                font{
                                                    pixelSize: app.subtitleFontSize
                                                    family: app.customTextFont.name
                                                }
                                                elide: Text.ElideRight
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 3

                                            }
                                        }

                                        Item {
                                            Layout.preferredHeight: 4 * scaleFactor
                                        }

                                    }

                                }

                            }

                        }
                    }
                }


            }

        }


        Rectangle {
            id:buttonbar
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50*app.scaleFactor
            Layout.maximumWidth: Math.min(parent.width * 0.95, 600*scaleFactor);
            Layout.alignment: Qt.AlignHCenter
            color:app.pageBackgroundColor

            radius: 4*app.scaleFactor
            clip: true

            Layout.bottomMargin:app.isIPhoneX ? 28 * app.scaleFactor : 8 * scaleFactor

            RowLayout{
                anchors.fill: parent
                spacing:8 * app.scaleFactor
                CustomButton {
                    buttonText: qsTr("Save")
                    buttonColor: app.buttonColor
                    buttonFill: false
                    buttonWidth: submitBtn.visible ? ((parent.width- 8 * app.scaleFactor)/2) : parent.width
                    buttonHeight: 50*app.scaleFactor
                    Layout.fillWidth: true
                    visible:true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var isValidGeo = false;

                            if(captureType === "line" && polylineObj && polylineObj.parts.part(0) && polylineObj.parts.part(0).pointCount>=2){
                                isValidGeo = true;
                            }else if(captureType === "area" && polygonObj && polygonObj.parts.part(0) && polygonObj.parts.part(0).pointCount>=3){
                                isValidGeo = true;
                            }else if(captureType === "point") {
                                if(app.theNewPoint)
                                    isValidGeo = true;
                            }
                            //console.log("isValidGeo", isValidGeo)

                            isReadyForSubmit = isValidGeo && isMediaRequirementMet() && isDetailRequirementMet()
                            app.isReadyForSubmitReport = isReadyForSubmit
                            next("save")
                        }
                    }
                }
                /*Item{
                 Layout.preferredWidth:8 * app.scaleFactor
                 Layout.fillHeight:true
                }*/

                CustomButton {
                    id: submitBtn

                    buttonText: qsTr("Submit")
                    buttonColor: app.buttonColor
                    buttonFill: app.isOnline
                    //buttonColor: (attributesPage.hasAllRequired && attributesPage.isRangeValidated)? app.buttonColor:"red"
                    //buttonFill: attributesPage.hasAllRequired && attributesPage.isRangeValidated
                    buttonWidth: (parent.width - 8 * app.scaleFactor)/2
                    buttonHeight: 50 * app.scaleFactor
                    Layout.preferredWidth:(parent.width - 8 * app.scaleFactor)/2
                    //Layout.fillWidth: true
                    visible: Networking.isOnline
                    MouseArea {
                        anchors.fill: parent
                        enabled:app.isOnline
                        onClicked: {
                            var detailRequirementsMet = isDetailRequirementMet()
                            var mediaRequirementsMet = isMediaRequirementMet()
                            if(captureType === "line" && !(polylineObj && polylineObj.parts.part(0) && polylineObj.parts.part(0).pointCount>=2)){
                                alertBox.text = qsTr("Unable to submit");
                                alertBox.informativeText = qsTr("Add a valid map path.")+"\n";
                                alertBox.visible = true;
                            }else if(captureType === "area" && !(polygonObj && polygonObj.parts.part(0) && polygonObj.parts.part(0).pointCount>=3)){
                                alertBox.text = qsTr("Unable to submit");
                                alertBox.informativeText = qsTr("Add a valid map area.")+"\n";
                                alertBox.visible = true;
                            }
                            else if(captureType === "point" && !app.theNewPoint)
                            {
                                alertBox.text = qsTr("Unable to submit");
                                alertBox.informativeText = qsTr("GPS not initialized.")+"\n";
                                alertBox.visible = true;


                            }

                            else if(!mediaRequirementsMet)
                            {

                                alertBox.text = qsTr("Unable to submit");
                                alertBox.informativeText = qsTr("Missing required attachment.")+"\n";
                                alertBox.visible = true;

                            }
                            else if(!detailRequirementsMet)
                            {
                                alertBox.text = qsTr("Unable to submit");
                                alertBox.informativeText = qsTr("Missing required field.")+"\n";
                                alertBox.visible = true;
                            }

                            else{

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



    ConfirmBox{
        id: attachmentSizeDialog
        anchors.fill: parent
        text: dataWarningMessage
        onAccepted: {
            next("submit");
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

    function isMediaRequirementMet()
    {
        if(!app.allowPhotoToSkip && app.appModel.count === 0)
            return false
        else
            return true
    }

    function isDetailRequirementMet()
    {
        var isDetailRequirementMet = true
        for(var i=0;i<fieldsMassaged.length;i++){
            var obj = fieldsMassaged[i]
            if(obj["nullable"]===false)
            {
                var fldName = obj["name"]
                var fieldVal = app.getAttributeValue(fldName)
                if(fieldVal === null || fieldVal === undefined || fieldVal === "")
                {
                    isDetailRequirementMet = false
                    break
                }


            }

        }
        return isDetailRequirementMet
    }

    function back(){
        stackView.pop();
    }


}


