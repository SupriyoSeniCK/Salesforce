/************************************************
@ Description : Trigger for Pay Off Quote
Developer : Supriyo Seni
Date : 03/02/2023
************************************************/

trigger LoanPayoffQuoteTrigger on loan__Payoff_Quote__c (after insert) {
    try{
        Bpay_Default_Values__c bpayIns = Bpay_Default_Values__c.getInstance();
        if((bpayIns!=null) && (bpayIns.LoanPayOffQuoteTrigger__c == true)){
            List<loan__Payoff_Quote__c> payOffQuoteList = new List<loan__Payoff_Quote__c> ();
            Set<String> loanListSet = new Set<String>();
            List<Insurance__c> insuranceList = new List<Insurance__c>();
            List<Insurance__c> insListForMl = new List<Insurance__c>();
            List<Insurance__c> insListForPl = new List<Insurance__c>();
            Map<Id,Decimal> loanIdVsRebate = new Map<Id,Decimal> ();
            Map<Id,loan__Payoff_Quote__c> loanIdVsPq = new Map<Id,loan__Payoff_Quote__c> ();
            List<loan__Payoff_Quote__c> payOffQuoteToUpdate = new List<loan__Payoff_Quote__c> ();
            if(Trigger.isInsert && Trigger.isAfter){
                for(Id recordId : Trigger.newMap.keyset()){
                    if(Trigger.newMap.get(recordId).loan__Loan_Account__c != NULL){
                        loanListSet.add(Trigger.newMap.get(recordId).loan__Loan_Account__c);
                        loanIdVsPq.put(Trigger.newMap.get(recordId).loan__Loan_Account__c,Trigger.newMap.get(recordId));
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
                                WHERE id IN : Trigger.newMap.keySet()];
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
                                AND Loan_Account__r.id IN : loanListSet];
                // Separating insurances based on Product Type PL or ML
                if(insuranceList != null && insuranceList.size()>0){
                    for(Insurance__c ins : insuranceList){
                        if(ins.Loan_Product_Name__c.contains(InsuranceConstants.PERSONAL_LOAN)){
                            insListForPl.add(ins);
                        }else if(ins.Loan_Product_Name__c.contains(InsuranceConstants.MOTOR_LOAN)){
                            insListForMl.add(ins);
                        }
                    }
                } 
                // Calculate and apply Total Insurance Rebate for PL Accounts
                if(insListForPl != null && insListForPl.size()>0){
                    for(Insurance__c insPl : insListForPl){
                        if(loanIdVsRebate.containsKey(insPl.Loan_Account__c) && loanIdVsRebate.get(insPl.Loan_Account__c) != null && insPl.Premium_Amount_Gross__c != null){
                            Decimal totalRebate = loanIdVsRebate.get(insPl.Loan_Account__c) + (insPl.Rebate_Factor__c * insPl.Premium_Amount_Gross__c);
                            loanIdVsRebate.put(insPl.Loan_Account__c,totalRebate);
                        }else if(insPl.Premium_Amount_Gross__c != null){
                            loanIdVsRebate.put(insPl.Loan_Account__c,insPl.Rebate_Factor__c * insPl.Premium_Amount_Gross__c);
                        }
                    }
                }
                if(insListForMl != null && insListForMl.size()>0){
                    // Get updated formula field values with Effective Cancellation Date as Payoff Date
                    for(Insurance__c insMl : insListForMl){
                        insMl.User_Defined_Policy_Status__c = InsuranceConstants.BLANK; 
                        insMl.Cancellation_Effective_Date__c = loanIdVsPq.get(insMl.Loan_Account__c).loan__Poq_valid_till_Dt__c;  
                    }
                    List<FormulaRecalcResult> results = Formula.recalculateFormulas(insListForMl);
                    // Calculate and apply Total Insurance Rebate for ML Accounts
                    for(Insurance__c ins : insListForMl){
                        if(loanIdVsRebate.containsKey(ins.Loan_Account__c) && loanIdVsRebate.get(ins.Loan_Account__c) != null && ins.Premium_Amount_Gross__c != null){
                            Decimal totalRebate = loanIdVsRebate.get(ins.Loan_Account__c) + (ins.Rebate_Factor__c * ins.Premium_Amount_Gross__c);
                            loanIdVsRebate.put(ins.Loan_Account__c,totalRebate);
                        }else if(ins.Premium_Amount_Gross__c != null){
                            loanIdVsRebate.put(ins.Loan_Account__c,ins.Rebate_Factor__c * ins.Premium_Amount_Gross__c);
                        }
                    }
                }               
                // Update Payoff Quote with applicable Insurance Rebate Amount
                if(payOffQuoteList != null && payOffQuoteList.size()>0){
                    for(loan__Payoff_Quote__c payOffQuote : payOffQuoteList){
                        if(loanIdVsRebate.containsKey(payOffQuote.loan__Loan_Account__c) && loanIdVsRebate.get(payOffQuote.loan__Loan_Account__c) != 0){
                            payOffQuote.Total_of_Insurance_rebates__c = -loanIdVsRebate.get(payOffQuote.loan__Loan_Account__c);
                            payOffQuote.loan__Poq_Total_Payoff_Amount__c = payOffQuote.loan__Poq_Total_Payoff_Amount__c - loanIdVsRebate.get(payOffQuote.loan__Loan_Account__c);
                            payOffQuoteToUpdate.add(payOffQuote);
                        }
                    }
                    if(payOffQuoteToUpdate != null && payOffQuoteToUpdate.size()>0){
                        update payOffQuoteToUpdate;
                    }
                }
            }
        }
    }catch(Exception ex){
        ExceptionManager.manageException(ex);
    }
}