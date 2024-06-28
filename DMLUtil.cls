/**
 * @description       : DMLUtil uill class provide  util method for database operation
 * @author            : Supriyo Seni
 * @group             : CK
 * @last modified on  : 04-25-2024
 * @last modified by  : Supriyo Seni
**/

public inherited sharing class DMLUtil {
    
    /**
    * @description | The Method inserts a list of sObject after checking the user's permission
    * @author Supriyo Seni | 04-25-2024 
    * @param sObjectList 
    * @param allOrNone 
    * @return database.saveResult[] 
    **/
    public static database.saveResult[] insertSObjectList(List<sObject> sObjectList, Boolean allOrNone ){
        database.saveResult[] src ;
        if(sObjectList == null || sObjectList?.size()==0){
            return null;
        }
        if(sObjectList[0].getSObjectType().getDescribe().isCreateable()){
            src = database.insert(sObjectList , allOrNone); 
        }else{
            throw new CustomException('DML is not allowed for this user for ' + sObjectList);
        } 
        return src;  
    }

    /**
    * @description | The Method updates a list of sObject after checking the user's permission
    * @author Supriyo Seni | 04-25-2024 
    * @param sObjectList 
    * @param allOrNone 
    * @return database.saveResult[] 
    **/
    public static database.saveResult[] updateSObjectList(List<sObject> sObjectList , Boolean allOrNone){
        database.saveResult[] src ;
        if(sObjectList == null || sObjectList?.size()==0){
            return null;
        }
        if(sObjectList[0].getSObjectType().getDescribe().isUpdateable()){
            src = database.update(sObjectList , allOrNone); 
        }else{
            throw new CustomException('DML is not allowed for this user for ' + sObjectList );
        }
        return src;   
    }

    /**
    * @description | The Method upserts a list of sObject after checking the user's permission
    * @author Supriyo Seni | 04-25-2024 
    * @param sObjectList 
    * @param allOrNone 
    * @return database.upsertResult[] 
    **/
    public static database.upsertResult[] upsertSObjectList(List<sObject> sObjectList , Boolean allOrNone){
        database.upsertResult[] src ;
        if(sObjectList == null || sObjectList?.size()==0){
            return null;
        }
        if(sObjectList[0].getSObjectType().getDescribe().isCreateable() && sObjectList[0].getSObjectType().getDescribe().isUpdateable() ){
            src = database.upsert(sObjectList , allOrNone); 
        }else{
            throw new CustomException('DML is not allowed for this user for ' + sObjectList );
        }  
        return src; 
    }

    /**
    * @description | The Method deletes a list of sObject after checking the user's permission
    * @author Supriyo Seni | 04-25-2024 
    * @param sObjectList 
    * @param allOrNone 
    * @return database.DeleteResult[] 
    **/
    public static database.DeleteResult[] deleteSObjectList(List<sObject> sObjectList , Boolean allOrNone){
        database.DeleteResult[] src ;
        if(sObjectList == null || sObjectList?.size()==0){
            return null;
        }
        if(sObjectList[0].getSObjectType().getDescribe().isDeletable() ){
            src = database.delete(sObjectList , allOrNone); 
        }else{
            throw new CustomException('DML is not allowed for this user for ' + sObjectList );
        }  
        return src; 
    }


    /**
    * @description | The Method inserts a list of sObject based on access level passed as a parameter
    * @author Supriyo Seni | 04-25-2024 
    * @param sObjectList 
    * @param allORNone 
    * @param accessLevel 
    * @return database.SaveResult[] 
    **/
    public static database.SaveResult[] insertSObjectList(List<sObject> sObjectList, Boolean allORNone, System.AccessLevel accessLevel){
        if(sObjectList == null || sObjectList.isEmpty()){
            return null;
        }
        Database.SaveResult[] saveResult = Database.insert(sObjectList, allORNone, accessLevel);
        return saveResult;
    }

    /**
    * @description | The Method updates a list of sObject based on access level passed as a parameter
    * @author Supriyo Seni | 04-25-2024 
    * @param sObjectList 
    * @param allORNone 
    * @param accessLevel 
    * @return database.SaveResult[] 
    **/
    public static database.SaveResult[] updateSObjectList(List<sObject> sObjectList, Boolean allORNone, System.AccessLevel accessLevel){
        if(sObjectList == null || sObjectList.isEmpty()){
            return null;
        }
        Database.SaveResult[] updateResult = Database.update(sObjectList, allORNone, accessLevel);
        return updateResult;
    }

    /**
    * @description | This Method upserts a list of sObject based on access level passed as a parameter
    * @author Supriyo Seni | 04-25-2024 
    * @param sObjectList 
    * @param allORNone 
    * @param accessLevel 
    * @return database.UpsertResult[] 
    **/
    public static database.UpsertResult[]  upsertSObjectList(List<sObject> sObjectList, Boolean allORNone, System.AccessLevel accessLevel){
        if( sObjectList == null || sObjectList.isEmpty()){
            return null;
        }
        Database.UpsertResult[] upsertResult = Database.upsert(sObjectList, allORNone, accessLevel);
        return upsertResult;
    }

    /**
    * @description | Method deletes a list of sObject based on access level passed as a parameter
    * @author Supriyo Seni | 04-25-2024 
    * @param sObjectList 
    * @param allORNone 
    * @param accessLevel 
    * @return database.DeleteResult[] 
    **/
    public static database.DeleteResult[]  deleteSObjectList(List<sObject> sObjectList, Boolean allORNone, System.AccessLevel accessLevel){
        if(sObjectList == null || sObjectList.isEmpty()){
            return null;
        }
        database.DeleteResult[] deleteResult = Database.delete(sObjectList, allORNone, accessLevel);
        return deleteResult;
    }
}