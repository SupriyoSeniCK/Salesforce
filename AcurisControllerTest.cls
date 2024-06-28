/*
 * Company : Cloudkaptan Consultancy Services Pvt. Ltd.
 * Date : 26/08/2021
 * Author : Saurabh Anand
 * Description : This class is the test class for AcurisController
 * History :   
*/
@isTest(SeeAllData=false)
global class AcurisControllerTest {
    @TestSetup
    static void testSetup() {

        //account record types
        Id borrowerRecordType = Schema.SObjectType.account.getRecordTypeInfosByName().get('Borrower').getRecordTypeId();

        //legal entity
        List<clcommon__Legal_Entity__c> legalEntityList = new List<clcommon__Legal_Entity__c>();
        clcommon__Legal_Entity__c individualLegalEntity = F2FTestHelper.getLegalEntity('Individual');
        legalEntityList.add(individualLegalEntity);
        clcommon__Legal_Entity__c ifisaLegalEntity = F2FTestHelper.getLegalEntity('IFISA');
        legalEntityList.add(ifisaLegalEntity);
        clcommon__Legal_Entity__c companyLegalEntity = F2FTestHelper.getLegalEntity('Company');
        legalEntityList.add(companyLegalEntity);

        if(!legalEntityList.isEmpty()) {
            insert legalEntityList;
        }

        List<clcommon__Legal_Entity__c> getLegalEntity = [SELECT id,
                                                                Name
                                                            FROM clcommon__Legal_Entity__c
                                                            WHERE Name != null];

        System.assertEquals(true, getLegalEntity.size() == 3, 'Legal entity list is not inserted');

        List<clcommon__Legal_Entity__c> getIndividualLegalEntity = [SELECT id,
                                                                        Name
                                                                    FROM clcommon__Legal_Entity__c
                                                                    WHERE Name = 'Individual'];

        System.assertEquals(true, getIndividualLegalEntity.size() == 1, 'Individual Legal entity is not found');

        List<clcommon__Legal_Entity__c> getIFISALegalEntity = [SELECT id,
                                                                    Name
                                                                FROM clcommon__Legal_Entity__c
                                                                WHERE Name = 'IFISA'];

        System.assertEquals(true, getIFISALegalEntity.size() == 1, 'IFISA Legal entity is not found');

        List<clcommon__Legal_Entity__c> getCompanyLegalEntity = [SELECT id,
                                                                        Name
                                                                    FROM clcommon__Legal_Entity__c
                                                                    WHERE Name = 'Company'];

        System.assertEquals(true, getIFISALegalEntity.size() == 1, 'Company Legal entity is not found');

        // Creating accounts
        List<Account> accountList = new List<Account>();

        Account borrowerAccount=F2FTestHelper.getAccount();
        borrowerAccount.Name = 'Borrower 1';
        borrowerAccount.clcommon__Email__c = 'borrower@mailinator.com';        
        borrowerAccount.recordTypeId = borrowerRecordType;
        borrowerAccount.CLS_Account_Id__c = '1234';
        borrowerAccount.clcommon__Legal_Entity_Type__c = getIndividualLegalEntity[0].Id;
        accountList.add(borrowerAccount);

        Account ifisaAccount=F2FTestHelper.getAccount();
        ifisaAccount.Name = 'IFISA Borrower 1';
        ifisaAccount.clcommon__Email__c = 'borrower@mailinator.com';        
        ifisaAccount.recordTypeId = borrowerRecordType;
        ifisaAccount.clcommon__Legal_Entity_Type__c = getIFISALegalEntity[0].Id;
        accountList.add(ifisaAccount);

        Account companyAccount=F2FTestHelper.getAccount();
        companyAccount.Name = 'Company Borrower 1';
        companyAccount.clcommon__Email__c = 'companyborrower@mailinator.com';        
        companyAccount.recordTypeId = borrowerRecordType;
        companyAccount.CLS_Account_Id__c = '1234';
        companyAccount.clcommon__Legal_Entity_Type__c = getCompanyLegalEntity[0].Id;
        accountList.add(companyAccount);

        if(!accountList.isEmpty()){
            insert accountList;
        }

        // query for assertion
        List<Account> queryAccountList = [SELECT id,
                                            CLS_Account_Id__c
                                            FROM Account
                                            WHERE recordTypeId!=null];

        System.assertEquals(true, queryAccountList.size() == 3, 'Account list is not inserted');

        List<Account> borrowerAccount1 = [SELECT id,
                                            CLS_Account_Id__c
                                            FROM Account
                                            WHERE Name = 'Borrower 1'];

        System.assertEquals(true, borrowerAccount1.size()==1, 'Borrower Account not found');

        List<Account> ifisaAccount1 = [SELECT id,
                                        CLS_Account_Id__c
                                        FROM Account
                                        WHERE Name = 'IFISA Borrower 1'];

        System.assertEquals(true, ifisaAccount1.size()==1, 'IFISA Borrower Account not found');

        List<Account> companyAccount1 = [SELECT id,
                                            CLS_Account_Id__c
                                            FROM Account
                                            WHERE Name = 'Company Borrower 1'];

        System.assertEquals(true, companyAccount1.size()==1, 'Company Borrower Account not found');

        F2FTestHelper.createRelationship(borrowerAccount1[0].Id, ifisaAccount1[0].Id, 'Individual');

        List<clcommon__Relationship__c> relationship = [SELECT Id,
                                                            clcommon__Entity__c
                                                        FROM clcommon__Relationship__c
                                                        WHERE clcommon__Entity__c =: borrowerAccount1[0].Id
                                                        AND clcommon__Related_Entity__c =: ifisaAccount1[0].Id];

        System.assertEquals(true, relationship.size() == 1, 'relationship not found');

        Contact contact = F2FTestHelper.getContact(borrowerAccount1[0].Id);
        insert contact;

        List<Contact> queryContactList = [SELECT id
                                            FROM Contact
                                            WHERE AccountId = :borrowerAccount1[0].Id];

        System.assertEquals(true, queryContactList.size() == 1, 'Contact not inserted');

        List<clcommon__Address__c> addressList = new List<clcommon__Address__c>();
        clcommon__Address__c address = F2FTestHelper.createAddress(borrowerAccount1[0]);
        addressList.add(address);

        clcommon__Address__c ifisaaddress = F2FTestHelper.createAddress(ifisaAccount1[0]);
        addressList.add(ifisaaddress);

        clcommon__Address__c companyAddress = F2FTestHelper.createAddress(companyAccount1[0]);
        addressList.add(companyAddress);

        if(!addressList.isEmpty()){
            insert addressList;
        }

        // query for assertion
        List<clcommon__Address__c> queryAddress = [SELECT id,
                                                        Name
                                                    FROM clcommon__Address__c
                                                    WHERE clcommon__Account__c != null];

        System.assertEquals(true, queryAddress.size() == 3, 'Address List not inserted');

        List<clcommon__Bank_Account__c> bankAccountList = new List<clcommon__Bank_Account__c>();
        clcommon__Bank_Account__c bankAccount = F2FTestHelper.getCommonBankAccount(borrowerAccount1[0]);
        bankAccountList.add(bankAccount);

        clcommon__Bank_Account__c ifisabankAccount = F2FTestHelper.getCommonBankAccount(ifisaAccount1[0]);
        bankAccountList.add(ifisabankAccount);

        if(!bankAccountList.isEmpty()) {
            insert bankAccountList;
        }

        List<clcommon__Bank_Account__c> queryBankAccount = [SELECT id,
                                                                Name
                                                            FROM clcommon__Bank_Account__c
                                                            WHERE clcommon__Account__c != null];

        System.assertEquals(true, queryBankAccount.size() == 2, 'Bank Account List not inserted');

        List<genesis__Applications__c> appList = new List<genesis__Applications__c>();

        genesis__Applications__c application = F2FTestHelper.getApplication(borrowerAccount1[0].Id);
        appList.add(application);

        genesis__Applications__c companyApplication = F2FTestHelper.getApplication(companyAccount1[0].Id);
        appList.add(companyApplication);

        genesis__Applications__c ifisaapplication = F2FTestHelper.getApplication(ifisaAccount1[0].Id);
        appList.add(ifisaapplication);

        if(!appList.isEmpty()){
            insert appList;
        }

        List<genesis__Applications__c> queryApplication = [SELECT id,
                                                                Name
                                                            FROM genesis__Applications__c
                                                            WHERE genesis__Account__c != null];

        System.assertEquals(true, queryApplication.size() == 3, 'Application List not inserted');

        List<clcommon__Party_Type__c> partyTypeList = new List<clcommon__Party_Type__c>();
        clcommon__Party_Type__c partyType = F2FTestHelper.getPartyType('BORROWER');
        partyTypeList.add(partyType);
        clcommon__Party_Type__c directorPartyType = F2FTestHelper.getPartyType('DIRECTOR');
        partyTypeList.add(directorPartyType);

        if(!partyTypeList.isEmpty()){
            insert partyTypeList;
        }

        List<clcommon__Party_Type__c> queryPartyTypeList = [SELECT id,
                                                                Name
                                                            FROM clcommon__Party_Type__c
                                                            WHERE Name != null];

        System.assertEquals(true, queryPartyTypeList.size() == 2, 'Party type not inserted');

        List<clcommon__Party_Type__c> getBorrowerPartyTypeList = [SELECT id,
                                                                        Name
                                                                    FROM clcommon__Party_Type__c
                                                                    WHERE Name = 'BORROWER'];

        System.assertEquals(true, getBorrowerPartyTypeList.size() == 1, 'BORROWER Party type not inserted');

        List<clcommon__Party_Type__c> getDirectorPartyTypeList = [SELECT id,
                                                                        Name
                                                                    FROM clcommon__Party_Type__c
                                                                    WHERE Name = 'DIRECTOR'];

        System.assertEquals(true, getDirectorPartyTypeList.size() == 1, 'DIRECTOR Party type not inserted');

        List<genesis__Applications__c> getIndividualApplication = [SELECT id,
                                                                        Name
                                                                    FROM genesis__Applications__c
                                                                    WHERE genesis__Account__c = :borrowerAccount1[0].Id];

        System.assertEquals(true, getIndividualApplication.size() == 1, 'Individual Application not found');

        List<genesis__Applications__c> getCompanyApplication = [SELECT id,
                                                                        Name
                                                                    FROM genesis__Applications__c
                                                                    WHERE genesis__Account__c = :companyAccount1[0].Id];

        System.assertEquals(true, getCompanyApplication.size() == 1, 'Company Application not found');

        List<clcommon__Party__c> partyList = new List<clcommon__Party__c>();

        clcommon__Party__c party = F2FTestHelper.createParty(borrowerAccount1[0], getIndividualApplication[0], getBorrowerPartyTypeList[0]);
        partyList.add(party);

        clcommon__Party__c party2 = F2FTestHelper.createParty(companyAccount1[0], getCompanyApplication[0], getBorrowerPartyTypeList[0]);
        partyList.add(party2);

        clcommon__Party__c party3 = F2FTestHelper.createParty(borrowerAccount1[0], getCompanyApplication[0], getDirectorPartyTypeList[0]);
        partyList.add(party3);

        if(!partyList.isEmpty()){
            insert partyList;
        }

        // query for assertion
        List<clcommon__Party__c> queryPartyList = [SELECT id
                                                    FROM clcommon__Party__c
                                                    WHERE clcommon__Account__c != null];

        System.assertEquals(true, queryPartyList.size() == 3, 'Party list is not inserted');

        intframework__Integration_Family__c family = F2FTestHelper.createIntegrationFamily('Acuris');
        insert family;

        List<intframework__Integration_Family__c> integrationFamily = [SELECT id,
                                                                            Name
                                                                        FROM intframework__Integration_Family__c
                                                                        WHERE Name = 'Acuris'];

        System.assertEquals(true, integrationFamily.size() == 1, 'family not inserted');

        List<intframework__Integration_API_Type__c> apiTypeList = new List<intframework__Integration_API_Type__c>();

        intframework__Integration_API_Type__c postBusinessApiType = F2FTestHelper.createAPIType(integrationFamily[0].Id, 'Acuris Post Business API Type');
        apiTypeList.add(postBusinessApiType);

        intframework__Integration_API_Type__c postPersonApiType = F2FTestHelper.createAPIType(integrationFamily[0].Id, 'Acuris Post Person API Type');
        apiTypeList.add(postPersonApiType);

        intframework__Integration_API_Type__c putBusinessApiType = F2FTestHelper.createAPIType(integrationFamily[0].Id, 'Acuris Put Business API Type');
        apiTypeList.add(putBusinessApiType);

        intframework__Integration_API_Type__c putPersonApiType = F2FTestHelper.createAPIType(integrationFamily[0].Id, 'Acuris Put Person API Type');
        apiTypeList.add(putPersonApiType);

        intframework__Integration_API_Type__c removeBusinessApiType = F2FTestHelper.createAPIType(integrationFamily[0].Id, 'Acuris Remove Business API Type');
        apiTypeList.add(removeBusinessApiType);

        intframework__Integration_API_Type__c removePersonApiType = F2FTestHelper.createAPIType(integrationFamily[0].Id, 'Acuris Remove Person API Type');
        apiTypeList.add(removePersonApiType);

        if(!apiTypeList.isEmpty()) {
            insert apiTypeList;
        }

        // query for assertion
        List<intframework__Integration_API_Type__c> queryApiTypeList = [SELECT id
                                                                        FROM intframework__Integration_API_Type__c
                                                                        WHERE intframework__Integration_Family__c = :integrationFamily[0].Id];

        System.assertEquals(true, queryApiTypeList.size() == 6, 'API Type list is not inserted');

        List<intframework__Integration_API_Type__c> getPostBusinessApiType = [SELECT id,
                                                                                    Name
                                                                                FROM intframework__Integration_API_Type__c
                                                                                WHERE intframework__Integration_Family__c = :integrationFamily[0].Id
                                                                                AND Name = 'Acuris Post Business API Type'];

        System.assertEquals(true, getPostBusinessApiType.size() == 1, 'Acuris Post Business API Type not inserted');

        List<intframework__Integration_API_Type__c> getPostPersonApiType = [SELECT id,
                                                                                Name
                                                                            FROM intframework__Integration_API_Type__c
                                                                            WHERE intframework__Integration_Family__c = :integrationFamily[0].Id
                                                                            AND Name = 'Acuris Post Person API Type'];

        System.assertEquals(true, getPostPersonApiType.size() == 1, 'Acuris Post Business API Type not inserted');

        List<intframework__Integration_API_Type__c> getPutBusinessApiType = [SELECT id,
                                                                                    Name
                                                                                FROM intframework__Integration_API_Type__c
                                                                                WHERE intframework__Integration_Family__c = :integrationFamily[0].Id
                                                                                AND Name = 'Acuris Put Business API Type'];

        System.assertEquals(true, getPutBusinessApiType.size() == 1, 'Acuris Put Business API Type not inserted');

        List<intframework__Integration_API_Type__c> getPutPersonApiType = [SELECT id,
                                                                                Name
                                                                            FROM intframework__Integration_API_Type__c
                                                                            WHERE intframework__Integration_Family__c = :integrationFamily[0].Id
                                                                            AND Name = 'Acuris Put Person API Type'];

        System.assertEquals(true, getPutPersonApiType.size() == 1, 'Acuris Put Person API Type not inserted');

        List<intframework__Integration_API_Type__c> getRemoveBusinessApiType = [SELECT id,
                                                                                    Name
                                                                                FROM intframework__Integration_API_Type__c
                                                                                WHERE intframework__Integration_Family__c = :integrationFamily[0].Id
                                                                                AND Name = 'Acuris Remove Business API Type'];

        System.assertEquals(true, getRemoveBusinessApiType.size() == 1, 'Acuris Remove Business API Type not inserted');

        List<intframework__Integration_API_Type__c> getRemovePersonApiType = [SELECT id,
                                                                                    Name
                                                                                FROM intframework__Integration_API_Type__c
                                                                                WHERE intframework__Integration_Family__c = :integrationFamily[0].Id
                                                                                AND Name = 'Acuris Remove Person API Type'];

        System.assertEquals(true, getRemovePersonApiType.size() == 1, 'Acuris Remove Person API Type not inserted');

        intframework__Integration_Provider__c provider = F2FTestHelper.createProvider(integrationFamily[0].Id, 'Acuris');
        insert provider;

        List<intframework__Integration_Provider__c> queryProvider = [SELECT id,
                                                                            Name
                                                                        FROM intframework__Integration_Provider__c
                                                                        WHERE intframework__Provider_Name__c = 'Acuris'];

        System.assertEquals(true, queryProvider.size() == 1, 'Provider not inserted');

        intframework__Integration_Configuration__c configuration = F2FTestHelper.createConfiguration(queryProvider[0].Id, 'Acuris');
        insert configuration;

        List<intframework__Integration_Configuration__c> queryConfiguration = [SELECT id,
                                                                                    Name
                                                                                FROM intframework__Integration_Configuration__c
                                                                                WHERE Name = 'Acuris'];

        System.assertEquals(true, queryConfiguration.size() == 1, 'Configuration not inserted');

        List<intframework__Integration_API_Configuration__c> intApiConfigList = new List<intframework__Integration_API_Configuration__c>();

        intframework__Integration_API_Configuration__c postBusinessApiConfig = F2FTestHelper.createAPIConfig('Acuris Post Business');
        postBusinessApiConfig.intframework__Adapter_Class_Name__c = 'AcurisPostBusinessAdapter';
        postBusinessApiConfig.intframework__Integration_Family__c = integrationFamily[0].Id;
        postBusinessApiConfig.intframework__Integration_API_Type__c = getPostBusinessApiType[0].Id;
        postBusinessApiConfig.intframework__Integration_Provider__c = queryProvider[0].Id;
        postBusinessApiConfig.intframework__Integration_Configuration__c = queryConfiguration[0].Id;
        postBusinessApiConfig.intframework__Execution_Priority__c = 1;
        postBusinessApiConfig.intframework__API_Named_Credential__c = 'Acuris';
        postBusinessApiConfig.intframework__API_Endpoint__c = 'monitorApi/v1_0/api/businesses';
        postBusinessApiConfig.intframework__HTTP_Content_Type__c = 'application/json';
        postBusinessApiConfig.intframework__HTTP_Method__c = 'POST';
        postBusinessApiConfig.intframework__Request_Mapping__c = '{"thirdPartySystem":{"name":"Acuris","filters":[{"objectAPI":"Account","objectAlias":"accountQuery","fields":[{"externalField":"name","fieldAPI":"Name"},{"externalField":"uniqueId","fieldAPI":"CLS_Account_Id__c"}],"whereClause":"Id = :accountId"},{"objectAPI":"clcommon__Address__c","objectAlias":"addressQuery","fields":[{"externalField":"houseNumber","fieldAPI":"House_no_name__c"},{"externalField":"addressLine1","fieldAPI":"clcommon__Street_Address__c"},{"externalField":"addressLine2","fieldAPI":"clcommon__Address_Line_2__c"},{"externalField":"addressLine3","fieldAPI":"Address_Line_3__c"},{"externalField":"city","fieldAPI":"clcommon__City__c"},{"externalField":"county","fieldAPI":"clcommon__County__c"},{"externalField":"zip","fieldAPI":"clcommon__Zip_Code__c"},{"externalField":"accountId","fieldAPI":"clcommon__Account__c"}],"whereClause":"clcommon__Account__c = :accountId"}],"staticParameters":[],"dynamicDataParameters":[{"externalField":"sourceName"}]}}';
        postBusinessApiConfig.intframework__Response_Mapping__c = '{"StorageConfiguration":{"StoreInDB":"False","PublishAsJSON":"False"},"DMLOperations":[]}';
        postBusinessApiConfig.intframework__Request_Timeout__c = 120000;
        postBusinessApiConfig.intframework__Additional_Header_Parameters__c = '{"apiKey":"67005c9c-4d6a-4d64-972b-4c84232fae04","Content-Type":"application/json; charset=utf-8","Host":"api1.uat.c6-intelligence.com"}';
        intApiConfigList.add(postBusinessApiConfig);

        intframework__Integration_API_Configuration__c postPersonApiConfig = F2FTestHelper.createAPIConfig('Acuris Post Person');
        postPersonApiConfig.intframework__Adapter_Class_Name__c = 'AcurisPostPersonAdapter';
        postPersonApiConfig.intframework__Integration_Family__c = integrationFamily[0].Id;
        postPersonApiConfig.intframework__Integration_API_Type__c = getPostPersonApiType[0].Id;
        postPersonApiConfig.intframework__Integration_Provider__c = queryProvider[0].Id;
        postPersonApiConfig.intframework__Integration_Configuration__c = queryConfiguration[0].Id;
        postPersonApiConfig.intframework__Execution_Priority__c = 1;
        postPersonApiConfig.intframework__API_Named_Credential__c = 'Acuris';
        postPersonApiConfig.intframework__API_Endpoint__c = 'monitorApi/v1_0/api/persons';
        postPersonApiConfig.intframework__HTTP_Content_Type__c = 'application/json';
        postPersonApiConfig.intframework__HTTP_Method__c = 'POST';
        postPersonApiConfig.intframework__Request_Mapping__c = '{"thirdPartySystem":{"name":"Acuris","filters":[{"objectAPI":"Account","objectAlias":"accountQuery","fields":[{"externalField":"name","fieldAPI":"Name"},{"externalField":"uniqueId","fieldAPI":"CLS_Account_Id__c"}],"whereClause":"Id = :accountId"},{"objectAPI":"Contact","objectAlias":"contactQuery","fields":[{"externalField":"dateOfBirth","fieldAPI":"Birthdate"},{"externalField":"firstName","fieldAPI":"FirstName"},{"externalField":"lastName","fieldAPI":"LastName"}],"whereClause":"AccountId = :accountId"},{"objectAPI":"clcommon__Address__c","objectAlias":"addressQuery","fields":[{"externalField":"houseNumber","fieldAPI":"House_no_name__c"},{"externalField":"addressLine1","fieldAPI":"clcommon__Street_Address__c"},{"externalField":"addressLine2","fieldAPI":"clcommon__Address_Line_2__c"},{"externalField":"addressLine3","fieldAPI":"Address_Line_3__c"},{"externalField":"city","fieldAPI":"clcommon__City__c"},{"externalField":"county","fieldAPI":"clcommon__County__c"},{"externalField":"zip","fieldAPI":"clcommon__Zip_Code__c"},{"externalField":"accountId","fieldAPI":"clcommon__Account__c"}],"whereClause":"clcommon__Account__c = :accountId"}],"staticParameters":[],"dynamicDataParameters":[{"externalField":"sourceName"}]}}';
        postPersonApiConfig.intframework__Response_Mapping__c = '{"StorageConfiguration":{"StoreInDB":"False","PublishAsJSON":"False"},"DMLOperations":[]}';
        postPersonApiConfig.intframework__Request_Timeout__c = 120000;
        postPersonApiConfig.intframework__Additional_Header_Parameters__c = '{"apiKey":"67005c9c-4d6a-4d64-972b-4c84232fae04","Content-Type":"application/json; charset=utf-8","Host":"api1.uat.c6-intelligence.com"}';
        intApiConfigList.add(postPersonApiConfig);

        intframework__Integration_API_Configuration__c putBusinessApiConfig = F2FTestHelper.createAPIConfig('Acuris Put Business');
        putBusinessApiConfig.intframework__Adapter_Class_Name__c = 'AcurisPutBusinessAdapter';
        putBusinessApiConfig.intframework__Integration_Family__c = integrationFamily[0].Id;
        putBusinessApiConfig.intframework__Integration_API_Type__c = getPutBusinessApiType[0].Id;
        putBusinessApiConfig.intframework__Integration_Provider__c = queryProvider[0].Id;
        putBusinessApiConfig.intframework__Integration_Configuration__c = queryConfiguration[0].Id;
        putBusinessApiConfig.intframework__Execution_Priority__c = 1;
        putBusinessApiConfig.intframework__API_Named_Credential__c = 'Acuris';
        putBusinessApiConfig.intframework__API_Endpoint__c = '/monitorApi/v1_0/api/businesses?uniqueId=';
        putBusinessApiConfig.intframework__HTTP_Content_Type__c = 'application/json';
        putBusinessApiConfig.intframework__HTTP_Method__c = 'PUT';
        putBusinessApiConfig.intframework__Request_Mapping__c = '{"thirdPartySystem":{"name":"Acuris","filters":[{"objectAPI":"Account","objectAlias":"accountQuery","fields":[{"externalField":"name","fieldAPI":"Name"},{"externalField":"uniqueId","fieldAPI":"CLS_Account_Id__c"}],"whereClause":"Id = :accountId"},{"objectAPI":"clcommon__Address__c","objectAlias":"addressQuery","fields":[{"externalField":"houseNumber","fieldAPI":"House_no_name__c"},{"externalField":"addressLine1","fieldAPI":"clcommon__Street_Address__c"},{"externalField":"addressLine2","fieldAPI":"clcommon__Address_Line_2__c"},{"externalField":"addressLine3","fieldAPI":"Address_Line_3__c"},{"externalField":"city","fieldAPI":"clcommon__City__c"},{"externalField":"county","fieldAPI":"clcommon__County__c"},{"externalField":"zip","fieldAPI":"clcommon__Zip_Code__c"},{"externalField":"accountId","fieldAPI":"clcommon__Account__c"}],"whereClause":"clcommon__Account__c = :accountId"}],"staticParameters":[],"dynamicDataParameters":[{"externalField":"sourceName"}]}}';
        putBusinessApiConfig.intframework__Response_Mapping__c = '{"StorageConfiguration":{"StoreInDB":"False","PublishAsJSON":"False"},"DMLOperations":[]}';
        putBusinessApiConfig.intframework__Request_Timeout__c = 120000;
        putBusinessApiConfig.intframework__Additional_Header_Parameters__c = '{"apiKey":"67005c9c-4d6a-4d64-972b-4c84232fae04","Content-Type":"application/json; charset=utf-8","Host":"api1.uat.c6-intelligence.com"}';
        intApiConfigList.add(putBusinessApiConfig);

        intframework__Integration_API_Configuration__c putPersonApiConfig = F2FTestHelper.createAPIConfig('Acuris Put Person');
        putPersonApiConfig.intframework__Adapter_Class_Name__c = 'AcurisPutPersonAdapter';
        putPersonApiConfig.intframework__Integration_Family__c = integrationFamily[0].Id;
        putPersonApiConfig.intframework__Integration_API_Type__c = getPutPersonApiType[0].Id;
        putPersonApiConfig.intframework__Integration_Provider__c = queryProvider[0].Id;
        putPersonApiConfig.intframework__Integration_Configuration__c = queryConfiguration[0].Id;
        putPersonApiConfig.intframework__Execution_Priority__c = 1;
        putPersonApiConfig.intframework__API_Named_Credential__c = 'Acuris';
        putPersonApiConfig.intframework__API_Endpoint__c = '/monitorApi/v1_0/api/persons?uniqueId=';
        putPersonApiConfig.intframework__HTTP_Content_Type__c = 'application/json';
        putPersonApiConfig.intframework__HTTP_Method__c = 'PUT';
        putPersonApiConfig.intframework__Request_Mapping__c = '{"thirdPartySystem":{"name":"Acuris","filters":[{"objectAPI":"Account","objectAlias":"accountQuery","fields":[{"externalField":"name","fieldAPI":"Name"},{"externalField":"uniqueId","fieldAPI":"CLS_Account_Id__c"}],"whereClause":"Id = :accountId"},{"objectAPI":"Contact","objectAlias":"contactQuery","fields":[{"externalField":"dateOfBirth","fieldAPI":"Birthdate"},{"externalField":"firstName","fieldAPI":"FirstName"},{"externalField":"lastName","fieldAPI":"LastName"}],"whereClause":"AccountId = :accountId"},{"objectAPI":"clcommon__Address__c","objectAlias":"addressQuery","fields":[{"externalField":"houseNumber","fieldAPI":"House_no_name__c"},{"externalField":"addressLine1","fieldAPI":"clcommon__Street_Address__c"},{"externalField":"addressLine2","fieldAPI":"clcommon__Address_Line_2__c"},{"externalField":"addressLine3","fieldAPI":"Address_Line_3__c"},{"externalField":"city","fieldAPI":"clcommon__City__c"},{"externalField":"county","fieldAPI":"clcommon__County__c"},{"externalField":"zip","fieldAPI":"clcommon__Zip_Code__c"},{"externalField":"accountId","fieldAPI":"clcommon__Account__c"}],"whereClause":"clcommon__Account__c = :accountId"}],"staticParameters":[],"dynamicDataParameters":[{"externalField":"sourceName"}]}}';
        putPersonApiConfig.intframework__Response_Mapping__c = '{"StorageConfiguration":{"StoreInDB":"False","PublishAsJSON":"False"},"DMLOperations":[]}';
        putPersonApiConfig.intframework__Request_Timeout__c = 120000;
        putPersonApiConfig.intframework__Additional_Header_Parameters__c = '{"apiKey":"67005c9c-4d6a-4d64-972b-4c84232fae04","Content-Type":"application/json; charset=utf-8","Host":"api1.uat.c6-intelligence.com"}';
        intApiConfigList.add(putPersonApiConfig);

        intframework__Integration_API_Configuration__c removeBusinessApiConfig = F2FTestHelper.createAPIConfig('Acuris Remove Business');
        removeBusinessApiConfig.intframework__Adapter_Class_Name__c = 'AcurisRemoveAdapter';
        removeBusinessApiConfig.intframework__Integration_Family__c = integrationFamily[0].Id;
        removeBusinessApiConfig.intframework__Integration_API_Type__c = getRemoveBusinessApiType[0].Id;
        removeBusinessApiConfig.intframework__Integration_Provider__c = queryProvider[0].Id;
        removeBusinessApiConfig.intframework__Integration_Configuration__c = queryConfiguration[0].Id;
        removeBusinessApiConfig.intframework__Execution_Priority__c = 1;
        removeBusinessApiConfig.intframework__API_Named_Credential__c = 'Acuris';
        removeBusinessApiConfig.intframework__API_Endpoint__c = '/monitorApi/v1_0/api/businesses?uniqueId=';
        removeBusinessApiConfig.intframework__HTTP_Content_Type__c = 'application/json';
        removeBusinessApiConfig.intframework__HTTP_Method__c = 'DELETE';
        removeBusinessApiConfig.intframework__Request_Mapping__c = '{"thirdPartySystem":{"name":"Acuris","dynamicDataParameters":[{"externalField":"uniqueId"}],"filters":[],"staticParameters":[]}}';
        removeBusinessApiConfig.intframework__Response_Mapping__c = '{"StorageConfiguration":{"StoreInDB":"False","PublishAsJSON":"False"},"DMLOperations":[]}';
        removeBusinessApiConfig.intframework__Request_Timeout__c = 120000;
        removeBusinessApiConfig.intframework__Additional_Header_Parameters__c = '{"apiKey":"67005c9c-4d6a-4d64-972b-4c84232fae04","Content-Type":"application/json; charset=utf-8","Host":"api1.uat.c6-intelligence.com"}';
        intApiConfigList.add(removeBusinessApiConfig);

        intframework__Integration_API_Configuration__c removePersonApiConfig = F2FTestHelper.createAPIConfig('Acuris Remove Person');
        removePersonApiConfig.intframework__Adapter_Class_Name__c = 'AcurisRemoveAdapter';
        removePersonApiConfig.intframework__Integration_Family__c = integrationFamily[0].Id;
        removePersonApiConfig.intframework__Integration_API_Type__c = getRemovePersonApiType[0].Id;
        removePersonApiConfig.intframework__Integration_Provider__c = queryProvider[0].Id;
        removePersonApiConfig.intframework__Integration_Configuration__c = queryConfiguration[0].Id;
        removePersonApiConfig.intframework__Execution_Priority__c = 1;
        removePersonApiConfig.intframework__API_Named_Credential__c = 'Acuris';
        removePersonApiConfig.intframework__API_Endpoint__c = '/monitorApi/v1_0/api/persons?uniqueId=';
        removePersonApiConfig.intframework__HTTP_Content_Type__c = 'application/json';
        removePersonApiConfig.intframework__HTTP_Method__c = 'DELETE';
        removePersonApiConfig.intframework__Request_Mapping__c = '{"thirdPartySystem":{"name":"Acuris","dynamicDataParameters":[{"externalField":"uniqueId"}],"filters":[],"staticParameters":[]}}';
        removePersonApiConfig.intframework__Response_Mapping__c = '{"StorageConfiguration":{"StoreInDB":"False","PublishAsJSON":"False"},"DMLOperations":[]}';
        removePersonApiConfig.intframework__Request_Timeout__c = 120000;
        removePersonApiConfig.intframework__Additional_Header_Parameters__c = '{"apiKey":"67005c9c-4d6a-4d64-972b-4c84232fae04","Content-Type":"application/json; charset=utf-8","Host":"api1.uat.c6-intelligence.com"}';
        intApiConfigList.add(removePersonApiConfig);

        if(!intApiConfigList.isEmpty()) {
            insert intApiConfigList;
        }

        // query for assertion
        List<intframework__Integration_API_Configuration__c> queryIntApiConfigList = [SELECT id
                                                                                        FROM intframework__Integration_API_Configuration__c
                                                                                        WHERE intframework__Integration_Family__c != null];

        System.assertEquals(true, queryIntApiConfigList.size() == 6, 'Integration API Configuration list is not inserted');

    }

    // for removing person account from Acuris callout
    @isTest(SeeAllData=false)
    static void runTest() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');
        
        Test.startTest();
        String result = AcurisController.makeRemoveBusinessCallout(account[0].Id);
        System.assertEquals(true, result == Folk2FolkIntegrationConstants.DELETED_FROM_ACURIS, result);
        Test.stopTest();
    }

    // for removing company account from Acuris callout
    @isTest(SeeAllData=false)
    static void runTest2() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Company Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');
        
        Test.startTest();
        String result = AcurisController.makeRemoveBusinessCallout(account[0].Id);
        System.assertEquals(true, result == Folk2FolkIntegrationConstants.DELETED_FROM_ACURIS, result);
        Test.stopTest();
    }

    // for error scenarion in remove account callout
    @isTest(SeeAllData=false)
    static void runTest3() {
        
        Test.startTest();
        String result = AcurisController.makeRemoveBusinessCallout(null);
        System.assertEquals(true, result == Folk2FolkConstantValues.EMPTY_PARAMETER, result);
        Test.stopTest();
    }

    // for sending company account to acuris callout
    @isTest(SeeAllData=false)
    static void runTest4() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Company Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];

        System.assertEquals(true, application.size() == 1, 'application not found');
        
        Test.startTest();
        AcurisController.makePostBusinessCallout(account[0].Id, application[0].Id, 'companyBorrower', 'Company', 'Company', 'Borrower Application');
        Test.stopTest();
    }

    // for sending person account to acuris callout
    @isTest(SeeAllData=false)
    static void runTest5() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id
                                    FROM Account
                                    WHERE Name = 'IFISA Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];

        System.assertEquals(true, application.size() == 1, 'application not found');
        
        Test.startTest();
        AcurisController.makePostPersonCallout(account[0].Id, application[0].Id, 'individualBorrower', 'Individual', 'Individual', 'Borrower Application');
        Test.stopTest();
    }

    // for error scenario in sending person account to acuris callout
    @isTest(SeeAllData=false)
    static void runTest6() {
        
        Test.startTest();
        AcurisController.makePostBusinessCallout(null, null, 'individualBorrower', 'Company', 'Company', 'Borrower Application');
        Test.stopTest();
    }

    // for sending business account of investor type to acuris callout
    @isTest(SeeAllData=false)
    static void runTest7() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Company Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];

        System.assertEquals(true, application.size() == 1, 'application not found');
        
        Test.startTest();
        AcurisController.makePostBusinessCallout(account[0].Id, application[0].Id, 'companyBorrower', 'Company', 'Company', 'Borrower Application');
        Test.stopTest();
    }

    // for error scenario in sending business account to acuris callout
    @isTest(SeeAllData=false)
    static void runTest8() {
        
        Test.startTest();
        AcurisController.postBusinessCallout(null, null, null, 'Individual', 'Investor Application');
        Test.stopTest();
    }

    // for sending company account of limited type borrower to acuris callout
    @isTest(SeeAllData=false)
    static void runTest9() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];

        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];

        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Borrower', true, true, true, 'Company', 'Company', 'Borrower Application');
        System.assertEquals(true, result == Folk2FolkIntegrationConstants.ADDED_TO_ACURIS, result);
        Test.stopTest();
    }

    // for editing company account of limited type borrower from acuris callout
    @isTest(SeeAllData=false)
    static void runTest10() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Borrower', true, true, false, 'Company', 'Company', 'Borrower Application');
        System.assertEquals(true, result == Folk2FolkConstantValues.SUCCESS_MESSAGE, result);
        Test.stopTest();
    }

    // for editing individual account of limited type investor from acuris callout
    @isTest(SeeAllData=false)
    static void runTest11() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result16 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'individual', 'Investor', true, true, false, 'Individual', 'Individual', 'Investor Application');
        System.assertEquals(true, result16 == Folk2FolkConstantValues.SUCCESS_MESSAGE, result16);
        Test.stopTest();
    }

    // for sending individual account of limited type director to acuris callout
    @isTest(SeeAllData=false)
    static void runTest12() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result3 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Borrower', false, true, true,'Company', 'Company', 'Borrower Application');
        System.assertEquals(true, result3 == Folk2FolkIntegrationConstants.ADDED_TO_ACURIS, result3);
        Test.stopTest();
    }

    // for editing individual account of limited type director from acuris callout
    @isTest(SeeAllData=false)
    static void runTest13() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result4 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Borrower', false, true, false,'Company', 'Company', 'Borrower Application');
        System.assertEquals(true, result4 == Folk2FolkConstantValues.SUCCESS_MESSAGE, result4);
        Test.stopTest();
    }

    // for sending individual account of non-limited type director to acuris callout
    @isTest(SeeAllData=false)
    static void runTest14() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result5 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Borrower', false, false, true,'Company', 'Company', 'Borrower Application');
        System.assertEquals(true, result5 == Folk2FolkIntegrationConstants.ADDED_TO_ACURIS, result5);
        Test.stopTest();
    }

    // for editing individual account of non-limited type director from acuris callout
    @isTest(SeeAllData=false)
    static void runTest15() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result6 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Borrower', false, false, false,'Company', 'Company', 'Borrower Application');
        System.assertEquals(true, result6 == Folk2FolkConstantValues.SUCCESS_MESSAGE, result6);
        Test.stopTest();
    }

    // for sending individual account of limited type borrower to acuris callout
    @isTest(SeeAllData=false)
    static void runTest16() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result7 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'individual', 'Borrower', true, true, true,'Individual', 'Individual', 'Borrower Application');
        System.assertEquals(true, result7 == Folk2FolkIntegrationConstants.ADDED_TO_ACURIS, result7);
        Test.stopTest();
    }

    // for editing individual account of limited type borrower from acuris callout
    @isTest(SeeAllData=false)
    static void runTest17() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result8 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'individual', 'Borrower', true, true, false,'Individual', 'Individual', 'Borrower Application');
        System.assertEquals(true, result8 == Folk2FolkConstantValues.SUCCESS_MESSAGE, result8);
        Test.stopTest();
    }

    // for sending company account of limited type investor to acuris callout
    @isTest(SeeAllData=false)
    static void runTest18() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result9 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Investor', true, true, true, 'Company', 'Company', 'Investor Application');
        System.assertEquals(true, result9 == Folk2FolkIntegrationConstants.ADDED_TO_ACURIS, result9);
        Test.stopTest();
    }

    // for editing company account of limited type investor from acuris callout
    @isTest(SeeAllData=false)
    static void runTest19() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result10 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Investor', true, true, false,'Company', 'Company', 'Investor Application');
        System.assertEquals(true, result10 == Folk2FolkConstantValues.SUCCESS_MESSAGE, result10);
        Test.stopTest();
    }

    // for sending individual account of limited type director to acuris callout
    @isTest(SeeAllData=false)
    static void runTest20() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result11 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Investor', false, true, true,'Company', 'Company', 'Investor Application');
        System.assertEquals(true, result11 == Folk2FolkIntegrationConstants.ADDED_TO_ACURIS, result11);
        Test.stopTest();
    }

    // for editing individual account of limited type director from acuris callout
    @isTest(SeeAllData=false)
    static void runTest21() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result12 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Investor', false, true, false, 'Company', 'Company', 'Investor Application');
        System.assertEquals(true, result12 == Folk2FolkConstantValues.SUCCESS_MESSAGE, result12);
        Test.stopTest();
    }

    // for sending individual account of non-limited type director to acuris callout
    @isTest(SeeAllData=false)
    static void runTest22() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result13 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Investor', false, false, true,'Company', 'Company', 'Investor Application');
        System.assertEquals(true, result13 == Folk2FolkIntegrationConstants.ADDED_TO_ACURIS, result13);
        Test.stopTest();
    }

    // for editing individual account of non-limited type director from acuris callout
    @isTest(SeeAllData=false)
    static void runTest23() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result14 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'business', 'Investor', false, false, false,'Company', 'Company', 'Investor Application');
        System.assertEquals(true, result14 == Folk2FolkConstantValues.SUCCESS_MESSAGE, result14);
        Test.stopTest();
    }

    // for sending individual account of limited type investor to acuris callout
    @isTest(SeeAllData=false)
    static void runTest24() {
        Test.setMock(HttpCalloutMock.class, new F2FTestHelper.Mock());
        List<Account> account = [SELECT id,
                                    CLS_Account_Id__c 
                                    FROM Account
                                    WHERE Name = 'Borrower 1'];

        System.assertEquals(true, account.size() == 1, 'Account not found');

        List<genesis__Applications__c> application = [SELECT id,
                                                            Name
                                                        FROM genesis__Applications__c
                                                        WHERE genesis__Account__c =: account[0].Id];
        System.assertEquals(true, application.size() == 1, 'application not found');

        List<clcommon__Party__c> party = [SELECT id,
                                                Name
                                            FROM clcommon__Party__c
                                            WHERE genesis__Application__c =: application[0].Id
                                            AND clcommon__Account__c =: account[0].Id];
        System.assertEquals(true, party.size() == 1, 'party not found');
        
        Test.startTest();
        String result15 = AcurisController.postAccountCallout(account[0].Id, party[0].Id, 'individual', 'Investor', true, true, true,'Individual', 'Individual', 'Investor Application');
        System.assertEquals(true, result15 == Folk2FolkIntegrationConstants.ADDED_TO_ACURIS, result15);
        Test.stopTest();
    }

}