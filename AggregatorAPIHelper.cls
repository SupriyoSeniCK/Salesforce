/**
 * @description       : HELPER CLASS FOR AGGREGATOR API RELATED DEVELOPMENTS
 * @author            : Supriyo Seni
 * @group             : Helper Class
 * @last modified on  : 10-17-2023
 * @last modified by  : Supriyo Seni
**/
public inherited sharing class AggregatorAPIHelper {

    /** 
    * @description | This method can be used to return the modified licence card number validation message
    * @author Supriyo Seni | 09-19-2023 
    * @param exceptionMessage 
    * @return String 
    **/
    public static Map<String,String> checkSystemValidationMessage(String exceptionMessage){
        Map<String,String> fieldVsMesssageMap = new Map<String,String>();
        Map<String,String> modifiedErrorMap = new Map<String,String>();
        fieldVsMesssageMap.put(AggregatorConstants.CITY_FIELD,AggregatorConstants.CITY_ERROR_MESSAGE);
        fieldVsMesssageMap.put(AggregatorConstants.EMAIL_FIELD,AggregatorConstants.EMAIL_ERROR_MESSAGE);
        fieldVsMesssageMap.put(AggregatorConstants.DRIVER_LICENCE_FIELD,AggregatorConstants.DL_VALIDATION_ERROR_MESSAGE);
        fieldVsMesssageMap.put(AggregatorConstants.LICENCE_CARD_NUMBER_STRING,AggregatorConstants.LICENCE_CARD_NUMBER_ERROR_MESSAGE);
        fieldVsMesssageMap.put(AggregatorConstants.POSTAL_CODE_FIELD,AggregatorConstants.POSTAL_CODE_ERROR_MESSAGE);
        fieldVsMesssageMap.put(AggregatorConstants.PROPERTY_NAME_FIELD,AggregatorConstants.PROPERTY_NAME_ERROR_MESSAGE);
        fieldVsMesssageMap.put(AggregatorConstants.STREET_NAME_FIELD,AggregatorConstants.STREET_NAME_ERROR_MESSAGE);
        fieldVsMesssageMap.put(AggregatorConstants.STREET_NUMBER_FIELD,AggregatorConstants.STREET_NUMBER_ERROR_MESSAGE);
        fieldVsMesssageMap.put(AggregatorConstants.BROKER_ID,exceptionMessage);
        fieldVsMesssageMap.put(AggregatorConstants.BROKER_DETAILS,exceptionMessage);
        fieldVsMesssageMap.put(AggregatorConstants.ANOTHER_QUOTE_EXIST_ERROR_MESSAGE_PREFIX,exceptionMessage);
        List<String> systemFieldList = (AggregatorConstants.QUOTE_FIELD_LIST).split(AggregatorConstants.COMMA);
        for(String fieldName : systemFieldList){
            if(exceptionMessage.contains(fieldName)){
                modifiedErrorMap.put(AggregatorConstants.ERROR_MESSAGE,fieldVsMesssageMap.get(fieldName));
                modifiedErrorMap.put(AggregatorConstants.ERROR_CODE,AggregatorConstants.VALIDATION_ERROR);
                return modifiedErrorMap;
            }
        }
        modifiedErrorMap.put(AggregatorConstants.ERROR_MESSAGE,AggregatorConstants.QUOTE_REQUEST_NOT_PROCESSED_ERROR + exceptionMessage);
        modifiedErrorMap.put(AggregatorConstants.ERROR_CODE,AggregatorConstants.CUSTOM_EXCEPTION);
        return modifiedErrorMap;
    }

    /**
    * @description This method removed space, hiphen and apostrophes from the input String
    * @author Supriyo Seni | 09-20-2023 
    * @param inputString 
    * @return String 
    **/
    public static String removeSpaceAndHyphenFromString(String inputString){
        if(inputString == null){
            return AggregatorConstants.SPACE;
        }
        inputString = inputString?.remove(AggregatorConstants.HIPHEN);
        inputString = inputString?.remove(AggregatorConstants.SPACE);
        return inputString;
    }


        /**
    * @description  | This method can be used to valitdate the API user corresponding to a profile and permission set or not.
    * @author Supriyo Seni | 10-11-2023 
    * @param apiUserId 
    **/
    public static void validateApiUser(Id apiUserId){
        List<String> allowedProfileList  = (System.label.AggregatorApiProfiles).split(AggregatorConstants.COMMA);
        // We are just reading the profile name for validation and not performing any DML. Thus, excluded SECURITY_ENFORCED 
        // from below query beuacuse of "Insufficient Query" error which may occur due to restricted access. 
        List<User> userList = [SELECT Id, 
                                        Username, 
                                        Profile.Name
                                FROM User 
                                WHERE Id =: apiUserId
                                LIMIT 1];
        IntegrationUtil.throwEmptyListException(userList, AggregatorConstants.API_USER_NOT_FOUND);
        IntegrationUtil.throwNullCaseException(userList[0].Profile?.Name, AggregatorConstants.API_USER_PROFILE_NOT_FOUND);
        for(String profileName : allowedProfileList){
            if(userList[0].Profile?.Name == profileName){
                return;
            }
        }
        throw new customException(AggregatorConstants.API_USER_ACCESS_DENIED);
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
    * @description : This method checks if the input object has the specified count of blank + null assignments or not after serialize.
    * @author Supriyo Seni | 09-08-2023 
    * @param obj 
    * @param count 
    * @return Boolean 
    **/
    public static Boolean hasNullAndBlankCountMatch(object obj, Integer count){
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
    * @description | Get current User IP Address
    * @author Supriyo Seni | 10-16-2023 
    * @return String 
    **/
    public static String getUserIPAddress() {
        Map<String, String> sessionMap = Auth.SessionManagement.getCurrentSession();
        return sessionMap.get(AggregatorConstants.SOURCE_IP);
    }

    /**
    * @description | Validates API user IP address within the trsuted IP range.
    * @author Supriyo Seni | 10-16-2023 
    * @param ipAddress 
    **/
    public static void validateApiUserIpAddress(String ipAddress){
        validateIpAddress(ipAddress,AggregatorConstants.INVALID_IP_ADDRESS);
        List<String> trustedIpRangeList  = (System.label.AggregatorTrustedIpRange).split(AggregatorConstants.COMMA);
        If(trustedIpRangeList.isEmpty() || trustedIpRangeList.size() != AggregatorConstants.TWO){
            return;
        }
        if(trustedIpRangeList.contains(ipAddress)){
            return;
        }
        validateIpAddress(trustedIpRangeList[0],AggregatorConstants.INVALID_TRUSTED_IP_RANGE);
        validateIpAddress(trustedIpRangeList[1],AggregatorConstants.INVALID_TRUSTED_IP_RANGE);
        if(!(ipAsDouble(ipAddress) >= ipAsDouble(trustedIpRangeList[0]) && ipAsDouble(ipAddress) <= ipAsDouble(trustedIpRangeList[1]))){
            throw new customException(AggregatorConstants.IP_ADDRESS_NOT_FROM_A_TRSUTED_SOURCE);
        }
    }

    /**
    * @description | This method validates the string format is an IP address or not
    * @author Supriyo Seni | 10-16-2023 
    * @param ipAddress 
    * @param exceptionMessage 
    **/
    public static void validateIpAddress(String ipAddress,String exceptionMessage){
        if(ipAddress.countMatches(AggregatorConstants.DOT) != AggregatorConstants.THREE || !(ipAddress.remove(AggregatorConstants.DOT)).isNumeric()){
            throw  new customException(exceptionMessage);
        }
    }

    /**
    * @description | This method can be used to represent an IP in double format
    * @author Supriyo Seni | 10-16-2023 
    * @param ipAddress 
    * @return Double 
    **/
    public static Double ipAsDouble(String ipAddress){
        String[] ipSingleList = ipAddress.split(AggregatorConstants.DOT_WITH_SLASH);
        Double ipAsDouble = Double.valueOf(ipSingleList[0]) * Math.pow(AggregatorConstants.TWO_HUNDRED_FIFTY_FIVE, AggregatorConstants.THREE) 
                + Double.valueOf(ipSingleList[1]) * Math.pow(AggregatorConstants.TWO_HUNDRED_FIFTY_FIVE, AggregatorConstants.TWO) 
                + Double.valueOf(ipSingleList[2]) * Math.pow(AggregatorConstants.TWO_HUNDRED_FIFTY_FIVE, AggregatorConstants.ONE) 
                + Double.valueOf(ipSingleList[3]) * Math.pow(AggregatorConstants.TWO_HUNDRED_FIFTY_FIVE, AggregatorConstants.ZERO);  
        return ipAsDouble;
    }
}