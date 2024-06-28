/**
 * @description       : Test class for EquifaxCreditPullCallout and EquifaxCreditPullAdapter
 * @author            : Supriyo Seni
 * @group             : Equifax Integration
 * @last modified on  : 08-27-2023
 * @last modified by  : Supriyo Seni
**/
@isTest
public class EquifaxCreditPullCalloutTest {
    @TestSetup
    static void testData() {      
        //Creating CL product
        clcommon__CL_Product__c clProd = FlowfiTestHelper.createCLProduct('Motor Loan Fixed Rate');
        insert clProd;

        Account acc = FlowfiTestHelper.accountCreator();
        insert acc;

        Contact con = FlowfiTestHelper.contactCreator(acc.Id);
        insert con;
        
        user usr = FlowfiTestHelper.userCreatorBroker(acc.Id,con.Id);
        insert usr;

        genesis__Applications__c app = FlowFiTestHelper.appCreator(acc.Id, con.Id);
        app.genesis__Status__c ='Referred-Sales';
        app.genesis__CL_Product__c = clProd.id;
        insert app;

        //creating a integration configuration
        intframework__Integration_Family__c family = new intframework__Integration_Family__c();
        family.Name = 'Equifax';
        insert family;
        List<intframework__Integration_Family__c> assertFamily = [ SELECT Id,
                                                                        Name
                                                                        FROM intframework__Integration_Family__c 
                                                                        WHERE Name = 'Equifax'
                                                                        AND Id = :family.Id LIMIT 1];
        System.assertEquals(true, assertFamily.size() == 1,'Family not inserted');
        intframework__Integration_Provider__c provider = new intframework__Integration_Provider__c();
        provider.Name = 'Equifax Provider';
        provider.intframework__Active__c = true;
        provider.intframework__Integration_Family__c = family.Id;
        insert provider;
        List<intframework__Integration_Provider__c> assertProvider = [ SELECT Id
                                                                            FROM intframework__Integration_Provider__c 
                                                                            WHERE Name = 'Equifax Provider'
                                                                            AND Id = :provider.Id LIMIT 1];
        System.assertEquals(true, assertProvider.size() == 1,'Provider Not Inserted');
 
        intframework__Integration_API_Type__c apiType = new intframework__Integration_API_Type__c();
        apiType.Name = 'Document';
        apiType.intframework__Integration_Family__c = family.Id;
        insert apiType;
        List<intframework__Integration_API_Type__c> assertApiType = [ SELECT Id
                                                                            FROM intframework__Integration_API_Type__c 
                                                                            WHERE Name = 'Document'];
        System.assertEquals(true, assertApiType.size() == 1,'ApiType Not Inserted');
 
        intframework__Integration_Configuration__c integrationConfig = new intframework__Integration_Configuration__c();
        integrationConfig.Name = 'Equifax Credit Pull';
        integrationConfig.intframework__Integration_Provider__c = provider.Id;
        insert integrationConfig;
        List<intframework__Integration_Configuration__c> assertIntegrationConfig = [ SELECT Id
                                                                                    FROM intframework__Integration_Configuration__c 
                                                                                    WHERE Name = 'Equifax Credit Pull'];
        System.assertEquals(true, assertIntegrationConfig.size() == 1,'IntegrationConfig Not Inserted');
 
        intframework__Integration_API_Configuration__c apiConfig = new intframework__Integration_API_Configuration__c();
        apiConfig.Name = 'Equifax Credit Pull';
        apiConfig.intframework__Integration_Family__c = family.Id;
        apiConfig.intframework__Integration_Provider__c = provider.Id;
        apiConfig.intframework__Integration_API_Type__c = apiType.Id;
        apiConfig.intframework__Integration_Configuration__c = integrationConfig.Id;
        apiConfig.intframework__Execution_Priority__c = 1;
        apiConfig.intframework__Request_Timeout__c = 120000;
        apiConfig.intframework__Number_Of_Retries__c = 0;
        apiConfig.intframework__Adapter_Class_Name__c = 'EquifaxCreditPullAdapter';
        apiConfig.intframework__HTTP_Content_Type__c = 'text/xml';
        apiConfig.intframework__API_Endpoint__c = '/sys2/previous-enquiry-v1';
        apiConfig.intframework__HTTP_Method__c = 'POST';
        apiConfig.intframework__Request_Mapping__c ='{"thirdPartySystem":{"name":"EquifaxCreditPull","filters":[{"objectAPI":"Equifax_Credit_Report__c","objectAlias":"EquifaxQuery","fields":[{"externalField":"enquiryId","fieldAPI":"Enquiry_ID__c"},{"externalField":"appId","fieldAPI":"Application__c"}],"whereClause":"Id = :eqfxCreditId"}],"staticParameters":[{"externalField":"username","value":"LPDrrcjQjh"},{"externalField":"password","value":"uyXukXzjZG"}],"dynamicDataParameters":[]}}}}';
        insert apiConfig;
        List<intframework__Integration_API_Configuration__c> assertApiConfig = [ SELECT Id
                                                                                FROM intframework__Integration_API_Configuration__c 
                                                                                WHERE Name = 'Equifax Credit Pull'];
        System.assertEquals(true, assertApiConfig.size() == 1,'ApiConfig Not Inserted');
    }
    @isTest
    static void testFunc(){
        Account acc=FlowfiTestHelper.accountCreator();
        insert acc;
        Contact con=FlowfiTestHelper.contactCreator(acc.Id);
        insert con;
        genesis__Applications__c app=FlowFiTestHelper.appCreator(acc.Id, con.Id);
        insert app;
        Equifax_Credit_Report__c eqfx=new Equifax_Credit_Report__c();
        eqfx.Enquiry_ID__c='221005-1C3C0-C7BA4';
        eqfx.Application__c=app.Id;
        insert eqfx;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EquifaxCreditPullMockTest()); 
        HttpResponse res=EquifaxCreditPullMockTest.respond(new HttpRequest());
        EquifaxCreditPullCallout.searchHits(eqfx.Id);  
        intframework.BaseIntegrationResponse resp=new EquifaxCreditPullAdapter().createResponse(res);
        Test.stopTest();
    }
    @isTest
    static void testFunc2(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EquifaxCreditPullMockTest());                                                                    
        EquifaxCreditPullCallout.searchHits(null);
        Test.stopTest();
    }
    @isTest
    static void testFuncBatch(){
        Account acc=FlowfiTestHelper.accountCreator();
        insert acc;
        Contact con=FlowfiTestHelper.contactCreator(acc.Id);
        insert con;
        genesis__Applications__c app=FlowFiTestHelper.appCreator(acc.Id, con.Id);
        insert app;
        app.genesis__Status__c ='Referred-Sales';
        update app;
        Equifax_Credit_Report__c eqfx=new Equifax_Credit_Report__c();
        eqfx.Enquiry_ID__c='220301-28408-44FBB';
        eqfx.Application__c=app.Id;
        insert eqfx;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EquifaxCreditPullMockTest()); 
        HttpResponse res=EquifaxCreditPullMockTest.respond(new HttpRequest());
        String query='SELECT Id, Name, CreatedDate, Application__c,Application__r.genesis__Status__c, Enquiry_ID__c, Party__c FROM Equifax_Credit_Report__c'; 
        GenerateEqfxCreditPullPDFBatch job = new GenerateEqfxCreditPullPDFBatch(query); 
        Id jobId=database.executebatch(job,1);
        System.assert(jobId!=null, 'Assertion Failed');
        Test.stopTest();
    }

    @isTest
    static void testAdapterForMl(){
        List<genesis__Applications__c> appList = [SELECT id,genesis__CL_Product__c FROM genesis__Applications__c WHERE Product_Name__c = 'Motor' ];
        Equifax_Credit_Report__c eqfx = new Equifax_Credit_Report__c();
        eqfx.Enquiry_ID__c = '220301-28408-44FBB';
        eqfx.Application__c = appList[0].Id;
        insert eqfx;
        List<User> usrList =[SELECT id FROM User WHERE Username = 'testinguser123@mailinator.com' LIMIT 1];
        Test.startTest();
        System.runAs(usrList[0]){
            Test.setMock(HttpCalloutMock.class, new EquifaxCreditPullMockTest()); 
            EquifaxCreditPullCallout.searchHits(eqfx.id);
        } 
        Test.stopTest();
    }
}