import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

Dialog {
    id: messageDialog

    property string text
    property real pageHeaderHeight: messageDialog.units(56)
    property real defaultMargin: messageDialog.units(5)//app.defaultMargin
    property var acceptedSlot: []
    Material.accent:app.headerBackgroundColor

    background:  Rectangle {
        id: content
        color:app.pageBackgroundColor
        radius: 3*app.scaleFactor
        implicitWidth: Math.min(500*AppFramework.displayScaleFactor, app.width*0.8)
        width: implicitWidth
        height: implicitHeight
        clip: true

    }


    signal closeCompleted ()

    modal: true

    x: 0.5 * (parent.width - width)
    y: 0.5 * (parent.height - height - messageDialog.pageHeaderHeight)
    width: Math.min(0.8 * parent.width, messageDialog.units(400))
    //height: Math.min(0.8 * parent.height, messageDialog.units(400))


    closePolicy: Popup.NoAutoClose

    header: Text {
        visible: text > ""
        topPadding: defaultMargin
        rightPadding: messageDialog.rightPadding
        leftPadding: messageDialog.leftPadding
        //color: baseTextColor
        bottomPadding: 0
        text: messageDialog.title
        maximumLineCount: 2
        //elide: Text.ElideRight

        font.family: app.customTextFont.name
        color: app.textColor
        font.weight: Font.Bold
        font.pixelSize: app.textFontSize
    }

    contentItem: Pane {
        id: contentContainer

        padding: 0
        Material.background: "transparent"
        topPadding: messageDialog.units(8)
        //height: message.height

        Text {
            id: message
            width:parent.width
            height:100
            text: messageDialog.text
            maximumLineCount: 15
            fontSizeMode: Text.Fit
            rightPadding: 10
            wrapMode: Text.Wrap


            //anchors.centerIn: parent
            //elide: Text.ElideRight
            //width: parent.width
            clip: false
            font.family: app.customTextFont.name

            color: app.textColor
            font.weight: Font.Bold
            font.pixelSize: app.textFontSize

        }
    }

    standardButtons: Dialog.Ok

    footer: DialogButtonBox {

        background: Rectangle {

            color:app.pageBackgroundColor
            radius: 3*app.scaleFactor

            width: implicitWidth
            height: implicitHeight
            clip: true

        }

    }

    Component {
        id: buttonComponent

        Button {
            id: btn
            property color textColor: app.primaryColor
            Material.background: "transparent"
            contentItem: Text {
                text: btn.text
                font.pointSize: app.textFontSize
                color: textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    onClosed: {
        messageDialog.title = ""
        messageDialog.text = ""
        standardButtons = Dialog.Ok
        disconnectAllFromAccepted()
    }

    function addButton (text, role, textColor) {
        if (!textColor) textColor = app.primaryColor
        if (!role) role = DialogButtonBox.AcceptRole
        if (!text) text = ""
        var btn = buttonComponent.createObject(footer, {"text": text, "DialogButtonBox.buttonRole": role, "textColor": textColor})
    }

    function disconnectAllFromAccepted () {
        for (var i=0; i<acceptedSlot.length; i++) {
            onAccepted.disconnect(acceptedSlot[i])
        }
        closeCompleted()
    }

    function connectToAccepted (method) {
        acceptedSlot.push(method)
        onAccepted.connect(acceptedSlot[acceptedSlot.length - 1])
    }

    function show (title, description) {
        if (title) messageDialog.title = title
        if (description) messageDialog.text = description
        messageDialog.open()
    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }
}

