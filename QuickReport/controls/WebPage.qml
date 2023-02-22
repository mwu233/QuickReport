import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import ArcGIS.AppFramework.WebView 1.0

import ArcGIS.AppFramework 1.0
import "../controls"

Page {

    transitions: Transition{
        PropertyAnimation { duration:200}
    }

    property url link: ""
    property string titleText: qsTr("Help")

    visible: showOnStart

    property bool showOnStart: false



    function loadPage(url) {
        while (webItem.canGoFront) {
            webItem.stop()
            console.debug("go back");
        }
        console.debug("Got: ", url);
        if(url) {
            link = url
        }
    }

    function loadLocalHtml(id){
        while (webItem.canGoFront) {
            webItem.stop()
            console.debug("go back");
        }

        //var path = AppFramework.userHomeFolder.filePath("ArcGIS/AppStudio/Data");
        var arr = helpPageUrl.split("/");
        var resourceFolderName = arr[0];
        var resourceFileName = arr[1];
        var resourceFolder = AppFramework.fileFolder(app.folder.folder(resourceFolderName).path)

        var html = resourceFolder.readTextFile(resourceFileName);

        webItem.loadHtml(html, "http://www.example.com#"+id);
    }

    function close(){
        console.debug("Close button clicked ");
        while (webItem.canGoBack) {
            webItem.goBack()
            console.debug("go back");
        }
        //close the page
        transitionOut(transition.topDown)
    }

    property color headerColor: app.headerBackgroundColor

    //footer.implicitHeight: 0

    header:  Rectangle {
        id: headerContainer
        anchors.fill: parent
        color: headerColor

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            height: 2 * app.scaleFactor
            color: app.buttonColor
            z:111
            visible: webItem.loading
            width: parent.width * webItem.loadProgress/100
        }
        Text {
            text: titleText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: app.titleFontSize
            font.family: app.customTitleFont.name
            color: "white"
        }

        Icon {
            imageSource: "../images/ic_clear_white_48dp.png"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            onIconClicked: {
                console.debug("Close button clicked ");
                //close the page
                transitionOut(transition.topDown)
            }
        }
    }

    DropShadow {
        source: headerContainer
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

    content: WebView {
        id: webItem
        width: parent.width
        height: parent.height
        url: link
        clip: true


        BusyIndicator {
            visible: running
            running: webItem.loading
            z: webItem.z + 1
            anchors.centerIn: webItem
        }

        Text {
            color: "#165F8C"
            text: webItem.url
            visible: webItem.loading
            width: parent.width * 0.8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20 * app.scaleFactor
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode:Text.WrapAnywhere
            z: webItem.z + 1
            textFormat: Text.StyledText
            maximumLineCount: 2

            onLinkActivated: {
                Qt.openUrlExternally(link);
            }
        }
    }

    Component.onCompleted:  {
        console.debug("Web page on-complete !!")
    }

    Component.onDestruction: {
        console.debug("Web page on-destruction :(")
    }

}
