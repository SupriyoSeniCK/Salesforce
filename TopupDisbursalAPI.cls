/**
* @description       : Disbursal API that funds (Principal Adjustment + Reschedule) Top Up Applications
* @last modified by  : Chayan Sengupta
**/

global without sharing class TopupDisbursalAPI{
    static genesis__Applications__c appObjCp = new genesis__Applications__c();
    static Decimal lefAmount=0;
    static List<loan.LoanRescheduleParameters.ProposedRepaymentPlan> repaymentPlanList = new List<loan.LoanRescheduleParameters.ProposedRepaymentPlan>();
    
    //Latitude_MyPersonalAndLoanDetails skuid page, FundTopUp snippet
    webservice static String disburseTopUp(id appId){
        id migappId = appId;
        String res;
        Decimal totalLEF = TopupDisbursalConstant.ZERO;
        Decimal totalFunded = TopupDisbursalConstant.ZERO;
        Savepoint sp_master = Database.setSavePoint();
        try{
            List<genesis__Applications__c> appList = [SELECT id,
                                                      CL_Contract__r.isMigrated__c,
                                                      (SELECT id,
                                                       Bank_Account__c,
                                                       Application__c,
                                                       Application__r.CL_Contract__c,
                                                       Eligible_for_Debt_Consolidation__c,
                                                       Total_Balance__c,
                                                       Details_Entered_are_correct__c
                                                       FROM Other_Loan_Details__r
                                                       WHERE Eligible_for_Debt_Consolidation__c=true
                                                       AND Total_Balance__c<>null
                                                       AND Bank_Account__c<>null
                                                       AND Details_Entered_are_correct__c=true),
                                                      (SELECT id,
                                                       Bank_Account__c,
                                                       Application__c,
                                                       Application__r.CL_Contract__c,
                                                       To_be_paid_out__c,
                                                       Total_Balance__c,
                                                       Credit_card_balance__c,
                                                       Details_Correct__c
                                                       FROM Monthly_Income_Expense_Info__r
                                                       WHERE RecordType.Name =: ApplicationConversionAPIConstants.CREDIT_CARD
                                                       AND To_be_paid_out__c = true
                                                       AND Credit_card_balance__c<>null
                                                       AND Bank_Account__c<>null
                                                       AND Details_Correct__c=true),
                                                      Top_Up__c,
                                                      Refinance__c,
                                                      genesis__Status__c,
                                                      genesis__Interest_Rate__c,
                                                      genesis__Margin__c,
                                                      Loan_Establishment_Fee_Percentage__c,
                                                      genesis__Loan_Amount__c,
                                                      genesis__Payment_Frequency__c,
                                                      LAF_Amount__c,
                                                      Loan_Establishment_Fee__c,
                                                      CCR_Bureau_Score__c,
                                                      Top_Up_Amount__c,
                                                      genesis__Term__c,
                                                      genesis__Account__c,
                                                      Actual_Loan_Purpose__c,
                                                      Refinance_Amount__c,
                                                      Original_Application__c,
                                                      Top_up_Channel__c,
                                                      TopUpPayOffAmount__c,
                                                      Insurance_Rebate_Amount__c
                                                      FROM genesis__Applications__c
                                                      WHERE id=:appId];
            //System.debug('appList: ----->'+appList);
            
            if(!appList.isEmpty()){
                genesis__Applications__c topUpObj = appList[TopupDisbursalConstant.ZERO];
                id loanAccId = topUpObj.CL_Contract__c;
                id ogAppId;
                List<genesis__applications__c> ogApp;
                if(topUpObj.Top_Up__c==false){
                    throw new CustomException(ResponseMessenger.TopupDisbursalAPI_err1);
                }else if(topUpObj.Original_Application__c==null && topUpObj.CL_Contract__r.isMigrated__c == false){
                    throw new CustomException(ResponseMessenger.TopupDisbursalAPI_err2);
                }else if(!String.isBlank(topUpObj.genesis__Status__c) && !topUpObj.genesis__Status__c.equals(ConstantValues.status_Application_PendingDrawdown)){
                    throw new CustomException(ResponseMessenger.TopupDisbursalAPI_err3);
                }
                if(!String.isBlank(topUpObj.Actual_Loan_Purpose__c) && topUpObj.Actual_Loan_Purpose__c==TopupDisbursalConstant.DEBT_CONSOLIDATION){
                    decimal totDebtAmt = TopupDisbursalConstant.ZERO;
                    for(Other_Loan_Detail__c oth : topUpObj.Other_Loan_Details__r){
                        totDebtAmt+=oth.Total_Balance__c;
                    }
                    for(genesis__Monthly_Income_Expense_Info__c cc : topUpObj.Monthly_Income_Expense_Info__r){
                        totDebtAmt += cc.Total_Balance__c;
                    }
                    if(totDebtAmt>topUpObj.genesis__Loan_Amount__c){
                        throw new CustomException(TopupDisbursalConstant.DEBT_CON_EXCEEDING_TOPUP_AMOUNT);
                    }
                }
                if(topUpObj.Original_Application__c != null){
                    ogAppId = topUpObj.Original_Application__c;
                    ogApp = [select id, loan_establishment_fee__c, PPSR_Search_Fee__c, PPSR_Registration_Fee__c  from genesis__applications__c where id =:ogAppId];
                }
                List<loan__Loan_Account__c> lnAcclist = [SELECT id,
                                                         (SELECT id,
                                                          Premium_Rebate_Amount_Gross__c,
                                                          User_Defined_Policy_Status__c,
                                                          Cancellation_Date__c,
                                                          Product__c,
                                                          Premium_Rebate_Amount_Net__c,
                                                          Premium_Rebate_Amount_GST__c,
                                                          Premium_Rebate_Amount_S_Duty__c,
                                                          Cancellation_Effective_Date__c,
                                                          Loan_Account__r.Perpetual_Product_Code__c,
                                                          Loan_Account__r.Original_State__c,
                                                          ICBS_Premium_Rebate_Amount_S_Duty__c,
                                                          Rebate_Factor__c,
                                                          Premium_Amount_S_Duty__c,
                                                          ICBS_Premium_Rebate_Amount_Net__c,
                                                          Premium_Amount_Net__c,
                                                          ICBS_Premium_Rebate_Amount_GST__c,
                                                          Premium_Amount_GST__c,
                                                          ICBS_Premium_Rebate_Amount_Gross__c,
                                                          Premium_Amount_Gross__c,
                                                          Cancelled_in_Q2__c
                                                          FROM Insurances__r
                                                          WHERE Policy_Status__c = 'Active'),
                                                         name,
                                                         isMigrated__c,
                                                         Total_Top_Up_Amount__c,
                                                         Top_Up_LEF__c,
                                                         Total_Top_Up_LEF__c,
                                                         Top_Up_Amount__c,
                                                         Application__c,
                                                         loan__Refinanced__c,
                                                         Refinance_Amount__c,
                                                         Top_Up_Channel__c,loan__Loan_Status__c,
                                                         Preferred_Payment_Frequency__c,
                                                         loan__Pay_Off_Amount_As_Of_Today__c
                                                         FROM loan__Loan_Account__c
                                                         WHERE ((isMigrated__c = false AND (Application__c = :ogAppId OR Last_Top_Up_Application__c = :ogAppId))
                                                                OR (isMigrated__c = true AND id =: loanAccId))
                                                         ORDER BY CreatedDate DESC
                                                         LIMIT 1];
                if(!lnAcclist.isEmpty()){
                    loan__Loan_Account__c lnAccObj = lnAcclist.get(TopupDisbursalConstant.ZERO);
                    Decimal topUpAmount = TopupDisbursalConstant.ZERO;
                    Decimal topUpLef = TopupDisbursalConstant.ZERO;
                    Decimal lnAmt = topUpObj.Top_Up_Amount__c + topUpObj.Loan_Establishment_Fee__c; 
                    Decimal iRate = topUpObj.genesis__Interest_Rate__c;
                    Map<String,Decimal> distributionMap =  new Map<String,Decimal>();
                    appObjCp = topUpObj;
                    topUpObj.TopUpPayOffAmount__c=lnAccObj.loan__Pay_Off_Amount_As_Of_Today__c;
                    distributionMap.put(TopupDisbursalConstant.DISBURSEMENT,topUpObj.Top_Up_Amount__c);
                    distributionMap.put(TopupDisbursalConstant.TOPUPLEF,topUpObj.Loan_Establishment_Fee__c);
                    
                    //cancel insurance --- SYM-4222 ---//
                    TopupDisbursalAPI.cancelInsurance(lnAcclist[0].Insurances__r, lnAcclist[0].id, appList[0].Insurance_Rebate_Amount__c);
                    
                    createLptInsuranceAccount(lnAcclist[0].Insurances__r, lnAcclist[0].id);
                    boolean isPrinciOk = TopupDisbursalAPI.doPrincipalAdjustmentAndCreateDistribution(lnAccObj.id,lnAmt,distributionMap,appId);
                    if(isPrinciOk){
                        boolean isResOk = TopupDisbursalAPI.doReschedule(lnAccObj.id,(Integer)topUpObj.genesis__Term__c,topUpObj.genesis__Payment_Frequency__c,iRate);
                        System.debug('isresok====>'+isResOk);
                        if(isResOk){
                            loan__Loan_Account__c lnAcc = [select id,
                                                           loan__Contractual_Interest_Rate__c,
                                                           loan__Interest_Rate__c,
                                                           name,
                                                           isMigrated__c,
                                                           Total_Top_Up_Amount__c,
                                                           Top_Up_LEF__c,
                                                           Total_Top_Up_LEF__c,
                                                           Top_Up_Amount__c,
                                                           Application__c,
                                                           loan__Refinanced__c,
                                                           Refinance_Amount__c,
                                                           Top_Up_Channel__c,
                                                           Preferred_Payment_Frequency__c,
                                                           loan__Reserve_Amount_for_Next_Due__c,
                                                           loan__Term_Cur__c,
                                                           loan__Pay_Off_Amount_As_Of_Today__c
                                                           FROM loan__Loan_Account__c 
                                                           WHERE id=:lnAccObj.id 
                                                          ];
                            
                            // lmb-150
                            List<loan__Loan_Account__c> lnAccList2=[SELECT Id,
                                                                    isMigrated__c,
                                                                    Total_Top_Up_Amount__c,
                                                                    Top_Up_Amount__c,loan__Total_Pre_Paid_Fees__c,
                                                                    Top_Up_LEF__c,Total_Top_Up_LEF__c 
                                                                    FROM loan__Loan_Account__c 
                                                                    WHERE loan__Account__c=:topUpObj.genesis__Account__c 
                                                                    AND loan__Loan_Status__c !=:TopupDisbursalConstant.CANCELED_STATUS];
                            
                            List<genesis__Applications__c> allAppList=[SELECT Id,
                                                                       genesis__Loan_Amount__c,
                                                                       Top_Up__c,
                                                                       Top_Up_Amount__c,
                                                                       genesis__Account__c 
                                                                       FROM genesis__Applications__c 
                                                                       WHERE genesis__Account__c=:topUpObj.genesis__Account__c
                                                                       AND (not (genesis__Status__c like :TopupDisbursalConstant.EXPIRED_STATUS or genesis__Status__c like :TopupDisbursalConstant.DECLINED_STATUS or genesis__Status__c like :TopupDisbursalConstant.WITHDRAWN_STATUS or genesis__Status__c like :TopupDisbursalConstant.FAILED_STATUS or genesis__Status__c like :TopupDisbursalConstant.CLOSED_STATUS))
                                                                      ];
                            if(!allAppList.isEmpty() && allAppList.size()>TopupDisbursalConstant.ZERO){
                                for(genesis__Applications__c app:allAppList){
                                    if(app.Top_Up__c==true){
                                        totalFunded+=app.Top_Up_Amount__c;
                                    }
                                    else{
                                        totalFunded+=app.genesis__Loan_Amount__c;
                                    }
                                }
                            } 
                            if(!lnAccList2.isEmpty() && lnAccList2.size()>TopupDisbursalConstant.ZERO){                                               
                                for(loan__Loan_Account__c loan:lnAccList2){
                                    if(loan.Top_Up_LEF__c==null){
                                        loan.Top_Up_LEF__c = TopupDisbursalConstant.ZERO;
                                    }
                                    if(loan.Top_Up_Amount__c==null){
                                        loan.Top_Up_Amount__c=TopupDisbursalConstant.ZERO;
                                    }
                                    topUpAmount+=loan.Top_Up_Amount__c;
                                    topUpLef+=loan.Top_Up_LEF__c;
                                    totalLEF+=loan.loan__Total_Pre_Paid_Fees__c;
                                }
                            }
                            
                            if(lnAcc.Total_Top_Up_Amount__c==null){
                                lnAcc.Total_Top_Up_Amount__c = TopupDisbursalConstant.ZERO; 
                            }
                            if(lnAcc.Total_Top_Up_LEF__c==null){
                                lnAcc.Total_Top_Up_LEF__c = TopupDisbursalConstant.ZERO;
                            }
                            lnAcc.Total_Top_Up_Amount__c=topUpAmount!=TopupDisbursalConstant.ZERO?topUpAmount+topUpObj.Top_Up_Amount__c:topUpObj.Top_Up_Amount__c;
                            lnAcc.Total_Top_Up_LEF__c=topUpLef!=TopupDisbursalConstant.ZERO?topUpLef+topUpObj.Loan_Establishment_Fee__c:topUpObj.Loan_Establishment_Fee__c;
                            lnAcc.Top_Up__c = true;
                            lnAcc.Top_Up_Amount__c = topUpObj.Top_Up_Amount__c;
                            lnAcc.Top_Up_LEF__c = topUpObj.Loan_Establishment_Fee__c;
                            lnAcc.Top_Up_Funded_On__c = System.now();
                            lnAcc.Send_Top_Up_Fund_Mail__c = true;
                            lnAcc.Last_Top_Up_Purpose__c = topUpObj.Actual_Loan_Purpose__c;
                            lnAcc.Last_Top_Up_CCR__c = topUpObj.CCR_Bureau_Score__c;
                            lnAcc.Last_Top_Up_Application__c = appId;
                            // lmb-150
                            if (topUpObj.Refinance__c) {
                                lnAcc.loan__Refinanced__c = true;
                                lnAcc.Refinance_Amount__c = topUpObj.Refinance_Amount__c;
                            }
                            lnAcc.loan__Total_Refinance_Amount_Actual__c=topUpObj.Top_Up_Amount__c;
                            lnAcc.Total_Lifetime_LEF__c= lnAcc.isMigrated__c ? 0 : lnAcc.Total_Top_Up_LEF__c + ogApp[TopupDisbursalConstant.ZERO].loan_establishment_fee__c;
                            lnAcc.Total_Lifetime_Funded__c=totalFunded;
                            lnAcc.Preferred_Payment_Frequency__c = topUpObj.genesis__Payment_Frequency__c;
                            lnAcc.Top_Up_Channel__c=topUpObj.Top_up_Channel__c;
                            update lnAcc;
                            res = TopupDisbursalConstant.TOPUP_FUNDED_SUCCESSFULLY_MESSAGE;
                            
                            if(lnAcc.loan__Reserve_Amount_for_Next_Due__c<>null && lnAcc.loan__Reserve_Amount_for_Next_Due__c>TopupDisbursalConstant.ZERO){
                                res+=TopupDisbursalConstant.RESERVE_AMOUNT_WARNING;
                            }
                            
                            topUpObj.genesis__Status__c = TopupDisbursalConstant.TOPUP_FUNDED_STATUS;
                            update topUpObj;
                            
                            TopupDisbursalAPI.updateAps(lnAccObj.id);
                            TopupDisbursalAPI.updateIntPostingDates(lnAccObj.id);
                        }
                    }else{
                        throw new CustomException(ResponseMessenger.TopupDisbursalAPI_err4);
                    }
                }else{
                    throw new CustomException(ResponseMessenger.TopupDisbursalAPI_err5);
                }
            }
        }catch(Exception ex){  
            Database.rollBack(sp_master);
            ExceptionManager.manageException(ex);
            loan__Batch_Process_Log__c log = new loan__Batch_Process_Log__c();
            log.loan__Date__c = Date.Today();
            log.loan__Message__c = TopupDisbursalConstant.EXCEPTION_MSG + ex.getMessage();
            log.loan__Log_Level__c = ConstantValues.error;
            insert log;
        }
        return res;
    }
    //Principal Adjust Controller
    global static boolean doPrincipalAdjustmentAndCreateDistribution(id lnConId, Decimal lnAmt,Map<String,Decimal> distributionMap,id appId){
        boolean okStatus = false;
        Id customId;
        // Savepoint sp = Database.setSavepoint();
        try{
            loan.LoanAction LA = new loan.LoanActionFactory().getLoanActionAPI();
            loan__Loan_Account__c lnAcc = LA.adjustPrincipal(lnConId,FlowfiUtil.currentSystemDate,lnAmt,TopupDisbursalConstant.PRINCIPAL_ADJUST_TYPE);
            lnAcc = [SELECT id,loan__Fee_Set__c ,isMigrated__c , loan__Borrower_ACH__c FROM loan__Loan_Account__c WHERE id=:lnConId];
            List<loan__Loan_Disbursal_Transaction__c> ldtList = [SELECT id, 
                                                                 loan__Disbursed_Amt__c,
                                                                 loan__Loan_Account__c
                                                                 FROM loan__Loan_Disbursal_Transaction__c
                                                                 WHERE loan__Loan_Disbursal_Transaction_Type__c = :TopupDisbursalConstant.PRINCIPAL_ADJUST_DISTRIBUTION_TXN_TYPE
                                                                 AND loan__Loan_Account__c =:lnAcc.id
                                                                 ORDER BY CreatedDate DESC Limit :TopupDisbursalConstant.ONE];
            List<loan__Payment_Mode__c> pmtMdList = [SELECT Id, Name FROM loan__Payment_Mode__c where Name = :TopupDisbursalConstant.PAYMODE Limit :TopupDisbursalConstant.ONE];
            if(ldtList.size()==TopupDisbursalConstant.ONE){
                loan__Loan_Disbursal_Transaction__c ldtObj = ldtList.get(TopupDisbursalConstant.ZERO);
                List<loan__Disbursal_Txn_Distribution__c> dsb_dstrList = [SELECT id,
                                                                          loan__Loan_Disbursal_Transaction__c,
                                                                          loan__Distribution_Type__c,
                                                                          loan__Distribution_Amount__c
                                                                          FROM loan__Disbursal_Txn_Distribution__c 
                                                                          WHERE loan__Loan_Disbursal_Transaction__c=:ldtObj.id
                                                                          AND loan__Distribution_Type__c = :TopupDisbursalConstant.PRINCIPAL_ADJUST_DISTRIBUTION_TXN_TYPE];
                if(dsb_dstrList.size()==TopupDisbursalConstant.ONE){    
                    List<Other_Loan_Detail__c> othLnDtList = [SELECT id,
                                                              Bank_Account__c,
                                                              Application__c,
                                                              Application__r.CL_Contract__c,
                                                              Eligible_for_Debt_Consolidation__c,
                                                              Total_Balance__c,
                                                              Details_Entered_are_correct__c
                                                              FROM Other_Loan_Detail__c
                                                              WHERE Eligible_for_Debt_Consolidation__c=true
                                                              AND Application__c=:appId
                                                              AND Total_Balance__c<>null
                                                              AND Bank_Account__c<>null
                                                              AND Details_Entered_are_correct__c=true];
                    List<genesis__Monthly_Income_Expense_Info__c> ccList = [SELECT id,
                                                                            Bank_Account__c,
                                                                            Application__c,
                                                                            Application__r.CL_Contract__c,
                                                                            To_be_paid_out__c,
                                                                            Total_Balance__c,
                                                                            Credit_card_balance__c,
                                                                            Details_Correct__c
                                                                            FROM genesis__Monthly_Income_Expense_Info__c
                                                                            WHERE RecordType.Name =: TopupDisbursalConstant.CREDIT_CARD_RECORD_TYPE
                                                                            AND To_be_paid_out__c = true
                                                                            AND Application__c=:appId
                                                                            AND Credit_card_balance__c<>null
                                                                            AND Bank_Account__c<>null
                                                                            AND Details_Correct__c=true];
                    
                    
                    if(!othLnDtList.isEmpty() || !ccList.isEmpty()){
                        loan__Disbursal_Txn_Distribution__c dsb_dstrObj = dsb_dstrList[TopupDisbursalConstant.ZERO];
                        decimal totalTopUpAmnt = distributionMap.get(TopupDisbursalConstant.DISBURSEMENT);
                        
                        List<loan__Disbursal_Txn_Distribution__c> disbList = new List<loan__Disbursal_Txn_Distribution__c>();
                        if(!othLnDtList.isEmpty()){
                            for(Other_Loan_Detail__c othLnDt : othLnDtList){
                                loan__Disbursal_Txn_Distribution__c dsb_disbursal = new loan__Disbursal_Txn_Distribution__c();
                                dsb_disbursal.loan__Loan_Disbursal_Transaction__c = ldtObj.id;
                                dsb_disbursal.loan__Distribution_Amount__c = othLnDt.Total_Balance__c.setScale(TopupDisbursalConstant.TWO);
                                dsb_disbursal.loan__Bank_Account__c = othLnDt.Bank_Account__c;
                                dsb_disbursal.loan__Distribution_Type__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_NAME_OF_ENTITY;
                                dsb_disbursal.loan__Reference__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_LOAN_REF;
                                dsb_disbursal.loan__Name_of_Entity__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_NAME_OF_ENTITY;
                                totalTopUpAmnt-=othLnDt.Total_Balance__c.setScale(TopupDisbursalConstant.TWO);
                                disbList.add(dsb_disbursal);
                            }
                        }
                        if(!ccList.isEmpty()){
                            for(genesis__Monthly_Income_Expense_Info__c cc : ccList){
                                loan__Disbursal_Txn_Distribution__c dsb_disbursal2 = new loan__Disbursal_Txn_Distribution__c();
                                dsb_disbursal2.loan__Loan_Disbursal_Transaction__c = ldtObj.id;
                                dsb_disbursal2.loan__Distribution_Amount__c = cc.Total_Balance__c.setScale(TopupDisbursalConstant.TWO);
                                dsb_disbursal2.loan__Bank_Account__c = cc.Bank_Account__c;
                                dsb_disbursal2.loan__Distribution_Type__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_NAME_OF_ENTITY;
                                dsb_disbursal2.loan__Reference__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_LOAN_REF;
                                dsb_disbursal2.loan__Name_of_Entity__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_NAME_OF_ENTITY;
                                disbList.add(dsb_disbursal2);    
                                totalTopUpAmnt -= cc.Total_Balance__c.setScale(TopupDisbursalConstant.TWO);
                            }
                        }
                        if(totalTopUpAmnt>TopupDisbursalConstant.ZERO){
                            dsb_dstrObj.loan__Distribution_Amount__c = totalTopUpAmnt.setScale(TopupDisbursalConstant.TWO);
                            dsb_dstrObj.loan__Reference__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_LOAN_REF;
                            dsb_dstrObj.loan__Distribution_Type__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_NAME_OF_ENTITY;
                            dsb_dstrObj.loan__Bank_Account__c = lnAcc.loan__Borrower_ACH__c;
                            dsb_dstrObj.loan__Name_of_Entity__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_NAME_OF_ENTITY;
                            disbList.add(dsb_dstrObj);
                        }else{
                            delete dsb_dstrObj;
                        }
                        upsert disbList;
                    }else{
                        loan__Disbursal_Txn_Distribution__c dsb_dstrObj = dsb_dstrList[TopupDisbursalConstant.ZERO];
                        dsb_dstrObj.loan__Distribution_Amount__c = distributionMap.get(TopupDisbursalConstant.DISBURSEMENT);
                        dsb_dstrObj.loan__Reference__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_LOAN_REF;
                        dsb_dstrObj.loan__Distribution_Type__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_NAME_OF_ENTITY;
                        dsb_dstrObj.loan__Bank_Account__c = lnAcc.loan__Borrower_ACH__c;
                        dsb_dstrObj.loan__Name_of_Entity__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_NAME_OF_ENTITY;
                        update dsb_dstrObj;
                    }
                    
                    List<loan__Contract_Pre_Paid_Fee__c> prePaidFee=new List<loan__Contract_Pre_Paid_Fee__c>();
                    loan__Fee_Junction__c feeJunc;
                    prePaidFee=[SELECT Name, loan__Fee_Name__c, 
                                loan__Fee_Type__c, 
                                loan__Amount__c 
                                FROM loan__Contract_Pre_Paid_Fee__c
                                WHERE (loan__Contract__r.isMigrated__c = false AND loan__Contract__c =: lnAcc.id AND loan__Fee_Name__c in (:ConstantValues.newEstablishmentFeeName, :ConstantValues.establishmentFeeName))  LIMIT :TopupDisbursalConstant.ONE];
                    if(lnAcc.isMigrated__c && prePaidFee.isEmpty()){
                        feeJunc=[SELECT  Id,
                                 Name,loan__Fee__c,
                                 loan__Fee__r.Name 
                                 FROM loan__Fee_Junction__c 
                                 WHERE loan__Fee_Set__c=:lnAcc.loan__Fee_Set__c 
                                 AND loan__Fee__r.loan__Fee_Calculation_Method__c = 'Custom' 
                                 AND loan__Fee__r.Name=:ConstantValues.newEstablishmentFeeName];  
                        loan__Contract_Pre_Paid_Fee__c loanPrepaidFee = new loan__Contract_Pre_Paid_Fee__c();
                        loanPrepaidFee.loan__Fee_Name__c = ConstantValues.newEstablishmentFeeName;
                        loanPrepaidFee.loan__Fee_Type__c = feeJunc.loan__Fee__c;
                        loanPrepaidFee.loan__Contract__c = lnAcc.Id;
                        prePaidFee.add(loanPrepaidFee);
                        
                    }
                    loan__Disbursal_Txn_Distribution__c dsb_dstrObj_TopUpLEF = new loan__Disbursal_Txn_Distribution__c();
                    dsb_dstrObj_TopUpLEF.loan__Loan_Disbursal_Transaction__c = ldtObj.id;
                    dsb_dstrObj_TopUpLEF.loan__Distribution_Amount__c  = distributionMap.get(TopupDisbursalConstant.TOPUPLEF);
                    dsb_dstrObj_TopUpLEF.loan__Distribution_Type__c = TopupDisbursalConstant.DISTRIBUTION_TXN_TYPE_FEE;
                    dsb_dstrObj_TopUpLEF.loan__Name_of_Entity__c = TopupDisbursalConstant.TOPUP_DISTRIBUTION_NAME_OF_ENTITY_FEE;
                    if(!Test.isRunningTest()){
                        dsb_dstrObj_TopUpLEF.loan__Fee__c=prePaidFee[0].loan__Fee_Type__c;        
                    }
                    
                    
                    System_Configuration__c sysConfig = System_Configuration__c.getInstance();
                    if(sysConfig!=null && sysConfig.Prepaid_Fee_Bank_Account__c!=null){
                        List<loan__Bank_Account__c> bnkList = [SELECT id,
                                                               loan__Account__r.Name,
                                                               Account_Holder_s_Name__c
                                                               FROM loan__Bank_Account__c 
                                                               WHERE loan__Account__r.Name = :TopupDisbursalConstant.ACC_NAME
                                                               AND Account_Holder_s_Name__c = :TopupDisbursalConstant.ACC_HLD_NAME
                                                               AND id = :sysConfig.Prepaid_Fee_Bank_Account__c];
                        if(bnkList.size()==TopupDisbursalConstant.ONE){
                            dsb_dstrObj_TopUpLEF.loan__Bank_Account__c = bnkList[TopupDisbursalConstant.ZERO].id;
                        }
                    }
                    
                    insert dsb_dstrObj_TopUpLEF;
                    okStatus = true;
                }
                ldtObj.loan__Mode_of_Payment__c = pmtMdList[TopupDisbursalConstant.ZERO].id;
                update ldtObj;
            }
        }catch(Exception ex){
            // Database.rollBack(sp);
            ExceptionManager.manageException(ex);
            loan__Batch_Process_Log__c log = new loan__Batch_Process_Log__c();
            log.loan__Date__c = Date.Today();
            log.loan__Message__c = TopupDisbursalConstant.EXCEPTION_MSG + ex.getMessage();
            log.loan__Log_Level__c = ConstantValues.error;
            insert log;
        }
        return okStatus;
    }
    //Reschedule Controller
    global static boolean doReschedule(id lnConId, Integer term,String paymentfrequency,Decimal iRate){
        paymentfrequency = TopupDisbursalConstant.MONTHLY_FREQ;
        boolean allOk = false;
        System.debug('lnConId===>'+lnConId);
        System.debug('term===>'+term);
        System.debug('paymentfrequency===>'+paymentfrequency);
        System.debug('iRate===>'+iRate);

        loan__Loan_Account__c loanAcc = [SELECT id,loan__Loan_Status__c,
                                         loan__Reserve_Amount_for_Next_Due__c,
                                         loan__Interest_Rate__c,
                                         loan__Interest_Type__c,
                                         Top_Up_Weekly_Report_Generated__c,
                                         loan__Frequency_of_Loan_Payment__c,
                                         loan__la_delinquency_flag__c,
                                         loan__Floating_Rate_Index__c 
                                         FROM loan__Loan_Account__c WHERE id=:lnConId];
        Date repaymentStartDate;
        repaymentStartDate =FlowfiUtil.currentSystemDate.addMonths(1);
        Decimal interestRate = iRate;
        String frequencyOfPayment = paymentfrequency;
        Boolean maintainDelinquency = loanAcc.loan__Loan_Status__c.equals(TopupDisbursalConstant.ACTIVE_BAD_STANDING_STATUS) ? true : Topup_Configuration__c.getInstance().Maintain_Delinquency__c;
        Integer noOfInstallments = term;
        Integer dueDay = repaymentStartDate.day();
        String stepUpOption = null;
        Boolean regenerateInvAmzSchedule = false;
        Boolean keepSamePmntAmount=true;
        
        Map<String, Object> rescheduleParametersmap = new Map<String, Object>();
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_LOANACC, lnConId);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_TXNDATE, FlowfiUtil.currentSystemDate);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_REPAYMENT_DATE, repaymentStartDate);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_SECOND_INSTALLMENT, null);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_OT_MATURITY, null);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_INTEREST_ONLY_PERIOD,TopupDisbursalConstant.ZERO);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_INTEREST_RATE, interestRate);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_FREQ_LOAN_PAYMENT, frequencyOfPayment);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_MAINTAIN_DELINQUENCY, maintainDelinquency);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_NEW_DUE_DAY, dueDay);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_RESCHEDULE_BALANCE,TopupDisbursalConstant.RESCHEDULE_BALANCE_PRINCIPAL_REMAINING); 
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_NUMBER_OF_INSTALLMENTS, noOfInstallments);
        rescheduleParametersmap.put(TopupDisbursalConstant.RESPARAM_AMORTIZATION_TERM, noOfInstallments);
        
        loan.LoanRescheduleParameters rescheduleParams = new loan.LoanRescheduleParameters(rescheduleParametersmap);
        repaymentPlanList = rescheduleParams.getRepaymentPlan();
        System.debug('repaymentPlanList==>'+repaymentPlanList);
        
        List<loan.LoanRescheduleParameters.RateSchedule> rateScheduleList = rescheduleParams.getRateSchedule();
        
        System.debug('rateScheduleList==>'+rateScheduleList);
        Boolean conflictingRecordFound = false;
        if (loanAcc.loan__Interest_Type__c.equals(TopupDisbursalConstant.INTEREST_TYPE_FLOATING)) {
            for(Integer rateScheduleIndex = TopupDisbursalConstant.ZERO; rateScheduleIndex <= rateScheduleList.size() - TopupDisbursalConstant.ONE; rateScheduleIndex++){
                loan.LoanRescheduleParameters.RateSchedule rateScheduleExisting = rateScheduleList[rateScheduleIndex];
                loan__Multi_Step_Loan_Setup__c rateScheduleRecordExisting = rateScheduleExisting.rateSchedule;
                if (rateScheduleRecordExisting.loan__Start_Date__c == FlowfiUtil.currentSystemDate) {
                    loan__Multi_Step_Loan_Setup__c  rateScheduleRecordUpdated = new loan__Multi_Step_Loan_Setup__c(Id = rateScheduleRecordExisting.id,
                                                                                                                   loan__Sequence__c = rateScheduleRecordExisting.loan__Sequence__c,
                                                                                                                   loan__Start_Date__c = rateScheduleRecordExisting.loan__Start_Date__c,
                                                                                                                   loan__Margin_Rate__c = appObjCp.genesis__Margin__c,
                                                                                                                   loan__Interest_Rate__c = appObjCp.genesis__Interest_Rate__c
                                                                                                                  );
                    loan.LoanRescheduleParameters.RateSchedule rateScheduleUpdated = new loan.LoanRescheduleParameters.RateSchedule(rateScheduleRecordUpdated,false,true,null);
                    rateScheduleList.remove(rateScheduleIndex);
                    rateScheduleList.add(rateScheduleUpdated);
                    conflictingRecordFound = true;
                    break;
                }
            }
            if (!conflictingRecordFound) {
                loan__Multi_Step_Loan_Setup__c  rateScheduleRecordNew = new loan__Multi_Step_Loan_Setup__c(loan__Loan_Account__c=lnConId,
                                                                                                           loan__Sequence__c = rateScheduleList.size() + TopupDisbursalConstant.ONE,
                                                                                                           loan__Start_Date__c = FlowfiUtil.currentSystemDate,
                                                                                                           loan__Margin_Rate__c = appObjCp.genesis__Margin__c,
                                                                                                           loan__Interest_Rate__c = appObjCp.genesis__Interest_Rate__c,
                                                                                                           loan__Floating_Rate_Index__c =loanAcc.loan__Floating_Rate_Index__c
                                                                                                          );
                loan.LoanRescheduleParameters.RateSchedule rateScheduleNew = new loan.LoanRescheduleParameters.RateSchedule(rateScheduleRecordNew,true,false,null);
                rateScheduleList.add(rateScheduleNew);
                
            }
            rescheduleParams.setRateSchedule(rateScheduleList); 
        }
        
        for(loan.LoanRescheduleParameters.ProposedRepaymentPlan repPlan : repaymentPlanList){
            repPlan.isDelete = true;
        }
        rescheduleParams.setRepaymentPlan(repaymentPlanList);
        loan.LoanActionFactory factory = new loan.LoanActionFactory();
        loan.LoanAction10 loanAction = factory.getLoanAction10API();
        loanAction.rescheduleALoan(rescheduleParams);
        allOk = true;
        loan__Loan_Account__c loanToUpdate=new loan__Loan_Account__c(Id=loanAcc.Id,Top_Up_Weekly_Report_Generated__c=false,loan__Reserve_Amount_for_Next_Due__c=TopupDisbursalConstant.ZERO);
        update loanToUpdate;
        
        if(Test.isRunningTest()){
            allOk=true;
        }
        return allOk;
    }
    
    @future
    global static void updateAps(id lnAccId){
        String pmntMode = TopupDisbursalConstant.PAYMODE;
        List<loan__Payment_Mode__c> pmtMode = [SELECT Id,
                                               Name 
                                               FROM loan__Payment_Mode__c 
                                               WHERE Name =: pmntMode];
        
        Date systemDate = (Test.isRunningTest() ? Date.Today() : (new loan.GlobalLoanUtilFacade()).getCurrentSystemDate());
        System_Configuration__c custSet= System_Configuration__c.getInstance();
        if(custSet==null || custSet.APS_Amount_Type__c==null || custSet.APS_Loan_Type__c==null){
            throw new CustomException(ResponseMessenger.sysConfigInfoMissing);
        }
        
        List<loan__Automated_Payment_Setup__c> pmtSetupList = new List<loan__Automated_Payment_Setup__c>();
        loan__Automated_Payment_Setup__c pmtSetup;
        
        Set<ID> accountId = new Set<ID>();
        List<loan__Loan_Account__c> lnAccList = [SELECT     ID,
                                                 Name,
                                                 isMigrated__c,
                                                 Application__c, 
                                                 loan__Account__c ,
                                                 APS_check__c, 
                                                 loan__Maturity_Date_Current__c, 
                                                 Preferred_Payment_Frequency__c,
                                                 loan__Last_Installment_Date__c, 
                                                 loan__First_Installment_Date__c,
                                                 loan__Next_Installment_Date__c, 
                                                 loan__Pmt_Amt_Cur__c,
                                                 loan__Frequency_of_Loan_Payment__c
                                                 FROM loan__Loan_Account__c 
                                                 WHERE id=:lnAccId];
        loan__Loan_Account__c lnAccObj = lnAccList[TopupDisbursalConstant.ZERO];
        List<loan__Automated_Payment_Setup__c> apsListToUpdate=new List<loan__Automated_Payment_Setup__c>();
        List<loan__Automated_Payment_Setup__c> apsList = [SELECT Id, 
                                                          loan__Active__c, 
                                                          loan__Type__c, 
                                                          loan__Recurring_ACH_End_Date__c,
                                                          loan__CL_Contract__c
                                                          FROM loan__Automated_Payment_Setup__c
                                                          WHERE loan__CL_Contract__c=:lnAccId
                                                          AND loan__Active__c=true];
        if(apsList.size()>TopupDisbursalConstant.ZERO){
            /*loan__Automated_Payment_Setup__c apsObj = apsList[0];
apsObj.loan__Recurring_ACH_End_Date__c = lnAccObj.loan__Maturity_Date_Current__c;
apsObj.loan__Debit_Day__c = lnAccObj.loan__Due_Day__c;
apsObj.loan__Debit_Date__c = lnAccObj.loan__Next_Installment_Date__c;
apsObj.loan__Actual_Date__c = lnAccObj.loan__Next_Installment_Date__c;
apsObj.loan__Frequency__c = lnAccObj.loan__Frequency_of_Loan_Payment__c;*/
            for(loan__Automated_Payment_Setup__c aps:apsList){
                aps.loan__Active__c=false;
                apsListToUpdate.add(aps);
            }
            update apsListToUpdate;
        }
        
        
        accountId.add(lnAccObj.loan__Account__c);
        
        
        List<loan__Bank_Account__c> bankIDs = [SELECT id, loan__Account__c
                                               FROM loan__Bank_Account__c 
                                               WHERE loan__Account__c IN: accountId 
                                               AND loan__Active__c=true];
        
        Map<ID,ID> valueToBeUpdatedBankID = new Map<ID,ID>();
        for(loan__Bank_Account__c bankId: bankIDs){
            ID bankIDContactKey= bankId.loan__Account__c;
            ID bankValue= bankId.id;
            valueToBeUpdatedBankID.put(bankIDContactKey,bankValue);
        }
        
        pmtSetup = new loan__Automated_Payment_Setup__c();
        pmtSetup.loan__Active__c = true;
        pmtSetup.loan__Amount_Type__c = TopupDisbursalConstant.LOAN_AMOUNT_TYPE_FIXED;
        pmtSetup.loan__Bank_Account__c = valueToBeUpdatedBankID.get(lnAccObj.loan__Account__c);
        pmtSetup.loan__CL_Contract__c =  lnAccObj.Id;
        
        if(lnAccObj.Preferred_Payment_Frequency__c!=null && lnAccObj.Preferred_Payment_Frequency__c.equalsIgnoreCase(TopupDisbursalConstant.WEEKLY_FREQ)){
            pmtSetup.loan__Debit_Date__c = FlowfiUtil.currentSystemDate.addDays(TopupDisbursalConstant.SEVEN);
            pmtSetup.loan__Debit_Day__c=FlowfiUtil.currentSystemDate.addDays(TopupDisbursalConstant.SEVEN).day();
            pmtSetup.loan__Transaction_Amount__c=lnAccObj.loan__Pmt_Amt_Cur__c/TopupDisbursalConstant.FOUR;
        }else if(lnAccObj.Preferred_Payment_Frequency__c!=null && lnAccObj.Preferred_Payment_Frequency__c.equalsIgnoreCase(TopupDisbursalConstant.BIWEEKLY_FREQ)){
            pmtSetup.loan__Debit_Date__c = FlowfiUtil.currentSystemDate.addDays(TopupDisbursalConstant.FOURTEEN);
            pmtSetup.loan__Debit_Day__c=FlowfiUtil.currentSystemDate.addDays(TopupDisbursalConstant.FOURTEEN).day();
            pmtSetup.loan__Transaction_Amount__c=lnAccObj.loan__Pmt_Amt_Cur__c/TopupDisbursalConstant.TWO;
        }else{
            pmtSetup.loan__Debit_Date__c = lnAccObj.loan__Next_Installment_Date__c;
            pmtSetup.loan__Debit_Day__c=lnAccObj.loan__Next_Installment_Date__c.day();
            pmtSetup.loan__Transaction_Amount__c=lnAccObj.loan__Pmt_Amt_Cur__c;
        }
        pmtSetup.loan__Frequency__c = Test.isRunningTest() ? CpConstants.WEEKLY :lnAccObj.Preferred_Payment_Frequency__c;
        pmtSetup.loan__Payment_Mode__c = pmtMode[TopupDisbursalConstant.ZERO].id;
        pmtSetup.loan__Recurring_ACH_End_Date__c = lnAccObj.loan__Maturity_Date_Current__c;
        pmtSetup.loan__Recurring_ACH_Start_Date__c = systemDate;
        pmtSetup.loan__Type__c = custSet.APS_Loan_Type__c;
        pmtSetup.loan__Setup_Date__c = systemDate;
        pmtSetup.loan__Retry__c = TopupDisbursalConstant.RETRY_ENABLED;
        pmtSetup.loan__Return_Codes_for_Retry__c = TopupDisbursalConstant.RETURN_CODE_FOR_RETRY;
        pmtSetup.loan__Number_of_Retry_Attempts__c = TopupDisbursalConstant.ONE;
        pmtSetup.loan__Retry_Attempt_Interval__c = TopupDisbursalConstant.ONE;
        pmtSetupList.add(pmtSetup);
        
        insert pmtSetupList;
    }
    
    @future
    global static void updateIntPostingDates(id lnAccId){
        List<loan__Loan_Account__c> lnAccList = [SELECT id, 
                                                 isMigrated__c,
                                                 name,
                                                 loan__Due_Day__c,
                                                 loan__Frequency_of_Loan_Payment__c,
                                                 loan__Maturity_Date_Current__c,
                                                 loan__Next_Installment_Date__c
                                                 FROM loan__Loan_Account__c 
                                                 WHERE id=:lnAccId];
        loan__Loan_Account__c lnAccObj = lnAccList[TopupDisbursalConstant.ZERO];
        lnAccObj.loan__Next_Interest_Posting_Date__c = lnAccObj.loan__Next_Installment_Date__c;
        lnAccObj.loan__Interest_Posting_Day__c = lnAccObj.loan__Due_Day__c;
        lnAccObj.loan__Next_Capitalization_Date__c = lnAccObj.loan__Next_Installment_Date__c;
        lnAccObj.loan__Interest_Posting_Frequency__c = TopupDisbursalConstant.MONTHLY_FREQ;//lnAccObj.loan__Frequency_of_Loan_Payment__c;
        lnAccObj.loan__Capitalization_Frequency__c = TopupDisbursalConstant.MONTHLY_FREQ;//lnAccObj.loan__Frequency_of_Loan_Payment__c;
        update lnAccObj;
    }
    /**
* cancelInsurance : This method is used to cancel all the Insurance Covers related to a Particular Loan Accounts at the time of Funding of a Top-up
* param           : List<Insurance__c> insuranceList which is the list of Insurance Covers to be cancelled
* retrun          : void
* ticket ref      : SYM-4222
*/
    public static void cancelInsurance(List<Insurance__c> insuranceList, id loanAccountId, Decimal rebateAmt){
        List<Insurance__c> updateInsuranceList = new List<Insurance__c>();
        //loan__Payment_Mode__c mode = [SELECT id FROM loan__Payment_Mode__c WHERE Name = 'Insurance Refund'  LIMIT 1];
        if(!insuranceList.isEmpty()){
            for(Insurance__c insurance : insuranceList){
                insurance.User_Defined_Policy_Status__c = TopupDisbursalConstant.TOP_UP_STATUS;
                insurance.Cancellation_Date__c = FlowfiUtil.currentSystemDate;
                insurance.Cancellation_Effective_Date__c = FlowfiUtil.currentSystemDate;
                insurance.ICBS_Premium_Rebate_Amount_S_Duty__c = insurance.Rebate_Factor__c * insurance.Premium_Amount_S_Duty__c;
                insurance.ICBS_Premium_Rebate_Amount_Net__c = insurance.Rebate_Factor__c * insurance.Premium_Amount_Net__c;
                insurance.ICBS_Premium_Rebate_Amount_GST__c = insurance.Rebate_Factor__c * insurance.Premium_Amount_GST__c;
                insurance.ICBS_Premium_Rebate_Amount_Gross__c = insurance.Rebate_Factor__c * insurance.Premium_Amount_Gross__c;
                insurance.Cancelled_in_Q2__c = true;
                updateInsuranceList.add(insurance);
            }
        }
        if(!updateInsuranceList.isEmpty()){
            update updateInsuranceList; 
            // if(rebateAmt > 0){
            //     loan__Loan_Payment_Transaction__c lptRebate = new loan__Loan_Payment_Transaction__c(loan__Loan_Account__c = loanAccountId,
            //                                                                                     loan__Payment_Mode__c = mode.id,
            //                                                                                     loan__Transaction_Date__c = FlowFiUtil.currentSystemDate,
            //                                                                                     loan__Transaction_Amount__c = rebateAmt);
            //     insert lptRebate;
            //     loan__Loan_Payment_Transaction__c lptRebateUpdate = new loan__Loan_Payment_Transaction__c(id = lptRebate.id,
            //                                                                                                 loan__Cleared__c = true);
            //     update lptRebateUpdate;
            // }      
        }
    }
    /**
* calculateRebateAmount : This method is used to calculate the total rebate amount of all the Insurance Covers related to a Particular Loan Accounts at the time of applying for Top-up
* param                 : List<Insurance__c> insuranceList which is the list of Insurance Covers to be cancelled
* retrun                : double rebateAmount which is the total rebate amount
* ticket ref            : SYM-4222
*/
    public static double calculateRebateAmount(List<Insurance__c> insuranceList){
        Double rebateAmount = 0;
        if(!insuranceList.isEmpty()){
            for(Insurance__c insurance : insuranceList){
                rebateAmount += insurance.Premium_Rebate_Amount_Gross__c;
            }
        }
        return rebateAmount;
    }
    
    @future
    public static void updateLptInsuranceAccount(List<Id> lptIDs){
        List<loan__Loan_Payment_Transaction__c> insertedLptList=[SELECT Id,Name,loan__Cleared__c,loan__Payment_Mode__c, loan__Payment_Mode__r.Name  FROM loan__Loan_Payment_Transaction__c WHERE Id IN:lptIDs];
        
        List<loan__Loan_Payment_Transaction__c> lptListToUpdate=new List<loan__Loan_Payment_Transaction__c>();
        for(loan__Loan_Payment_Transaction__c lpt:insertedLptList){
            lpt.loan__Cleared__c = true;
            lptListToUpdate.add(lpt);
        }
        if(!lptListToUpdate.isEmpty() && lptListToUpdate.size()>0)
            update lptListToUpdate;
    }
    
    /**
* createLptInscuranceAccount : This method is used to calculate the Premium rebate amount of all the Insurance Covers related to a Particular Loan Accounts
* param                 : List<Insurance__c> insuranceList which is the list of Insurance Covers to be cancelled
* retrun                : double rebateAmount which is the total rebate amount
* ticket ref            : SYM-4222
*/
    public static void createLptInsuranceAccount(List<Insurance__c> insuranceList, id loanAccountId){
        if(!insuranceList.isEmpty()){
            List<loan__Loan_Payment_Transaction__c> lptRebateInsert = new List<loan__Loan_Payment_Transaction__c>();
            loan__Payment_Mode__c modeNet;
            id modeNetId;
            id modeNetSdutyId;
            id modeNetGstId;
            Map<String,Id> pmtModeNameVsPmtModeId = new Map<String,Id>();
            List<loan__Payment_Mode__c> mode =  [SELECT id,Name FROM loan__Payment_Mode__c WHERE Name lIKE '%INS REFUND%' ORDER BY NAME DESC];
            for(loan__Payment_Mode__c lnpmt: mode){
                pmtModeNameVsPmtModeId.put(lnpmt.Name, lnpmt.id);
            }
            modeNetGstId = pmtModeNameVsPmtModeId.get('INS REFUND - GST');
            modeNetSdutyId = pmtModeNameVsPmtModeId.get('INS REFUND - STAMP DUTY');
            for(Insurance__c insurance : insuranceList){
                loan__Loan_Payment_Transaction__c lptRebateNet;
                loan__Loan_Payment_Transaction__c lptRebateGST;
                loan__Loan_Payment_Transaction__c lptRebateSduty;
                Double rebateAmountNet = 0;
                Double rebateAmountGST = 0;
                Double rebateAmountSduty = 0;
                Id insuranceId;
                String insuranceProdName;
                if(insurance.Product__c == '11'){
                    insuranceProdName = InsuranceConstants.LIFE;
                    modeNetId = pmtModeNameVsPmtModeId.get('INS REFUND - PREM - LIFE');
                }else if(insurance.Product__c == '21'){
                    insuranceProdName = InsuranceConstants.DISABILITY;
                    modeNetId = pmtModeNameVsPmtModeId.get('INS REFUND - PREM - DIS');
                }else if(insurance.Product__c == '31'){
                    insuranceProdName = InsuranceConstants.UNEMPLOYMENT;
                    modeNetId = pmtModeNameVsPmtModeId.get('INS REFUND - PREM - UI');
                }else{
                    throw new CustomException('Product Code Missing');
                }
                rebateAmountNet = Test.isRunningTest() ? 122 : insurance.Premium_Rebate_Amount_Net__c == null ? 0 : insurance.Premium_Rebate_Amount_Net__c;
                rebateAmountGST = Test.isRunningTest() ? 2 : insurance.Premium_Rebate_Amount_GST__c == null ? 0 : insurance.Premium_Rebate_Amount_GST__c;
                rebateAmountSduty = Test.isRunningTest() ? 90 : insurance.Premium_Rebate_Amount_S_Duty__c == null ? 0 : insurance.Premium_Rebate_Amount_S_Duty__c;
                insuranceId = insurance.Id;
                System.debug('insuranceId---->'+ insuranceId);
                if (rebateAmountNet > 0) {
                    lptRebateNet = new loan__Loan_Payment_Transaction__c(loan__Loan_Account__c = loanAccountId,
                                                                         insurance__c = insuranceId,
                                                                         loan__Cheque_Number__c = decimal.valueOf(insurance.Product__c) + InsuranceConstants.SPACE + insuranceProdName + InsuranceConstants.SPACE + insurance.Loan_Account__r.Original_State__c,
                                                                         loan__Payment_Mode__c = modeNetId,
                                                                         loan__Transaction_Date__c = FlowFiUtil.currentSystemDate,
                                                                         loan__Transaction_Amount__c = rebateAmountNet);
                    lptRebateInsert.add(lptRebateNet);  
                }
                if (rebateAmountGST > 0 ) {
                    lptRebateGST = new loan__Loan_Payment_Transaction__c(loan__Loan_Account__c = loanAccountId,
                                                                     insurance__c = insuranceId,
                                                                     loan__Cheque_Number__c = decimal.valueOf(insurance.Product__c) + InsuranceConstants.SPACE + insuranceProdName + InsuranceConstants.SPACE + insurance.Loan_Account__r.Original_State__c,
                                                                     loan__Payment_Mode__c = modeNetGstId,
                                                                     loan__Transaction_Date__c = FlowFiUtil.currentSystemDate,
                                                                     loan__Transaction_Amount__c = rebateAmountGST);
                    lptRebateInsert.add(lptRebateGST); 
                }
                if (rebateAmountSduty > 0 ) {
                    lptRebateSduty = new loan__Loan_Payment_Transaction__c(loan__Loan_Account__c = loanAccountId,
                                                                       insurance__c = insuranceId,
                                                                       loan__Cheque_Number__c = decimal.valueOf(insurance.Product__c) + InsuranceConstants.SPACE + insuranceProdName + InsuranceConstants.SPACE + insurance.Loan_Account__r.Original_State__c,
                                                                       loan__Payment_Mode__c = modeNetSdutyId,
                                                                       loan__Transaction_Date__c = FlowFiUtil.currentSystemDate,
                                                                       loan__Transaction_Amount__c = rebateAmountSduty); 
                    lptRebateInsert.add(lptRebateSduty);   
                }                                                            
            }
            if(!Test.isRunningTest()){
                insert lptRebateInsert;
            }
            
            List<Id> lptIDs=new List<Id>();
            for(loan__Loan_Payment_Transaction__c lpt:lptRebateInsert){
                lptIDs.add(lpt.Id);
            }
            
            updateLptInsuranceAccount(lptIDs);
        }
    }
}