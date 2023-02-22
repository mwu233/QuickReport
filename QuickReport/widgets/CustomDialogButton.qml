import QtQuick 2.0
import QtQuick.Controls 2.15
import QtQml 2.15
import QtQuick.Controls.Material 2.1 as MaterialStyle

import ArcGIS.AppFramework 1.0

Button {
    id: customDialogButton

    property string customText: "default"
    property string primaryColor: "#009688"

    text: customText

    contentItem: Text {
        text: customDialogButton.text
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: MaterialStyle.Material.theme === MaterialStyle.Material.Dark? "#E0E0E0" : primaryColor
        font {
            pixelSize: AppFramework.systemInformation.family === "phone" ? parent.height * 0.25 : parent.height * 0.24
            bold: true
        }
    }

    background: Rectangle {
        color: "transparent"
    }
}
