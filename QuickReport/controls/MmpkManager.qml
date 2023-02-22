import QtQuick 2.7
import QtQuick.Controls 2.2

import ArcGIS.AppFramework 1.0

Item {
    id: mmpkManager
    property string itemId: ""
    property string rootUrl: "http://www.arcgis.com/sharing/rest/content/items/"
    property string itemName: itemId > "" ? "%1.mmpk".arg(itemId) : ""
    property url fileUrl: [fileFolder.url, itemName].join("/")
    property string subFolder: "Offline"
    property int loadStatus: -1 //unknow = -1, loaded = 0, loading = 1, failed to load = 2
    property bool offlineMapExist: hasOfflineMap()
    property bool isPubished: false

    FileFolder{
        id: fileFolder
        readonly property url storageBasePath: AppFramework.userHomeFolder.fileUrl("ArcGIS/AppStudio/"+ app.itemId +"/Data")
        property url storagePath: subFolder && subFolder>"" ? storageBasePath + "/" + subFolder : storageBasePath
        url: storagePath
        Component.onCompleted: {
            if(!fileFolder.exists){
                fileFolder.makeFolder(storagePath);
            }
            if(!fileFolder.fileExists(".nomedia") && Qt.platform.os === "android"){
                fileFolder.writeFile(".nomedia", "");
            }
        }
    }

    Component.onCompleted: {
        var oldMmpkExists = fileFolder.fileExists(itemId);
        if (oldMmpkExists) {
            fileFolder.renameFile(itemId, "%1.mmpk".arg(itemId))
        }

        // clean dirty mmpk on windows
        if(Qt.platform.os === "windows") {
            var dirtyItemId = app.settings.value("mmpkManageDirtyItemId", "")
            var dirtyItemName = dirtyItemId > "" ? "%1.mmpk".arg(dirtyItemId) : ""

            if(fileFolder.fileExists("~"+dirtyItemName))fileFolder.removeFile("~"+dirtyItemName);
            if(fileFolder.fileExists(dirtyItemName))fileFolder.removeFile(dirtyItemName);

            app.settings.remove("mmpkManageDirtyItemId")
        }

        checkOfflineMapTags()
        hasOfflineMap()
    }

    function downloadOfflineMap(callback){
        if(itemId>""){
            if(Qt.platform.os === "windows" && fileFolder.fileExists(itemName)) {
                app.settings.remove("mmpkManageDirtyItemId");
                hasOfflineMap();
                callback();
                return;
            }

            var component = typeNetworkRequestComponent;
            var networkRequest = component.createObject(parent);
            var url = rootUrl+itemId+"?f=json";
            networkRequest.checkType(url, callback);
        }
    }

    function updateOfflineMap(callback){
        if(itemId>""){
            downloadOfflineMap(callback);
        }
    }

    function hasOfflineMap(){
        var dirtyItemId = app.settings.value("mmpkManageDirtyItemId", "")
        var dirtyItemName = dirtyItemId > "" ? "%1.mmpk".arg(dirtyItemId) : ""

        var offlineMMPKFileExist = fileFolder.fileExists(itemName);
        offlineMapExist = Qt.platform.os === "windows" ? (offlineMMPKFileExist && (dirtyItemName !== itemName)) : offlineMMPKFileExist
        return offlineMapExist;
    }

    function deleteOfflineMap(){
        if(fileFolder.fileExists("~"+itemName))fileFolder.removeFile("~"+itemName);
        if(fileFolder.fileExists(itemName))fileFolder.removeFile(itemName);
        hasOfflineMap();

        if(Qt.platform.os === "windows" && fileFolder.fileExists(itemName)) {
            app.settings.setValue("mmpkManageDirtyItemId", itemId);
            hasOfflineMap()
        }
    }

    function checkOfflineMapTags(){
        var component = checkMmpkTagsRequestComponent;
        var networkRequest = component.createObject(parent);
        networkRequest.url = rootUrl + "%1?f=json".arg(itemId);
        networkRequest.send();
    }

    Component {
        id: checkMmpkTagsRequestComponent
        NetworkRequest {
            id: checkMmpkTags
            responseType: "json"
            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE) {
                    if (response.hasOwnProperty("typeKeywords"))
                        isPubished = (response.typeKeywords.indexOf("Published Map") !== -1);
                }
            }
        }
    }

    Component{
        id: typeNetworkRequestComponent
        NetworkRequest{
            id: typeNetworkRequest

            property var callback

            method: "GET"
            ignoreSslErrors: true

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){
                    if(errorCode != 0){
                        loadStatus = 2;
                    } else {
                        var root = JSON.parse(responseText);
                        if(root.type == "Mobile Map Package"){
                            loadStatus = 1;
                            var component = networkRequestComponent;
                            var networkRequest = component.createObject(parent);
                            var url = rootUrl+itemId+"/data";
                            var path = [fileFolder.path, "~"+itemName].join("/");
                            networkRequest.downloadFile("~"+itemName, url, path, typeNetworkRequest.callback);
                        } else {
                            loadStatus = 2;
                        }
                    }
                }
            }

            function checkType(url, callback){
                typeNetworkRequest.url = url;
                typeNetworkRequest.callback = callback;
                typeNetworkRequest.send();
                loadStatus = 1;
            }
        }
    }

    Component{
        id: networkRequestComponent
        NetworkRequest{
            id: networkRequest

            property var name;
            property var callback;

            method: "GET"
            ignoreSslErrors: true

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){
                    if(errorCode != 0){
                        fileFolder.removeFile(networkRequest.name);
                        loadStatus = 2;
                    } else {
                        loadStatus = 0;
                        if(hasOfflineMap()) fileFolder.removeFile(itemId);
                        fileFolder.renameFile(name, itemName);
                        hasOfflineMap();
                        callback();
                    }
                }
            }

            function downloadFile(name, url, path, callback){
                networkRequest.name = name;
                networkRequest.url = url;
                networkRequest.responsePath = path;
                networkRequest.callback = callback;
                networkRequest.send();
                loadStatus = 1;
            }
        }
    }
}
