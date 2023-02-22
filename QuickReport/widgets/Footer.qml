import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3

ToolBar {
    id: root

    height: column.height

    Material.primary: app.pageBackgroundColor
    Material.elevation: 4
    property Item content

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 0
    }

    Component.onCompleted: {
        if (content)
            content.parent = column;
    }
}

