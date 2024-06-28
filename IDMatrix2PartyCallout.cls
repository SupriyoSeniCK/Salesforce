/*********************************************************************************************************
Class          : IDMatrix2PartyCallout
Description    : Callout class for ID Matrix 2 Integration using Party
Created Date   : 21/12/2021
Developer      : Reet Roy
**********************************************************************************************************/

global without sharing class IDMatrix2PartyCallout 
{
    static WebService String callout(String partyId , Boolean consentCheck) {
        Map<String, Object> requestParamMap = new Map<String, Object>();
        Map<String, String> queryIdMap = new Map<String, String>();
        String resp = ResponseMessenger.genericIDMatrixMsgForAPI2;
        intframework.BaseIntegrationResponse res;
        Wrapper.IDMatrixResponseWrapper idResWrap = new Wrapper.IDMatrixResponseWrapper();
        try{
            if(partyId == null){
                throw new CustomException(ResponseMessenger.requiredParamsMissing);
            }
            queryIdMap.put(CpConstants.PARTY_ID, partyId);
            requestParamMap.put(CpConstants.CONSENT_CHECK,String.valueOf(consentCheck));

            intframework.AbstractIntegrationService baseintegrationService = intframework.IntegrationServiceFactory.getBaseIntegrationService();

            res = (intframework.BaseIntegrationResponse) baseintegrationService.runSynchronousIntegrationService(ConstantValues.EQUIFAX_FAMILY_NAME,
                                                                                                                CpConstants.IDM2Party,
                                                                                                                queryIdMap,
                                                                                                                requestParamMap
                                                                                                                );          
            idResWrap.responseBody = res.getBody();  
            if(res.getStatusCode() == 200){   
                /***************If successful, returns threshold, score and final result******************/                  
                idResWrap.threshold = idResWrap?.responseBody?.substringBetween(CpConstants.THRESHOLD_BEGIN,CpConstants.THRESHOLD_END) != null ? Decimal.valueOf(idResWrap?.responseBody?.substringBetween(CpConstants.THRESHOLD_BEGIN,CpConstants.THRESHOLD_END)) : CpConstants.ZERO;
                idResWrap.score = idResWrap?.responseBody?.substringBetween(CpConstants.SCORE_BEGIN,CpConstants.SCORE_END) != null ? Decimal.valueOf(idResWrap?.responseBody?.substringBetween(CpConstants.SCORE_BEGIN,CpConstants.SCORE_END)) : CpConstants.ZERO ;
                idResWrap.finalResult = idResWrap.responseBody.substringBetween(CpConstants.OVERALLOUTCOME_BEGIN,CpConstants.OVERALLOUTCOME_END) != NULL ? idResWrap.responseBody.substringBetween(CpConstants.OVERALLOUTCOME_BEGIN,CpConstants.OVERALLOUTCOME_END) : CpConstants.BLANK;
                String fraudStore = idResWrap.responseBody.substringBetween(CpConstants.FRAUD_ASESSMENT_BEGIN,CpConstants.ASSESMENT_FACTOR_BEGIN) != NULL ? idResWrap.responseBody.substringBetween(CpConstants.FRAUD_ASESSMENT_BEGIN,CpConstants.ASSESMENT_FACTOR_BEGIN) :  CpConstants.BLANK;
                idResWrap.fraudAssesment = fraudStore.substringBetween(CpConstants.RESULT_BEGIN,CpConstants.RESULT_END) != NULL ? fraudStore.substringBetween(CpConstants.RESULT_BEGIN,CpConstants.RESULT_END) : CpConstants.BLANK;
                String evStore = idResWrap.responseBody.substringBetween(CpConstants.VERIFICATIONOUTCOME_BEGIN,CpConstants.VERIFICATIONOUTCOME_END) != NULL ? idResWrap.responseBody.substringBetween(CpConstants.VERIFICATIONOUTCOME_BEGIN,CpConstants.VERIFICATIONOUTCOME_END) : CpConstants.BLANK;
                idresWrap.evResponse = evStore.substringBetween(CpConstants.INDICATOR_BEGIN,CpConstants.INDICATOR_END) != NULL ? evStore.substringBetween(CpConstants.INDICATOR_BEGIN,CpConstants.INDICATOR_END) : CpConstants.BLANK;
                String  messageId = idResWrap.responseBody.substringBetween(CpConstants.MESSAGE_ID_BEGIN,CpConstants.MESSAGE_ID_END) != NULL ? idResWrap.responseBody.substringBetween(CpConstants.MESSAGE_ID_BEGIN,CpConstants.MESSAGE_ID_END) : CpConstants.BLANK;
                String assFacXml  = idResWrap.responseBody.substringBetween(CpConstants.ASSESMENT_FACTOR_BEGIN,CpConstants.ASSESSMENT_FACTOR_END)!=null?idResWrap.responseBody.substringBetween(CpConstants.ASSESMENT_FACTOR_BEGIN,CpConstants.ASSESSMENT_FACTOR_END):CpConstants.BLANK;
                if(!assFacXml.equals(CpConstants.BLANK)){
                    String kycBlock = assFacXml.substringBetween(CpConstants.KYC_PEP,CpConstants.ASSESSEMENT_END);
                    String sncBlock = assFacXml.substringBetween(CpConstants.KY_SNC, CpConstants.ASSESSEMENT_END);
                    if(kycBlock!=null){
                        idresWrap.pepRes = kycBlock.subStringBetween(CpConstants.RESULT_BEGIN,CpConstants.RESULT_END);
                    }
                    if(sncBlock!=null){
                        idResWrap.sncRes = sncBlock.subStringBetween(CpConstants.RESULT_BEGIN,CpConstants.RESULT_END);
                    }
                }
                if(idResWrap.finalResult == ConstantValues.idMatrix_overall_outcome_status_accept 
                    ||  idResWrap.finalResult == ConstantValues.idMatrix_overall_outcome_status_reject){
                    idResWrap.finalResultBoolean = true;
                }else if(idResWrap.finalResult == ConstantValues.timeout || idResWrap.finalResult == ConstantValues.error){
                        idResWrap.finalResultBoolean = false;
                }else{
                        throw new CustomException(ResponseMessenger.idMatrixErrorORTimeOut);
                }
                IDMatrix2Parser parser=new IDMatrix2Parser();
                parser.parseData(partyId,idResWrap.responseBody);
                if(idResWrap.finalResultBoolean == true && String.isNotBlank(idResWrap.finalResult)){
                    clcommon__Party__c partyObj = new clcommon__Party__c();
                    resp = idResWrap.finalResult;
                    partyObj.Id = partyId;
                    partyObj.ID_Matrix_Response__c = idResWrap.finalResult;
                    partyObj.ID_Matrix_Score__c = idResWrap.score;
                    partyObj.ID_Matrix_Threshold__c = idResWrap.threshold;
                    partyObj.ID_Matrix_Message_ID__c = messageId;
                    partyObj.Id_Matrix_Status__c = CpConstants.COMPLETED;
                    partyObj.ID_Matrix_EV_Response__c = idResWrap.evResponse;
                    partyObj.ID_Matrix_Fraud_Assesment_Response__c = idResWrap.fraudAssesment;
                    partyObj.Id_Matrix_Check__c = true;
                    partyObj.AML_Verified_Date__c = Date.today();
                    partyObj.Id_Matrix_Sanctions_Response__c = idResWrap.sncRes;
                    partyObj.Id_Matrix_KYC_PEP_Response__c = idResWrap.pepRes;
                    partyObj.Underwriting_Fail_Message__c = CpConstants.BLANK;
                    update partyObj;
                }         
                /**
                 * This block was added on 12th July 2022, to handle Service Unavailable scenarios
                 * We throw an custom exception in line 85 which is caught by the catchblock that parses the error response
                 * The catch block in turn throws a custom exception which the PostIDMBatch job takes care of
                 */
            }else if(res.getStatusCode() == CpConstants.FIVE_HUNDRED || res.getStatusCode() == CpConstants.FIVE_HUNDRED_TWO ){
                throw new CustomException(CpConstants.SERVICE_UNAVAILABLE);
            }else{
                /*************Throws exception if endpoint not found********************/
                throw new CustomException(ResponseMessenger.EndPoint_not_found);
            }            
        }catch(CustomException e){
            if(e.getMessage().equals(CpConstants.SERVICE_UNAVAILABLE)){
                String apiPayload = res.getBody();
                List<clcommon__Party__c> partyList=[SELECT  id, 
                                                            genesis__Application__c	 
                                                    FROM    clcommon__Party__c 
                                                    WHERE   id =: partyId
                                                    LIMIT 1];
                ServiceUnavailableHandler parser=new ServiceUnavailableHandler();
                parser.IDMatrix2ServiceUnavailableHandler(apiPayload,partyList[0].genesis__Application__c);
                throw new CustomException(CpConstants.SERVICE_UNAVAILABLE);
            }else {
                ExceptionManager.manageException(e);
                return null;
            }
        }catch (Exception ex) {
            ExceptionManager.manageException(ex);
            insert ExceptionManager.getCLCommonLog(ex,ResponseMessenger.INTFRAMEWORK);
            resp = CpConstants.ERRORINIDM2;
            if(ex.getTypeName() == CpConstants.CUSTOMEXCEPTIONTYPE){
                resp += ex.getMessage();
            }
        }
        return resp;
    }
}