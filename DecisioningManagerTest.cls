/******************************************************************************************************************
@Company            : CloudKaptan Consultancy Services Pvt. Ltd.
@Developer          : Soumyajit Mahapatra
@Development Date   : 17/11/2020
@Last Modified By   : Supriyo Seni
@Last Modified Date : 25/06/2021
@Description        : This api checks all the mandatory and required fields of borrowerEnquiryform and create relevant
                      account, contact, relationship and quick quote accorrding to the type of borrower.
@History            : Last modified by Priyanka Maharana 
                      following code standards, & better readability
******************************************************************************************************************/
global without sharing class BorrowerEnquiryFormApi implements clcommon.PortalCustomRemoteAPI1 {
    
    global clcommon.Response invokeAction(String componentStrName, String[] disclosureNames, Map<String, Object> params) {

        // Declaring response variable and savepoints
        clcommon.Response returnRes;
        Savepoint sp = Database.setSavepoint();
        map <String, Object> fields = new map <String, Object>();
        // Initializing the portal variables that are going to be used with blank string
        Boolean borrowerfolk2folkMonthlyNewsLetter = false;
        Boolean borrowerVerifyProperty = false;
        String borrowerMiddleName = '';
        String companyEmail = '';
        String jointEmail = '';
        String borrowerSecondaryTelephone = '';
        // String previousBorrowerName = '';
        String accName = '';
        String brokerCompany = '';
        String borrowerTitle = '';
        String otherTitle = '';
        String borrowerEmail = '';
        String borrowerFirstName = '';
        String borrowerSurname = '';
        String borrowerTelephone = '';
        String borrowercompanyName = '';
        String borrowerNameApplicationIn = '';
        String borrowerRegion = '';
        String borrowerSector = '';
        String borrowingOnBehalf = '';
        String borrowerRole = '';
        String borrowerOtherposition = '';
        String borrowerLoanAmount = '';
        String borrowerLoanTerm = '';
        String loanProductType = '';
        String borrowerEstimatedValueofProperty = '';
        String hearAboutUs = '';
        String hearAboutSpecifyOther = '';
        String specifyAnswerForFriendsFam = '';
        String solicitor = '';
        // String accountant = '';
        // String advisor = '';
        String firmName = '';
        String bankName = '';
        String individualName = '';
        String purposeOfLoan = '';
        String isBroker = '';
        String uniquenessCheck = '';
        String otherPositionRole = '';
        String brokerEmail;
        String brokerName;
        String brokerPhone;
        String quickQuotePortalResponse;
        String quickQuoteResponse;
        String positionRole;
        String primaryEmail;
        Id borrowerAccountRecordTypeId;
        Id otherBorrowertypeId;
        Id productTypeId;
        Id accountId;
        Id contactId;
        Id indvBorrowerTypeId;
        Id jobID;
        // Declaring objects & lists here
        List<Account> newAccount = new List<Account>();
        Account primaryAccount = new Account();
        Account brokerAccount = new Account();
        List<Account> existingBroker = new List<Account>();
        List <Account> accountList = new List<Account>();
        List <Account> accountsToBeInserted = new List<Account>();
        List <Contact> borrowerContactList = new List<Contact>();
        clcommon__Relationship__c primaryRelation = new clcommon__Relationship__c();
        List<genesis__Quick_Quotes__c> quickQuoteIds = new List<genesis__Quick_Quotes__c>();
        List<String> borrowerLegalEntities = new List<String>{Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE, 
                                                                Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE,
                                                                Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE};
        Map<String, Id> fetchedLegalEntities = new Map<String, Id>();
        Map<String, Id> fetchedProductTypes = new Map<String, Id>();
        Map<String, Id> borrowerRecordTypes = new Map<String, Id>();

        List<String> productTypeLists = new List<String>();
        List<String> borrowerRecordTypeLists = new List<String>{Folk2FolkConstantValues.SOBJECT_TYPE_QUICK_QUOTE,
                                                                Folk2FolkConstantValues.SOBJECT_TYPE_ACCOUNT};

        Folk2FolkWrapper.QuickQuoteWrapper enquiryQuoteObj = new Folk2FolkWrapper.QuickQuoteWrapper();
        List<Folk2FolkWrapper.QuickQuoteWrapper> quoteWrapperList = new List<Folk2FolkWrapper.QuickQuoteWrapper>();
        Folk2FolkWrapper.AccountWrapper accWrapperObj = new Folk2FolkWrapper.AccountWrapper();
        List<Folk2FolkWrapper.AccountWrapper> accWrapperObjList = new List<Folk2FolkWrapper.AccountWrapper>();
        Folk2FolkWrapper.ContactWrapper contactWrapperObj = new Folk2FolkWrapper.ContactWrapper();
        List<Folk2FolkWrapper.ContactWrapper> contactWrapperObjList = new List<Folk2FolkWrapper.ContactWrapper>();

        try{

            // Validating all the values coming from portal 
            DataValidatorUtility.doVerifyBorrowerDetails(params);
            // Getting the values from params
            borrowerTitle = String.valueof(params.get(Folk2FolkConstantValues.TITLE));
            otherTitle = String.valueof(params.get(Folk2FolkConstantValues.OTHER_TITLE));
            borrowerEmail = String.valueof (params.get(Folk2FolkConstantValues.EMAIL));
            borrowerFirstName = String.valueof(params.get(Folk2FolkConstantValues.FIRST_NAME));
            // Optional Field
            if(params.containskey(Folk2FolkConstantValues.MIDDLE_NAME )){
                borrowerMiddleName = String.valueof(params.get(Folk2FolkConstantValues.MIDDLE_NAME));
            }

            // This field is only for company type borrower
            if(params.containskey(Folk2FolkConstantValues.COMPANY_EMAIL)){
                companyEmail = String.valueof(params.get(Folk2FolkConstantValues.COMPANY_EMAIL));
            }

            // This field is only for joint type borrower
            if(params.containskey(Folk2FolkConstantValues.JOINT_EMAIL)){
                jointEmail = String.valueof(params.get(Folk2FolkConstantValues.JOINT_EMAIL));
            }
            borrowerSurname = String.valueof(params.get(Folk2FolkConstantValues.SURNAME));
            borrowerTelephone = String.valueof(params.get(Folk2FolkConstantValues.TELEPHONE));
            // Optional Field
            if(params.containskey(Folk2FolkConstantValues.SECONDARY_TELEPHONE)) {
                borrowerSecondaryTelephone = String.valueof(params.get(Folk2FolkConstantValues.SECONDARY_TELEPHONE));
            }
            
            // previous borrower Optional Field
            // if(params.containskey(Folk2FolkConstantValues.PREVIOUS_BORROWER_NAME)) {
            //     previousBorrowerName = String.valueof(params.get(Folk2FolkConstantValues.PREVIOUS_BORROWER_NAME));
            // }
            //if newsletter checkbox is on
            if( params.containsKey(Folk2FolkConstantValues.FOLK2FOLKMONTHLYNEWSLETTER)) {
                borrowerfolk2folkMonthlyNewsLetter = Boolean.valueof(params.get(Folk2FolkConstantValues.FOLK2FOLKMONTHLYNEWSLETTER));
            }
            borrowercompanyName = String.valueof(params.get(Folk2FolkConstantValues.COMPANY_NAME));
            borrowerNameApplicationIn = String.valueof(params.get(Folk2FolkConstantValues.NAME_APPLICATION_IN));
            borrowerRegion = String.valueof(params.get(Folk2FolkConstantValues.REGION));
            borrowerSector = String.valueof(params.get(Folk2FolkConstantValues.SECTOR));
            borrowingOnBehalf = String.valueof(params.get(Folk2FolkConstantValues.BORROWING_ON_BEHALF_OF));
            borrowerRole = String.valueof(params.get(Folk2FolkConstantValues.POSITION_HELD));
            borrowerOtherposition = String.valueof(params.get(Folk2FolkConstantValues.OTHER_POSITION));
            borrowerLoanAmount = String.valueOf(params.get(Folk2FolkConstantValues.LOAN_AMOUNT));
            borrowerLoanTerm = String.valueOf(params.get(Folk2FolkConstantValues.TERM));
            loanProductType = String.valueof(params.get(Folk2FolkConstantValues.PRODUCT_TYPE));
            borrowerVerifyProperty = Boolean.valueof(params.get(Folk2FolkConstantValues.VERIFY_PROPERTY));
            borrowerEstimatedValueofProperty = String.valueof(params.get(Folk2FolkConstantValues.ESTIMATED_VALUE_OF_PROPERTY));
            hearAboutUs = String.valueof(params.get(Folk2FolkConstantValues.HEAR_ABOUT_US));
            hearAboutSpecifyOther = String.valueof(params.get(Folk2FolkConstantValues.HEAR_ABOUT_SPECIFY_OTHER));
            specifyAnswerForFriendsFam = String.valueof(params.get(Folk2FolkConstantValues.HEAR_ABOUT_SPECIFY_FAM));
            solicitor = String.valueof(params.get(Folk2FolkConstantValues.SOLICITOR_NAME));
            firmName = String.valueof(params.get(Folk2FolkConstantValues.FIRM_NAME));
            bankName = String.valueof(params.get(Folk2FolkConstantValues.BANK_NAME));
            individualName = String.valueof(params.get(Folk2FolkConstantValues.INDIVIDUAL_NAME_BORROWER));
            // accountant = String.valueof(params.get(Folk2FolkConstantValues.ACCOUNTANT_NAME));
            // advisor = String.valueof(params.get(Folk2FolkConstantValues.ADVISOR_NAME));
            purposeOfLoan = String.valueof(params.get(Folk2FolkConstantValues.PURPOSE_OF_LOAN));
            isBroker = String.valueOf(params.get(Folk2FolkConstantValues.BROKER_TYPE));
            //Removing company & borrower email as same, validation CLS-177

            if (isBroker.equals(Folk2FolkConstantValues.YES)) {
                brokerEmail = String.valueof(params.get(Folk2FolkConstantValues.BROKER_EMAIL));
                brokerName = String.valueof(params.get(Folk2FolkConstantValues.BROKER_NAME));
                brokerPhone = String.valueof(params.get(Folk2FolkConstantValues.BROKER_TELEPHONE));
                // Optional Field
                if(params.containskey(Folk2FolkConstantValues.BROKER_COMPANY)) {
                    brokerCompany = String.valueof(params.get(Folk2FolkConstantValues.BROKER_COMPANY));
                }
            }
            /***********************************************************************************
            Checking if there is any existing account with same email and quick quote
            status other than 'ENTERED' or 'CONVERTED TO APPLICATION'.
            Method accountUniquenessCheck checks if account exist with borrower email or not. 
            if account exist with a cancelled quick quote then here we are updating the same
            account otherwise if an active quick quote exist for the account then throwing error.
            ************************************************************************************/
            uniquenessCheck = SkuidActionsCtrl.accountUniquenessCheck(borrowerEmail, Folk2FolkConstantValues.PORTAL);
            if(String.isNotBlank(uniquenessCheck)){
                if(uniquenessCheck.equals(Folk2FolkConstantValues.ACCOUNT_EXIST_WITH_CANCELLED_QUICK_QUOTE)) {
                    accountList = [ SELECT Id, 
                                            (SELECT Id 
                                            FROM Contacts)
                                    FROM Account
                                    WHERE clcommon__Email__c =: borrowerEmail ];
                    if(!accountList.isEmpty()) {
                        accountId = accountList.get(0).id;
                        if(accountList.get(0).Contacts != null && accountList.get(0).Contacts.size() == 1) {
                            contactId = accountList.get(0).Contacts.get(0).id;
                        }
                    }
                } else if(uniquenessCheck.equals(Folk2FolkConstantValues.ACCOUNT_EXIST_WITH_ACTIVE_QUICK_QUOTE)) {
                    throw new CustomException(Folk2FolkConstantValues.ACCOUNT_ALREADY_EXISTS);
                }
            }
            // Getting legal entities id from utility class
            fetchedLegalEntities = Folk2FolkQueriesUtility.getLegalEntityId(borrowerLegalEntities);
            borrowerRecordTypes = Folk2FolkQueriesUtility.getRecordTypeId(Folk2FolkConstantValues.BORROWER_RECORD_TYPE, borrowerRecordTypeLists);

            indvBorrowerTypeId = fetchedLegalEntities.get(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE);
            if(!borrowingOnBehalf.equals(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE)){
                otherBorrowertypeId = fetchedLegalEntities.get(borrowingOnBehalf);
            }
            // Getting borrower account record type id from utility class
            borrowerAccountRecordTypeId = borrowerRecordTypes.get(Folk2FolkConstantValues.SOBJECT_TYPE_ACCOUNT);

            // Setting account name on basis of middle name is blank or have some value
            accName = String.isBlank(borrowerMiddleName) 
                            ? (borrowerFirstName + Folk2FolkConstantValues.BLANK_SPACE + borrowerSurname)
                            : (borrowerFirstName + Folk2FolkConstantValues.BLANK_SPACE + borrowerMiddleName + Folk2FolkConstantValues.BLANK_SPACE + borrowerSurname);
            if(borrowingOnBehalf.equals(Folk2FolkConstantValues.INDIVIDUAL_LEGAL_ENITITY_TYPE)) {
                borrowerNameApplicationIn = accName;
            }
            // Creating individual account for borrower
            accWrapperObj.accountId = accountId;
            accWrapperObj.name = accName;
            accWrapperObj.telephone = borrowerTelephone;
            accWrapperObj.secondaryPhone = borrowerSecondaryTelephone;
            accWrapperObj.email = borrowerEmail;
            accWrapperObj.legalEntity = indvBorrowerTypeId;
            accWrapperObj.recordType = borrowerAccountRecordTypeId;
            accWrapperObjList.add(accWrapperObj);

            if(accWrapperObjList.isEmpty()){
                throw new CustomException(Folk2FolkConstantValues.GENERIC_ERROR_MESSAGE);
            }
            newAccount = Folk2FolkMethodsUtility.createIndividualAccount(accWrapperObjList);
            accountsToBeInserted.add(newAccount[0]);

            /**************************************************************************************
            Checking if the legal entity is of company or joint/partnership, if yes then inserting
            one more accountant also a relationship with individual account
            ***************************************************************************************/

            // Checking borrower type in order to create different type of relationship and account
            if(borrowingOnBehalf.equals(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE )
                || borrowingOnBehalf.equals(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE)) {

                    if(borrowingOnBehalf.equals(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE)) {
                        borrowerNameApplicationIn = borrowercompanyName;
                        primaryEmail = companyEmail;
                        positionRole = borrowerRole;
                        otherPositionRole = borrowerOtherposition;
                    } else if(borrowingOnBehalf.equals(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE)) {
                        primaryEmail = jointEmail;
                        positionRole = Folk2FolkConstantValues.JOINT_PARTNER_ROLE;
                    }
                    String primaryAccountUniquenessCheck = SkuidActionsCtrl.accountUniquenessCheck(primaryEmail, Folk2FolkConstantValues.PORTAL);
                    System.debug('chekcing' + primaryAccountUniquenessCheck);
                    if(String.isNotBlank(primaryAccountUniquenessCheck)){
                        if(primaryAccountUniquenessCheck.equals(Folk2FolkConstantValues.ACCOUNT_EXIST_WITH_CANCELLED_QUICK_QUOTE)
                            || primaryAccountUniquenessCheck.equals(Folk2FolkConstantValues.ACCOUNT_DOES_NOT_EXIST)) {
                            //Create primary account only if there is no account or account exists with canceled quick quote
                            primaryAccount = Folk2FolkMethodsUtility.createPrimaryAccount(borrowerNameApplicationIn, 
                                                                                            primaryEmail, 
                                                                                            otherBorrowertypeId, 
                                                                                            borrowerAccountRecordTypeId);
                            
                            accountsToBeInserted.add(primaryAccount);
                        } else if(primaryAccountUniquenessCheck.equals(Folk2FolkConstantValues.ACCOUNT_EXIST_WITH_ACTIVE_QUICK_QUOTE)){
                            throw new CustomException(Folk2FolkConstantValues.ACCOUNT_ALREADY_EXISTS);
                        }
                    }
            }
            // If the user is broker then creating a broker account for that user
            if (isBroker.equals(Folk2FolkConstantValues.YES)) {
                List<String> recordTypeList = new List<String>{Folk2FolkConstantValues.BORROWER_RECORD_TYPE,
                                                                Folk2FolkConstantValues.INVESTOR_RECORD_TYPE,
                                                                Folk2FolkConstantValues.POA_RECORD_TYPE,
                                                                Folk2FolkConstantValues.SOLICITOR_TYPE,
                                                                Folk2FolkConstantValues.ACCOUNTANT_TYPE};
                existingBroker = [ SELECT id
                                    FROM Account
                                    WHERE clcommon__Email__c =: brokerEmail
                                    AND RecordType.Name IN: recordTypeList
                                    LIMIT 1];
                if(!existingBroker.isEmpty()){
                    throw new CustomException(Folk2FolkConstantValues.BORROWER_OR_INVESTOR_CANNOT_BE_BROKER);
                }
                brokerAccount = Folk2FolkMethodsUtility.createBrokerAccount(brokerName, 
                                                                            brokerEmail, 
                                                                            brokerPhone, 
                                                                            brokerCompany);
                accountsToBeInserted.add(brokerAccount);
            }
            UPSERT accountsToBeInserted;

            // after all accounts have been inserted, perform linking them via clcommon__Relationship__c
            if(borrowingOnBehalf.equals(Folk2FolkConstantValues.COMPANY_LEGAL_ENTITY_TYPE )
                || borrowingOnBehalf.equals(Folk2FolkConstantValues.JOINT_OR_PARTNERSHIP_LEGAL_ENTITY_TYPE)) {

                    primaryRelation = Folk2FolkMethodsUtility.createRelationship(newAccount[0].Id, 
                                                                                    primaryAccount.id, 
                                                                                    positionRole, 
                                                                                    otherPositionRole, 
                                                                                    null);
                    INSERT primaryRelation;
            }
            // Inserting individual contact
            contactWrapperObj.contactId = contactId;
            contactWrapperObj.title = borrowerTitle;
            contactWrapperObj.otherTitle = otherTitle;
            contactWrapperObj.firstName = borrowerFirstName;
            contactWrapperObj.middleName = borrowerMiddleName;
            contactWrapperObj.surname = borrowerSurname;
            contactWrapperObj.telephone = borrowerTelephone;
            contactWrapperObj.secondaryPhone = borrowerSecondaryTelephone;
            contactWrapperObj.email = borrowerEmail;
            contactWrapperObj.legalEntity = indvBorrowerTypeId;
            contactWrapperObj.accountId = newAccount[0].Id;
            contactWrapperObjList.add(contactWrapperObj);

            if(contactWrapperObjList.isEmpty()){
                throw new CustomException(Folk2FolkConstantValues.GENERIC_ERROR_MESSAGE);
            }

            borrowerContactList = Folk2FolkMethodsUtility.createIndividualContact(contactWrapperObjList);
            UPSERT borrowerContactList;
            
            // Querying product type of the loan
            productTypeLists.add(loanProductType);
            fetchedProductTypes = Folk2FolkQueriesUtility.getProductTypeId(productTypeLists);

            productTypeId = fetchedProductTypes.get(loanProductType);
            // Inserting quick quote
            enquiryQuoteObj.individualAccId = newAccount[0].Id;
            if (primaryAccount != null) {
                enquiryQuoteObj.relatedAccId  = primaryAccount.id;
            }
            enquiryQuoteObj.contactId = borrowerContactList[0].id;
            enquiryQuoteObj.loanAmount = Decimal.valueof ( borrowerLoanAmount );
            enquiryQuoteObj.term = borrowerLoanTerm;
            enquiryQuoteObj.productId = productTypeId;
            enquiryQuoteObj.haveLandForSecurity = borrowerVerifyProperty;
            enquiryQuoteObj.estimatedValueOfProperty = Decimal.valueof ( borrowerEstimatedValueofProperty );
            enquiryQuoteObj.hearAboutUs = hearAboutUs;
            enquiryQuoteObj.firmName=firmName;
            enquiryQuoteObj.bankName=bankName;
            enquiryQuoteObj.individualName=individualName;

            enquiryQuoteObj.borrowingOnBehalf = borrowingOnBehalf;
            enquiryQuoteObj.hearAboutSpecifyOther = hearAboutSpecifyOther;
            enquiryQuoteObj.specifyAnswerForFriendsFam = specifyAnswerForFriendsFam;
            enquiryQuoteObj.referenceName = hearAboutUs.equals(Folk2FolkConstantValues.SOLICITOR) ? solicitor
                                            :hearAboutUs.equals(Folk2FolkConstantValues.BANK) ? individualName
                                            : hearAboutUs.equals(Folk2FolkConstantValues.HEAR_ABOUT_US_ACCOUNTANT) ? individualName
                                            : hearAboutUs.equals(Folk2FolkConstantValues.FINANCIAL_ADVISOR) ? individualName
                                            // : hearAboutUs.equals(Folk2FolkConstantValues.HEAR_ABOUT_US_PREVIOUS_BORROWER) ? previousBorrowerName
                                            : '';
            enquiryQuoteObj.sector = borrowerSector;
            enquiryQuoteObj.region = borrowerRegion;
            enquiryQuoteObj.purposeOfLoan = purposeOfLoan;
            enquiryQuoteObj.signedUpForNewsletter = borrowerfolk2folkMonthlyNewsLetter;
            enquiryQuoteObj.nameApplicationIn = borrowerNameApplicationIn;
            enquiryQuoteObj.recordTypeId = borrowerRecordTypes.get(Folk2FolkConstantValues.SOBJECT_TYPE_QUICK_QUOTE);
            enquiryQuoteObj.isBrokerPresent = (isBroker.equals(Folk2FolkConstantValues.YES)) 
                                                ? true 
                                                : false;

            if (isBroker.equals(Folk2FolkConstantValues.YES)) {
                enquiryQuoteObj.brokerAccountId = brokerAccount.id;
            }
            quoteWrapperList.add(enquiryQuoteObj);
            //quick quote is inserted here
            if(!quoteWrapperList.isEmpty()){
                quickQuoteIds = Folk2FolkMethodsUtility.createQuote(quoteWrapperList);
                INSERT quickQuoteIds;
            }
            /**************************************************************************************
            Querying each and every data of quick quote for sending in 'convertQuickQuoteToApp'
            function of QuickQuoteConversionUtil which converts a quick quote into genesis
            application and return a response based on LTV of that quick quote.
            The polling method is called to check if the processed_text of quick quote is updated
            **************************************************************************************/
            if(!quickQuoteIds.isEmpty()){
                // Sending response to the portal
                fields.put(Folk2FolkConstantValues.QUICK_QUOTE_ID, quickQuoteIds[0].Quick_Quote_UUID__c);
                fields.put(Folk2FolkConstantValues.QUICK_QUOTE_SFID, quickQuoteIds[0].Id);
            }
            returnRes = DataUtil.getSuccessResponse(fields);
        } catch(Exception e) {
            Database.rollback(sp);
            returnRes = DataUtil.handleException(e, BorrowerEnquiryFormApi.class.getname());
        }
        return returnRes;
    }

}