import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

ProgressBar{
    id: progressBar

    width: parent.width /2
    height: width

    value: 0.0
    padding: 0

    property real weight: 10
    property alias backgroundColor: canvas.primaryColor
    property alias accentColor: canvas.secondaryColor
    property alias labelText: label.text

    background: Rectangle {
        width: 0
        height: 0
        visible: false
    }

    contentItem : Item {
        width: progressBar.width
        height: progressBar.height
        Canvas {
            id: canvas
            width: parent.width
            height: parent.height
            antialiasing: true
            smooth: true

            property color primaryColor: "orange"
            property color secondaryColor: "lightblue"

            property real centerWidth: width / 2
            property real centerHeight: height / 2
            property real radius: Math.min(canvas.width, canvas.height) / 2
            property real minimumValue: 0
            property real maximumValue: 100
            property real currentValue: Math.floor(progressBar.value*100)

            // this is the angle that splits the circle in two arcs
            // first arc is drawn from 0 radians to angle radians
            // second arc is angle radians to 2*PI radians
            property real angle: (currentValue - minimumValue) / (maximumValue - minimumValue) * 2 * Math.PI

            // we want both circle to start / end at 12 o'clock
            // without this offset we would start / end at 9 o'clock
            property real angleOffset: -Math.PI / 2

            property string text: currentValue + "%"

            onPrimaryColorChanged: requestPaint()
            onSecondaryColorChanged: requestPaint()
            onMinimumValueChanged: requestPaint()
            onMaximumValueChanged: requestPaint()
            onCurrentValueChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.save();

                ctx.clearRect(0, 0, canvas.width, canvas.height);

                ctx.beginPath();
                ctx.lineWidth = weight;
                ctx.strokeStyle = primaryColor;
                ctx.lineCap = "butt";
                ctx.arc(canvas.centerWidth,
                        canvas.centerHeight,
                        canvas.radius-ctx.lineWidth,
                        angleOffset,
                        angleOffset + 2*Math.PI);
                ctx.stroke();

                ctx.beginPath();
                ctx.lineWidth = weight;
                ctx.strokeStyle = canvas.secondaryColor;
                ctx.lineCap = "butt";
                ctx.arc(canvas.centerWidth,
                        canvas.centerHeight,
                        canvas.radius-ctx.lineWidth,
                        canvas.angleOffset,
                        canvas.angleOffset + canvas.angle);
                ctx.stroke();

                ctx.restore();
            }

            Label {
                id: label
                anchors.centerIn: parent

                text: canvas.text
                color: canvas.secondaryColor
                font.pixelSize: 20*AppFramework.displayScaleFactor
            }
        }
    }

}
