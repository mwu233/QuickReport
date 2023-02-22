import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1

import ArcGIS.AppFramework 1.0

Popup {
    id: rootPopup

    property var menuItems: []
    property real defaultMargin: app.units(16)
    property color backgroundColor:"#F7F8F8"
    property color highlightColor: Qt.darker(backgroundColor, 1.1)
    property color textColor:app.headerTextColor//"#F7F8F8"
    property color primaryColor: "#166DB2"
    property int defaultContentWidth: 0
    property int defaultContentHeight: popuplist.height
    property int maxWidth: units(200)
    property int minWidth: units(130)
    property string oldLabel:""

    signal menuItemSelected (string itemLabel)

    leftPadding: 0
    rightPadding: 0

    ListView {
        id:popuplist

        anchors.fill: parent
        model: menuModel
        //interactive: isInteractive

        delegate:  Card {
            id: menuItem

            headerHeight: 0
            footerHeight: 0
            padding: 0
            spacing: rootPopup.defaultMargin
            backgroundColor:rootPopup.backgroundColor
            height: label.contentHeight + app.units(16)
            width:  rootPopup.defaultContentWidth
            //anchors.horizontalCenter: popuplist.horizontalCenter

            propagateComposedEvents: false
            preventStealing: false
            mouseAccepted: true
            Material.elevation: 0
            content: Pane {
                id:copyPane
                anchors.fill: parent
                leftPadding:   rootPopup.defaultMargin
                rightPadding:  rootPopup.defaultMargin
                topPadding: 0
                bottomPadding: 0

                RowLayout {
                    id: copyRowLayout
                    anchors.fill: parent
                    spacing:0

                    Rectangle {
                        id:icon
                        Layout.fillHeight: 20 * scaleFactor
                        Layout.preferredWidth: 20 * scaleFactor //Math.floor((parent.width - 4 * scaleFactor) / 4)
                        color:backgroundColor

                        ImageOverlay{
                            width: 20 * scaleFactor
                            height: 20 * scaleFactor
                            anchors.centerIn: parent
                            source: getImageSource(itemLabel)
                            showOverlay: true
                            overlayColor: app.isDarkMode ? "white" : "#595959"

                        }
                    }

                    Item {
                        Layout.preferredWidth: 10 * scaleFactor
                        Layout.preferredHeight: parent.height
                    }

                    BaseText {
                        id: label
                        text: itemLabel

                        Layout.preferredWidth: rootPopup.defaultContentWidth - app.units(64)

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        color:  rootPopup.textColor
                        maximumLineCount: 1
                        Layout.margins: 0
                        elide: Text.ElideRight

                        onContentWidthChanged: {
                            if(oldLabel !== app.save_entries && itemLabel === save_entries)
                            {

                                rootPopup.defaultContentWidth = 0

                            }
                            oldLabel = itemLabel


                            var oldWidth = rootPopup.defaultContentWidth
                            var newWidth = contentWidth + icon.width + app.units(86)

                            newWidth=Math.min(newWidth,app.width-icon.width-app.units(32))


                           var finalWidth = 0
                            finalWidth = Math.max(oldWidth,newWidth)


                               rootPopup.defaultContentWidth = finalWidth



                        }
                    }
                }
            }

            function getImageSource(label)
            {
                switch(label)
                {
                case app.paste_entries:
                    return "../images/ic_content_copy_black_24dp.png"
                case app.clear_entries:
                    return "../images/ic_trash_can_outline_black_24dp.png"
                case app.save_entries:
                    return "../images/ic_star_outline_black_24dp.png"
                case app.delete_app:
                    return "../images/delete.png"
                default:
                    return null


                }

            }

            onClicked: {

                menuItemSelected(itemLabel)

            }

        }
    }

    ListModel {
        id: menuModel
    }

    onMenuItemSelected: {
        close()
    }

    onVisibleChanged: {
        if (visible) {
            updateMenu()
        }
    }

    function updateMenu () {
        menuModel.clear()
        for (var i=0; i< rootPopup.menuItems.length; i++) {
            menuModel.append( rootPopup.menuItems[i])
        }
    }

    function appendUniqueItemToMenuList (item, keyCheck) {
        if (!keyCheck) keyCheck = "itemLabel"
        var hasItem = false
        for (var i=0; i<menuItems.length; i++) {
            if (menuItems[i][keyCheck] === item[keyCheck]) {
                hasItem = true
                break
            }
        }
        if (!hasItem) menuItems.push(item)
    }

    function removeItemFromMenuList (item, keyCheck) {
        if (!keyCheck) keyCheck = "itemLabel"
        var newList = []
        for (var i=0; i<menuItems.length; i++) {
            if (menuItems[i][keyCheck] === item[keyCheck]) continue
            newList.push(menuItems[i])
        }
        menuItems = newList
    }

    function appendItemsToMenuList (items) {
         rootPopup.menuItems = items.concat( rootPopup.menuItems)

    }

    function units (num) {
        return num ? num * AppFramework.displayScaleFactor : num
    }
}
