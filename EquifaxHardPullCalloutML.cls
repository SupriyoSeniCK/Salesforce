/**
 * @description       : Callout class for Equifax Hard Pull Integration using integration framework
 * @author            : Supriyo Seni
 * @group             : Integration Classs
 * @last modified on  : 12-12-2023
 * @last modified by  : Supriyo Seni
**/


global with sharing class EquifaxHardPullMLCallout
{ 
    /**
    * @description | In this method here we are calling the Equifax HardPull integration API configuration using request params
    * @author Supriyo Seni | 12-08-2023 
    * @param partyObj 
    **/
    global static void callout(clcommon__Party__c partyObj) {
        Map<String, String> queryIdMap = new Map<String, String>();
        Map<String, Object> requestParamMap = new Map<String, Object>();
        List<Attachment> attachList = new List<Attachment>();
        ints.VedaComprehensiveResponse vedaObj = new ints.VedaComprehensiveResponse();
        String xmlResBody;
        intframework.AbstractIntegrationService baseintegrationService = intframework.IntegrationServiceFactory.getBaseIntegrationService();
        intframework.BaseIntegrationResponse responseObject;
        requestParamMap = createRequestMap(partyObj);
        responseObject = (intframework.BaseIntegrationResponse) baseintegrationService.runSynchronousIntegrationService(ConstantValues.EQUIFAX_FAMILY_NAME,
                                                                                                                        EquifaxIntegrationConstants.EQUIFAXHARDPULL,
                                                                                                                        queryIdMap,
                                                                                                                        requestParamMap);
        if(String.isBlank(responseObject.getBody()) && responseObject.getStatusCode() == CpConstants.TWO_HUNDRED){
            throw new CustomException(ResponseMessenger.somethingWentWrong);
        }
        List<StaticResource> statResList = [SELECT Id,
                                                    Body 
                                            FROM StaticResource 
                                            WHERE Name = 'EquifaxHardPullResponseXml'
                                            LIMIT 1];
        xmlResBody = statResList[0].Body.toString();
        //xmlResBody = responseObject.getBody();    
        // Attch received response from Equifax callout to partyObj                     
        attachList.add(FlowfiUtil.getAttachment(partyObj.id, EquifaxIntegrationConstants.TEXT_XML,
                EquifaxIntegrationConstants.EQUIFAX_RESPONSE_SPACE + partyObj.clcommon__Account__r.Name + 
                EquifaxIntegrationConstants.BLANK_SPACE + DateTime.Now()+EquifaxIntegrationConstants.DOT_XML,xmlResBody));
        DMLUtil.insertSObjectList(attachList, true);
        vedaObj = EquifaxVedaResponseParser.createVedaResponse(xmlResBody);
        IntegrationUtil.throwNullCaseException(vedaObj,ConstantValues.DATA_PARSING_FAILED);
        updateRelatedRecords(vedaObj,partyObj);
    }

    /**
    * @description | This method is used to throw service exception error if error is found in response body 
    * @author Supriyo Seni | 12-08-2023 
    * @param errorList 
    **/
    global static void throwServiceError(List<Error__c> errorList){
        for(Error__c errorObj : errorList) {
            if(errorObj.Fault_String__c.equals(ConstantValues.EQUIFAX_ERROR_POLICY_FALSIFIED)){
                throw new CustomException(ConstantValues.SERVICE_UNAVAILABLE);
            }
        }
    }

    /**
    * @description | This method is used to update Equifax Score fields in partyObj
    * @author Supriyo Seni | 12-08-2023 
    * @param partyObj 
    * @param vedaScoreList 
    * @return clcommon__Party__c 
    **/
    global static clcommon__Party__c updatePartyScores(clcommon__Party__c partyObj,List<ints.VedaComprehensiveResponse.Score> vedaScoreList){
        ints__Veda_Comprehensive__c veda  = ints__Veda_Comprehensive__c.getInstance();
        if(!vedaScoreList.isEmpty()){
            for(ints.VedaComprehensiveResponse.Score scoreDataObj : vedaScoreList){
                partyObj.CCR_Bureau_Score__c = (veda.Scorecard_Id__c != null && scoreDataObj.scoreId == veda.Scorecard_Id__c) ? 
                        Integer.valueOf(scoreDataObj.scoreMasterScale) : partyObj.CCR_Bureau_Score__c;
                partyObj.Equifax_One_Score__c = (veda.Secondary_Scorecard__c != null && scoreDataObj.scoreId == veda.Secondary_Scorecard__c) ? 
                        Integer.valueOf(scoreDataObj.scoreMasterScale) : partyObj.Equifax_One_Score__c;
            }
        }
        return partyObj;
    }

    /**
    * @description | This method updates the partyObj and related fields after getting the response from the equifax callout 
    * @author Supriyo Seni | 12-08-2023 
    * @param res 
    * @param partyObj 
    **/
    global static void updateRelatedRecords(ints.VedaComprehensiveResponse res,clcommon__Party__c partyObj){
        ServiceUnavailableHandler parser = new ServiceUnavailableHandler();
        partyObj = updatePartyScores(partyObj,res.scoreData);
        //sending response wrapper to be parsed according to the data model. 
        Wrapper.EquifaxHardpullDataWrapper2 eqWrap = DataParsingManager.parseVedaResponse2(res);
        IntegrationUtil.throwNullCaseException(eqWrap,ConstantValues.DATA_PARSING_FAILED);
        eqWrap.appId = partyObj.genesis__Application__r.Id;
        eqWrap.accId = partyObj.clcommon__Account__c;
        eqWrap.partyId =  partyObj.id;
        eqWrap.accName = String.valueOf(partyObj.clcommon__Account__r.Name);
        eqWrap.resXml = null;
        DataParsingManager.createEquifaxHardpullResponseRecord2(eqWrap);  
        // If Policy Falsified error occured then throw service error to Callout Batch job
        if(eqWrap.errList != null && !eqWrap.errList.isEmpty()) {
            throwServiceError(eqWrap.errList);
        }
        if(eqWrap.ecr != null){
            partyObj.Bankruptcy__c = eqWrap.ecr.Bankruptcy__c;
        }
        partyObj.Equifax_Apply_Check__c = true;
        partyObj.Underwriting_Fail_Message__c = null;
        if(clcommon__Party__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()){
            update partyObj;
        }
        // If Equifax one score is still null after all Integration operations then initiate service error handler
        if(partyObj.Equifax_One_Score__c == null){
            parser.EquifaxHardpullServiceUnavailableHandler(res.xmlResponse,partyObj.genesis__Application__r.Id);
            throw new CustomException(ConstantValues.SERVICE_UNAVAILABLE);
        }
    }
 
    /**
    * @description | This method is used to update the address for request map creation
    * @author Supriyo Seni | 12-08-2023 
    * @param requestParamMap 
    * @param partyObj 
    * @return Map<String, Object> 
    **/
    global static Map<String, Object> updateAddressMap(Map<String, Object> requestParamMap,clcommon__Party__c partyObj){
        String countryCode;
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_STREET_NAME,partyObj.clcommon__Account__r.Street_Name__c);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_STATE,partyObj.clcommon__Account__r.State__c);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_CITY,partyObj.clcommon__Account__r.City__c);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_ZIP_CODE,partyObj.clcommon__Account__r.Zip__c);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_STREET_NUMBER,partyObj.clcommon__Account__r.Street_Number__c);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_UNIT_NUMBER,partyObj.clcommon__Account__r.Unit_Number__c);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_STREET_TYPE,partyObj.clcommon__Account__r.Street_Type__c);
        // Get country code based on country name AUTRALIA else throw exception
        if(partyObj.clcommon__Account__r.Country__c!=null){
            countryCode = FlowfiUtil.getCountryCode(partyObj.clcommon__Account__r.Country__c);
        }
        if(countryCode != null && countryCode.equals(ConstantValues.NOT_FOUND)){
            throw new CustomException(ResponseMessenger.INVALID_COUNTRY_ADDRESS);
        }else{
            requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_COUNTRY,countryCode);
        }
        return requestParamMap;
    }

    /**
    * @description | This method creates the request parameter map that will be used to create the request body in the adapter class
    * @author Supriyo Seni | 12-08-2023 
    * @param partyObj 
    * @return Map<String, Object> 
    **/
    global static Map<String, Object> createRequestMap(clcommon__Party__c partyObj){
        Map<String, Object> requestParamMap = new Map<String, Object>();
        String gender;
        IntegrationUtil.throwNullCaseException(partyObj.genesis__Application__c,CpConstants.APPLICATION_NOT_FOUND);
        IntegrationUtil.throwNullCaseException(partyObj.clcommon__Account__c,ResponseMessenger.ACCOUNT_NOT_FOUND_IN_APPLICATION);
        IntegrationUtil.throwNullCaseException(partyObj.clcommon__Account__r.First_Name__c,ResponseMessenger.BORROWER_NAME_INVALID);
        IntegrationUtil.throwNullCaseException(partyObj.clcommon__Account__r.Last_Name__c,ResponseMessenger.BORROWER_NAME_INVALID);
        IntegrationUtil.throwNullCaseException(partyObj.genesis__Application__r.genesis__Loan_Amount__c,ResponseMessenger.LOAN_AMOUNT_NOT_FOUND);
        IntegrationUtil.throwNullCaseException(partyObj.clcommon__Account__r.Gender__c,ResponseMessenger.GENDER_INVALID);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_MIDDLENAME,partyObj.clcommon__Account__r.Middle_Name__c);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,EquifaxIntegrationConstants.ENQUIRY_CLIENT_REFERENCE,partyObj.genesis__Application__r.Name);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_DRIVERLICENSE,partyObj.clcommon__Account__r.Drivers_Licence__c);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,ParamsKeyManager.EQH_DOB,String.valueOf(partyObj.clcommon__Account__r.Date_of_Birth__c));
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,EquifaxIntegrationConstants.ACCNAME,partyObj.clcommon__Account__r.Name);
        requestParamMap = IntegrationUtil.validateMapValues(requestParamMap,EquifaxIntegrationConstants.PARTYID,partyObj.id);
        requestParamMap.put(ParamsKeyManager.EQH_LOAN_AMOUNT,String.valueOf(partyObj.genesis__Application__r.genesis__Loan_Amount__c.round(System.RoundingMode.CEILING)));
        requestParamMap.put(ParamsKeyManager.EQH_LASTNAME, partyObj.clcommon__Account__r.Last_Name__c);
        requestParamMap.put(ParamsKeyManager.EQH_FIRSTNAME, partyObj.clcommon__Account__r.First_Name__c);
        gender = (partyObj.clcommon__Account__r.Gender__c.equals(ConstantValues.OTHER_GENDER)) ? ConstantValues.UNKNOWN_GENDER : partyObj.clcommon__Account__r.Gender__c;
        requestParamMap.put(ParamsKeyManager.EQH_GENDER, gender.subString(0,1)); 
        requestParamMap = updateAddressMap(requestParamMap,partyObj);
        return requestParamMap;
    }

    /**
    * @description | This method initiates the callout and used for Skuid button action controller to initiate hardpull manually from backend
    * @author Supriyo Seni | 12-08-2023 
    * @param partyId 
    * @return String 
    **/
    webservice static String makeCallWS(Id partyId){
        try{
            List<clcommon__Party__c> partyList = [SELECT id,
                                                            name,
                                                            genesis__Application__c,
                                                            genesis__Application__r.Id,
                                                            genesis__Application__r.Name,
                                                            genesis__Application__r.genesis__CL_Product_Name__c,
                                                            clcommon__Account__r.City__c,
                                                            clcommon__Account__r.State__c,
                                                            clcommon__Account__r.Street_Name__c,
                                                            clcommon__Account__r.Street_Number__c,
                                                            clcommon__Account__r.Street_Type__c,
                                                            clcommon__Account__r.Country__c,
                                                            clcommon__Account__r.Zip__c,
                                                            clcommon__Account__r.BillingAddress,
                                                            clcommon__Account__r.Drivers_Licence__c,
                                                            genesis__Application__r.genesis__Loan_Amount__c,
                                                            clcommon__Account__c,
                                                            clcommon__Account__r.Unit_Number__c,
                                                            clcommon__Account__r.Name,
                                                            clcommon__Account__r.Gender__c,
                                                            clcommon__Account__r.Date_of_Birth__c,
                                                            clcommon__Account__r.First_Name__c,
                                                            clcommon__Account__r.Last_Name__c,
                                                            clcommon__Account__r.Middle_Name__C,
                                                            Underwriting_Fail_Message__c,
                                                            Equifax_Apply_Check__c,
                                                            Equifax_One_Score__c,
                                                            CCR_Bureau_Score__c,
                                                            Bankruptcy__c
                                                        FROM clcommon__Party__c
                                                        WHERE id=:partyId
                                                        WITH SECURITY_ENFORCED];
            if(partyList.size()>0){
                callout(partyList.get(0));
            }
            return EquifaxIntegrationConstants.EQUIFAXHARDPULLSUCCESS;
        }catch(CustomException e){
            if(e.getMessage().equals(ConstantValues.SERVICE_UNAVAILABLE)){
                throw new CustomException(ConstantValues.SERVICE_UNAVAILABLE);
            }else {
                ExceptionManager.manageException(e);
                return null;
            }
        }catch(Exception Ex){
            ExceptionManager.manageException(ex);
            insert ExceptionManager.getClCommonLog(ex, ResponseMessenger.genesis);
            return ConstantValues.equifaxHardpullFailurePrefix + ConstantValues.DELIMETER_WITH_SPACE + Ex.getMessage();
        }
    }
}