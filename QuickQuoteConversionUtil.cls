/****************************************************************************************************************************************
 * @description       : This helper class is called from flow when there is changes in loan amount,
                                                                                        pre-paid fees on application at in-funding stage.
 * @author            : Divyam Kumar
 * @Development Date  : 03/14/2020
 * @group             : 
 * @last modified on  : 04-23-2024
 * @last modified by  : Supriyo Seni
*******************************************************************************************************************************************/
public inherited sharing class F2FLoanApplicationDataSyncHandler {

    public static final String MANAGEMENT_FEE = 'Pre-Paid Management Fee';
    public static final String INITIAL_ARRANGEMENT_FEE = 'Initial arrangement fee';
    public static final Decimal ZERO_POINT_ZERO_ONE = 0.01;
    public static List<loan__Contract_Pre_Paid_Fee__c> newPrepaidFeeOnLoanList = new List<loan__Contract_Pre_Paid_Fee__c>();
    public static List<loan__Contract_Pre_Paid_Fee__c> deleteFeesOnLoanList = new List<loan__Contract_Pre_Paid_Fee__c>();
    public static Map<String, Decimal> feeNameVsAmountMap = new Map<String, Decimal>();
    public static Map<String, String> feeNameVsFeeIdMap = new Map<String, String>();

    /**
    * @description : This method will sync changes from Application to Loan App as well as to Contract.
    * @author Divyam Kumar | 03-14-2024 
    * @param applicationIdList 
    **/
    @InvocableMethod
    public static void  syncChangesFromApplication(List<Id> applicationIdList){
        List<genesis__applications__c> genesisApplicationList;
        List<loan__Loan_Account__c> loanAccountList;
        Set<Id> genesisApplicationIdSet = new Set<Id>();
        Set<Id> loanAccountIdSet = new Set<Id>();
        List<loan__Loan_Account__c> newFeesOnLoanAccountList;
        Savepoint savePointObj;
        try{
            if(applicationIdList.isEmpty()){
                throw new CustomException(Folk2FolkConstantValues.APPLICATION_NOT_RECEIVED);
            }
            genesisApplicationList = Folk2FolkQueriesUtility.fetchGenesisApplicationList(applicationIdList);
            loanAccountList = Folk2FolkQueriesUtility.fetchLoanAccountList(genesisApplicationList);
            
            //storing Borrower Application Id in a set.
            for(genesis__applications__c genesisAppObj: genesisApplicationList){
                genesisApplicationIdSet.add(genesisAppObj.Id);
            }

            //storing Loan Account Id in a set.
            for(loan__Loan_Account__c loanAccountObj: loanAccountList){
                loanAccountIdSet.add(loanAccountObj.Id);
            }

            //storing all pre-paid fee name vs their corresponding ids.
            feeNameVsFeeIdMap = fetchFeesId();

            //reschedule the loan based on new loan amount
            rescheduleLoanHelper(loanAccountIdSet);

            savePointObj = Database.setSavepoint();

            //Adding pre-paid fee if exist or edited on borrower application.
            updatePrepaidFees(loanAccountIdSet, genesisApplicationIdSet);
            //Re-calculate total pre-paid fees
            newFeesOnLoanAccountList = [SELECT Id,
                                                Application__r.genesis__Loan_Amount__c,
                                                loan__Loan_Amount__c,
                                                loan__Total_Pre_Paid_Fees__c 
                                            FROM loan__Loan_Account__c 
                                            WHERE Id IN: loanAccountIdSet
                                            WITH SYSTEM_MODE];
            //update new disbursal amount on each loan contract.
            for(loan__Loan_Account__c loanAccountObj: newFeesOnLoanAccountList){
                loanAccountObj.loan__Disbursal_Amount__c = loanAccountObj.loan__Loan_Amount__c - loanAccountObj.loan__Total_Pre_Paid_Fees__c;
                loanAccountObj.loan__Loan_Amount__c = loanAccountObj.Application__r.genesis__Loan_Amount__c;
            }
            SecureDMLUtil.updateSObject(newFeesOnLoanAccountList, true, AccessLevel.SYSTEM_MODE);
        }catch(Exception excep) {
            Database.rollback(savePointObj);
            DataUtil.insertLog(F2FLoanApplicationDataSyncHandler.class.getname(), excep);
        }
    }
    /**
    * @description : Update pre-paid fees on loan contract when changes on application.
    * @author Divyam Kumar | 04-08-2024 
    * @param loanAccountIdSet 
    * @param genesisApplicationIdSet 
    **/
    public static void updatePrepaidFees(Set<Id> loanAccountIdSet, Set<Id> genesisApplicationIdSet){
        Map<Id, List<clcommon__Fee__c>> appIdVsClCommonFeeListMap = new Map<Id, List<clcommon__Fee__c>>();
        Map<Id, List<loan__Contract_Pre_Paid_Fee__c>> loanIdVsLoanFeeListMap = new Map<Id, List<loan__Contract_Pre_Paid_Fee__c>>();
        List<clcommon__Fee__c> newClCommonFeeList = new List<clcommon__Fee__c>();
        List<loan__Contract_Pre_Paid_Fee__c> existingFeeOnLoanList = new List<loan__Contract_Pre_Paid_Fee__c>();

        //fetching pre-paid fees on Borrower Application and adding it to a map.
        appIdVsClCommonFeeListMap = Folk2FolkQueriesUtility.fetchPrePaidFeeOnApplicationUpdate(genesisApplicationIdSet);

        //check if MAF fee or Initial Arrangement fee is present then update its value
        updateMafAndInitialFeeOnApplication(appIdVsClCommonFeeListMap);

        //fetching pre-paid fees on Borrower Application of loan contract and adding it to a map. 
        loanIdVsLoanFeeListMap = Folk2FolkQueriesUtility.fetchPrePaidFeeOnLoanContractUpdate(loanAccountIdSet);

        for(Id applicationId: appIdVsClCommonFeeListMap.keyset()){
            newClCommonFeeList = appIdVsClCommonFeeListMap.get(applicationId);
            existingFeeOnLoanList = loanIdVsLoanFeeListMap.get(applicationId);
            if(newClCommonFeeList.isEmpty() && !existingFeeOnLoanList.isEmpty()){
                deleteFeesOnLoanList.addAll(existingFeeOnLoanList);
                existingFeeOnLoanList.clear();
                continue;
            }
            
            else if(existingFeeOnLoanList.isEmpty() && !newClCommonFeeList.isEmpty()){
                createNewFeeOnLoanContractFelper(newClCommonFeeList);
                newClCommonFeeList.clear();
                continue;
            }
            
            else{
                masterMethod(newClCommonFeeList, existingFeeOnLoanList);
                newClCommonFeeList.clear();
                existingFeeOnLoanList.clear();
            }
        }
        if(!newPrepaidFeeOnLoanList.isEmpty()){
            SecureDMLUtil.upsertSObject(newPrepaidFeeOnLoanList, true, AccessLevel.SYSTEM_MODE);
        }
        if(!deleteFeesOnLoanList.isEmpty()){
            SecureDMLUtil.deleteSObject(deleteFeesOnLoanList, true, AccessLevel.SYSTEM_MODE);
        }    
    }
    /**
    * @description : This method create new pre-paid fees on loan contract.
    * @author Divyam Kumar | 04-15-2024 
    * @param newClCommonFeeList 
    **/
    public static void createNewFeeOnLoanContractFelper(List<clcommon__Fee__c> newClCommonFeeList){
        for(clcommon__Fee__c eachClcommonFee: newClCommonFeeList){
            loan__Contract_Pre_Paid_Fee__c createNewLoanFeeObj = new loan__Contract_Pre_Paid_Fee__c();
            createNewLoanFeeObj.loan__Contract__c = eachClcommonFee.genesis__Application__r.CL_Contract__c;
            createNewLoanFeeObj.loan__Amount__c = eachClcommonFee.clcommon__Original_Amount__c;
            createNewLoanFeeObj.loan__Fee_Type__c = feeNameVsFeeIdMap.get(eachClcommonFee.Fee_Name__c);
            newPrepaidFeeOnLoanList.add(createNewLoanFeeObj);
        }
    }
    /**
    * @description : This method stores each fee and their respective amount in a map and calls helper method to update it on loan contract.
    * @author Divyam Kumar | 04-11-2024 
    * @param newClCommonFeeList 
    * @param existingFeeOnLoanList 
    **/
    public static void masterMethod(List<clcommon__Fee__c> newClCommonFeeList, List<loan__Contract_Pre_Paid_Fee__c> existingFeeOnLoanList){
        Map<String, String> feeNameVsLoanAccMap = new Map<String, String>();
        Set<String> feeNameSet = new Set<String>();
        for(clcommon__Fee__c eachFeeOnApplication: newClCommonFeeList){
            feeNameVsAmountMap.put(eachFeeOnApplication.Fee_Name__c, eachFeeOnApplication.clcommon__Original_Amount__c);
            feeNameVsLoanAccMap.put(eachFeeOnApplication.Fee_Name__c, eachFeeOnApplication.genesis__Application__r.CL_Contract__c);
        }
        feeNameSet = feeNameVsAmountMap.keySet();
        updateFeeAmountHelper(feeNameSet, existingFeeOnLoanList);
        //if new fees are added on application
        if(feeNameSet != null && !feeNameSet.isEmpty()){
            for(String eachFees: feeNameSet){
                loan__Contract_Pre_Paid_Fee__c createNewLoanFeeObj = new loan__Contract_Pre_Paid_Fee__c();
                createNewLoanFeeObj.loan__Contract__c = feeNameVsLoanAccMap.get(eachFees);
                createNewLoanFeeObj.loan__Amount__c = feeNameVsAmountMap.get(eachFees);
                createNewLoanFeeObj.loan__Fee_Type__c = feeNameVsFeeIdMap.get(eachFees);
                newPrepaidFeeOnLoanList.add(createNewLoanFeeObj);
            }
        }     
    }
    
    /**
    * @description : This method will fetch the Id of their respective fees.
    * @author Divyam Kumar | 04-08-2024 
    * @return Map<String, String> 
    **/
    public static Map<String, String> fetchFeesId(){
        List<String> feeNameList = System.label.PRE_PAID_FEE_NAME.split(',');
        List<loan__Fee__c> loanFeeList = [SELECT Id,
                                                Name,
                                                loan__Time_of_charge__c,
                                                loan__State__c
                                            FROM loan__Fee__c
                                            WHERE Name IN: feeNameList
                                            AND loan__Time_of_charge__c =: Folk2FolkConstantValues.PREPAID_FEES
                                            AND loan__State__c =: Folk2FolkConstantValues.ACTIVE_STATUS
                                            WITH SYSTEM_MODE];
        if(!loanFeeList.isEmpty()){
            for(loan__Fee__c loanFeeObj: loanFeeList){
                feeNameVsFeeIdMap.put(loanFeeObj.Name, loanFeeObj.Id);
            }
            return feeNameVsFeeIdMap;
        }else{
            throw new CustomException(Folk2FolkConstantValues.PREPAID_LIST_IS_EMPTY);
        }
     }

    /**
    * @description : This method update or add on deleted list based on operation performed on the application.
    * @author Divyam Kumar | 04-09-2024 
    * @param feeNameSet 
    * @param prepaidFeeOnLoanList 
    **/
    public static void updateFeeAmountHelper(Set<String> feeNameSet, List<loan__Contract_Pre_Paid_Fee__c> prepaidFeeOnLoanList){
        for(loan__Contract_Pre_Paid_Fee__c eachFeeOnLoanApplication: prepaidFeeOnLoanList){
            //for changing in fee amount on fees.
            if(feeNameSet.contains(eachFeeOnLoanApplication.loan__Fee_Name__c) && (eachFeeOnLoanApplication.loan__Amount__c != feeNameVsAmountMap.get(eachFeeOnLoanApplication.loan__Fee_Name__c))){
                eachFeeOnLoanApplication.loan__Amount__c = feeNameVsAmountMap.get(eachFeeOnLoanApplication.loan__Fee_Name__c);
                newPrepaidFeeOnLoanList.add(eachFeeOnLoanApplication);
            }
            //if fees are deleted on application
            if(!feeNameSet.contains(eachFeeOnLoanApplication.loan__Fee_Name__c)){
                deleteFeesOnLoanList.add(eachFeeOnLoanApplication);
            }
            feeNameSet.remove(eachFeeOnLoanApplication.loan__Fee_Name__c);
        }
    }
    
    /**
    * @description : This helper method Reschedule the loan.
    * @author Divyam Kumar | 04-13-2024 
    * @param loanAccountIdSet 
    **/
    public static void rescheduleLoanHelper(Set<Id> loanAccountIdSet){
        for(Id loanAccountIdObj: loanAccountIdSet){
            loan.RegenerateAmortizationScheduleCtrl.regenerateAmortizationSchedule(loanAccountIdObj);
        }
    }

    /**
    * @description : This method checks whether maf or initial fee is present then it get's updated based on loan amount of application.
    * @author Divyam Kumar | 04-23-2024 
    * @param appIdVsClCommonFeeListMap 
    **/
    public static void updateMafAndInitialFeeOnApplication(Map<Id, List<clcommon__Fee__c>> appIdVsClCommonFeeListMap){
        List<clcommon__Fee__c> clCommonFeeOnAppList = new List<clcommon__Fee__c>();
        for(Id applicationId: appIdVsClCommonFeeListMap.keyset()){
            clCommonFeeOnAppList = appIdVsClCommonFeeListMap.get(applicationId);
            if(!clCommonFeeOnAppList.isEmpty()){
                for(clcommon__Fee__c clcommonFeeObj: clCommonFeeOnAppList){
                    if(clcommonFeeObj.Fee_Name__c.equals(MANAGEMENT_FEE)){
                        clcommonFeeObj.clcommon__Original_Amount__c = ((clcommonFeeObj.genesis__Application__r.MAF_rate__c*clcommonFeeObj.genesis__Application__r.genesis__Loan_Amount__c)/1200).setScale(2);
                    }
                    if(clcommonFeeObj.Fee_Name__c.equals(INITIAL_ARRANGEMENT_FEE)){
                        clcommonFeeObj.clcommon__Original_Amount__c = (clcommonFeeObj.clcommon__Fee_Definition__r.clcommon__Amount__c*clcommonFeeObj.genesis__Application__r.genesis__Loan_Amount__c*ZERO_POINT_ZERO_ONE).setScale(2);
                    }
                }
            }
        }
        SecureDMLUtil.updateSObject(clCommonFeeOnAppList, true, AccessLevel.SYSTEM_MODE);
    }
}