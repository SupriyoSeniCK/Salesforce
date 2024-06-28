/******************************************************************************************************************
 * Company             : Cloudkaptan Consultancy Services Pvt. Ltd.
 * Date                : 17/05/2021
 * Author              : Saurabh Anand
 * Last Modified By    : Priyanka Maharana
 * Last Modified Date  : 23/11/2023
 * Description         : This Controller Class is used for Integration Framework to call Acuris API.
                            This Class is called when an Investor Application is approved or a Borrower Application status is changed to 'Credit Approved & Ready for Initial Review'.
                            It can also be called for a particular account for send that Account's Information to Acuris.
******************************************************************************************************************/
global with sharing class AcurisController {

    public class FlowInputs{
        @InvocableVariable(required=true)
        public String accountId;
        @InvocableVariable(required=true)
        public  String appId;
        @InvocableVariable(required=true)
        public  String type;
        @InvocableVariable(required=true)
        public  String borrowerType;
        @InvocableVariable(required=true)
        public  String legalEnity;
        @InvocableVariable(required=true)
        public String appRecordType;
    }

    // this method is called from Lightning button on Account page to remove an account from Acuris
    @AuraEnabled
    public static String makeRemoveBusinessCallout(String accountId) {
        
        String response;
        List<clcommon__Party__c> party;
        List<clcommon__Party__c> updateParty = new List<clcommon__Party__c>();
        Account account;
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, SObject> existingAccountIdVsAccount;
        Map<String,Object> requestparamMap = new Map<String,Object>();
        Map<String,Object> queryIdMap = new Map<String,Object>();
        List<genesis__Applications__c> appList = new List<genesis__Applications__c>();
        String borrType;
        String legalEnity;
        String appRecordType;
        
        try {
            if(String.isEmpty(accountId)) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.EMPTY_PARAMETER);
            }

            appList = [SELECT Id,
                            Borrower_Type__c,
                            Record_type_name__c
                        FROM genesis__Applications__c
                        WHERE genesis__Account__c = :accountId
                        ORDER BY LastModifiedDate DESC
                        LIMIT 1];
            
            if(appList.isEmpty()){
                throw new intframework.IntegrationException(Folk2FolkConstantValues.APPLICATION_NOT_FOUND);
            }
            accountIdSet.add(accountId);
            existingAccountIdVsAccount = Folk2FolkQueriesUtility.fetchAccount(accountIdSet);
            if(existingAccountIdVsAccount.get(accountId) == null) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.ACCOUNT_NOT_FOUND);
            }
            account = (Account)existingAccountIdVsAccount.get(accountId);

            requestparamMap.put(Folk2FolkIntegrationConstants.MONITOR_RECORD_ID, account.CLS_Account_Id__c);

            borrType = appList[0].Borrower_Type__c;
            legalEnity = account.Legal_Entity_Name__c;
            appRecordType = appList[0].Record_type_name__c;

            if(borrType.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2723);
            } else if(borrType.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && legalEnity.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2726);
            } else if((borrType.equalsIgnorecase(Folk2FolkConstantValues.SIPP) || borrType.equalsIgnorecase(Folk2FolkConstantValues.SSAS) || borrType.equalsIgnorecase(Folk2FolkConstantValues.TRUST) || borrType.equalsIgnorecase(Folk2FolkConstantValues.COUNCIL) || borrType.equalsIgnorecase(Folk2FolkConstantValues.LIMITED)) 
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.SIPP) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.SSAS) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.TRUST) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.COUNCIL) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.LIMITED))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.INVESTOR_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2727);
            } else if((borrType.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || borrType.equalsIgnorecase(Folk2FolkConstantValues.IFISA) || borrType.equalsIgnorecase(Folk2FolkConstantValues.JOINT))
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.IFISA) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.JOINT))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.INVESTOR_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2725);
            } else if((borrType.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || borrType.equalsIgnorecase(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE))
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2724);
            }

            intframework.AbstractIntegrationService baseIntegrationService = intframework.IntegrationServiceFactory.getBaseIntegrationService();
            intframework.baseIntegrationResponse responseObject;
            if(account.Legal_Entity_Name__c.equals(Folk2FolkConstantValues.INDIVIDUAL)) {
                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                Folk2FolkIntegrationConstants.REMOVE_PERSON_API_TYPE,
                                                                                                                                queryIdMap,
                                                                                                                                requestparamMap);
            } else {
                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                Folk2FolkIntegrationConstants.REMOVE_BUSINESS_API_TYPE,
                                                                                                                                queryIdMap,
                                                                                                                                requestparamMap);
            }
            if(responseObject == null) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.RESPONSE_IS_NULL);
            }
            
            response = responseObject.getBody();
            if(responseObject.response.getStatusCode() == Folk2FolkIntegrationConstants.STATUS_CODE_200) {
                party = [SELECT id,
                                clcommon__Account__c,
                                genesis__Application__c,
                                Acuris_Outcome__c
                            FROM clcommon__Party__c
                            WHERE clcommon__Account__c =: accountId
                            AND clcommon__Active__c = true];

                for(clcommon__Party__c eachParty : party) {
                    eachParty.Acuris_Outcome__c = Folk2FolkIntegrationConstants.DELETED_FROM_ACURIS;
                    updateParty.add(eachParty);
                }
                if(!updateParty.isEmpty()) {
                    update updateParty;
                }
                return Folk2FolkIntegrationConstants.DELETED_FROM_ACURIS;
            }
            return responseObject.response.getStatus();
        } catch(Exception e) {
            F2FUtil.insertIntegrationExceptionLog(e, AcurisController.class.getName());
            return e.getMessage();
        }
    }

    /**
    * @description 
    * @author Priyanka | 21/11/2023
    **/
    @InvocableMethod(label='Borrower Application Acuris Callout' description='Borrower Application - Acuris will get called on status Credit Approved & Ready for Initial Review' category= 'Identity')
    public static void makeCalloutFromFlow(List<FlowInputs> flowInputsList){
        try{
            for(FlowInputs flowinput: flowInputsList){
                if(String.isNotBlank(flowinput.borrowerType) 
                    && ((flowinput.borrowerType).equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL)
                        || (flowinput.borrowerType).equalsIgnorecase(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE))){
                    makePostPersonCallout(flowinput.accountId, flowinput.appId, flowinput.type, flowinput.borrowerType, flowinput.legalEnity, flowinput.appRecordType);
                } else if(String.isNotBlank(flowinput.borrowerType) 
                    && (flowinput.borrowerType).equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE)) {
                    makePostBusinessCallout(flowinput.accountId, flowinput.appId, flowinput.type, flowinput.borrowerType, flowinput.legalEnity, flowinput.appRecordType);
                }
            }
        } catch(Exception e) {
            DataUtil.insertLog(AcurisController.class.getname(), e);
        }
    }

    /* this method is called when an Investor Application is approved or a Borrower Application status is Credit Approved & Ready for Initial Review
        to send each applicatnt's information to Acuris when Borrower type is of type Non-Individual */
    webservice static void makePostBusinessCallout(String accountId, String appId, String type, String borrowerType, String legalEnity, String appRecordType) {
        
        List<clcommon__Party__c> partiesApplication;
        Account account;
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, SObject> existingAccountIdVsAccount;
        try{
            if(String.isEmpty(accountId) || String.isEmpty(appId) || String.isEmpty(type) || String.isEmpty(borrowerType) 
                || String.isEmpty(legalEnity) || String.isEmpty(appRecordType)) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.EMPTY_PARAMETER);
            }

            partiesApplication = [SELECT id,
                                        Party_Type_Name__c,
                                        clcommon__Account__c,
                                        genesis__Application__r.Borrower_Type__c,
                                        clcommon__Account__r.Legal_Entity_Name__c,
                                        genesis__Application__r.Record_type_name__c
                                    FROM clcommon__Party__c
                                    WHERE genesis__Application__c =: appId
                                    AND clcommon__Active__c = true
                                    AND Party_Type_Name__c NOT IN: Folk2FolkIntegrationConstants.NON_INDIVIDUAL_PARTY_TYPES];

            for(clcommon__Party__c eachParty : partiesApplication) {
                // calling Future method to send each Individual type account's information to Acuris
                makePostPersonCallout(eachParty.clcommon__Account__c, appId, type, eachParty.genesis__Application__r.Borrower_Type__c, eachParty.clcommon__Account__r.Legal_Entity_Name__c, eachParty.genesis__Application__r.Record_type_name__c);
            }
            accountIdSet.add(accountId);
            existingAccountIdVsAccount = Folk2FolkQueriesUtility.fetchAccount(accountIdSet);
            if(existingAccountIdVsAccount.get(accountId) == null) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.ACCOUNT_NOT_FOUND);
            }
            account = (Account)existingAccountIdVsAccount.get(accountId);
            if(!account.Legal_Entity_Name__c.equals(Folk2FolkConstantValues.IFISA)
                    && !account.Legal_Entity_Name__c.equals(Folk2FolkConstantValues.JOINT_PARTNER)) {
                if(type.equals(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE)) {
                    // Borrower type is send from application status change sending Business type account's information to Acuris
                    postBusinessCallout(accountId, appId, borrowerType, legalEnity, appRecordType);
                } else if(type.equals(Folk2FolkIntegrationConstants.COMPANY_INVESTOR)) {
                    // sending Business type account's information to Acuris
                    postBusinessCallout(accountId, appId, borrowerType, legalEnity, appRecordType);
                }
            }
        } catch(Exception e) {
            F2FUtil.insertIntegrationExceptionLog(e, AcurisController.class.getName());
        }
    }

    /* this method is called when an Investor Application is approved or a Borrower Application status is Credit Approved & Ready for Initial Review
        to send each applicant's information to Acuris when Borrower type is of type Individual
        and this method is also used to send each Individual type account's information of Non-Individual applications to Acuris */
    @future(callout=true)
    webservice static void makePostPersonCallout(String accountId, String appId, String type, String borrowerType, String legalEnity, String appRecordType) {
        
        String response;
        List<clcommon__Party__c> party;
        Account account;
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, SObject> existingAccountIdVsAccount;
        List<clcommon__Relationship__c> individualRelationship = new List<clcommon__Relationship__c>();
        Map<String,Object> requestparamMap = new Map<String,Object>();
        Map<String,Object> queryIdMap = new Map<String,Object>();
        
        try{
            if(String.isEmpty(accountId) || String.isEmpty(appId) || String.isEmpty(type) || String.isEmpty(borrowerType) 
                || String.isEmpty(legalEnity) || String.isEmpty(appRecordType)) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.EMPTY_PARAMETER);
            }
            accountIdSet.add(accountId);
            existingAccountIdVsAccount = Folk2FolkQueriesUtility.fetchAccount(accountIdSet);
            if(existingAccountIdVsAccount.get(accountId) == null) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.ACCOUNT_NOT_FOUND);
            }
            account = (Account)existingAccountIdVsAccount.get(accountId);
            if(account.Legal_Entity_Name__c.equals(Folk2FolkConstantValues.IFISA)
                    || account.Legal_Entity_Name__c.equals(Folk2FolkConstantValues.JOINT_PARTNER)) {
                individualRelationship = [SELECT Id,
                                                clcommon__Entity__c,
                                                clcommon__Related_Entity__c,
                                                clcommon__Relationship__r.Name
                                            FROM clcommon__Relationship__c
                                            WHERE clcommon__Related_Entity__c =: accountId
                                            AND clcommon__Entity__c != null
                                            AND (clcommon__Relationship__r.Name =: Folk2FolkConstantValues.INDIVIDUAL
                                                OR clcommon__Relationship__r.Name =: Folk2FolkConstantValues.JOINT_PARTNER_ROLE)];

                if(individualRelationship.isEmpty()) {
                    throw new intframework.IntegrationException(Folk2FolkConstantValues.RELATIONSHIP_NOT_FOUND);
                }
                queryIdMap.put(Folk2FolkConstantValues.ACCOUNT_ID, individualRelationship[0].clcommon__Entity__c);
            } else {
                queryIdMap.put(Folk2FolkConstantValues.ACCOUNT_ID, accountId);
            }

            if(borrowerType.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2723);
            } else if(borrowerType.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && legalEnity.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2726);
            } else if((borrowerType.equalsIgnorecase(Folk2FolkConstantValues.SIPP) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.SSAS) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.TRUST) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.COUNCIL) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.LIMITED)) 
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.SIPP) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.SSAS) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.TRUST) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.COUNCIL) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.LIMITED))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.INVESTOR_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2727);
            } else if((borrowerType.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.IFISA) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.JOINT))
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.IFISA) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.JOINT))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.INVESTOR_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2725);
            } else if((borrowerType.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE))
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2724);
            }

            // Calling Integration Framework
            intframework.AbstractIntegrationService baseIntegrationService = intframework.IntegrationServiceFactory.getBaseIntegrationService();
            intframework.baseIntegrationResponse responseObject;
            responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                            Folk2FolkIntegrationConstants.POST_PERSON_API_TYPE,
                                                                                                                            queryIdMap,
                                                                                                                            requestparamMap);

            if(responseObject == null) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.RESPONSE_IS_NULL);
            }
            
            response = responseObject.getBody();
            response = response.replace(Folk2FolkIntegrationConstants.OPENING_BRACKETS, '');
            response = response.replace(Folk2FolkIntegrationConstants.CLOSING_BRACKETS, '');
            response = response.replace(Folk2FolkIntegrationConstants.DOUBLE_QUOTES, '');

            party = [SELECT id,
                            clcommon__Account__c,
                            genesis__Application__c,
                            Acuris_Outcome__c,
                            clcommon__Account__r.CLS_Account_Id__c
                        FROM clcommon__Party__c
                        WHERE genesis__Application__c =: appId
                        AND clcommon__Account__c =: accountId
                        AND clcommon__Active__c = true];

            if(party.isEmpty()) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.PARTY_ID_NOT_FOUND);
            }
            if(response.equalsIgnorecase(Folk2FolkIntegrationConstants.OK) || response.equalsIgnorecase(Folk2FolkIntegrationConstants.CREATED)) {
                party[0].Acuris_Outcome__c = Folk2FolkIntegrationConstants.ADDED_TO_ACURIS;
            } else {
                party[0].Acuris_Outcome__c = response;
            }
            upsert party;
        } catch(Exception e) {
            F2FUtil.insertIntegrationExceptionLog(e, AcurisController.class.getName());
        }
    }

    // this method is used to send each Business type account's information of Non-Individual applications to Acuris
    @future(callout=true)
    public static void postBusinessCallout(String accountId, String appId, String borrowerType, String legalEnity, String appRecordType) {
        String response;
        List<clcommon__Party__c> party;
        Map<String,Object> requestparamMap = new Map<String,Object>();
        Map<String,Object> queryIdMap = new Map<String,Object>();
        
        try{
            if(String.isEmpty(accountId) || String.isEmpty(appId) || String.isEmpty(borrowerType) 
                || String.isEmpty(legalEnity) || String.isEmpty(appRecordType)) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.EMPTY_PARAMETER);
            }
            queryIdMap.put(Folk2FolkConstantValues.ACCOUNT_ID, accountId);

            if(borrowerType.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2723);
            } else if(borrowerType.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && legalEnity.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2726);
            } else if((borrowerType.equalsIgnorecase(Folk2FolkConstantValues.SIPP) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.SSAS) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.TRUST) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.COUNCIL) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.LIMITED)) 
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.SIPP) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.SSAS) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.TRUST) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.COUNCIL) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.LIMITED))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.INVESTOR_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2727);
            } else if((borrowerType.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.IFISA) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.JOINT))
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.IFISA) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.JOINT))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.INVESTOR_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2725);
            } else if((borrowerType.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || borrowerType.equalsIgnorecase(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE))
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2724);
            }

            // Calling Integration Framework
            intframework.AbstractIntegrationService baseIntegrationService = intframework.IntegrationServiceFactory.getBaseIntegrationService();
            intframework.baseIntegrationResponse responseObject;
            responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                            Folk2FolkIntegrationConstants.POST_BUSINESS_API_TYPE,
                                                                                                                            queryIdMap,
                                                                                                                            requestparamMap);
            
            if(responseObject == null) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.RESPONSE_IS_NULL);
            }
            
            response = responseObject.getBody();
            response = response.replace(Folk2FolkIntegrationConstants.OPENING_BRACKETS, '');
            response = response.replace(Folk2FolkIntegrationConstants.CLOSING_BRACKETS, '');
            response = response.replace(Folk2FolkIntegrationConstants.DOUBLE_QUOTES, '');
            
            party = [SELECT id,
                            clcommon__Account__c,
                            genesis__Application__c,
                            Acuris_Outcome__c,
                            clcommon__Account__r.CLS_Account_Id__c
                        FROM clcommon__Party__c
                        WHERE genesis__Application__c =: appId
                        AND clcommon__Active__c = true
                        AND clcommon__Account__c =: accountId];

            if(party.isEmpty()) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.PARTY_ID_NOT_FOUND);
            }
            if(response.equalsIgnorecase(Folk2FolkIntegrationConstants.OK) || response.equalsIgnorecase(Folk2FolkIntegrationConstants.CREATED)) {
                party[0].Acuris_Outcome__c = Folk2FolkIntegrationConstants.ADDED_TO_ACURIS;
            } else {
                party[0].Acuris_Outcome__c = response;
            }
            upsert party;
        } catch(Exception e) {
            F2FUtil.insertIntegrationExceptionLog(e, AcurisController.class.getName());
        }
    }

    /* this method is called from Skuid button on Party tab of Application to send a particular account's information to Acuris
        whenever there is error on sending each account's information when an Investor is approved or when an application
        is Ready to fund, this method is also called to edit any particular account's information from Acuris */
    webservice static String postAccountCallout(String accountId,
                                                    String partyId,
                                                    String borrowerType,
                                                    String recordType,
                                                    Boolean mainAccount,
                                                    Boolean limited,
                                                    Boolean post,
                                                    String borrType,
                                                    String legalEnity,
                                                    String appRecordType) {
        
        String response;
        List<clcommon__Party__c> party;
        intframework.baseIntegrationResponse responseObject;
        Map<String,Object> requestparamMap = new Map<String,Object>();
        Map<String,Object> queryIdMap = new Map<String,Object>();
        
        try{
            if(String.isEmpty(accountId) || String.isEmpty(partyId) || String.isEmpty(borrowerType) || String.isEmpty(recordType) || mainAccount == null 
                || limited == null || post == null || String.isEmpty(borrType) || String.isEmpty(legalEnity) || String.isEmpty(appRecordType)) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.EMPTY_PARAMETER);
            }
            queryIdMap.put(Folk2FolkConstantValues.ACCOUNT_ID, accountId);

            if(borrType.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2723);
            } else if(borrType.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && legalEnity.equalsIgnorecase(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE) && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2726);
            } else if((borrType.equalsIgnorecase(Folk2FolkConstantValues.SIPP) || borrType.equalsIgnorecase(Folk2FolkConstantValues.SSAS) || borrType.equalsIgnorecase(Folk2FolkConstantValues.TRUST) || borrType.equalsIgnorecase(Folk2FolkConstantValues.COUNCIL) || borrType.equalsIgnorecase(Folk2FolkConstantValues.LIMITED)) 
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.SIPP) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.SSAS) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.TRUST) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.COUNCIL) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.LIMITED))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.INVESTOR_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2727);
            } else if((borrType.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || borrType.equalsIgnorecase(Folk2FolkConstantValues.IFISA) || borrType.equalsIgnorecase(Folk2FolkConstantValues.JOINT))
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.IFISA) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.JOINT))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.INVESTOR_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2725);
            } else if((borrType.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || borrType.equalsIgnorecase(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE))
                && (legalEnity.equalsIgnorecase(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE) || legalEnity.equalsIgnorecase(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE))
                && appRecordType.equalsIgnorecase(Folk2FolkConstantValues.BORROWER_APPLICATION)){
                requestparamMap.put(Folk2FolkIntegrationConstants.WORK_LIST_ID, Folk2FolkIntegrationConstants.WORKLIST_2724);
            }
            intframework.AbstractIntegrationService baseIntegrationService = intframework.IntegrationServiceFactory.getBaseIntegrationService();

            // checking application record type (Borrower or Investor)
            if(recordType.equals(Folk2FolkConstantValues.BORROWER_RECORD_TYPE)) {
                // checking account type (Individual or Business)
                if(borrowerType.equals(Folk2FolkIntegrationConstants.BUSINESS)) {
                    // checking company type (Limited or Non-limited)
                    if(limited) {
                        // checking if account is of Application's main account (Borrower or Investor) or Additional applicant's account
                        if(mainAccount) {
                            // checking request type (POST or PUT)
                            if(post) {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.POST_BUSINESS_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            } else {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.PUT_BUSINESS_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            }
                        } else {
                            if(post) {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.POST_PERSON_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            } else {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.PUT_PERSON_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            }
                        }
                    } else {
                        if(!mainAccount) {
                            if(post) {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.POST_PERSON_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            } else {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.PUT_PERSON_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            }
                        } else {
                            throw new intframework.IntegrationException(Folk2FolkIntegrationConstants.NON_LIMITED_BUSINESS_ACCOUNT_CAN_NOT_BE_ADDED);
                        }
                    }
                } else {
                    if(post) {
                        responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                        Folk2FolkIntegrationConstants.POST_PERSON_API_TYPE,
                                                                                                                                        queryIdMap,
                                                                                                                                        requestparamMap);
                    } else {
                        responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                        Folk2FolkIntegrationConstants.PUT_PERSON_API_TYPE,
                                                                                                                                        queryIdMap,
                                                                                                                                        requestparamMap);
                    }
                }
            } else {
                if(borrowerType.equals(Folk2FolkIntegrationConstants.BUSINESS)) {
                    if(limited) {
                        if(mainAccount) {
                            if(post) {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.POST_BUSINESS_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            } else {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.PUT_BUSINESS_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            }
                        } else {
                            if(post) {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.POST_PERSON_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            } else {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.PUT_PERSON_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            }
                        }
                    } else {
                        if(!mainAccount) {
                            if(post) {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.POST_PERSON_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            } else {
                                responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                                Folk2FolkIntegrationConstants.PUT_PERSON_API_TYPE,
                                                                                                                                                queryIdMap,
                                                                                                                                                requestparamMap);
                            }
                        } else {
                            throw new intframework.IntegrationException(Folk2FolkIntegrationConstants.NON_LIMITED_BUSINESS_ACCOUNT_CAN_NOT_BE_ADDED);
                        }
                    }
                } else {
                    if(post) {
                        responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                        Folk2FolkIntegrationConstants.POST_PERSON_API_TYPE,
                                                                                                                                        queryIdMap,
                                                                                                                                        requestparamMap);
                    } else {
                        responseObject = (intframework.BaseIntegrationResponse)baseIntegrationService.runSynchronousIntegrationService(Folk2FolkIntegrationConstants.ACURIS_INTEGRATION_FAMILY,
                                                                                                                                        Folk2FolkIntegrationConstants.PUT_PERSON_API_TYPE,
                                                                                                                                        queryIdMap,
                                                                                                                                        requestparamMap);
                    }
                }
            }
            if(responseObject == null) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.RESPONSE_IS_NULL);
            }
            
            response = responseObject.getBody();
            response = response.replace(Folk2FolkIntegrationConstants.OPENING_BRACKETS, '');
            response = response.replace(Folk2FolkIntegrationConstants.CLOSING_BRACKETS, '');
            response = response.replace(Folk2FolkIntegrationConstants.DOUBLE_QUOTES, '');

            party = [SELECT id,
                            clcommon__Account__c,
                            clcommon__Account__r.CLS_Account_Id__c,
                            genesis__Application__c,
                            Acuris_Outcome__c
                        FROM clcommon__Party__c
                        WHERE id =: partyId 
                        AND clcommon__Active__c = true
                        LIMIT 1];

            if(party.isEmpty()) {
                throw new intframework.IntegrationException(Folk2FolkConstantValues.PARTY_ID_NOT_FOUND);
            }
            if(post) {
                if(response.equalsIgnorecase(Folk2FolkIntegrationConstants.OK) || response.equalsIgnorecase(Folk2FolkIntegrationConstants.CREATED)) {
                    party[0].Acuris_Outcome__c = Folk2FolkIntegrationConstants.ADDED_TO_ACURIS;
                } else {
                    party[0].Acuris_Outcome__c = response;
                }
                upsert party;
                return party[0].Acuris_Outcome__c;
            } else {
                if(!String.isBlank(response)) {
                    party[0].Acuris_Outcome__c = response;
                    upsert party;
                    return response;
                }
                return Folk2FolkConstantValues.SUCCESS_MESSAGE;
            }
        } catch(Exception e) {
            F2FUtil.insertIntegrationExceptionLog(e, AcurisController.class.getName());
            return e.getMessage();
        }
    }
}