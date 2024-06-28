/**
 * @description       : Validation uill class provide validation util method 
 * @author            : Supriyo Seni
 * @group             : CK
 * @last modified on  : 04-25-2024
 * @last modified by  : Supriyo Seni
**/

public inherited sharing class ValidationUtil {

    /**
    * @description | This method validates if the value passed as a parameter is null or not
    * @author Supriyo Seni | 04-25-2024 
    * @param value 
    **/
    public static void validateObjectNotNull(Object value){
        if(value == null){
            throw new CustomException('Value is null');
        }
    }

    /**
    * @description | This method validates if the value passed as a parameter is null and if null, it throws the exception message
    * @author Supriyo Seni | 04-25-2024 
    * @param value 
    * @param exceptionMessage 
    **/
    public static void validateObjectNotNull(Object value , String exceptionMessage ){
        if(value == null){
            throw new CustomException(exceptionMessage);
        }
    }

    /**
    * @description | This method validates if the List is null or of size 0
    * @author Supriyo Seni | 04-25-2024 
    * @param objectList
    **/
    public static void validateObjectListNotNull(List<Object> objectList){
        if(objectList == null || objectList.size()== 0){
            throw new CustomException('Object is either null or size is 0');
        }
    }

    /**
    * @description | This method validates if the List is null or of size 0 and throws exception 
    * @author Supriyo Seni | 04-25-2024 
    * @param objectList 
    * @param exceptionMessage 
    **/
    public static void validateobjectListectListNotNull(List<Object> objectList , String exceptionMessage ){
        if(objectList == null || objectList.size() == 0){
            throw new CustomException(exceptionMessage);
        }
    }
    
    /**
    * @description | This method is used to sanitize a number
    * @author Supriyo Seni | 04-25-2024 
    * @param value 
    * @return Decimal 
    **/
    public static Decimal sanitiseNumber( Decimal value){
        return value != null ? value : 0 ;
    }

    /**
    * @description | This method returns true if the list passed has a null value
    * @author Supriyo Seni | 04-25-2024 
    * @param valuesList 
    * @return Boolean 
    **/
    public static Boolean isListContainNull(List<object> valuesList){
        if(valuesList == null){
            return true;
        }
        for(Object obj : valuesList){
            if(obj != null){
                continue ;
            }else{
                return true ;
            }
        }
        return false ;
    }

    /**
    * @description | This method can be used to perform a ternary operation
    * @author Supriyo Seni | 04-25-2024 
    * @param condition 
    * @param firstObj 
    * @param secondObj 
    * @return Object 
    **/
    public static Object getTernaryOpValue(Boolean condition, Object firstObj, Object secondObj){
        return (condition? firstObj : secondObj);
    }

    /**
    * @description | This method can be used to do AND operations for multiple conditons
    * @author Supriyo Seni | 04-25-2024 
    * @param conditionList 
    * @return Boolean 
    **/
    public static Boolean getAndResults(List<Boolean> conditionList){
        Boolean getResult = true;
        for(Boolean condition : conditionList){
            getResult &= condition;
        }
        return getResult;
    }

    /**
    * @description | This method can be used to do OR operations for multiple conditons
    * @author Supriyo Seni | 04-25-2024 
    * @param conditionList 
    * @return Boolean 
    **/
    public static Boolean getOrResults(List<Boolean> conditionList){
        Boolean getResult = false;
        for(Boolean condition : conditionList){
            getResult |= condition;
        }
        return getResult;
    }

    /**
    * @description |  Throws exception if passed String list have a blank string
    * @author Supriyo Seni | 04-25-2024 
    * @param stringList 
    * @param exceptionMessage 
    **/
    public static void checkBlankStringInList(List<String> stringList, String exceptionMessage) {
        for (String str : stringList) {
            if (String.isBlank(str)) {
                throw new CustomException(exceptionMessage);
            }
        }
    }

    /**
    * @description | General method to throw exception if map key or value is null
    * @author Supriyo Seni | 04-25-2024 
    * @param paramMap 
    * @param mapKey 
    * @param excpMsg 
    **/
    public static void throwMapKeyMismatchException(Map<String, Object> paramMap,String mapKey,String excpMsg){
        if(!paramMap.containsKey(mapKey) || (paramMap.get(mapKey)) == null){
            throw new CustomException(excpMsg);
        }
    }

    /**
    * @description | This method can be used to throw exceptions on conditon
    * @author Supriyo Seni | 04-25-2024 
    * @param condition 
    * @param message 
    **/
    public static void throwErrorOnCondition(Boolean condition, String message){
        if(condition && message!=null){
            throw new CustomException(message);
        }
    }
}