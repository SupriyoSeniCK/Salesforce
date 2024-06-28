/*********************************************************************************************************
* Class            : EquifaxHardpullIntegration2
* @ Description    : Class for Equifax Hardpull Integration in Party Level
* @ Created Date   : 13/06/2018
* @ Developer      : Kushal Basu
* @ Modified By    : Arnab Majumdar
* @ Last Modified Date : 25/01/2022
**********************************************************************************************************/
global without sharing class EquifaxHardpullIntegration2{
    static Map<String,ints.VedaComprehensiveResponse> mapOfEquifaxResponse = new Map<String,ints.VedaComprehensiveResponse>();
    static Map<String,String> mapOfEquifaxByCompId = new Map<String,String>();

    /*-----Function that does initiates the callout process against an application record------*/ 
    global static void makeCalloutByObj(clcommon__Party__c party){
        System_Configuration__c sysConfig = System_Configuration__c.getInstance();
        if(sysConfig==null){
            throw new CustomException(ResponseMessenger.sysConfigInfoMissing);
        }
        /*------Querying up API credentials from product custom settings------*/
        //---------------added changes as per Motor Loans LMM-192----------------//
        ints__Veda_Comprehensive__c veda;
        if(party.genesis__Application__r.genesis__CL_Product_Name__c.contains(ParamsKeyManager.AUTO_LOANS_PRODUCT_SUFFIX)){
            User adminUser = [SELECT id FROM User WHERE UserName =: System_Configuration__c.getInstance().Default_User_Account_Owner_Username__c ORDER BY CreatedDate DESC LIMIT 1];
            veda = ints__Veda_Comprehensive__c.getInstance(adminUser.Id);
        }else{
            veda = ints__Veda_Comprehensive__c.getInstance();
        }
        //-----------------------------------------------------------------------//
        ints.IntegrationObjectFactory factroy = ints.IntegrationObjectFactory.getInstance();
        ints.IntegrationRequestObject requestObj = new ints.IntegrationRequestObject();
        /*-----Start of generation of API requests------*/
        requestObj.requestMap.put(ParamsKeyManager.EQH_TYPE_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, ConstantValues.LETTER_C);
        if(veda!=null && veda.Account_Type_Code__c!=null && veda.Client_Reference__c!=null
                && veda.ints__Endpoint__c!=null && veda.Operator_Id__c!=null && veda.Operator_Name__c!=null
                && veda.ints__Password__c!=null && veda.Permission_Type__c!=null && veda.Scorecard_Id__c!=null
                && veda.Product_Data_Level_Code__c!=null && veda.Relationship_Code__c!=null && veda.ints__UserName__c!=null){
                    requestObj.requestMap.put(ParamsKeyManager.EQH_ACCOUNT_TYPE_CODE_ENQUIRY_DATA, veda.Account_Type_Code__c);        
                    requestObj.requestMap.put(ParamsKeyManager.EQH_RELATIONSHIP_CODE_ENQUIRY_DATA, veda.Relationship_Code__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_PERMISSION_TYPE_CODE_ENQUIRY_HEADER, veda.Permission_Type__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_CLIENT_REFERENCE_ENQUIRY_HEADER, veda.Client_Reference__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_OPERATOR_ID_ENQUIRY_HEADER, veda.Operator_Id__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_OPERATOR_NAME_ENQUIRY_HEADER, veda.Operator_Name__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_PRODUCT_DATA_LEVEL_CODE_ENQUIRY_HEADER, veda.Product_Data_Level_Code__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_SCORECARD_ID_REQUESTED_SCORES_ENQUIRY_HEADER_1, veda.Scorecard_Id__c);
                    if(veda.Secondary_Scorecard__c!=null){
                        requestObj.requestMap.put(ParamsKeyManager.EQH_SCORECARD_ID_REQUESTED_SCORES_ENQUIRY_HEADER_2, veda.Secondary_Scorecard__c);
                    }
        }else{
            throw new CustomException(ResponseMessenger.sysConfigInfoMissing);
        }
        
        if(party.genesis__Application__r.Name!=NULL){
            requestObj.requestMap.put(ParamsKeyManager.EQH_ENQUIRY_CLIENT_REFERENCE_ENQUIRY_DATA, party.genesis__Application__r.Name);
        }
        if(party.clcommon__Account__r == null){
            throw new CustomException(ResponseMessenger.ACCOUNT_NOT_FOUND_IN_APPLICATION);
        }
        if(party.clcommon__Account__r.First_Name__c!=null && party.clcommon__Account__r.Last_Name__c!=null){
            requestObj.requestMap.put(ParamsKeyManager.EQH_FAMILY_NAME_CURRENT_NAME_INDIVIDUAL_ENQUIRY_DATA, party.clcommon__Account__r.Last_Name__c);
            requestObj.requestMap.put(ParamsKeyManager.EQH_FIRST_GIVEN_NAME_CURRENT_NAME_INDIVIDUAL_ENQUIRY_DATA, party.clcommon__Account__r.First_Name__c);
            if(party.clcommon__Account__r.Middle_Name__C!=null){
                requestObj.requestMap.put(ParamsKeyManager.EQH_OTHER_GIVEN_NAME_CURRENT_NAME_INDIVIDUAL_ENQUIRY_DATA,party.clcommon__Account__r.Middle_Name__C);
            }
        }else{
            throw new CustomException(ResponseMessenger.BORROWER_NAME_INVALID);
        }
        if(party.clcommon__Account__r.Gender__c!=null){
            String gen;
            if(party.clcommon__Account__r.Gender__c.equals(ConstantValues.OTHER_GENDER)){
                gen = ConstantValues.UNKNOWN_GENDER;
            }else{
                gen = party.clcommon__Account__r.Gender__c;
            }
            requestObj.requestMap.put(ParamsKeyManager.EQH_GENDER_CODE_INVALID_ENQUIRY_DATA, gen.subString(0,1));
        }else{
            throw new CustomException(ResponseMessenger.GENDER_INVALID);
        }
        if(party.clcommon__Account__r.Street_Name__c!=null && party.clcommon__Account__r.State__c!=null
                && party.clcommon__Account__r.Country__c!=null && party.clcommon__Account__r.City__c!=null
                && party.clcommon__Account__r.Zip__c!=null  && party.clcommon__Account__r.Street_Number__c!=null
                && party.clcommon__Account__r.Street_Type__c!=null){
                    requestObj.requestMap.put(ParamsKeyManager.EQH_STREET_NAME_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, party.clcommon__Account__r.Street_Name__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_SUBURB_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, party.clcommon__Account__r.City__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_STATE_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, String.valueOf(party.clcommon__Account__r.State__c));
                    String countryCode = FlowfiUtil.getCountryCode(party.clcommon__Account__r.Country__c);
                    if(countryCode.equals(ConstantValues.NOT_FOUND)){
                        countryCode = FlowfiUtil.getCountryCode(party.clcommon__Account__r.Country__c);
                        if(countryCode.equals(ConstantValues.NOT_FOUND)){
                            throw new CustomException(ResponseMessenger.INVALID_COUNTRY_ADDRESS);
                        }
                    }
                    if(party.clcommon__Account__r.Unit_Number__c!=null){
                        requestObj.requestMap.put(ParamsKeyManager.EQH_UNIT_NUMBER_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, party.clcommon__Account__r.Unit_Number__c);
                    }
                    requestObj.requestMap.put(ParamsKeyManager.EQH_COUNTRY_CODE_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, countryCode);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_STREET_NUMBER_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, party.clcommon__Account__r.Street_Number__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_STREET_TYPE_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, party.clcommon__Account__r.Street_Type__c);
                    requestObj.requestMap.put(ParamsKeyManager.EQH_POST_CODE_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, party.clcommon__Account__r.Zip__c);
        }else if(party.clcommon__Account__r.BillingAddress!=null){
            requestObj.requestMap.put(ParamsKeyManager.EQH_UNFORMATTED_ADDRESS_ADDRESSES_INDIVIDUAL_ENQUIRY_DATA_1, String.valueOf(party.clcommon__Account__r.BillingAddress));
        }else{
            throw new CustomException(ResponseMessenger.NO_ADDRESS_ASSOCIATED_WITH_APPLICATION);
        }
        if(party.clcommon__Account__r.Drivers_Licence__c!=null && String.isNotBlank(party.clcommon__Account__r.Drivers_Licence__c)){
            requestObj.requestMap.put(ParamsKeyManager.EQH_NUMBER_DRIVERS_LICENCE_INDIVIDUAL_ENQUIRY_DATA, party.clcommon__Account__r.Drivers_Licence__c);
        }
        if(party.clcommon__Account__r.Date_of_Birth__c!=NULL){
            requestObj.requestMap.put(ParamsKeyManager.EQH_DOB_INDIVIDUAL_ENQUIRY_DATA, String.valueOf(party.clcommon__Account__r.Date_of_Birth__c));
        }
        if(party.genesis__Application__r.genesis__Loan_Amount__c!=null){
            requestObj.requestMap.put(ParamsKeyManager.EQH_ENQUIRY_AMOUNT_ENQUIRY_DATA, 
                                        String.valueOf(party.genesis__Application__r.genesis__Loan_Amount__c.round(System.RoundingMode.CEILING)));
            if(sysConfig.Default_Currency_Code__c!=null){
                requestObj.requestMap.put(ParamsKeyManager.EQH_CURRENCY_CODE_ENQUIRY_DATA, sysConfig.Default_Currency_Code__c);
            }
        }else{
            throw new CustomException(ResponseMessenger.LOAN_AMOUNT_NOT_FOUND);
        }
        ints.VedaComprehensiveResponse res = new ints.VedaComprehensiveResponse();
        /*-----following code block is test context specific as there was an Null pointer exception happening over-----*/
        System.debug('requestObj = '+requestObj);
        if(Test.isRunningTest()){
            res = FlowfiTestHelper.getMockHardpullResponse();            
        }else{
            /*-----Calling integration API to make the callout-----*/
            res=(ints.VedaComprehensiveResponse)factroy.getIntegrationObject(ConstantValues.VEDA_COMPREHENSIVE).integrate(requestObj);
        }
        System.debug('res = '+res);

        if(res!=null){
            if(res.ScoreData!=null && res.ScoreData.size()>0){
                for(ints.VedaComprehensiveResponse.Score scoreDataObj : res.scoreData){
                    if(veda.Scorecard_Id__c!=null && scoreDataObj.scoreId==veda.Scorecard_Id__c){
                        party.CCR_Bureau_Score__c = Integer.valueOf(scoreDataObj.scoreMasterScale);
                    }
                    if(veda.Secondary_Scorecard__c!=null && scoreDataObj.scoreId==veda.Secondary_Scorecard__c){
                        party.Equifax_One_Score__c = Integer.valueOf(scoreDataObj.scoreMasterScale);
                    }
                }
            }
            //sending response wrapper to be parsed according to the data model. 
            Wrapper.EquifaxHardpullDataWrapper2 eqWrap = DataParsingManager.parseVedaResponse2(res);
            if(eqWrap!=null){
                eqWrap.appId = party.genesis__Application__r.Id;
                eqWrap.accId = party.clcommon__Account__c;
                eqWrap.partyId =  party.id;
                eqWrap.accName = String.valueOf(party.clcommon__Account__r.Name);
                DataParsingManager.createEquifaxHardpullResponseRecord2(eqWrap);  

                if(eqWrap.errList != null) {
                    if(eqWrap.errList.size()>0) {
                        for(Error__c err : eqWrap.errList) {
                            if(err.Fault_String__c.equals(ConstantValues.EQUIFAX_ERROR_POLICY_FALSIFIED)){
                                throw new CustomException(ConstantValues.SERVICE_UNAVAILABLE);
                            }
                        }
                    } 
                }
                
                /*------Updating fields in party-------*/
                if(eqWrap.ecr!=null){
                    party.Bankruptcy__c = eqWrap.ecr.Bankruptcy__c;
                }
                party.Equifax_Apply_Check__c = true;
                party.Underwriting_Fail_Message__c = CpConstants.BLANK;
                update party;
                List<clcommon__Party__c> partylist = [SELECT Id,
                                                                Equifax_One_Score__c,
                                                                genesis__Application__r.Id
                                                                FROM clcommon__Party__c 
                                                                WHERE Id =:party.Id 
                                                                LIMIT 1];
                if((partylist != null && partylist.size() > 0 ) ){
                    /** 
                    * added on 12th July as a part of SYM-2415
                    *If the integration sends a response with 200 OK but no score, its an error, so we parse accordingly and throw the exception to the batch
                    */
                    if ( partylist[0].Equifax_One_Score__c == null && !Test.isRunningTest() ) {
                        String apipayload=res.xmlResponse;
                        ServiceUnavailableHandler parser=new ServiceUnavailableHandler();
                        parser.EquifaxHardpullServiceUnavailableHandler(apiPayload,partylist[0].genesis__Application__r.Id);
                        List<genesis__Applications__c> appList2 = [SELECT id, 
                                                                        Service_Unavailable_Response__c	 
                                                                    FROM genesis__Applications__c 
                                                                    WHERE id =: partylist[0].genesis__Application__r.Id
                                                                    LIMIT 1];
                        throw new CustomException(ConstantValues.SERVICE_UNAVAILABLE);
                    }else if(Test.isRunningTest()){
                        throw new CustomException(ConstantValues.SERVICE_UNAVAILABLE);
                    }
                }
            } else {
                throw new CustomException(ConstantValues.DATA_PARSING_FAILED);
            }
        } 
    }

    /*------Skuid button action controller to initiate hardpull manually from backend------*/
    webservice static String makeCall(Id partyId){
        try{
            List<clcommon__Party__c> partyList = [SELECT id,
                                                            name,
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
                                                            clcommon__Account__r.BillingStreet,
                                                            clcommon__Account__r.BillingCity,
                                                            clcommon__Account__r.BillingState,
                                                            clcommon__Account__r.BillingPostalCode,
                                                            clcommon__Account__r.BillingCountry,
                                                            clcommon__Account__r.Citizenship__c
                                                        FROM clcommon__Party__c
                                                        WHERE id=:partyId];
            if(partyList.size()>0){
                makeCalloutByObj(partyList.get(0));
            }
            return ConstantValues.equifaxHardpullSuccess;
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