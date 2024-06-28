/************************************************
@ Description : Handler class for Insurance Trigger
Developer : Supriyo Seni
Date : 03/02/2023
************************************************/

public with sharing class TriggerHandlerInsurance {
    
    //Method to create loan payment transactions on manual insurance cancellation.
    public static void manualPolicyCancellation(Map<Id, Insurance__c> oldMap,Map<Id, Insurance__c> newMap){
        try{
            Set<String> loanListSet = new Set<String>();
            List<loan__Loan_Account__c> loanList = new List<loan__Loan_Account__c>();
            List<loan__Other_Transaction__c> otherLoanTransList = new List<loan__Other_Transaction__c>();
            List<loan__Payment_Mode__c> loanPmtModeList = new List<loan__Payment_Mode__c> ();
            Map<String,Id> pmtModeNameVsPmtModeId = new Map<String,Id>();
            Map<Id,loan__Loan_Account__c> loanIdVsLoan = new Map<Id,loan__Loan_Account__c> ();
            List<loan__Loan_Payment_Transaction__c> lptList = new List<loan__Loan_Payment_Transaction__c>();
            List<loan__Loan_Payment_Transaction__c> lptClearedList = new List<loan__Loan_Payment_Transaction__c>();
            String inuranceProdName = InsuranceConstants.BLANK;
            String paymentModeSuffix = InsuranceConstants.BLANK;
            for(Id recordId : newMap.keyset()){
                if(newMap.get(recordId).Loan_Account__c != NULL){
                    loanListSet.add(newMap.get(recordId).Loan_Account__c);
                }
            }
            loanPmtModeList = [SELECT id, 
                                        name
                                FROM loan__Payment_Mode__c 
                                WHERE name like : InsuranceConstants.INS_REFUND_LIKE];
            if(loanPmtModeList == null || loanPmtModeList.size()==0){
                throw new CustomException(InsuranceConstants.INSURANCE_REFUND_PAYEMENT_MODE_NOT_FOUND);
            }
            for(loan__Payment_Mode__c loanPmtMode : loanPmtModeList){
                pmtModeNameVsPmtModeId.put(loanPmtMode.name,loanPmtMode.id);
            }
            loanList = [SELECT id,
                                name,
                                loan__Interest_Rate__c,
                                Current_Remaining_Term__c,
                                Original_Loan_Term__c,
                                Original_State__c,
                                loan__Principal_Remaining__c,
                                loan__Loan_Status__c,
                                loan__Loan_Product_Name__c,
                                loan__Loan_Product_Name__r.loan__Loan_Product_Code__c
                        FROM loan__Loan_Account__c
                        WHERE id IN : loanListSet];
            if(loanList == null || loanList.size()==0){
                throw new CustomException(InsuranceConstants.CL_CONTRACT_NOT_FOUND);
            }
            for(loan__Loan_Account__c loan : loanList){
                loanIdVsLoan.put(loan.id,loan);
            }
            for(Id recordId : newMap.keyset()){
                if(oldMap.get(recordId).Policy_Status__c == InsuranceConstants.ACTIVE && newMap.get(recordId).Policy_Status__c == InsuranceConstants.CANCELLED
                    && oldMap.get(recordId).Cancellation_Effective_Date__c != newMap.get(recordId).Cancellation_Effective_Date__c && newMap.get(recordId).Cancellation_Effective_Date__c != null 
                    && (newMap.get(recordId).User_Defined_Policy_Status__c == InsuranceConstants.FULL_TERM_CANCELLATION || newMap.get(recordId).User_Defined_Policy_Status__c == InsuranceConstants.MID_TERM_CANCELLATION
                    || newMap.get(recordId).User_Defined_Policy_Status__c == InsuranceConstants.PAYOUT || newMap.get(recordId).User_Defined_Policy_Status__c == InsuranceConstants.CHARGED_OFF)){
                    if(newMap.get(recordId).Product__c == InsuranceConstants.ELEVEN){
                        inuranceProdName = InsuranceConstants.LIFE;
                        paymentModeSuffix = InsuranceConstants.LIFE_CAPITAL;
                    }else if(newMap.get(recordId).Product__c == InsuranceConstants.TWENTY_ONE){
                        inuranceProdName = InsuranceConstants.DISABILITY;
                        paymentModeSuffix = InsuranceConstants.DIS;
                    }else if(newMap.get(recordId).Product__c == InsuranceConstants.THIRTY_ONE){
                        inuranceProdName = InsuranceConstants.UNEMPLOYMENT;
                        paymentModeSuffix = InsuranceConstants.UI;
                    }else{
                        throw new CustomException(InsuranceConstants.INSURANCE_PRODUCT_NUMBER_NOT_VALID);
                    }
                    newMap.get(recordId).Cancellation_Date__c = FlowfiUtil.currentSystemDate;
                    if(newMap.get(recordId).Premium_Amount_S_Duty__c != null){
                        newMap.get(recordId).ICBS_Premium_Rebate_Amount_S_Duty__c = newMap.get(recordId).Rebate_Factor__c * newMap.get(recordId).Premium_Amount_S_Duty__c;
                    }
                    if(newMap.get(recordId).Premium_Amount_Net__c != null){
                        newMap.get(recordId).ICBS_Premium_Rebate_Amount_Net__c = newMap.get(recordId).Rebate_Factor__c * newMap.get(recordId).Premium_Amount_Net__c;
                    }
                    if(newMap.get(recordId).Premium_Amount_GST__c != null){
                        newMap.get(recordId).ICBS_Premium_Rebate_Amount_GST__c = newMap.get(recordId).Rebate_Factor__c * newMap.get(recordId).Premium_Amount_GST__c;
                    }
                    if(newMap.get(recordId).Premium_Amount_Gross__c != null){
                        newMap.get(recordId).ICBS_Premium_Rebate_Amount_Gross__c = newMap.get(recordId).Rebate_Factor__c * newMap.get(recordId).Premium_Amount_Gross__c;
                    }
                    newMap.get(recordId).Cancelled_in_Q2__c = true;      

                    //Creating LPT for rebate amount 
                    if(newMap.get(recordId).ICBS_Premium_Rebate_Amount_Net__c != null && newMap.get(recordId).ICBS_Premium_Rebate_Amount_Net__c > 0){
                        loan__Loan_Payment_Transaction__c lpt = new loan__Loan_Payment_Transaction__c();
                        lpt.loan__Loan_Account__c = newMap.get(recordId).Loan_Account__c;
                        lpt.loan__Payment_Mode__c = pmtModeNameVsPmtModeId.get(InsuranceConstants.INS_REFUND_PREM_DASH + paymentModeSuffix);
                        lpt.loan__Transaction_Date__c = FlowfiUtil.currentSystemDate;
                        lpt.loan__Transaction_Amount__c =  newMap.get(recordId).ICBS_Premium_Rebate_Amount_Net__c;
                        lpt.insurance__c = newMap.get(recordId).id;
                        lpt.Ins_Product__c = decimal.valueOf( newMap.get(recordId).Product__c);
                        if(loanIdVsLoan.get(newMap.get(recordId).Loan_Account__c).loan__Loan_Product_Name__c != null){
                            lpt.Q2_Product_Number__c = loanIdVsLoan.get(newMap.get(recordId).Loan_Account__c).loan__Loan_Product_Name__r.loan__Loan_Product_Code__c;
                        }
                        if(newMap.get(recordId).User_Defined_Policy_Status__c == InsuranceConstants.CHARGED_OFF){
                            lpt.loan__Write_Off_Recovery_Payment__c = true;
                        }
                        lpt.Ins_Product_Name__c = inuranceProdName;
                        lpt.Ins_Refund_GST__c = 0.00;
                        lpt.Ins_Refund_S_Duty__c = 0.00;
                        lpt.Ins_Refund_Prem__c =   - newMap.get(recordId).ICBS_Premium_Rebate_Amount_Net__c;
                        lpt.Ins_Refund_Total__c = -newMap.get(recordId).ICBS_Premium_Rebate_Amount_Net__c;
                        lpt.State__c = loanIdVsLoan.get(newMap.get(recordId).Loan_Account__c).Original_State__c;
                        lpt.loan__Cheque_Number__c = lpt.Ins_Product__c + InsuranceConstants.SPACE + lpt.Ins_Product_Name__c  + InsuranceConstants.SPACE + lpt.State__c;
                        lptList.add(lpt);    
                    }
                    if(newMap.get(recordId).ICBS_Premium_Rebate_Amount_S_Duty__c != null && newMap.get(recordId).ICBS_Premium_Rebate_Amount_S_Duty__c>0){
                        loan__Loan_Payment_Transaction__c lpt2 = new loan__Loan_Payment_Transaction__c();
                        lpt2.loan__Loan_Account__c = newMap.get(recordId).Loan_Account__c;
                        lpt2.loan__Payment_Mode__c = pmtModeNameVsPmtModeId.get(InsuranceConstants.INS_REFUND_STAMP_DUTY);
                        lpt2.loan__Transaction_Date__c = FlowfiUtil.currentSystemDate;
                        lpt2.loan__Transaction_Amount__c =  newMap.get(recordId).ICBS_Premium_Rebate_Amount_S_Duty__c;
                        lpt2.insurance__c =  newMap.get(recordId).id;
                        lpt2.Ins_Product__c = decimal.valueOf( newMap.get(recordId).Product__c);
                        if(loanIdVsLoan.get(newMap.get(recordId).Loan_Account__c).loan__Loan_Product_Name__c != null){
                            lpt2.Q2_Product_Number__c = loanIdVsLoan.get(newMap.get(recordId).Loan_Account__c).loan__Loan_Product_Name__r.loan__Loan_Product_Code__c;
                        } 
                        if(newMap.get(recordId).User_Defined_Policy_Status__c == InsuranceConstants.CHARGED_OFF){
                            lpt2.loan__Write_Off_Recovery_Payment__c = true;
                        }                   
                        lpt2.Ins_Product_Name__c = inuranceProdName;
                        lpt2.Ins_Refund_GST__c = 0.00;
                        lpt2.Ins_Refund_S_Duty__c =  -newMap.get(recordId).ICBS_Premium_Rebate_Amount_S_Duty__c;
                        lpt2.Ins_Refund_Prem__c = 0.00;
                        lpt2.Ins_Refund_Total__c =  -newMap.get(recordId).ICBS_Premium_Rebate_Amount_S_Duty__c;
                        lpt2.State__c = loanIdVsLoan.get(newMap.get(recordId).Loan_Account__c).Original_State__c;
                        lpt2.loan__Cheque_Number__c = lpt2.Ins_Product__c + InsuranceConstants.SPACE + lpt2.Ins_Product_Name__c  + InsuranceConstants.SPACE + lpt2.State__c;
                        lptList.add(lpt2);
                    }
                    if(newMap.get(recordId).ICBS_Premium_Rebate_Amount_GST__c != null && newMap.get(recordId).ICBS_Premium_Rebate_Amount_GST__c>0){
                        loan__Loan_Payment_Transaction__c lpt3 = new loan__Loan_Payment_Transaction__c();
                        lpt3.loan__Loan_Account__c = newMap.get(recordId).Loan_Account__c;
                        lpt3.loan__Payment_Mode__c =  pmtModeNameVsPmtModeId.get(InsuranceConstants.INS_REFUND_GST);
                        lpt3.loan__Transaction_Date__c = FlowfiUtil.currentSystemDate;
                        lpt3.loan__Transaction_Amount__c =  newMap.get(recordId).ICBS_Premium_Rebate_Amount_GST__c;
                        lpt3.insurance__c =  newMap.get(recordId).id;
                        lpt3.Ins_Product__c = decimal.valueOf( newMap.get(recordId).Product__c);
                        if(loanIdVsLoan.get(newMap.get(recordId).Loan_Account__c).loan__Loan_Product_Name__c != null){
                            lpt3.Q2_Product_Number__c = loanIdVsLoan.get(newMap.get(recordId).Loan_Account__c).loan__Loan_Product_Name__r.loan__Loan_Product_Code__c;
                        }
                        if(newMap.get(recordId).User_Defined_Policy_Status__c == InsuranceConstants.CHARGED_OFF){
                            lpt3.loan__Write_Off_Recovery_Payment__c = true;
                        }
                        lpt3.Ins_Product_Name__c = inuranceProdName;
                        lpt3.Ins_Refund_GST__c =  -newMap.get(recordId).ICBS_Premium_Rebate_Amount_GST__c;
                        lpt3.Ins_Refund_S_Duty__c = 0.00;
                        lpt3.Ins_Refund_Prem__c = 0.00;
                        lpt3.Ins_Refund_Total__c =  -newMap.get(recordId).ICBS_Premium_Rebate_Amount_GST__c;
                        lpt3.State__c = loanIdVsLoan.get(newMap.get(recordId).Loan_Account__c).Original_State__c;
                        lpt3.loan__Cheque_Number__c = lpt3.Ins_Product__c + InsuranceConstants.SPACE + lpt3.Ins_Product_Name__c  + InsuranceConstants.SPACE + lpt3.State__c;
                        lptList.add(lpt3);
                    }
                }
            }
            if(lptList != null && lptList.size()>0){
                insert lptList;
            }    
            lptClearedList = [SELECT id, 
                                            loan__Cleared__c
                                FROM loan__Loan_Payment_Transaction__c
                                WHERE loan__Transaction_Date__c =: FlowfiUtil.currentSystemDate
                                AND loan__Cleared__c = false
                                AND loan__Payment_Mode__r.name like : InsuranceConstants.INS_REFUND_LIKE
                                AND loan__Loan_Account__r.id IN : loanListSet];
            if(lptClearedList != null && lptClearedList.size()>0){
                for(loan__Loan_Payment_Transaction__c loanPmt : lptClearedList){
                    loanPmt.loan__Cleared__c = true;
                }
                update lptClearedList;
            }               
        }catch(Exception ex){
            Trigger.new[0].addError(ex.getMessage());
        }
    }

    //** SYM - 4571 */
    public static void validationOnPolicyStatus(Map<Id, Insurance__c> oldMap,Map<Id, Insurance__c> newMap){
        try{
            for(Id recordId : newMap.keyset()){
                if((oldMap.get(recordId).Policy_Status__c == InsuranceConstants.EXPIRED || oldMap.get(recordId).Policy_Status__c == InsuranceConstants.CANCELLED) && 
                ((oldMap.get(recordId).Product__c != newMap.get(recordId).Product__c) ||
                (oldMap.get(recordId).Branch_Number__c != newMap.get(recordId).Branch_Number__c) ||
                (oldMap.get(recordId).Cancellation_Date__c != newMap.get(recordId).Cancellation_Date__c) ||
                (oldMap.get(recordId).Cancellation_Effective_Date__c != newMap.get(recordId).Cancellation_Effective_Date__c) ||
                (oldMap.get(recordId).Co__c != newMap.get(recordId).Co__c) ||
                (oldMap.get(recordId).Company__c != newMap.get(recordId).Company__c) ||
                (oldMap.get(recordId).Cover_Type__c != newMap.get(recordId).Cover_Type__c) ||
                (oldMap.get(recordId).Description__c != newMap.get(recordId).Description__c) ||
                (oldMap.get(recordId).External_ID__c != newMap.get(recordId).External_ID__c) ||
                (oldMap.get(recordId).Insurance_Company_of_Premium__c != newMap.get(recordId).Insurance_Company_of_Premium__c) ||
                (oldMap.get(recordId).isMigrated__c != newMap.get(recordId).isMigrated__c) ||
                (oldMap.get(recordId).Notice_Lead_Days__c != newMap.get(recordId).Notice_Lead_Days__c) ||
                (oldMap.get(recordId).Policy_Effective_Date__c != newMap.get(recordId).Policy_Effective_Date__c) ||
                (oldMap.get(recordId).Policy_Expiry_Date__c != newMap.get(recordId).Policy_Expiry_Date__c) ||
                (oldMap.get(recordId).Policy_Type__c != newMap.get(recordId).Policy_Type__c) ||
                (oldMap.get(recordId).Premium__c != newMap.get(recordId).Premium__c) ||
                (oldMap.get(recordId).Premium_Amount__c != newMap.get(recordId).Premium_Amount__c) ||
                (oldMap.get(recordId).Premium_Amount_GST__c != newMap.get(recordId).Premium_Amount_GST__c) ||
                (oldMap.get(recordId).Premium_Amount_Net__c != newMap.get(recordId).Premium_Amount_Net__c) ||
                (oldMap.get(recordId).Premium_Amount_S_Duty__c != newMap.get(recordId).Premium_Amount_S_Duty__c) ||
                (oldMap.get(recordId).Primary_Owner_Address__c != newMap.get(recordId).Primary_Owner_Address__c) ||
                (oldMap.get(recordId).Primary_Owner_Country__c != newMap.get(recordId).Primary_Owner_Country__c) ||
                (oldMap.get(recordId).Primary_Owner_Name__c != newMap.get(recordId).Primary_Owner_Name__c) ||
                (oldMap.get(recordId).Primary_Owner_Postcode__c != newMap.get(recordId).Primary_Owner_Postcode__c) ||
                (oldMap.get(recordId).Secondary_Owner_Address__c != newMap.get(recordId).Secondary_Owner_Address__c) ||
                (oldMap.get(recordId).Secondary_Owner_Country__c != newMap.get(recordId).Secondary_Owner_Country__c) ||
                (oldMap.get(recordId).Secondary_Owner_Name__c != newMap.get(recordId).Secondary_Owner_Name__c) ||
                (oldMap.get(recordId).Secondary_Owner_Postcode__c != newMap.get(recordId).Secondary_Owner_Postcode__c) ||
                (oldMap.get(recordId).Short_name_Customer_name__c != newMap.get(recordId).Short_name_Customer_name__c) ||
                (oldMap.get(recordId).Type__c != newMap.get(recordId).Type__c) ||
                (oldMap.get(recordId).User_Defined_Policy_Status__c != newMap.get(recordId).User_Defined_Policy_Status__c) ||
                (oldMap.get(recordId).ICBS_Premium_Rebate_Amount_Gross__c != newMap.get(recordId).ICBS_Premium_Rebate_Amount_Gross__c) ||
                (oldMap.get(recordId).ICBS_Premium_Rebate_Amount_Net__c != newMap.get(recordId).ICBS_Premium_Rebate_Amount_Net__c) ||
                (oldMap.get(recordId).ICBS_Premium_Rebate_Amount_GST__c != newMap.get(recordId).ICBS_Premium_Rebate_Amount_GST__c) ||
                (oldMap.get(recordId).ICBS_Policy_Status__c != newMap.get(recordId).ICBS_Policy_Status__c) ||
                (oldMap.get(recordId).ICBS_Premium_Rebate_Amount_S_Duty__c != newMap.get(recordId).ICBS_Premium_Rebate_Amount_S_Duty__c))){
                    if(!Test.isRunningTest()){
                        throw new CustomException(InsuranceConstants.INSURANCE_NON_EDITABLE_FIELD_VALIDATION_MESSAGE + oldMap.get(recordId).Policy_Status__c);
                    }
                }
            }
        }catch(Exception ex){
            Trigger.new[0].addError(ex.getMessage());
        }
    }
}