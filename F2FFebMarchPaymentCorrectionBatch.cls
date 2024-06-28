/**
 * @description                : 
 * @author                     : Anshu Kumari Mahato
 * @group                      : 
 * @last modified on           : 02-19-2024
 * @last modified by           : Supriyo Seni
 * @last modification details  :  
 * Modifications Log
 * Ver   Date         Author                Modification
 * 1.0   06-02-2024   Anshu Kumari Mahato   Initial Version
**/
public without sharing class F2FFebMarchPaymentCorrectionBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    /**
    * @description 
    * @author Anshu Kumari Mahato | 06-02-2024 
    * @param batchableContext 
    * @return Database.QueryLocator 
    **/
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        return Database.getQueryLocator([SELECT Id, 
                                                    Name,
                                                    loan__Due_Day__c,
                                                    loan__Previous_Installment_Date__c,
                                                    loan__Interest_Posted__c,
                                                    Loans_corrected_for_Feb__c,
                                                    Loans_corrected_for_March__c,
                                                    loan__Principal_Remaining__c,
                                                    loan__Interest_Rate__c,
                                                    loan__Last_Interest_Posting_Date__c,
                                                    Previous_Values_Transaction_Summary__c,
                                                    (SELECT Id, name,
                                                        loan__Due_Amt__c,
                                                        loan__Loan_Account__r.name,
                                                        loan__DD_Primary_Flag__c,
                                                        loan__Transaction_Date__c,
                                                        bills_corrected_for_feb__c,
                                                        bills_corrected_for_march__c,
                                                        Previous_Values_Transaction_Summary__c 
                                                        FROM loan__Dues_Details__r 
                                                        WHERE loan__DD_Primary_Flag__c = true 
                                                        AND loan__Rescheduled_flag__c = false
                                                        AND bills_corrected_for_march__c = false
                                                        AND bills_corrected_for_feb__c = false),
                                                    (SELECT id, Name,
                                                        loan__Loan_Account__r.Name,
                                                        loan__Sent_to_ACH__c,
                                                        loan__Sent_To_ACH_On__c,
                                                        loan__ACH_Filename__c,
                                                        loan__Transaction_Amount__c,
                                                        LPT_corrected_for_feb__c,
                                                        LPT_corrected_for_march__c,
                                                        loan__Transaction_Date__c,
                                                        loan__Automated_Payment_Setup__c,
                                                        Previous_Values_Transaction_Summary__c,
                                                        loan__Loan_Account__r.loan__Principal_Remaining__c,
                                                        loan__Loan_Account__r.loan__Interest_Rate__c 
                                                        FROM loan__Loan_Payment_Transactions__r 
                                                        WHERE loan__Loan_Account__r.loan__Due_Day__c > 28 
                                                        AND(CALENDAR_MONTH(loan__Transaction_Date__c) =2 OR CALENDAR_MONTH(loan__Transaction_Date__c) = 3) 
                                                        and loan__Loan_Account__r.loan__Invalid_Data__c =false 
                                                        and loan__Automated_Payment_Setup__r.loan__Amount_Type__c ='LAST BILLED AMOUNT'
                                                        and loan__Loan_Account__r.loan__Loan_Status__c != 'Closed - Obligations met' 
                                                        and loan__Cleared__c = false 
                                                        and loan__Rejected__c = false
                                                        and loan__Reversed__c = false 
                                                        AND LPT_corrected_for_feb__c = false 
                                                        AND LPT_corrected_for_march__c = false),
                                                    (SELECT id, name,
                                                        loan__Loan_Contract__r.name,
                                                        loan__Due_Amount__c,
                                                        loan__Interest_Posted__c,
                                                        loan__Principal_Posted__c,
                                                        loan__Transaction_Due_Date__c,
                                                        loan__Loan_Contract__r.loan__Principal_Remaining__c,
                                                        loan__Loan_Contract__r.loan__Interest_Rate__c,
                                                        IPT_corrected_for_feb__c,
                                                        IPT_corrected_for_march__c,
                                                        Previous_Values_Transaction_Summary__c
                                                        FROM loan__Interest_Posting_Transactions__r
                                                        WHERE loan__Loan_Contract__r.loan__Due_Day__c >28
                                                        AND loan__Loan_Contract__r.loan__Invalid_Data__c =false
                                                        AND IPT_corrected_for_feb__c = false
                                                        AND IPT_corrected_for_march__c = false 
                                                        AND(CALENDAR_MONTH( loan__Transaction_Due_Date__c) = 2 OR CALENDAR_MONTH(loan__Transaction_Due_Date__c) = 3)),
                                                    (SELECT Id,
                                                        loan__Certificate_Rate__c,
                                                        loan__Status__c,
                                                        loan__Inv_Actual_Interest_Posted__c,
                                                        loan__Remaining_Investment_Amount__c,
                                                        loan__Last_Transaction_Type__c,
                                                        loan__Loan__r.loan__Last_Interest_Posting_Date__c,
                                                        IO_corrected_for_feb__c,
                                                        IO_corrected_for_march__c,
                                                        Previous_Values_Transaction_Summary__c
                                                        FROM loan__Investors_Loans__r 
                                                        WHERE loan__Status__c =: Folk2FolkConstantValues.ACTIVE_STATUS
                                                        AND IO_corrected_for_feb__c = false 
                                                        AND IO_corrected_for_march__c = false)
                                                        FROM loan__Loan_Account__c 
                                                        WHERE loan__Invalid_Data__c = false 
                                                        AND loan__Due_Day__c > 28
                                                        AND Loans_corrected_for_Feb__c = false 
                                                        AND Loans_corrected_for_March__c = false
                                                        AND(CALENDAR_MONTH(loan__Previous_Installment_Date__c) =2 OR CALENDAR_MONTH(loan__Previous_Installment_Date__c) = 3)]);
                                                }

    /**
    * @description 
    * @author Anshu Kumari Mahato | 06-02-2024 
    * @param batchableContext 
    * @param scope 
    **/
    public void execute(Database.BatchableContext batchableContext, List<loan__Loan_Account__c> scope) {
        
        Date currentSysDate = (!Test.isRunningTest() ? (new loan.GlobalLoanUtilFacade()).getCurrentSystemDate() : Date.today());
        Savepoint sp = Database.setSavepoint();

        try {
            for (loan__Loan_Account__c loanObj : scope) {
                processLoanAccount(currentSysDate, loanObj);
            }
            processInvestorLoanAccountTransactions(currentSysDate, scope);
        } catch (Exception e) {
            Database.rollback(sp);
            // Inserting batch process log
            Loan__Batch_Process_log__c batchLog = F2FUtil.insertBatchProcesslogException(e, F2FFebMarchPaymentCorrectionBatch.class.getName());
            insert batchLog;
        }
    }

    /**
    * @description 
    * @author Anshu Kumari Mahato | 06-02-2024 
    * @param batchableContext 
    **/
    public void finish(Database.BatchableContext batchableContext) {
        F2FLoanPaymentFileGenDagJob job = new F2FLoanPaymentFileGenDagJob();
        Integer size = 1;
        Database.executeBatch(job, size);
    }

    /**
    * @description 
    * @author Anshu Kumari Mahato | 06-02-2024 
    * @param sc 
    **/
    public void execute(SchedulableContext sc) {
        F2FFebMarchPaymentCorrectionBatch job = new F2FFebMarchPaymentCorrectionBatch();
        Integer size = 1;
        Database.executeBatch(job, size);
    }

    /**
    * @description 
    * @author Anshu Kumari Mahato | 06-02-2024 
    * @param currentSysDate 
    * @param loanObj 
    **/
    private void processLoanAccount(Date currentSysDate, loan__Loan_Account__c loanObj) {

        List<loan__Loan_account_Due_Details__c> billList = new List<loan__Loan_account_Due_Details__c>();
        List<loan__Interest_Posting_Transaction__c> iptList = new List<loan__Interest_Posting_Transaction__c>();
        List<loan__Loan_Account__c> contractList = new List<loan__Loan_Account__c>();
        List<loan__Investor_Loan__c> ioList = new List<loan__Investor_Loan__c>();
        List<loan__Loan_Payment_Transaction__c> lptList = new List<loan__Loan_Payment_Transaction__c>();

        //if (loanObj.loan__Previous_Installment_Date__c.month() != 2 || loanObj.loan__Previous_Installment_Date__c.month() != 3) {
            //return;
        //}
        Date previousInstallment = loanObj.loan__Previous_Installment_Date__c.addDays(-11);
        if (currentSysDate == previousInstallment) {
            for (loan__Loan_account_Due_Details__c eachBill : loanObj.loan__Dues_Details__r) {
                if (eachBill.loan__DD_Primary_Flag__c == true && eachBill.loan__Transaction_Date__c.day() >= 17 &&
                    eachBill.loan__Transaction_Date__c.month() == 2 && (currentSysDate.month() == 2 || Test.isRunningTest())) {
                    String previousValue = 'Previous loan__Due_Amt__c=' + eachBill.loan__Due_Amt__c+', '+'Previous bills_corrected_for_feb__c='+eachBill.bills_corrected_for_feb__c;
                    eachBill.loan__Due_Amt__c += calculateInterest(loanObj.loan__Principal_Remaining__c, loanObj.loan__Interest_Rate__c);
                    eachBill.bills_corrected_for_feb__c = true;
                    eachBill.Previous_Values_Transaction_Summary__c = previousValue;
                    billList.add(eachBill);
                    System.debug(billList);
                }
                else if(eachBill.loan__DD_Primary_Flag__c == true && eachBill.loan__Transaction_Date__c.day() >= 17 &&
                eachBill.loan__Transaction_Date__c.month() == 3 && (currentSysDate.month()==3 || Test.isRunningTest())){
                    String previousValue = 'Previous loan__Due_Amt__c=' + eachBill.loan__Due_Amt__c+', '+'Previous bills_corrected_for_march__c='+eachBill.bills_corrected_for_feb__c;
                    eachBill.loan__Due_Amt__c -= calculateInterest(loanObj.loan__Principal_Remaining__c, loanObj.loan__Interest_Rate__c);
                    eachBill.bills_corrected_for_march__c = true;
                    eachBill.Previous_Values_Transaction_Summary__c = previousValue;
                    billList.add(eachBill);
                    System.debug(billList);
                }
            }
            SecureDMLUtil.updateSObject(billList, false, AccessLevel.SYSTEM_MODE);
        }
        if(loanObj.loan__Last_Interest_Posting_Date__c == currentSysDate && loanObj.loan__Last_Interest_Posting_Date__c.month()==2 && (currentSysDate.month()==2 || Test.isRunningTest())){
            String previousValue = 'Previous loan__Interest_Posted__c=' + loanObj.loan__Interest_Posted__c+', '+'Previous Loans_corrected_for_Feb__c='+loanObj.Loans_corrected_for_Feb__c;
            loanObj.loan__Interest_Posted__c += calculateInterest(loanObj.loan__Principal_Remaining__c, loanObj.loan__Interest_Rate__c);
            loanObj.Loans_corrected_for_Feb__c = true;
            loanObj.Previous_Values_Transaction_Summary__c = previousValue;
            contractList.add(loanObj);
            SecureDMLUtil.updateSObject(contractList, false, AccessLevel.SYSTEM_MODE);
            System.debug(contractList);
        }

        else if(loanObj.loan__Last_Interest_Posting_Date__c == currentSysDate && loanObj.loan__Last_Interest_Posting_Date__c.month()==3 && (currentSysDate.month()==3 || Test.isRunningTest())){
            String previousValue = 'Previous loan__Interest_Posted__c=' + loanObj.loan__Interest_Posted__c+', '+'Previous Loans_corrected_for_March__c='+loanObj.Loans_corrected_for_March__c;
            loanObj.loan__Interest_Posted__c -= calculateInterest(loanObj.loan__Principal_Remaining__c, loanObj.loan__Interest_Rate__c);
            loanObj.Loans_corrected_for_March__c = true;
            loanObj.Previous_Values_Transaction_Summary__c = previousValue;
            contractList.add(loanObj);
            SecureDMLUtil.updateSObject(contractList, false, AccessLevel.SYSTEM_MODE);
            System.debug(contractList);
        }
        
        for (loan__Interest_Posting_Transaction__c eachIpt : loanObj.loan__Interest_Posting_Transactions__r) {
            if (eachIpt.loan__Transaction_Due_Date__c == currentSysDate && eachIpt.loan__Transaction_Due_Date__c.month()== 2 && (currentSysDate.month()==2|| Test.isRunningTest())) {
                String previousValue = 'Previous loan__Interest_Posted__c=' + eachIpt.loan__Interest_Posted__c+', '+'Previous loan__Principal_Posted__c='+eachIpt.loan__Principal_Posted__c+', '+'Previous loan__Due_Amount__c='+eachIpt.loan__Due_Amount__c+', '+'Previous IPT_corrected_for_feb__c='+eachIpt.IPT_corrected_for_feb__c;
                eachIpt.loan__Interest_Posted__c += calculateInterest(eachIpt.loan__Loan_Contract__r.loan__Principal_Remaining__c,
                eachIpt.loan__Loan_Contract__r.loan__Interest_Rate__c);
                Decimal calcValue = (Decimal.valueOf(String.valueOf(eachIpt.loan__Due_Amount__c)) - (eachIpt.loan__Principal_Posted__c));
                eachIpt.loan__Due_Amount__c = calcValue + (calculateInterest(eachIpt.loan__Loan_Contract__r.loan__Principal_Remaining__c,
                eachIpt.loan__Loan_Contract__r.loan__Interest_Rate__c));
                eachIpt.loan__Principal_Posted__c = 0.00;
                eachIpt.IPT_corrected_for_feb__c = true;
                eachIpt.Previous_Values_Transaction_Summary__c = previousValue;
            iptList.add(eachIpt);
            System.debug(iptList);
            }
            else if (eachIpt.loan__Transaction_Due_Date__c == currentSysDate && eachIpt.loan__Transaction_Due_Date__c.month()== 3 && (currentSysDate.month()==3|| Test.isRunningTest())) {
                String previousValue = 'Previous loan__Interest_Posted__c = ' + eachIpt.loan__Interest_Posted__c+', '+'Previous loan__Principal_Posted__c = '+eachIpt.loan__Principal_Posted__c +', '+'Previous loan__Due_Amount__c = '+eachIpt.loan__Due_Amount__c+', '+'Previous IPT_corrected_for_march__c = '+ eachIpt.IPT_corrected_for_march__c;
                eachIpt.loan__Interest_Posted__c -= calculateInterest(eachIpt.loan__Loan_Contract__r.loan__Principal_Remaining__c,
                eachIpt.loan__Loan_Contract__r.loan__Interest_Rate__c);
                Decimal calcValue = (Decimal.valueOf(String.valueOf(eachIpt.loan__Due_Amount__c)) - (eachIpt.loan__Principal_Posted__c));
                eachIpt.loan__Due_Amount__c = calcValue - (calculateInterest(eachIpt.loan__Loan_Contract__r.loan__Principal_Remaining__c,
                eachIpt.loan__Loan_Contract__r.loan__Interest_Rate__c));
                eachIpt.loan__Principal_Posted__c = 0.00;
                eachIpt.IPT_corrected_for_march__c = true;
                eachIpt.Previous_Values_Transaction_Summary__c = previousValue;
            iptList.add(eachIpt);
            System.debug(iptList);
            }
        }
        SecureDMLUtil.updateSObject(iptList, false, AccessLevel.SYSTEM_MODE);

        for (loan__Investor_Loan__c eachIo : loanObj.loan__Investors_Loans__r) {
            if (eachIo.loan__Last_Transaction_Type__c == 'Interest Posting Transaction' &&
                eachIo.loan__Loan__r.loan__Last_Interest_Posting_Date__c == currentSysDate && eachIo.loan__Loan__r.loan__Last_Interest_Posting_Date__c.month()== 2 && (currentSysDate.month()== 2|| Test.isRunningTest())) {
                String previousValue = 'Previous loan__Inv_Actual_Interest_Posted__c=' + eachIo.loan__Inv_Actual_Interest_Posted__c+', '+'Previous IO_corrected_for_feb__c='+eachIo.IO_corrected_for_feb__c;
                eachIo.loan__Inv_Actual_Interest_Posted__c += calculateInterest(eachIo.loan__Remaining_Investment_Amount__c,
                    eachIo.loan__Certificate_Rate__c);
                eachIo.IO_corrected_for_feb__c = true;
                eachIo.Previous_Values_Transaction_Summary__c = previousValue;
                    ioList.add(eachIo);
                    System.debug(ioList);
            }
            else if (eachIo.loan__Last_Transaction_Type__c == 'Interest Posting Transaction' &&
            eachIo.loan__Loan__r.loan__Last_Interest_Posting_Date__c == currentSysDate && eachIo.loan__Loan__r.loan__Last_Interest_Posting_Date__c.month()== 3 && (currentSysDate.month()==3 || Test.isRunningTest())) {
            String previousValue = 'Previous loan__Inv_Actual_Interest_Posted__c=' + eachIo.loan__Inv_Actual_Interest_Posted__c+', '+'Previous IO_corrected_for_march__c='+eachIo.IO_corrected_for_march__c;
            eachIo.loan__Inv_Actual_Interest_Posted__c -= calculateInterest(eachIo.loan__Remaining_Investment_Amount__c,
                eachIo.loan__Certificate_Rate__c);
            eachIo.IO_corrected_for_march__c = true;
            eachIo.Previous_Values_Transaction_Summary__c = previousValue;
                ioList.add(eachIo);
                System.debug(ioList);
        }
        }
        SecureDMLUtil.updateSObject(ioList, false, AccessLevel.SYSTEM_MODE);
        Date lptCreationDate = loanObj.loan__Previous_Installment_Date__c.addDays(-9);
        if (currentSysDate == lptCreationDate) {
        for (loan__Loan_Payment_Transaction__c eachLpt : loanObj.loan__Loan_Payment_Transactions__r) {
            if (eachLpt.loan__Transaction_Date__c.month() == 2 && eachLpt.loan__Automated_Payment_Setup__c != null && (currentSysDate.month()== 2 || Test.isRunningTest())){
                String previousValue = 'Previous loan__Transaction_Amount__c=' + eachLpt.loan__Transaction_Amount__c +', '+'Previous LPT_corrected_for_feb__c='+eachLpt.LPT_corrected_for_feb__c;
                eachLpt.loan__Transaction_Amount__c += calculateInterest(eachLpt.loan__Loan_Account__r.loan__Principal_Remaining__c,
                eachLpt.loan__Loan_Account__r.loan__Interest_Rate__c);
                eachLpt.LPT_corrected_for_feb__c = true;
                eachLpt.Previous_Values_Transaction_Summary__c = previousValue;
                eachLpt.loan__Sent_to_ACH__c = false;
                eachLpt.loan__Sent_To_ACH_On__c = null;
                eachLpt.loan__ACH_Filename__c = null;
                lptList.add(eachLpt);
                System.debug(lptList);
            }
            else if (eachLpt.loan__Transaction_Date__c.month() == 3 && eachLpt.loan__Automated_Payment_Setup__c != null&& (currentSysDate.month()== 3 || Test.isRunningTest()) ){
                String previousValue = 'Previous loan__Transaction_Amount__c=' + eachLpt.loan__Transaction_Amount__c +', '+'Previous LPT_corrected_for_march__c='+eachLpt.LPT_corrected_for_march__c;
                eachLpt.loan__Transaction_Amount__c -= calculateInterest(eachLpt.loan__Loan_Account__r.loan__Principal_Remaining__c,
                eachLpt.loan__Loan_Account__r.loan__Interest_Rate__c);
                eachLpt.LPT_corrected_for_march__c = true;
                eachLpt.Previous_Values_Transaction_Summary__c = previousValue;
                eachLpt.loan__Sent_to_ACH__c = false;
                eachLpt.loan__Sent_To_ACH_On__c = null;
                eachLpt.loan__ACH_Filename__c = null;
                lptList.add(eachLpt);
                System.debug(lptList);
        }
        }
        SecureDMLUtil.updateSObject(lptList, false, AccessLevel.SYSTEM_MODE);
    }
    }

    /**
    * @description 
    * @author Anshu Kumari Mahato | 06-02-2024 
    * @param currentSysDate 
    * @param scope 
    **/
    private void processInvestorLoanAccountTransactions(Date currentSysDate, List<loan__Loan_Account__c> scope) {
        List<loan__Investor_Loan_Account_Txns__c> iltList = [SELECT id,
                                                                    name, 
                                                                    loan__Txn_Amount__c, 
                                                                    loan__Investor_Loan__r.loan__Share__c, 
                                                                    loan__Investor_Loan__r.loan__Share_rounded__c, 
                                                                    loan__Investor_Loan__r.Name, 
                                                                    loan__Investor_Loan__r.loan__Loan__r.name, 
                                                                    loan__Investor_Loan__r.loan__Remaining_Investment_Amount__c,
                                                                    loan__Investor_Loan__r.loan__Certificate_Rate__c,
                                                                    loan__Interest_Posted__c,
                                                                    loan__Investor_Loan__r.loan__Loan__r.loan__Last_Interest_Posting_Date__c,
                                                                    loan__Transaction_Date__c,
                                                                    ILT_Corrected_for_feb__c,
                                                                    ILT_Corrected_for_march__c
                                                            FROM loan__Investor_Loan_Account_Txns__c
                                                            WHERE loan__Txn_Code__c = 'Interest Posting Transaction'
                                                            AND loan__Investor_Loan__c in :scope[0].loan__Investors_Loans__r
                                                            AND (CALENDAR_MONTH(loan__Transaction_Date__c) = 2 OR CALENDAR_MONTH(loan__Transaction_Date__c) = 3)];
        
        List<loan__Investor_Loan_Account_Txns__c> updateILTList = new List<loan__Investor_Loan_Account_Txns__c>();
        
        for (loan__Investor_Loan_Account_Txns__c eachIlt : iltList) {
            if (eachIlt.loan__Transaction_Date__c == currentSysDate && 
                eachIlt.loan__Investor_Loan__r.loan__Loan__r.loan__Last_Interest_Posting_Date__c == currentSysDate && eachIlt.loan__Transaction_Date__c.month()== 2 && (currentSysDate.month()==2 || Test.isRunningTest())) {
                String previousValue = 'Previous loan__Interest_Posted__c=' + eachIlt.loan__Interest_Posted__c +', '+'Previous loan__Txn_Amount__c='+eachIlt.loan__Txn_Amount__c+', '+'Previous ILT_Corrected_for_feb__c='+eachIlt.ILT_Corrected_for_feb__c;
                eachIlt.loan__Interest_Posted__c += calculateInterest(eachIlt.loan__Investor_Loan__r.loan__Remaining_Investment_Amount__c,
                    eachIlt.loan__Investor_Loan__r.loan__Certificate_Rate__c);
                eachIlt.loan__Txn_Amount__c += calculateInterest(eachIlt.loan__Investor_Loan__r.loan__Remaining_Investment_Amount__c,
                    eachIlt.loan__Investor_Loan__r.loan__Certificate_Rate__c);
                eachIlt.ILT_Corrected_for_feb__c = true;
               // eachIlt.Previous_Values_Transaction_Summary__c = previousValue;
                    updateILTList.add(eachIlt);
                    System.debug(updateILTList);

            }
            else if (eachIlt.loan__Transaction_Date__c == currentSysDate && 
            eachIlt.loan__Investor_Loan__r.loan__Loan__r.loan__Last_Interest_Posting_Date__c == currentSysDate && eachIlt.loan__Transaction_Date__c.month()== 3&& (currentSysDate.month()==3|| Test.isRunningTest())) {
            String previousValue = 'Previous loan__Interest_Posted__c=' + eachIlt.loan__Interest_Posted__c +', '+'Previous loan__Txn_Amount__c='+eachIlt.loan__Txn_Amount__c+', '+'Previous ILT_Corrected_for_march__c='+eachIlt.ILT_Corrected_for_march__c;
            eachIlt.loan__Interest_Posted__c -= calculateInterest(eachIlt.loan__Investor_Loan__r.loan__Remaining_Investment_Amount__c,
                eachIlt.loan__Investor_Loan__r.loan__Certificate_Rate__c);
            eachIlt.loan__Txn_Amount__c -= calculateInterest(eachIlt.loan__Investor_Loan__r.loan__Remaining_Investment_Amount__c,
                eachIlt.loan__Investor_Loan__r.loan__Certificate_Rate__c);
            eachIlt.ILT_Corrected_for_march__c = true;
                updateILTList.add(eachIlt);
                System.debug(updateILTList);
        }
        }
        SecureDMLUtil.updateSObject(updateILTList, false, AccessLevel.SYSTEM_MODE);
    }

    /**
    * @description 
    * @author Anshu Kumari Mahato | 06-02-2024 
    * @param principal 
    * @param interestRate 
    * @return Decimal 
    **/
    private Decimal calculateInterest(Decimal principal, Decimal interestRate) {

        Date currentSysDate = (!Test.isRunningTest() ? (new loan.GlobalLoanUtilFacade()).getCurrentSystemDate() : Date.today());
        Integer daysInYear = (Math.mod(currentSysDate.year(), 400) == 0) ||
                         (Math.mod(currentSysDate.year(), 4) == 0 && Math.mod(currentSysDate.year(), 100) != 0) ? 366 : 365;
        if(daysInYear == 366){
            return (loan.ValueUtil.round((principal * interestRate / 36000) * 1));
        }
        return (loan.ValueUtil.round((principal * interestRate / 36000) * 2));
        }
}