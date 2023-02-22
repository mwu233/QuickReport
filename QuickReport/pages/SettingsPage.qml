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
import QtQuick.Dialogs 1.2
import QtQuick.Controls 2.2 as NewControls
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.1 as NewMaterial
import ArcGIS.AppFramework.Platform 1.0

import ArcGIS.AppFramework 1.0

import "../controls/"



Item{
    id:_root
    width: parent.width
    height: parent.height

    signal next(string message)
    signal previous(string message)

    property int hitFeatureId
    property variant attrValue
    visible: false

    property real factor: 1.2

    function open(){
        _root.visible = true
        bottomUp.start();
    }

    function hide(){
        topDown.start();
    }
    function showTheme(){
        settingsstackView.push(themeListPage)
    }
    Component{
        id: themeListPage
        ThemeListPage {

        }
    }

    Rectangle {
        id:settingsRect
        width: parent.width
        height: parent.height
        color: app.pageBackgroundColor

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: settingsPage_headerBar
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

                Text {
                    id: mapPage_titleText
                    text: qsTr("Settings")
                    textFormat: Text.StyledText
                    anchors.centerIn: parent
                    font.pixelSize: app.titleFontSize
                    font.family: app.customTitleFont.name
                    color: app.headerTextColor
                    maximumLineCount: 1
                    elide: Text.ElideRight
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
                        hide();
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.fillHeight: true
                color: app.pageBackgroundColor
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: parent.height - settingsPage_headerBar.height
                Layout.topMargin: app.units(16)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mouse.accepted = false
                    }
                }

                Flickable {
                    anchors.fill: parent
                    contentHeight: columnContainer.height
                    clip: true

                    ColumnLayout {
                        id: columnContainer
                        width: Math.min(parent.width, 600*app.scaleFactor)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0//-1

                        Rectangle {

                            Layout.preferredHeight: 1 * app.scaleFactor
                            Layout.fillWidth: true
                            color:Qt.darker(app.pageBackgroundColor, factor)
                            //color:blk_030
                        }

                        Rectangle{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45*app.scaleFactor
                            color: Qt.lighter(app.pageBackgroundColor, factor)
                            //border.width: 1
                            //border.color: Qt.darker(app.pageBackgroundColor, factor)
                            RowLayout{
                                anchors.fill: parent
                                anchors.left: parent.left
                                anchors.leftMargin: 16*app.scaleFactor
                                anchors.right: parent.right
                                anchors.rightMargin: 16*app.scaleFactor
                                spacing: 16*app.scaleFactor
                                ImageOverlay{
                                    Layout.preferredHeight: 25*app.scaleFactor
                                    Layout.preferredWidth: 25*app.scaleFactor
                                    Layout.alignment: Qt.AlignVCenter
                                    source: "../images/text_field_black.png"
                                    fillMode: Image.PreserveAspectFit
                                    opacity: 0.6
                                    showOverlay: app.isDarkMode
                                }

                                Text{
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: qsTr("Font Size")
                                    fontSizeMode: Text.Fit
                                    font.pixelSize: app.textFontSize
                                    font.family: app.customTitleFont.name
                                    color: app.subtitleColor
                                }

                                NewControls.SpinBox {

                                    id: box
                                    from: 80
                                    to: app.isSmallScreen? 120:160
                                    stepSize: app.isSmallScreen? 10:20
                                    value: app.fontScale*100


                                    textFromValue: function(value, locale) {
                                        return value+"%";
                                    }

                                    valueFromText: function(text, locale) {
                                        return Number.fromLocaleString(locale, text.replace("%",""))
                                    }

                                    implicitHeight: 30*app.scaleFactor
                                    Layout.alignment: Qt.AlignVCenter
                                    font:{

                                        pixelSize: app.subtitleFontSize
                                        family: app.customTitleFont.name
                                    }

                                    onValueChanged: {
                                        app.fontScale = value/100;
                                        app.settings.setValue("fontScale", app.fontScale);
                                    }

                                    contentItem: Text {
                                        z: 8

                                        text: "%1%".arg(box.value)
                                        font: box.font
                                        fontSizeMode: Text.Fit
                                        elide: Text.ElideRight
                                        color: black_87
                                        horizontalAlignment: Qt.AlignHCenter
                                        verticalAlignment: Qt.AlignVCenter
                                        anchors.centerIn: parent
                                        width: box.width - (upButton.width + downButton.width)
                                        minimumPointSize: 1
                                    }

                                    up.indicator: Rectangle {
                                        id: upButton

                                        x: box.mirrored ? 0 : parent.width - width
                                        height: parent.height
                                        implicitWidth: units(32)
                                        implicitHeight: units(32)
                                        color: "transparent"
                                        border.color: Qt.darker("#EFEFEF", 1.1)

                                        Text {
                                            text: "+"
                                            font.pixelSize: box.font.pixelSize * 2
                                            color: black_87
                                            anchors.fill: parent
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    down.indicator: Rectangle {
                                        id: downButton

                                        x: box.mirrored ? parent.width - width : 0
                                        height: parent.height
                                        implicitWidth: units(32)
                                        implicitHeight: units(32)
                                        color: "transparent"
                                        border.color: Qt.darker("#EFEFEF", 1.1)

                                        Text {
                                            text: "-"
                                            font.pixelSize: box.font.pixelSize * 2
                                            color:  black_87
                                            anchors.fill: parent
                                            fontSizeMode: Text.Fit
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    background: Rectangle {
                                        implicitWidth: units(140)
                                        border.color: Qt.darker("#EFEFEF", 1.1)
                                        color:"transparent"
                                    }
                                }

                            }
                        }
                        Rectangle {

                            Layout.preferredHeight: 1 * app.scaleFactor
                            Layout.fillWidth: true
                            color:Qt.darker(app.pageBackgroundColor, factor)
                            //color:blk_030
                        }
                        Item{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36*app.scaleFactor
                        }
                        Rectangle {

                            Layout.preferredHeight: 1 * app.scaleFactor
                            Layout.fillWidth: true
                            color:Qt.darker(app.pageBackgroundColor, factor)
                            //color:blk_030
                        }

                        SettingsTheme {
                            title: app.theme
                            subtitle:app.defaultTheme
                            visible: true//app.isDarkMode
                            imagesource: "../images/ic_chevron_right_white_48dp.png"
                            isImageVisible: true
                            overlayColor: app.blk_140
                            isAlignmentSet: false
                            parentPage:"settingsPage"
                            onClicked: {
                                showTheme()
                            }

                        }
                        Rectangle {

                            Layout.preferredHeight: 1 * app.scaleFactor
                            Layout.fillWidth: true
                            color:Qt.darker(app.pageBackgroundColor, factor)
                            //color:blk_030
                        }


                        Item{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36*app.scaleFactor
                        }

                        Rectangle{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45*app.scaleFactor
                            color: Qt.lighter(app.pageBackgroundColor, factor)
                            //border.width: 1
                            //border.color: Qt.darker(app.pageBackgroundColor, factor)
                            visible: app.isOnline && offlineMMPKID>"" && !app.mmpkSecureFlag
                            RowLayout{
                                anchors.fill: parent
                                anchors.left: parent.left
                                anchors.leftMargin: 16*app.scaleFactor
                                anchors.right: parent.right
                                anchors.rightMargin: 16*app.scaleFactor
                                spacing: 16*app.scaleFactor
                                Item{
                                    Layout.preferredHeight: 25*app.scaleFactor
                                    Layout.preferredWidth: 25*app.scaleFactor
                                    Layout.alignment: Qt.AlignVCenter
                                    clip: true
                                    ImageOverlay{
                                        width: 25*app.scaleFactor
                                        height: 25*app.scaleFactor
                                        source: app.mmpkManager.offlineMapExist? "../images/ic_offline_pin_black_48dp.png" : "../images/ic_file_download_black_48dp.png"
                                        fillMode: Image.PreserveAspectFit
                                        opacity: 0.6
                                        showOverlay: app.isDarkMode
                                        visible: !downloadingAnimation.running && app.mmpkManager.loadStatus != 1
                                    }

                                    ImageOverlay{
                                        id: downloadImage
                                        width: 25*app.scaleFactor
                                        height: 25*app.scaleFactor
                                        source: "../images/download_no_bar.png"
                                        fillMode: Image.PreserveAspectFit
                                        opacity: 0.6
                                        showOverlay: app.isDarkMode
                                        visible: downloadingAnimation.running
                                    }

                                    NumberAnimation{
                                        id: downloadingAnimation
                                        running: app.mmpkManager.loadStatus === 1
                                        target: downloadImage
                                        properties: "y"
                                        from: -25*app.scaleFactor
                                        to: 0
                                        alwaysRunToEnd: true
                                        duration: 1000
                                        loops: Animation.Infinite
                                    }
                                }

                                Text{
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: app.mmpkManager.offlineMapExist? app.mmpkMenuUpdateString : app.mmpkMenuDownloadString
                                    fontSizeMode: Text.Fit
                                    font.pixelSize: app.textFontSize
                                    font.family: app.customTitleFont.name
                                    color: app.subtitleColor
                                }
                            }
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    mmpkDialog.visible = true;
                                }
                            }
                        }

                        Rectangle {

                            Layout.preferredHeight: 1 * app.scaleFactor
                            Layout.fillWidth: true
                            color:Qt.darker(app.pageBackgroundColor, factor)
                            //color:blk_030
                        }

                        Item{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36*app.scaleFactor
                            visible: app.isOnline && offlineMMPKID>"" && !app.mmpkSecureFlag
                        }

                        Rectangle{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45*app.scaleFactor
                            color: Qt.lighter(app.pageBackgroundColor, factor)
                            //border.width: 1
                            //border.color: Qt.darker(app.pageBackgroundColor, factor)
                            RowLayout{
                                anchors.fill: parent
                                anchors.left: parent.left
                                anchors.leftMargin: 16*app.scaleFactor
                                anchors.right: parent.right
                                anchors.rightMargin: 16*app.scaleFactor
                                spacing: 16*app.scaleFactor
                                ImageOverlay{
                                    Layout.preferredHeight: 25*app.scaleFactor
                                    Layout.preferredWidth: 25*app.scaleFactor
                                    Layout.alignment: Qt.AlignVCenter
                                    source: "../images/ic_refresh_black_48dp.png"
                                    fillMode: Image.PreserveAspectFit
                                    opacity: 0.6
                                    showOverlay: app.isDarkMode
                                }

                                Text{
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: qsTr("Reset")
                                    fontSizeMode: Text.Fit
                                    font.pixelSize: app.textFontSize
                                    font.family: app.customTitleFont.name
                                    color: app.subtitleColor
                                }
                            }

                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    resetDialog.visible = true;
                                }
                            }
                        }

                        Rectangle {

                            Layout.preferredHeight: 1 * app.scaleFactor
                            Layout.fillWidth: true
                            color:Qt.darker(app.pageBackgroundColor, factor)
                            //color:blk_030
                        }

                        Item{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36*app.scaleFactor
                        }



                        Rectangle{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45*app.scaleFactor
                            color: Qt.lighter(app.pageBackgroundColor, factor)
                            //border.width: 1
                            //border.color: Qt.darker(app.pageBackgroundColor, factor)
                            visible: app.token.length>0
                            RowLayout{
                                anchors.fill: parent
                                anchors.left: parent.left
                                anchors.leftMargin: 16*app.scaleFactor
                                anchors.right: parent.right
                                anchors.rightMargin: 16*app.scaleFactor
                                spacing: 16*app.scaleFactor
                                ImageOverlay{
                                    Layout.preferredHeight: 25*app.scaleFactor
                                    Layout.preferredWidth: 25*app.scaleFactor
                                    Layout.alignment: Qt.AlignVCenter
                                    source: "../images/logout.png"
                                    fillMode: Image.PreserveAspectFit
                                    opacity: 0.6
                                    showOverlay: app.isDarkMode
                                }

                                Text{
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    text: qsTr("Sign Out")
                                    fontSizeMode: Text.Fit
                                    font.pixelSize: app.textFontSize
                                    font.family: app.customTitleFont.name
                                    color: app.subtitleColor
                                }
                            }

                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    logoutDialog.visible = true;
                                }
                            }
                        }
                        Rectangle {

                            Layout.preferredHeight: 1 * app.scaleFactor
                            Layout.fillWidth: true
                            color:Qt.darker(app.pageBackgroundColor, factor)
                            visible:app.token.length>0
                            //color:blk_030
                        }
                    }
                }
            }
        }

        DropShadow {
            source: settingsPage_headerBar
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

        function showTheme(){

            settingsstackView.push(themeListPage)
        }


        NumberAnimation {
            id: bottomUp
            target: _root
            property: "y"
            duration: 200
            from:_root.height
            to:0
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            id: topDown
            target: _root
            property: "y"
            duration: 200
            from:0
            to:_root.height
            easing.type: Easing.InOutQuad
            onStopped: {
                _root.visible = false
            }
        }

        ConfirmBox{
            id: mmpkDialog
            anchors.fill: parent
            text: app.mmpkManager.offlineMapExist? app.mmpkUpdateDialogString : app.mmpkDownloadDialogString
            onAccepted: {
                if(app.mmpkManager.offlineMapExist){
                    app.mmpkManager.updateOfflineMap(function(){})
                } else {
                    app.mmpkManager.downloadOfflineMap(function(){})
                }
            }
        }

        ConfirmBox{
            id: mmpkFailedDialog
            anchors.fill: parent
            text: app.mmpkDownloadFailString
            standardButtons: StandardButton.Ok
        }

        ConfirmBox{
            id: resetDialog
            anchors.fill: parent
            text: app.resetTitle
            informativeText: app.resetMessage
            onAccepted: {
                settingsRect.reset();
            }
        }

        ConfirmBox{
            id: logoutDialog
            anchors.fill: parent
            text: app.logoutTitle
            onAccepted: {
                settingsRect.logout();
            }
        }

        function reset(){
            app.mmpkManager.deleteOfflineMap();
            logout();
            app.removeAllSavedReport()
            app.clearAllFavorites()
            app.favoriteEntries = {}
            app.settings.setValue("appDefaultTheme", app.automatic);
            app.defaultTheme = app.automatic
            app.isDarkMode = app.defaultTheme === app.automatic?Platform.systemTheme.mode === SystemTheme.Dark:(defaultTheme === app.light?false:true) //false

            //
            // favoriteEntries[app.featureLayerBeingEdited] = {}
            app.loadFavorites()

            //
            //app.isDarkMode = false;
            //modeSwitch.checked = false;
            app.fontScale = 1.0;
            app.settings.setValue("isDarkMode", app.isDarkMode);
            app.settings.remove("fontScale");
        }

        function logout(){
            app.settings.remove("username");
            app.settings.remove("password");
            app.settings.remove("token");
            app.settings.remove("expiration");
            app.username = "";
            app.password = "";
            app.token = "";
            featureServiceManager.token = "";
            app.serverDialog.clearText();
            featureServiceManager.clearAllCache();
        }

        Connections{
            target: app.mmpkManager
            onLoadStatusChanged: {
                if(app.mmpkManager.loadStatus===2){
                    mmpkFailedDialog.visible = true;
                }
            }
        }

        function back(){
            if(resetDialog.visible == true) {
                resetDialog.visible = false;
            } else if(logoutDialog.visible == true) {
                logoutDialog.visible = false;
            } else if(mmpkDialog.visible == true) {
                mmpkDialog.visible = false;
            } else if(mmpkFailedDialog.visible == true) {
                mmpkFailedDialog.visible = false;
            } else{
                hide();
            }
        }
    }

    NewControls.StackView{
        id: settingsstackView
        anchors.fill: parent
        focus: true
        initialItem: Item {
            id: initpage
        }
    }
}
