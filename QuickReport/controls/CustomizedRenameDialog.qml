import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.3
import QtMultimedia 5.8
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Multimedia 1.0

Dialog {
    id: dialog

    property string newName: ""             // audio file name
    property string extension: ""           // audio file extension
    property bool isNameConflict: false     // flag for name conflict

    modal: true
    dim: true
    closePolicy: Dialog.NoAutoClose
    title: qsTr("Rename file")

    Material.background: "#424242"
    Material.foreground: "white"
    Material.accent: "white"

    ColumnLayout {
        width: parent.width

        // text show up when name conflict
        Label {
            text: qsTr("File already exists or filename is not valid. Please use a different name.")
            Layout.preferredWidth: parent.width
            wrapMode: Label.Wrap
            color: "red"
            visible: isNameConflict
        }

        TextField {
            id: textField
            Layout.fillWidth: true
            Material.primary: "white"
            Material.foreground: "white"
            Material.accent: Material.Indigo

            onTextChanged: {
                newName = text + "." + extension;
            }

            onAccepted: {
                dialog.accept();
            }
        }
    }

    standardButtons: Dialog.Cancel | Dialog.Ok

    // initial rename dialog
    function openDialog(fileName){
        newName = fileName;
        var array = fileName.split(".");
        textField.text = array[0];
        extension = array[1];
        textField.selectAll();
    }
}
