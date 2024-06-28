/**
 * @description       : 
 * @author            : Supriyo Seni
 * @group             : 
 * @last modified on  : 06-21-2024
 * @last modified by  : Supriyo Seni
**/
public without sharing class ExportPaymentHistoryInPDFController{
    public class ContractDetails{
        public Date sodDate{get;set;}\
        public String contactName{get;set;}
        public String currentStreet{get;set;}
        public String currentCity{get;set;}
        public String zipCode{get;set;}
        public String appNumber{get;set;}
        public String accountNumber{get;set;}
        public String todaysBalance{get;set;}
        public ContractDetails(Date sodDate, String contactName, String currentStreet, String currentCity, String zipCode, String appNumber, String accountNumber, String todaysBalance){
            this.sodDate = sodDate;
            this.contactName = contactName;
            this.currentStreet = currentStreet;
            this.currentCity = currentCity;
            this.zipCode = zipCode;
            this.appNumber = appNumber;
            this.accountNumber = accountNumber;
            this.todaysBalance = todaysBalance;
        }
    }
    public class LptDetails{
        public Date txnDate{get;set;}
        public String paymentType{get;set;}
        public String paymentMode{get;set;}
        public String txnAmt{get;set;}
        public String principal{get;set;}
        public String interest{get;set;}
        public String fees{get;set;}
        public String balance{get;set;}
        public String excess{get;set;}
        public Date reversalDate{get;set;}
        public LptDetails(Date txnDate, String paymentType, String paymentMode, String txnAmt, String principal, String interest, String fees, String balance, String excess, Date reversalDate){
            this.txnDate = txnDate;
            this.paymentType = paymentType;
            this.paymentMode = paymentMode;
            this.txnAmt = txnAmt;
            this.principal = principal;
            this.interest = interest;
            this.fees = fees;
            this.balance = balance;
            this.excess = excess;
            this.reversalDate = reversalDate;
        }
    }
    public class Bills{
        public Date dueDate{get;set;}
        public String dueAmt{get;set;}
        public Date paymentDate{get;set;}
        public String paymentAmt{get;set;}
        public Bills(Date dueDate, String dueAmt, Date paymentDate, String paymentAmt){
            this.dueDate = dueDate;
            this.dueAmt = dueAmt;
            this.paymentDate = paymentDate;
            this.paymentAmt = paymentAmt;
        }
    }
    public class Fees{
        public Date feeDate{get;set;}
        public String feeType{get;set;}
        public String totalAmtDue{get;set;}
        public String paidAmt{get;set;}
        public Fees(Date feeDate, String feeType, String totalAmtDue, String paidAmt){
            this.feeDate = feeDate;
            this.feeType = feeType;
            this.totalAmtDue = totalAmtDue;
            this.paidAmt = paidAmt;
        }
    }
    public List<ContractDetails> borrowerInfo {get; set;}
    public List<LptDetails> paymentHistory {get; set;}
    public List<Bills> billList {get; set;}
    public List<Fees> feeList {get; set;}
    public void downloadAsPDF(){
        try{
            loan__Loan_Account__c loanAccount;
            List<loan__Loan_Payment_Transaction__c> allLpts;
            List<loan__Loan_account_Due_Details__c> allBills;
            List<loan__Charge__c> allFees;
            borrowerInfo = new List<ContractDetails>();
            paymentHistory = new List<LptDetails>();
            billList = new List<Bills>();
            feeList = new List<Fees>();
            String contractId;
            Date currentSysDate = (Test.isRunningTest()
                ? Date.Today()
                : (new loan.GlobalLoanUtilFacade()).getCurrentSystemDate());

            contractId = String.valueOf(System.currentPagereference().getParameters().get(PortalConstants.CONTRACT_ID));
            if(contractId != null) {
                loanAccount = getContract(contractId);
                allLpts = getLptList(contractId);
                allBills = getBills(contractId);
                allFees = getFees(contractId);
                borrowerInfo.add(new ContractDetails(currentSysDate,
                String.valueof(loanAccount.loan__Contact__r.Name),
                String.valueof(loanAccount.loan__Contact__r.clcommon__Current_Street__c),
                String.valueof(loanAccount.loan__Contact__r.clcommon__Current_City__c),
                String.valueof(loanAccount.loan__Contact__r.clcommon__Current_Zip_Code__c),
                String.valueof(loanAccount.Application__r.Name),
                String.valueof(loanAccount.Name),
                String.valueof(loanAccount.loan__Pay_Off_Amount_As_Of_Today__c)
                ));
                if(allLpts.size() > 0){
                    for(loan__Loan_Payment_Transaction__c lpt : allLpts){
                        paymentHistory.add(new LptDetails(Date.valueOf(lpt.loan__Transaction_Date__c),
                        String.valueof(lpt.loan__Payment_Type__c),
                        String.valueof(lpt.loan__Payment_Mode__r.Name),
                        String.valueof(lpt.loan__Transaction_Amount__c),
                        String.valueof(lpt.loan__Principal__c),
                        String.valueof(lpt.loan__Interest__c),
                        String.valueof(lpt.loan__Fees__c),
                        String.valueof(lpt.loan__Balance__c),
                        String.valueof(lpt.loan__Excess__c),
                        Date.valueOf(lpt.Reversal_Date__c)
                        ));
                    }
                }
                if(allBills.size() > 0){
                    for(loan__Loan_account_Due_Details__c bill : allBills){
                        billList.add(new Bills(Date.valueOf(bill.loan__Due_Date__c),
                        String.valueof(bill.loan__Due_Amt__c),
                        Date.valueof(bill.loan__Payment_Date__c),
                        String.valueof(bill.loan__Payment_Amt__c)
                        ));
                    }
                }
                if(allFees.size() > 0){
                    for(loan__Charge__c fee : allFees){
                        feeList.add(new Fees(Date.valueOf(fee.loan__Date__c),
                        String.valueof(fee.loan__Fee__r.Name),
                        String.valueof(fee.loan__Total_Amount_Due__c),
                        String.valueof(fee.loan__Paid_Amount__c)
                        ));
                    }
                }
            } else {
                throw new CustomException(CLXConstants.CONTRACT_ID_NULL);
            }
            String filename = CLXConstants.PAYMENT_HISTORY_PDF;
            Apexpages.currentPage().getHeaders().put(CLXConstants.CONTENT_DISPOSITION, CLXConstants.ATTACHEMNT_FILENAME + filename);
        } catch(Exception e){
            ExceptionLog.insertBatchLog(ExportPaymentHistoryInPDFController.class.getname(), e);
        }
    }
    //fetches LPTs
    public static List<loan__Loan_Payment_Transaction__c> getLptList(String contractId){
        List<loan__Loan_Payment_Transaction__c> lptList = [SELECT loan__Transaction_Date__c,
                                                                    loan__Payment_Type__c,
                                                                    loan__Payment_Mode__r.Name,
                                                                    loan__Transaction_Amount__c,
                                                                    loan__Principal__c,
                                                                    loan__Interest__c,
                                                                    loan__Fees__c,
                                                                    loan__Balance__c,
                                                                    loan__Excess__c,
                                                                    Reversal_Date__c
                                                            FROM loan__Loan_Payment_Transaction__c
                                                            WHERE loan__Loan_Account__c = :contractId
                                                            AND loan__waived__c = false
                                                            AND loan__Rejected__c = false
                                                            AND loan__Payment_Type__c =:CLXConstants.REGULAR];
        return lptList;
    }
    //fetches contract
    public static loan__Loan_Account__c getContract(String contractId){
        loan__Loan_Account__c loanAccount = [SELECT Id,
                                                loan__Contact__r.Name,
                                                loan__Contact__r.clcommon__Current_Street__c,
                                                loan__Contact__r.clcommon__Current_City__c,
                                                loan__Contact__r.clcommon__Current_Zip_Code__c,
                                                Application__r.Name,
                                                Name,
                                                loan__Pay_Off_Amount_As_Of_Today__c
                                            FROM loan__Loan_Account__c
                                            WHERE Id = :contractId];
        return loanAccount;
    }
    //fetches bills
    public static List<loan__Loan_account_Due_Details__c> getBills(String contractId){
        List<loan__Loan_account_Due_Details__c> bills = [SELECT Id,
                                                            loan__Due_Date__c,
                                                            loan__Due_Amt__c,
                                                            loan__Payment_Date__c,
                                                            loan__Payment_Amt__c                                               
                                                        FROM loan__Loan_account_Due_Details__c
                                                        WHERE loan__Loan_Account__c = :contractId];
        return bills;
    }
    //fetches fees
    public static List<loan__Charge__c> getFees(String contractId){
        List<loan__Charge__c> fees = [SELECT Id,
                                            loan__Date__c,
                                            loan__Fee__r.Name,
                                            loan__Total_Amount_Due__c,
                                            loan__Paid_Amount__c                                               
                                        FROM loan__Charge__c
                                        WHERE loan__Loan_Account__c = :contractId];
        return fees;
    }
}