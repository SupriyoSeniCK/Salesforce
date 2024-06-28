/**
 * @description       : Controller class to update Primary Contact field of party on Application creation
 * @author            : Supriyo Seni
 * @group             : Apex Class
 * @last modified on  : 04-14-2024
 * @last modified by  : Supriyo Seni
**/
public without sharing class F2FPartyPrimaryContactController {

    /**
    * @description | Invocable method for Pimary Contact Update flow
    * @author Supriyo Seni | 04-13-2024 
    * @param applicationIdList 
    **/
    @InvocableMethod
    public static void initiatePrimaryContactUpdate(List<Id> applicationIdList) {
        try{
            Set<Id> relatedEntityIdSet = new Set<Id>();
            Set<Id> entityIdSet = new Set<Id>();
            Set<Id> applicationIdSet = new Set<Id>();
            Set<Id> primaryAppIdSet = new Set<Id>();
            List<Map<Id,clcommon__Party__c>> idPartyMapList = new List<Map<Id,clcommon__Party__c>> ();
            Map<Id,clcommon__Party__c> appIdVsIndividualPartyMap = new Map<Id,clcommon__Party__c>();
            Map<Id,clcommon__Party__c> appIdVsFirstPartyMap = new Map<Id,clcommon__Party__c>();  
            Map<Id,clcommon__Party__c> appIdVsFirstPOAPartyMap = new Map<Id,clcommon__Party__c>();
            List<clcommon__Party__c> partyList = [SELECT id,
                                                            Primary_Contact__c,
                                                            clcommon__Account__c,
                                                            genesis__Application__c,
                                                            genesis__Application__r.genesis__Account__c,
                                                            Account_Legal_Entity__c,
                                                            Party_Type_Name__c
                                                    FROM clcommon__Party__c
                                                    WHERE genesis__Application__c IN : applicationIdList
                                                    WITH SYSTEM_MODE
                                                    ORDER BY createdDate];
            for(clcommon__Party__c partyObj : partyList){
                applicationIdSet.add(partyObj.genesis__Application__c);
                if(partyObj.Primary_Contact__c){
                    primaryAppIdSet.add(partyObj.genesis__Application__c);
                    continue;
                }
                entityIdSet.add(partyObj.clcommon__Account__c);
                if(!appIdVsFirstPartyMap.containsKey(partyObj.genesis__Application__c)){
                    appIdVsFirstPartyMap.put(partyObj.genesis__Application__c,partyObj);
                    relatedEntityIdSet.add(partyObj.clcommon__Account__c);
                }
                if(partyObj.Account_Legal_Entity__c == Folk2FolkConstantValues.INDIVIDUAL && partyObj.Party_Type_Name__c == Folk2FolkConstantValues.POWER_OF_ATTORNEY_PARTY_TYPE 
                        && !appIdVsIndividualPartyMap.containsKey(partyObj.genesis__Application__c)){
                    appIdVsIndividualPartyMap.put(partyObj.genesis__Application__c,partyObj);
                }
                if(partyObj.Party_Type_Name__c == Folk2FolkConstantValues.POWER_OF_ATTORNEY_PARTY_TYPE
                        && !appIdVsFirstPOAPartyMap.containsKey(partyObj.genesis__Application__c)){
                    appIdVsFirstPOAPartyMap.put(partyObj.genesis__Application__c,partyObj);
                }
            }
            // To exclude application which already has a Primary Contact Party
            applicationIdSet.removeAll(primaryAppIdSet);
            idPartyMapList.add(appIdVsFirstPartyMap);
            idPartyMapList.add(appIdVsIndividualPartyMap);
            idPartyMapList.add(appIdVsFirstPOAPartyMap);
            // Store relationships in a Map
            Map<String,List<clcommon__Relationship__c>> accountIdVsRelationMap = getRelationList(relatedEntityIdSet,entityIdSet);
            // Call for Party Updates
            partyPrimaryContactUpdate(applicationIdSet,idPartyMapList,accountIdVsRelationMap);
        }catch(Exception ex){
            //insert if any logs are generated
            clcommon__Log__c logObj = F2FUtil.insertlog(ex, F2FPartyPrimaryContactController.class.getName());
            SecureDMLUtil.insertSObject(new List<clcommon__Log__c>{logObj}, false, AccessLevel.SYSTEM_MODE);
        }
    }

    /**
    * @description | Fet POA Relationships
    * @author Supriyo Seni | 04-13-2024 
    * @param relatedEntityIdSet 
    * @param entityIdSet 
    * @return Map<Id, List<clcommon__Relationship__c>> 
    **/
    public static Map<String,List<clcommon__Relationship__c>>  getRelationList(Set<Id> relatedEntityIdSet,Set<Id> entityIdSet){
        Map<String,List<clcommon__Relationship__c>> accountIdVsRelationMap = new Map<String,List<clcommon__Relationship__c>>();
        String keyId;
        // Get POA relation list
        List<clcommon__Relationship__c> relationList = [SELECT id,
                                                            clcommon__Entity__c,
                                                            clcommon__Related_Entity__c,
                                                            clcommon__Relationship__c,
                                                            Primary_Contact__c,
                                                            POA_Approved__c
                                                        FROM clcommon__Relationship__c
                                                        WHERE clcommon__Entity__c IN : entityIdSet
                                                        AND clcommon__Related_Entity__c IN : relatedEntityIdSet
                                                        AND clcommon__Relationship__r.Name =: Folk2FolkConstantValues.POA_RECORD_TYPE
                                                        WITH SYSTEM_MODE];
        for(clcommon__Relationship__c relationObj : relationList){
            keyId = String.valueOf(relationObj.clcommon__Entity__c) + String.valueOf(relationObj.clcommon__Related_Entity__c);
            if(accountIdVsRelationMap.containsKey(keyId)){
                List<clcommon__Relationship__c> accountRelationList = accountIdVsRelationMap.get(keyId);
                accountRelationList.add(relationObj);
                accountIdVsRelationMap.put(keyId,accountRelationList);
            }else{
                accountIdVsRelationMap.put(keyId, new List<clcommon__Relationship__c>{relationObj});
            }
        }  
        return accountIdVsRelationMap;
    }

    /**
    * @description | Update Primary Contact in party
    * @author Supriyo Seni | 04-13-2024 
    * @param applicationIdSet 
    * @param idPartyMapList 
    * @param accountIdVsRelationMap 
    **/
    public static void partyPrimaryContactUpdate(Set<Id> applicationIdSet,List<Map<Id,clcommon__Party__c>> idPartyMapList,Map<String,List<clcommon__Relationship__c>> accountIdVsRelationMap){
        //List<Id> applicationIdList = appIdVsPartyMap.keySet();
        List<clcommon__Party__c> partyToUpdateList;
        List<clcommon__Relationship__c> relationToUpdateList;
        Map<Id,clcommon__Party__c> appIdVsFirstPartyMap = idPartyMapList[0];
        Map<Id,clcommon__Party__c> appIdVsIndividualPartyMap = idPartyMapList[1];  
        Map<Id,clcommon__Party__c> appIdVsFirstPOAPartyMap = idPartyMapList[2];
        Boolean isPOAApproved;
        String keyId;
        for(Id applicationId : applicationIdSet){
            isPOAApproved = false;
            // Check for relationship that is POA approved 
            if(appIdVsFirstPOAPartyMap?.get(applicationId) != null){
                keyId = (String.valueOf(appIdVsFirstPOAPartyMap.get(applicationId).clcommon__Account__c) + String.valueOf(appIdVsFirstPartyMap.get(applicationId).clcommon__Account__c));
                List<clcommon__Relationship__c> poaRelationList = accountIdVsRelationMap.get(keyId);
                if(!isListNullOrEmpty(poaRelationList) && poaRelationList[0].POA_Approved__c){
                    isPOAApproved = true;    
                    poaRelationList[0].Primary_Contact__c = true;
                    relationToUpdateList.add(poaRelationList[0]);      
                    clcommon__Party__c poaPartyObj = appIdVsFirstPOAPartyMap.get(applicationId);
                    poaPartyObj.Primary_Contact__c = true;
                    partyToUpdateList.add(poaPartyObj);
                }
            }
            // If POA Approved is false then check primary contact for first individual party
            if(!isPOAApproved && appIdVsIndividualPartyMap?.get(applicationId) != null){
                clcommon__Party__c partyObj = appIdVsIndividualPartyMap.get(applicationId);
                partyObj.Primary_Contact__c = true;
                partyToUpdateList.add(partyObj);
                keyId = (String.valueOf(appIdVsIndividualPartyMap.get(applicationId).clcommon__Account__c) + String.valueOf(appIdVsFirstPartyMap.get(applicationId).clcommon__Account__c));
                List<clcommon__Relationship__c> individualRelationList = accountIdVsRelationMap.get(keyId);
                if(!isListNullOrEmpty(individualRelationList)){
                    individualRelationList[0].Primary_Contact__c = true;
                    relationToUpdateList.add(individualRelationList[0]);      
                }
            }
        }
        updateSobject(partyToUpdateList);
        updateSobject(relationToUpdateList);
    }

    /**
    * @description | Chekc whethe list if null or size greater than one
    * @author Supriyo Seni | 04-13-2024 
    * @param sObjectList 
    * @return Boolean 
    **/
    public static Boolean isListNullOrEmpty(List<Sobject> sObjectList){
        if(sObjectList != null && sObjectList.size() == 1){
            return false;
        }
        return true;
    }
    /**
    * @description | Update operations
    * @author Supriyo Seni | 04-02-2024 
    * @param sObjectList 
    **/
    public static void updateSobject(List<Sobject> sObjectList){
        if(sObjectList != null && !sObjectList.isEmpty()){
            Database.update(sObjectList, true, AccessLevel.SYSTEM_MODE);
        }
    }

}