/**
 * @description       : 
 * @author            : Supriyo Seni
 * @group             : 
 * @last modified on  : 04-13-2024
 * @last modified by  : Supriyo Seni
**/
public without sharing class F2FPrimaryContactController {
    /**
    * @description 
    * @author Supriyo Seni | 04-05-2024 
    * @param relationIdList 
    **/
    @InvocableMethod
    public static void updatePrimaryContactForPOA(List<Id> relationIdList) {
        try{
            Map<Id,List<clcommon__Party__c>> accountIdVsPartiesMap = new Map<Id,List<clcommon__Party__c>>();
            Set<Id> entityIdSet = new  Set<Id>();
            List<clcommon__Relationship__c> relationList = [SELECT id,
                                                                    clcommon__Entity__c,
                                                                    clcommon__Related_Entity__c,
                                                                    clcommon__Relationship__c,
                                                                    Primary_Contact__c,
                                                                    POA_Approved__c
                                                                FROM clcommon__Relationship__c
                                                                WHERE Id IN : relationIdList
                                                                AND clcommon__Relationship__r.Name = 'POA'
                                                                WITH SYSTEM_MODE];
            for(clcommon__Relationship__c relationshipObj : relationList){
                entityIdSet.add(relationshipObj.clcommon__Entity__c);
                entityIdSet.add(relationshipObj.clcommon__Related_Entity__c);
            }
            List<clcommon__Party__c> partyList = [SELECT id,
                                                            Primary_Contact__c,
                                                            clcommon__Account__c,
                                                            genesis__Application__c,
                                                            genesis__Application__r.genesis__Account__c
                                                    FROM clcommon__Party__c
                                                    WHERE clcommon__Account__c IN : entityIdSet
                                                    WITH SYSTEM_MODE];
            for(clcommon__Party__c partyObj : partyList){
                if(accountIdVsPartiesMap.containsKey(partyObj.clcommon__Account__c)){
                    List<clcommon__Party__c> accountPartyList = accountIdVsPartiesMap.get(partyObj.clcommon__Account__c);
                    accountPartyList.add(partyObj);
                    accountIdVsPartiesMap.put(partyObj.clcommon__Account__c,accountPartyList);
                }else{
                    accountIdVsPartiesMap.put(partyObj.clcommon__Account__c, new List<clcommon__Party__c>{partyObj});
                }
            }   
            updateEntityAccountParty(accountIdVsPartiesMap,relationList);
        }catch(Exception ex){
            //insert if any logs are generated
            clcommon__Log__c logObj = F2FUtil.insertlog(ex, F2FPrimaryContactController.class.getName());
            SecureDMLUtil.insertSObject(new List<clcommon__Log__c>{logObj}, false, AccessLevel.SYSTEM_MODE);
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 04-11-2024 
    * @param accountIdVsPartiesMap 
    * @param relationList 
    **/
    public static void updateEntityAccountParty(Map<Id,List<clcommon__Party__c>> accountIdVsPartiesMap,List<clcommon__Relationship__c> relationList){
        List<clcommon__Party__c> partyToUpdateList = new List<clcommon__Party__c>();
        List<clcommon__Relationship__c> relationToUpdateList = new List<clcommon__Relationship__c>();
        for(clcommon__Relationship__c relationshipObj : relationList){
            List<clcommon__Party__c> entityPartyList = accountIdVsPartiesMap.containsKey(relationshipObj.clcommon__Entity__c) ? 
                    accountIdVsPartiesMap.get(relationshipObj.clcommon__Entity__c) : null;
            List<clcommon__Party__c> relatedEntityPartyList = accountIdVsPartiesMap.containsKey(relationshipObj.clcommon__Related_Entity__c) ? 
                    accountIdVsPartiesMap.get(relationshipObj.clcommon__Related_Entity__c) : null;
            if(entityPartyList == null || relatedEntityPartyList == null){
                continue;
            }
            clcommon__Party__c entityAccountPartyObj = getUniqueEntityAccountParty(entityPartyList,relatedEntityPartyList,relationshipObj);
            // Only update if Primary Contact of parties is false
            if(entityAccountPartyObj == null){
                continue;
            }
            if(relationshipObj.POA_Approved__c){
                entityAccountPartyObj.Primary_Contact__c = true;
                relationshipObj.Primary_Contact__c = true;
                relationToUpdateList.add(relationshipObj);
                partyToUpdateList.add(entityAccountPartyObj);
            }
            if(!relationshipObj.POA_Approved__c){
                entityAccountPartyObj.Primary_Contact__c = false;
                relationshipObj.Primary_Contact__c = false;
                relationToUpdateList.add(relationshipObj);
                partyToUpdateList.add(entityAccountPartyObj);
            }
        }
        updateSobject(partyToUpdateList);
        updateSobject(relationToUpdateList);
    }

    /**
    * @description | Update operations
    * @author Supriyo Seni | 04-02-2024 
    * @param sObjectList 
    **/
    public static void updateSobject(List<Sobject> sObjectList){
        if(!sObjectList.isEmpty()){
            Database.update(sObjectList, true, AccessLevel.SYSTEM_MODE);
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 04-11-2024 
    * @param relatedEntityPartyList 
    * @param relationshipObj 
    * @return Set<Id> 
    **/
    public static Set<Id> getRelatedEntityAppIdSet(List<clcommon__Party__c> relatedEntityPartyList,clcommon__Relationship__c relationshipObj){
        Set<Id> relatedEntityAppIdSet = new Set<Id>();
        for(clcommon__Party__c relatedEntityPartyObj : relatedEntityPartyList){
            if(relatedEntityPartyObj.clcommon__Account__c == relationshipObj.clcommon__Related_Entity__c){
                relatedEntityAppIdSet.add(relatedEntityPartyObj.genesis__Application__c);
            }
        }
        return relatedEntityAppIdSet;
    }

    /**
    * @description 
    * @author Supriyo Seni | 04-11-2024 
    * @param entityPartyList 
    * @param relatedEntityPartyList 
    * @param relationshipObj 
    * @return clcommon__Party__c 
    **/
    public static clcommon__Party__c getUniqueEntityAccountParty( List<clcommon__Party__c> entityPartyList,List<clcommon__Party__c> relatedEntityPartyList,clcommon__Relationship__c relationshipObj){
        Set<Id> entityAppIdSet = new Set<Id>();
        Set<Id> relatedEntityAppIdSet = getRelatedEntityAppIdSet(relatedEntityPartyList,relationshipObj);
        List<clcommon__Party__c> filteredPartyList = new List<clcommon__Party__c>();
        for(clcommon__Party__c entityPartyObj : entityPartyList){
            if(entityPartyObj.clcommon__Account__c == relationshipObj.clcommon__Entity__c && relatedEntityAppIdSet.contains(entityPartyObj.genesis__Application__c)){
                entityAppIdSet.add(entityPartyObj.genesis__Application__c);
                filteredPartyList.add(entityPartyObj);
            }
        }
        Id uniqueAppId = validateCommonApplication(entityAppIdSet,relatedEntityAppIdSet,relationshipObj);
        for(clcommon__Party__c filteredPartyObj : filteredPartyList){
            if(uniqueAppId != null && filteredPartyObj.genesis__Application__c == uniqueAppId && filteredPartyObj.genesis__Application__r?.genesis__Account__c == relationshipObj.clcommon__Related_Entity__c){
                return filteredPartyObj;
            }
        }
        return null;
    }

    /**
    * @description 
    * @author Supriyo Seni | 04-11-2024 
    * @param entityAppIdSet 
    * @param relatedEntityAppIdSet 
    * @param relationshipObj 
    * @return Id 
    **/
    public static Id validateCommonApplication(Set<Id> entityAppIdSet, Set<Id> relatedEntityAppIdSet,clcommon__Relationship__c relationshipObj){
        try{
            Integer count = 0;
            Id uniqueAppId;
            for (Id entityAppId : entityAppIdSet) {
                if(relatedEntityAppIdSet.contains(entityAppId)) {
                    uniqueAppId = entityAppId;
                    count++;
                }
                if(count > 1){
                    throw new customException('More than one common Application ID found for clcommon__Relationship__c - ' + relationshipObj.id 
                            + 'Entity Application Ids - ' + entityAppIdSet + ' Related Entity Application Ids - ' +relatedEntityAppIdSet);
                }
            }
            if(count == 0){
                throw new customException('No Application found for Party Primary Contact Update clcommon__Relationship__c - ' + relationshipObj.id);
            }
            return uniqueAppId;
        }catch(Exception ex){
            //insert if any logs are generated
            clcommon__Log__c logObj = F2FUtil.insertlog(ex, F2FPrimaryContactController.class.getName());
            SecureDMLUtil.insertSObject(new List<clcommon__Log__c>{logObj}, false, AccessLevel.SYSTEM_MODE);
            return null;
        }
    }
    
}