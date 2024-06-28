/**
 * @description       : Integration Adapter Class for PWC protect to upload a file to S3
 * @author            : Rajashree Das
 * @group             : Integration Class
 * @last modified on  : 12-08-2023
 * @last modified by  : Supriyo Seni
**/

global without sharing class PWCProtectUploadFileToS3Adapter extends intframework.BaseIntegrationAdapter {

    List<Attachment> insertReqResAttachment = new List<Attachment>();
    List<clcommon__Document_Category__c> docCategoryQueryForParentId = new List<clcommon__Document_Category__c>();
    List<clcommon__Category_Attachment_Association__c> appDocAssList = new List<clcommon__Category_Attachment_Association__c>();
    intframework.BaseIntegrationRequest requestHttp = new intframework.BaseIntegrationRequest();


    /**
    * @description | Creates Request to generate the AmazonS3 url and then uplaods the file to the url.
    * @author Supriyo Seni | 12-08-2023 
    * @param relatedObjectIds 
    * @param filledInRequestMap 
    * @return intframework.BaseIntegrationRequest 
    **/
    global override intframework.BaseIntegrationRequest createRequest(Map<String, Object> relatedObjectIds, Map<String, Object> filledInRequestMap) {
        String amazonSUrl;
        Id attchId;
        String guid;
        try {
            /*-------Getting attch Id from dynamic parameter as List-------*/
            validateMapAndThrowException(filledInRequestMap,ParamsKeyManager.ATTID,ResponseMessenger.attIdMissing);
            attchId = (Id)filledInRequestMap.get(ParamsKeyManager.ATTID);
            // if(filledInRequestMap.containsKey(ParamsKeyManager.ATTID) && filledInRequestMap.get(ParamsKeyManager.ATTID) != null){
            // }else{
            //     throw new CustomException(ResponseMessenger.attIdMissing);
            // }
            validateMapAndThrowException(filledInRequestMap,ParamsKeyManager.GUID,ResponseMessenger.guidMissing);
            guid = String.valueOf(filledInRequestMap.get(ParamsKeyManager.GUID));
            amazonSUrl = getAmazonUrl(attchId,guid,filledInRequestMap);
            // if(filledInRequestMap.containsKey(ParamsKeyManager.GUID) && String.valueOf(filledInRequestMap.get(ParamsKeyManager.GUID)) != null){
            // }else{
            //     throw new CustomException(ResponseMessenger.guidMissing);
            // }

            /*-------Getting the amazonS3url and sending the doc-------*/
            // try{

            //     /*-------Attachment to be queried here-------*/
            //     List<Attachment> attchList = [SELECT id,
            //                                             Body,
            //                                             parentId,
            //                                             Name
            //                                     FROM Attachment
            //                                     WHERE id =: attch
            //                                     WITH SYSTEM_MODE
            //                                     LIMIT 1];
            //     if(attchList.size()==0) {
            //         throw new CustomException(ResponseMessenger.attchNotFound);
            //     }
            //     Attachment attchmentObj = attchList[0];

            //     /*-------Querying to get the document category of the attachment-------*/     
            //     List<clcommon__Document_Category__c> docCategoryQueryForFetchingAppId=[SELECT id,
            //                                                                                 genesis__Application__c 
            //                                                                             FROM clcommon__Document_Category__c 
            //                                                                             WHERE id=:attchmentObj.parentId];

            //     if(docCategoryQueryForFetchingAppId !=null && docCategoryQueryForFetchingAppId.size()>0){
            //         docCategoryQueryForParentId=[SELECT id,
            //                                             genesis__Application__c,
            //                                             genesis__Application__r.name 
            //                                         FROM clcommon__Document_Category__c 
            //                                         WHERE clcommon__Category_Name__c =:ConstantValues.pwcDocsCatName
            //                                         AND genesis__Application__c=:docCategoryQueryForFetchingAppId[0].genesis__Application__c];
            //     }else{
            //         throw new CustomException(ResponseMessenger.docCatEmpty);
            //     }
            //     if(docCategoryQueryForParentId == null || docCategoryQueryForParentId.size() == 0){
            //         throw new CustomException(ResponseMessenger.docCatEmpty);
            //     }

            //     HttpRequest httpreq=new HttpRequest();
            //     String endpoint;
                
            //     /*-----To update the {{Scan_Name}} value in request body-----*/
            //     List<StaticResource> statResList = [SELECT id,
            //                                                 Name,
            //                                                 Body
            //                                         FROM StaticResource
            //                                         WHERE Name =:ConstantValues.PWCPROTECT_UPLOAD_FILE_TO_S3
            //                                         LIMIT 1];
            //     if(statResList.size()==0) {
            //         throw new CustomException(ResponseMessenger.STATIC_RESOURCE_NOT_FOUND);
            //     }
            //     String apiPayload = (statResList[0].Body).toString();
            //     apiPayLoad = apiPayLoad.replace(ConstantValues.scanNameKey, String.valueOf(attchmentObj.Name));

            //     /*-------Setting endpoint of url to get AmazonS3url from static parameters of request mapping-------*/
            //     String uplaodRequestUrl;
            //     if(filledInRequestMap.containsKey(ParamsKeyManager.URL) && String.isNotBlank(String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL)))){
            //         uplaodRequestUrl = String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL));
            //     }else{
            //         throw new CustomException(ResponseMessenger.uploadUrlMissing);
            //     }
            //     if(filledInRequestMap.containsKey(ParamsKeyManager.XAPI_KEY) && String.isNotBlank(String.valueOf(filledInRequestMap.get(ParamsKeyManager.XAPI_KEY)))){
            //         httpreq.setHeader(ConstantValues.headerXApiKey,String.valueOf(filledInRequestMap.get(ParamsKeyManager.XAPI_KEY)));
            //     }else{
            //         throw new CustomException(ResponseMessenger.xApiKeyMissing);
            //     }
            //     if(filledInRequestMap.containsKey(ParamsKeyManager.URL_METHOD) && String.isNotBlank(String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_METHOD)))){
            //         httpreq.setMethod(String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_METHOD)));
            //     }else{
            //         throw new CustomException(ResponseMessenger.httpMethodMissing);
            //     }
            //     if(filledInRequestMap.containsKey(ParamsKeyManager.URL_CONTENT_TYPE) && String.isNotBlank(String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_CONTENT_TYPE)))){
            //         httpreq.setHeader(ConstantValues.cntntType, String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_CONTENT_TYPE)));
            //     }else{
            //         throw new CustomException(ResponseMessenger.httpCntnTypeMissing);
            //     }

            //     /*-------Changing the {{fileGuid}} value in url-------*/
            //     if(uplaodRequestUrl !=null){
            //         endpoint=uplaodRequestUrl.replace(ConstantValues.FILE_GUID_KEY, guid);
            //         httpreq.setEndpoint(endpoint);
            //     }

            //     /*-------Setting other parameters for httpreq-------*/
            //     httpreq.setBody(apiPayload);

            //     /*-------Storing the reqthat is being sent-------*/
            //     if(httpreq.getBody() != null){
            //         Attachment attchReqToBeInserted=FlowfiUtil.getAttachment(docCategoryQueryForParentId.get(0).id,
            //                                                                     ConstantValues.attchContentType,ConstantValues.PWC_FILE_UPLOAD_REQUEST 
            //                                                                     + System.now().format(ConstantValues.dateFormatForAttch)
            //                                                                     + ConstantValues.JSON_EXTENSION, 
            //                                                                     String.valueOf(httpreq.getBody()));
            //         insertReqResAttachment.add(attchReqToBeInserted);
            //     }

            //     /*-------Callout to get the amazonS3url-------*/
            //     Http httpSocket=new Http();
            //     HttpResponse httpRes=httpSocket.send(httpReq);
            //     map<String,Object> fileUploadRequestRes = (map<String,Object>)JSON.deserializeUntyped(httpRes.getBody());
            //     fileUploadRequestRes.put(ConstantValues.respBodyKey, httpRes.getBody());

            //     /*-------Storing the res that is being recieved-------*/
            //     if(fileUploadRequestRes.ContainsKey(ConstantValues.respBodyKey) && String.isNotBlank(String.valueOf(fileUploadRequestRes.get(ConstantValues.respBodyKey)))){
            //         Attachment attchResToBeInserted=FlowfiUtil.getAttachment(docCategoryQueryForParentId.get(0).id,
            //                                                                     ConstantValues.attchContentType,
            //                                                                     ConstantValues.PWC_FILE_UPLOAD_RESPONSE 
            //                                                                     + System.now().format(ConstantValues.dateFormatForAttch)
            //                                                                     + ConstantValues.JSON_EXTENSION, 
            //                                                                     String.valueOf(fileUploadRequestRes.get(ConstantValues.respBodyKey)));
            //         insertReqResAttachment.add(attchResToBeInserted);
            //     }

            //     /*-------Parsing the url that recieved from the callout-------*/
            //     if(httpRes != null && httpRes.getStatusCode()==200){
            //         amazonSUrl = FlowfiUtil.validateNullParams(fileUploadRequestRes.get(ConstantValues.urlResKey), ResponseMessenger.s3UploadUrlNotFound, true);
            //     }else{
            //         throw new CustomException(ResponseMessenger.AmazonS3urlNotGenerated + httpRes.getStatusCode() + httpRes.getStatus());
            //     }

            //     /*-------Sending each attachment using this amazonSUrl-------*/
            //     System.HttpRequest req= requestHttp.getRequest();
            //     if(attchmentObj.Body != null){
            //         req.setBodyAsBlob(attchmentObj.Body);
            //     }else {
            //         throw new CustomException(ResponseMessenger.attBodyMissing);
            //     }
            // } catch(Exception ex){
            //     ExceptionManager.manageException(ex);
            //     insert ExceptionManager.getCLCommonLog(ex,ResponseMessenger.intFramework);
            // }

            /*-------Setting the request to upload the file-------*/
            requestHttp.setEndpoint(amazonSUrl);
            requestHttp.setHeader(ConstantValues.cntntType,apiConfig.httpContentType);
            requestHttp.setMethod(apiConfig.httpMethod);
            requestHttp.setTimeOut(apiConfig.requestTimeout);   
            return requestHttp;
        } catch (Exception ex) {
            ExceptionManager.manageException(ex);
            insert ExceptionManager.getCLCommonLog(ex,ResponseMessenger.INTFRAMEWORK);
            return null;
        }
    }

    /**
    * @description |  overrirde the sendRequest method to store the req-res attachment and also inserting the Category Attachment association 
    * @author Supriyo Seni | 12-08-2023 
    * @param httpReq 
    * @return System.HttpResponse 
    **/
    global override System.HttpResponse sendRequest(System.HttpRequest httpReq){
        System.HTTPResponse res;
        System.Http http = new System.Http();
        try {
            httpReq.setMethod(apiConfig.httpMethod);
            httpReq.setTimeout(apiConfig.requestTimeout);
            res = http.send(httpReq);

            /*-------after getting the amazonS3url inserting the req-res attachment and also inserting the Category Attachment association-------*/
            if(!insertReqResAttachment.isEmpty()){
                DMLUtil.insertSObjectList(insertReqResAttachment,true);
                //insert insertReqResAttachment;
                for(Attachment att : insertReqResAttachment){
                    clcommon__Category_Attachment_Association__c appDocAssObj = FlowfiUtil.getAppDocAss(att.Name,att.id,docCategoryQueryForParentId[0].id);
                    appDocAssList.add(appDocAssObj);
                }
            }
            if(!appDocAssList.isEmpty()){
                DMLUtil.insertSObjectList(appDocAssList,true);
                //insert appDocAssList;
            }
            return res;
        }catch (Exception ex) {
            ExceptionManager.manageException(ex);
            insert ExceptionManager.getCLCommonLog(ex,ResponseMessenger.intFramework);
            return null;
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-08-2023 
    * @param requestMap 
    * @param mapKey 
    * @param exception 
    **/
    public static void validateMapAndThrowException(Map<String, Object> requestMap, String mapKey, String errorMessage){
        if(!requestMap.containsKey(mapKey) || String.isBlank(String.valueOf(requestMap.get(mapKey)))){
            throw new CustomException(errorMessage);   
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-08-2023 
    * @param attchId 
    * @param guid 
    * @param filledInRequestMap 
    * @return String 
    **/
    public String getAmazonUrl(Id attchId,String guid,Map<String, Object> filledInRequestMap){
        HttpRequest httpreq = new HttpRequest();
        String endpoint;
        String amazonSUrl;
        try{
            /*-------Attachment to be queried here-------*/
            List<Attachment> attchList = [SELECT id,
                                                    Body,
                                                    parentId,
                                                    Name
                                            FROM Attachment
                                            WHERE id =: attchId
                                            WITH SYSTEM_MODE
                                            LIMIT 1];
            ValidationUtil.validateObjectListNotNull(attchList,ResponseMessenger.attchNotFound);
            // if(attchList.size()==0) {
            //     throw new CustomException(ResponseMessenger.attchNotFound);
            // }
            Attachment attchmentObj = attchList[0];
            /*-------Querying to get the document category of the attachment-------*/     
            List<clcommon__Document_Category__c> docCategoryQueryForFetchingAppId = [SELECT Id,
                                                                                            genesis__Application__c 
                                                                                    FROM clcommon__Document_Category__c 
                                                                                    WHERE Id=:attchmentObj.parentId
                                                                                    WITH SYSTEM_MODE];
            ValidationUtil.validateObjectListNotNull(docCategoryQueryForFetchingAppId,ResponseMessenger.docCatEmpty);
            docCategoryQueryForParentId = [SELECT id,
                                                genesis__Application__c,
                                                genesis__Application__r.name 
                                            FROM clcommon__Document_Category__c 
                                            WHERE clcommon__Category_Name__c =: ConstantValues.pwcDocsCatName
                                            AND genesis__Application__c =: docCategoryQueryForFetchingAppId[0].genesis__Application__c
                                            WITH SYSTEM_MODE];
            ValidationUtil.validateObjectListNotNull(docCategoryQueryForParentId,ResponseMessenger.docCatEmpty);

            // if(docCategoryQueryForFetchingAppId !=null && docCategoryQueryForFetchingAppId.size()>0){

            // }else{
            //     throw new CustomException(ResponseMessenger.docCatEmpty);
            // }
            // if(docCategoryQueryForParentId == null || docCategoryQueryForParentId.size() == 0){
            //     throw new CustomException(ResponseMessenger.docCatEmpty);
            // }
            
            /*-----To update the {{Scan_Name}} value in request body-----*/
            List<StaticResource> statResList = [SELECT id,
                                                        Name,
                                                        Body
                                                FROM StaticResource
                                                WHERE Name =:ConstantValues.PWCPROTECT_UPLOAD_FILE_TO_S3
                                                WITH SYSTEM_MODE
                                                LIMIT 1];
            ValidationUtil.validateObjectListNotNull(statResList,ResponseMessenger.STATIC_RESOURCE_NOT_FOUND);

            // if(statResList.size()==0) {
            //     throw new CustomException(ResponseMessenger.STATIC_RESOURCE_NOT_FOUND);
            // }
            String apiPayload = (statResList[0].Body).toString();
            apiPayLoad = apiPayLoad.replace(ConstantValues.scanNameKey, String.valueOf(attchmentObj.Name));

            /*-------Setting endpoint of url to get AmazonS3url from static parameters of request mapping-------*/
            validateMapAndThrowException(filledInRequestMap,ParamsKeyManager.URL,ResponseMessenger.uploadUrlMissing);
            String uplaodRequestUrl = String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL));
            // if(filledInRequestMap.containsKey(ParamsKeyManager.URL) && String.isNotBlank(String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL)))){
            // }else{
            //     throw new CustomException(ResponseMessenger.uploadUrlMissing);
            // }
            validateMapAndThrowException(filledInRequestMap,ParamsKeyManager.XAPI_KEY,ResponseMessenger.xApiKeyMissing);
            httpreq.setHeader(ConstantValues.headerXApiKey,String.valueOf(filledInRequestMap.get(ParamsKeyManager.XAPI_KEY)));
            // if(filledInRequestMap.containsKey(ParamsKeyManager.XAPI_KEY) && String.isNotBlank(String.valueOf(filledInRequestMap.get(ParamsKeyManager.XAPI_KEY)))){
            //     httpreq.setHeader(ConstantValues.headerXApiKey,String.valueOf(filledInRequestMap.get(ParamsKeyManager.XAPI_KEY)));
            // }else{
            //     throw new CustomException(ResponseMessenger.xApiKeyMissing);
            // }
            validateMapAndThrowException(filledInRequestMap,ParamsKeyManager.URL_METHOD,ResponseMessenger.httpMethodMissing);
            httpreq.setMethod(String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_METHOD)));
            // if(filledInRequestMap.containsKey(ParamsKeyManager.URL_METHOD) && String.isNotBlank(String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_METHOD)))){
            //     httpreq.setMethod(String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_METHOD)));
            // }else{
            //     throw new CustomException(ResponseMessenger.httpMethodMissing);
            // }
            validateMapAndThrowException(filledInRequestMap,ParamsKeyManager.URL_CONTENT_TYPE,ResponseMessenger.httpCntnTypeMissing);
            httpreq.setHeader(ConstantValues.cntntType, String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_CONTENT_TYPE)));
            // if(filledInRequestMap.containsKey(ParamsKeyManager.URL_CONTENT_TYPE) && String.isNotBlank(String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_CONTENT_TYPE)))){
            //     httpreq.setHeader(ConstantValues.cntntType, String.valueOf(filledInRequestMap.get(ParamsKeyManager.URL_CONTENT_TYPE)));
            // }else{
            //     throw new CustomException(ResponseMessenger.httpCntnTypeMissing);
            // }

            /*-------Changing the {{fileGuid}} value in url-------*/

            if(uplaodRequestUrl !=null){
                endpoint = uplaodRequestUrl.replace(ConstantValues.FILE_GUID_KEY, guid);
                httpreq.setEndpoint(endpoint);
            }

            /*-------Setting other parameters for httpreq-------*/
            httpreq.setBody(apiPayload);

            /*-------Storing the reqthat is being sent-------*/
            if(httpreq.getBody() != null){
                Attachment attchReqToBeInserted=FlowfiUtil.getAttachment(docCategoryQueryForParentId.get(0).id,
                                                                            ConstantValues.attchContentType,ConstantValues.PWC_FILE_UPLOAD_REQUEST 
                                                                            + System.now().format(ConstantValues.dateFormatForAttch)
                                                                            + ConstantValues.JSON_EXTENSION, 
                                                                            String.valueOf(httpreq.getBody()));
                insertReqResAttachment.add(attchReqToBeInserted);
            }

            /*-------Callout to get the amazonS3url-------*/
            Http httpSocket = new Http();
            HttpResponse httpRes = httpSocket.send(httpReq);
            map<String,Object> fileUploadRequestRes = (map<String,Object>)JSON.deserializeUntyped(httpRes.getBody());
            fileUploadRequestRes.put(ConstantValues.respBodyKey, httpRes.getBody());

            /*-------Storing the res that is being recieved-------*/
            if(fileUploadRequestRes.ContainsKey(ConstantValues.respBodyKey) && String.isNotBlank(String.valueOf(fileUploadRequestRes.get(ConstantValues.respBodyKey)))){
                Attachment attchResToBeInserted=FlowfiUtil.getAttachment(docCategoryQueryForParentId.get(0).id,
                                                                            ConstantValues.attchContentType,
                                                                            ConstantValues.PWC_FILE_UPLOAD_RESPONSE 
                                                                            + System.now().format(ConstantValues.dateFormatForAttch)
                                                                            + ConstantValues.JSON_EXTENSION, 
                                                                            String.valueOf(fileUploadRequestRes.get(ConstantValues.respBodyKey)));
                insertReqResAttachment.add(attchResToBeInserted);
            }

            /*-------Parsing the url that recieved from the callout-------*/
            if(httpRes == null || httpRes.getStatusCode() != 200){
                throw new CustomException(ResponseMessenger.AmazonS3urlNotGenerated + httpRes.getStatusCode() + httpRes.getStatus());
            }
            amazonSUrl = FlowfiUtil.validateNullParams(fileUploadRequestRes.get(ConstantValues.urlResKey), ResponseMessenger.s3UploadUrlNotFound, true);

            /*-------Sending each attachment using this amazonSUrl-------*/
            System.HttpRequest requestInst = requestHttp.getRequest();
            //validateObjectNotNull(attchmentObj.Body,ResponseMessenger.attBodyMissing);
           // requestInst.setBodyAsBlob(attchmentObj.Body);
            if(attchmentObj.Body == null){
                throw new CustomException(ResponseMessenger.attBodyMissing);
            }
            requestInst.setBodyAsBlob(attchmentObj.Body);
        } catch(Exception ex){
            ExceptionManager.manageException(ex);
            insert ExceptionManager.getCLCommonLog(ex,ResponseMessenger.intFramework);
        }
        return amazonSUrl;
    }
}