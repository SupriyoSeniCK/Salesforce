/**
 * @description       : 
 * @author            : Supriyo Seni
 * @group             : 
 * @last modified on  : 02-23-2024
 * @last modified by  : Supriyo Seni
**/
public inherited sharing class F2FEarlyPartialRedemptionIFTDagHelper{
    /**
    * @description 
    * @author Supriyo Seni | 02-23-2024 
    * @return String 
    **/
    public static String startQuery(){
        if (!loan__Fee_Payment__c.sObjectType.getDescribe(SObjectDescribeOptions.FULL).isAccessible()) {
            throw new CustomException(Folk2FolkConstantValues.INSUFFICIENT_ACCESS_TO_FEE_PAYMENTS_OBJECT);
        }
        String feeName = Folk2FolkConstantValues.EARLY_TERMINATION_INTEREST_FEE_TO_INVESTORS;
        String query ='SELECT Id, ' +
                                'Name, ' +
                                'IFT_Created__c, ' +
                                'loan__Transaction_Amount__c, ' +
                                'loan__Loan_Payment_Transaction__c, ' +
                                'loan__Loan_Payment_Transaction__r.loan__Loan_Account__c, ' +
                                'loan__Loan_Payment_Transaction__r.loan__Transaction_Date__c, ' +
                                'loan__Loan_Payment_Transaction__r.loan__Loan_Account__r.Name ' +
                            'FROM loan__Fee_Payment__c ' +
                            'WHERE Fee_Name__c = \''+feeName+'\' ' +
                            'AND loan__Loan_Payment_Transaction__r.loan__Loan_Account__r.loan__Invalid_Data__c = false ' +
                            'AND loan__Loan_Payment_Transaction__r.loan__Loan_Account__c != null ' +
                            'AND loan__Loan_Payment_Transaction__r.loan__Waived__c = false ' +
                            'AND loan__Loan_Payment_Transaction__r.loan__Cleared__c = true ' +
                            'AND loan__Loan_Payment_Transaction__r.loan__Rejected__c = false ' +
                            'AND loan__Loan_Payment_Transaction__r.loan__Reversed__c = false ' +
                            'AND loan__Loan_Payment_Transaction__r.loan__Principal__c > 0 ' +
                            'AND loan__Loan_Payment_Transaction__r.loan__Fees__c > 0 ' +
                            'AND IFT_Created__c = false ' +
                            'AND loan__Cleared__c = true ' +
                            'WITH SYSTEM_MODE';
        return query;
    }

    /**
    * @description 
    * @author Supriyo Seni | 02-23-2024 
    * @param feePaymentList 
    **/
    public void executeHelper(List<loan__Fee_Payment__c> feePaymentList){
        List<Id> lptIdList = new List<Id>();
        public Map<Id, loan__Fee_Payment__c> lptIdVsFeePaymentMap = new Map<Id, loan__Fee_Payment__c>();
        try{
            for(loan__Fee_Payment__c loanFeePaymentObj : feePaymentList){
                lptIdList.add(loanFeePaymentObj.loan__Loan_Payment_Transaction__c);
                lptIdVsFeePaymentMap.put(loanFeePaymentObj.loan__Loan_Payment_Transaction__c,loanFeePaymentObj);
            }
            List<loan__Investor_Loan_Account_Txns__c> investorLoanTxnList = [SELECT id,
                                                                                    Name
                                                                                FROM loan__Investor_Loan_Account_Txns__c
                                                                                WHERE loan__Loan_Payment_Transaction__c IN : lptIdList
                                                                                WITH SYSTEM_MODE];
            if(investorLoanTxnList.isEmpty()){
                throw new CustomException('ILTs Not found');
            }
            loan.ValueUtil.round(((eachILT.loan__Principal_Paid__c / lptIdVsILTPrincipalSumMap.get(eachILT.loan__Loan_Payment_Transaction__c))
                                                                                 * feePayment.loan__Transaction_Amount__c).setScale(2));
            for(loan__Investor_Loan_Account_Txns__c iltObj :investorLoanTxnList ){
                
            }
        }catch(Exception exe) {
            Loan__Batch_Process_log__c log = F2FUtil.insertBatchProcesslogException(exe, F2FEarlyPartialRedemptionIFTDagHelper.class.getName());
            log.loan__Message__c += ' ' + recordId + ' ' + recordName;
            logList.add(log);
            mfiflexUtil.SecureDML.insertRecords(logList, false);
        }
    }

}