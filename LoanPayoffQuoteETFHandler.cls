/******************************************************************************
* @Company     :    CloudKaptan Consultancy Services Pvt. Ltd.
* @Author      :    Megha Kumari
* @Date        :    31/07/2023
* @Group       :    Hnadler Class 
* @Description :    This class contains the method to calculate the Insurance Rebate Amount & Early Termination Fee Amount 
                    to calculate the sum total of payoff amount .

******************************************************************************/

/******************************************************************************
* MODIFICATION LOG
* Version         Developer         Date            Description
******************************************************************************
* 1.0             Megha Kumari      31/07/2023      Initial Creation
******************************************************************************/

public with sharing class LoanPayoffQuoteETFHandler {
    public static boolean runOnce = TRUE;
    public static string TYPE_1 = 'TYPE1';
    public static string TYPE_2 = 'TYPE2';
    public static string PERSONAL_LOAN_FIXED_Rate = 'Personal Loan Fixed Rate';
    public static string SECURED_LOAN_FIXED_RATE = 'Secured Loan Fixed Rate';
    public static string MOTOR_LOAN_FIXED_RATE ='Motor Loan Fixed Rate';
    public static Integer TWELVE_THOUSAND = 12000;
    public static void afterInsert(Map<Id,loan__Payoff_Quote__c> newPayoffQuotes) {
        List<loan__Payoff_Quote__c> payOffQuoteList = new List<loan__Payoff_Quote__c> ();
        List<loan__Payoff_Quote__c> payOffQuoteListUp = new List<loan__Payoff_Quote__c> ();
        Set<String> loanListSet = new Set<String>();
        List<Insurance__c> insuranceList = new List<Insurance__c>();
        Decimal rebateTotalForActivePolicies = 0;
        Decimal etfAmount = 0;
        List<String> etfAmountList = (system.label.ETF_Amount).split(',');
        if(runOnce){
            runOnce= FALSE;
            for(Id recordId : newPayoffQuotes.keyset()){
                if(newPayoffQuotes.get(recordId).loan__Loan_Account__c != NULL){
                    loanListSet.add(newPayoffQuotes.get(recordId).loan__Loan_Account__c);
                }
            }
            payOffQuoteList = [SELECT id,
                                    name,
                                    Total_of_Insurance_rebates__c,
                                    loan__Loan_Account__c,
                                    loan__Poq_Principal_Bal__c,
                                    loan__Poq_Total_Payoff_Amount__c,
                                    loan__Poq_valid_till_Dt__c
                                FROM loan__Payoff_Quote__c
                                WHERE id IN : newPayoffQuotes.keySet()];

            insuranceList = [SELECT id,
                                name,
                                Loan_Account__c,
                                Product__c,
                                Premium_Rebate_Amount_Net__c,
                                Premium_Rebate_Amount_GST__c,
                                Premium_Rebate_Amount_S_Duty__c,
                                User_Defined_Policy_Status__c,
                                Premium_Rebate_Amount_Gross__c,
                                Policy_Status__c
                            FROM Insurance__c
                            WHERE Policy_Status__c =: InsuranceConstants.ACTIVE
                            AND Loan_Account__r.id IN : loanListSet];
            if(insuranceList != null && insuranceList.size()>0){
                for(Insurance__c ins : insuranceList){
                    //Sum of Rebate Amount Gross of all the insurance of a loan
                    rebateTotalForActivePolicies += ins.Premium_Rebate_Amount_Gross__c;
                }
            }
            // Calculate Early termination Fee 
            List<loan__Loan_Account__c> loanAcc = [Select id,
                                                        name,
                                                        Perpetual_Loan_Product_Name__c,
                                                        loan__Loan_Amount__c,
                                                        loan__Disbursal_Date__c,
                                                        loan__Term_Cur__c,
                                                        isMigrated__c,
                                                        Early_Termination_Fee_Type__c,
                                                        loan__Maturity_Date_Current__c
                                                    FROM loan__Loan_Account__c
                                                    WHERE id IN : loanListSet];
    
            for(loan__Loan_Account__c itr:loanAcc){
                Integer monthsleft = Integer.valueOf(((payOffQuoteList[0].loan__Poq_valid_till_Dt__c).daysbetween(itr.loan__Maturity_Date_Current__c))/30.43685);
                if(itr.isMigrated__c){
                    //Calculate the Early termination Fee Amount on the basis of ETF Fee Type
                    if(itr.Early_Termination_Fee_Type__c == TYPE_1){
                        if(monthsleft<=6){
                            etfAmount = Decimal.valueof(etfAmountList[0]);
                        }else{
                            if(monthsleft<=((itr.loan__Term_Cur__c)/2)){
                                etfAmount = Decimal.valueof(etfAmountList[1]);
                            }else{
                                etfAmount = Decimal.valueof(etfAmountList[2]);
                            }
                        }
                    }else if(itr.Early_Termination_Fee_Type__c == TYPE_2){
                        if(monthsleft<=((itr.loan__Term_Cur__c)/2)){
                            etfAmount = Decimal.valueof(etfAmountList[3]);
                        }else{
                            etfAmount = Decimal.valueof(etfAmountList[0]);
                        }
                    }
                }
                //Calculate the Early termination Fee Amount on the basis of Product Name 
                else if((itr.Perpetual_Loan_Product_Name__c== PERSONAL_LOAN_FIXED_Rate
                            || itr.Perpetual_Loan_Product_Name__c== SECURED_LOAN_FIXED_RATE) && monthsleft>3){ 
                        etfAmount = Decimal.valueof(etfAmountList[4]);
                }
                //Calculate the Early termination Fee Amount on the basis of Product Name , Disbursal date & Loan Amount 
                else if(itr.Perpetual_Loan_Product_Name__c==MOTOR_LOAN_FIXED_RATE){
                    if(itr.loan__Disbursal_Date__c>=(Date.newInstance(2022,04,01))){
                        etfAmount = Decimal.valueof(etfAmountList[5]);
                    }else if(itr.loan__Disbursal_Date__c<=(Date.newInstance(2022,03,31)) && itr.loan__Loan_Amount__c>TWELVE_THOUSAND){
                        etfAmount = ((Decimal.valueof(etfAmountList[5]))*monthsleft)/itr.loan__Term_Cur__c;
                    }else if(itr.loan__Disbursal_Date__c<=(Date.newInstance(2022,03,31)) && itr.loan__Loan_Amount__c<TWELVE_THOUSAND){
                        etfAmount = ((itr.loan__Loan_Amount__c*(Decimal.valueof(etfAmountList[6])))*monthsleft)/itr.loan__Term_Cur__c;
                    }
                }
            }
            for(Id recordId : newPayoffQuotes.keyset()){
                if(payOffQuoteList != null && payOffQuoteList.size()>0){
                    for(loan__Payoff_Quote__c payOffQuote : payOffQuoteList){
                        payOffQuote.Total_of_Insurance_rebates__c = -rebateTotalForActivePolicies;
                        if(rebateTotalForActivePolicies != 0){
                            payOffQuote.loan__Poq_Total_Payoff_Amount__c = payOffQuote.loan__Poq_Total_Payoff_Amount__c - rebateTotalForActivePolicies;
                        }
                        if(etfAmount != 0){
                            payOffQuote.loan__Poq_Prepayment_Penalty__c = etfAmount;
                            payOffQuote.loan__Poq_Total_Payoff_Amount__c = payOffQuote.loan__Poq_Total_Payoff_Amount__c +etfAmount;
                        }
                        payOffQuoteListUp.add(payOffQuote);
                    }
                }
            }
            update payOffQuoteListUp;
            runOnce = TRUE;
        }
    }
}