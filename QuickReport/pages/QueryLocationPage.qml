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

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtPositioning 5.11
import QtSensors 5.3
import QtMultimedia 5.2
import QtGraphicalEffects 1.0
import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Platform 1.0
import QtQuick.Controls.Material 2.2

// 2021-12-10
import QtLocation 5.11

import Esri.ArcGISRuntime 100.10

import "../controls"


Rectangle {
    id: queryLocationPage
    objectName: "queryLocationPage"
    width: parent?parent.width:0
    height: parent?parent.height:0
    color: app.pageBackgroundColor

    //signal next(string message)
    signal previous(string message)

    property bool isFirstTime: false
    property string gpsLocationString : ""
    property string currentLocatorTaskId: ""
    property string currentQueryTaskId:""

    property real xCoord: 0
    property real yCoord: 0

    property string offlineModeTitle: qsTr("Map not available in offline mode.")
    property string offlineModeGPSMEssage: qsTr("Using device GPS.")
    property string kAccuracy: qsTr("Accuracy")
    property string kLat: qsTr("Latitude")
    property string kLon: qsTr("Longitude")
    property string selectBookmarkString: qsTr("Select Bookmark")
    property string hintForGeoSearch: qsTr("Find address or place")
    property string type: "appview"
    property var webPage

    property int polygonId
    property int polylineId
    property var pointIds: []
    property bool firstPoint: true
    property bool isUndoable: false
    property bool isMapError: false

    property bool isFullMap: false
    // property alias reloadMapTimer: reloadMapTimer

    property var currentExt
    property bool isOfflineMap: false

    property var polylineBuilder
    property var polygonBuilder

    property var storedReadyForGeo
    property bool menuloaded: false
    Material.accent: Material.Grey

    //=============================== edit for filter =====================================================
    property real scaleFactor: AppFramework.displayScaleFactor
    property string displayText: "Click or tap to select features."

    //============================ edit for feature attribute and attachment===============================
    property real curIndx: -1
    property string url: ""

    ListModel{
        id:displayAttributesModel
    }
    //=============================== edit for filter =====================================================

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: createPage_headerBar
            Layout.alignment: Qt.AlignTop
            color: app.headerBackgroundColor
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 50 * app.scaleFactor
            visible: !isFullMap

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
                    processInput()
                    app.populateSummaryObject()
                    skipPressed = false;
                    positionSource.active = false;

                    previous("");
                }
            }

            Text {
                id: title
                text: qsTr("Query Disaster Reports")
                textFormat: Text.StyledText
                anchors.centerIn: parent
                font.pixelSize: app.titleFontSize
                font.family: app.customTitleFont.name
                color: app.headerTextColor
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            ImageButton {
                source: "../images/ic_send_white_48dp.png"
                height: 30 * app.scaleFactor
                width: 30 * app.scaleFactor
                visible:false // app.isFromSaved
                enabled: app.isFromSaved && app.isReadyForSubmitReport && app.isOnline
                opacity: enabled? 1:0.3
                checkedColor : "transparent"
                pressedColor : "transparent"
                hoverColor : "transparent"
                glowColor : "transparent"
                anchors.rightMargin: 10
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    confirmToSubmit.visible = false;
                }
            }
        }

        Item{
            Layout.fillWidth: true
            Layout.preferredHeight: 16*app.scaleFactor
            visible: !isFullMap
        }

//        RowLayout{
//            Layout.preferredWidth: parent.width
//            Layout.preferredHeight: createPage_titleText.height
//            Layout.alignment: Qt.AlignHCenter
//            spacing: 5*app.scaleFactor
//            visible: !isFullMap
//            Text {
//                id: createPage_titleText
//                // changes on 2021-12-09
//                text: captureType === "point"?qsTr("Query Disasters"):(captureType==="line"?qsTr("Add Path"):qsTr("Add Area"))

//                textFormat: Text.StyledText
//                Layout.alignment: Qt.AlignHCenter
//                font.pixelSize: app.titleFontSize
//                font.family: app.customTitleFont.name
//                horizontalAlignment: Text.AlignHCenter
//                verticalAlignment: Text.AlignVCenter
//                color: app.textColor
//                maximumLineCount: 1
//                elide: Text.ElideRight
//                fontSizeMode: Text.Fit
//            }

//            ImageOverlay{
//                Layout.preferredHeight: Math.min(36*app.scaleFactor, parent.height)*0.9
//                Layout.preferredWidth: Math.min(36*app.scaleFactor, parent.height - (5*app.scaleFactor))*0.9
//                source: "../images/ic_info_outline_black_48dp.png"
//                visible: app.isHelpUrlAvailable
//                overlayColor: app.textColor
//                showOverlay: true
//                fillMode: Image.PreserveAspectFit
//                Layout.alignment: Qt.AlignVCenter
//                MouseArea{
//                    anchors.fill: parent
//                    onClicked: {
//                        if(app.helpPageUrl && validURL(app.helpPageUrl))
//                            app.openWebView(0, {  url: app.helpPageUrl });
//                        else
//                        {
//                            var component = webPageComponent;
//                            webPage = component.createObject(queryLocationPage);
//                            webPage.openSectionID(""+2)
//                        }
//                        //app.openWebView(1, { pageId: queryLocationPage, url: "" + 2 });
//                    }
//                }
//            }
//        }

        Item{
            Layout.fillWidth: true
            Layout.preferredHeight: 8*app.scaleFactor
            visible: !isFullMap
        }

        Item{
            Layout.fillWidth: true
            Layout.preferredHeight: 8*app.scaleFactor
            visible: !isFullMap
        }

        MobileMapPackage {
            id: mmpk
            path: app.mmpkManager.fileUrl
            onLoadStatusChanged: {
                if (loadStatus === Enums.LoadStatusLoaded) {
                    mapView.map = mmpk.maps[0];
                    isOfflineMap = true;
                    if(queryLocationPage.currentExt){
                        mapView.setViewpointGeometry(queryLocationPage.currentExt);
                    }
                    mapView.initGeometry()
                    // mapView.updateQueryReportsData();
                }
            }
        }

        Map{
            id: webMap
            initUrl: app.webMapRootUrl + app.webMapID

            // add points to the map, 2021-12-10
//            onLoadStatusChanged: {
//                if (loadStatus !== Enums.LoadStatusLoaded)
//                    return;
//                mapView.updateQueryReportsData();
//            }
            FeatureLayer {
                id: featureLayer

                // feature table
                ServiceFeatureTable {
                    id: featureTable
                    url: app.featureLayerURL;
                }
            }
        }

        MapView{
            id: mapView
            Layout.preferredWidth: isFullMap? parent.width:(parent.width - 20 *app.scaleFactor)
            Layout.fillHeight: true
            Layout.maximumWidth: isFullMap? Number.POSITIVE_INFINITY: 600 * app.scaleFactor
            Layout.alignment: Qt.AlignHCenter

            property real initialMapRotation: 0

            rotationByPinchingEnabled: true
            zoomByPinchingEnabled: true
            wrapAroundMode: Enums.WrapAroundModeEnabledWhenSupported

            backgroundGrid: BackgroundGrid {
                gridLineWidth: 1
                gridLineColor: "#22000000"
            }

            Rectangle{
                anchors.fill: parent
                border.width: 1
                border.color: "darkgrey"
                color: "transparent"
            }

            locationDisplay {
                positionSource: PositionSource {
                    id: positionSource
                    active: Permission.checkPermission(Permission.PermissionTypeLocationWhenInUse) === Permission.PermissionResultGranted
                }
                compass: Compass {}
                showAccuracy: true
                showLocation: true
            }

            GeocodeParameters {
                id: geocodeParameters
                minScore: 75
                maxResults: 10
                resultAttributeNames: ["Place_addr", "Match_addr", "Postal", "Region"]
            }

            LocatorTask {
                id: locatorTask
                url: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"
                suggestions.suggestParameters: SuggestParameters{
                    maxResults: 4
                    //countryCode: app.countryCode
                }
                suggestions.searchText: searchTextField.text
                onGeocodeStatusChanged: {
                    if (geocodeStatus === Enums.TaskStatusCompleted) {
                        if(geocodeResults){
                            mapView.zoomToPoint(geocodeResults[0].displayLocation);
                        }
                    }
                }
            }

            Component.onCompleted: {
                // add points
                //mapView.updateQueryReportsData();

                storedReadyForGeo = app.isReadyForGeo;

                if(app.isOnline) {
                    mapView.map = webMap;
                    isOfflineMap = false;
                } else {
                    if(mmpkManager.offlineMapExist){
                        mmpk.load();
                        isOfflineMap = true;
                    }
                }
            }

            Connections{
                target: mapView.map
                onLoadStatusChanged :{
                    if (mapView.map.loadStatus === Enums.LoadStatusLoaded) {
                        // reloadMapTimer.stop();
                        var currentPositionPoint
                        if(theNewPoint) currentPositionPoint = theNewPoint;
                        else currentPositionPoint = ArcGISRuntimeEnvironment.createObject("Point", {x: positionSource.position.coordinate.longitude, y: positionSource.position.coordinate.latitude, spatialReference: Factory.SpatialReference.createWgs84()});

                        var viewPointCenter = GeometryEngine.project(currentPositionPoint, mapView.spatialReference);

                        if(queryLocationPage.currentExt) {
                            mapView.setViewpointGeometry(queryLocationPage.currentExt);
                        } else if(app.centerExtent) {
                            app.centerExtent = GeometryEngine.project(app.centerExtent, mapView.spatialReference);
                            mapView.setViewpointGeometry(app.centerExtent);
                        } else {
                            mapView.zoomToCurrentLocation();
                        }

                        var bookmarkModel = mapView.map.bookmarks;
                        if(bookmarkModel.count>0){
                            var defaultBookmark = ArcGISRuntimeEnvironment.createObject("Bookmark", {name: selectBookmarkString, viewpoint: viewPointCenter})
                            bookmarkModel.insert(0, defaultBookmark);
                        }
                        mapView.initGeometry();
                        //mapView.updateQueryReportsData();
                    }
                }
            }

            function geocodeAddress() {
                if(currentLocatorTaskId > "" && locatorTask.loadStatus === Enums.LoadStatusLoading) locatorTask.cancelTask(currentLocatorTaskId);
                currentLocatorTaskId = locatorTask.geocodeWithParameters(searchTextField.text, geocodeParameters);
            }

            function zoomToCurrentLocation(){
                var currentPositionPoint
                if(positionSource.position.coordinate.longitude){
                    currentPositionPoint = ArcGISRuntimeEnvironment.createObject("Point", {x: positionSource.position.coordinate.longitude, y: positionSource.position.coordinate.latitude, spatialReference: SpatialReference.createWgs84()});
                } else if(mapView.map && mapView.map.initialViewpoint && mapView.map.initialViewpoint.camera){
                    currentPositionPoint = mapView.map.initialViewpoint.camera.location;
                }
                var viewPointCenter = GeometryEngine.project(currentPositionPoint, mapView.spatialReference);
                mapView.setViewpointCenterAndScale(viewPointCenter, 10000);
            }

            function zoomToPoint(point){
                var centerPoint = GeometryEngine.project(point, mapView.spatialReference);
                var viewPointCenter = ArcGISRuntimeEnvironment.createObject("ViewpointCenter",{center: centerPoint, targetScale: 10000});
                mapView.setViewpointWithAnimationCurve(viewPointCenter, 2.0,  Enums.AnimationCurveEaseInOutCubic);
            }

            GraphicsOverlay{
                id: graphicOverlay
            }

            //! [identify graphics api snippet]
            // Signal handler for mouse click event on the map view
            onMouseClicked: {
//                const tolerance = 22;
//                const returnPopupsOnly = false;
//                const maximumResults = 1000;
//                mapView.identifyGraphicsOverlayWithMaxResults(graphicOverlay, mouse.x, mouse.y, tolerance, returnPopupsOnly, maximumResults);

                if(mapView.map.loadStatus === Enums.LoadStatusLoaded){
                    if (app.captureType === "line"){
                        addPointToPolyline(mapView.screenToLocation(mouse.x, mouse.y));
                        drawPoint(mapView.screenToLocation(mouse.x, mouse.y));
                    } else if(app.captureType === "area") {
                        addPointToPolygon(mapView.screenToLocation(mouse.x, mouse.y));
                        drawPoint(mapView.screenToLocation(mouse.x, mouse.y));
                    }
                }

                var tolerance = 22;
                var returnPopupsOnly = false;
                var maximumResults = 1000;
                mapView.identifyLayerWithMaxResults(featureLayer, mouse.x, mouse.y, tolerance, returnPopupsOnly, maximumResults);
            }

            onIdentifyLayerStatusChanged: {
                if (identifyLayerStatus === Enums.TaskStatusCompleted) {
                    // clear any previous selections
                    featureLayer.clearSelection();
                    displayAttributesModel.clear();

                    // create an array to store the features
                    var identifiedObjects = [];

                    console.log(identifyLayerResult.geoElements.length);
                    for (var i = 0; i < identifyLayerResult.geoElements.length; i++){
                        var elem = identifyLayerResult.geoElements[i];
                        //console.log(elem);
                        identifiedObjects.push(elem);
                        displayAttributesModel.append(elem);

                    }
                    // cache the number of identifyLayerResult
                    var count = identifyLayerResult.geoElements.length;

                    // select the features in the feature layer
                    featureLayer.selectFeatures(identifiedObjects);
                    displayText = "%1 %2 selected.".arg(count).arg(count > 1 ? "features" : "feature");
                }
            }

            Pane {
                id: attributeViewDialog

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: messageBar.top
                }

                Material.primary: "white"
                Material.elevation:2
                padding: 5 * scaleFactor
                visible: displayAttributesModel.count > 0

                SwipeView{
                    id:swipeView
                    implicitHeight: 150 * scaleFactor
                    implicitWidth: parent.width
                    clip: true
                    Repeater {
                        model:displayAttributesModel
                        Rectangle{
                            color: "white"
                            clip: true
                            Flickable {
                                anchors.fill:parent
                                contentWidth:parent.width
                                contentHeight: popupColumn.height
                                clip: true
                                flickableDirection: Flickable.VerticalFlick
                                ColumnLayout {
                                    id: popupColumn
                                    width: parent.width //*  0.95
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 3 * scaleFactor
                                    clip: true
                                    Text {
                                        Layout.preferredWidth:  parent.width
                                        id:itemDesc
                                        text: "Observations " + "(" + curIndx + " of " + displayAttributesModel.count + ")"
                                        elide: Text.ElideRight
                                        color: app.textColor
                                        font {
                                            family: "Times New Roman"
                                            pixelSize: 15 * scaleFactor
                                            bold: true
                                        }
                                        renderType: Text.NativeRendering
                                    }
                                    Rectangle {
                                        id:line
                                        Layout.preferredWidth: parent.width
                                        Layout.preferredHeight: 2 * scaleFactor
                                        color: app.textColor
                                    }

                                    //======================= modify attribute ==================================
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        clip: true
                                        spacing: 5 * scaleFactor

                                        Text {
                                            Layout.preferredWidth: popupColumn.width * 0.55
                                            Layout.fillHeight: true
                                            text:  "Disaster Type"
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: 12 * scaleFactor
                                            color: "gray"
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            text:attributes.attributeValue("DisasterType")
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: 12 * scaleFactor
                                            color: "#4f4f4f"

                                        }

                                        Text {
                                            Layout.preferredWidth: popupColumn.width * 0.55
                                            Layout.fillHeight: true
                                            text:  "Topic"
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: 12 * scaleFactor
                                            color: "gray"
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            text:attributes.attributeValue("Topic")
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: 12 * scaleFactor
                                            color: "#4f4f4f"

                                        }

                                        Text {
                                            Layout.preferredWidth: popupColumn.width * 0.55
                                            Layout.fillHeight: true
                                            text:  "Comments"
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: 12 * scaleFactor
                                            color: "gray"
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            text:attributes.attributeValue("Comments")
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: 12 * scaleFactor
                                            color: "#4f4f4f"

                                        }

                                        Text {
                                            Layout.preferredWidth: popupColumn.width * 0.55
                                            Layout.fillHeight: true
                                            text:  "Observed Date"
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: 12 * scaleFactor
                                            color: "gray"
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            text:attributes.attributeValue("ObservedDate")
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: 12 * scaleFactor
                                            color: "#4f4f4f"

                                        }

                                        Text {
                                            Layout.preferredWidth: popupColumn.width * 0.55
                                            Layout.fillHeight: true
                                            text:  "Attachment(s)"
                                            wrapMode: Text.WrapAnywhere
                                            font.pixelSize: 12 * scaleFactor
                                            color: "gray"
                                        }

                                        // ===================show attached img====================================
                                        Repeater {
                                            model:attachments
                                            // show the attachment's URL if it is an image
                                            Image {
                                                id: img
                                                width: 44 * scaleFactor
                                                height: width

                                                fillMode: Image.PreserveAspectFit
                                                source: attachmentUrl

                                                sourceSize.width: 44 * scaleFactor
                                                sourceSize.height: 44 * scaleFactor
                                                onSourceChanged: {
                                                    //console.log(source)
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        url = source
                                                        callout.y = messageBar.y - swipeView.height + line.y
                                                        callout.visible = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    //================================update ob index==================================

                    onCurrentIndexChanged: {
                        if(currentIndex < 0)return;
                        curIndx = currentIndex + 1
                    }

                }

            }

            //==============================img popout==========================================
            Rectangle {
                id: callout
                width: swipeView.width
                height: swipeView.height - 25 * scaleFactor
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 5
                border {
                    color: "lightgrey"
                    width: .5
                }
                visible: false

                Image {
                    id: zoomImg
                    width: parent.width
                    height: parent.height

                    fillMode: Image.PreserveAspectFit
                    source: url

                    //sourceSize.width: parent.width
                    //sourceSize.height: parent.height
                    onSourceChanged: {
                        console.log(source)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            callout.visible = false
                        }
                    }
                }
            }

            Rectangle {
                id: messageBar
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: mapView.bottom
                }
                height: 30 * scaleFactor
                color: app.headerBackgroundColor
                border {
                    width: 0.5 * scaleFactor
                    color: app.headerBackgroundColor
                }

                Text {
                    id: msgText
                    color: "white"
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 10 * scaleFactor
                    }
                    text: displayText
                    font.pixelSize: 14 * scaleFactor
                }
            }

            //! [identify feature layer qml api snippet]

            // Signal handler for identify graphics overlay
//            onIdentifyGraphicsOverlayStatusChanged: {
//                if (identifyGraphicsOverlayStatus === Enums.TaskStatusCompleted) {
//                    if (identifyGraphicsOverlayResult.graphics.length > 0) {

//                        var disasterType = identifyGraphicsOverlayResult.graphics[0].attributes.attributeValue("disasterType");
//                        var reportType = identifyGraphicsOverlayResult.graphics[0].attributes.attributeValue("reportType");
//                        var reportDate = identifyGraphicsOverlayResult.graphics[0].attributes.attributeValue("reportDate");

//                        messageDialog.text = qsTr("Report Type: ") + reportType + "\n" +
//                                qsTr("Disaster Type: ") + disasterType + "\n" +
//                                qsTr("Report Date: ") + reportDate + "\n";
//                        messageDialog.open();
//                    }
//                } else if (identifyGraphicsOverlayStatus === Enums.TaskStatusErrored) {
//                    console.log("error");
//                }
//            }
            //! [identify graphics api snippet]

            SimpleFillSymbol {
                id: simpleFillSymbol
                color: Qt.rgba(0.2,0.2,0.2,0.5)
                style: Enums.SimpleFillSymbolStyleSolid

                SimpleLineSymbol {
                    style: Enums.SimpleLineSymbolStyleSolid
                    color: "#0079C1"
                    width: 2.0
                }
            }

            SimpleLineSymbol {
                id: simpleLineSymbol
                color: "#0079C1"
                style: Enums.SimpleLineSymbolStyleSolid
                width: 2
            }

            Point {
                id: dume_beach
                x: -118.80657463861
                y: 34.0005930608889
                spatialReference: SpatialReference {wkid: 4326}
            }

            SimpleMarkerSymbol {
                id: bluePointSymbol
                color: "#0079C1"
                style: Enums.SimpleMarkerSymbolStyleCircle
                size: 8
            }

            SimpleMarkerSymbol {
                id: redPointSymbol
                color: "#C7461A"
                style: Enums.SimpleMarkerSymbolStyleCircle
                size: 12
            }

            SimpleMarkerSymbol {
                id: greenPointSymbol
                color: "green"
                style: Enums.SimpleMarkerSymbolStyleCircle
                size: 16
            }

            PictureMarkerSymbol {
                id: damageSymbol
                url: "../images/damage.png"
                width: 24.0
                height: 24.0
            }

            PictureMarkerSymbol {
                id: requestSymbol
                url: "../images/request.png"
                width: 24.0
                height: 24.0
            }

            PictureMarkerSymbol {
                id: donateSymbol
                url: "../images/donate.png"
                width: 24.0
                height: 24.0
            }

            function updateQueryReportsData(reportTypeSelected){

                mapView.clearGraphics();
                var queryString = "SELECT * FROM DRAFTS WHERE disasterType = '%1' ORDER BY featureLayerURL ASC, date DESC,CAST(SUBSTR(nameofitem,6) AS INT) DESC";

                if (typeof reportTypeSelected === "undefined" || reportTypeSelected === null) {
                    queryString = "SELECT * FROM DRAFTS ORDER BY featureLayerURL ASC, date DESC,CAST(SUBSTR(nameofitem,6) AS INT) DESC";
                } else {
                    queryString = queryString.arg(reportTypeSelected)
                }

                var select_query = db.query(queryString);
                console.log(queryString);

                db.query("BEGIN TRANSACTION")

                for(var ok = select_query.first(); ok; ok = select_query.next()) {
                    var obj = select_query.values;

                    var id = obj.id;
                    var editsJson = obj.editsjson;
                    var reportDate = obj.date;
                    var reportType = obj.reportType;
                    var disasterType = obj.disasterType;

                    // changes on 2021-12-10
                    var geometryDescription = JSON.parse(editsJson)[0]["geometryDescription"];

                    var geometryLatLon = geometryDescription.split(" ");
                    var latString = geometryLatLon[0];
                    var lonString = geometryLatLon[1];

                    var lat = Number(latString.substring(0, latString.length - 1));
                    var lon = Number(lonString.substring(0, lonString.length - 1));

                    if (latString[latString.length - 1] === 'S') {
                        lat = (-1) * lat;
                    }
                    if (lonString[lonString.length - 1] === 'W') {
                        lon = (-1) * lon;
                    }

                    console.log(latString, " lat: ", lat, typeof lat);
                    console.log(lonString, " lon: ", lon, typeof lon);

                    if (reportType === "Damage") {
                        graphicOverlay.graphics.append(createGraphic(createMapPoint(lat, lon), damageSymbol, disasterType, reportType, reportDate));
                    } else if (reportType === "Request") {
                        graphicOverlay.graphics.append(createGraphic(createMapPoint(lat, lon), requestSymbol, disasterType, reportType, reportDate));
                    } else if (reportType === "Donation") {
                        graphicOverlay.graphics.append(createGraphic(createMapPoint(lat, lon), donateSymbol, disasterType, reportType, reportDate));
                    }
                }
                select_query.finish();

                db.query("END TRANSACTION")
            }

            function createMapPoint(lat, lon) {
                // Return a map point where the Esri headquarters is located.
                return ArcGISRuntimeEnvironment.createObject("Point", {
                                                                 x: lon,
                                                                 y: lat,
                                                                 spatialReference: Factory.SpatialReference.createWgs84()
                                                             });
            }

            function createGraphic(geometry, symbol, disasterType, reportType, reportDate) {
                const graphic = ArcGISRuntimeEnvironment.createObject("Graphic");
                graphic.geometry = geometry;
                graphic.symbol = symbol;
                graphic.attributes.insertAttribute("disasterType", disasterType);
                graphic.attributes.insertAttribute("reportType", reportType);
                graphic.attributes.insertAttribute("reportDate", reportDate);
                return graphic;
            }

            function initGeometry(){
                graphicOverlay.graphics.clear();
                if(captureType === "area"){
                    if(polygonBuilder === null || polygonBuilder === undefined) {
                        polygonBuilder = ArcGISRuntimeEnvironment.createObject("PolygonBuilder", {spatialReference: mapView.spatialReference, geometry: app.polygonObj});
                    }
                    var newGeometry1 = GeometryEngine.project(polygonBuilder.geometry, mapView.spatialReference);
                    var ring = newGeometry1.json.rings[0];
                    var ringLength = ring.length;
                    polygonBuilder = ArcGISRuntimeEnvironment.createObject("PolygonBuilder", {spatialReference: mapView.spatialReference});
                    var offset = (ring[0][0] === ring[1][0] && ring[0][1] === ring[1][1] && ring[1][0] === ring[2][0] && ring[1][1] === ring[2][1])? 2 : 1;
                    for(var i = 0; i< ringLength-offset; i++){
                        var ringPoint = ArcGISRuntimeEnvironment.createObject("Point", {x: ring[i][0], y:ring[i][1], spatialReference: mapView.spatialReference});
                        mapView.addPointToPolygon(ringPoint);
                        mapView.drawPoint(ringPoint);
                    }
                }

                if(captureType === "line"){
                    if(polylineBuilder === null || polylineBuilder === undefined) {
                        polylineBuilder = ArcGISRuntimeEnvironment.createObject("PolylineBuilder", {spatialReference: mapView.spatialReference, geometry: app.polylineObj});
                    }
                    var newGeometry2 = GeometryEngine.project(polylineBuilder.geometry, mapView.spatialReference);
                    var path = newGeometry2.json.paths[0];
                    var pathLength = path.length;
                    if(pathLength === 2 && storedReadyForGeo === false) pathLength = pathLength - 1;
                    polylineBuilder = ArcGISRuntimeEnvironment.createObject("PolylineBuilder", {spatialReference: mapView.spatialReference});
                    for(var j = 0; j< pathLength; j++){
                        var point = ArcGISRuntimeEnvironment.createObject("Point", {x: path[j][0], y:path[j][1], spatialReference: mapView.spatialReference});
                        mapView.addPointToPolyline(point);
                        mapView.drawPoint(point);
                    }
                }
            }

            function getDetailValue(){
                var detail
                var center = (mapView.currentViewpointCenter && mapView.currentViewpointCenter.center && mapView.map.loadStatus === Enums.LoadStatusLoaded) ?
                            CoordinateFormatter.toLatitudeLongitude(mapView.currentViewpointCenter.center, Enums.LatitudeLongitudeFormatDecimalDegrees, 3)
                          :qsTr("No Location Available.");
                if(captureType === "line"){
                    detail = (polylineBuilder && polylineBuilder.geometry)? Math.abs(GeometryEngine.lengthGeodetic(polylineBuilder.geometry, Enums.LinearUnitIdMeters, Enums.GeodeticCurveTypeGeodesic)):0;

                    if(polylineBuilder && polylineBuilder.parts.part(0) && polylineBuilder.parts.part(0).pointCount)
                        isUndoable = true;
                    else
                        isUndoable = false;
                    isReadyForGeo = (captureType === "line" && polylineBuilder.parts.part(0) && polylineBuilder.parts.part(0).pointCount>=2);
                    return detail;
                } else if(captureType === "area"){
                    detail = polygonBuilder.geometry? Math.abs(GeometryEngine.areaGeodetic(polygonBuilder.geometry, Enums.AreaUnitIdSquareMeters, Enums.GeodeticCurveTypeGeodesic)):0;
                    if(polygonBuilder.parts.part(0).pointCount) isUndoable = true;
                    else isUndoable = false;
                    isReadyForGeo = (captureType === "area" && polygonBuilder.parts.part(0) && polygonBuilder.parts.part(0).pointCount>=3);
                    return detail;
                }
                return center + ""
            }

            function drawPoint(point){
                var oldPointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: bluePointSymbol, geometry: point, zIndex: 2});
                var newPointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: redPointSymbol, geometry: point, zIndex: 3});
                var graphicsCount = graphicOverlay.graphics.count;
                if(graphicsCount>=3)graphicOverlay.graphics.remove(graphicsCount-1, 1);
                graphicOverlay.graphics.append(oldPointGraphic);
                graphicOverlay.graphics.append(newPointGraphic);
            }

            function addPointToPolyline(point){
                if(polylineBuilder.parts.empty || polylineBuilder.empty) {
                    var part = ArcGISRuntimeEnvironment.createObject("Part");
                    part.spatialReference = mapView.spatialReference;
                    var pCollection = ArcGISRuntimeEnvironment.createObject("PartCollection");
                    pCollection.spatialReference = mapView.spatialReference;
                    pCollection.addPart(part);
                    polylineBuilder.parts = pCollection;
                }
                point = GeometryEngine.project(point, polylineBuilder.spatialReference);

                positionSource.active = false
                var polylinePart = polylineBuilder.parts.part(0);

                polylinePart.addPoint(point);
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: simpleLineSymbol, geometry: polylineBuilder.geometry, zIndex: 1});
                graphicOverlay.graphics.remove(0, 1);
                graphicOverlay.graphics.insert(0, graphic);

                unitConverter.realValue = mapView.getDetailValue();
            }

            function undoPolyline(){
                var polylinePart = polylineBuilder.parts.part(0);
                polylinePart.removePoint(polylinePart.pointCount-1, 1);
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: simpleLineSymbol, geometry: polylineBuilder.geometry, zIndex: 1});
                graphicOverlay.graphics.remove(0, 1);
                graphicOverlay.graphics.insert(0, graphic);

                var previousPoint = graphicOverlay.graphics.get(graphicOverlay.graphics.count-3);
                var previousGeometry = previousPoint.geometry;
                var newPointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: redPointSymbol, geometry: previousGeometry, zIndex: 3});
                graphicOverlay.graphics.remove(graphicOverlay.graphics.count-1,1);
                graphicOverlay.graphics.remove(graphicOverlay.graphics.count-1,1);
                graphicOverlay.graphics.append(newPointGraphic);

                unitConverter.realValue = mapView.getDetailValue();
            }

            function addPointToPolygon(point){
                if(polygonBuilder.parts.empty) {
                    var part = ArcGISRuntimeEnvironment.createObject("Part");
                    part.spatialReference = mapView.spatialReference;
                    var pCollection = ArcGISRuntimeEnvironment.createObject("PartCollection");
                    pCollection.spatialReference = mapView.spatialReference;
                    pCollection.addPart(part);
                    polygonBuilder.parts = pCollection;
                }

                point = GeometryEngine.project(point, polygonBuilder.spatialReference);

                positionSource.active = false;
                var polygonPart = polygonBuilder.parts.part(0);

                polygonPart.addPoint(point);
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: simpleFillSymbol, geometry: polygonBuilder.geometry, zIndex: 1});
                graphicOverlay.graphics.remove(0, 1);
                graphicOverlay.graphics.insert(0, graphic);

                unitConverter.realValue = mapView.getDetailValue();
            }

            function undoPolygon(){
                var polygonPart = polygonBuilder.parts.part(0);
                polygonPart.removePoint(polygonPart.pointCount-1, 1);
                var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: simpleFillSymbol, geometry: polygonBuilder.geometry, zIndex: 1});
                graphicOverlay.graphics.remove(0, 1);
                graphicOverlay.graphics.insert(0, graphic);

                var previousPoint = graphicOverlay.graphics.get(graphicOverlay.graphics.count-3);
                var previousGeometry = previousPoint.geometry;
                var newPointGraphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: redPointSymbol, geometry: previousGeometry, zIndex: 3});
                graphicOverlay.graphics.remove(graphicOverlay.graphics.count-1,1);
                graphicOverlay.graphics.remove(graphicOverlay.graphics.count-1,1);
                graphicOverlay.graphics.append(newPointGraphic);

                unitConverter.realValue = mapView.getDetailValue();
            }

            function clearGraphics(){
                if(app.captureType === "line") polylineBuilder.parts.removeAll();
                else if(app.captureType === "area") polygonBuilder.parts.removeAll();
                graphicOverlay.graphics.clear();

                unitConverter.realValue = 0;
                isReadyForGeo = false;
                isUndoable = false;
            }

            Image {
                source: "../images/esri_pin_red.png"
                width: 20 * app.scaleFactor
                height: 40 * app.scaleFactor
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.verticalCenter
                }
                //visible: app.captureType === "point" && mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded
                visible: false
            }

            BusyIndicator {
                visible: app.mmpkManager.loadStatus === 1
                running: visible
                anchors.bottom: offlineSwitchButton.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                Material.accent: app.headerBackgroundColor
            }

            Button{
                id: offlineSwitchButton
                visible: app.offlineMMPKID>"" && (app.settings.value("token", "")>"" || app.mmpkManager.isPubished) && app.mmpkManager.loadStatus != 1 && enabled && AppFramework.network.isOnline
                text: isOfflineMap? qsTr("Go Online") : (mmpkManager.offlineMapExist ? ("\u2713 " + qsTr("Go Offline")) : qsTr("Go Offline"))
                Material.background: "white"
                Material.foreground: mmpkManager.offlineMapExist ? "#424242" : Qt.darker("darkgrey", 1.2)
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: app.subtitleFontSize
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 32*app.scaleFactor

                onClicked: {
                    queryLocationPage.currentExt = mapView.currentViewpointExtent.extent;
                    if(!isOfflineMap){
                        if(mmpkManager.offlineMapExist){
                            if(mmpk.loadStatus === Enums.LoadStatusLoaded) {
                                mapView.map = mmpk.maps[0];
                                mapView.setViewpointGeometry(queryLocationPage.currentExt)
                            } else {
                                mmpk.load();
                            }
                            isOfflineMap = true;
                        } else {
                            if(app.mmpkSecureFlag) {

                                if(networkConfig.isWIFI || networkConfig.isLAN) {
                                    downloadMMPK();
                                } else {
                                    downloadMMPKDialog.visible = true;
                                }
                            }
                        }
                    } else {
                        if(app.isOnline){
                            // reloadMapTimer.start();
                            isOfflineMap = false;
                        }
                    }
                }
            }

            Item {
                id: pane
                width: (isMini && !isFullMap)? 40*app.scaleFactor:(parent.width-32*app.scaleFactor)
                height: searchBar.height
                anchors.right: parent.right
                anchors.rightMargin: 16*app.scaleFactor
                anchors.top: parent.top
                anchors.topMargin: 8*app.scaleFactor
                clip: true
                visible:  mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded && app.isOnline
                property bool isMini: true
                z: toolsContainer.z+1

                Behavior on width{
                    NumberAnimation {duration: 200}
                }

                ColumnLayout{
                    id: searchBar
                    width: parent.width
                    spacing: 0

                    Rectangle{
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40*app.scaleFactor
                        border.color: "darkgrey"
                        radius: Layout.preferredHeight/2
                        clip: true
                        RowLayout{
                            anchors.fill: parent
                            spacing: 0

                            Rectangle{
                                color: "transparent"
                                Layout.preferredHeight: parent.height
                                Layout.preferredWidth: parent.height
                                radius: parent.height/2
                                clip: true
                                visible: mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded
                                Image {
                                    id: searchImage
                                    width: parent.width*0.7
                                    height: parent.height*0.7
                                    anchors.centerIn: parent
                                    source: !pane.isMini && !isFullMap? "../images/ic_keyboard_arrow_left_black_48dp.png":"../images/ic_search_black_48dp.png"
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                }
                                ColorOverlay{
                                    anchors.fill: searchImage
                                    source: searchImage
                                    color: "darkgrey"
                                }
                                MouseArea{
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if(!isFullMap){
                                            if(pane.isMini){
                                                searchTextField.clear();
                                                pane.isMini = false;
                                            } else {
                                                pane.isMini = true;
                                            }
                                        }
                                    }
                                }
                            }

                            TextField {
                                id: searchTextField
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                Material.accent: "#80000000"
                                focusReason: Qt.PopupFocusReason
                                font.pixelSize: 16*app.scaleFactor
                                bottomPadding: topPadding
                                rightPadding: 2*app.scaleFactor
                                leftPadding: rightPadding
                                placeholderText: hintForGeoSearch
                                background: Rectangle {
                                    color: "transparent"
                                    border.color: "transparent"
                                }
                                onAccepted: {
                                    focus = false;
                                    mapView.geocodeAddress();
                                    pane.isMini = true;
                                }
                                onFocusChanged: {
                                    if(!focus){
                                        Qt.inputMethod.hide();
                                    }
                                }
                            }

                            Rectangle{
                                color: "transparent"
                                Layout.preferredHeight: parent.height
                                Layout.preferredWidth: parent.height
                                radius: parent.height/2
                                clip: true
                                visible: searchTextField.text>""
                                Image {
                                    id: clearTextImage
                                    width: parent.width*0.7
                                    height: parent.height*0.7
                                    anchors.centerIn: parent
                                    source: "../images/ic_close_black_48dp.png"
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                }
                                ColorOverlay{
                                    anchors.fill: clearTextImage
                                    source: clearTextImage
                                    color: "darkgrey"
                                }
                                MouseArea{
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if(searchTextField.text>"") {
                                            searchTextField.clear();
                                            pane.isMini = false;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle{
                        Layout.preferredWidth: parent.width-2*app.scaleFactor
                        Layout.preferredHeight: 160*app.scaleFactor
                        Layout.alignment: Qt.AlignHCenter
                        clip: true
                        border.color: "darkgrey"
                        radius: 10*app.scaleFactor
                        visible: locatorTask.suggestions.count>0 && searchTextField.focus && (!pane.isMini || isFullMap)

                        ListView{
                            id: searchResultListView
                            anchors.fill: parent
                            clip: true
                            model: locatorTask.suggestions
                            delegate: Label{
                                width: parent.width
                                height: 40*app.scaleFactor
                                verticalAlignment: Label.AlignVCenter
                                elide: Label.ElideRight
                                clip: true
                                leftPadding: 40*app.scaleFactor
                                rightPadding: 40*app.scaleFactor
                                font.pixelSize: 16*app.scaleFactor
                                text: locatorTask.suggestions? locatorTask.suggestions.get(index).label : ""
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked: {
                                        searchTextField.text = locatorTask.suggestions.get(index).label;
                                        searchTextField.focus = false;
                                        mapView.geocodeAddress();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item{
                id: toolsContainer
                width: 40*app.scaleFactor
                height: parent.height - 100*app.scaleFactor
                anchors.top: parent.top
                anchors.topMargin: isFullMap? 120*app.scaleFactor : 80*app.scaleFactor
                anchors.right: parent.right
                anchors.rightMargin: 16*app.scaleFactor
                ColumnLayout{
                    anchors.fill: parent
                    spacing: 4*app.scaleFactor
                    Rectangle{
                        id:bookmark
                        color: "white"
                        Layout.preferredHeight: parent.width
                        Layout.fillWidth: true
                        radius: parent.width/2
                        border.color: "darkgrey"
                        visible: mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded && mapView.map.bookmarks && mapView.map.bookmarks.count>0 && !(app.captureType!="point" && isUndoable)
                        Image {
                            id: bookmarkIcon
                            width: parent.width*0.7
                            height: width
                            anchors.centerIn: parent
                            source: "../images/bookmark.png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                        ColorOverlay{
                            anchors.fill: bookmarkIcon
                            source: bookmarkIcon
                            color: "darkgrey"
                        }
                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked:{

                                if(!menuloaded)
                                {
                                    mapView.map.bookmarks.forEach(function(bkmark){
                                        contextMenu.addItem(menuItem.createObject(contextMenu,{text:bkmark.name} ))
                                    })
                                    menuloaded = true
                                }
                                contextMenu.popup(-120,30)

                            }

                            Menu{
                                id:contextMenu
                                Material.accent: Material.Grey


                                background: Rectangle{
                                    implicitWidth: 175 * scaleFactor


                                }
                                Component{
                                    id:menuItem
                                    MenuItem{
                                        id:root

                                        checkable: true

                                        onTriggered:{
                                            uncheckItems(checked,text)

                                            if(visible) {
                                                mapView.locationDisplay.stop();
                                                mapView.map.bookmarks.forEach(function(bookmark){
                                                    if(bookmark.name === text)
                                                    {
                                                        mapView.setViewpointWithAnimationCurve(bookmark.viewpoint, 2.0, Enums.AnimationCurveEaseInOutCubic);

                                                    }
                                                }
                                                )

                                            }
                                        }

                                        height: 30 * scaleFactor
                                        font.pixelSize: 12* scaleFactor
                                        leftPadding: 10 * scaleFactor


                                    }
                                }
                            }



                        }
                    }



                    Rectangle{
                        color: "white"
                        Layout.preferredHeight: parent.width
                        Layout.fillWidth: true
                        radius: parent.width/2
                        border.color: "darkgrey"
                        visible: mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded
                        Image {
                            id: homeImage
                            width: parent.width*0.7
                            height: parent.height*0.7
                            anchors.centerIn: parent
                            source: mapView.mapRotation == mapView.initialMapRotation? "../images/ic_home_black_48dp.png":"../images/compass.png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                        ColorOverlay{
                            anchors.fill: homeImage
                            source: homeImage
                            color: "darkgrey"
                        }
                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                mapView.locationDisplay.stop();
                                if(mapView.mapRotation == mapView.initialMapRotation) mapView.setViewpointWithAnimationCurve(mapView.map.initialViewpoint, 2.0, Enums.AnimationCurveEaseInOutCubic)
                                else mapView.setViewpointRotation(mapView.initialMapRotation)
                            }
                        }
                    }

                    Rectangle{
                        color: "white"
                        Layout.preferredHeight: parent.width
                        Layout.fillWidth: true
                        radius: parent.width/2
                        border.color: "darkgrey"
                        visible: mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded && !(app.captureType!="point" && isUndoable)
                        Image {
                            id: currentLocationImage
                            width: parent.width*0.7
                            height: parent.height*0.7
                            anchors.centerIn: parent
                            source: "../images/ic_my_location_black_48dp.png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                        ColorOverlay{
                            anchors.fill: currentLocationImage
                            source: currentLocationImage
                            color: mapView.locationDisplay.started ? "steelBlue":"darkgrey"
                        }
                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (Qt.platform.os === "ios" || Qt.platform.os === "android"){
                                    if(Permission.checkPermission(Permission.PermissionTypeLocationWhenInUse) === Permission.PermissionResultGranted)
                                    {
                                        if (!mapView.locationDisplay.started) {
                                            mapView.locationDisplay.start();
                                            mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter;
                                        } else {
                                            mapView.locationDisplay.stop();
                                        }
                                    }
                                    else
                                    {
                                        permissionDialog.permission = PermissionDialog.PermissionDialogTypeLocationWhenInUse;
                                        permissionDialog.open()
                                    }
                                }
                                else
                                {
                                    if (!mapView.locationDisplay.started) {
                                        mapView.locationDisplay.start();
                                        mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter;
                                    } else {
                                        mapView.locationDisplay.stop();
                                    }
                                }
                            }
                        }
                    }
                    PermissionDialog {
                        id:permissionDialog
                        openSettingsWhenDenied: true

                        onRejected:{


                        }
                        onAccepted:{

                        }


                    }

                    Rectangle{
                        color: "white"
                        Layout.preferredHeight: parent.width
                        Layout.fillWidth: true
                        radius: parent.width/2
                        border.color: "darkgrey"
                        visible: mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded && app.captureType!="point" && isUndoable
                        Image {
                            id: undoImage
                            width: parent.width*0.7
                            height: parent.height*0.7
                            anchors.centerIn: parent
                            source: "../images/ic_undo_black_48dp.png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                        ColorOverlay{
                            anchors.fill: undoImage
                            source: undoImage
                            color: "darkgrey"
                        }
                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if(app.captureType === "line") mapView.undoPolyline();
                                else if(app.captureType === "area") mapView.undoPolygon();
                            }
                        }
                    }

                    Rectangle{
                        color: "white"
                        Layout.preferredHeight: parent.width
                        Layout.fillWidth: true
                        radius: parent.width/2
                        border.color: "darkgrey"
                        visible: mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded && app.captureType!="point" && isUndoable
                        Image {
                            id: clearImage
                            width: parent.width*0.7
                            height: parent.height*0.7
                            anchors.centerIn: parent
                            source: "../images/ic_delete_forever_black_48dp.png"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                        ColorOverlay{
                            anchors.fill: clearImage
                            source: clearImage
                            color: "darkgrey"
                        }
                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                mapView.clearGraphics();
                            }
                        }
                    }

                    Item{
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle{
                color: "white"
                width: 40*app.scaleFactor
                height: width
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 32*app.scaleFactor
                anchors.right: parent.right
                anchors.rightMargin: 16*app.scaleFactor
                radius: parent.width/2
                border.color: "darkgrey"
                visible: mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded
                Image {
                    id: fullscreenImage
                    width: parent.width*0.7
                    height: parent.height*0.7
                    anchors.centerIn: parent
                    source: isFullMap? "../images/ic_fullscreen_exit_black_48dp.png":"../images/ic_fullscreen_black_48dp.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
                ColorOverlay{
                    anchors.fill: fullscreenImage
                    source: fullscreenImage
                    color: "darkgrey"
                }
                MouseArea{
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        isFullMap = !isFullMap
                    }
                }
            }

            Rectangle {
                id: locationAccuracy

                property string distanceUnit: Qt.locale().measurementSystem === Locale.MetricSystem ? "m" : "ft"
                property real accuracy: Qt.locale().measurementSystem === Locale.MetricSystem ? positionSource.position.horizontalAccuracy : 3.28084 * positionSource.position.horizontalAccuracy
                property real threshold: Qt.locale().measurementSystem === Locale.MetricSystem ? (50/3.28084) : 50

                visible:positionSource.active && positionSource.position.horizontalAccuracyValid && app.captureType==="point"

                width: app.units(80)
                height: width/3
                radius: app.units(4)
                color: "white"
                clip: true

                anchors {
                    bottom: mapView.bottom
                    left: mapView.left
                    leftMargin: app.units(4)
                    bottomMargin: app.units(4)
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: app.units(4)

                    Rectangle {
                        Layout.preferredWidth: parent.width
                        Layout.preferredHeight: parent.height
                        radius: app.units(4)
                        clip: true
                        color: locationAccuracy.accuracy <= locationAccuracy.threshold ? "green" : "red"

                        Text {
                            anchors.centerIn: parent
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: "white"
                            text: "± %1 %2".arg(locationAccuracy.accuracy.toFixed(1)).arg(locationAccuracy.distanceUnit)
                            fontSizeMode: Text.HorizontalFit
                            font.pixelSize: app.textFontSize
                            font.family: app.customTextFont.name
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    enabled: app.captureType === "point"
                    onClicked: {
                        page3_mapView.map.panTo(page3_mapView.map.positionDisplay.mapPoint)
                    }
                }
            }

            Rectangle{
                id: refreshButton
                width: 48*app.scaleFactor
                height: 48*app.scaleFactor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: -48*app.scaleFactor
                color: "lightgrey"
                opacity: 0.8
                radius: 4*app.scaleFactor
                border.color: "lightgrey"
                border.width: 1
                visible: (!app.isOnline && !isOfflineMap && mapView.map.loadStatus !== Enums.LoadStatusLoaded) || (!isOfflineMap && mapView.map && mapView.map.loadStatus > 1)
                Image{
                    id: mapRefreshImage
                    anchors.fill: parent
                    anchors.margins: 8*app.scaleFactor
                    source: "../images/ic_refresh_black_48dp.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
                ColorOverlay{
                    anchors.fill: mapRefreshImage
                    source: mapRefreshImage
                    color: "darkgrey"
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        var webMapUrl = app.webMapRootUrl + app.webMapID;
                        var newMap = ArcGISRuntimeEnvironment.createObject("Map", {initUrl: webMapUrl});
                        mapView.map = newMap;
                    }
                }
            }

            Label{
                anchors.top: refreshButton.bottom
                anchors.topMargin: 8*app.scaleFactor
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                color: "#565656"
                maximumLineCount: 2
                font.pixelSize: app.subtitleFontSize
                font.family: app.customTextFont.name
                wrapMode: Text.Wrap
                text: qsTr("Map is not available offline.\nClick to refresh.")
                width: Math.min(280*app.scaleFactor, parent.width*0.6)
                visible: refreshButton.visible
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        var webMapUrl = app.webMapRootUrl + app.webMapID;
                        var newMap = ArcGISRuntimeEnvironment.createObject("Map", {initUrl: webMapUrl});
                        mapView.map = newMap;
                    }
                }
            }

            // add a filter to the map from DRAFTS database, 2021-12-10
            Row {
                id: findRow

                anchors {
                    top: parent.top
                    bottom: mapView.top
                    left: parent.left
                    right: parent.right
                    margins: 10 * scaleFactor
                }
                spacing: 5

                // customize ComboBox
                ComboBox {
                    id: comboBox

                    Material.background: app.headerBackgroundColor

                    currentIndex: 0
                    model: ListModel {
                        id: cbItems

                        ListElement {
                            text: "Filter by disaster"
                        }

                        ListElement {
                            text: "Hurricane"
                        }
                        ListElement {
                            text: "Flood"

                        }
                        ListElement {
                            text: "Storm"
                        }
                        ListElement {
                            text: "Landslide"

                        }
                    }

                    contentItem: Text {

                        leftPadding: comboBox.indicator.width
                        rightPadding: comboBox.indicator.width + comboBox.spacing

                        text: comboBox.displayText
                        font: comboBox.font
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    font: {
                        pixelSize: app.textFontSize
                        family: app.customTextFont.name
                    }

                    indicator: Canvas {
                        id: indCanvas
                        x: comboBox.width - width - comboBox.rightPadding
                        y: comboBox.topPadding + (comboBox.availableHeight - height) / 2
                        width: 12
                        height: 8
                        contextType: "2d"

                        onPaint: {
                            context.reset();
                            context.moveTo(0, 0);
                            context.lineTo(width, 0);
                            context.lineTo(width / 2, height);
                            context.closePath();
                            context.fillStyle = "white"
                            context.fill();
                        }
                    }

                    width: 200

                    enabled: featureTable.loadStatus === Enums.LoadStatusLoaded
                    onCurrentIndexChanged:{
                        console.debug(cbItems.get(currentIndex).text);
                        if (currentIndex != 0) {
                            featureLayer.definitionExpression = "DisasterType LIKE '" + cbItems.get(currentIndex).text + "%'";
                            //mapView.updateQueryReportsData(cbItems.get(currentIndex).text);
                        } else {
                            //mapView.updateQueryReportsData();
                            featureLayer.definitionExpression = "";
                        }
                    }
                }

                // reset button
                Button {
                    Material.background: app.headerBackgroundColor
                    Material.accent:app.black_87
                    highlighted: true
                    text: "Reset"
                    enabled: featureTable.loadStatus === Enums.LoadStatusLoaded
                    onClicked: {
                        featureLayer.definitionExpression = "";
                        // mapView.updateQueryReportsData();
                        comboBox.currentIndex = 0;
                    }
                }
            }

        }

        // function to form and execute the query
        function query() {
            // set the where clause
            params.whereClause = "DisasterType LIKE '" + findText.text + "%'";

            // start the query
            featureTable.queryFeatures(params);

            featureLayer.definitionExpression = params.whereClause;
        }

        Item{
            Layout.fillWidth: true
            Layout.preferredHeight: 8*app.scaleFactor
        }

        Text {
            id: page3_geoDetailText
            textFormat: Text.StyledText
            Layout.preferredWidth: parent.width
            Layout.maximumWidth: 600 * app.scaleFactor
            font.pixelSize: app.textFontSize
            font.family: app.customTextFont.name
            color: app.textColor
            maximumLineCount: 1
            text: mapView.getDetailValue()
            elide: Text.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            fontSizeMode: Text.Fit
            visible: false //app.captureType === "point"
        }

        ComboBox{
            id: unitConverter
            property real realValue: -1

            Layout.preferredHeight: 50 * scaleFactor
            Layout.preferredWidth: parent.width * 0.6
            Layout.maximumWidth: 420*app.scaleFactor
            Layout.alignment: Qt.AlignHCenter
            //defaultMargin: defaultMargin
            visible: false // !page3_geoDetailText.visible
            model: unitConvertModel
            Material.accent: app.headerBackgroundColor
            contentItem:Text {
                text:unitConverter.displayText
                color: app.black_87
                font:unitConverter.font
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            indicator: Canvas {
                id: canvas
                x: unitConverter.width - width - unitConverter.rightPadding
                y: unitConverter.topPadding + (unitConverter.availableHeight - height) / 2
                width: 12
                height: 8
                contextType: "2d"


                Connections {
                    target: unitConverter
                    onPressedChanged: canvas.requestPaint()
                }

                onPaint: {
                    unitConverter.popup.y = isFullMap ? 40:20
                    context.reset();

                    context.moveTo(0, 0);
                    context.lineTo(width, 0);
                    context.lineTo(width / 2, height);
                    context.closePath();
                    context.fillStyle = app.black_87;
                    context.fill();
                }
            }

            currentIndex: 0

            popup.contentItem.implicitHeight:Math.min(250,unitConvertModel.count * 30)

            background: Rectangle {
                id: rectCategory
                width: unitConverter.width
                height: unitConverter.height
                color: app.pageBackgroundColor

                radius: 5*app.scaleFactor

            }

            onRealValueChanged: {

                unitConvertModel.clear();
                if(app.captureType==="line"){
                    unitConvertModel.append({text: qsTr("%1 Meters").arg(realValue<1000000? realValue.toFixed(0):realValue.toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Miles").arg((realValue*0.000621371)<1000000?(realValue*0.000621371).toFixed(2): (realValue*0.000621371).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Kilometers").arg((realValue*0.001)<10000000? (realValue*0.001).toFixed(2):(realValue*0.001).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Feet").arg((realValue*3.28084)<1000000?(realValue*3.28084).toFixed(0):(realValue*3.28084).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Feet (US)").arg((realValue*3.28083)<1000000?(realValue*3.28083).toFixed(0):(realValue*3.28083).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Yards").arg((realValue*1.09361)<1000000?(realValue*1.09361).toFixed(1):(realValue*1.09361).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Nautical Miles").arg((realValue*0.000539957)<1000000?(realValue*0.000539957).toFixed(1):(realValue*0.000539957).toExponential(3))})
                } else if(app.captureType==="area"){
                    unitConvertModel.append({text: qsTr("%1 Sq Meters").arg(realValue<1000000? realValue.toFixed(0):realValue.toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Acres").arg((realValue/4046.86)<1000000?(realValue/4046.86).toFixed(1):(realValue/4046.86).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Sq Miles").arg((realValue/2589990)<1000000?(realValue/2589990).toFixed(2):(realValue/2589990).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Sq Kilometers").arg((realValue/1000000)<1000000?(realValue/1000000).toFixed(2):(realValue/1000000).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Hectares").arg((realValue/10000)<1000000?(realValue/10000).toFixed(1):(realValue/10000).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Sq Yards").arg((realValue/0.836128)<1000000?(realValue/0.836128).toFixed(1):(realValue/0.836128).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Sq Feet").arg((realValue/0.092903)<1000000?(realValue/0.092903).toFixed(1):(realValue/0.092903).toExponential(3))})
                    unitConvertModel.append({text: qsTr("%1 Sq Feet (US)").arg((realValue*10.7638)<1000000?(realValue*10.7638).toFixed(1):(realValue*10.7638).toExponential(3))})
                }

                unitConverter.currentIndex = 0
            }

            Component.onCompleted: {
                realValue = app.measureValue>0? app.measureValue:0;

            }

            ListModel{
                id: unitConvertModel
            }
        }

        Item{
            Layout.fillWidth: true
            Layout.preferredHeight: 16*app.scaleFactor
            visible: !isFullMap
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: isIPhoneX ? 20 * app.scaleFactor : 0
            visible: isFullMap
        }
    }

    DropShadow {
        source: createPage_headerBar
        width: source.width
        height: source.height
        cached: false
        radius: 5.0
        samples: 16
        color: "#80000000"
        smooth: true
        visible: source.visible
    }

    ConfirmBox{
        id: invalidGeometryAlertBox
        anchors.fill: parent
        standardButtons: StandardButton.Yes | StandardButton.No
        onAccepted: {
            // nextPage();
        }
    }

    ConfirmBox{
        id: confirmToSubmit
        anchors.fill: parent
        standardButtons: StandardButton.Yes | StandardButton.No
        text: app.titleForSubmitInDraft
        informativeText: app.messageForSubmitInDraft
        onAccepted: {
            positionSource.active = false;
            if(app.captureType==="line"){
                app.polylineObj = polylineBuilder.geometry;
                app.measureValue = unitConverter.realValue;
            } else if(app.captureType === "area"){
                app.polygonObj = polygonBuilder.geometry;
                app.measureValue = unitConverter.realValue;
            }

            if(mapView.map.loadStatus != Enums.LoadStatusLoaded){
                app.centerExtent = mapView.currentViewpointExtent.extent.extent;
            }
            app.submitReport();
        }
    }

    function processInput()
    {
        if(app.captureType==="line"){
            if(mapView.currentViewpointCenter.center) {
                app.polylineObj = polylineBuilder.geometry;
                app.measureValue = unitConverter.realValue;
            } else {
                if(!app.isFromSaved) {
                    if(polylineBuilder!== undefined)app.polylineObj = GeometryEngine.project(polylineBuilder.geometry, SpatialReference.createWgs84());
                    else {
                        var tempPolylineBuilder = ArcGISRuntimeEnvironment.createObject("PolylineBuilder", {spatialReference: mapView.spatialReference, geometry: app.polylineObj});
                        app.polylineObj = GeometryEngine.project(tempPolylineBuilder.geometry, SpatialReference.createWgs84());
                    }
                }
                app.measureValue = unitConverter.realValue;
            }
        } else if(app.captureType === "area"){
            if(mapView.currentViewpointCenter.center) {
                app.polygonObj = polygonBuilder.geometry;
                app.measureValue = unitConverter.realValue;
            } else {
                if(!app.isFromSaved) {
                    if(polygonBuilder!== undefined) app.polygonObj = GeometryEngine.project(polygonBuilder.geometry, SpatialReference.createWgs84());
                    else {
                        var tempPolygonBuilder = ArcGISRuntimeEnvironment.createObject("PolygonBuilder", {spatialReference: mapView.spatialReference, geometry: app.polygonObj});
                        app.polygonObj = GeometryEngine.project(tempPolygonBuilder.geometry, SpatialReference.createWgs84());
                    }
                }
                app.measureValue = unitConverter.realValue;
            }
        } else {
            if(mapView.currentViewpointCenter.center) {
                app.theNewPoint = mapView.currentViewpointCenter.center;
            } else {
                app.theNewPoint = ArcGISRuntimeEnvironment.createObject("Point", {x: positionSource.position.coordinate.longitude, y: positionSource.position.coordinate.latitude, spatialReference: SpatialReference.createWgs84()});
            }
        }

        if(mapView.map && mapView.map.loadStatus === Enums.LoadStatusLoaded){
            app.centerExtent = GeometryEngine.project(mapView.currentViewpointExtent.extent.extent, mapView.spatialReference);
        }

        positionSource.active = false;
        app.locationDisplayText = unitConverter.displayText || page3_geoDetailText.text
    }

    Connections{
        target: AppFramework.network
        onOnlineStateChanged: {
            if(isOnline) {
                if(!app.mmpkManager.offlineMapExist) {
                    var webMapUrl = app.webMapRootUrl + app.webMapID;
                    var newMap = ArcGISRuntimeEnvironment.createObject("Map", {initUrl: webMapUrl});
                    mapView.map = newMap;

                    mapView.initGeometry();
                    //mapView.updateQueryReportsData();

                    isOfflineMap = false;
                }
            } else {
                if(app.mmpkManager.offlineMapExist) offlineSwitchButton.clicked();
            }
        }
    }

    //================================================================================

    ConfirmBox{
        id: downloadMMPKDialog
        anchors.fill: parent
        text: qsTr("Use your cellular data to download the offline map?")
        onAccepted: {
            downloadMMPK();
        }
    }

    function downloadMMPK(){
        offlineSwitchButton.enabled = false;
        app.mmpkManager.downloadOfflineMap(function(){
            try {
                offlineSwitchButton.enabled = true;
                offlineSwitchButton.clicked();
            } catch (e) {
                console.log(e)
            }
        });
    }

    //================================================================================


    Keys.onReleased: {
        if (event.key === Qt.Key_Back) {
            back()
            event.accepted = true;
        }
    }

    function back(){
        app.locationDisplayText = unitConverter.displayText || page3_geoDetailText.text
        if(invalidGeometryAlertBox.visible){
            invalidGeometryAlertBox.visible = false;
        } else if(webPage !== null && webPage !== undefined && webPage.visible === true){
            webPage.close();
            app.focus = true;
        } else {
            processInput()
            app.populateSummaryObject()
            skipPressed = false;
            positionSource.active = false;

            previous("");
        }
    }

    function uncheckItems(checked,text)
    {

        var noofItems = contextMenu.count
        if(checked)
        {
            for(var k=0;k<noofItems;k++)
            {
                var menuitem = contextMenu.itemAt(k)
                if(menuitem.text !== text)
                    menuitem.checked = false
            }
        }


    }
}
