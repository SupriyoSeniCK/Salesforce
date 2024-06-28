/**
 * @description       : Test class for QuoteToAppWebServiceAPI
 * @author            : Supriyo Seni
 * @group             : Test Class
 * @last modified on  : 10-10-2023
 * @last modified by  : Supriyo Seni
**/
@isTest
private class QuoteToAppWebServiceAPITest{

    @TestSetup
    static void makeData(){
        // Insert system configurations
        System_Configuration__c systemConfig = FlowfiTestHelper.getSystemConfigSet();
		systemConfig.PPSR_Registration_Fee__c = 6.00;
        systemConfig.PPSR_Search_Fee__c = 2.00;
        systemConfig.Save_Equifax_Softpull_Request__c = true;
        systemConfig.Save_Equifax_Softpull_Response__c = true;
        systemConfig.Default_Days_Convention__c = '365/365';
        systemConfig.Default_Interest_Calculation_Method__c = 'Declining Balance';
        systemConfig.Loan_Admin_Fee__c = 13;
        systemConfig.Motor_Discounted_Rate__c = 1;
        systemConfig.ByPass_Risk_API__c = false;
        systemConfig.Default_Quick_Quote_Payment_Frequency__c = 'WEEKLY';
        systemConfig.Maximum_Loan_Amount__c = 130000000;
        systemConfig.Minimum_Loan_Amount__c = 100;
        systemConfig.Motor_Maximum_Loan_Amount__c = 500000;

		insert systemConfig;

        // Create Account
        Account testAccount = FlowfiTestHelper.accountCreator();
        testAccount.Email__c = 'Aggregator1234@mailnator.com';
        insert testAccount;

        // Create borrower Account
        Account quoteAccount = FlowfiTestHelper.accountCreator();
        testAccount.Email__c = 'quote1234@mailnator.com';
        testAccount.Name = 'Tester Roy';
        testAccount.Last_Name__c = 'Roy';
        insert quoteAccount;

        // Create contact
        Contact testContact = FlowfiTestHelper.contactCreator(testAccount.Id);
        testContact.Broker_ID__c = 'B-12354';
        testContact.brk_AccreditationStatus__c = 'Active';
        testContact.brk_BrokerClassification__c = 'Mortgage Broker';
        testContact.brk_ProductAccreditation__c = 'Both Personal and Motor Loans';
        insert testContact;

        //Create Broker User
        User brokerUser = FlowfiTestHelper.userCreatorBroker(testAccount.id,testContact.id);
        insert brokerUser;

        // Create CL product
        clcommon__CL_Product__c clProduct = FlowfiTestHelper.createCLProduct(AggregatorConstants.MOTOR_LOAN_FIXED_RATE);
        insert clProduct;

        List<genesis__Credit_Rating_Matrix__c> matrixList = FlowfiTestHelper.createPricing();
        matrixList[0].Loan_Product__c = AggregatorConstants.MOTOR_LOAN_FIXED_RATE;
        matrixList[0].Risk_Grade_Segment__c = 'LFS_STRANGER';
        matrixList[0].Enabled__c = true;
        matrixList[0].Name = '11600';
        matrixList[0].Broker_Max_Loan_Amount__c = 10000000;
        insert matrixList;

        genesis__Quick_Quotes__c quickQuote = FlowfiTestHelper.createQuickQuotes(quoteAccount.id);
        quickQuote.genesis__Application__c = null;
        quickQuote.genesis__Status__c = AggregatorConstants.ENTERED;
        quickQuote.Broker_Contact__c = testContact.id;
        quickQuote.genesis__Last_Name__c = 'Test';
        quickQuote.Email__c = 'quote1234@mailnator.com';
        quickQuote.Submitted_Via_Aggregator_API__c = true;
        quickQuote.Term__c = '5';
        quickQuote.Credit_Rating_Matrix__c = matrixList[0].id;
        quickQuote.genesis__Financed_Amount__c = 50000;
        quickQuote.genesis__CL_Product__c = clProduct.id;
        quickQuote.genesis__Country__c = 'Australia';
        quickQuote.Broker_Fee_Amount__c = 100;
        quickQuote.genesis__Payment_Frequency__c = 'Monthly';
        quickQuote.Driver_Licence_State__c = 'NSW';
        quickQuote.License_Card_Number__c = '7818218167';
        quickQuote.Driver_Licence__c = 'DL26272';
        quickQuote.Street_Number__c = '44';
        update quickQuote;
    }

    @isTest
    static void testQuoteToApplicationConversion() {
        List<Profile> profileList  = [SELECT Id FROM Profile WHERE Name =: AggregatorConstants.AGGREGATOR_PROFILE_NAME LIMIT 1];
        List<PermissionSet> permissionSetsList = [SELECT Id FROM PermissionSet WHERE Name =: AggregatorConstants.AGGREGATOR_PERMISSION_SET_NAME LIMIT 1];
        User runAsUser = new User(LastName = 'API Only User',
                            FirstName='Aggregator',
                            Alias = 'jliv',
                            Email = 'example@asdf.com',
                            Username = 'exaample@asdf.com',
                            ProfileId = profileList[0].id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                            );
        insert runAsUser;
        insert new PermissionSetAssignment(AssigneeId = runAsUser.id, PermissionSetId = permissionSetsList[0].Id);
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/quote/application/convert';
        request.httpMethod = 'POST';
        List<genesis__Quick_Quotes__c> quoteList = [SELECT id, name FROM genesis__Quick_Quotes__c LIMIT 1];
        String testApiPayload = '{ "quoteNumber": "{quoteNumber}", "lastName":"Test", "emailAddress" : "quote1234@mailnator.com", "brokerId": "B-12354" }';
        testApiPayload = testApiPayload.replace('{quoteNumber}', quoteList[0].name);
        // Set the request body as per the test payload
        request.requestBody = Blob.valueOf(testApiPayload);
        RestContext.request = request;
        String apiResponse;
        Test.startTest();
        System.runAs(runAsUser){
            apiResponse = QuoteToAppWebServiceAPI.convertQuoteToApplication();
        }
        Test.stopTest();
        System.assertEquals(true, apiResponse.contains('ERROR'),'No Error Message Found');
    }

        /**
    * @description | Test the Qupte to Application Conversion scenarios and its Exceptions
    * @author Supriyo Seni | 10-10-2023 
    **/
    // @isTest
    // static void testQuoteToApplicationConversion() {
    //     List<Profile> profileList  = [SELECT Id 
    //                                     FROM Profile 
    //                                     WHERE Name =: AggregatorConstants.AGGREGATOR_PROFILE_NAME 
    //                                     LIMIT 1];
    //     List<PermissionSet> permissionSetsList = [SELECT Id 
    //                                                 FROM PermissionSet 
    //                                                 WHERE Name =: AggregatorConstants.AGGREGATOR_PERMISSION_SET_NAME 
    //                                                 LIMIT 1];
    //     User runAsUser = new User(LastName = 'API Only User',
    //                         FirstName='Aggregator',
    //                         Alias = 'jliv',
    //                         Email = 'example@asdf.com',
    //                         Username = 'exaample@asdf.com',
    //                         ProfileId = profileList[0].id,
    //                         TimeZoneSidKey = 'GMT',
    //                         LanguageLocaleKey = 'en_US',
    //                         EmailEncodingKey = 'UTF-8',
    //                         LocaleSidKey = 'en_US'
    //                         );
    //     insert runAsUser;
    //     insert new PermissionSetAssignment(AssigneeId = runAsUser.id, PermissionSetId = permissionSetsList[0].Id);
    //     RestRequest request = new RestRequest();
    //     request.requestURI = '/services/apexrest/quote/create';
    //     request.httpMethod = 'POST';
    //     // Set the request body as per your test data
    //     String testApiPayload = '{ "quoteNumber": "{quoteNumber}", "lastName":"Jr", "emailAddress" : "aggreeegtorTest@mailnator.com", "brokerId": "B-12354" }';
    //     request.requestBody = Blob.valueOf('{ "personalDetails": { "firstName": "Robert", "lastName": "Jr", "gender": "Male", "dateOfBirthDetails": { "birthDate": 3, "birthMonth": 5, "birthYear": 1994 } }, "contactDetails": { "emailAddress": "aggreeegtorTest@mailnator.com", "mobileNumber": "12345678" }, "loanDetails": { "term": "5", "loanAmount": 30000, "loanPurpose": "Private Sale" }, "driverLicenceDetails": { "isDriverLicenceAvailable" : true, "stateOfIssue": "ACT", "driverLicenceNumber": "DL1234", "licenceCardNumber": "1234556789" }, "addressDetails": { "residentialStatus": "Renting", "streetNumber": "32", "streetName": "Warrangi", "streetType": "Street", "city": "Turrahmurrah", "state": "VIC", "postalCode": "1234", "propertyName": "", "isMailingAddressSame": false, "postalAddressDetails": { "postalStreetNumber": "34", "postalStreetName": "ABC", "postalStreetType": "Road", "postalCity": "SGH", "postalState": "NSW", "postalCode": "3492" }, "poGpoAddressDetails": { "poBoxNumber": "", "postalBoxState": "", "postalBoxCity": "", "poBoxPostalCode": "" } }, "brokerDetails": { "brokerFeeAmount": 200, "brokerId": "B-12354" }, "quoteConsentDetails": { "quoteConsent": true } }');
    //     RestContext.request = request;
    //     String quoteApiResponse;
    //     String apiResponse;
    //         try{
    //             System.runAs(runAsUser){
    //                 Test.startTest();
    //                 Test.setMock(HttpCalloutMock.class, new QuoteToAppWebServiceAPITest());
    //                 quoteApiResponse = QuoteWebServiceAPI.createQuickQuote();
    //                 List<genesis__Quick_Quotes__c> quoteList = [SELECT Id, Name FROM genesis__Quick_Quotes__c LIMIT 1];
    //                 testApiPayload = testApiPayload.replace('{quoteNumber}', quoteList[0].name);
    //                 request.requestURI = '/services/apexrest/quote/application/convert';
    //                 request.requestBody = Blob.valueOf(testApiPayload);
    //                 RestContext.request = request;
    //                 apiResponse = QuoteToAppWebServiceAPI.convertQuoteToApplication();
    //                 Test.stopTest();
    //             }
    //         }catch(Exception ex){
    //             System.debug('Exception = '+ex.getMessage());
    //             System.assertEquals(null, apiResponse,'No Exception Occured');
    //         }
    //     System.assertEquals(true, apiResponse.contains('error'),'No Error Message Found');
    // }
}