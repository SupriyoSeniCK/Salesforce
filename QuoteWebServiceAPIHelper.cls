/**
 * @description       : HELPER CLASS FOR AGGREGATOR API WEBSERVICE QUICK QUOTE GENERATION
 * @author            : Supriyo Seni
 * @group             : Agreegator API
 * @last modified on  : 10-16-2023
 * @last modified by  : Supriyo Seni
**/

public inherited sharing class QuoteWebServiceAPIHelper {
    public static List<QuoteJSONWrapper.ErrorResponse> errorResponseList = new List<QuoteJSONWrapper.ErrorResponse>();
    public static Boolean isPostalAddressProvided = false;
    public static Boolean isGpoAddressProvided = false;
    public static Boolean isDriverLicenceProvided = false;
    public static List<string> stateList = (AggregatorConstants.POSSIBLE_STATES).split(AggregatorConstants.COMMA);
    public static List<string> residentialStatusList = (AggregatorConstants.RESIDETIAL_STATUS_LIST).split(AggregatorConstants.COMMA);
    public static List<string> streetTypeList = (AggregatorConstants.STREET_TYPE_LIST).split(AggregatorConstants.COMMA);
    public static List<String> genderList = (AggregatorConstants.GENDER_POSSIBLE_VALUES).split(AggregatorConstants.COMMA);
    public static List<String> loanTypeList = (AggregatorConstants.LOAN_PURPOSE_POSSIBLE_VALUES).split(AggregatorConstants.COMMA);

    /**
    * @description : This method creates the error responses
    * @author Supriyo Seni | 09-04-2023 
    * @param errorMessage 
    * @param errorCode 
    **/
    public static void createErrorResponse(String errorMessage, String errorCode){
        QuoteJSONWrapper.ErrorResponse errorResponseInst = new QuoteJSONWrapper.ErrorResponse();
        errorResponseInst.message = errorMessage;
        errorResponseInst.errorCode = errorCode;
        errorResponseList.add(errorResponseInst);
    }

    /**
    * @description : This method can be used to create error response if received object is null or blank
    * @author Supriyo Seni | 09-04-2023 
    * @param obj 
    * @param errorMessage 
    **/
    public static void requiredFieldValidation(object obj, String errorMessage){
        if(obj == null || String.isBlank(String.valueOf(obj))){
            createErrorResponse(errorMessage,AggregatorConstants.REQUEST_INVALID);
        }
    }

    /**
    * @description : This method can be used to create error response if received object is null
    * @author Supriyo Seni | 09-04-2023 
    * @param obj 
    * @param errorMessage 
    **/
    public static void redundantFieldValidation(object obj, String errorMessage){
        if(obj != null && String.isNotBlank(String.valueOf(obj))){
            createErrorResponse(errorMessage,AggregatorConstants.REQUEST_INVALID);
        }
    }

    /**
    * @description : This method checks if all the required sections are received in the payload or not.
    * @author Supriyo Seni | 09-01-2023 
    * @param quotePayLoad 
    **/
    public static void doPrimaryNullCheck(QuoteJSONWrapper quotePayLoad){
        requiredFieldValidation(quotePayLoad.personalDetails,AggregatorConstants.PERSONAL_DETAILS_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad.contactDetails,AggregatorConstants.CONTACT_DETAILS_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad.loanDetails,AggregatorConstants.LOAN_DETAILS_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad.driverLicenceDetails,AggregatorConstants.DL_DETAILS_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad.addressDetails,AggregatorConstants.ADDRESS_DETAILS_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad.quoteConsentDetails,AggregatorConstants.QUOTE_CONSENT_DETAILS_ERROR_MESSAGE);
    }

    /**
    * @description : This method checks if all the required fields are received in the payload or not.
    * @author Supriyo Seni | 09-01-2023 
    * @param quotePayLoad 
    **/
    public static void doSecondaryNullCheck(QuoteJSONWrapper quotePayLoad){
        requiredFieldValidation(quotePayLoad?.personalDetails?.firstName,AggregatorConstants.FIRST_NAME_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.personalDetails?.lastName,AggregatorConstants.LAST_NAME_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.personalDetails?.gender,AggregatorConstants.GENDER_NAME_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.personalDetails?.dateOfBirthDetails,AggregatorConstants.DOB_DETAILS_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.contactDetails?.emailAddress,AggregatorConstants.EMAIL_ADDRESS_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.contactDetails?.mobileNumber,AggregatorConstants.MOBILE_NUMBER_MISSING_ERROR_MESSAGE);

        requiredFieldValidation(quotePayLoad?.loanDetails?.term,AggregatorConstants.TERM_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.loanDetails?.loanAmount,AggregatorConstants.LOAN_AMOUNT_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.loanDetails?.loanPurpose,AggregatorConstants.LOAN_PURPOSE_MISSING_ERROR_MESSAGE);

        // Check if drived licence available checkbox is true/false or null
        if(AggregatorAPIHelper.checkNullCaseTrueOrFalse(quotePayLoad?.driverLicenceDetails?.isDriverLicenceAvailable)){
            isDriverLicenceProvided = true;
            requiredFieldValidation(quotePayLoad?.driverLicenceDetails?.stateOfIssue,AggregatorConstants.DL_STATE_OF_ISSUE_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(quotePayLoad?.driverLicenceDetails?.driverLicenceNumber,AggregatorConstants.DRIVER_LICENCE_NUMBER_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(quotePayLoad?.driverLicenceDetails?.licenceCardNumber,AggregatorConstants.DL_LICENCE_CARD_NUMBER_MISSING_ERROR_MESSAGE);
        }else{
            redundantFieldValidation(quotePayLoad?.driverLicenceDetails?.stateOfIssue,AggregatorConstants.STATE_OF_ISSUE_FIELD_REDUNDANCY_MESSAGE);
            redundantFieldValidation(quotePayLoad?.driverLicenceDetails?.driverLicenceNumber,AggregatorConstants.DL_NUMBER_FIELD_REDUNDANCY_MESSAGE);
            redundantFieldValidation(quotePayLoad?.driverLicenceDetails?.licenceCardNumber,AggregatorConstants.DL_CARD_NUMBER_FIELD_REDUNDANCY_MESSAGE);
        }

        requiredFieldValidation(quotePayLoad?.addressDetails?.residentialStatus,AggregatorConstants.RESIDENTIAL_STATUS_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.addressDetails?.streetNumber,AggregatorConstants.STREET_NUMBER_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.addressDetails?.streetName,AggregatorConstants.STREET_NAME_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.addressDetails?.streetType,AggregatorConstants.STREET_TYPE_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.addressDetails?.city,AggregatorConstants.CITY_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.addressDetails?.state,AggregatorConstants.STATE_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.addressDetails?.postalCode,AggregatorConstants.POSTAL_CODE_MISSING_ERROR_MESSAGE);
        // Check if mailing address provided or not in the payload
        isPostalAddressProvided = !AggregatorAPIHelper.hasNullAndBlankCountMatch(quotePayLoad?.addressDetails?.postalAddressDetails,AggregatorConstants.EIGHT);
        // Check if PO/GPO address provided or not in the payload
        isGpoAddressProvided = !AggregatorAPIHelper.hasNullAndBlankCountMatch(quotePayLoad?.addressDetails?.poGpoAddressDetails,AggregatorConstants.FOUR);
        if(AggregatorAPIHelper.checkNullCaseTrueOrFalse(quotePayLoad?.addressDetails?.isMailingAddressSame)){
            if(isPostalAddressProvided){
                redundantFieldValidation(quotePayLoad?.addressDetails?.postalAddressDetails,AggregatorConstants.MAILING_ADDRESS_DETAILS_REDUNDANCY_MESSAGE);
            }
            if(isGpoAddressProvided){
                redundantFieldValidation(quotePayLoad?.addressDetails?.poGpoAddressDetails,AggregatorConstants.PO_GPO_DETAILS_REDUNDANCY_MESSAGE);
            }
        }else{
            // If mailing address is different from home address
            checkMailingAddress(quotePayLoad?.addressDetails);
        }
        requiredFieldValidation(quotePayLoad?.brokerDetails?.brokerFeeAmount,AggregatorConstants.BROKER_FEE_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.quoteConsentDetails?.quoteConsent,AggregatorConstants.QUOTE_CONSENT_MISSING_ERROR_MESSAGE);
    }

    /**
    * @description : This method checks if the mailing address required fields are having values or not
    * @author Supriyo Seni | 09-04-2023 
    * @param addressDetails 
    **/
    public static void checkMailingAddress(QuoteJSONWrapper.AddressDetails addressDetails){
        if(isPostalAddressProvided && isGpoAddressProvided){
            // If both mailing and PO/GPO address are provided then create invalid request error response 
            createErrorResponse(AggregatorConstants.BOTH_MAILING_AND_PO_GPO_ERROR,AggregatorConstants.REQUEST_INVALID);
        }else if(isPostalAddressProvided){
            requiredFieldValidation(addressDetails?.postalAddressDetails?.postalStreetNumber,AggregatorConstants.POSTAL_STREET_NUMBER_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(addressDetails?.postalAddressDetails?.postalStreetName,AggregatorConstants.POSTAL_STREET_NAME_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(addressDetails?.postalAddressDetails?.postalStreetType,AggregatorConstants.POSTAL_STREET_TYPE_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(addressDetails?.postalAddressDetails?.postalCity,AggregatorConstants.POSTAL_CITY_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(addressDetails?.postalAddressDetails?.postalState,AggregatorConstants.POSTAL_STATE_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(addressDetails?.postalAddressDetails?.postalCode,AggregatorConstants.POSTAL_CODE_MISSING_ERROR_MESSAGE);
        }else if(isGpoAddressProvided){
            requiredFieldValidation(addressDetails?.poGpoAddressDetails?.poBoxNumber,AggregatorConstants.PO_BOX_NUMBER_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(addressDetails?.poGpoAddressDetails?.postalBoxState,AggregatorConstants.POS_BOX_STATE_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(addressDetails?.poGpoAddressDetails?.postalBoxCity,AggregatorConstants.PO_BOX_CITY_MISSING_ERROR_MESSAGE);
            requiredFieldValidation(addressDetails?.poGpoAddressDetails?.poBoxPostalCode,AggregatorConstants.PO_BOX_POSTAL_CODE_ERROR_MESSAGE);
        }else{
            // If no mailing and PO/GPO address are provided then create invalid request error response 
            createErrorResponse(AggregatorConstants.BOTH_POSTAL_AND_POGPO_ADDRESS_PROVIDED_ERROR_MESSAGE,AggregatorConstants.VALIDATION_ERROR);
        }
    }

    /**
    * @description | This method validates the parsed request response fields
    * @author Supriyo Seni | 08-28-2023 
    * @param quotePayLoad 
    * @return List<QuoteJSONWrapper.ErrorResponse> 
    **/
    public static List<QuoteJSONWrapper.ErrorResponse> validateRequest(QuoteJSONWrapper quotePayLoad){
        QuoteJSONWrapper.CharaterLimitWrapper charLimitInst = new QuoteJSONWrapper.CharaterLimitWrapper();
        // Do a primary null check for required details/sections
        doPrimaryNullCheck(quotePayLoad);
        // Do a secondary null check for all required section fields
        doSecondaryNullCheck(quotePayLoad);
        if(!errorResponseList.isEmpty()){
            return errorResponseList;
        }
        requiredFieldValidation(quotePayLoad?.personalDetails?.dateOfBirthDetails?.birthDate,AggregatorConstants.BIRTHDATE_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.personalDetails?.dateOfBirthDetails?.birthMonth,AggregatorConstants.BIRTHMONTH_MISSING_ERROR_MESSAGE);
        requiredFieldValidation(quotePayLoad?.personalDetails?.dateOfBirthDetails?.birthYear,AggregatorConstants.BIRTHYEAR_MISSING_ERROR_MESSAGE);
        // Possible loan types array validation check
        checkPicklistError(loanTypeList,quotePayLoad?.loanDetails?.loanPurpose,AggregatorConstants.LOAN_PURPOSE_VALIDATION_ERROR);
        // Gender picklist validation check
        checkPicklistError(genderList,quotePayLoad?.personalDetails?.gender.trim().toLowerCase(),AggregatorConstants.GENDER_ERROR);
        if(!quotePayLoad?.personalDetails?.gender.trim().toLowerCase().equals(AggregatorConstants.OTHER) && String.isNotBlank(quotePayLoad?.personalDetails?.otherGenderSpecification)) {
            createErrorResponse(AggregatorConstants.OTHER_GENDER_SPECIFICATION_VALIDATION_MESSAGE, AggregatorConstants.VALIDATION_ERROR);
        }
        charLimitInst.minimumLength = AggregatorConstants.TWO;
        charLimitInst.maximumLength = AggregatorConstants.FIFTEEN;
        charLimitInst.isAlpha = true;
        charLimitInst.isNumeric = false;
        charLimitInst.stringToValidate = quotePayLoad?.personalDetails?.otherGenderSpecification;
        validateCharacterLimit(charLimitInst,AggregatorConstants.OTHER_GENDER_SPECIFICATIONS_ERROR_MESSAGE);
        // If driver licence details are provided then validate them
        if(isDriverLicenceProvided){
            validateIdentityDetails(quotePayLoad?.driverLicenceDetails);
        }
        // Validate home address details
        validateAddressDetails(quotePayLoad?.addressDetails);
        // Validate broker fee amounts
        if(AggregatorBrokerHandler.validateBrokerFeeAmount(quotePayLoad) != null){
            errorResponseList.add(AggregatorBrokerHandler.validateBrokerFeeAmount(quotePayLoad));
        }
        return errorResponseList;
    }

    /**
    * @description | This method validates the character limit of of aplha and numeric fields
    * @author Supriyo Seni | 10-13-2023 
    * @param charLimitInst 
    * @param errorMessage 
    **/
    public static void validateCharacterLimit(QuoteJSONWrapper.CharaterLimitWrapper charLimitInst,String errorMessage){
        if(String.isNotBlank(charLimitInst?.stringToValidate) && !AggregatorAPIHelper.isWithinCharaterLimits(charLimitInst)){
            createErrorResponse(errorMessage, AggregatorConstants.VALIDATION_ERROR);
        }
    }

    /**
    * @description | This method validates the driver licence details
    * @author Supriyo Seni | 09-04-2023 
    * @param driverLicence 
    **/
    public static void validateIdentityDetails(QuoteJSONWrapper.DriverLicenceDetails driverLicence){
        if(!(driverLicence?.driverLicenceNumber).isAlphanumericSpace()){
            createErrorResponse(AggregatorConstants.DL_VALIDATION_ERROR_MESSAGE, AggregatorConstants.VALIDATION_ERROR);
        }
        // Validate state of the applicant
        checkPicklistError(stateList,driverLicence?.stateOfIssue,AggregatorConstants.DL_STATE_OF_ISSUE_VALIDATION_ERROR_MESSAGE);
    }

    /**
    * @description | This method checks if the postal code is valid or not
    * @author Supriyo Seni | 09-04-2023 
    * @param postalCode 
    * @param errMessage 
    **/
    public static void checkPostalCode(String postalCode, String errMessage){
        if(!IntegrationUtil.isValidPostCode(postalCode)){
            createErrorResponse(errMessage, AggregatorConstants.VALIDATION_ERROR);
        }
    }

    /**
    * @description | Create error response if the input value is not from the defined picklist values.
    * @author Supriyo Seni | 09-20-2023 
    * @param possibleValuesList 
    * @param inputString 
    * @param errorMessage 
    **/
    public static void checkPicklistError(List<String> possibleValuesList, String inputString, String errorMessage){
        if(!possibleValuesList.contains(inputString)){
            createErrorResponse(errorMessage, AggregatorConstants.VALIDATION_ERROR);
        }
    }

    /**
    * @description | This method validates address details 
    * @author Supriyo Seni | 09-05-2023 
    * @param addressDetails 
    **/
    public static void validateAddressDetails(QuoteJSONWrapper.AddressDetails addressDetails){
        // Validate Validate residential Status
        checkPicklistError(residentialStatusList,addressDetails?.residentialStatus,AggregatorConstants.RESIDENTIAL_STATUS_POSSIBLE_VALUES_ERROR_MESSAGE);
        // Validate Unit Number
        QuoteJSONWrapper.CharaterLimitWrapper charLimitInst = new QuoteJSONWrapper.CharaterLimitWrapper();
        // charLimitInst.minimumLength = AggregatorConstants.ONE;
        // charLimitInst.maximumLength = AggregatorConstants.TEN;
        // charLimitInst.isAlpha = false;
        // charLimitInst.isNumeric = true;
        // charLimitInst.stringToValidate = addressDetails?.unitNumber;
        // validateCharacterLimit(charLimitInst,AggregatorConstants.UNIT_NUMBER_MUST_BE_A_NUMBER_ERROR_MESSAGE);
        validateRegex(AggregatorConstants.UNIT_NUMBER_REGEX,addressDetails?.unitNumber,AggregatorConstants.UNIT_NUMBER_VALIDATION_ERROR_MESSAGE);


        // Validate Street Number
        charLimitInst.minimumLength = AggregatorConstants.ONE;
        charLimitInst.maximumLength = AggregatorConstants.EIGHT;
        charLimitInst.isAlpha = false;
        charLimitInst.isNumeric = true;
        charLimitInst.stringToValidate = addressDetails?.streetNumber;
        validateCharacterLimit(charLimitInst,AggregatorConstants.STREET_NUMBER_MUST_BE_A_NUMBER_ERROR_MESSAGE);

        // Validate Street Name
        charLimitInst.minimumLength = AggregatorConstants.ONE;
        charLimitInst.maximumLength = AggregatorConstants.THIRTY;
        charLimitInst.isAlpha = true;
        charLimitInst.isNumeric = false;
        charLimitInst.stringToValidate = addressDetails?.streetName;
        validateCharacterLimit(charLimitInst,AggregatorConstants.STREET_NAME_VALIDATION_MESSAGE);

        // Validate Street Type
        checkPicklistError(streetTypeList,addressDetails?.streetType,AggregatorConstants.STREET_TYPE_POSSIBLE_VALUES_ERROR_MESSAGE);

        // Validate City
        charLimitInst.minimumLength = AggregatorConstants.THREE;
        charLimitInst.maximumLength = AggregatorConstants.THIRTY;
        charLimitInst.isAlpha = true;
        charLimitInst.isNumeric = false;
        charLimitInst.stringToValidate = addressDetails?.city;
        validateCharacterLimit(charLimitInst,AggregatorConstants.CITY_VALIDATION_MESSAGE);

        // Validate State
        checkPicklistError(stateList,addressDetails?.state,AggregatorConstants.STATE_VALIDATION_ERROR_MESSAGE);

        // Validate Postal Code
        checkPostalCode(addressDetails?.postalCode,AggregatorConstants.POSTAL_CODE_ERROR_MESSAGE);

        // VALIDATE Property Name
        charLimitInst.minimumLength = AggregatorConstants.TWO;
        charLimitInst.maximumLength = AggregatorConstants.TWENTY;
        charLimitInst.isAlpha = true;
        charLimitInst.isNumeric = false;
        charLimitInst.stringToValidate = addressDetails?.propertyName;
        validateCharacterLimit(charLimitInst,AggregatorConstants.PROPERTY_NAME_ERROR_MESSAGE);

        if(isPostalAddressProvided){
            // Validate Mailing Unit Number
            charLimitInst.minimumLength = AggregatorConstants.ONE;
            charLimitInst.maximumLength = AggregatorConstants.FOUR;
            charLimitInst.isAlpha = false;
            charLimitInst.isNumeric = true;
            charLimitInst.stringToValidate = addressDetails?.postalAddressDetails?.postalUnitNumber;
            validateCharacterLimit(charLimitInst,AggregatorConstants.POSTAL_UNIT_NUMBER_MUST_BE_A_NUMBER_ERROR_MESSAGE);

            // Validate Postal Street Number
            charLimitInst.minimumLength = AggregatorConstants.ONE;
            charLimitInst.maximumLength = AggregatorConstants.EIGHT;
            charLimitInst.isAlpha = false;
            charLimitInst.isNumeric = true;
            charLimitInst.stringToValidate = addressDetails?.postalAddressDetails?.postalStreetNumber;
            validateCharacterLimit(charLimitInst,AggregatorConstants.POSTAL_STREET_NUMBER_MUST_BE_A_NUMBER_ERROR_MESSAGE);

            //Postal Street Name
            charLimitInst.minimumLength = AggregatorConstants.ONE;
            charLimitInst.maximumLength = AggregatorConstants.THIRTY;
            charLimitInst.isAlpha = true;
            charLimitInst.isNumeric = false;
            charLimitInst.stringToValidate = addressDetails?.postalAddressDetails?.postalStreetName;
            validateCharacterLimit(charLimitInst,AggregatorConstants.MAILING_STREET_NAME_VALIDATION_MESSAGE);

            //Postal Street Type
            checkPicklistError(streetTypeList,addressDetails?.postalAddressDetails?.postalStreetType,AggregatorConstants.POSTAL_STREET_TYPE_POSSIBLE_VALUES_ERROR_MESSAGE);

            // Validate Postal City
            charLimitInst.minimumLength = AggregatorConstants.THREE;
            charLimitInst.maximumLength = AggregatorConstants.THIRTY;
            charLimitInst.isAlpha = true;
            charLimitInst.isNumeric = false;
            charLimitInst.stringToValidate = addressDetails?.postalAddressDetails?.postalCity;
            validateCharacterLimit(charLimitInst,AggregatorConstants.MAILING_CITY_VALIDATION_MESSAGE);

            // Validate Postal State
            checkPicklistError(stateList,addressDetails?.postalAddressDetails?.postalState,AggregatorConstants.POSTAL_STATE_VALIDATION_ERROR_MESSAGE);

            // Validate Mailing Postal Code
            checkPostalCode(addressDetails?.postalAddressDetails?.postalCode,AggregatorConstants.MAILING_POSTAL_CODE_VALIDATION_MESSAGE);

            // Validate Postal Property
            charLimitInst.minimumLength = AggregatorConstants.TWO;
            charLimitInst.maximumLength = AggregatorConstants.TWENTY;
            charLimitInst.isAlpha = true;
            charLimitInst.isNumeric = false;
            charLimitInst.stringToValidate = addressDetails?.postalAddressDetails?.postalPropertyName;
            validateCharacterLimit(charLimitInst,AggregatorConstants.POSTAL_PROPERTY_NAME_ERROR_MESSAGE);
        }
        if(isGpoAddressProvided){

            // Validate PO/GPO Box number
            charLimitInst.minimumLength = AggregatorConstants.ONE;
            charLimitInst.maximumLength = AggregatorConstants.TWENTY;
            charLimitInst.isAlpha = false;
            charLimitInst.isNumeric = true;
            charLimitInst.stringToValidate = addressDetails?.poGpoAddressDetails?.poBoxNumber;
            validateCharacterLimit(charLimitInst,AggregatorConstants.PO_GPO_BOX_NUMBER_MUST_BE_A_NUMBER_ERROR_MESSAGE);

            // Validate PO/GPO State
            checkPicklistError(stateList,addressDetails?.poGpoAddressDetails?.postalBoxState,AggregatorConstants.POSTAL_BOX_STATE_VALIDATION_ERROR_MESSAGE); 

            // Validate PO/GPO City
            charLimitInst.minimumLength = AggregatorConstants.THREE;
            charLimitInst.maximumLength = AggregatorConstants.THIRTY;
            charLimitInst.isAlpha = true;
            charLimitInst.isNumeric = false;
            charLimitInst.stringToValidate = addressDetails?.poGpoAddressDetails?.postalBoxCity;
            validateCharacterLimit(charLimitInst,AggregatorConstants.PO_GPO_CITY_VALIDATION_MESSAGE);

            // Validate PO/GPO Postal Code
            checkPostalCode(addressDetails?.poGpoAddressDetails?.poBoxPostalCode,AggregatorConstants.PO_BOX_POSTAL_CODE_MUST_BE_A_FOUR_DIGIT_NUMBER);
        }
    }

    /**
    * @description | Validating with Regex
    * @author Supriyo Seni | 10-16-2023 
    * @param regex 
    * @param matchString 
    * @param errorMessage 
    **/
    public static void validateRegex(String regex, String matchString,String errorMessage){
        if(String.isNotBlank(matchString) && !Pattern.matches(regex,matchString)){
            createErrorResponse(errorMessage, AggregatorConstants.VALIDATION_ERROR);
        }
    }
}