import QtQuick 2.7
import QtQuick.Controls 2.2

import ArcGIS.AppFramework 1.0

Item {
    id: featureServiceManager

    property url url
    property string token
    property var jsonSchema

    property int threadCounter: 0

    NetworkCacheManager{
        id: networkCacheManager
        returnType: "text"
    }

    function initialize(){
        getSchema(featureServiceManager.url, featureServiceManager.token)
    }

    function checkFeatureService(featureServiceURL, token, callback, params) {
        var obj = {"f": "json"};
        if(typeof token !== "undefined" && token !== null) obj.token = token;
        makeNetworkConnection(featureServiceURL, obj, callback, params);
    }

    function getAllSchemas(featureServiceURL, featureLayerIds, callback, fallback) {
        var params = {
            "callback": callback,
            "fallback": fallback,
            "featureLayerIds": featureLayerIds
        }

        var numOfCashedFeatureLayer = 0;

        for(var i in featureLayerIds) {
            var schemaURL = featureServiceURL + "/" + featureLayerIds[i];
            if(networkCacheManager.isCached(schemaURL)) numOfCashedFeatureLayer++;
        }

        if(numOfCashedFeatureLayer === featureLayerIds.length) {
            callback();
            return;
        }

        checkFeatureService(app.featureServiceURL, app.token, function(responseText, functions, errorCode, errorMessage) {
            if(errorCode === 0 && threadCounter === 0) {
                // download all feature layer schema
                threadCounter = functions.featureLayerIds.length;
                for(var i in functions.featureLayerIds) {
                    var schemaURL = featureServiceURL + "/" + functions.featureLayerIds[i];
                    featureServiceManager.getSchema(schemaURL, featureServiceManager.token, function(){
                        threadCounter--;
                    })
                }
                featureServiceManager.threadCounterChanged.connect(function(){
                    if(threadCounter === 0) {
                        functions.callback();
                    }
                })

            } else {
                functions.fallback(errorCode, errorMessage);
            }
        }, params)
    }

    function getSchema(url, token, callback){
        if(typeof url !== "undefined"&& url !== null)featureServiceManager.url = url;
        if(typeof token !== "undefined"&& token !== null)featureServiceManager.token = token;

        var targetUrl = featureServiceManager.url
        var alias = targetUrl;
        var obj = {"f": "json"}
        if(typeof token !== "undefined"&& token !== null) obj.token = token;

        console.log("targetUrl", targetUrl);

        networkCacheManager.cacheJson(targetUrl, obj, alias, function(errorCode, errorMsg){
            if(errorCode === 0){
                var cacheName = Qt.md5(alias);
                console.log("cacheName", cacheName);
                var temp = networkCacheManager.readLocalJson(cacheName);
                jsonSchema = JSON.parse(temp)
                if(jsonSchema.hasOwnProperty("supportsAttachmentsByUploadId") && jsonSchema["supportsAttachmentsByUploadId"] === true && jsonSchema["globalIdField"]>"")
                    app.useGlobalIDForEditing = true
                callback(0,errorMsg,jsonSchema, cacheName);
            }else{
                console.log("FSM::NM::Error:", errorCode);
                callback(errorCode, errorMsg, null ,cacheName)
            }
        })
    }

    function getLocalSchema(feautreLayerURL) {
        var cacheName = Qt.md5(feautreLayerURL);
        var localJson = networkCacheManager.readLocalJson(cacheName)
        if(localJson)
        {
            var jsonObj = JSON.parse(localJson)
            if(jsonObj.hasOwnProperty("supportsAttachmentsByUploadId") && jsonObj["supportsAttachmentsByUploadId"] === true && jsonObj["globalIdField"] > "" )
                app.useGlobalIDForEditing = true


            return JSON.parse(localJson)
        }
        else
            return null

    }

    function clearCache(cacheName){
        networkCacheManager.deleteCacheName(cacheName);
    }

    function clearAllCache() {
        for(var i in app.featureLayerId) {
            var targetUrl = featureServiceURL + "/" + featureLayerId[i];
            var cacheName = Qt.md5(targetUrl);
            featureServiceManager.clearCache(cacheName);
        }
    }
    function sendEmail(body)
    {
        var component = emailHandlerRequestComponent;
        var networkRequest = component.createObject(parent);
        networkRequest.sendEmail(body)
    }

    function getCurrentDateTime()
    {
        var currentdate =  new Date().toLocaleString();

        return currentdate

    }

    function uploadAttachment(filePath, featureglobalId, callback, cacheI)
    {
       // console.log("globalId::" + featureglobalId)
        var targetUrl = app.featureServiceURL+"/uploads/upload";
        var component = uploadAttachmentNetworkRequestComponent;
        var uploadAttachmentNetworkRequest = component.createObject(parent);
        uploadAttachmentNetworkRequest.url = targetUrl;
        uploadAttachmentNetworkRequest.callback = callback;
        uploadAttachmentNetworkRequest.cacheI = cacheI

        var obj = {"file": "@"+filePath,
            "f": "json"};


        if(typeof token !== "undefined"&& token !== null && token!=="") obj.token = token;
        uploadAttachmentNetworkRequest.send(obj);
    }
    function applyEditsUsingAttachmentFirst(obj, callback){
       // console.log("token when edits", token)
//        var obj = {"adds": JSON.stringify(attributes),
//            "f": "json"};


        var targetUrl = url+"/applyEdits";
        if(typeof token !== "undefined"&& token !== null && token!=="") obj.token = token;
        var component = applyEditsNetworkRequestComponent;
        var applyEditsNetworkRequest = component.createObject(parent);
        applyEditsNetworkRequest.url = targetUrl;
        applyEditsNetworkRequest.callback = function(errorcode, objectId){
            if(errorcode === 0){

                console.log("objectId", objectId);
                callback(objectId, 0)
            } else if(errorcode===498 || errorcode===499){
                callback(objectId,-498);
            } else{
                callback(objectId,-1);
            }
        }
        applyEditsNetworkRequest.send(obj);
    }

    function applyEditsUsingFeatureFirst(attributes, callback){
        console.log("token when edits", token)
        var obj = {"adds": JSON.stringify(attributes),
            "f": "json"};


        var targetUrl = url+"/applyEdits";
        if(typeof token !== "undefined"&& token !== null && token!=="") obj.token = token;
        var component = applyEditsNetworkRequestComponent;
        var applyEditsNetworkRequest = component.createObject(parent);
        applyEditsNetworkRequest.url = targetUrl;
        applyEditsNetworkRequest.callback = function(errorcode, objectId){
            if(errorcode === 0){

                console.log("objectId", objectId);
                callback(objectId, 0)
            } else if(errorcode===498 || errorcode===499){
                callback(objectId,-498);
            } else{
                callback(objectId,-1);
            }
        }
        applyEditsNetworkRequest.send(obj);
    }

    function addAttachment(filePath, objectId, callback, cacheI){
        console.log("objectId::" + objectId)
        var targetUrl = url+"/"+objectId+"/addAttachment";
        var component = addAttachmentNetworkRequestComponent;
        var addAttachmentNetworkRequest = component.createObject(parent);
        addAttachmentNetworkRequest.url = targetUrl;
        addAttachmentNetworkRequest.callback = callback;
        addAttachmentNetworkRequest.cacheI = cacheI

        var obj = {"attachment": "@"+filePath,
            "f": "json"};


        if(typeof token !== "undefined"&& token !== null && token!=="") obj.token = token;
        addAttachmentNetworkRequest.send(obj);
    }

    function deleteFeature(objectId, callback) {
        try {
            var targetUrl = url+"/deleteFeatures";

            var obj = {"objectIds": objectId,
                "f": "json"};
            if(typeof token !== "undefined"&& token !== null && token!=="") obj.token = token;

            var component = deleteFeaturesNetworkRequestComponent;
            var deleteFeaturesNetworkRequest = component.createObject(parent);
            deleteFeaturesNetworkRequest.url = targetUrl;
            deleteFeaturesNetworkRequest.callback = callback;
            deleteFeaturesNetworkRequest.send(obj);
        } catch (e) {
            console.log("Failed to delete feature: " + objectId);
        }
    }

    function generateToken(username, password, callback){
        featureServiceManager.getServiceInfo(function(errorcode, message, details, tokenUrl){
            if(errorcode===0){
                var component = generateTokenNetworkRequestComponent;
                var generateTokenNetworkRequest = component.createObject(parent);
                var targetUrl = tokenUrl
                console.log("targetUrl:::", targetUrl)
                generateTokenNetworkRequest.url = targetUrl;
                generateTokenNetworkRequest.callback = callback;
                var obj = {"username":username, "password":password, "f":"json", referer: "http://www.arcgis.com"/*, expiration:"1"*/};
                generateTokenNetworkRequest.send(obj);
            }
        })
    }

    function getServiceInfo(callback){
        var arr = app.featureServiceURL.toString().split("/rest/");

        if(arr.length>0){
            var targetUrl = arr[0]+"/rest/info";
            console.log("info url", targetUrl)
            var component = getServiceInfoNetworkRequestComponent;
            var getServiceInfoNetworkRequest = component.createObject(parent);
            getServiceInfoNetworkRequest.url = targetUrl;
            var obj = {"f":"json"};
            getServiceInfoNetworkRequest.callback = callback;
            getServiceInfoNetworkRequest.send(obj);
        }
    }

    Component{
        id: applyEditsNetworkRequestComponent
        NetworkRequest{
            id: applyEditsNetworkRequest

            property var callback;

            responseType: "text"
            method: "POST"

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){
                    if(errorCode!=0){

                        callback(errorCode, "NetworkError");
                    }else{
                        console.log("READY", responseText)
                        var json = JSON.parse(responseText);

                        if(json.error!=null){
                            var code = json.error.code;
                            var message = json.error.message;
                            callback(code, message);
                        } else{
                            var objectId = json.addResults[0].objectId;
                            callback(0, objectId)
                        }
                    }
                }
            }
        }


    }

    Component{
        id:emailHandlerRequestComponent
        NetworkRequest {
            id: emailHandler
            url: app.payloadUrl
            method: "POST"

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){
                    if (errorCode!=0) {
                        console.log("Error while sending email!");
                        //do something, may be retry later
                    } else {
                        //success.
                    }
                }
            }
            function sendEmail(body) {

                var obj = {
                    "f":"json",
                    "parameter": JSON.stringify(body)
                }
                console.log("payload:" + JSON.stringify(body))

                send(obj)


            }
        }
    }

    Component{
        id: uploadAttachmentNetworkRequestComponent
        NetworkRequest {
            id: uploadAttachmentNetworkRequest
            method: "POST"
            responseType: "text"
            ignoreSslErrors: true

            property var callback;
            property var cacheI;

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE) {
                    if(errorCode!=0){
                        callback(errorCode, errorText);

                    }else{
                        //console.log("READY2", responseText)
                        var json = JSON.parse(responseText);


                        if(json.error){
                            var code = json.error.code;
                            var message = json.error.message;
                            callback(code, message, cacheI);
                        } else{
                            //var attachmentobjectid = json.addAttachmentResult.objectId
                            callback(0, json,cacheI)
                        }
                    }
                }
            }
        }
    }

    Component{
        id: addAttachmentNetworkRequestComponent
        NetworkRequest {
            id: addAttachmentNetworkRequest
            method: "POST"
            responseType: "text"
            ignoreSslErrors: true

            property var callback;
            property var cacheI;

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE) {
                    if(errorCode!=0){
                        callback(errorCode, errorText);

                    }else{
                        console.log("READY2", responseText)
                        var json = JSON.parse(responseText);
                        var attachmentobjectid
                        if(json.addAttachmentResult)
                         attachmentobjectid = json.addAttachmentResult.objectId

                        if(json.error){
                            var code = json.error.code;
                            var message = json.error.message;
                            callback(code, message, cacheI);
                        } else{
                            callback(0, attachmentobjectid, cacheI)
                        }
                    }
                }
            }
        }
    }



    Component{
        id: generateTokenNetworkRequestComponent
        NetworkRequest {
            id: generateTokenNetworkRequest
            method: "POST"
            responseType: "text"
            ignoreSslErrors: true

            property var callback;

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE) {
                    if(errorCode!=0){
                        callback(errorCode,"NetworkError","","","")
                    }else{
                        console.log("TOKEN RESPOND:", responseText)
                        var root = JSON.parse(responseText);
                        var error = root.error;
                        if(error){
                            callback(error.code,error.message,error.details, "", "");
                        } else{
                            featureServiceManager.token = root.token;
                            callback(0, "", "", root.token, root.expires)
                        }
                    }
                }
            }
        }
    }

    Component{
        id: getServiceInfoNetworkRequestComponent
        NetworkRequest {
            id: getServiceInfoNetworkRequest
            method: "POST"
            responseType: "text"
            ignoreSslErrors: true

            property var callback;

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE) {
                    if(errorCode!=0){
                        callback(errorCode,"NetworkError","","")
                    }else{
                        console.log("Service Info:", responseText)
                        var root = JSON.parse(responseText);
                        var error = root.error;
                        if(error){
                            callback(error.code,error.message,error.details,"");
                        } else{
                            if(root.authInfo.isTokenBasedSecurity){
                                callback(0, "", "", root.authInfo.tokenServicesUrl)
                            }
                        }
                    }
                }
            }
        }
    }

    Component{
        id: deleteFeaturesNetworkRequestComponent
        NetworkRequest{
            property var callback;

            responseType: "text"
            method: "POST"
            ignoreSslErrors: true

            onReadyStateChanged: {
                if (readyState === NetworkRequest.DONE ){
                    if(errorCode === 0) {
                        callback(responseText);
                    } else {
                        console.log("ERROR"+errorCode+": Request Failed");
                    }
                }
            }
        }
    }

    function makeNetworkConnection(url, obj, callback, params) {
        var component = networkRequestComponent;
        var networkRequest = component.createObject(parent);
        networkRequest.url = url;
        networkRequest.callback = callback;
        networkRequest.params = params;
        networkRequest.send(obj);
    }

    Component {
        id: networkRequestComponent

        NetworkRequest {
            property var callback
            property var params

            ignoreSslErrors: true
            responseType: "json"
            method: "POST"

            onReadyStateChanged: {
                if (readyState == NetworkRequest.DONE){
                    if (errorCode === 0) {
                        if(response.error){
                            var code = response.error.code;
                            var message = response.error.message;
                            callback(response, params, code, message);
                        } else {
                            callback(response, params, errorCode, "");
                        }

                    } else {
                        callback(response, params, errorCode, errorText);
                    }
                }
            }

            onError: {
                callback({}, params, -1);
            }
        }
    }

}
