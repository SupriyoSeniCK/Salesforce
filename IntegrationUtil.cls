/*********************************************************************************************************
Class            : IntegrationUtil
Description      : Util Class for Third Party Integration
Created Date     : 14/08/2023
Developer        : Supriyo Seni
last Modified By : Supriyo Seni
**********************************************************************************************************/
public inherited sharing class IntegrationUtil {

    /************************************************************************
     * @Description : General method to update requestParamMap with key and values
     * @params     : Map of String and Object AND Party
     * @returnType : Map of String and Object
    *************************************************************************/  
    public static Map<String, Object> validateMapValues(Map<String, Object>  requestParamMap,String mapKey, String mapValue){
        if(mapValue!=null){
            requestParamMap.put(mapKey, mapValue);
        }
        return requestParamMap;
    }

    /************************************************************************
     * @Description : General method to throw exception after null value found
     * @params     : Object and exception message
     * @returnType : void
    *************************************************************************/  
    public static void throwNullCaseException(Object obj,String excpMsg){
        if(obj == null){
            throw new CustomException(ExcpMsg);
        }
    }

    /************************************************************************
     * @Description : General method to throw exception if List<Object> is null or of size zero.
     * @params     : Object and exception message
     * @returnType : void
    *************************************************************************/  
    public static void throwEmptyListException(List<Object> objList,String excpMsg){
        if(objList == null || objList.isEmpty()){
            throw new CustomException(ExcpMsg);
        }
    }

    /**
    * @description This method can be used to generate serialize response in prettier format supprasing the null values
    * @author Supriyo Seni | 08-28-2023 
    * @param objList 
    * @return String 
    **/
    public static String serializeResponse(List<Object> objList){
        return (objList.size()>1) ? JSON.serializePretty(objList,true) : JSON.serializePretty(objList[0],true);
    }

    /**
    * @description This method can be used to check if the input string is within the given length or not.
    * @author Supriyo Seni | 09-04-2023 
    * @param str 
    * @param startLength 
    * @param endLength 
    * @return Boolean 
    **/
    public static Boolean isStringWithinLength(String str, Integer startLength, Integer endLength){
        return ((str.trim().length() >= startLength && str.trim().length() <= endLength));
    }

    /**
    * @description This method can be used to validate a email address
    * @author Supriyo Seni | 09-05-2023 
    * @param email 
    * @return Boolean 
    **/
    public static Boolean validateEmail(String email) {
        List<String> invalidDomains = AggregatorConstants.INVALID_EMAIL_DOMAINS.split(EquifaxIntegrationConstants.COMMA);
        String domainPart = email.split(AggregatorConstants.AT_SIGN)[AggregatorConstants.ONE];
        for (String invalidDomain : invalidDomains) {
            if (domainPart.contains(invalidDomain)) {
                return false;
            }
        }
        Pattern emailPattern = Pattern.compile(AggregatorConstants.EMAIL_REGEX);
        Matcher emailMatcher = emailPattern.matcher(email);
        return emailMatcher.matches();
    }

    /**
    * @description This method can be used to return the updated payload payload after replacing the replaced part
    * @author Supriyo Seni | 09-05-2023 
    * @param payload 
    * @param toReplace 
    * @param obj 
    * @return String 
    **/
    public static String replaceApiPayload(String payload, String toReplace, object obj){
        String newValue;
        if(obj != null && String.isNotBlank(String.valueOf(obj))){
            newValue = String.valueOf(obj);
        }else{
            toReplace = AggregatorConstants.DOUBLE_QUOTE + toReplace + AggregatorConstants.DOUBLE_QUOTE ; 
            newValue = AggregatorConstants.NULL_STRING;
        }
        payload = payload.replace(toReplace,newValue);
        return payload;
    }


    /**
    * @description This method determines whether the input object is true of false. If null received it returns false.
    * @author Supriyo Seni | 09-06-2023 
    * @param obj 
    * @return Boolean 
    **/
    public static Boolean checkNullCaseTrueOrFalse(object obj){
        if(obj != null && Boolean.valueOf(obj)){
            return true;
        }
        return false;
    }

    /**
    * @description : This method checks for DML access for Quick Quote.
    * @author Supriyo Seni | 09-05-2023 
    **/
    public static void checkQuickQuoteAccess(){
        if(!Schema.sObjectType.genesis__Quick_Quotes__c.isAccessible() || !Schema.sObjectType.genesis__Quick_Quotes__c.isCreateable() || !Schema.sObjectType.genesis__Quick_Quotes__c.isUpdateable()) {
            throw new CustomException(AggregatorConstants.QUICK_QUOTE_DML_ACCESS_ERROR);
        }
    }
    /**
    * @description : This method checks for DML access for Customer consent.
    * @author Supriyo Seni | 08-28-2023 
    **/
    public static void checkCustomerConsentAccess(){
        if(!Schema.sObjectType.Customer_Communication_Consent__c.isAccessible() || !Schema.sObjectType.Customer_Communication_Consent__c.isUpdateable()) {
            throw new CustomException(AggregatorConstants.CUSTOMER_CONSENT_DML_ACCESS_ERROR);
        }
    }
    /**
    * @description : This method checks for DML access for Attachment object
    * @author Supriyo Seni | 08-28-2023 
    **/
    public static void checkAttachmentAccess(){
        if(!Schema.sObjectType.Attachment.isAccessible() || !Schema.sObjectType.Attachment.isUpdateable()) {
            throw new CustomException(AggregatorConstants.ATTACHMENT_DML_ACCESS_ERROR);
        }
    }

    /**
    * @description : This method validates if the input parameters forms a valid date or not
    * @author Supriyo Seni | 09-07-2023 
    * @param inputDate 
    * @param inputMonth 
    * @param inputYear 
    * @return Boolean 
    **/
    public static Boolean isValidDate(Integer inputDate, Integer inputMonth,Integer inputYear){
        String dateString = String.valueOf(inputMonth) + AggregatorConstants.SLASH + String.valueOf(inputDate)+ AggregatorConstants.SLASH +String.valueOf(inputYear);
        try{
            if(!(inputMonth <= AggregatorConstants.TWELVE && inputMonth >= AggregatorConstants.ONE)){
                return false;
            }
            date dateExtract = date.parse(dateString);
            return (dateExtract!= null) ? true : false;
        }catch(Exception ex){
            return false;
        }
    }


    /**
    * @description : This method checks if the input object has the specified count of blank + null assignments or not after serialize.
    * @author Supriyo Seni | 09-08-2023 
    * @param obj 
    * @param count 
    * @return Boolean 
    **/
    public static Boolean nullAndBlankCountMatch(object obj, Integer count){
        if(obj == null){
            return true;
        }
        String jsonString = (JSON.serialize(obj)).replaceAll(AggregatorConstants.SPACES_INSIDE_STRING,AggregatorConstants.BLANK);
        Integer nullCount = jsonString.countMatches(AggregatorConstants.NULL_STRING);
        Integer blankCount = jsonString.countMatches(AggregatorConstants.DOUBLE_QUOTES);
        if(count == nullCount + blankCount){
            return true;
        }
        return false;
    }

    /**
    * @description | This method throws an exception if the input string is null or blank
    * @author Supriyo Seni | 09-18-2023 
    * @param inputString 
    * @param excpMsg 
    **/
    public static void throwBlankCaseException(String inputString,String excpMsg){
        if(inputString ==  null || String.isBlank(inputString)){
            throw new CustomException(ExcpMsg);
        }
    }

    /**
    * @description  | This method can be used to valitdate the API user corresponding to a profile and permission set or not.
    * @author Supriyo Seni | 10-11-2023 
    * @param apiUserId 
    * @param profileName 
    * @param permissionSetName 
    **/
    public static void validateApiUser(Id apiUserId,String profileName,String permissionSetName){
        // Excluded SECURITY_ENFORCED from below query beuacuse of "Insufficient Query" error. 
        // We are just reading the profile name for validation and not performing any DML.   
        List<User> userList = [SELECT Id, 
                                        Username, 
                                        Profile.Name,
                                        (SELECT PermissionSet.Name 
                                        FROM PermissionSetAssignments) 
                                FROM User 
                                WHERE Id =: apiUserId
                                LIMIT 1];
        throwEmptyListException(userList, AggregatorConstants.API_USER_NOT_FOUND);
        throwNullCaseException(userList[0].Profile?.Name, AggregatorConstants.API_USER_PROFILE_NOT_FOUND);
        if(userList[0].Profile?.Name != profileName){
            throw new customException(AggregatorConstants.API_USER_ACCESS_DENIED);
        }
        // Only check for permission set assignment mismatch if the received permissionSetName is not null
        if(permissionSetName != null){
            throwEmptyListException(userList[0].PermissionSetAssignments, AggregatorConstants.API_USER_PERMISSION_SET_ASSIGNMENT_NOT_FOUND);
            for(PermissionSetAssignment permissionAssignment : userList[0].PermissionSetAssignments){
                if(permissionAssignment?.PermissionSet?.Name == permissionSetName){
                    return;
                }
            }
            throw new customException(AggregatorConstants.API_USER_ACCESS_DENIED);
        }
    }
}