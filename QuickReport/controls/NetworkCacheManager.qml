import QtQuick 2.7
import QtQuick.Controls 2.2

import ArcGIS.AppFramework 1.0

Item {
    id: networkCacheManager

    property string subFolder: ""
    property string returnType



    FileFolder{
        id: fileFolder
        readonly property url storageBasePath: AppFramework.userHomeFolder.fileUrl("ArcGIS/AppStudio/"+ app.itemId +"/Data/cache")
        property url storagePath: subFolder&&subFolder>"" ? storageBasePath + "/" + subFolder : storageBasePath
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

    function cache(url, alias, callback){

        if(!(alias>"")) alias = url;
        var result = url
        var cacheName = Qt.md5(alias)

        console.log("**** NM:cache :: for  ", url, alias, cacheName)

        if(!fileFolder.fileExists(cacheName)){
            console.log("**** NM:cache :: no cache, creating new ...");
            var component = networkRequestComponent;
            var networkRequest = component.createObject(parent);
            networkRequest.downloadImage(url, {} , cacheName, fileFolder.path, callback);
        } else{
            var cacheUrl = [fileFolder.url, cacheName].join("/");
            console.log("####cacheUrl####", cacheUrl);
            result = cacheUrl;
        }

        return result;
    }

    function clearAllCache(){
        var names = fileFolder.fileNames();
        console.log("**** NM:clearAllCache :: Total files ", names.length)
        for(var i=0; i<names.length; i++){
            var success = fileFolder.removeFile(names[i]);
            console.log("**** NM:clearAllCache :: Removing file ", names[i], success)
        }
    }

    function isCached(alias){
        var name = Qt.md5(alias);
        console.log("**** NM: isCached : ", alias)
        return fileFolder.fileExists(name);
    }

    function clearCache(alias){
        var name = Qt.md5(alias);
        return fileFolder.removeFile(name);
    }

    function deleteCacheName(cacheName){
        return fileFolder.removeFile(cacheName);
    }

    function refreshCache(url, alias, callback){
        if(!(alias>"")) alias = url;
        if(isCached(alias)){
            clearCache(alias);
        }
        console.log("**** NM: url : ", url);
        if(callback) {
            cache(url, alias, callback);
        } else {
            return cache(url,alias);
        }
    }

    function cacheJson(url, obj, alias, callback){
        if(!(alias>"")) alias = url;
        var cacheName = Qt.md5(alias)

        console.log("**** NM:cache :: for  ", url, alias, cacheName)

        if(!fileFolder.fileExists(cacheName)){
            console.log("**** NM:cache :: no cache, creating new ...");
            var component = networkRequestComponent;
            var networkRequest = component.createObject(parent);
            networkRequest.downloadImage(url, obj, cacheName, fileFolder.path, callback);
        } else{
            var cacheUrl = [fileFolder.url, cacheName].join("/");
            console.log("####cacheUrl####", cacheUrl);
            var result = fileFolder.readTextFile(cacheName);
            callback(0, "");
        }
    }

    function readLocalJson(cacheName){
        var result = fileFolder.readTextFile(cacheName);

        return result;
    }


    Component{
        id: networkRequestComponent
        NetworkRequest{
            id: networkRequest

            property string name;
            property var callback;

            responseType: networkCacheManager.returnType
            method: "POST"
            ignoreSslErrors: true

            onReadyStateChanged: {
                var fileName = name;
                if (readyState === NetworkRequest.DONE ){
                    console.log("####error####", errorCode);
                    if(errorCode != 0){
                        fileFolder.removeFile(networkRequest.name);
                        callback(errorCode, errorText);
                    } else{
                        console.log("**** NM: download successful", networkRequest.name, fileName);
                        var json = fileFolder.readJsonFile(networkRequest.name);
                        if(json.error!=null){
                            var code = json.error.code;
                            var message = json.error.message;
                            fileFolder.removeFile(networkRequest.name);
                            callback(code, message);
                        } else{
                            if(callback!=null){
                                callback(0, "");
                            }
                        }
                    }
                }
            }

            function downloadImage(url, obj, name, fileFolderPath, callback) {
                networkRequest.url = url;
                networkRequest.callback = callback;
                console.log("####PATH####", name)
                networkRequest.name = name;
                networkRequest.responsePath = [fileFolderPath, name].join("/");
                networkRequest.send(obj);
            }
        }
    }
}
