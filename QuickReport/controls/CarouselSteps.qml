import QtQuick 2.7
import ArcGIS.AppFramework 1.0
import QtQuick.Layouts 1.3

Rectangle {
    property int items: 5
    property int currentIndex: 1
    property int size: 8*app.scaleFactor
    property color itemColor: "white"
    property bool isDebug: false

    color: "transparent"
    border.width: isDebug? 1:0
    border.color: "yellow"

    anchors.centerIn: parent

    RowLayout{
        anchors.centerIn: parent
        spacing: 8*app.scaleFactor
        Repeater{
            model: items
            delegate: Rectangle{
                color: itemColor
                opacity: currentIndex === index ? 0.9 : 0.5
                width: size
                height: size
                radius: size/2
                anchors.margins: 8 * AppFramework.displayScaleFactor
            }
        }
    }
}
