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
import QtPositioning 5.8
import QtQuick.LocalStorage 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Material 2.1 as MaterialStyle
import QtMultimedia 5.8

import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.Multimedia 1.0
import ArcGIS.AppFramework.Notifications 1.0
import ArcGIS.AppFramework.WebView 1.0
import ArcGIS.AppFramework 1.0

import Esri.ArcGISRuntime 100.10
import ArcGIS.AppFramework.Sql 1.0
import ArcGIS.AppFramework.Platform 1.0


import "controls"
import "pages"
import QtQuick.Controls.Material 2.1



App {
    id: app
    width: 421
    height: 750

    function units(value) {
        return AppFramework.displayScaleFactor * value
    }

    property real scaleFactor: AppFramework.displayScaleFactor

    property bool isSmallScreen: (width || height) < units(550) || (AppFramework.systemInformation.family === "phone")
    property bool isPortrait: app.height > app.width
    property real maximumScreenWidth: app.width > 1000 * scaleFactor ? 800 * scaleFactor : 568 * scaleFactor
    property bool isIPhoneX: false

    property bool featureServiceInfoComplete : false
    property bool featureServiceInfoErrored : false
    property bool initializationCompleted: true

    property int steps: -1
    property int savedReportsCount: 0
    property string token: ""
    property var expiration
    property string webMapRootUrl: "http://www.arcgis.com/home/item.html?id="

    //check ready for submitting for saved draftSaveDialog:
    property bool isReadyForAttachments: false
    property bool isReadyForGeo: false
    property bool isReadyForDetails: false
    property bool isReadyForSubType: true
    property bool isReadyForSubmitReport: isReadyForAttachments && isReadyForGeo && isReadyForDetails && isReadyForSubType
    property bool useGlobalIDForEditing:false
    readonly property string theme: qsTr("Theme")
    property string defaultTheme:app.settings.value("appDefaultTheme",app.automatic)
    readonly property string automatic: qsTr("Automatic")
    property color blk_140: app.isDarkMode ? "#BFBFBF" : "#6A6A6A"
    readonly property string light: qsTr("Light")
    readonly property string dark: qsTr("Dark")
    readonly property url theme_select:"./images/done-48px.png"


    // Animation on AboutPage
    readonly property int normalDuration: 250

    function updateSavedReportsCount() {
        var count = 0;
        var queryString = "SELECT COUNT(*) AS TOTAL FROM DRAFTS;";

        db.query("BEGIN TRANSACTION")
        var select_query = db.query(queryString)
        for(var ok = select_query.first(); ok; ok = select_query.next()) {
            var rs = select_query.values;

            count = rs.TOTAL

            savedReportsCount = count;

        }
        db.query("END TRANSACTION");
    }

    property bool isOnline: Networking.isOnline
    property bool isRealOnline: false
    property int configurationState

    // special flag for mmpk
    property bool mmpkSecureFlag: true

    Connections {
        target: Platform
        onSystemThemeChanged: {
            console.error("ThemeChanged current: ", Platform.systemTheme.mode);
            if(app.defaultTheme === app.automatic)
            {
                if (Platform.systemTheme.mode === SystemTheme.Dark) {
                    app.isDarkMode = true
                    app.settings.setValue("isDarkMode", app.isDarkMode);
                } else if (Platform.systemTheme.mode === SystemTheme.Light) {
                    app.isDarkMode = false
                    app.settings.setValue("isDarkMode", app.isDarkMode);
                }
            }

        }
    }

    Connections {
        target: AppFramework.network

        onConfigurationChanged:{
            app.configurationState = configuration.state
        }
    }

    onIsOnlineChanged: {
        if (isOnline && featureServiceInfoErrored){
            serviceInfoTask.fetchFeatureServiceInfo()
            featureServiceInfoErrored = false
        }
    }

    property string deviceOS: Qt.platform.os

    /* *********** CONFIG ********************* */
    property string arcGISLicenseString: app.info.propertyValue("ArcGISLicenseString","");

    //assets
    property string appLogoImageUrl: app.folder.fileUrl(app.info.propertyValue("logoImage", "template/images/esrilogo.png"))
    property string landingPageBackgroundImageURL: app.folder.fileUrl(app.info.propertyValue("startBackground", ""))
    property bool showDescriptionOnStartup : app.info.propertyValue("showDescriptionOnStartup",false);
    property bool startShowLogo : app.info.propertyValue("startShowLogo",true);
    property string loginImage : app.info.propertyValue("startButton","../images/signin.png");
    property string pickListCaption: app.info.propertyValue("pickListCaption", "Pick a type");
    property bool showAlbum: app.info.propertyValue("showAlbum", false);
    property bool showFileAttachment: app.info.propertyValue("enableSelectFiles", true);
    property bool supportVideoRecorder: app.info.propertyValue("supportVideoRecorder", false);
    property bool supportAudioRecorder: app.info.propertyValue("supportAudioRecorder", false);
    property bool supportMedia: Qt.platform.os != "windows" && app.supportVideoRecorder

    // fonts
    property int baseFontSize:app.info.propertyValue("baseFontSize", 20)
    property string customTitleFontTTF: app.info.propertyValue("customTitleFontTTF","");
    property string customTextFontTTF: app.info.propertyValue("customTextFontTTF","")

    property alias baseFontFamily: customTextFont.name
    property alias titleFontFamily: customTitleFont.name

    property int headingFontSize: 1.8 * titleFontSize
    property int titleFontSize: baseFontSize * scaleFactor * fontScale
    property int subtitleFontSize: 0.7 * titleFontSize
    property int popupFontSize: 0.7 * titleFontSize
    property int textFontSize: 0.8 * titleFontSize
    property real fontScale: app.settings.value("fontScale", 1.0);
    property int isDarkMode: app.settings.value("isDarkMode", 0);
    property bool isSortDomainByAlphabetical: app.info.propertyValue("sortDomainByAlphabetical", false);
    property string payloadUrl:app.info.propertyValue("payloadUrl", "");
    property bool isTablet: (Math.max(app.width, app.height) > 1000 * scaleFactor) || (AppFramework.systemInformation.family === "tablet")
    property bool showSummary:true//app.info.propertyValue("showSummary",true)


    //custom font if any
    property alias customTitleFont: customTitleFont
    FontLoader {
        id: customTitleFont
        source: app.folder.fileUrl(customTitleFontTTF)
    }

    property alias customTextFont: customTextFont
    FontLoader {
        id: customTextFont
        source: app.folder.fileUrl(customTextFontTTF)
    }

    //colors
    property color headerBackgroundColor: /*app.isDarkMode? "#6e6e6e":*/app.info.propertyValue("headerBackgroundColor","#00897b");
    property color headerTextColor: app.isDarkMode? "white": app.info.propertyValue("headerTextColor","white");
    property color pageBackgroundColor: app.isDarkMode? "#404040":app.info.propertyValue("pageBackgroundColor","#EBEBEB");
    property color buttonColor: /*isDarkMode? "#969696":*/ app.info.propertyValue("buttonColor","orange");
    property color textColor: app.isDarkMode? "white": app.info.propertyValue("textColor","white");
    property color titleColor: app.isDarkMode? "white": app.info.propertyValue("titleColor","white");
    property color subtitleColor: app.isDarkMode? "white": app.info.propertyValue("subtitleColor","#4C4C4C");
    property color headerHighlightTextColor: app.isDarkMode? "white": "#0000FF";

    //report types
    property var disasterTypeId: []
    property var disasterTypeIdString: app.info.propertyValue("disasterTypeId","")

    //report types
    property var reportTypeId: []
    property var reportTypeIdString: app.info.propertyValue("reportTypeId","")

    //damage types
    property var damageTypeId: []
    property var damageTypeIdString: app.info.propertyValue("damageTypeId","")

    //layers
    property string featureServiceURL: app.info.propertyValue("featureServiceURL","")
    property var featureLayerId: []
    property var featureLayerIdString: app.info.propertyValue("featureLayerId","")
    property string featureLayerName: app.info.propertyValue("featureLayerName","")
    property string featureLayerURL: featureServiceURL + "/" + featureLayerId
    property string baseMapURL: app.info.propertyValue("baseMapServiceURL","")
    property bool allowPhotoToSkip: app.info.propertyValue("allowPhotoToSkip",true)
    property string webMapID: app.info.propertyValue("webMapID","")
    property string offlineMMPKID: app.info.propertyValue("offlineMMPKID","")
    property string logoUrl: app.info.propertyValue("logoUrl","")

    //feedback
    property string websiteUrl: app.info.propertyValue("websiteUrl","")
    property string websiteLabel: app.info.propertyValue("websiteLabel", "")
    property string phoneNumber : app.info.propertyValue("phoneNumber","")
    property string phoneLabel: app.info.propertyValue("phoneLabel", "")
    property string emailAddress : app.info.propertyValue("emailAddress","")
    property string emailLabel: app.info.propertyValue("emailLabel", "")
    property string socialMediaUrl : app.info.propertyValue("socialMediaUrl","")
    property string socialMediaLabel : app.info.propertyValue("socialMediaLabel","")
    property string disclaimerMessage: app.info.licenseInfo
    property string helpPageUrl: app.info.propertyValue("reportHelpUrl", "")
    property string thankyouMessage: app.info.propertyValue("thankyouMessage", "")

    //Cellular data strings for issue 401
    property string dataWarningMessage: qsTr("The total attachment size is greater than 10 MB, are you sure you want to use cellular data to submit the report?")
    property string warningMessageButtonYes: qsTr("Yes")
    property string warningMessageButtonNo: qsTr("No")
    property string warningMessageButtonDontAsk: qsTr("Don't ask again")
    property string warningMessageButtonSubmit: qsTr("Submit")
    property string saveDataMode: qsTr("Cellular Data Saver")
    property string saveDataModeDes: qsTr("Enable this setting to display a warning message when using cellular data to download the Mobile Map Package, or submitting a report with a total attachment size greater than 10 MB.")
    property string allowMessage: qsTr("Allow uploads or downloads using cellular data")
    property string summary:qsTr("Summary")
    // property string report:qsTr("Disaster")
    property string type:qsTr("Disaster Type")
    property string reportType:qsTr("Report Type")
    property string damageType:qsTr("Damage Type")
    property string location:qsTr("Location")
    property string media:qsTr("Media")
    property string details:qsTr("Details")

    property string reportTypeString: ""
    property string damageTypeString: ""

    readonly property color black_87: app.isDarkMode ? app.textColor:"#DE000000"
    readonly property color white_100: "#FFFFFFFF"
    readonly property url license_appstudio_icon: "./Images/appstudio.png"
    property color blk_030: app.isDarkMode ? "#4A4A4A" : "#DFDFDF"
    property color blk_000: app.isDarkMode ? "#2B2B2B" : "#FFFFFF"
    readonly property var kContentTypes: ({
                                              "jpg": "image/jpeg",
                                              "jfif": "image/jpeg",
                                              "jpeg": "image/jpeg",
                                              "png": "image/png",
                                              "gif": "image/gif",
                                              "tif": "image/tiff",
                                              "tiff": "image/tiff",
                                              "txt": "text/plain",
                                              "csv": "text/plain",
                                              "zip": "application/zip",
                                              "mp3": "audio/basic",
                                              "mpeg": "audio/basic",
                                              "wav": "audio/wav",
                                              "xml": "text/xml",
                                              "pdf":"application/pdf"
                                          });

    readonly property string kDefaultContentType: "application/octet-stream"
    property var favoriteEntries:({})
    property string  featureLayerBeingEdited:""
    property var activeLayerIcon:({})
    property var locationDisplayText:""
    property bool hasAllRequired: false

    signal attributesChanged()


    // property checks
    property bool isPhoneAvailable: {
        if (phoneNumber > "") {
            footerModel.append({"name":phoneLabel, "type": "phone", "value":phoneNumber, "icon": "../images/ic_phone_white_48dp.png"})
            return true
        } else {
            return false
        }
    }

    property bool isEmailAvailable: {
        if (emailAddress > "") {
            footerModel.append({"name":emailLabel, "type": "email", "value":emailAddress, "icon": "../images/ic_drafts_white_48dp.png"})
            return true
        } else {
            return false
        }
    }

    property bool isWebUrlAvailable: {
        if (websiteUrl > "") {
            footerModel.append({"name":websiteLabel, "type": "link", "value":websiteUrl, "icon": "../images/ic_public_white_48dp.png"})
            return true
        } else {
            return false
        }
    }

    property bool isSocialMediaUrlAvailable: {
        if (socialMediaUrl > "") {
            footerModel.append({"name":socialMediaLabel, "type": "link", "value":socialMediaUrl, "icon": "../images/ic_public_white_48dp.png"})
            return true
        } else {
            return false
        }
    }

    property bool isHelpUrlAvailable: helpPageUrl > ""
    property bool isLandingPageBackgroundImageAvailable: landingPageBackgroundImageURL > ""
    property bool isDisclamerMessageAvailable: checkEmptyText(disclaimerMessage)
    property bool hasDisclamerMessageShown: false
    function checkEmptyText(text) {
        var cleanText = text.replace(/<\/?[^>]+(>|$)/g, "");
        cleanText = cleanText.trim();
        return cleanText > ""
    }
    function fileSizeConverter(fileSizeInBytes) {
        var i = -1;
        var byteUnits = [qsTr("KB"), qsTr("MB"), qsTr("GB")];
        do {
            fileSizeInBytes = fileSizeInBytes / 1024;
            i++;
        } while (fileSizeInBytes > 1024);

        return "%1 %2".arg(Number(Math.max(fileSizeInBytes, 0.1).toFixed(1)).toLocaleString(Qt.locale(), "f", 0)).arg(byteUnits[i]);


    }

    //Attributes
    property var attributesArray
    property var attributesArrayCopy
    property var savedReportLocationJson

    //Security
    property string username: rot13(app.settings.value("username",""))
    property string password: rot13(app.settings.value("password",""))
    property string signInType: app.info.propertyValue("signInType", "none")

    /* *********** DOMAINS AND SUBTYPES ********************* */

    property variant domainValueArray: []
    property variant domainCodeArray: []

    property variant subTypeCodeArray: []
    property variant subTypeValueArray: []

    property variant domainRangeArray: []
    property variant delegateTypeArray:[]

    property var protoTypesArray: []
    property var protoTypesCodeArray: []

    property variant networkDomainsInfo

    property bool hasSubtypes: false
    property bool hasSubTypeDomain: false

    property var featureTypes
    property var featureType

    property var selectedFeatureType
    property var fields: []
    property var fieldsMassaged:[]
    property var templatesAttributes: ({})
    property var typeIdField

    property int pickListIndex: -1
    property bool isFromSaved: false
    property bool isFromSend: false
    property var currentEditedSavedIndex
    property bool isShowCustomText: true

    property int counts: 0
    property var datas: []

    //-------------------- Setup for the App ----------------------

    property string selectedImageFilePath: ""
    property string selectedImageFilePath_ORIG: ""
    property bool selectedImageHasGeolocation: false
    property var currentAddedFeatures : []

    property bool hasAttachment: false
    property bool hasType: false

    property var theFeatureToBeInsertedID: null
    property var theFeatureSucessfullyInsertedID: null
    property bool theFeatureEditingAllDone: false
    property bool theFeatureEditingSuccess: false
    property bool theFeatureAttachmentsSuccess: true
    property int theFeatureServiceWKID: -1
    property SpatialReference theFeatureServiceSpatialReference

    property string reportSubmitMsg: qsTr("Submitting the report")
    property string reportSuccessMsg: qsTr("Submitted successfully.")
    property string errorMsg: qsTr("Sorry there was an error!")
    property string photoSizeMsg: qsTr("Photo size is ")
    property string photoAddMsg: qsTr("Adding photo to draft: ")
    property string photoSuccessMsg: qsTr("Photo added successfully: ")
    property string photoFailureMsg: qsTr("Sorry could not add photo: ")
    property string videoFailureMsg: qsTr("Sorry could not add video")
    property string audioFailureMsg: qsTr("Sorry could not add audio")
    property string doneMsg: qsTr("Click Done to continue.")
    property string askToSaveMsg: qsTr("Please save as draft and submit later.")
    property string savedSuccessMessage: qsTr("Saved as draft.")
    property string resetTitle: qsTr("Do you wish to continue?")
    property string resetMessage: qsTr("This will erase all saved drafts, saved entries in clipboard, offline map, and custom app settings from this device.")
    property string logoutTitle: qsTr("Are you sure you want to sign out?")
    property string logoutMessage: qsTr("")
    property string titleForSubmitInDraft: qsTr("Do you want to continue?")
    property string messageForSubmitInDraft: qsTr("You are about to submit this draft.") + "\n"

    property string mmpkDownloadingString: qsTr("Downloading")
    property string mmpkDownloadCompletedString: qsTr("Download completed")
    property string mmpkDownloadDialogString: qsTr("Offline map available. Download now?")
    property string mmpkUpdateDialogString: qsTr("Do you want to update offline map?")
    property string mmpkMenuDownloadString: qsTr("Download Offline Map")
    property string mmpkMenuUpdateString: qsTr("Update Offline Map")
    property string mmpkDownloadFailString: qsTr("Failed to download. Try again later.")
    property string mmpkMapDownloadSizeString: qsTr("Map download size")
    property string mmpkMapLastUpdatedString: qsTr("Last updated")
    property string mmpkSwitchToOfflineString: qsTr("Switching to offline map.")
    property string mmpkSwitchToOnlineString: qsTr("Switching to online map.")
    property string mmpkUseOfflineMapString: qsTr("Use offline Map")

    // Check capabilities
    readonly property string locationAccessDisabledTitle: qsTr("Location access disabled")
    readonly property string locationAccessDisabledMessage: qsTr("Please enable Location access permission for %1 in the device Settings.").arg(app.info.title)
    readonly property string ok_String: qsTr("OK")

    // Dialog buttons
    readonly property string today_string: qsTr("TODAY")
    readonly property string cancel_string: qsTr("CANCEL")

    // Copy and paste
    readonly property string save_entries: qsTr("Save to clipboard")
    readonly property string entries_saved: qsTr("Entries saved to clipboard.")
    readonly property string paste_entries: qsTr("Paste from clipboard")
    readonly property string clear_entries: qsTr("Clear clipboard")
    readonly property string clear_toast: qsTr("Are you sure you want to clear saved entries from clipboard?")

    readonly property string delete_app: qsTr("Delete")
    property bool skipPressed: false
    property string captureType: "point"
    property Polyline polylineObj
    property Polygon polygonObj
    property Envelope centerExtent
    property var measureValue
    property bool isReadyForSubmit: false

    property Point theNewPoint

    property var theFeatureServiceTable
    property var theFeatureLayer
    property var theFeatureAttachment

    property bool bugTestFlag: true
    property url temp

    property alias appModel:fileListModel
    property alias appModelCopy: fileListModelCopy
    property int maximumAttachments: app.info.propertyValue("maximumAttachments", 6)
    property alias savedReportsModel: savedReportsListModel
    property alias submitStatusModel: submitStatusModel
    property var summaryModel:[]

    property var localdb

    property string galleryTitle: qsTr("Gallery")
    property int numOfSteps: 2 + (hasAttachment? 1 : 0) + (hasType? 1: 0)

    property alias alertBox: alertBox
    property alias serverDialog: serverDialog
    property alias draftSaveDialog: draftSaveDialog

    property alias mmpkManager: mmpkManager
    property alias calendarDialogComponent: calendarDialogComponent
    property var calendarPicker

    property var currentObjectId: -1

    property alias networkConfig: networkConfig

    property bool isHapticFeedbackSupported
    readonly property bool isDebug: false
    readonly property color primaryColor: app.isDebug ? app.randomColor("primary") : app.getProperty("brandColor", "#166DB2")

    readonly property color accentColor: Qt.lighter(app.primaryColor)
    readonly property real baseUnit: app.units(8)
    readonly property real defaultMargin:2 * app.baseUnit
    readonly property real headerHeight: 7 * app.baseUnit
    property var sentAttachmentCount1
    property var submittedAttachments: []

    property var itemId:app.info.itemId ?app.info.itemId:app.folder.folderName
    property string dbfolderPath:"~/ArcGIS/AppStudio/"+ itemId + "/Data/Sql/quickreport.sqlite"
    property string attachmentsBasePath:"~/ArcGIS/AppStudio/"+ itemId + "/Data/Attachments/"
    property FileFolder attachmentsFolder:(AppFramework.fileInfo(attachmentsBasePath)).folder
     property ListModel themes: ListModel{}

    focus: true

    Keys.onReleased: {
        event.accepted = true
        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape){
            if(confirmBox.visible === true){
                confirmBox.visible = false
            } else if(alertBox.visible === true){
                alertBox.visible = false;
            } else if(serverDialog.visible === true){
                serverDialog.visible = false;
            } else{
                stackView.currentItem.back();
            }
        }
    }
    property bool isNeedGenerateToken: false

    ListModel{
        id: fileListModel
    }

    ListModel{
        id: fileListModelCopy
    }

    ListModel {
        id: submitStatusModel
    }

    FileFolder{
        id: mypicturesFolder
        path: "~/ArcGIS/AppStudio/"+ itemId + "/Data/Pictures"
        Component.onCompleted: {
            makeFolder();
        }
    }

    FileFolder{
        id: videoFolder

        path: "~/ArcGIS/AppStudio/"+ itemId + "/Data/Video"

        Component.onCompleted: {
            makeFolder();
        }
    }


    SqlDatabase {
        id: db

       property FileInfo dbfileInfo: AppFramework.fileInfo(dbfolderPath)
       databaseName: dbfileInfo.filePath

        Component.onCompleted: {            
            console.log("makeFolder", dbfileInfo.folder.makeFolder())
           // console.log("makePath", dbFolder.makePath(dbFolder.path))
            console.log("2", db.open());
            console.log("INITIALIZED", dbfileInfo.folder.path)
            initDBTables()
            importDataIntoSqlFromLocalStorage()
            loadFavorites()
            if (Qt.platform.os === "ios")
                updateAttachmentPathForiOS()

            attributesArray = {};
            updateSavedReportsCount();
        }
    }


    function randomColor (colortype) {
        var types = {
            "primary": ["#4A148C", "#0D47A1", "#004D40", "#006064", "#1B5E20", "#827717", "#3E2723"],
            "background": ["#F5F5F5", "#EEEEEE"],
            "foreground": ["#22000000"],
            "accent": ["#FF9800", "yellow", "red"]
        },
        type = types[colortype]
        return type[Math.floor(Math.random() * type.length)]
    }

    function getProperty (name, fallback) {
        if (!fallback && typeof fallback !== "boolean") fallback = ""
        return app.info.propertyValue(name, fallback) || fallback
    }

    function initDBTables(){
        // add firstName TEXT, lastName TEXT, gender INT, age INT, bloodType TEXT, tel TEXT, email TEXT to attributes
        // add disasterType TEXT, reportType TEXT, damageType TEXT, resourceType TEXT to query below
        db.query("CREATE TABLE IF NOT EXISTS DRAFTS(id INT, pickListIndex INT, size INT, nameofitem TEXT, editsjson TEXT, attributes TEXT, date TEXT, attachements TEXT, featureLayerURL TEXT, disasterType TEXT, reportType TEXT, damageType TEXT, resourceType TEXT)");
        db.query("CREATE TABLE IF NOT EXISTS FAVORITES(featureServiceURL TEXT,layerName INT, category TEXT,  editsjson TEXT)");
    }
    function importDataIntoSqlFromLocalStorage()
    {
        //get the data from local storage
        var dbname = itemId;
        if(dbname)
        {
            localdb = LocalStorage.openDatabaseSync(dbname, "1.0", "Unsent Reports", 1000000);
            console.log("localdb", localdb)
            try{
                importData();
            }
            catch(error)
            {
                console.log("Error in importing data. Check if the database exists")
            }

        }

    }

    function saveFavorites(favoriteObj)
    {
        clearFavorites()
        db.query("BEGIN TRANSACTION");
        var insert_query = db.query();
        insert_query.prepare("INSERT INTO FAVORITES(featureServiceUrl,layerName, category, editsJson)  VALUES(:featureServiceUrl,:layerName, :category, :editsJson);")
        insert_query.executePrepared({featureServiceUrl:app.featureServiceURL,layerName:favoriteObj.layerName, category:favoriteObj.category, editsJson:favoriteObj.editsJson});
        insert_query.finish();
        db.query("END TRANSACTION")
    }
    function clearAllFavorites()
    {
        db.query("BEGIN TRANSACTION");
        var delete_query1 = db.query();
        delete_query1.prepare("DELETE FROM FAVORITES;")
        delete_query1.executePrepared();
        delete_query1.finish();

        db.query("END TRANSACTION")
    }

    function clearFavorites()
    {
        db.query("BEGIN TRANSACTION");
        var delete_query1 = db.query();
        delete_query1.prepare("DELETE FROM FAVORITES where featureServiceUrl= :featureServiceURL and layerName = :featureLayerUrl")
        delete_query1.executePrepared({featureServiceURL:app.featureServiceURL,featureLayerUrl:app.featureLayerBeingEdited});




        delete_query1.finish();

        db.query("END TRANSACTION")

    }

    function loadFavorites()
    {
        db.query("BEGIN TRANSACTION");

        var select_query = db.query("SELECT * FROM FAVORITES where featureServiceUrl=:featureServiceURL",{featureServiceURL:app.featureServiceURL});


        for(var ok = select_query.first(); ok; ok = select_query.next()) {
            var rs = select_query.values;

            var layerName = rs.layerName;
            var category = rs.category;
            var editsjson = rs.editsjson;
            var categoryObj = {}
            categoryObj[category] = editsjson
            favoriteEntries[layerName] = categoryObj


        }

        db.query("END TRANSACTION")

    }

    function importData()
    {  db.query("BEGIN TRANSACTION");
        localdb.transaction(function(tx){
            var rs = tx.executeSql('SELECT * FROM DRAFTS');
            console.log("break 1");
            for(var i = 0; i < rs.rows.length; i++) {
                var attributes = rs.rows.item(i).attributes;
                var id = rs.rows[i].id;
                var pickListIndex = rs.rows[i].pickListIndex;
                var size = rs.rows[i].size;
                var nameofitem = rs.rows[i].nameofitem;
                var editsjson = rs.rows[i].editsjson;
                var date = rs.rows[i].date;
                var attachments = rs.rows[i].attachements;
                var featureLayerURL = rs.rows[i].featureLayerURL;

                console.log("break 2");
                // add var disasterType TEXT, reportType TEXT, damageType TEXT, resourceType TEXT
                var disasterType = rs.rows[i].disasterType;
                var reportType = rs.rows[i].reportType;
                var damageType = rs.rows[i].damageType;
                var resourceType = rs.rows[i].resourceType;
                console.log("break 3");

                //insert in SQLDatabase
                var insert_query = db.query();
                insert_query.prepare("INSERT INTO DRAFTS(id, pickListIndex, size, nameofitem, editsjson, attributes, date, attachements, featureLayerURL, disasterType, reportType, damageType, resourceType)  VALUES(:id, :pickListIndex, :size, :nameofitem, :editsjson, :attributes, :date, :attachements, :featureLayerURL, :reportType, :damageType, :resourceType);")
                insert_query.executePrepared({id:id, pickListIndex:pickListIndex, size:size, nameofitem:nameofitem, editsjson:editsjson, attributes:attributes, date:date, attachements:attachments, featureLayerURL:featureLayerURL, disasterType:disasterType, reportType:reportType, damageType:damageType, resourceType:resourceType});
                insert_query.finish();
                // now delete the imported record from LocalStorage
                tx.executeSql('DELETE FROM DRAFTS WHERE id = ?', id)

            }

        })

        db.query("END TRANSACTION")


    }

    //update the attachments path in sqlite db
    function updateAttachmentPathForiOS()
    {
        db.query("BEGIN TRANSACTION")
        var select_query = db.query("SELECT * FROM DRAFTS;");
        var insert_query1 = db.query();
        insert_query1.prepare(`UPDATE DRAFTS SET attachements = :attachments WHERE id = :id;`)

        for(var ok = select_query.first(); ok; ok = select_query.next()) {
            var rs = select_query.values;
            var attachments = rs.attachements;
            if(attachments.length > 3)
            {
                var attachments_new = getAttachmentsPath(attachments)
                var recid = rs.id;

                insert_query1.executePrepared({attachments:attachments_new,id: recid});
            }
        }
        select_query.finish()
        db.query("END TRANSACTION");

    }


    function getAttachmentsPath(attachments)
    {
        var attach1 = attachments.substring(1,attachments.length -1 ).replace(/(^")|("$)/g,'')
        var attach2 = attach1.split(',')

        var newAttachments=[];
        if(attach2)
        {

            newAttachments = attach2.map(getCurrentPath)
        }

        var newAttach = "[" + newAttachments.toString() + "]"
        return newAttach

    }
    //whenever an app is installed in iOS the appData location changes.
    //So we need to update the paths for attachments when the app starts.Need to revisit this
    //for storing relative paths instead of absolute paths.
    function getCurrentPath(filepath)
    {
        var sandboxpath = AppFramework.standardPaths.standardLocations(StandardPaths.AppDataLocation[0])
        var prefix = sandboxpath[0].split("/Desktop")[0]
        var oldfilePath_trimmed = filepath.split("/Documents")[1]
        var newfilepath = prefix + oldfilePath_trimmed

        var attach_renamed = newfilepath.substring(0,newfilepath.length).replace(/(^")|("$)/g,'')
        var beginchar = attach_renamed.charAt(0)
        while(beginchar === '\"')
        {
            attach_renamed = attach_renamed.substring(0,attach_renamed.length).replace(/(^")|("$)/g,'')
            beginchar = attach_renamed.charAt(0)
        }
        var endchar = attach_renamed.charAt(attach_renamed.length)
        while(endchar === '\"')
        {
            attach_renamed = attach_renamed.substring(0,attach_renamed.length).replace(/(^")|("$)/g,'')
            endchar = attach_renamed.charAt(attach_renamed.length -1)
        }
        newfilepath = '\"' + attach_renamed + '\"'

        return newfilepath.toString()
    }


    function db_prepare_sql(db, sql) {
        var dbQuery = db.query();
        dbQuery.prepare(sql);

        return dbQuery;
    }

    function db_error(dbError) {
        return new Error( "Error %1 (Type %2)\n%3\n%4\n"
                         .arg(dbError.nativeErrorCode)
                         .arg(dbError.type)
                         .arg(dbError.driverText)
                         .arg(dbError.databaseText)
                         );
    }

    function db_exec_sql(db, sql, obj) {
        var dbQuery = obj ? db.query(sql) : db.query(sql, obj);
        if (dbQuery.error) throw db_error(dbQuery.error);
        var ok = dbQuery.first();

        while (ok) {
            console.log("while ok", JSON.stringify(dbQuery.values));
            ok = dbQuery.next();
        }
        dbQuery.finish();
    }
    function populateThemes(){
        themes.append({theme:app.automatic})
        themes.append({theme:app.light})
        themes.append({theme:app.dark})
    }

    Component.onCompleted: {
        populateThemes()
        if(!attachmentsFolder.exists)
            attachmentsFolder.makeFolder()

        isHapticFeedbackSupported = HapticFeedback.supported

        // add disaster types
        if(typeof disasterTypeIdString === "string") {
            if(disasterTypeIdString.trim() > "") disasterTypeId = disasterTypeIdString.split(",").map(Number);
            else disasterTypeId = [];
        } else if(typeof disasterTypeIdString === "number") {
            disasterTypeId = [disasterTypeIdString];
        }

        // add report types
        if(typeof reportTypeIdString === "string") {
            if(reportTypeIdString.trim() > "") reportTypeId = reportTypeIdString.split(",").map(Number);
            else reportTypeId = [];
        } else if(typeof reportTypeIdString === "number") {
            reportTypeId = [reportTypeIdString];
        }

        // add damage types
        if(typeof damageTypeIdString === "string") {
            if(damageTypeIdString.trim() > "") damageTypeId = damageTypeIdString.split(",").map(Number);
            else damageTypeId = [];
        } else if(typeof damageTypeIdString === "number") {
            damageTypeId = [damageTypeIdString];
        }

        if(typeof featureLayerIdString === "string") {
            if(featureLayerIdString.trim() > "")featureLayerId = featureLayerIdString.split(",").map(Number);
            else featureLayerId = [];
        } else if(typeof featureLayerIdString === "number") {
            featureLayerId = [featureLayerIdString];
        }

        // @TODO: Update with latest iPhone X models
        if (Qt.platform.os === "ios" && AppFramework.systemInformation.hasOwnProperty("unixMachine")) {
            if(isNotchAvailable())
                app.isIPhoneX = true;
        }
//        if(app.helpPageUrl && !validURL(app.helpPageUrl))
//        copyLocalFile();

        app.token = app.settings.value("token", "");
        app.expiration = app.settings.value("expiration", "");
    }

    function isNotchAvailable() {
        var unixName = AppFramework.systemInformation.unixMachine;

        if (unixName.match(/iPhone(10|\d\d)/)) {
            switch(unixName) {
            case "iPhone10,1":
            case "iPhone10,4":
            case "iPhone10,2":
            case "iPhone10,5":
                return false;
            default:
                return true;
            }
        }
        return false;
    }

    function copyLocalFile(){
        var path = AppFramework.userHomeFolder.filePath("ArcGIS/AppStudio/Data");
        var arr = helpPageUrl.split("/");        
        var newPath = path
        var resourceFolderName = arr[0];
        var resourceFileName = arr[1];
        if(resourceFolderName.length > 1)
        newPath = path + "/" + resourceFolderName
        AppFramework.userHomeFolder.makePath(newPath);
        var resourceFolder = AppFramework.fileFolder(app.folder.folder(resourceFolderName).path);
        var outputFolder = AppFramework.fileFolder(newPath);
        if(resourceFileName !== undefined)
        {
        var outputLocation = newPath + "/" + resourceFileName;
        outputFolder.removeFile(resourceFileName);
        resourceFolder.copyFile(resourceFileName, outputLocation);
        }
    }

    function rot13(s) {
        return s.replace(/[A-Za-z]/g, function (c) {
            return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".charAt(
                        "NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm".indexOf(c)
                        );
        } );
    }

    Connections {
        target: AppFramework.network
        onIsOnlineChanged: {
            isOnline = Networking.isOnline
        }
    }

    Point {
        id: pointGeometry
        x: 200
        y: 200
    }

    MessageDialog {
        id: messageDialog

        Material.primary: app.primaryColor

        pageHeaderHeight: app.headerHeight
    }

    FileFolder {
        id: folder
    }


    function getFileSize(filePath)
    {
        var fileInfo = AppFramework.fileInfo(filePath);
        var fileSize =  ""
        if(fileInfo.size < 1024)
            fileSize = `${fileInfo.size} Bytes`
        else
            fileSize = app.fileSizeConverter(fileInfo.size)
        return fileSize
    }

    function submitFeature(featureUid,mailpayload,attachments)
    {
        app.focus = true;

        var featureattributes = {}

        var geometryForFeatureToEdit;
        if(captureType === "point")geometryForFeatureToEdit = app.theNewPoint;
        else if(captureType === "line")geometryForFeatureToEdit = app.polylineObj;
        else geometryForFeatureToEdit = app.polygonObj;

        var attributesToEdit = {};

        for ( var field in attributesArray) {
            if ( attributesArray[field] === "" || attributesArray[field] === null) {
                attributesToEdit[field] = null;
            } else {
                attributesToEdit[field] = attributesArray[field];
            }
        }
        // TO-DO
        if(theFeatureTypesModel.count>0) attributesToEdit[app.typeIdField] =  theFeatureTypesModel.get(pickListIndex).value;

        attributesToEdit["GlobalID"] = featureUid
        var finalJSONEdits = [{"attributes": attributesToEdit, "geometry":geometryForFeatureToEdit.json}]
        console.log("JSON for save feature json", JSON.stringify(finalJSONEdits))


        mailpayload.reportInfo.attributes = finalJSONEdits
        mailpayload.reportInfo.featureServiceUrl = (featureServiceManager.url).toString()

        app.theFeatureAttachmentsSuccess = true;
        app.theFeatureEditingAllDone = false;
        app.theFeatureEditingSuccess = false;
        var featureToSubmit = {}
        var featureAttachments = {"adds":app.submittedAttachments}

        featureToSubmit = {"f":"json","adds":JSON.stringify(finalJSONEdits),"useGlobalIds":true,"attachments":JSON.stringify(featureAttachments)}

        featureServiceManager.applyEditsUsingAttachmentFirst(featureToSubmit, function(objectId,errorCode){

            // console.log("success")
            if(errorCode === 0)
            {
                mailpayload.reportInfo.objectId = objectId
                app.theFeatureEditingAllDone = true
                app.theFeatureEditingSuccess = true
                submitStatusModel.append({"type":"feature","loadStatus":"success","objectid":objectId,"fileName":""})
                removeAttachments(attachments)

                if(app.theFeatureEditingSuccess === true && app.isFromSaved){
                    var delete_query = db.query();
                    delete_query.prepare("DELETE FROM DRAFTS WHERE id =:id;")
                    db.query("BEGIN TRANSACTION");
                    delete_query.executePrepared({id: app.currentEditedSavedIndex});
                    delete_query.finish();
                    db.query("END TRANSACTION");

                }
                if(app.payloadUrl)
                    featureServiceManager.sendEmail(mailpayload)
                app.theFeatureEditingAllDone = true;
                app.theFeatureEditingSuccess = true;
            }
            else
                submitStatusModel.append({"type":"feature","loadStatus":"failed","objectid":objectId,"fileName":""})

        })

    }

    function submitReportUsingAttachmentFirst(){
        app.sentAttachmentCount1 = 0;
        var mailpayload = {
            "meta":{},
            "reportInfo":{},
            "attachmentInfo":[]

        }
        stackView.showResultsPage()

        var metaObjInfo = {}
        metaObjInfo.os = Qt.platform.os
        metaObjInfo.appVersion = app.info.version
        metaObjInfo.appName = app.info.title
        metaObjInfo.deviceLocale = Qt.locale().name
        metaObjInfo.appStudioVersion = AppFramework.version

        var currentdate =  new Date().toLocaleString();

        metaObjInfo.submitDate = currentdate

        metaObjInfo.systemInfo  = AppFramework.systemInformation
        mailpayload.meta = metaObjInfo

        var featureUid = AppFramework.createUuidString(0)
        if(submitStatusModel.count > 0) submitStatusModel.clear();
        var attachments = [];
        if(app.appModel.count > 0)
        {
            for(var i=0;i<app.appModel.count;i++){

                var type = app.appModel.get(i).type;

                if(type === "attachment") {
                    temp = app.appModel.get(i).path;
                    app.selectedImageFilePath = AppFramework.resolvedPath(temp);
                } else if(type === "attachment2"){
                    app.selectedImageFilePath = app.appModel.get(i).path//.replace("file://","");
                } else if(type === "attachment3"){
                    app.selectedImageFilePath = app.appModel.get(i).path//.replace("file://","");
                }
                else
                    app.selectedImageFilePath = app.appModel.get(i).path//.replace("file://","");

                if(Qt.platform.os === "windows")
                    app.selectedImageFilePath = app.selectedImageFilePath.replace("file:///","");
                else
                    app.selectedImageFilePath = app.selectedImageFilePath.replace("file://","");



                var fileInfo = AppFramework.fileInfo(app.selectedImageFilePath);
                var fileName = fileInfo.fileName
                var arr = fileName.split(".");
                var suffix = arr[1];

                var imageFilePath = fileInfo.filePath
                if(imageFilePath.includes(":"))
                {
                    var temparr = imageFilePath.split(":");
                    imageFilePath = temparr[1]
                }
                var filePath = app.selectedImageFilePath
                if(Qt.platform.os === "windows")
                {
                    var res = app.selectedImageFilePath.charAt(0)
                    if(res === "/")
                        filePath = app.selectedImageFilePath.substring(1)
                }
                var sizeOfAttachment = app.getFileSize(filePath)


                submitStatusModel.append({"type": type, "loadStatus": "loading", "objectId": "", "fileName": fileName});
                attachments[i] = {"type":suffix,"size":sizeOfAttachment,"name":fileInfo.fileName,"filePath":filePath}


                featureServiceManager.uploadAttachment(imageFilePath, featureUid, function(errorcode, responseJson, fileIndex){

                    if(errorcode===0){
                        app.sentAttachmentCount1++
                        mailpayload.attachmentInfo.push({type:attachments[app.sentAttachmentCount1 - 1].type,size:attachments[app.sentAttachmentCount1 - 1].size,name:attachments[app.sentAttachmentCount1 - 1].name})

                        var attach = {}
                        //generate a globalid for the attachment
                        var attachmentUid = AppFramework.createUuidString(0)
                        //get the suffix
                        var filesuffix = responseJson.item.itemName.split('.')[1]
                        var contentType = app.kContentTypes[filesuffix]
                        if(!contentType)
                            contentType = app.kDefaultContentType

                        var item = {
                            "uploadId":responseJson.item.itemID,
                            "name":responseJson.item.itemName,
                            "globalId":attachmentUid,
                            "parentGlobalId":featureUid,
                            "contentType":contentType
                        }
                        app.submittedAttachments.push(item)
                        submitStatusModel.setProperty(fileIndex+1, "loadStatus", "success");

                        //add the feature after uploading all the attachments
                        if(app.sentAttachmentCount1 === app.appModel.count)
                        {
                            //now upload the feature
                            submitFeature(featureUid,mailpayload,attachments)

                        }

                    }
                    else
                    {
                        submitStatusModel.setProperty(fileIndex+1, "loadStatus", "failed");
                        app.theFeatureAttachmentsSuccess = false;

                    }

                }, i);
            }
        }
        else
        {

            submitFeature(featureUid,mailpayload,attachments)

        }


    }

    function submitReportUsingFeatureFirst(){
        app.focus = true;
        isShowCustomText = true

        app.currentObjectId = -1;
        var featureattributes = {}
        var mailpayload = {
            "meta":{},
            "reportInfo":{},
            "attachmentInfo":[]

        }
        var attachments={}
        var metaObjInfo = {}
        metaObjInfo.os = Qt.platform.os
        metaObjInfo.appVersion = app.info.version
        metaObjInfo.appName = app.info.title
        metaObjInfo.deviceLocale = Qt.locale().name
        metaObjInfo.appStudioVersion = AppFramework.version

        var currentdate =  new Date().toLocaleString();

        metaObjInfo.submitDate = currentdate

        metaObjInfo.systemInfo  = AppFramework.systemInformation
        mailpayload.meta = metaObjInfo

        if(submitStatusModel.count > 0) submitStatusModel.clear();

        var geometryForFeatureToEdit;
        if(captureType === "point")geometryForFeatureToEdit = app.theNewPoint;
        else if(captureType === "line")geometryForFeatureToEdit = app.polylineObj;
        else geometryForFeatureToEdit = app.polygonObj;

        var attributesToEdit = {};

        for ( var field in attributesArray) {
            if ( attributesArray[field] === "" || attributesArray[field] === null) {
                attributesToEdit[field] = null;
            } else {
                attributesToEdit[field] = attributesArray[field];
            }
        }
        // TO-DO
        if(theFeatureTypesModel.count>0) attributesToEdit[app.typeIdField] =  theFeatureTypesModel.get(pickListIndex).value;

        var finalJSONEdits = [{"attributes": attributesToEdit, "geometry":geometryForFeatureToEdit.json}]
        //console.log("JSON for save feature json", JSON.stringify(finalJSONEdits))

        app.theFeatureAttachmentsSuccess = true;
        app.theFeatureEditingAllDone = false;
        app.theFeatureEditingSuccess = false;

        featureServiceManager.applyEditsUsingFeatureFirst(finalJSONEdits, function(objectId, errorCode){

            if(errorCode === -1){
                stackView.showResultsPage();
                app.theFeatureEditingAllDone = true;
                app.theFeatureEditingSuccess = false;
                app.theFeatureAttachmentsSuccess = false;

                submitStatusModel.append({"type": "feature", "loadStatus": "failed", "objectId": objectId, "fileName": ""});
            } else if(errorCode === -498){
                if(app.isNeedGenerateToken){
                    serverDialog.isReportSubmit = true;
                    serverDialog.submitFunction = submitReport;
                    serverDialog.handleGenerateToken();
                    app.isNeedGenerateToken = false;
                } else {
                    featureServiceManager.token = app.token;
                    app.isNeedGenerateToken = true;
                    submitReport();
                }
            } else{
                mailpayload.reportInfo.objectId = objectId
                mailpayload.reportInfo.attributes = finalJSONEdits
                mailpayload.reportInfo.featureServiceUrl = (featureServiceManager.url).toString()

                stackView.showResultsPage()

                submitStatusModel.append({"type": "feature", "loadStatus": "success", "objectId": objectId, "fileName": ""});
                app.currentObjectId = objectId;

                app.theFeatureEditingSuccess = true;

                if(app.appModel.count>0){
                    var sentAttachmentCount = 0;
                    var attachments = [];
                    for(var i=0;i<app.appModel.count;i++){

                        var type = app.appModel.get(i).type;

                        if(type === "attachment") {
                            temp = app.appModel.get(i).path;
                            app.selectedImageFilePath = AppFramework.resolvedPath(temp);
                        } else if(type === "attachment2"){
                            app.selectedImageFilePath = app.appModel.get(i).path.replace("file://","");
                        } else if(type === "attachment3"){
                            app.selectedImageFilePath = app.appModel.get(i).path.replace("file://","");
                        }
                        else
                            app.selectedImageFilePath = app.appModel.get(i).path.replace("file://","");

                        attachments.push(app.selectedImageFilePath);

                        var fileInfo = AppFramework.fileInfo(app.selectedImageFilePath);
                        var fileName = fileInfo.fileName
                        var arr = fileName.split(".");
                        var suffix = arr[1];

                        var imageFilePath = fileInfo.filePath
                        if(imageFilePath.includes(":"))
                        {
                            var temparr = imageFilePath.split(":");
                            imageFilePath = temparr[1]
                        }
                        var filePath = app.selectedImageFilePath
                        if(Qt.platform.os === "windows")
                        {
                            var res = app.selectedImageFilePath.charAt(0)
                            if(res === "/")
                                filePath = app.selectedImageFilePath.substring(1)
                        }
                        var sizeOfAttachment = app.getFileSize(filePath)


                        submitStatusModel.append({"type": type, "loadStatus": "loading", "objectId": "", "fileName": fileName});

                        attachments[i] = {"type":suffix,"size":sizeOfAttachment,"name":fileInfo.fileName,"filePath":filePath}

                        featureServiceManager.addAttachment(imageFilePath, objectId, function(errorcode, attachmentObjectId, fileIndex){
                            if(errorcode===0){
                                sentAttachmentCount++;
                                var attachmentUrl = featureServiceManager.url + "/"+ objectId + "/attachments/" + attachmentObjectId

                                mailpayload.attachmentInfo.push({url:attachmentUrl,type:attachments[sentAttachmentCount - 1].type,size:attachments[sentAttachmentCount - 1].size,name:attachments[sentAttachmentCount - 1].name})


                                submitStatusModel.setProperty(fileIndex+1, "loadStatus", "success");

                                if(sentAttachmentCount==app.appModel.count)
                                {
                                    app.theFeatureEditingAllDone = true
                                    removeAttachments(attachments)

                                    if(app.theFeatureEditingSuccess === true && app.isFromSaved){
                                        var delete_query = db.query();
                                        delete_query.prepare("DELETE FROM DRAFTS WHERE id =:id;")
                                        db.query("BEGIN TRANSACTION");
                                        delete_query.executePrepared({id: app.currentEditedSavedIndex});
                                        delete_query.finish();
                                        db.query("END TRANSACTION");

                                    }
                                    if(app.payloadUrl)
                                        featureServiceManager.sendEmail(mailpayload)
                                }
                            }else{
                                var type = app.appModel.get(fileIndex).type;

                                submitStatusModel.setProperty(fileIndex+1, "loadStatus", "failed");
                                app.theFeatureAttachmentsSuccess = false;

                                sentAttachmentCount++;

                                if(sentAttachmentCount==app.appModel.count){
                                    app.theFeatureEditingAllDone = true
                                    if(app.theFeatureEditingSuccess === true && app.isFromSaved){
                                        var delete_query1 = db.query();
                                        delete_query1.prepare("DELETE FROM DRAFTS WHERE id = :id;")
                                        db.query("BEGIN TRANSACTION");
                                        delete_query1.executePrepared({id: app.currentEditedSavedIndex});
                                        delete_query1.finish();
                                        db.query("END TRANSACTION");

                                    }
                                    if(app.payloadUrl)
                                        featureServiceManager.sendEmail(mailpayload)
                                }
                            }
                        }, i);
                    }

                } else{
                    app.theFeatureEditingAllDone = true;
                    app.theFeatureAttachmentsSuccess = true;
                    if(app.theFeatureEditingSuccess === true && app.isFromSaved){
                        var delete_query1 = db.query();
                        delete_query1.prepare("DELETE FROM DRAFTS WHERE id =:id;")
                        db.query("BEGIN TRANSACTION");
                        delete_query1.executePrepared({id: app.currentEditedSavedIndex});
                        delete_query1.finish();
                        db.query("END TRANSACTION");

                    }
                    if(app.payloadUrl)
                        featureServiceManager.sendEmail(mailpayload)
                }
            }

        });
    }

    function submitReport()
    {
        if(app.useGlobalIDForEditing)
            submitReportUsingAttachmentFirst()
        else
            submitReportUsingFeatureFirst()
    }

    function populateSummaryTitle()
    {
        var reportTitleSection = null
        if(app.featureLayerBeingEdited !== "default")
        {
            reportTitleSection = {}
            reportTitleSection["content"] = []
            var contentItem = {}
            var title = app.featureLayerBeingEdited    // point layer
            contentItem["icon"] = app.activeLayerIcon  // point icon
            contentItem["title"] = title               // point layer as title
            contentItem["isDotIconVisible"] = false
            contentItem["hasIcon"] = true

            reportTitleSection["heading"] = app.report // = "Disaster"
            reportTitleSection["content"].push(contentItem)
        }

        return reportTitleSection
    }

    function populateSummaryType()
    {
        var disasterTypeSection = null
        if(pickListIndex > -1) // TO-DO
        {
            disasterTypeSection = {}
            disasterTypeSection["content"] = []
            var contentItem = {}
            var disasterType = theFeatureTypesModel.count>0?theFeatureTypesModel.get(pickListIndex).label:""
            contentItem["title"] = disasterType
            contentItem["isDotIconVisible"] = false
            contentItem["hasIcon"] = false

            disasterTypeSection["heading"] = app.type
            disasterTypeSection["content"].push(contentItem)
        }
        return disasterTypeSection
    }

    function populateSummaryReportType()
    {
        var reportTypeSection = null
        reportTypeSection = {}
        reportTypeSection["content"] = []
        var contentItem = {}
        // var reportType = reportListModel.get(0).reportType //TO-DO

        contentItem["title"] = app.reportTypeString
        contentItem["isDotIconVisible"] = false
        contentItem["hasIcon"] = false

        reportTypeSection["heading"] = app.reportType
        reportTypeSection["content"].push(contentItem)

        return reportTypeSection
    }

    function populateSummaryDamageType()
    {
        var damageTypeSection = null
        damageTypeSection = {}
        damageTypeSection["content"] = []
        var contentItem = {}
        //var damageTypeId = app.damageTypeId //TO-DO

        contentItem["title"] = app.damageTypeString
        contentItem["isDotIconVisible"] = false
        contentItem["hasIcon"] = false

        damageTypeSection["heading"] = app.damageType
        damageTypeSection["content"].push(contentItem)

        return damageTypeSection
    }

    function populateSummaryLocation()
    {
        var reportLocationSection = {}
        reportLocationSection["content"] = []
        var contentItem = {}
        var geometryType = ""
        var geometryDesc = ""

        var geometryForFeatureToEdit;

        geometryDesc = app.locationDisplayText
        if(captureType === "point")
        {
            geometryType = "Point"
            geometryForFeatureToEdit = app.theNewPoint;
            var latitude = geometryForFeatureToEdit.y
            var longitude = geometryForFeatureToEdit.x
            // geometryDesc = `Lat: ${latitude} Long:${longitude}`
        }
        else if(captureType === "line")
        {
            geometryType = "Polyline"
            geometryForFeatureToEdit = app.polylineObj;
            var length = GeometryEngine.length(geometryForFeatureToEdit)
            //geometryDesc = length

        }
        else
        {
            geometryType = "Polygon"
            geometryForFeatureToEdit = app.polygonObj;
            var area = GeometryEngine.area(geometryForFeatureToEdit)
            //geometryDesc = area
        }
        contentItem["title"] = geometryType
        contentItem["description"] = geometryDesc
        contentItem["hasIcon"] = false
        contentItem["isDotIconVisible"] = true
        reportLocationSection["heading"] = app.location
        reportLocationSection["content"].push(contentItem)

        return reportLocationSection
    }

    function populateSummaryMedia()
    {
        var reportMediaSection = {}
        reportMediaSection["content"] = []
        reportMediaSection["heading"] = app.media
        for(var i=0;i<app.appModel.count;i++){
            var path = app.appModel.get(i).path;
            var modPath
            var fileSize = 0
            var fileInfo
            if(path.includes("file:"))
            {
                if(Qt.platform.os === "windows")
                {
                    var tempPath
                    if(path.includes("file:///")){
                        tempPath = path.split("file:///")[1]
                    }
                    else
                        tempPath = path.split("file://")[1]

                    modPath = tempPath.replace(":/","://")
                }
                else
                    modPath = path.split("file://")[1]

                fileInfo = AppFramework.fileInfo(modPath);
            }
            else
                fileInfo = AppFramework.fileInfo(path);

            var fileName = fileInfo.fileName
            //var fileInfo_attachment = AppFramework.fileInfo(modPath)

            if(fileInfo.size < 1024)
                fileSize = `${fileInfo.size} Bytes`
            else
                fileSize = app.fileSizeConverter(fileInfo.size)
            //var sizeOfAttachment = app.getFileSize(filePath)
            var contentItem = {}
            contentItem["title"] = fileName
            contentItem["description"] = fileSize
            contentItem["hasIcon"] = false
            contentItem["isDotIconVisible"] = true
            reportMediaSection["content"].push(contentItem)
        }


        if(app.appModel.count === 0)
        {
            var contentItem1 = {}
            contentItem1["title"] = qsTr("No attachment added")
            contentItem1["description"] = ""
            contentItem1["hasIcon"] = false
            contentItem1["isDotIconVisible"] = false
            reportMediaSection["content"].push(contentItem1)
        }

        return reportMediaSection

    }


    function getAttributeValue(fldName)
    {

        var attributes = Object.keys(attributesArray)
        var fldval = ""
        for(var i=0; i<attributes.length; i++)
        {
            var fldItem = attributes[i]
            if(fldItem.toLowerCase() === fldName.toLowerCase())
            {
                fldval = attributesArray[fldItem]
                fldval = getCodedDomainValue(fldName,fldval)
                break;
            }

        }
        return fldval
    }

    function getCodedDomainValue(fieldName,fldvalue)
    {
        var fieldValue = fldvalue
        for(var k=0;k<fieldsMassaged.length;k++)
        {
            var fld = fieldsMassaged[k]
            if(fld.name === fieldName)
            {

                var domain = fld.domain
                if(domain)
                {
                    if(domain.codedValues)
                    {
                        var codedValues = domain.codedValues
                        var fldnameArray = codedValues.filter(obj => obj.code === fldvalue)
                        if(fldnameArray.length > 0)
                        {
                            var fldDomainValue = fldnameArray[0].name
                            fieldValue = fldDomainValue
                        }

                    }


                }
                break
            }
        }
        return fieldValue
    }

    function populateSummaryDetails()
    {
        var reportDetailSection = {}
        reportDetailSection["content"] = []
        reportDetailSection["heading"] = app.details // = "Details"

        for(var i=0; i<fieldsMassaged.length; i++) {//featureAttributesModel
            var item = fieldsMassaged[i];
            var fieldName = item["alias"]
            var fldName = item["name"]
            var fieldVal = getAttributeValue(fldName)
            //var fieldVal = attributesArray[fldName.toLowerCase()]
            var fieldType = item["type"]
            if(fieldType === "esriFieldTypeDate")
            {
                fieldVal =  new Date (fieldVal).toLocaleString(Qt.locale(), Qt.DefaultLocaleShortDate)
            }

            var contentItem = {}
            contentItem["title"] = fieldName
            contentItem["description"] = fieldVal
            contentItem["isDotIconVisible"] = false
            contentItem["hasIcon"] = false
            reportDetailSection["content"].push(contentItem)

        }
        return reportDetailSection
    }


    function populateSummaryObject() // TO-DO
    {
        var summaryObject = []
//        var titleObject =  populateSummaryTitle() // point / line / polygon
//        if(titleObject)
//            summaryObject.push(titleObject)
        var typeObject = populateSummaryType() // what type of disaster
        if(typeObject)
            summaryObject.push(typeObject)

        var reportTypeObject = populateSummaryReportType() // what type of report
        if(reportTypeObject)
            summaryObject.push(reportTypeObject)

        var damageTypeObject = populateSummaryDamageType() // what type of report
        if(damageTypeObject)
            summaryObject.push(damageTypeObject)

        var locationObject = populateSummaryLocation()
        summaryObject.push(locationObject)
        if(app.hasAttachment)
        {
        var mediaObject = populateSummaryMedia()
        summaryObject.push(mediaObject)
        }
        var detailsObject = populateSummaryDetails() // details!!
        summaryObject.push(detailsObject)
        summaryModel = summaryObject

    }


    FileInfo{
        id: fileInfo
    }

    ExifInfo{
        id: exifInfo
    }

    NetworkConfig {
        id: networkConfig
    }

    function saveReport(){
        app.focus = true;
        var savedNameofitem;
        if(app.isFromSaved){
            if(app.currentEditedSavedIndex !== undefined)
            {
                var select_query = db.query("SELECT * FROM DRAFTS WHERE id=:id;", {id: app.currentEditedSavedIndex});

                db.query("BEGIN TRANSACTION")

                for(var ok = select_query.first(); ok; ok = select_query.next()) {
                    var rs = select_query.values;
                    var attributes = rs.attributes;
                    savedNameofitem = JSON.parse(attributes)["index"];
                    var delete_query1 = db.query();
                    delete_query1.prepare("DELETE FROM DRAFTS WHERE id = :id;")

                    delete_query1.executePrepared({id: app.currentEditedSavedIndex});
                    delete_query1.finish();
                    db.query("END TRANSACTION");


                }

            }
        }

        var geometryForFeatureToEdit;
        if(captureType === "point")geometryForFeatureToEdit = app.theNewPoint;
        else if(captureType === "line")geometryForFeatureToEdit = app.polylineObj;
        else geometryForFeatureToEdit = app.polygonObj;

        var attributesToEdit = {};

        for ( var field in attributesArray) {
            if ( attributesArray[field] === "" || attributesArray[field] === null) {
                attributesToEdit[field] = null;
            } else {
                attributesToEdit[field] = attributesArray[field];
            }
        }

        // TO-DO: DELETE THE pickListIndex
        //if(theFeatureTypesModel.count>0) attributesToEdit[app.typeIdField] =  theFeatureTypesModel.get(0).value;
        if(theFeatureTypesModel.count>0) attributesToEdit[app.typeIdField] =  theFeatureTypesModel.get(pickListIndex).value;
        var finalJSONEdits = [{"attributes": attributesToEdit, "geometry":geometryForFeatureToEdit? geometryForFeatureToEdit.json:null,"featureLayerName":app.featureLayerBeingEdited,"geometryDescription":app.locationDisplayText}]
        console.log("JSON for save feature json", JSON.stringify(finalJSONEdits))

        var currentDate = new Date();
        var id = currentDate.getTime();
        var dateString = currentDate.toLocaleString(Qt.locale(),"MMM d, hh:mm AP");

        var filePaths = [];
        var size = 0;

        for(var i=0;i<app.appModel.count;i++){
            temp = app.appModel.get(i).path;
            exifInfo.load(temp.toString().replace(Qt.platform.os == "windows"? "file:///": "file://",""))
            fileInfo.filePath = exifInfo.filePath;
            size+=fileInfo.size;
            app.selectedImageFilePath = AppFramework.resolvedPath(temp);
            filePaths.push(AppFramework.resolvedPath(temp))
        }
        var count = 0;

        var select_query1 = db.query("SELECT MAX(CAST(SUBSTR(nameofitem,6) AS INT)) as maxdraft FROM DRAFTS")
        if(theFeatureTypesModel.count === 0)
        {
            for(var name = select_query1.first(); name; name = select_query1.next()) {
                var rs_name = select_query1.values;
                var itemname =rs_name["maxdraft"]
                count = itemname + 1


            }
        }

        //TO-DO
        //var nameofitem = theFeatureTypesModel.count>0 ? theFeatureTypesModel.get(0).label : (app.isFromSaved? "Draft "+(savedNameofitem+1): "Draft "+count);
        var nameofitem = theFeatureTypesModel.count>0 ? theFeatureTypesModel.get(pickListIndex).label : (app.isFromSaved? "Draft "+(savedNameofitem+1): "Draft "+count);
        var xmax = app.centerExtent? app.centerExtent.xMax : null;
        var xmin = app.centerExtent? app.centerExtent.xMin : null;
        var ymax = app.centerExtent? app.centerExtent.yMax: null;
        var ymin = app.centerExtent? app.centerExtent.yMin: null;

        console.log("app.centerExtent", xmax, xmin, ymax, ymin);

        attributesArray["_xMax"] = xmax;
        attributesArray["_xMin"] = xmin;
        attributesArray["_yMax"] = ymax;
        attributesArray["_yMin"] = ymin;
        attributesArray["_realValue"] = app.measureValue? app.measureValue:0;
        attributesArray["hasAttachment"] = app.hasAttachment;
        attributesArray["isReadyForSubmit"] = app.isReadyForSubmit;
        attributesArray["index"] = app.isFromSaved?savedNameofitem:(theFeatureTypesModel.count>0? -1:count-1);

        // assign values
        var disasterType = theFeatureTypesModel.count>0 ? theFeatureTypesModel.get(pickListIndex).label : "";
        var reportType = app.reportTypeString;
        var damageType = app.damageTypeString;
        var resourceType = ""; // TO-DO: later, now for damage report

        var insert_query = db.query();
        // ADD attributes
        insert_query.prepare("INSERT INTO DRAFTS(id, pickListIndex, size, nameofitem, editsjson, attributes, date, attachements, featureLayerURL, disasterType, reportType, damageType, resourceType)  VALUES(:id, :pickListIndex, :size, :nameofitem, :editsjson, :attributes, :date, :attachements, :featureLayerURL, :disasterType, :reportType, :damageType, :resourceType);")

        insert_query.executePrepared({id:id, pickListIndex:pickListIndex, size:size, nameofitem:nameofitem, editsjson:JSON.stringify(finalJSONEdits), attributes:JSON.stringify(attributesArray), date:dateString, attachements:JSON.stringify(filePaths), featureLayerURL:featureLayerURL.toString(),  disasterType:disasterType, reportType:reportType, damageType:damageType, resourceType:resourceType});

        db.query("END TRANSACTION")

        isShowCustomText = false

        app.theFeatureEditingAllDone = true;
        app.theFeatureEditingSuccess = true;


    }

    SimpleMarkerSymbol {
        id: markerSymbol
    }
    SimpleLineSymbol {
        id: lineSymbol
    }
    SimpleFillSymbol{
        id: fillSymbol
    }

    MapView{
        id: mapView
    }


    function initializeFeatureService(errorcode, errormessage, root, cacheName){

        if(errorcode===0){
            var typeCheck = root.type;

            if(typeCheck == "Feature Layer"){
                var capabilities = root.capabilities+"";
                var geometryType = root.geometryType;
                if(geometryType === "esriGeometryPoint"){
                    captureType = "point";
                } else if(geometryType === "esriGeometryPolyline"){
                    captureType = "line";
                } else if(geometryType === "esriGeometryPolygon"){
                    captureType = "area";
                } else {
                    initializationCompleted = true;
                    featureServiceManager.clearCache(cacheName)

                    alertBox.text = qsTr("Unable to initialize - Invalid service.");
                    alertBox.informativeText = qsTr("Please make sure the ArcGIS feature service supports") + geometryType + ".";
                    alertBox.visible = true;
                }

                if(capabilities.indexOf("Create")>-1){
                    var fields = root.fields
                    for(var i=0;i<fields.length;i++){
                        //@@@f structure not right
                        if(fields[i].editable===true && fields[i].name!=root.typeIdField) {
                            var f = fields[i];
                            app.fields.push(f);
                            fieldsMassaged.push(f);
                        }
                    }

                    if(root.hasOwnProperty("templates") && root.templates.length > 0 && root.templates[0].hasOwnProperty("prototype")) app.templatesAttributes = root.templates[0].prototype.attributes;

                    var params = root.extent.spatialReference;

                    if ( root.typeIdField > ""){
                        hasSubtypes = true;
                        featureTypes = root.types;
                        app.typeIdField = root.typeIdField;
                    }else{
                        console.log("This service DOES NOT have a sub Type::");
                        initializationCompleted = true;
                    }

                    for ( var j = 0; j < fields.length; j++ ){
                        if(fields[j].editable===true){
                            var hasDomain = false;
                            var isRangeDomain = false;
                            if ( fields[j].domain !== null){
                                hasDomain = true;
                                if (fields[j].domain.objectType === "RangeDomain" ) {
                                    isRangeDomain = true
                                }
                            }

                            var isSubTypeField = false;
                            if ( fields[j].name === root.typeIdField ){
                                isSubTypeField = true;
                            }

                            var defaultFieldValue = 0;
                            theFeatureAttributesModel.append({"fieldIndex": j, "fieldName": fields[j].name, "fieldAlias": fields[j].alias, "fieldType": fields[j].fieldTypeString, "fieldValue": "", "defaultNumber": defaultFieldValue, "isSubTypeField": isSubTypeField, "hasSubTypeDomain" : false, "hasDomain": hasDomain, "isRangeDomain": isRangeDomain })
                        }
                    }

                    app.hasAttachment = root.hasAttachments;
                    console.log("app.hasAttachment", app.hasAttachment)

                    var rendererJson = root.drawingInfo;
                    var values;
                    if(rendererJson.renderer.uniqueValueInfos) {
                        values = rendererJson.renderer.uniqueValueInfos;
                        hasType = values.length>0;
                    } else {
                        values = [];
                        hasType = false;
                    }
                    var syms = [];

                    for(var i=0; i< values.length; i++) {
                        console.log("values[i].symbol",values[i].symbol)
                        if(values[i].symbol.imageData) {
                            syms.push({"data": "data:image/png;base64," + values[i].symbol.imageData, "type" :"imageData", "label": values[i].label, "value" : values[i].value.toString(), "description": values[i].description})
                            counts++;
                        } else if(values[i].symbol.type === "esriSMS") {
                            var sym = ArcGISRuntimeEnvironment.createObject("SimpleMarkerSymbol" ,{}, mapView);
                            sym.json = values[i].symbol;
                            syms.push({"data": sym, "type" :values[i].symbol.type, "label": values[i].label, "value" : values[i].value.toString(), "description": values[i].description})
                            counts++;
                        } else if(values[i].symbol.type === "esriSLS"){
                            var sym = ArcGISRuntimeEnvironment.createObject("SimpleLineSymbol" ,{}, mapView);
                            sym.json = values[i].symbol;
                            sym.width = sym.width*0.2
                            syms.push({"data": sym, "type" :values[i].symbol.type, "label": values[i].label, "value" : values[i].value.toString(), "description": values[i].description})
                            counts++;
                        } else if(values[i].symbol.type === "esriSFS"){
                            var sym = ArcGISRuntimeEnvironment.createObject("SimpleFillSymbol" ,{}, mapView);
                            sym.json = values[i].symbol;
                            syms.push({"data": sym, "type" :values[i].symbol.type, "label": values[i].label, "value" : values[i].value.toString(), "description": values[i].description})
                            counts++;
                        }
                    }

                    app.countsChanged.connect(function(){
                        if(counts==0) {
                            theFeatureTypesModel.clear();
                            datas.forEach(function(e){
                                if(e.type === "swatch"){
                                    theFeatureTypesModel.append({"label": e.label, "value" : e.value.toString(), "description": e.description, "imageUrl": Qt.resolvedUrl(e.data)});
                                    //                                    listModel.append({"sourceImg": Qt.resolvedUrl(e.data)});
                                } else {
                                    theFeatureTypesModel.append({"label": e.label, "value" : e.value.toString(), "description": e.description, "imageUrl": e.data});
                                    //                                    listModel.append({"sourceImg": e.data});
                                }
                            })
                            initializationCompleted = true;
                        }
                    });

                    syms.forEach(function(e, index){
                        if(e.type === "imageData"){
                            datas[index] = {"data": e.data, "index": index, "type": "imageData", "label": e.label, "value" : e.value.toString(), "description": e.description};
                            counts--;
                        } else {
                            e.data.swatchImageChanged.connect(function(){
                                console.log("e.data.swatchImage.toString()",e.data.swatchImage.toString())
                                datas[index] = {"data": e.data.swatchImage.toString(), "index": index, "type": "swatch", "label": e.label, "value" : e.value.toString(), "description": e.description};
                                counts--;
                            });
                            e.data.createSwatch();
                        }
                    });

                    if(app.isFromSaved) {
                        checkReadyForSubmitReport();
                        steps++
                        if(app.showSummary)
                        {
                            if(datas.length === 0)
                            {
                                syms.forEach(function(e, index){

                                    theFeatureTypesModel.append({"label": e.label, "value" : e.value.toString(), "description": e.description});

                                })
                            }
                            steps--;
                            populateSummaryObject()
                            stackView.push(summaryPage)
                        }
                        else
                        {
                            if(hasSubtypes)
                                stackView.showPickTypePage(false);
                                //stackView.showReportGallery();
                            else
                                stackView.showRefineLocationPage(false);
                        }
                    }

                    else
                    {
                        if(hasSubtypes)
                            stackView.showPickTypePage(false);
                            //stackView.showReportGallery();
                        else
                            stackView.showRefineLocationPage(false);
                    }
                }

                else {
                    initializationCompleted = true;
                    featureServiceManager.clearCache(cacheName)
                    alertBox.text = qsTr("Unable to initialize - Insufficient capability.");
                    alertBox.informativeText = qsTr("Please make sure the ArcGIS feature service is editable.");
                    alertBox.visible = true;
                }
            } else{
                initializationCompleted = true;
                featureServiceManager.clearCache(cacheName)
                alertBox.text = qsTr("Unable to initialize - Invalid service.");
                alertBox.informativeText = qsTr("Please make sure you have configured a valid ArcGIS feature service url.");
                alertBox.visible = true;
            }
        }
         else {
            initializationCompleted = true;
            if(errorcode===3){
                alertBox.text = qsTr("Unable to initialize - Network not available.")
                alertBox.informativeText = qsTr("Turn off airplane mode or use wifi to access data.");
                alertBox.visible = true;
            } else if(errorcode === 499){
                if(app.isNeedGenerateToken){
                    serverDialog.visible = true
                } else {
                    initializationCompleted = false;
                    featureServiceManager.token = app.token;
                    featureServiceManager.getSchema(null, null, app.initializeFeatureService)
                    app.isNeedGenerateToken = true;
                }
            }else{
                alertBox.text = qsTr("Sorry, something went wrong.")
                alertBox.informativeText = errorcode + " - " + errormessage;
                alertBox.visible = true;
            }
        }

    }

    FeatureServiceManager{
        id: featureServiceManager
    }

    MmpkManager{
        id: mmpkManager
        itemId: app.offlineMMPKID
    }

    ListModel {
        id: theFeatureTypesModel
    }

    ListModel {
        id: theFeatureAttributesModel
    }

    VisualItemModel  {
        id: theFeatureAttributesVisualModel
    }

    ListModel{
        id: savedReportsListModel
    }
    ListModel{
        id: savedReportsModel
    }
    property var savedReportsSectionModel: []

    //--------------------------------

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: landingPage

        function showLandingPage() {
            while (stackView.count > 0)
                stackView.pop()

            push(stackView.initialItem)
            clearData()
            steps = -1;
            updateSavedReportsCount()
        }

        function showDisasterType() {
            //steps++;
            push(disasterTypePage);
        }

        function showReportGallery() {
            //steps++;
            push(reportGalleryPage);
        }

        function showMapPage() {
            steps++;
            push(mapPage);
        }

        function showAddPhotoPage(flag) {
            if (flag === undefined) {
                flag = false;
            }
            steps++;
            if(isFromSaved){
                appModelCopy.clear();
                for(var i =0; i < appModel.count; i++){
                    appModelCopy.append(appModel.get(i));
                }
            }
            push(addPhotoPage)
        }

        function showRefineLocationPage(flag){
            steps++;
            push(refineLocationPage)
        }

        function showQueryLocationPage(){
            push(queryLocationPage)
        }

        function showAddDetailsPage(){
            steps++;
            attributesArrayCopy = JSON.parse(JSON.stringify(attributesArray));
            push(addDetailsPage)
        }

        function showResultsPage() {
            push(resultsPage)
        }

        function showPickTypePage(flag){
            if (flag === undefined) {
                flag = false;
            }
            steps++;
            stackView.push(pickTypePage)
        }

        function showDamageTypePage(){
            //steps++;
            push(damageTypePage)
        }
    }

    //--------------------------------
    function clearData(){
        captureType = "point";
        polylineObj = null;
        polygonObj = null;
        centerExtent = null;

        savedReportLocationJson = null;

        measureValue = 0;

        initializationCompleted = true
        fileListModel.clear();
        attributesArray = {}

        domainValueArray=[]
        domainCodeArray=[]

        subTypeCodeArray=[]
        subTypeValueArray=[]

        domainRangeArray=[]
        delegateTypeArray=[]

        protoTypesArray=[]
        protoTypesCodeArray=[]

        networkDomainsInfo = null

        hasSubtypes=false
        hasSubTypeDomain=false

        featureTypes=null
        featureType=null

        selectedFeatureType=null
        fields=[]
        fieldsMassaged=[]
        templatesAttributes = {}

        pickListIndex=-1

        hasAttachment = false
        isReadyForSubmit = false

        selectedImageFilePath = ""
        selectedImageFilePath_ORIG = ""
        selectedImageHasGeolocation = false
        currentAddedFeatures = []

        theFeatureToBeInsertedID = null
        theFeatureSucessfullyInsertedID = null
        theFeatureEditingAllDone = false
        theFeatureEditingSuccess = false
        theFeatureServiceWKID = -1

        skipPressed = false
    }

    //--------------------------------

    function initSavedReportsPage(){
        initSavedReportsData(-1)
        // changes on 2021-12-09;
        stackView.push(savedReportsPage);
    }

    function initSubmittedReportsPage(){
        // changes on 2021-12-11;
        stackView.push(queryLocationPage);
    }

    function initSavedReportsData(order, refreshSection){                   //order: -1 - last recent first; 1 - last recent last
        savedReportsListModel.clear();

        if(typeof refreshSection === "undefined" || refreshSection === null) refreshSection = true;

        if(refreshSection) savedReportsSectionModel = [];
        var queryString = "SELECT * FROM DRAFTS ORDER BY featureLayerURL ASC, date DESC,CAST(SUBSTR(nameofitem,6) AS INT) DESC";
        var select_query = db.query(queryString);

        db.query("BEGIN TRANSACTION")
        var i=0
        for(var ok = select_query.first(); ok; ok = select_query.next()) {
            var obj = select_query.values;

            var id = obj.id;
            var editsJson = obj.editsjson;
            var attributes = obj.attributes;
            var date = obj.date;
            var attachements = obj.attachements;
            var featureLayerURL = obj.featureLayerURL;
            var nameofitem = obj.nameofitem;
            nameofitem = (nameofitem === null? "Default Type": nameofitem)
            var size = obj.size;
            var pickListIndex = obj.pickListIndex;
            var xmax = JSON.parse(attributes)["_xMax"];
            var xmin = JSON.parse(attributes)["_xMin"];
            var ymax = JSON.parse(attributes)["_yMax"];
            var ymin = JSON.parse(attributes)["_yMin"];
            var realValue = JSON.parse(attributes)["_realValue"];
            var hasAttachments = JSON.parse(attributes)["hasAttachment"]===null? true:JSON.parse(attributes)["hasAttachment"];
            var isReady = JSON.parse(attributes)["isReadyForSubmit"]===null? true:JSON.parse(attributes)["isReadyForSubmit"];

            if(refreshSection) {
                if(typeof savedReportsSectionModel[featureLayerURL] !== "undefined" && savedReportsSectionModel[featureLayerURL] !== null) {
                    savedReportsSectionModel[featureLayerURL].count++;
                } else {
                    var json = featureServiceManager.getLocalSchema(featureLayerURL);
                    if(json)
                    {
                        var geometryType = json.geometryType;
                        var icon = ""
                        if(geometryType === "esriGeometryPoint"){
                            icon = "../images/point.png";
                        } else if(geometryType === "esriGeometryPolyline"){
                            icon = "../images/line.png";
                        } else if(geometryType === "esriGeometryPolygon"){
                            icon = "../images/polygon.png";
                        }

                        var name = json.name;
                        var description = ""
                        if(json.hasOwnProperty("description")) description = json.description;
                        savedReportsSectionModel[featureLayerURL] = {"count": 1, "sectionTitle": name, "sectionIcon": icon, "sectionVisible": true}
                    }
                }
            }
            var attach = JSON.parse(attachements)
            var an = 0
            attach.forEach(function(element){
                if(element !== null)
                    an = an + 1
            }
            )

            // changes on 2021-12-10
            var geometryDescription = JSON.parse(editsJson)[0]["geometryDescription"];

            var geometryLatLon = geometryDescription.split(" ");
            var latString = geometryLatLon[0];
            var lonString = geometryLatLon[1];

            // console.log(typeof latString, typeof lonString);

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

            var reportType = obj.reportType;
            var damageType = obj.damageType;
//            savedReportsListModel.append({id: id, attributes:attributes, pickListIndex: pickListIndex, draftFeatureLayerURL: featureLayerURL, attachements: attachements, editsJson: editsJson, name: "Report "+i, type: nameofitem, date: date, size: (size/1024/1024).toFixed(2), numberOfAttachment: an,
//                                             xmax:xmax, xmin:xmin, ymax:ymax, ymin:ymin, realValue:realValue, hasAttachments:hasAttachments, isReady:isReady})

            savedReportsListModel.append({id: id, attributes:attributes, pickListIndex: pickListIndex, draftFeatureLayerURL: featureLayerURL, attachements: attachements, editsJson: editsJson, name: "Report "+i, type: nameofitem, date: date, size: (size/1024/1024).toFixed(2), numberOfAttachment: an,
                                             xmax:xmax, xmin:xmin, ymax:ymax, ymin:ymin, realValue:realValue, hasAttachments:hasAttachments, isReady:isReady, lat: lat, lon: lon, reportType: reportType, damageType: damageType})

            // savedReportsListModel.append({id: id, attributes:attributes, pickListIndex: pickListIndex, draftFeatureLayerURL: featureLayerURL, attachements: attachements, editsJson: editsJson, name: "Report "+i, type: nameofitem, date: date, size: (size/1024/1024).toFixed(2), numberOfAttachment: JSON.parse(attachements).length,
            //                                  xmax:xmax, xmin:xmin, ymax:ymax, ymin:ymin, realValue:realValue, hasAttachments:hasAttachments, isReady:isReady})

            i = i+1
        }
        select_query.finish();

        db.query("END TRANSACTION")
    }

    Component {
        id: tempListModel
        ListModel {
        }
    }

    function reverseSavedReportData(){
        var t = tempListModel.createObject(parent);
        var count = savedReportsListModel.count;
        for (var i=0; i<count; i++){
            var obj = savedReportsListModel.get(count-i-1);
            t.append(obj);
        }
        savedReportsListModel.clear();
        for(var j=0;j<t.count;j++){
            savedReportsListModel.append(t.get(j));
        }
    }

    function deleteReportFromDatabase(){
        var delete_query1 = db.query();
        delete_query1.prepare("DELETE FROM DRAFTS WHERE id = :id;")
        db.query("BEGIN TRANSACTION");
        delete_query1.executePrepared({id: app.currentEditedSavedIndex});
        delete_query1.finish();
        db.query("END TRANSACTION");

    }

    function removeItemFromSavedReportPage(id, index, attachments){
        removeAttachments(attachments);
        var t = tempListModel.createObject(parent);
        var count = savedReportsListModel.count;
        for (var i=0; i<count; i++){
            var obj = savedReportsListModel.get(i);
            t.append(obj);
        }
        savedReportsListModel.clear();
        for(var j=0;j<t.count;j++){
            savedReportsListModel.append(t.get(j));
        }
        savedReportsListModel.remove(index)
        var delete_query1 = db.query();
        delete_query1.prepare("DELETE FROM DRAFTS WHERE id = :id;")
        db.query("BEGIN TRANSACTION");
        delete_query1.executePrepared({id: id});
        delete_query1.finish();
        db.query("END TRANSACTION");

        updateSavedReportsCount();
    }

    function removeAttachments(attachments){

        for(var i in attachments){
            try {
                var filePath = attachments[i].filePath
                if(filePath)
                {
                var attachmentFileInfo = AppFramework.fileInfo(filePath);
                var fileName = attachmentFileInfo.fileName;
                var fileFolder = attachmentFileInfo.folder
                if(fileFolder.fileExists(fileName)) fileFolder.removeFile(fileName);
                }
            } catch (e) {
                console.log("Error: failed to remove  file." + attachments[i]);
            }

        }
    }

    function deleteFeature(objectId) {
        featureServiceManager.deleteFeature(objectId, function(responseText){
            app.currentObjectId = -1;
        });
    }

    function removeAllSavedReport(){
        var allAttachments = [];
        var queryString = "SELECT * FROM DRAFTS";
        var select_query = db.query(queryString);
        db.query("BEGIN TRANSACTION")
        var i=0
        for(var ok = select_query.first(); ok; ok = select_query.next()) {
            var obj = select_query.values;
            var attachements = JSON.parse(obj.attachements);
            for(var j=0; j < attachements.length; j++){
                allAttachments.push(attachements[j]);
            }

        }
        var delete_query1 = db.query();
        delete_query1.prepare("DELETE FROM DRAFTS;")
        delete_query1.executePrepared();
        delete_query1.finish();
        db.query("END TRANSACTION");

        removeAttachments(allAttachments);
        savedReportsListModel.clear();
        savedReportsCount = 0;
    }

    function checkReadyForGeo(){
        var isValidGeo = false;

        try {
            if(captureType === "point"){
                if(app.savedReportLocationJson.x && app.savedReportLocationJson.y) isValidGeo = true;
            } else if(captureType === "line"){
                var path = app.savedReportLocationJson.paths[0];
                if(path){
                    var pathLength = path.length;
                    if(pathLength>=2) {
                        if(path[0][0] === path[1][0] && path[0][1] === path[1][1] && pathLength===2) isValidGeo = false;
                        else isValidGeo = true;
                    }
                }
            } else if(captureType === "area"){
                var ring = app.savedReportLocationJson.rings[0];
                if(ring){
                    var ringLength = ring.length;
                    if(ringLength>=4) isValidGeo = true
                }
            }
        } catch(e) {
            isValidGeo = false;
        }

        isReadyForGeo = isValidGeo;
        console.log("isReadyForGeo:::", isReadyForGeo);
        console.log("isReadyForSubmitReport:::", isReadyForSubmitReport);
        initGeometryForSavedReport();
    }

    function checkReadyForDetails(){
        isReadyForDetails = true;
        for(var i=0;i<fieldsMassaged.length;i++){
            var obj = fieldsMassaged[i]
            if(obj["nullable"]=== false){
                if ( attributesArray[obj["name"]] === "") {
                    isReadyForDetails = false;
                    break;
                }
            }
        }
    }

    function checkReadyForAttachments(){
        isReadyForAttachments = app.allowPhotoToSkip? true: (app.appModel.count>0);
    }

    function checkReadyForSubmitReport(){
        checkReadyForGeo();
        checkReadyForDetails();
        checkReadyForAttachments();
    }

    function initGeometryForSavedReport(){
        var t = app.savedReportLocationJson;
        if(app.isFromSaved && app.savedReportLocationJson) {
            //this report might have location saved and we should use that
            var x = 0.0;
            var y = 0.0;
            var spatialReferenceJson = app.savedReportLocationJson.spatialReference;
            console.log("spartialReferenceJson", JSON.stringify(spatialReferenceJson))
            var wkid = spatialReferenceJson.wkid;
            var spatialReference = ArcGISRuntimeEnvironment.createObject("SpatialReference", {wkid:wkid});
            console.log(wkid, spatialReference.wkid);
            if(captureType === "point"){
                x = app.savedReportLocationJson.x;
                y = app.savedReportLocationJson.y;

                if (x && y) {
                    app.theNewPoint = ArcGISRuntimeEnvironment.createObject("Point", {x: app.savedReportLocationJson.x, y: app.savedReportLocationJson.y, spatialReference:spatialReference});
                    console.log("inside point", JSON.stringify(theNewPoint.json));
                }

            } else if(captureType === "line"){
                var path = app.savedReportLocationJson.paths[0];
                var polylineBuilder = ArcGISRuntimeEnvironment.createObject("PolylineBuilder", {spatialReference:spatialReference})
                if(path){
                    var pathLength = path.length;
                    var firstPoint = true;

                    var part = ArcGISRuntimeEnvironment.createObject("Part");
                    part.spatialReference = spatialReference;

                    for(var i=0; i< pathLength; i++){
                        part.addPointXY(path[i][0], path[i][1]);
                    }

                    var pCollection = ArcGISRuntimeEnvironment.createObject("PartCollection");
                    pCollection.spatialReference = spatialReference;
                    pCollection.addPart(part);
                    polylineBuilder.parts = pCollection;

                    console.log(JSON.stringify(polylineBuilder.geometry.json));
                    polylineObj = polylineBuilder.geometry;
                }

            } else if(captureType === "area"){
                var ring = app.savedReportLocationJson.rings[0];
                var polygonBuilder = ArcGISRuntimeEnvironment.createObject("PolygonBuilder", {spatialReference:spatialReference})
                if(ring){
                    var ringLength = ring.length;

                    var part2 = ArcGISRuntimeEnvironment.createObject("Part");
                    part2.spatialReference = spatialReference;

                    for(var j=0; j< ringLength-1; j++){
                        part2.addPointXY(ring[j][0], ring[j][1]);
                    }
                    var pCollection2 = ArcGISRuntimeEnvironment.createObject("PartCollection");
                    pCollection2.spatialReference = spatialReference;
                    pCollection2.addPart(part2);
                    polygonBuilder.parts = pCollection2;
                    polygonObj = polygonBuilder.geometry;
                }
            }
        }
    }

    //--------------------------------

    Component {
        id: landingPage

        LandingPage {
            onNext: {
                switch(message) {
                case "viewmap": stackView.showMapPage(); break;
                case "createnew": if(app.hasAttachment) {
                        stackView.showAddPhotoPage();
                        break;
                    } else {
                        stackView.showRefineLocationPage();
                        break;
                    }
                case "details" : stackView.showAddDetailsPage();break;
                }
            }
        }
    }

    //--------------------------------------------------------------------------
    Component {
        id: disclamerPage

        DisclamerPage {

        }
    }

    //--------------------------------------------------------------------------
    Component {
        id: disasterTypePage

        DisasterTypePage {
            onPrevious: {
                stackView.pop()
            }

            onNext: {
                stackView.showReportGallery();
            }
        }
    }

    //--------------------------------------------------------------------------
    Component {
        id: reportGalleryPage

        ReportGalleryPage {
            onPrevious: {
                stackView.pop()
            }

            onNext: {
                stackView.showDamageTypePage();
            }
        }
    }

    //--------------------------------------------------------------------------
    Component {
        id: damageTypePage

        DamageTypePage {
            onPrevious: {
                stackView.pop()
            }

            onNext: {
                stackView.showRefineLocationPage();
            }
        }
    }

    //--------------------------------------------------------------------------
    Component {
        id: addPhotoPage
        AddPhotoPage {
            onNext: {
                stackView.showAddDetailsPage();
            }
            onPrevious: {
                stackView.pop();
                var stackitem = stackView.get(stackView.depth - 1)
                if(stackitem.objectName !== "summaryPage")
                {

                    var attachments = [];
                    for(var i=0; i<appModel.count; i++){
                        temp = app.appModel.get(i).path;
                        app.selectedImageFilePath = AppFramework.resolvedPath(temp);
                        attachments.push(app.selectedImageFilePath);
                    }
                    if(!app.isFromSaved) {
                        removeAttachments(attachments);
                        appModel.clear();
                    } else {
                        appModel.clear();
                        for(var i =0; i < appModelCopy.count; i++){
                            appModel.append(appModelCopy.get(i))
                        }
                    }
                    if(app.isFromSaved)
                    {
                        checkReadyForAttachments();

                    }
                }
                else
                {
                    checkReadyForAttachments();
                    if(!isReadyForAttachments)
                        app.hasAllRequired = false
                    app.populateSummaryObject()
                }

            }
        }
    }
    //--------------------------------------------------------------------------
    Component {
        id: refineLocationPage
        RefineLocationPage {
            onNext: {
                reloadMapTimer.stop();
                if(app.hasAttachment) {
                    stackView.showAddPhotoPage(false);
                } else {
                    stackView.showAddDetailsPage();
                }
            }
            onPrevious: {
                app.isReadyForGeo = storedReadyForGeo;
                reloadMapTimer.stop();
                stackView.pop();
                //                if(app.isFromSaved)checkReadyForGeo();
            }
        }
    }

    //--------------------------------------------------------------------------
    Component {
        id: queryLocationPage
        QueryLocationPage {
            onPrevious: {
                app.isReadyForGeo = storedReadyForGeo;
                // reloadMapTimer.stop();
                stackView.pop();
            }
        }
    }

    //--------------------------------------------------------------------------
    Component {
        id: pickTypePage
        PickTypePage {
            onNext: {
                console.log("isReadyForSubmitReport:::", isReadyForSubmitReport);
                // stackView.showRefineLocationPage(false);
                stackView.showReportGallery();
            }
            onPrevious: {
                stackView.pop();
            }
        }
    }

    //--------------------------------------------------------------------------
    property alias addDetailsPage: addDetailsPage
    Component {
        id: addDetailsPage
        AddDetailsPage {
            onNext: {
                if(message=="submit"){
                    submitReport()
                }
                else if(message === "showSummary")
                {
                    populateSummaryObject()
                    stackView.push(summaryPage)
                }
                else{
                    draftSaveDialog.visible = true;
                }
            }
            onPrevious: {
                stackView.pop();
                var stackitem = stackView.get(stackView.depth - 1)
                if(stackitem.objectName !== "summaryPage")
                {
                    attributesArray = JSON.parse(JSON.stringify(attributesArrayCopy));
                    if(app.isFromSaved)checkReadyForDetails();
                }
            }
        }
    }

    Component {
        id: summaryPage
        SummaryPage {

            onShowNext: {
                if(message === app.type)               // disaster type: storm / hurricane / landslide / flood
                    stackView.push(pickTypePage)
                else if (message === app.reportType)   // report type: damage / request / donation
                    stackView.push(reportGalleryPage)
                else if(message === app.damageType)    // damage type: casualties / buildings / roads / others
                    stackView.push(damageTypePage)
                //else if(message === app.resourceType)    // resource type: ...
                    //stackView.push(ResourceTypePage)
                else if(message === app.location)
                    stackView.push(refineLocationPage)
                else if (message === app.media)
                    stackView.push(addPhotoPage)
                else if(message === app.details)
                    stackView.push(addDetailsPage)


            }

            onPrevious: {
                stackView.pop();
            }
            onNext:{
                if(message=="submit"){
                    submitReport()
                }
                else{
                    draftSaveDialog.visible = true;
                }

            }
        }
    }
    //--------------------------------------------------------------------------
    Component {
        id: resultsPage
        ResultsPage {
            onNext: {
                stackView.showLandingPage()
            }
            onPrevious: {
                stackView.pop();
            }
        }
    }
    //--------------------------------------------------------------------------
    Component {
        id: savedReportsPage

        SavedReportsPage {
            onPrevious: {
                stackView.pop()
            }
        }
    }

    //--------------------------------------------------------------------------

    BrowserView {
        id: browserView
        z: 10000
        anchors.fill: parent
        primaryColor: app.headerBackgroundColor
        foregroundColor: "white"
    }

    function generateFeedbackEmailLink() {
        var urlInfo = AppFramework.urlInfo("mailto:%1".arg(emailAddress)),
        deviceDetails = [
                    "%1: %2 (%3)".arg(qsTr("Device OS")).arg(Qt.platform.os).arg(AppFramework.osVersion),
                    "%1: %2".arg(qsTr("Device Locale")).arg(Qt.locale().name),
                    "%1: %2".arg(qsTr("App Version")).arg(app.info.version),
                    "%1: %2".arg(qsTr("AppStudio Version")).arg(AppFramework.version),
                ];
        urlInfo.queryParameters = {
            "subject": "%1 %2".arg(qsTr("Feedback for")).arg(app.info.title),
            "body": "\n\n%1".arg(deviceDetails.join("\n"))
        };
        return urlInfo.url
    }

    function openWebView(mode, obj) {

        browserView.url = obj.url;
        browserView.show();

    }


    function validURL(str) {
        var regex = /(http|https):\/\/(\w+:{0,1}\w*)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%!\-\/]))?/;

        if(!regex .test(str)) {
            return false;
        } else {
            return true;
        }
    }

    Component{
           id: webPageComponent
           WebPage {
               id: webPage
               headerColor: app.headerBackgroundColor

               function generateFeedbackEmailLink() {
                   var urlInfo = AppFramework.urlInfo("mailto:%1".arg(emailAddress)),
                   deviceDetails = [
                               "%1: %2 (%3)".arg(qsTr("Device OS")).arg(Qt.platform.os).arg(AppFramework.osVersion),
                               "%1: %2".arg(qsTr("Device Locale")).arg(Qt.locale().name),
                               "%1: %2".arg(qsTr("App Version")).arg(app.info.version),
                               "%1: %2".arg(qsTr("AppStudio Version")).arg(AppFramework.version),
                           ];
                   urlInfo.queryParameters = {
                       "subject": "%1 %2".arg(qsTr("Feedback for")).arg(app.info.title),
                       "body": "\n\n%1".arg(deviceDetails.join("\n"))
                   };
                   return urlInfo.url
               }

               function openWebURL(link, title) {
                   webPage.titleText = title
                   webPage.transitionIn(webPage.transition.bottomUp)
                   webPage.loadPage(link)
               }

               function openSectionID(link) {
                   var pageURL
                   if (validURL(helpPageUrl)) {
                       pageURL = helpPageUrl+"#"+link
                       webPage.transitionIn(webPage.transition.bottomUp)
                       webPage.loadPage(pageURL)
                   } else {
                       webPage.transitionIn(webPage.transition.bottomUp)
                       webPage.loadLocalHtml(link)
                   }

               }

               function validURL(str) {
                   var regex = /(http|https):\/\/(\w+:{0,1}\w*)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%!\-\/]))?/;
                   if(!regex .test(str)) {
                       return false;
                   } else {
                       return true;
                   }
               }
           }
       }



    ListModel {
        id: footerModel

        Component.onCompleted: {
            footerModel.append({"name": "About", "type": "about", "value": "", icon:"../images/ic_info_outline_white_48dp.png"})
            footerModel.append({"name": "Settings", "type": "settings", "value": "", icon:"../images/ic_settings_white_48dp.png"})
        }
    }

    function init() {
        initializationCompleted = false;
        fieldsMassaged = [];
        templatesAttributes = {};
        theFeatureAttributesModel.clear();
        theFeatureTypesModel.clear();
        protoTypesArray = [];
        datas = [];
        featureServiceManager.token = ""
        app.isNeedGenerateToken = false;

        featureServiceManager.url = app.featureLayerURL;
        featureServiceManager.getSchema(null, null, app.initializeFeatureService)

        skipPressed = false;
    }

    function getAllSchemas() {
        featureServiceManager.getAllSchemas(app.featureServiceURL, app.featureLayerId, function() {
            if (app.isDisclamerMessageAvailable && (!app.isFromSaved) && (!app.hasDisclamerMessageShown)) {
                app.hasDisclamerMessageShown = true
                stackView.push(disclamerPage)
            } else {
                if(featureLayerId.length === 1) {
                    app.featureLayerURL = featureServiceURL + "/" + featureLayerId[0];
                    app.init();
                } else {
                    // stackView.showDisasterType();
                    stackView.showPickTypePage();
                }
                // stackView.showDisasterType();
                // stackView.showPickTypePage();
            }
        }, function(errorCode, errormessage) {
            console.log(errorCode)
            if(errorCode===3){
                alertBox.text = qsTr("Unable to initialize - Network not available.")
                alertBox.informativeText = qsTr("Turn off airplane mode or use wifi to access data.");
                alertBox.visible = true;
            } else if(errorCode === 499){
                if(app.isNeedGenerateToken){
                    serverDialog.visible = true
                } else {
                    initializationCompleted = false;
                    featureServiceManager.token = app.token;
                    app.getAllSchemas();
                    app.isNeedGenerateToken = true;
                }
            }else{
                alertBox.text = qsTr("Sorry, something went wrong.")
                alertBox.informativeText = errorCode + " - " + errormessage;
                alertBox.visible = true;
            }
        })
    }

    ServerDialog {
        id: serverDialog

        property bool isReportSubmit: false
        property var submitFunction

        onAccepted: {
            handleGenerateToken();
        }

        function handleGenerateToken(){
            featureServiceManager.generateToken(username, password, function(errorcode, message, details, token, expires){
                if(errorcode===0){
                    app.token = token;
                    app.expiration = expires;
                    app.settings.setValue("token",token);
                    app.settings.setValue("expiration", expires);
                    if(isReportSubmit){
                        serverDialog.visible = false;
                        submitFunction();
                    } else{
                        initializationCompleted = false;
                        app.settings.setValue("username", rot13(username));
                        app.settings.setValue("password", rot13(password));
                        clearData();
                        app.getAllSchemas();
                    }

                    serverDialog.isReportSubmit = false;

                } else{
                    serverDialog.errorDetails = details
                    serverDialog.errorMessage = message
                    serverDialog.visible = true;
                }
                serverDialog.busy = false;
            })
        }

    }

    AboutPage {
        id: aboutPage
    }

    SettingsPage {
        id: settingsPage
    }

    ConfirmBox{
        id: confirmBox
        anchors.fill: parent
    }

    ConfirmBox{
        id: alertBox
        anchors.fill: parent
        standardButtons: StandardButton.Ok
    }

    SaveDialog{
        id: draftSaveDialog
        anchors.fill: parent
        onAccepted: {
            saveReport();
            stackView.showLandingPage();
        }
    }

    ToastDialog {
        id: toastMessage
        // textColor: app.titleTextColor
    }


    Component {
        id: calendarDialogComponent
        CalendarDialog{
            property var attributesId

            primaryColor: app.headerBackgroundColor
            theme: app.isDarkMode? MaterialStyle.Material.Dark : MaterialStyle.Material.Light

            width: app.width*0.8
            height: Math.min(app.height*0.8, 400)
            x: (app.width - width)/2
            y: (app.height - height)/2
            visible: false
            padding: 0
            topPadding: 0
            bottomPadding: 0
            closePolicy: Popup.CloseOnEscape
        }
    }


    //Workaround for permissions

    PositionSource {
        id: permission_positionSource
    }

    ConfirmBox {
        id: locationAccessDialog
        text: locationAccessDisabledTitle
        informativeText: locationAccessDisabledMessage
        standardButtons: StandardButton.Ok

        property bool flag: false

        onClickOK: {
            if (flag === undefined) {
                flag = false;
            }
            steps++;
            stackView.push(refineLocationPage)

        }
    }
}
