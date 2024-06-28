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
* 1.0             Supriyo Seni      31/07/2023      Initial Creation
******************************************************************************/


public with sharing class LoanPayoffQuoteTriggerHandler {
    public static string TYPE_1 = 'TYPE1';
    public static string TYPE_2 = 'TYPE2';
    public static string PERSONAL_LOAN_FIXED_Rate = 'Personal Loan Fixed Rate';
    public static string SECURED_LOAN_FIXED_RATE = 'Secured Loan Fixed Rate';
    public static string MOTOR_LOAN_FIXED_RATE ='Motor Loan Fixed Rate';
    public static Integer TWELVE_THOUSAND = 12000;
    /************************************************************************
     * @Description : This method handles after insert opeartions for LoanPayoffTrigger
     * @params     : map of id and loanPayoftQuote
     * @returnType : void
    *************************************************************************/  
    public static void afterInsert(Map<Id,loan__Payoff_Quote__c> newPayoffQuotes) {
        List<loan__Payoff_Quote__c> payOffQuoteList = new List<loan__Payoff_Quote__c> ();
        Set<String> loanListSet = new Set<String>();
        List<Insurance__c> insuranceList = new List<Insurance__c>();
        List<Insurance__c> insListForMl = new List<Insurance__c>();
        List<Insurance__c> insListForPl = new List<Insurance__c>();
        Map<Id,Decimal> loanIdVsRebate = new Map<Id,Decimal> ();
        Map<Id,Decimal> loanIdVsEtfAmt = new Map<Id,Decimal> ();
        Map<Id,loan__Payoff_Quote__c> loanIdVsPq = new Map<Id,loan__Payoff_Quote__c> ();
        try{
            for(Id recordId : newPayoffQuotes.keyset()){
                loanListSet.add(newPayoffQuotes.get(recordId).loan__Loan_Account__c);
                loanIdVsPq.put(newPayoffQuotes.get(recordId).loan__Loan_Account__c,newPayoffQuotes.get(recordId));
            }
            payOffQuoteList = [SELECT id,
                                        name,
                                        Total_of_Insurance_rebates__c,
                                        loan__Loan_Account__c,
                                        loan__Poq_Principal_Bal__c,
                                        loan__Poq_Total_Payoff_Amount__c,
                                        loan__Poq_valid_till_Dt__c
                            FROM loan__Payoff_Quote__c
                            WHERE id IN : newPayoffQuotes.keySet()
                            WITH SECURITY_ENFORCED];
            insuranceList = [SELECT id,
                                    name,
                                    Loan_Account__c,
                                    Product__c,
                                    Premium_Rebate_Amount_Net__c,
                                    Premium_Rebate_Amount_GST__c,
                                    Premium_Rebate_Amount_S_Duty__c,
                                    User_Defined_Policy_Status__c,
                                    Premium_Rebate_Amount_Gross__c,
                                    Policy_Status__c,
                                    Rebate_Factor__c,
                                    Premium_Amount_Gross__c,
                                    Loan_Product_Name__c
                            FROM Insurance__c
                            WHERE Policy_Status__c NOT IN (:InsuranceConstants.CANCELLED,:InsuranceConstants.EXPIRED)
                            AND Loan_Account__r.id IN : loanListSet
                            WITH SECURITY_ENFORCED];
            // Separating insurances based on Product Type PL or ML
            for(Insurance__c ins : insuranceList){
                if(ins.Loan_Product_Name__c.contains(InsuranceConstants.PERSONAL_LOAN)){
                    insListForPl.add(ins);
                }else if(ins.Loan_Product_Name__c.contains(InsuranceConstants.MOTOR_LOAN)){
                    insListForMl.add(ins);
                }
            }
            loanIdVsRebate = getRebateAmtMap(loanIdVsRebate,insListForPl); 
            if(insListForMl != null && insListForMl.size()>0 && updateInsFormulas(insListForMl,loanIdVsPq)){
                loanIdVsRebate = getRebateAmtMap(loanIdVsRebate,insListForMl);
            }
            loanIdVsEtfAmt = calculateETFAmount(loanListSet,loanIdVsPq);
            // Update Payoff Quote with applicable Insurance Rebate Amount and etf amount
            updatePayoffQuote(payOffQuoteList,loanIdVsRebate,loanIdVsEtfAmt);
        }catch(Exception ex) {
            ExceptionManager.manageException(ex);
        }
    }

    /************************************************************************
     * @Description : This method returns a map which stores loanId Vs applicable rebate amount
     * @params     : map of id and Decimal AND Insurance List
     * @returnType : map of id and Decimal
    *************************************************************************/  
    public static Map<Id,Decimal> getRebateAmtMap(Map<Id,Decimal> loanIdVsRebate,List<Insurance__c> insList){
        for(Insurance__c ins : insList){
            if(loanIdVsRebate.containsKey(ins.Loan_Account__c) && loanIdVsRebate.get(ins.Loan_Account__c) != null && ins.Premium_Amount_Gross__c != null){
                Decimal totalRebate = loanIdVsRebate.get(ins.Loan_Account__c) + (ins.Rebate_Factor__c * ins.Premium_Amount_Gross__c);
                loanIdVsRebate.put(ins.Loan_Account__c,totalRebate);
            }else{
                loanIdVsRebate.put(ins.Loan_Account__c,ins.Rebate_Factor__c * ins.Premium_Amount_Gross__c);
            }
        }
        return loanIdVsRebate;
    }

    /************************************************************************
     * @Description : This method updates the formula fields of insurance and returns true if it is updated
     * @params     :  Insurance List AND map of id and loan__Payoff_Quote__c
     * @returnType : Boolean
    *************************************************************************/  
    public static Boolean updateInsFormulas(List<Insurance__c> insList,Map<Id,loan__Payoff_Quote__c> loanIdVsPq ){
        for(Insurance__c insMl : insList){
            insMl.User_Defined_Policy_Status__c = InsuranceConstants.BLANK; 
            insMl.Cancellation_Effective_Date__c = loanIdVsPq.get(insMl.Loan_Account__c).loan__Poq_valid_till_Dt__c;  
        }
        List<FormulaRecalcResult> results = Formula.recalculateFormulas(insList);
        return (results != null) ? true : false;
    }

    /************************************************************************
     * @Description : This method updates loan__Payoff_Quote__c
     * @params     :  loan__Payoff_Quote__c List AND map of loan Id vs Rebate Amount and 
     * @returnType : void
    *************************************************************************/  
    public static void updatePayoffQuote(List<loan__Payoff_Quote__c> payOffQuoteList,Map<Id,Decimal> loanIdVsRebate,Map<Id,Decimal> loanIdVsEtfAmt){
        List<loan__Payoff_Quote__c> payOffQuoteToUpdate = new List<loan__Payoff_Quote__c> ();
        for(loan__Payoff_Quote__c payOffQuote : payOffQuoteList){
            if(loanIdVsEtfAmt.containsKey(payOffQuote.loan__Loan_Account__c) && loanIdVsEtfAmt.get(payOffQuote.loan__Loan_Account__c) != 0){
                payOffQuote.loan__Poq_Prepayment_Penalty__c = loanIdVsEtfAmt.get(payOffQuote.loan__Loan_Account__c);
                payOffQuote.loan__Poq_Total_Payoff_Amount__c = payOffQuote.loan__Poq_Total_Payoff_Amount__c + loanIdVsEtfAmt.get(payOffQuote.loan__Loan_Account__c);
            }
            if(loanIdVsRebate.containsKey(payOffQuote.loan__Loan_Account__c) && loanIdVsRebate.get(payOffQuote.loan__Loan_Account__c) != 0){
                payOffQuote.Total_of_Insurance_rebates__c = -loanIdVsRebate.get(payOffQuote.loan__Loan_Account__c);
                payOffQuote.loan__Poq_Total_Payoff_Amount__c = payOffQuote.loan__Poq_Total_Payoff_Amount__c - loanIdVsRebate.get(payOffQuote.loan__Loan_Account__c);
            }
            payOffQuoteToUpdate.add(payOffQuote);
        }
        if(payOffQuoteToUpdate != null && payOffQuoteToUpdate.size()>0 && loan__Payoff_Quote__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()){
            update payOffQuoteToUpdate;
        }
    }


    /************************************************************************
     * @Description : This method calculates ETF amount
     * @params     :  Loan Account List AND payOffQuote List 
     * @returnType : Map<Id,Decimal>
    *************************************************************************/  
    public static Map<Id,Decimal> calculateETFAmount(Set<String> loanListSet,Map<Id,loan__Payoff_Quote__c> loanIdVsPq ){
        Map<Id,Decimal> loanIdVsEtfAmt = new Map<Id,Decimal> ();
        List<String> etfAmountList = (system.label.ETF_Amount).split(',');
        Decimal etfAmount = 0;
        List<loan__Loan_Account__c> loanAccList = new List<loan__Loan_Account__c>();
        loanAccList = [Select id,
                                name,
                                Perpetual_Loan_Product_Name__c,
                                loan__Loan_Amount__c,
                                loan__Disbursal_Date__c,
                                loan__Term_Cur__c,
                                isMigrated__c,
                                Early_Termination_Fee_Type__c,
                                loan__Maturity_Date_Current__c
                            FROM loan__Loan_Account__c
                            WHERE id IN : loanListSet
                            WITH SECURITY_ENFORCED];
        for(loan__Loan_Account__c itr : loanAccList){
            Integer monthsleft = Integer.valueOf(((loanIdVsPq.get(itr.id).loan__Poq_valid_till_Dt__c).daysbetween(itr.loan__Maturity_Date_Current__c))/30.43685);
            etfAmount = (itr.isMigrated__c) ? getEtfAmtForMigratedAccs(itr,monthsleft,etfAmountList) : 
                ((itr.Perpetual_Loan_Product_Name__c == PERSONAL_LOAN_FIXED_Rate || itr.Perpetual_Loan_Product_Name__c == SECURED_LOAN_FIXED_RATE) && monthsleft>3) ? 
                Decimal.valueof(etfAmountList[4]) : (itr.Perpetual_Loan_Product_Name__c == MOTOR_LOAN_FIXED_RATE) ? getEtfAmtForMlAccs(itr,monthsleft,etfAmountList) : 0;
            loanIdVsEtfAmt.put(itr.id,etfAmount);
        }
        return loanIdVsEtfAmt;
    } 

    /************************************************************************
     * @Description : This method Calculates the Early termination Fee Amount on the basis of ETF Fee Type
     * @params     :  Loan Account, months Left AND ETF Amount List
     * @returnType : Decimal
    *************************************************************************/  
    public static Decimal getEtfAmtForMigratedAccs(loan__Loan_Account__c loanAcc, Integer monthsleft,List<String> etfAmountList){
        Decimal etfAmount = 0;
        etfAmount = (loanAcc.Early_Termination_Fee_Type__c == TYPE_1) ? ((monthsleft <= 6) ? 
            Decimal.valueof(etfAmountList[0]) : (monthsleft <=((loanAcc.loan__Term_Cur__c)/2)) ? 
            Decimal.valueof(etfAmountList[1]) : Decimal.valueof(etfAmountList[2])) : 
            ((loanAcc.Early_Termination_Fee_Type__c == TYPE_2) ? (monthsleft<=((loanAcc.loan__Term_Cur__c)/2)) ? 
            Decimal.valueof(etfAmountList[3]) : Decimal.valueof(etfAmountList[0]): 0);
        return etfAmount;
    }

    /************************************************************************
     * @Description : This method calculates the Early termination Fee Amount on the basis of Product Name , Disbursal date & Loan Amount 
     * @params     :  Loan Account, months Left AND ETF Amount List
     * @returnType : Decimal
    *************************************************************************/ 
    public static Decimal getEtfAmtForMlAccs(loan__Loan_Account__c loanAcc,Integer monthsleft,List<String> etfAmountList){
        Decimal etfAmount = 0;
        etfAmount = (loanAcc.loan__Disbursal_Date__c>=(Date.newInstance(2022,04,01))) ? Decimal.valueof(etfAmountList[5]) : 
            ((loanAcc.loan__Disbursal_Date__c<=(Date.newInstance(2022,03,31)) && loanAcc.loan__Loan_Amount__c>TWELVE_THOUSAND) ? 
            ((Decimal.valueof(etfAmountList[5]))*monthsleft)/loanAcc.loan__Term_Cur__c : 
            (loanAcc.loan__Disbursal_Date__c<=(Date.newInstance(2022,03,31)) && loanAcc.loan__Loan_Amount__c<TWELVE_THOUSAND) ? 
            ((loanAcc.loan__Loan_Amount__c*(Decimal.valueof(etfAmountList[6])))*monthsleft)/loanAcc.loan__Term_Cur__c : 0);
        return etfAmount;
    }
}