/**
 * @description                : Remove personal data from org.
 * @author                     : 
 * @group                      : Batch Class
 * @last modified on           : 05-08-2024
 * @last modified by           : Supriyo Seni
 * Script             : Database.executeBatch(new PersonalDataRemovalBatch(),100);
**/
public with sharing class PersonalDataRemovalBatch implements Database.Batchable<sObject>, Database.Stateful{
    public Integer counter = 1;
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator([SELECT id, 
                                                Name,
                                                genesis__SSN__c,
                                                Unit_Phone_Number__c,
                                                BirthDate,
                                                (SELECT Id,
                                                        Name
                                                FROM clcommon__Bank_Accounts__r),
                                                (SELECT Id,
                                                        Name
                                                FROM loan__Bank_Accounts__r) 
                                                FROM Contact 
                                                WHERE NOT Email Like '%preprod@yopmail.com%']);
    }
    public void execute(Database.BatchableContext batchableContext, List<Contact> contactList){
        try {
            List<Contact> updateContactList = new List<Contact>();
            Integer ssn;
            Integer unitPhoneNumber;
            List<clcommon__Bank_Account__c> updateCommonBankList = new List<clcommon__Bank_Account__c>();
            List<loan__Bank_Account__c> updateLoanBank = new List<loan__Bank_Account__c>(); 
            for (Contact eachContact : contactList) {
                Integer ssn = 896600000 + counter;
                Integer unitPhoneNumber = 554432344 + counter;
                eachContact.genesis__SSN__c = String.valueOf(ssn);
                eachContact.Unit_Phone_Number__c = String.valueOf(unitPhoneNumber);
                eachContact.BirthDate = eachContact.BirthDate != null ? (eachContact.BirthDate).addDays(2) : eachContact.BirthDate;
                eachContact.Email = 'test.ck.' + String.valueOf(counter) + '.preprod@yopmail.com';
                updateContactList.add(eachContact);
 
                List<clcommon__Bank_Account__c> commonBank = eachContact?.clcommon__Bank_Accounts__r;
                if (commonBank != null && commonBank.size() > 0){
                    for (clcommon__Bank_Account__c eachCommonBank : commonBank) {
                        eachCommonBank.clcommon__Bank_Account_Number__c = '7897979780';
                        eachCommonBank.Confirmed_Account_Number__c = '7897979780';
                        eachCommonBank.clcommon__Routing_Number__c = '051000017';
                        eachCommonBank.clcommon__Account_Type__c = 'Savings';
                        eachCommonBank.clcommon__Bank_Name__c = 'Test Bank ACCOUNT';
                        updateCommonBankList.add(eachCommonBank);
                    }
                }
 
                List<loan__Bank_Account__c> loanBank = eachContact?.loan__Bank_Accounts__r;
                if (loanBank != null && loanBank.size() > 0){
                    for (loan__Bank_Account__c eachLoanBank : loanBank) {
                        eachLoanBank.loan__Bank_Account_Number__c = '7897979780';
                        eachLoanBank.loan__Bank_Name__c = 'Test Bank ACCOUNT';
                        eachLoanBank.loan__Routing_Number__c = '051000017';
                        updateLoanBank.add(eachLoanBank);
                    }
                }
                counter = counter + 1;
            }
            if(updateContactList != null && !updateContactList.isEmpty()){
                update updateContactList;
            }
            if(updateCommonBankList != null && !updateCommonBankList.isEmpty()){
                update updateCommonBankList;
            }
            if(updateLoanBank != null && !updateLoanBank.isEmpty()){
                update updateLoanBank;
            }
        } catch (Exception exe) {
            loan__Batch_Process_Log__c log =  CLXReadReturnFiles.createLog(PersonalDataRemovalBatch.class.getName(),
            CLXConstants.EXCEPTION_MESSAGE + exe.getMessage()+
            CLXConstants.EXCEPTION_LINE_NO + exe.getLineNumber(),
            CLXConstants.TYPE);
            insert log;
        }
    }
    public void finish(Database.BatchableContext batchableContext) {}
}