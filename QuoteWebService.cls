/**
 * @description       : This is the REST API for creation of Quick Quote (Broker Aggregator API)
 * @author            : chayan.sengupta@cloudkaptan.com
 * @group             : 
 * @last modified on  : 
**/
@RestResource(urlMapping='/quote/*')
    global with sharing class QuoteWebService {
        static Boolean errorFlag = false;
        static List<QuoteJSONWrapper.ErrorResponse> listOfErrorResponses = new List<QuoteJSONWrapper.ErrorResponse>();

        @HttpPost
        global static String createQQ(){
            QuoteJSONWrapper.ErrorResponse errResponse;
            List<QuoteJSONWrapper.SuccessResponse> listOfSuccessResponses = new List<QuoteJSONWrapper.SuccessResponse>();
            QuoteJSONWrapper.SuccessResponse successResponse;

            if(RestContext.request != null){
                String requestBody = RestContext.request.requestBody.toString();
                Savepoint sp;
                if(String.isNotBlank(requestBody)){
                    try{
                        if (!Schema.sObjectType.genesis__Quick_Quotes__c.isAccessible() || 
                            !Schema.sObjectType.genesis__Quick_Quotes__c.isCreateable() || 
                            !Schema.sObjectType.genesis__Quick_Quotes__c.isUpdateable()) {
                            throw new CustomException(CpConstants.DML_ACCESS_ERROR);
                        }
                        if (!Schema.sObjectType.Customer_Communication_Consent__c.isAccessible() ||
                            !Schema.sObjectType.Customer_Communication_Consent__c.isUpdateable()
                        ) {
                            throw new CustomException(CpConstants.DML_ACCESS_ERROR);
                        }
                        if (!Schema.sObjectType.Attachment.isAccessible() ||
                            !Schema.sObjectType.Attachment.isUpdateable()
                        ) {
                            throw new CustomException(CpConstants.DML_ACCESS_ERROR);
                        }
                        sp = Database.setSavepoint();
                        QuoteJSONWrapper quotePayLoad = (QuoteJSONWrapper)JSON.deserialize(requestbody, QuoteJSONWrapper.class);
                        System.debug('quotePayLoad=>' + quotePayLoad);
                        if (quotePayLoad == null) {
                            throw new CustomException('Payload format is not correct. Verify that the required format has been provided or contact the Salesforce Admin for help.');
                        }
                        validate(quotePayLoad); // assuming only one quote request is present
                        if (!listOfErrorResponses.isEmpty()) {
                            return listOfErrorResponses.size() > 1 ? JSON.serialize(listOfErrorResponses) : JSON.serialize(listOfErrorResponses[0]);
                        }
                        List<genesis__Quick_Quotes__c> quoteList = createQuoteList(quotePayLoad);
                        if(quoteList.isEmpty()){
                            createErrorResponse('Quick Quote Request not processed. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'VALIDATION_ERROR');
                            return listOfErrorResponses.size() > 1 ? JSON.serialize(listOfErrorResponses) : JSON.serialize(listOfErrorResponses[0]);
                        }
                        upsert quoteList;
                        List<Attachment> qqAttachments = new List<Attachment>();
                        List<Customer_Communication_Consent__c> qqConsents = new List<Customer_Communication_Consent__c>();
                        for (genesis__Quick_Quotes__c qq : quoteList) {
                            successResponse = new QuoteJSONWrapper.SuccessResponse();
                            List<Customer_Communication_Consent__c> consentQQ  =  [SELECT Id,
                                                            Quote_Confirmation__c
                                                    FROM Customer_Communication_Consent__c 
                                                    WHERE Quick_Quote_ID__c  =: qq.id WITH SECURITY_ENFORCED order by createdDate desc limit 1];
                            if(!consentQQ.isEmpty()){
                                consentQQ[0].Quote_Confirmation__c  =  true;
                                qqConsents.add(consentQQ[0]);
                            }
                            /**
                             * quote evaluation
                             */
                            doCallouts(qq.id);
                            /**
                             * rate estimate
                             */
                            getRateEstimate(qq.id);
                            List <genesis__Quick_Quotes__c> updatedQQList  = [SELECT  id,
                                                    Name,
                                                    Repayment_Amount__c,
                                                    Term__c, 
                                                    genesis__Account__c,
                                                    genesis__Contact__c,
                                                    CL_Product_Name__c,
                                                    genesis__Financed_Amount__c, 
                                                    genesis__Payment_Frequency__c,
                                                    Interest_Type__c, 
                                                    Indicative_Interest_Rate__c,
                                                    Loan_Establishment_Fee__c,
                                                    Broker_Fee_Amount__c,
                                                    Other_Fees__c
                                                    FROM genesis__Quick_Quotes__c 
                                                    WHERE id = :qq.id
                                                    WITH SECURITY_ENFORCED
                                                    LIMIT 1];
                            if (!updatedQQList.isEmpty()) {
                                System.debug('updatedQQList=>' + updatedQQList);
                                successResponse.quoteId = updatedQQList[0].Name;
                                System.debug('indicativeInterestRate=>' + updatedQQList[0].Indicative_Interest_Rate__c);
                                System.debug('repaymentAmount=>' + updatedQQList[0].Repayment_Amount__c);
                                successResponse.repaymentAmount = CreateQQActionConstants.DOLLAR +  String.valueOf(updatedQQList[0].Repayment_Amount__c.setScale(2, RoundingMode.HALF_UP));
                                System.debug('paymentfreq=>' + updatedQQList[0].genesis__Payment_Frequency__c);
                                successResponse.repaymentFrequency = updatedQQList[0].genesis__Payment_Frequency__c;
                                successResponse.indicativeRate = String.valueOf(updatedQQList[0].Indicative_Interest_Rate__c) + CreateQQActionConstants.PER_ANNUM;
                                successResponse.loanEstablishmentFee = CreateQQActionConstants.DOLLAR +  String.valueOf(updatedQQList[0].Loan_Establishment_Fee__c.setScale(2, RoundingMode.HALF_UP));
                                successResponse.ppsrFees = CreateQQActionConstants.DOLLAR +  String.valueOf(updatedQQList[0].Other_Fees__c.setScale(2, RoundingMode.HALF_UP));
                                successResponse.brokerFee = CreateQQActionConstants.DOLLAR +  String.valueOf(updatedQQList[0].Broker_Fee_Amount__c.setScale(2, RoundingMode.HALF_UP));
                                listOfSuccessResponses.add(successResponse);
                                Attachment quoteReq = new Attachment(
                                                                ParentId = qq.id,
                                                                Name = 'Quote Request Payload - ' + String.valueOf(DateTime.now()) + '.json',
                                                                Body = Blob.valueOf(requestbody));
                                qqAttachments.add(quoteReq);
                            }
                        }
                        if (!qqConsents.isEmpty()) {
                            update qqConsents;
                        }
                        if (!qqAttachments.isEmpty()) {
                            upsert qqAttachments;
                        }
                    }catch(CustomException e){
                        Database.rollback(sp);
                        createErrorResponse('Quote Request not processed. Encountered Error: ' + e.getMessage(), e.getTypeName());
                        ExceptionManager.manageException(e);
                        insert ExceptionManager.getCLCommonLog(e,UnderwritingBatchJobConstants.GENESIS);
                    } 
                    catch(Exception e){
                        Database.rollback(sp);
                        createErrorResponse('Quote Request not processed. Encountered Error: ' + e.getMessage(), e.getTypeName());
                        ExceptionManager.manageException(e);
                        insert ExceptionManager.getCLCommonLog(e,UnderwritingBatchJobConstants.GENESIS);
                    }
                }
            }
            return errorFlag && !listOfErrorResponses.isEmpty() ? listOfErrorResponses.size() > 1 ? JSON.serialize(listOfErrorResponses) : JSON.serialize(listOfErrorResponses[0]) : JSON.serialize(listOfSuccessResponses);  
        }
        
        global static List<genesis__Quick_Quotes__c> createQuoteList(QuoteJSONWrapper quote){
            List<genesis__Quick_Quotes__c> quoteList = new List<genesis__Quick_Quotes__c>();
            Savepoint sp;
            genesis__Quick_Quotes__c quoteRecord = new genesis__Quick_Quotes__c();
            try {
                sp = Database.setSavepoint();
                quoteRecord.genesis__First_Name__c  =  quote.personal_details.firstName.trim();
                quoteRecord.genesis__Last_Name__c  =   quote.personal_details.lastName.trim();
                if(String.isNotBlank(quote.personal_details.middleName)){
                    quoteRecord.Middle_Name__c = quote.personal_details.middleName.trim();
                }
                quoteRecord.Gender__c = quote.personal_details.gender.trim();
                if (quote.personal_details.gender.trim().toLowerCase().equals('other') && String.isNotBlank(quote.personal_details.otherGenderSpecification)) {
                    quoteRecord.Other_Gender_Specification__c = quote.personal_details.otherGenderSpecification.trim();
                }
                quoteRecord.Date_Of_Birth__c  = Date.valueOf(String.valueOf(quote.dob_details.birthYear) + CreateQQActionConstants.DASH_SIGN + String.valueOf(quote.dob_details.birthMonth).leftPad(2, CreateQQActionConstants.ZERO_STRING ) + CreateQQActionConstants.DASH_SIGN + String.valueOf(quote.dob_details.birthDate).leftPad(2, CreateQQActionConstants.ZERO_STRING ));
                quoteRecord.Email__c  =  quote.contact_details.emailAddress;
                quoteRecord.Mobile_Number__c  =  quote.contact_details.mobileNumber;
                String prodName;
                // if (quote.LoanDetails.product.trim().toLowerCase().equals('fixed')){
                //     prodName  =  'Motor Loan Fixed Rate' ;
                // } else if (quote.LoanDetails.product.trim().toLowerCase().equals('auto')){
                //     prodName  =   'Motor Loan Variable Rate';
                // }
                prodName = 'Motor Loan Fixed Rate';
                /* querying product based on product name to assign it to quick quote */
                clcommon__CL_Product__c prod =  [ SELECT  ID, 
                                                        Name,
                                                        clcommon__Product_Name__c
                                                        FROM clcommon__CL_Product__c 
                                                        WHERE clcommon__Product_Name__c  = :prodName
                                                        WITH SECURITY_ENFORCED
                                                        LIMIT 1 ];
                if(prod.clcommon__Product_Name__c.contains('Motor')){
                    quoteRecord.Other_Fees__c = System_Configuration__c.getInstance().PPSR_Registration_Fee__c + System_Configuration__c.getInstance().PPSR_Search_Fee__c;
                }
                quoteRecord.genesis__CL_Product__c  =  prod.id;
                quoteRecord.Term__c = quote.loan_details.term.trim();
                quoteRecord.genesis__Payment_Frequency__c = quote.loan_details.repaymentFrequency.trim();
                quoteRecord.Loan_Amount_Requested__c  =  Decimal.valueOf(quote.loan_details.loanAmount.trim());
                quoteRecord.Loan_Purposes__c  =  quote.loan_details.loanPurpose.trim();
                quoteRecord.Loan_Purpose__c  =  quote.loan_details.loanPurpose.trim();
                quoteRecord.Asset_Type__c = quote.loan_details.assetType.trim();

                if (String.isNotBlank(quote.identification_details.driverLicenceNumber)) {
                    quoteRecord.Driver_Licence__c  =  quote.identification_details.driverLicenceNumber.trim();
                }
                if(String.isNotBlank(quote.identification_details.licenceCardNumber)){
                    quoteRecord.License_Card_Number__c = quote.identification_details.licenceCardNumber.trim();
                }
                if(String.isNotBlank(quote.identification_details.stateOfIssue)){
                    quoteRecord.Driver_Licence_State__c  =  quote.identification_details.stateOfIssue.trim();
                }

                if(String.isNotBlank(quote.address_details.unitNumber) && quote.address_details.unitNumber.trim().isNumeric()){
                    quoteRecord.Unit_Number__c  =  Integer.valueOf(quote.address_details.unitNumber.trim());
                }
                if(quote.address_details.isMailingAddressSame == null){
                    quoteRecord.Is_Mailing_Address_Same__c = false;
                }
                else{
                    quoteRecord.Is_Mailing_Address_Same__c = true;
                }
                if(quote.postaladdress_details == null || quote.postaladdress_details.poGpoAddressFlag == null){
                    quoteRecord.Is_PO_box_exist__c = false;
                }else{
                    quoteRecord.Is_PO_box_exist__c = true;
                }
                if(quote.postaladdress_details != null && String.isNotBlank(quote.postaladdress_details.postalUnitNumber) && quote.postaladdress_details.postalUnitNumber.trim().isNumeric()){
                    quoteRecord.Mailing_Unit_Number__c  =  Integer.valueOf(quote.postaladdress_details.postalUnitNumber.trim());
                } 
                if(quoteRecord.Is_Mailing_Address_Same__c == true && quoteRecord.Is_PO_box_exist__c == false){
                    quoteRecord.Mailing_Street_Number__c =  quote.address_details.streetNumber.trim() ;
                    quoteRecord.Mailing_Street_Name__c = quote.address_details.streetName.trim() ;
                    quoteRecord.Mailing_Street_Type__c = quote.address_details.streetTypeAddress.trim();
                    quoteRecord.Mailing_State__c = quote.address_details.stateAddress.trim();
                    quoteRecord.Mailing_Country__c = CreateQQActionConstants.AUSTRALIA;
                    quoteRecord.Mailing_City__c = quote.address_details.city.trim() ;
                    quoteRecord.Mailing_Postal_Code__c = quote.address_details.postalCode.trim();
                    if (!String.isBlank(quote.address_details.propertyName)) {
                        quoteRecord.Mailing_Property_Name__c = quote.address_details.propertyName.trim();
                    }
                    quoteRecord.Mailing_Unformatted_Address__c = quoteRecord.Mailing_Street_Number__c + ' ' + quoteRecord.Mailing_Street_Name__c + ' ' + quoteRecord.Mailing_Street_Type__c + ', ' + quoteRecord.Mailing_City__c + ' ' + quoteRecord.Mailing_State__c + ', ' + quoteRecord.Mailing_Country__c;
                }else if(quoteRecord.Is_Mailing_Address_Same__c == false && quoteRecord.Is_PO_box_exist__c == false){
                    quoteRecord.Mailing_Street_Number__c = quote.postaladdress_details.postalStreetNumber;
                    quoteRecord.Mailing_Street_Name__c = quote.postaladdress_details.postalStreetName;
                    quoteRecord.Mailing_Street_Type__c = quote.postaladdress_details.postalStreetTypeAddress;
                    quoteRecord.Mailing_State__c = quote.postaladdress_details.postalStateAddress;
                    quoteRecord.Mailing_Country__c = CreateQQActionConstants.AUSTRALIA;
                    quoteRecord.Mailing_City__c = quote.postaladdress_details.postalCity;
                    quoteRecord.Mailing_Postal_Code__c = quote.postaladdress_details.postalCode;
                    if (!String.isBlank(quote.postaladdress_details.postalPropertyName)) {
                        quoteRecord.Mailing_Property_Name__c = quote.postaladdress_details.postalPropertyName.trim();
                    }                   
                    quoteRecord.Mailing_Unformatted_Address__c = quoteRecord.Mailing_Street_Number__c + ' ' + quoteRecord.Mailing_Street_Name__c + ' ' + quoteRecord.Mailing_Street_Type__c + ', ' + quoteRecord.Mailing_City__c + ' ' + quoteRecord.Mailing_State__c + ', ' + quoteRecord.Mailing_Country__c;
                }else{
                    quoteRecord.PO_GPO_Box__c = quote.gpoaddress_details.poBoxNumber;
                    quoteRecord.Mailing_State__c = quote.gpoaddress_details.postalBoxStateAddress;
                    quoteRecord.Mailing_Country__c = CreateQQActionConstants.AUSTRALIA;
                    quoteRecord.Mailing_City__c = quote.gpoaddress_details.postalBoxCity;
                    quoteRecord.Mailing_Postal_Code__c = quote.gpoaddress_details.poBoxPostalCode;
                }
                quoteRecord.Street_Name__c  =  quote.address_details.streetName ;
                quoteRecord.Street_Number__c  =  quote.address_details.streetNumber ;
                quoteRecord.Street_Type__c  =  quote.address_details.streetTypeAddress;
                quoteRecord.genesis__City__c  =   quote.address_details.city ;
                quoteRecord.genesis__State__c  =  quote.address_details.stateAddress;
                quoteRecord.genesis__Postal_Code__c  =  quote.address_details.postalCode ;
                quoteRecord.property_name__c = quote.address_details.propertyName;
                quoteRecord.genesis__Country__c  =  CreateQQActionConstants.AUSTRALIA;
                
                quoteRecord.Unformatted_Address__c  =  quoteRecord.Street_Number__c + ' ' + quoteRecord.Street_Name__c + ' ' + quoteRecord.Street_Type__c + ', ' + quoteRecord.genesis__City__c + ' ' + quoteRecord.genesis__State__c + ', ' + quoteRecord.genesis__Country__c ;

                quoteRecord.CCR_Consent__c  =  true;   
                quoteRecord.Terms_Of_Use_Consent__c  =  true;
                quoteRecord.Communication_Consent__c  =  true;
                
                quoteRecord.Residential_Status__c  =  quote.address_details.residentialStatus;
                quoteRecord.Sales_Channel__c  =  ConstantValues.CHANNEL_BROKER;
                /**
                 * checking whether active broker exists in the system or not
                 */
                List<Contact> brokerContactDetails = [
                                                        SELECT Id,
                                                        brk_AccreditationStatus__c,
                                                        Email,
                                                        Broker_ID__c,
                                                        Account.id,
                                                        (select id from Users)
                                                        FROM Contact where Broker_ID__c =: quote.broker_details.brokerId and brk_AccreditationStatus__c = 'Active' 
                                                        WITH SECURITY_ENFORCED
                                                        limit 1
                                                    ];
                if (!brokerContactDetails.isEmpty()) {
                    quoteRecord.Broker__c = brokerContactDetails[0].Account.id;
                    quoteRecord.Broker_Contact__c = brokerContactDetails[0].Id;
                    quoteRecord.Broker_Email__c = brokerContactDetails[0].Email;
                    quoteRecord.Broker_Initiated__c = true;
                    quoteRecord.Broker_Fee_Amount__c = Decimal.valueOf(quote.broker_details.brokerFeeAmount);
                    /**
                     * to make the quote available in broker portal
                     */
                    if (!brokerContactDetails[0].Users.isEmpty()) {
                        quoteRecord.OwnerId = brokerContactDetails[0].Users[0].id;
                    }else {
                        throw new CustomException('Active broker user not present. Contact the Salesforce Admin for help.');
                    }
                }
                /* querying account based on mail provided to check for existing borrower account */
                List<Account> existingAccount = [SELECT Id,
                                                        Email__c
                                                        FROM Account 
                                                        WHERE Email__c =: quoteRecord.Email__c WITH SECURITY_ENFORCED order by createddate desc
                                                        LIMIT 1];
                /**
                 * if no account exists in the system, create new account
                 */
                if(existingAccount.isEmpty()){
                    Account newAcc = new Account();
                    newAcc.First_Name__c  =  quoteRecord.genesis__First_Name__c;
                    newAcc.Last_Name__c  =  quoteRecord.genesis__Last_Name__c;
                    newAcc.Name = quoteRecord.genesis__First_Name__c + ' ' + quoteRecord.genesis__Last_Name__c;
                    if (quoteRecord.Middle_Name__c != null) {
                        newAcc.Middle_Name__c  =  quoteRecord.Middle_Name__c;
                    }
                    newAcc.Date_of_Birth__c  =  quoteRecord.Date_Of_Birth__c;
                    newAcc.Mobile_Number__c  =  quoteRecord.Mobile_Number__c;
                    newAcc.Email__c = quoteRecord.Email__c;
                    newAcc.cnotify__Email__c = quoteRecord.Email__c;
                    newAcc.Residential_Status__c = quoteRecord.Residential_Status__c;
                    newAcc.Gender__c = quoteRecord.Gender__c;
                    
                    /**
                     * account address updation
                     */
                    if (quoteRecord.Unit_Number__c != null) {
                        newAcc.Unit_Number__c = String.valueOf(quoteRecord.Unit_Number__c);
                    }
                    if (quoteRecord.property_name__c != null) {
                        newAcc.Property_Name__c = quoteRecord.property_name__c;
                    }
                    newAcc.Street_Number__c = quoteRecord.Street_Number__c;
                    newAcc.Street_Name__c = quoteRecord.Street_Name__c;
                    newAcc.Street_Type__c = quoteRecord.Street_Type__c;
                    newAcc.City__c = quoteRecord.genesis__City__c;
                    newAcc.State__c = quoteRecord.genesis__State__c;
                    newAcc.Zip__c = quoteRecord.genesis__Postal_Code__c;
                    newAcc.Country__c = CreateQQActionConstants.AUSTRALIA;
                    newAcc.BillingCity = newAcc.City__c;
                    newAcc.BillingCountry = newAcc.Country__c;
                    newAcc.BillingPostalCode = newAcc.Zip__c;
                    newAcc.BillingStreet = newAcc.Street_Number__c + ' ' + newAcc.Street_Name__c + ' ' + newAcc.Street_Type__c;
                    newAcc.BillingState = newAcc.State__c;
                    if (!Schema.sObjectType.Account.isAccessible() || 
                        !Schema.sObjectType.Account.isCreateable() || 
                        !Schema.sObjectType.Account.isUpdateable() ) {
                            throw new CustomException(CpConstants.DML_ACCESS_ERROR);
                    }
                    upsert newAcc;
                    List<Account> createdAccount = [SELECT Id, 
                                                        Name, 
                                                        First_Name__c,
                                                        Middle_Name__c,
                                                        Last_Name__c,
                                                        Date_of_Birth__c,
                                                        Gender__c,
                                                        Email__c,
                                                        Mobile_Number__c    
                                                        FROM Account 
                                                        WHERE Email__c =: quoteRecord.Email__c
                                                        WITH SECURITY_ENFORCED
                                                        LIMIT 1];
                    if (!createdAccount.isEmpty()) {
                        quoteRecord.genesis__Account__c	= createdAccount[0].Id;
                    }else {
                        throw new CustomException('Account creation failed. Contact the Salesforce Admin for help.');
                    }
                }else{
                    quoteRecord.genesis__Account__c	= existingAccount[0].Id;
                }

                // quoteRecord.Bureau_Checks__c = true;//marking true as the QQ is only created if Bureau checks are completed
                // quoteRecord.utmCampaign__c=utmCampaign;
                // quoteRecord.utmContent__c=utmContent;
                // quoteRecord.utmMedium__c=utmMedium;
                // quoteRecord.utmSource__c=utmSource;
                // quoteRecord.GCLID__c=gclId;
                // quoteRecord.MSCLKID__c=mscklID;
                // quoteRecord.pageName__c=pageName;
                // quoteRecord.sourceCode__c=sourceCode;
                // quoteRecord.offerCode__c=offerCode;
                // if(String.isNotBlank(this.quoteTaggingIdJson)){
                //     quoteRecord.Quote_Tagging_Id__c = this.quoteTaggingIdJson;
                // }
                //upsert quoteRecord;
                quoteList.add(quoteRecord);
            } catch (Exception e) {
                Database.rollback(sp);
                createErrorResponse('Quote Request not processed. Encountered Error: ' + e.getMessage(), e.getTypeName());
                ExceptionManager.manageException(e);
                insert ExceptionManager.getCLCommonLog(e,UnderwritingBatchJobConstants.GENESIS);
            }
            return quoteList;
        }
        public static void validate(QuoteJSONWrapper quotePayLoad){
            QuoteJSONWrapper.PersonalDetails personalDetails = quotePayLoad.personal_details;
            if (personalDetails != null) {
                if (personalDetails.firstName == null) {
                    createErrorResponse('First name can not be blank', 'REQUIRED_PARAM_MISSING');
                }else if(!personalDetails.firstName.isAlphaSpace() || !(personalDetails.firstName.trim().length() >= 2 && personalDetails.firstName.trim().length() <= 15)){
                    createErrorResponse('Only upper and lower case characters, - and space allowed in between 2-15 characters for First Name.', 'VALIDATION_ERROR');
                }
                if (personalDetails.lastName == null) {
                    createErrorResponse('Last name can not be blank', 'REQUIRED_PARAM_MISSING');
                }else if(!personalDetails.lastName.isAlphaSpace() || !(personalDetails.lastName.trim().length() >= 2 && personalDetails.lastName.trim().length() <= 15)){
                    createErrorResponse('Only upper and lower case characters, - and space allowed in between 2-15 characters for Last Name.', 'VALIDATION_ERROR');
                }
                if(personalDetails.middleName != null && (!personalDetails.middleName.isAlphaSpace() || !(personalDetails.middleName.trim().length() >= 2 && personalDetails.middleName.trim().length() <= 15))){
                    createErrorResponse('Only upper and lower case characters, - and space allowed in between 2-15 characters for Middle Name.', 'VALIDATION_ERROR');
                }
                if (personalDetails.gender == null) {
                    createErrorResponse('Gender can not be blank', 'REQUIRED_PARAM_MISSING');
                }else if (!(personalDetails.gender.trim().toLowerCase().equals('male') || personalDetails.gender.trim().toLowerCase().equals('female') || personalDetails.gender.trim().toLowerCase().equals('other') || personalDetails.gender.trim().toLowerCase().equals('unknown'))) {
                    createErrorResponse('Required value (Male, Female, Other, Unknown) is missing for gender', 'VALIDATION_ERROR');
                }else if(personalDetails.gender.trim().toLowerCase().equals('other') && personalDetails.otherGenderSpecification == null){
                    createErrorResponse('Other gender specification field can not be blank when you are choosing gender value as Other', 'REQUIRED_PARAM_MISSING');
                }
            }else {
                createErrorResponse('Personal details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
            }
            QuoteJSONWrapper.DOBDetails dobDetails = quotePayLoad.dob_details;
            if (dobDetails != null) {
                if (dobDetails.birthDate == null || dobDetails.birthMonth == null || dobDetails.birthYear == null) {
                    createErrorResponse('One of Birth date, Birth month and Birth year is blank', 'REQUIRED_PARAM_MISSING');
                }else if ( !(((Date.newInstance(dobDetails.birthYear, dobDetails.birthMonth, dobDetails.birthDate).daysBetween(System.today()))/365) >= 18)) {
                    createErrorResponse('Must of 18 years old.', 'VALIDATION_ERROR');
                }
            }else {
                createErrorResponse('DOB details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
            }
            QuoteJSONWrapper.ContactDetails contactDetails = quotePayLoad.contact_details;
            if (contactDetails != null) {
                if (contactDetails.emailAddress == null) {
                    createErrorResponse('Email address can not be blank', 'REQUIRED_PARAM_MISSING');
                }else if (!(contactDetails.emailAddress.trim().length() >= 4 && contactDetails.emailAddress.trim().length() <= 60)) {
                    createErrorResponse('Valid email must be in between 4-60 characters.', 'VALIDATION_ERROR');
                }else if(!validateEmail(contactDetails.emailAddress.trim())){
                    createErrorResponse('Email format is not correct or valid domain name has not been provided', 'VALIDATION_ERROR');
                }
                if (contactDetails.mobileNumber == null) {
                    createErrorResponse('Mobile number can not be blank', 'REQUIRED_PARAM_MISSING');
                }else if(!contactDetails.mobileNumber.trim().substring(1).isNumeric() || !(contactDetails.mobileNumber.trim().substring(1).length() == 8)){
                    createErrorResponse('Valid mobile number must be 8 digit number.', 'VALIDATION_ERROR');
                }
            }else {
                createErrorResponse('Contact details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
            }
            QuoteJSONWrapper.LoanDetails loanDetails = quotePayLoad.loan_details;
            if (loanDetails != null) {
                // if (loanDetails.product == null) {
                //     createErrorResponse('Loan product can not be blank', 'REQUIRED_PARAM_MISSING');
                // }else if(!(loanDetails.product.trim().toLowerCase().equals('personal') || loanDetails.product.trim().toLowerCase().equals('auto'))){
                //     createErrorResponse('Loan product must be either Personal or Auto', 'VALIDATION_ERROR');
                // }
                if (loanDetails.term == null) {
                    createErrorResponse('Loan term can not be blank', 'REQUIRED_PARAM_MISSING');
                }else if (!loanDetails.term.trim().isNumeric() || !((Integer.valueOf(loanDetails.term.trim()) >= 2) && (Integer.valueOf(loanDetails.term.trim()) <= 7))) {
                    createErrorResponse('Loan term must be a number between 2 and 7', 'VALIDATION_ERROR');
                }
                if (loanDetails.repaymentFrequency == null) {
                    createErrorResponse('Loan payment frequency can not be blank', 'REQUIRED_PARAM_MISSING');
                }else if (!(loanDetails.repaymentFrequency.trim().toLowerCase().equals('weekly') || loanDetails.repaymentFrequency.trim().toLowerCase().equals('bi-weekly') || loanDetails.repaymentFrequency.trim().toLowerCase().equals('monthly'))) {
                    createErrorResponse('Loan payment frequency must be one of Weekly, Bi-Weekly and Monthly', 'VALIDATION_ERROR');
                }
                if (loanDetails.loanAmount == null) {
                    createErrorResponse('Loan amount can not be blank', 'REQUIRED_PARAM_MISSING');
                }else if (!loanDetails.loanAmount.trim().isNumeric() || !(Integer.valueOf(loanDetails.loanAmount.trim()) >= 5000 && Integer.valueOf(loanDetails.loanAmount.trim()) <= 200000)) {
                    createErrorResponse('Loan amount must be in between 5000 to 200000', 'VALIDATION_ERROR');
                }
                if (loanDetails.loanPurpose == null) {
                    createErrorResponse('Loan purpose can not be blank', 'REQUIRED_PARAM_MISSING');
                }
                if (loanDetails.assetType == null) {
                    createErrorResponse('Loan asset type can not be blank', 'REQUIRED_PARAM_MISSING');
                }else if(!(loanDetails.assetType.trim().toLowerCase().equals('auto') || loanDetails.assetType.trim().toLowerCase().equals('marine') || loanDetails.assetType.trim().toLowerCase().equals('motorhome') || loanDetails.assetType.trim().toLowerCase().equals('motorcycle'))){
                    createErrorResponse('Loan asset type required value missing', 'VALIDATION_ERROR');
                }
            }else {
                createErrorResponse('Loan details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
            }
            QuoteJSONWrapper.IdentificationDetails identificationInfo = quotePayLoad.identification_details;
            if (identificationInfo != null) {
                if (identificationInfo.isDriverLicenceAvailable == true && (identificationInfo.driverLicenceNumber == null || identificationInfo.licenceCardNumber == null || identificationInfo.stateOfIssue == null)) {
                    createErrorResponse('Some of Identification info blank whereas DriverLicenceAvailable checkbox has been chosen as true', 'REQUIRED_DATA_MISSING');
                }
                if (identificationInfo.driverLicenceNumber != null && !(identificationInfo.driverLicenceNumber.trim().length() >= 5 && identificationInfo.driverLicenceNumber.trim().length() <= 9)) {
                    createErrorResponse('Driver licence number have to be in between 5-9 characters', 'VALIDATION_ERROR');
                }else if (identificationInfo.stateOfIssue != null && identificationInfo.stateOfIssue.trim().length() != 3) {
                    createErrorResponse('State of issue must consist of 3 characters', 'VALIDATION_ERROR');
                }
            }
            QuoteJSONWrapper.AddressDetails addressDetails = quotePayLoad.address_details;
            QuoteJSONWrapper.PostalAddressDetails postalAddressDetails = quotePayLoad.postaladdress_details;
            QuoteJSONWrapper.GPOAddressDetails gpoAddressDetails = quotePayLoad.gpoaddress_details;
            if (addressDetails != null) {
                if (((addressDetails.unitNumber != null && !addressDetails.unitNumber.trim().isNumeric())) || ((addressDetails.postalCode != null && !addressDetails.postalCode.trim().isNumeric()))) {
                    createErrorResponse('Unit number and postal code must be a number.', 'VALIDATION_ERROR');
                }
                if (addressDetails.postalCode == null || addressDetails.stateAddress == null || addressDetails.streetNumber == null || addressDetails.residentialStatus == null || addressDetails.streetName == null || addressDetails.city == null || addressDetails.streetTypeAddress == null) {
                    createErrorResponse('One of required fields for address is missing', 'REQUIRED_PARAM_MISSING');
                }else if (addressDetails.streetNumber != null && !(addressDetails.streetNumber.trim().length() >= 1 && addressDetails.streetNumber.trim().length() <= 8)) {
                    createErrorResponse('Street number must lie between 1-8 characters.', 'VALIDATION_ERROR');
                }
                if (addressDetails.isMailingAddressSame == null && postalAddressDetails == null) {
                    createErrorResponse('Postal address details not provided whereas IsMailingAddressSame has been chosen as false. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
                }else if(addressDetails.isMailingAddressSame == null && postalAddressDetails != null){
                    if (postalAddressDetails.postalStreetNumber == null || postalAddressDetails.postalStateAddress == null || postalAddressDetails.postalStreetName == null || postalAddressDetails.postalCity == null || postalAddressDetails.postalStreetTypeAddress == null || postalAddressDetails.postalCode == null) {
                        createErrorResponse('One of required fields for postal address is missing', 'REQUIRED_PARAM_MISSING');
                    }else if (((postalAddressDetails.postalUnitNumber != null && !postalAddressDetails.postalUnitNumber.trim().isNumeric())) || ((postalAddressDetails.postalCode != null && !postalAddressDetails.postalCode.trim().isNumeric()))) {
                        createErrorResponse('Unit number and postal code of postal address must be a number.', 'VALIDATION_ERROR');
                    }
                }
            }else {
                createErrorResponse('Address details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
            }
            if (postalAddressDetails != null && postalAddressDetails.poGpoAddressFlag == true && gpoAddressDetails == null) {
                createErrorResponse('GPO Address details not provided whereas PoGpoAddressFlag has been chosen as true. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
            }else if (postalAddressDetails != null && postalAddressDetails.poGpoAddressFlag == true && gpoAddressDetails != null) {
                if (gpoAddressDetails.poBoxNumber == null || gpoAddressDetails.postalBoxCity == null || gpoAddressDetails.poBoxPostalCode == null || gpoAddressDetails.postalBoxStateAddress == null) {
                    createErrorResponse('One of required fields for GPO address is missing', 'REQUIRED_PARAM_MISSING');
                }
            }
            
            QuoteJSONWrapper.BrokerDetails brokerDetails = quotePayLoad.broker_details;
            if (brokerDetails == null || brokerDetails.brokerFeeAmount == null || brokerDetails.brokerId == null) {
                createErrorResponse('Broker details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
            }else if(brokerDetails.brokerId != null){
                List<Contact> brokerContactDetails = [
                                                        SELECT Id,
                                                        brk_AccreditationStatus__c,
                                                        Email,
                                                        Broker_ID__c,
                                                        Account.id FROM Contact where Broker_ID__c =: brokerDetails.brokerId and brk_AccreditationStatus__c = 'Active' WITH SECURITY_ENFORCED limit 1
                                                    ];
                if (brokerContactDetails.isEmpty()) {
                    createErrorResponse('Active broker not found. Contact the Salesforce Admin for help.', 'BROKER_UNAVAILABLE');
                }
            }
            QuoteJSONWrapper.QuoteConsentDetails quoteConsentDetails = quotePayLoad.quoteconsent_details;
            if (quoteConsentDetails == null || quoteConsentDetails.quoteConsent == null || quoteConsentDetails.quoteConsent == false) {
                createErrorResponse('Quote consent details not provided. Verify that the required fields are provided or contact the Salesforce Admin for help.', 'REQUIRED_DATA_MISSING');
            }
            List<genesis__Quick_Quotes__c> qqListExisiting = [
                                                                select id,
                                                                Name
                                                                from genesis__Quick_Quotes__c
                                                                where Email__c =: contactDetails.emailAddress.trim() 
                                                                WITH SECURITY_ENFORCED limit 1
                                                            ];
            if (!qqListExisiting.isEmpty()) {
                createErrorResponse('Another Quote with same email already exists in the system - ' + qqListExisiting[0].Name + '.Contact the Salesforce Admin for help.', 'VALIDATION_ERROR');
            }
        }
        public static void createErrorResponse(String errorMessage, String errorCode){
            QuoteJSONWrapper.ErrorResponse errorResponse = new QuoteJSONWrapper.ErrorResponse();
            errorResponse.message = errorMessage;
            errorResponse.errorCode = errorCode;
            listOfErrorResponses.add(errorResponse);
            errorFlag = true;
        }
        public static Boolean validateEmail(String email) {
            final String DOMAIN_1 = '.con';
            final String DOMAIN_2 = '.con.au';
            final String DOMAIN_3 = '.comm';
            final String DOMAIN_4 = '.comm.au';
            final String DOMAIN_5 = 'hotmsil.com';
            final String DOMAIN_6 = 'gmsil.com';
            final String AT_SIGN = '@';
            final List<String> INVALID_DOMAINS = new List<String>{'.con','.con.au','.comm','.comm.au','hotmsil.com','gmsil.com'};
            String domainPart = email.split(AT_SIGN)[1];
            for (String invalidDomain : INVALID_DOMAINS) {
                if (domainPart.contains(invalidDomain)) {
                    return false;
                }
            }
            String emailRegex = '^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\\.[a-zA-Z]{2,4}$';
            Pattern emailPattern = Pattern.compile(emailRegex);
            Matcher emailMatcher = emailPattern.matcher(email);
            return emailMatcher.matches();
        }
        @future(callout = true)
        global static void doCallouts(id qqId){
            System.savepoint sp;
            String unitNumber;
            String response;
            String result;
            String pricingResult;
            String rulesResp;
            List<genesis__Quick_Quotes__c> qqList ;
            try {
                qqList = [SELECT id,
                                Name,
                                Loan_Amount_Requested__c,
                                Email__C,
                                Gender__c,
                                genesis__Account__c,
                                genesis__First_Name__c,
                                genesis__Last_Name__c,
                                Middle_Name__c,
                                genesis__State__c,
                                Loan_Purpose__c,
                                Other_Loan_Purpose__c,
                                Driver_Licence_State__c,
                                Driver_Licence__c,
                                genesis__Financed_Amount__c,
                                genesis__City__c,
                                Unit_Number__c,
                                Street_Type__c,
                                Street_Name__c,
                                CCR_Score__c,
                                Street_Number__c,
                                genesis__Country__c,
                                Mobile_Number__c,
                                genesis__Postal_Code__c,
                                Bureau_Checks__c,
                                CL_Product_Name__c,
                                Date_Of_Birth__c,
                                Unformatted_Address__c,
                                Quick_Quote_Evaluated__c
                            FROM genesis__Quick_Quotes__c
                            WHERE id =: qqId
                            WITH SECURITY_ENFORCED
                            LIMIT 1];
                if(qqList.size() > 0){
                    if(qqList[0].Bureau_Checks__c){
                        throw new CustomException(QuickQuoteBEHandlerConstants.IB_DATA_CAPTURED);
                    }
                    List<Account> accList = [SELECT id, Account_Security_Token__c 
                                            FROM Account    
                                            WHERE Email__c =: qqList[0].Email__c 
                                            ORDER BY CreatedDate DESC 
                                            LIMIT 1];
                    Equifaxsoftpullcallout.EquifaxSoftpullRequestWrapper equifaxWrap = new Equifaxsoftpullcallout.EquifaxSoftpullRequestWrapper();
                    //passing Softpull request details to request wrapper
                    equifaxWrap.firstName = qqList[0].genesis__First_Name__c;
                    equifaxWrap.lastName = qqList[0].genesis__Last_Name__c;
                    equifaxWrap.middleName = qqList[0].Middle_Name__c;
                    equifaxWrap.streetType = qqList[0].Street_Type__c;
                    equifaxWrap.streetName = qqList[0].Street_Name__c;
                    equifaxWrap.streetNumber = qqlist[0].Street_Number__c;
                    equifaxWrap.city = qqList[0].genesis__City__c;
                    equifaxWrap.province = qqlist[0].genesis__State__c;
                    equifaxWrap.postalCode = qqList[0].genesis__Postal_Code__c;
                    equifaxWrap.driverLicense = qqList[0].Driver_Licence__c;
                    equifaxWrap.loanAmount = String.valueOf(qqList[0].Loan_Amount_Requested__c);
                    equifaxWrap.unitNum = String.valueOf(qqlist[0].Unit_Number__c);
                    equifaxWrap.dateOfBirth = String.valueOf(qqlist[0].Date_Of_Birth__c);
                    equifaxWrap.gender = qqList[0].Gender__c;
                    //passing IB request details to the request wrapper
                    equifaxWrap.IB_firstName=qqList[0].genesis__First_Name__c;  
                    equifaxWrap.IB_middleName=qqList[0].Middle_Name__c;  
                    equifaxWrap.IB_lastName=qqList[0].genesis__Last_Name__c; 
                    equifaxWrap.IB_dateOfBirth=String.valueOf(qqlist[0].Date_Of_Birth__c);
                    equifaxWrap.IB_mobile=String.valueOf(qqList[0].Mobile_Number__c);
                    equifaxWrap.IB_addressLine1=qqlist[0].Street_Number__c +' '+qqList[0].Street_Name__c;
                    equifaxWrap.IB_adminArea3=String.valueOf(qqlist[0].Unit_Number__c);
                    equifaxWrap.IB_adminArea1=qqlist[0].genesis__State__c; 
                    equifaxWrap.IB_postcode=qqList[0].genesis__Postal_Code__c;  
                    equifaxWrap.driverState = qqList[0].Driver_Licence_State__c;
    
                    
                    Wrapper.ScoreSeekerRequestWrapper resp = Equifaxsoftpullcallout.callout(equifaxWrap); // callout to IB and Equifax ScoreSeeker(Softpull)
                    if(resp == null) {
                        throw new CustomException(CreateQQActionConstants.SOFTPULL_GENERATION_FAILED_MGS);
                    }else{
                        CreateQQAction.insertAtt(resp, qqList[0].id);
                    }
                    sp = Database.setSavepoint();
                    if(accList.size()==0 && qqList[0].genesis__Account__c == null){
                        GenerateEncryptedQQuoteTokenBatch.updateQuickQuote(qqList);
                        QQToAppConversionHandler obj = new QQToAppConversionHandler();
                        obj.setQQId(qqId);
                        obj.setConfigId(qqlist[0].CL_Product_Name__c);
                        obj.getRunTimeQuery();
                        Account qqAccount = obj.createAccount();
                        insert qqAccount;
                        qqAccount.Mogo_Token__c = FlowfiUtil.generateUniqueId(qqAccount.id + qqAccount.Name + 
                                                                                qqAccount.First_Name__c + qqAccount.Middle_Name__c +
                                                                                qqAccount.Last_Name__c,
                                                                                Integer.valueOf(QuickQuoteBEHandlerConstants.TWELVE));
                        update qqAccount;
                        if(!Test.isRunningTest()){
                            CreateQQAction classObj = new CreateQQAction();
                            classObj.updateSecToken(qqAccount);
                        }
                        qqlist[0].genesis__Account__c = qqAccount.Id;
                    }else if(!accList.isEmpty() && qqList[0].genesis__Account__c == null){
                        qqList[0].genesis__Account__c = accList[0].id;
                    }
                    if(resp.oneScore != null){
                        qqList[0].CCR_Score__c = resp.oneScore;
                        qqList[0].Bureau_Checks__c = true;
                        unitNumber = qqList[0].Unit_Number__c != null ? qqList[0].Unit_Number__c + ' ': '';
                        qqList[0].Unformatted_Address__c=unitNumber+qqList[0].Street_Number__c+' '+qqList[0].Street_Name__c+' '+qqList[0].Street_Type__c+', '+qqList[0].genesis__City__c+' '+qqList[0].genesis__State__c+', '+qqList[0].genesis__Country__c;
                        rulesResp = QuickQuoteBEHandler.runScoringAndRules(qqList[0].id);
                        response = rulesResp;
                        if(response.equals(QuickQuoteBEHandlerConstants.SUCCESS)){
                            response=  PricingManager.getRateEstimate(qqList[0].id);
                            qqList[0].genesis__Financed_Amount__c = qqList[0].Loan_Amount_Requested__c;
                        }
                    }else{
                        if(resp.resXml != null && resp.resXml.containsIgnoreCase(CreateQQActionConstants.ERROR_TAG)){
                            String errMsg = (resp.resXml!=null && String.isNotBlank(resp.resXml)) ? resp.resXml.subStringBetween(CreateQQActionConstants.DETAIL_TAG1, CreateQQActionConstants.DETAIL_TAG2):'';
                            qqList[0].genesis__Status__c = CreateQQActionConstants.FAILED;
                            qqList[0].Quote_Decision_Date__c = System.now();
                            //<--this change was made as per the defect ticket SYM-2213 raised on 24-05-2022-->>//
                            //qqList[0].Failed_Reason__c = CreateQQActionConstants.EQUIFAX_FAILED + CreateQQActionConstants.DASH_SIGN_WITH_SPACE +errMsg;                        
                            qqList[0].Failed_Reason__c = CreateQQActionConstants.EQUIFAX_FAILED + CreateQQActionConstants.DASH_SIGN_WITH_SPACE +errMsg;
                            response = CreateQQActionConstants.FAILED;
                        }else if(resp.resXml!=null && resp.resXml.containsIgnoreCase(CreateQQActionConstants.MESSAGE_TAG1)){
                            qqlist[0].Quote_New_to_Bureau__c=true;
                            qqList[0].Bureau_Checks__c = true;
                            unitNumber = qqList[0].Unit_Number__c != null ? qqList[0].Unit_Number__c + ' ': '';
                            qqList[0].Unformatted_Address__c=unitNumber+qqList[0].Street_Number__c+' '+qqList[0].Street_Name__c+' '+qqList[0].Street_Type__c+', '+qqList[0].genesis__City__c+' '+qqList[0].genesis__State__c+', '+qqList[0].genesis__Country__c;
                            result = QuickQuoteBEHandler.runScoringAndRulesforStranger(qqList[0].id);
                            if(!result.equals(QuickQuoteBEHandlerConstants.FAILED)){
                                pricingResult =  PricingManager.getRateEstimate(qqList[0].id);
                                qqList[0].genesis__Financed_Amount__c = qqList[0].Loan_Amount_Requested__c;
                                if(pricingResult.equals(CreateQQActionConstants.REFERRED)){
                                    throw new CustomException(CreateQQActionConstants.REFERRED);
                                } 
                                if(!Test.isRunningTest()){
                                    result = pricingResult;
                                }else{
                                    result=ConstantValues.success;
                                }
                            }else{
                                throw new CustomException(CreateQQActionConstants.FAILED);
                            }
                            if(result==ConstantValues.success){
                                response=result;
                            }else{
                                throw new CustomException(CreateQQActionConstants.FAILED);
                            }
                        }else{
                            throw new CustomException(CreateQQActionConstants.UNAVAILABLE);
                        }
                    }
                }
                update qqList;
            }catch (Exception e) {
                if(sp == null){
                    sp = Database.setSavepoint();
                }
                ExceptionManager.manageException(e);
                if(e.getTypeName().equals(QuickQuoteBEHandlerConstants.CUSTOM_EXCEPTION_TYPE)){
                    throw new CustomException(e.getMessage());
                }
                else{
                    Database.rollback(sp);
                    throw new CustomException(ResponseMessenger.genericExceptionMsg + QuickQuoteBEHandlerConstants.HYPHEN + e.getMessage());
                }
                //return ('Failed-'+e.getMessage());
            }
            qqList[0].Quick_Quote_Evaluated__c=true;
            update qqList;
            System.debug('response=>' + response);
        }
        global static void getRateEstimate(id qqId){
            String response;
            String respStr;
            List<genesis__Quick_Quotes__c> qqList;
            genesis__Quick_Quotes__c qqObj;
            System.Savepoint sp = Database.setSavepoint();
            try {
                response = PricingManager.getRateEstimate(qqId);
                if(response == ConstantValues.success){
                    qqList = [SELECT id, 
                                Loan_Amount_Requested__c,
                                genesis__Financed_Amount__c,
                                Interest_Type__c,
                                Sales_Channel__c,
                                CCR_Score__c,
                                Credit_Rating_Matrix__r.Risk_Grade__c,
                                Indicative_Interest_Rate__c,
                                Max_Loan_Amount__c,
                                Loan_Establishment_Fee_Percent__c,
                                genesis__Expected_Start_Date__c,
                                CL_Product_Name__c,
                                Loan_Establishment_Fee__c,
                                genesis__Status__c,
                                Final_Score__c,
                                Repayment_Amount__c,
                                Underwriting_check__c,
                                Quick_Quote_Evaluated__c,
                                Failed_Reason__c
                            FROM genesis__Quick_Quotes__c
                            WHERE id =: qqId
                            WITH SECURITY_ENFORCED
                            LIMIT 1];
    
                    if(!qqList.isEmpty()){
                        qqObj = qqList[0];
                        if(qqObj.Sales_Channel__c == EMICalculationConstants.OTP_CHANNEL && !qqObj.Quick_Quote_Evaluated__c){
                            throw new CustomException(EMICalculationConstants.UNDWERITING_ERROR_MSG);
                        }
                        if(qqObj.genesis__Status__c == ConstantValues.qqStatus_failed || qqObj.genesis__Status__c == ConstantValues.qqStatus_convertedToApp || qqObj.genesis__Status__c == ConstantValues.qqStatus_expired){
                            throw new CustomException(EMICalculationConstants.IMPROPER_STATUS_ERROR_MSG);
                        }
                    }
    
                    if(qqObj.CL_Product_Name__c == 'Motor' ){
                        respStr = EMICalculationConstants.OUTPUT_TEXT_1 +  qqObj.Indicative_Interest_Rate__c + '%,' + 
                                //' Maximum Loan Amount - $ ' + qqObj.Max_Loan_Amount__c + ',' +
                                //' LEF % - ' + qqObj.Loan_Establishment_Fee_Percent__c + '%,' + 
                                //' LEF Amount - $ ' + qqObj.Loan_Establishment_Fee__c + ',' +
                                EMICalculationConstants.OUTPUT_TEXT_2 + qqObj.Repayment_Amount__c;
                    } else {
                        respStr = EMICalculationConstants.OUTPUT_TEXT_1 +  qqObj.Indicative_Interest_Rate__c + '%,' + 
                                //' Maximum Loan Amount - $ ' + qqObj.Max_Loan_Amount__c + ',' +
                                //' LEF % - ' + qqObj.Loan_Establishment_Fee_Percent__c + '%,' + 
                                //' LEF Amount - $ ' + qqObj.Loan_Establishment_Fee__c + ',' +
                                EMICalculationConstants.OUTPUT_TEXT_2 + qqObj.Repayment_Amount__c;
                    }
                }else{
                    throw new CustomException(response);
                }
            }catch(Exception e) {
                Database.rollback(sp);
                ExceptionManager.manageException(e);
                insert ExceptionManager.getClCommonLog(e, ConversionConstant.genesis);
                throw new CustomException(ResponseMessenger.somethingWentWrong + '-' + e.getMessage());
            }
            System.debug('RateEstimate Response=>' + respStr);
        }
    }