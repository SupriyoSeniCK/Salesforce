/**
 * @description       : This is the test class for LoanPayoffQuoteTrigger & LoanPayoffQuoteTriggerHandler
 * @author            : Supriyo Seni
 * @group             : Apex Trigger  
 * @last modified on  : 09-05-2023
 * @last modified by  : Supriyo Seni
**/
@isTest
private class LoanPayoffQuoteTriggerTest {
    @TestSetup
    static void makeData(){
        Bpay_Default_Values__c bpayIns = new Bpay_Default_Values__c();
        bpayIns.LoanPayOffQuoteTrigger__c = true;
        upsert bpayIns;

        Account accTest = FlowfiTestHelper.accountCreator();
        insert accTest;

        Contact con = FlowfiTestHelper.contactCreator(accTest.id);
        insert con;

        loan.TestHelper.createSeedDataForTesting();
        loan__Client__c dummyClient = loan.TestHelper.createClient();
        loan__Office_Name__c offObj = loan.TestHelper.createOffice();
        loan__MF_Account__c mfObj = loan.TestHelper.createMFAccount('XXXAccountForTest','10000 - ASSETS');
        loan__MF_Account__c mfIncObj = loan.TestHelper.createMFAccount('XXXIncAccountForTest','30000 - INCOME');
        loan__Currency__c currObj = loan.TestHelper.createCurrency();

        loan__User_Branch_Info__c bc = new loan__User_Branch_Info__c();
        bc.loan__Branch__c = offObj.id;
        bc.loan__User__c = UserInfo.getUserId();
        bc.loan__Default_Branch__c = true;
        insert bc;

        loan__Fee__c dummyFee = loan.TestHelper.createFee(currObj,mfIncObj ,mfObj);                                    
        loan__Fee_Set__c dummyFeeSet = loan.TestHelper.createFeeSet();
        loan__Fee_Junction__c dummyFeeJunction = loan.TestHelper.createFeeJunction(dummyFee,dummyFeeSet);
        loan__Loan_Product__c proObj = loan.TestHelper.createLoanProduct(offObj , mfObj , currObj , dummyFeeSet );
        proObj.Name = 'Personal Loan Variable Rate';
        update proObj;
        loan__Loan_Purpose__c purObj = loan.TestHelper.createLoanPurpose();
        loan__Loan_Account__c conObj = loan.TestHelper.createLoanAccount(proObj , dummyClient, dummyFeeSet , purObj ,offObj);
        conObj.loan__Loan_Product_Name__c = proObj.id;
        conObj.loan__Loan_Status__c = 'Active - Good Standing';
        conObj.Original_State__c = 'ABC';
        conObj.Early_Termination_Fee_Type__c= 'TYPE1';
        conObj.loan__Maturity_Date_Current__c = Date.newInstance(2023,08,01);
        conObj.isMigrated__c = TRUE;
        update conObj; 

        //Creating Insurance data
        Insurance__c inc = new Insurance__c();
        inc.Short_name_Customer_name__c = 'Rj';
        inc.Policy_Type__c = 'joint';
        inc.Premium_Amount__c = 900;
        inc.Cover_Type__c = 'Life Cover';
        inc.Loan_Account__c = conObj.id;
        inc.Policy_Effective_Date__c = FlowfiUtil.currentSystemDate-4;
        inc.Policy_Expiry_Date__c = FlowfiUtil.currentSystemDate+10;
        inc.Premium_Amount_Net__c = 20;
        inc.Premium_Amount_S_Duty__c = 20;
        inc.Premium_Amount_GST__c = 20;
        inc.Product__c='11';
        inc.ICBS_Policy_Status__c = 'Active';
        inc.Type__c = 'CCI';
        insert inc;

        //Creating Insurance data
        Insurance__c incDis = new Insurance__c();
        incDis.Short_name_Customer_name__c = 'Rj';
        incDis.Policy_Type__c = 'joint';
        incDis.Premium_Amount__c = 900;
        incDis.Cover_Type__c = 'Disability Cover';
        incDis.Loan_Account__c = conObj.id;
        incDis.Policy_Effective_Date__c = FlowfiUtil.currentSystemDate-4;
        incDis.Policy_Expiry_Date__c = FlowfiUtil.currentSystemDate+11;
        incDis.Premium_Amount_Net__c = 20;
        incDis.Premium_Amount_S_Duty__c = 20;
        incDis.Premium_Amount_GST__c = 20;
        incDis.Product__c='21';
        incDis.ICBS_Policy_Status__c = 'Active';
        incDis.Type__c = 'CCI';
        insert incDis;
        
        loan__Payoff_Quote__c loanPayOff = new loan__Payoff_Quote__c();
        loanPayOff.loan__Loan_Account__c = conObj.id;
        loanPayOff.loan__Poq_Transaction_Date__c  = FlowfiUtil.currentSystemDate;
        loanPayOff.Name = 'Test';
        loanPayOff.loan__Poq_valid_till_Dt__c = date.today();
        insert loanPayOff;
    }

    @isTest 
    static void checkAfterInsertPl(){  
        List<loan__Payoff_Quote__c> loanPayOffList = [SELECT id, name,loan__Loan_Account__c,loan__Poq_Transaction_Date__c,loan__Poq_valid_till_Dt__c FROM loan__Payoff_Quote__c LIMIT 1];
        Map<Id,loan__Payoff_Quote__c> payoffMap = new Map<Id,loan__Payoff_Quote__c>();
        payoffMap.put(loanPayOffList[0].id,loanPayOffList[0]);
        Test.startTest();
        LoanPayoffQuoteTriggerHandler.afterInsert(payoffMap);
        Test.stopTest();
        List<loan__Payoff_Quote__c> pfList =[SELECT Id, Total_of_Insurance_rebates__c FROM loan__Payoff_Quote__c WHERE Id =: loanPayOffList[0].id LIMIT 1];
        System.assertEquals(0, pfList[0].Total_of_Insurance_rebates__c,'Rebate Amount is zero');
    }

    @isTest 
    static void checkAfterInsertMl(){  
        List<loan__Loan_Product__c> prodList = [SELECT id, Name FROM loan__Loan_Product__c LIMIT 1];
        prodList[0].name  = 'Motor Loan Variable Rate';
        update prodList;
        List<loan__Payoff_Quote__c> loanPayOffList = [SELECT id, name,loan__Loan_Account__c,loan__Poq_Transaction_Date__c,loan__Poq_valid_till_Dt__c FROM loan__Payoff_Quote__c LIMIT 1];
        Map<Id,loan__Payoff_Quote__c> payoffMap = new Map<Id,loan__Payoff_Quote__c>();
        payoffMap.put(loanPayOffList[0].id,loanPayOffList[0]);
        Test.startTest();
        LoanPayoffQuoteTriggerHandler.afterInsert(payoffMap);
        Test.stopTest();
        List<loan__Payoff_Quote__c> pfList =[SELECT Id, Total_of_Insurance_rebates__c FROM loan__Payoff_Quote__c WHERE Id =: loanPayOffList[0].id LIMIT 1];
        System.assertEquals(0, pfList[0].Total_of_Insurance_rebates__c,'Rebate Amount is zero');
    }

    @isTest 
    static void checkEtfAmount(){  
        List<loan__Loan_Account__c> clContractList = [SELECT id,name from loan__Loan_Account__c LIMIT 1];
        Set<String> loanListSet = new Set<String> ();
        loanListSet.add(clContractList[0].id);
        List<loan__Payoff_Quote__c> loanPayOffList = [SELECT id, name,loan__Loan_Account__c,loan__Poq_Transaction_Date__c,loan__Poq_valid_till_Dt__c FROM loan__Payoff_Quote__c LIMIT 1];
        Map<Id,loan__Payoff_Quote__c> payoffMap = new Map<Id,loan__Payoff_Quote__c>();
        payoffMap.put(clContractList[0].id,loanPayOffList[0]);
        Test.startTest();
        Map<Id,Decimal>  idVsDecimalMap = LoanPayoffQuoteETFHandler.calculateETFAmount(loanListSet,payoffMap);
        Test.stopTest();
        System.assertNotEquals(null, idVsDecimalMap,'Map not found');
    }

    @isTest 
    static void checkEtfMlAmount(){  
        List<String> etfAmtList = (system.label.ETF_Amount).split(',');
        List<loan__Loan_Account__c> loanList = [SELECT id,name,loan__Disbursal_Date__c,loan__Loan_Amount__c,loan__Term_Cur__c FROM loan__Loan_Account__c LIMIT 1];
        Test.startTest();
        Decimal etfAmt = LoanPayoffQuoteETFHandler.getETFForMLAccounts(loanList[0],6,etfAmtList);
        Test.stopTest();
        System.assertNotEquals(0, etfAmt,'EFT amount zero');
    }
}