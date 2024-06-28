/**
 * @description       : Stores Expense details of borrower, in Broker Portal
 * @author            : Sourabh Dadhich
 * @group             : Portal API
 * @last modified on  : 12-18-2023
 * @last modified by  : Supriyo Seni
**/
public without sharing class BPStoreExpense implements PortalActionAdapter{
    Map<String,Object> resFieldsMap = new Map<String, Object>();
    List<String> paramKeysList;
    private clcommon.Response res;
    String currentPage;
    String appId;
    String partyType;
    String expenseJson;
    String loanJson;
    String otherLoanJson;
    String ccOtherJson;
    String ccJson;
    String topup;
    clcommon__party__c partyBorrower = new clcommon__party__c();
    genesis__Applications__c app = new genesis__Applications__c();
    Decimal reqLoanAmount = 0.0;
    Decimal totalLoanAmount = 0.0;
    Boolean isDebtCon = false;
    String errMsg ;
    Boolean jointApplication = false;
    private final static String AUTO =  BPCreateQQActionConstants.AUTO;
    private final static String SECURITY_INFO_INCOMPLETE = BPCreateQQActionConstants.SECURITY_INFO_INCOMPLETE;

    /**
    * @description | This is a constructor which intializes the response AND the list of param keys
    * @author Supriyo Seni | 12-15-2023 
    **/
    public BPStoreExpense(){
        res = new clcommon.Response();
        paramKeysList = new List<String>();
        paramKeysList.add(BPCreateQQActionConstants.APPID);
        paramKeysList.add(BPCreateQQActionConstants.PARTY_TYPE);
        paramKeysList.add(BPCreateQQActionConstants.EXP_JSON);
        paramKeysList.add(BPCreateQQActionConstants.CRED_JSON);
        paramKeysList.add(BPCreateQQActionConstants.OTHERLOANJSON);
        paramKeysList.add(BPCreateQQActionConstants.CRED_DET_JSON);
        paramKeysList.add(BPCreateQQActionConstants.OTHER_LOAN_DET_JSON);
        paramKeysList.add(BPCreateQQActionConstants.TOPUP);
    }

    /**
    * @description | This method fetches the information, then filters out the JSON AND parses
    * @author Supriyo Seni | 12-15-2023 
    * @param param 
    **/
    public void setParams(Map<String, Object> param){
        try{
            Map<String,Object> customParamMap = new Map<String,Object>();
            // Validate Param Map
            ValidationUtil.validateObjectNotNull(param,CpConstants.PARAMMAP_BLANK);
            ValidationUtil.throwErrorOnCondition(param.isEmpty(),CpConstants.PARAMMAP_BLANK);
            for(String paramKey : paramKeysList){
                ValidationUtil.throwErrorOnCondition(!param.containsKey(paramKey),CpConstants.MISSING_PARAM + paramKey);
                ValidationUtil.validateObjectNotNull(param.get(paramKey),CpConstants.MISSING_PARAMVALUE + paramKey);
                String filteredVal = String.valueOf(param.get(paramKey));
                /*-----REGEX Check------*/
                ValidationUtil.throwErrorOnCondition(!FlowfiUtil.regexCheckOnJson(paramKey,filteredVal),CpConstants.REGEX_FAILED + paramKey);
                customParamMap.put(paramKey,filteredVal);
            }
            this.appId = String.valueOf(customParamMap.get(BPCreateQQActionConstants.APPID));
            this.partyType = String.valueOf(customParamMap.get(BPCreateQQActionConstants.PARTY_TYPE));
            this.expenseJson = String.valueOf(customParamMap.get(BPCreateQQActionConstants.EXP_JSON)).replaceAll(CpConstants.NEW_RECORD_ID, CpConstants.BLANK);
            this.ccJson = String.valueOf(customParamMap.get(BPCreateQQActionConstants.CRED_JSON));
            this.loanJson = String.valueOf(customParamMap.get(BPCreateQQActionConstants.OTHERLOANJSON));
            this.ccOtherJson = String.valueOf(customParamMap.get(BPCreateQQActionConstants.CRED_DET_JSON)).replaceAll(CpConstants.NEW_RECORD_ID, CpConstants.BLANK);
            this.otherLoanJson = String.valueOf(customParamMap.get(BPCreateQQActionConstants.OTHER_LOAN_DET_JSON)).replaceAll(CpConstants.NEW_RECORD_ID, CpConstants.BLANK);
            this.topup = String.valueOf(customParamMap.get(BPCreateQQActionConstants.TOPUP));
        }catch(Exception ex){
            res = (ex.getTypeName().equals(CpConstants.CUSTOMEXCEPTIONTYPE)) ? FlowfiUtil.getErrorMessageResponse(e.getMessage()) :  FlowfiUtil.getErrorResponse(CpConstants.SOMETHINGWENTWRONG);
            insert ExceptionManager.getCLCommonLog(ex,CpConstants.GENESIS);
            ExceptionManager.manageException(ex);
        }
    }

    /**
    * @description | This method sets response to send back to portal
    * @author Supriyo Seni | 12-15-2023 
    **/
    public void execute(){
        SavePoint sp = Database.setSavePoint();
        try{
            /*------Checking if the current user profile is Community Broker or not------*/
                        /*-----Broker Check against the application-----*/
            ValidationUtil.brokerProfileCheck();
            // if(!(FlowfiUtil.brokerUserCheck() && BrokerPortalSecurityUtil.brokerAccessChecking())){
            //     throw new CustomException(CpConstants.ACCESS_DENIED);
            // }
            this.partyType = String.isNotBlank(this.partyType) ? this.partyType.trim().capitalize() : CpConstants.BLANK;
            List<clcommon__party__c> partyBorrowerList = [SELECT id,
                                                                clcommon__Contact__c,
                                                                clcommon__Account__c,
                                                                Do_you_have_any_credit_card__c,
                                                                Do_you_have_any_other_loans__c 
                                                            FROM clcommon__party__c 
                                                            WHERE genesis__Application__c =: appId 
                                                            AND clcommon__Type__r.Name =: partyType
                                                            WITH SYSTEM_MODE
                                                            LIMIT 1];
            ValidationUtil.validateObjectListNotNull(partyBorrowerList,CpConstants.ACCOUNT_NOTFOUND);
            this.partyBorrower = partyBorrowerList[0];
            List<genesis__Applications__c> appList = [SELECT id,
                                                            Portal_Page__c,
                                                            genesis__Status__c,
                                                            Joint_Application__c,
                                                            Loan_Purposes__c,
                                                            genesis__Loan_Amount__c,
                                                            Product_Name__c,
                                                            App_Submission_Count__c
                                                        FROM genesis__Applications__c 
                                                        WHERE id =: appId
                                                        WITH SYSTEM_MODE
                                                        LIMIT 1];
            ValidationUtil.validateObjectListNotNull(appList,CpConstants.APPLICATION_NOTFOUND);
            this.app = appList[0];
            if(app.genesis__Loan_Amount__c != null){
                reqLoanAmount = app.genesis__Loan_Amount__c;
                jointApplication = app.Joint_Application__c;
            }
            if(ValidationUtil.getAndResults(new List<Boolean> {String.isNotBlank(app.Loan_Purposes__c),app.Loan_Purposes__c.containsIgnoreCase(CpConstants.DEBT_CON_PURPOSE)})){
                isDebtCon = true;
            }
            storeExpense();
            if(getOrResults(new List<Boolean>{getOrResults(new List<Boolean>{app.Joint_Application__c, partyType == BPCreateQQActionConstants.CO_BORROWER}),getOrResults(new List<Boolean>{!app.Joint_Application__c, partyType == BPCreateQQActionConstants.BORROWER})})){
                this.app.genesis__Status__c = getApplicationStatus(appList);
                // if(appList[0].Product_Name__c == AUTO){
                //     this.app.genesis__Status__c = SECURITY_INFO_INCOMPLETE;
                // }else{
                //     if(String.isNotBlank(this.topup) && this.topup.equalsIgnoreCase(BPCreateQQActionConstants.TRUE_VAL)){
                //         this.app.genesis__Status__c = BPCreateQQActionConstants.SUBMISSION_PENDING;
                //     }else{
                //         this.app.genesis__Status__c = BPCreateQQActionConstants.CONFIRMATION_PENDING;
                //     }
                // }
                if(app.App_Submission_Count__c < 1){
                    List<genesis__Applications__c> applicationToUpdateList = new List<genesis__Applications__c> {this.app};
                    DMLUtil.updateSObjectList(applicationToUpdateList, true);
                    // update this.app; 
                }else if (getAndResults(new List<Boolean>{app.App_Submission_Count__c >= 1,getOrResults(new List<Boolean>{
                        app.genesis__status__c == BPCreateQQActionConstants.REFERRED_BROKER,
                        app.genesis__status__c == BPCreateQQActionConstants.RETURNED_BROKER,
                        app.genesis__status__c == BPCreateQQActionConstants.CONDITIONALLY_APPROVED
                    })
                })) {
                    res = FlowfiUtil.getSuccessResponse(CpConstants.SUCCESS, this.resFieldsMap);
                }
                // else if(app.App_Submission_Count__c >= 1 && (app.genesis__status__c == BPCreateQQActionConstants.REFERRED_BROKER || app.genesis__status__c == BPCreateQQActionConstants.RETURNED_BROKER || app.genesis__status__c == BPCreateQQActionConstants.CONDITIONALLY_APPROVED)){
                //     res = FlowfiUtil.getSuccessResponse(CpConstants.SUCCESS, this.resFieldsMap);
                // }
            }
            
            res = FlowfiUtil.getSuccessResponse(CpConstants.SUCCESS, this.resFieldsMap);
        }catch(exception ex){
            Database.rollback(sp);
            res = getExceptionResponse(ex);
            // if(e.getTypeName() == CpConstants.CUSTOMEXCEPTIONTYPE){
            //     if(e.getMessage().equalsIgnoreCase(CpConstants.ADD_CC_OR_LOAN_FOR_DEBT_CON) || e.getMessage().equalsIgnoreCase(CpConstants.TOTAL_DEBT_AMOUNT_GREATER) ){
            //         res = FlowfiUtil.getErrorMessageResponse(e.getMessage());
            //     }else{
            //         res = FlowfiUtil.getErrorResponse(e.getMessage());
            //     }
            // }else{
            //     res = FlowfiUtil.getErrorResponse(CpConstants.SOMETHINGWENTWRONG);
            // }
            insert ExceptionManager.getCLCommonLog(ex,CpConstants.GENESIS);
            ExceptionManager.manageException(ex);
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param ex 
    * @return clcommon.Response 
    **/
    public clcommon.Response getExceptionResponse(Exception ex){
        if(ex.getTypeName() == CpConstants.CUSTOMEXCEPTIONTYPE){
            if(getOrResults(new List<Boolean>{ex.getMessage().equalsIgnoreCase(CpConstants.ADD_CC_OR_LOAN_FOR_DEBT_CON),
                    ex.getMessage().equalsIgnoreCase(CpConstants.TOTAL_DEBT_AMOUNT_GREATER)})){
                return FlowfiUtil.getErrorMessageResponse(ex.getMessage());
            }else{
                return FlowfiUtil.getErrorResponse(ex.getMessage());
            }
        }else{
            return FlowfiUtil.getErrorResponse(CpConstants.SOMETHINGWENTWRONG);
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param appList 
    * @return String 
    **/
    public String getApplicationStatus(List<genesis__Applications__c> appList ){
        if(appList[0].Product_Name__c == AUTO){
            return SECURITY_INFO_INCOMPLETE;
        }else if(getAndResults(new List<Boolean>{String.isNotBlank(this.topup),this.topup.equalsIgnoreCase(BPCreateQQActionConstants.TRUE_VAL)})){
                return BPCreateQQActionConstants.SUBMISSION_PENDING;
        }else{
            return BPCreateQQActionConstants.CONFIRMATION_PENDING;
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    **/
    public void storeExpense(){
        Boolean creditCard = false;
        Boolean otherLoan = false;
        upsertExpense();
        if(hasCC()){
            creditCard = true;
            upsertCC();
        }else{
            deleteCreditCard();
        }
        if(hasOtherLoan()){
            otherLoan = true;
            upsertOtherLoan();
        }else{
            deleteOtherLoan();
        }
        updateParty(creditCard,otherLoan);
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @return clcommon.Response 
    **/
    public clcommon.Response getPortalResponse(){
        return res;
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    **/
    public void upsertExpense(){
        List<genesis__Monthly_Income_Expense_Info__c > expenseInfo = new List<genesis__Monthly_Income_Expense_Info__c>();
        if(String.isNotBlank(this.expenseJson)){
            try{
                expenseInfo = (List<genesis__Monthly_Income_Expense_Info__c >) System.JSON.deserialize((this.expenseJson), List<genesis__Monthly_Income_Expense_Info__c>.class);
            }catch(Exception ex){
                throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.EXP_JSON);
            }
        }
        ValidationUtil.throwErrorOnCondition(expenseInfo.size() != 1,BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.EXP_JSON);
        //if(expenseInfo.size() == 1){
        RecordType rt = [SELECT Id 
                        FROM RecordType 
                        WHERE sobjecttype =: CpConstants.GENESIS_MONTHLY_INCOME_EXPENSE_INFO 
                        AND name in (:CpConstants.EXPENSE)
                        WITH SYSTEM_MODE];
        if(String.isNotBlank(expenseInfo[0].Residential_Status__c)){
            updateAccount(expenseInfo[0].Residential_Status__c);
        }
        if(String.isBlank(expenseInfo[0].Id)){
            deleteExpense(rt.Id);
            expenseInfo[0].Id = null;
            expenseInfo[0].Application__c = this.appId;
            expenseInfo[0].Party__c = this.partyBorrower.Id;
            expenseInfo[0].RecordTypeId = rt.Id;
            DMLUtil.insertSObjectList(expenseInfo, true);
            //insert expenseInfo;
        }else{
            ValidationUtil.throwErrorOnCondition(!checkExpenseDetails(expenseInfo,rt.Id),BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.EXP_JSON);
            //if(checkExpenseDetails(expenseInfo,rt.Id)){
            DMLUtil.updateSObjectList(expenseInfo, true);
            //update expenseInfo;
            // }else{
            //     throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.EXP_JSON);
            // }
        }
        // }else{
        //     throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.EXP_JSON);
        // }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param rtId 
    **/
    public void deleteExpense(String rtId){
        if(String.isNotBlank(rtId)){
            List<genesis__Monthly_Income_Expense_Info__c > consolidatedList = [SELECT Id
                                                                                FROM genesis__Monthly_Income_Expense_Info__c
                                                                                WHERE Application__c =: appId
                                                                                AND Party__c =: partyBorrower.Id
                                                                                AND RecordTypeId =: rtId
                                                                                WITH SYSTEM_MODE];
            if(consolidatedList.size() > 0){
                DMLUtil.deleteSObjectList(consolidatedList, true);
                //delete consolidatedList;
            }
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param expenseInfo 
    * @param rtId 
    * @return Boolean 
    **/
    public Boolean checkExpenseDetails(List<genesis__Monthly_Income_Expense_Info__c > expenseInfo, String rtId){
        List<genesis__Monthly_Income_Expense_Info__c > otherLoanDeleteList = new List<genesis__Monthly_Income_Expense_Info__c>();
        Boolean result = false;
        if(String.isBlank(rtId)){
            return result;
        }
        List<genesis__Monthly_Income_Expense_Info__c > consolidatedList = [SELECT Id
                                                                            FROM genesis__Monthly_Income_Expense_Info__c
                                                                            WHERE Application__c =: appId
                                                                            AND Party__c =: partyBorrower.Id
                                                                            AND RecordTypeId =: rtId
                                                                            WITH SYSTEM_MODE];
        if(consolidatedList.size() > 0){
            for(genesis__Monthly_Income_Expense_Info__c expDetails : consolidatedList){
                if(compareIds(expDetails.id,expenseInfo[0].Id)){
                    result = true;
                }else{
                    otherLoanDeleteList.add(expDetails);
                }
            }
        }
        if(otherLoanDeleteList.size() > 0){
            List<genesis__Applications__c> appList = [SELECT id,
                                                            App_Submission_Count__c 
                                                    FROM genesis__Applications__c 
                                                    WHERE id = :appId 
                                                    WITH SYSTEM_MODE
                                                    LIMIT 1];
            if(appList[0].App_Submission_Count__c < 1){
                DMLUtil.deleteSObjectList(otherLoanDeleteList, true);
                //delete otherLoanDeleteList;
            }
        }
        //if(String.isNotBlank(rtId)){
            // List<genesis__Monthly_Income_Expense_Info__c > otherLoanDeleteList = new List<genesis__Monthly_Income_Expense_Info__c>();
            // List<genesis__Monthly_Income_Expense_Info__c > consolidatedList = [SELECT Id
            //                                                                     FROM genesis__Monthly_Income_Expense_Info__c
            //                                                                     WHERE Application__c =: appId
            //                                                                     AND Party__c =: partyBorrower.Id
            //                                                                     AND RecordTypeId =: rtId];
            // if(consolidatedList.size() > 0){
            //     for(genesis__Monthly_Income_Expense_Info__c expDetails : consolidatedList){
            //         if(compareIds(expDetails.id,expenseInfo[0].Id)){
            //             result = true;
            //         }else{
            //             otherLoanDeleteList.add(expDetails);
            //         }
            //     }
            // }
            // if(otherLoanDeleteList.size() > 0){
            //     List<genesis__Applications__c> appList = [SELECT id,App_Submission_Count__c FROM genesis__Applications__c WHERE id = :appId LIMIT 1];
            //     if(appList[0].App_Submission_Count__c < 1){
            //         delete otherLoanDeleteList;
            //     }
            // }
        //}
        return result;
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param firstId 
    * @param secondId 
    * @return Boolean 
    **/
    public Boolean compareIds(String firstId, String secondId){
        Boolean result = false;
        if(ValidationUtil.getAndResults(new List<Boolean>{String.isNotBlank(firstId),String.isNotBlank(secondId),(firstId.length() >= 15),(secondId.length() >= 15)})){
            firstId = (firstId.length() >= 18) ? firstId.substring(0,15) : firstId;
            secondId = (secondId.length() >= 18) ? secondId.substring(0,15) : secondId;
            if(firstId.equalsIgnoreCase(secondId)){
                result = true;
            }
        }
        // if(String.isNotBlank(firstId) && String.isNotBlank(secondId) && (firstId.length() >= 15) && (secondId.length() >= 15)){
        //     firstId = (firstId.length() >= 18) ? firstId.substring(0,15) : firstId;
        //     secondId = (secondId.length() >= 18) ? secondId.substring(0,15) : secondId;
        //     if(firstId.equalsIgnoreCase(secondId)){
        //         result = true;
        //     }
        // }
        return result;
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @return Boolean 
    **/
    public Boolean hasCC(){
        Boolean result = false;
        List<clcommon__Party__c > partyList = new List<clcommon__Party__c>();
        if(String.isNotBlank(this.ccJson)){
            try{
                partyList = (List<clcommon__Party__c >) System.JSON.deserialize((this.ccJson), List<clcommon__Party__c>.class);
            }catch(Exception ex){
                throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.CRED_JSON);
            }
        }
        ValidationUtil.throwErrorOnCondition(partyList.size() != 1,BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.CRED_JSON);
        if(partyList[0].Do_you_have_any_credit_card__c.equalsIgnoreCase(BPCreateQQActionConstants.YES)){
            result = true;
        }
        return result;
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @return Boolean 
    **/
    public Boolean hasOtherLoan(){
        Boolean result = false;
        List<clcommon__Party__c > partyList = new List<clcommon__Party__c>();
        if(String.isNotBlank(this.loanJson)){
            try{
                partyList = (List<clcommon__Party__c >) System.JSON.deserialize((this.loanJson), List<clcommon__Party__c>.class);
            }catch(Exception ex){
                throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.OTHERLOANJSON);
            }
        }
        ValidationUtil.throwErrorOnCondition(partyList.size() != 1,BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.OTHERLOANJSON);
        if(partyList[0].Do_you_have_any_other_loans__c.equalsIgnoreCase(BPCreateQQActionConstants.YES)){
            result = true;
        }
        return result;
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param creditCard 
    * @param otherLoan 
    **/
    public void updateParty(Boolean creditCard, Boolean otherLoan){
        if(getAndResults(new List<Boolean>{isDebtCon, getOrResults(new List<Boolean>{!jointApplication, getAndResults(new List<Boolean>{jointApplication,partyType == BPCreateQQActionConstants.BORROWER})})})) {
            ValidationUtil.throwErrorOnCondition(getAndResults(new List<Boolean>{!creditCard, !otherLoan, !jointApplication}),CpConstants.ADD_CC_OR_LOAN_FOR_DEBT_CON);
            ValidationUtil.throwErrorOnCondition(reqLoanAmount < totalLoanAmount,CpConstants.TOTAL_DEBT_AMOUNT_GREATER);
            List<genesis__Monthly_Income_Expense_Info__c> ccRecords = getCCRecord();
            List<Other_loan_detail__c> otherloanDetails = [SELECT Id, 
                                                                    Eligible_for_Debt_Consolidation__c, 
                                                                    Loan_Type__c, 
                                                                    Loan_Balance__c,
                                                                    Loan_Limit__c 
                                                            FROM Other_loan_detail__c 
                                                            WHERE Application__c =: appId
                                                            AND party__c =: partyBorrower.id
                                                            WITH SYSTEM_MODE];
            Integer countDbtConLoans = 0;
            for(genesis__Monthly_Income_Expense_Info__c obj : ccRecords){
                countDbtConLoans = updateCount(obj.To_be_paid_out__c, countDbtConLoans);
            }
            for(Other_loan_detail__c obj : otherloanDetails){
                countDbtConLoans = updateCount(obj.Eligible_for_Debt_Consolidation__c, countDbtConLoans);
            }
            ValidationUtil.throwErrorOnCondition(getAndResults(new List<Boolean>{countDbtConLoans==0,!jointApplication}),CpConstants.ADD_CC_OR_LOAN_FOR_DEBT_CON);
        }else if (getAndResults(new List<Boolean>{isDebtCon,getAndResults(new List<Boolean>{jointApplication,partyType == BPCreateQQActionConstants.CO_BORROWER})})) {
            List<genesis__Monthly_Income_Expense_Info__c> ccRecords = getALLCCRecord();
            List<Other_loan_detail__c> otherloanDetails = [SELECT Id, 
                                                                    Eligible_for_Debt_Consolidation__c, 
                                                                    Loan_Type__c, 
                                                                    Loan_Balance__c,
                                                                    Loan_Limit__c 
                                                            FROM Other_loan_detail__c 
                                                            WHERE Application__c =: appId
                                                            WITH SYSTEM_MODE];
                                                    
            Integer countDbtConLoans = 0;
            for(genesis__Monthly_Income_Expense_Info__c obj : ccRecords){
                countDbtConLoans = updateCount(obj.To_be_paid_out__c, countDbtConLoans);
            }
            for(Other_loan_detail__c obj : otherloanDetails){
                countDbtConLoans = updateCount(obj.Eligible_for_Debt_Consolidation__c, countDbtConLoans);
                // if(obj.Eligible_for_Debt_Consolidation__c == true){
                //     countDbtConLoans ++;
                // }
            }
            ValidationUtil.throwErrorOnCondition(countDbtConLoans == 0,CpConstants.ADD_CC_OR_LOAN_FOR_DEBT_CON);
            totalLoanAmount = 0;
            totalLoanAmount = getTotalDebConsolidationCCAmount(ccRecords) + getTotalDebConsolidationOLAmount(otherloanDetails);
            ValidationUtil.throwErrorOnCondition(reqLoanAmount < totalLoanAmount,CpConstants.TOTAL_DEBT_AMOUNT_GREATER);
            // if(reqLoanAmount < totalLoanAmount){
            //     throw new CustomException(CpConstants.TOTAL_DEBT_AMOUNT_GREATER);
            // } 
        }
        updateBorrowerParty();
        
        //if(isDebtCon == true ){

            //if(jointApplication == false || (jointApplication == true && partyType == BPCreateQQActionConstants.BORROWER)){
                // if(creditCard == false && otherLoan == false  && jointApplication == false ){
                    
                //     throw new CustomException(CpConstants.ADD_CC_OR_LOAN_FOR_DEBT_CON);
                // }
                // if(reqLoanAmount < totalLoanAmount){
                //     throw new CustomException(CpConstants.TOTAL_DEBT_AMOUNT_GREATER);
                // }
                // List<genesis__Monthly_Income_Expense_Info__c> ccRecords = getCCRecord();
                // List<Other_loan_detail__c> otherloanDetails = [SELECT Id, 
                //                                                         Eligible_for_Debt_Consolidation__c, 
                //                                                         Loan_Type__c, 
                //                                                         Loan_Balance__c,
                //                                                         Loan_Limit__c 
                //                                                 FROM Other_loan_detail__c 
                //                                                 WHERE Application__c =: appId
                //                                                 AND party__c =: partyBorrower.id];
                // Integer countDbtConLoans = 0;
                // for(genesis__Monthly_Income_Expense_Info__c obj : ccRecords){
                //     if(obj.To_be_paid_out__c == true){
                //         countDbtConLoans ++;
                //     }
                // }
                // for(Other_loan_detail__c obj : otherloanDetails){
                //     if(obj.Eligible_for_Debt_Consolidation__c == true){
                //         countDbtConLoans ++;
                //     }
                // }
                // if(countDbtConLoans == 0 &&  jointApplication == false ){
                //     throw new CustomException(CpConstants.ADD_CC_OR_LOAN_FOR_DEBT_CON);
                // }
            //}else if(jointApplication == true && partyType == BPCreateQQActionConstants.CO_BORROWER){
                
                // List<genesis__Monthly_Income_Expense_Info__c> ccRecords = getALLCCRecord();
                // List<Other_loan_detail__c> otherloanDetails = [SELECT Id, 
                //                                                         Eligible_for_Debt_Consolidation__c, 
                //                                                         Loan_Type__c, 
                //                                                         Loan_Balance__c,
                //                                                         Loan_Limit__c 
                //                                                 FROM Other_loan_detail__c 
                //                                                 WHERE Application__c =: appId
                //                                                 ];
                                                        
                // Integer countDbtConLoans = 0;
                // for(genesis__Monthly_Income_Expense_Info__c obj : ccRecords){
                //     if(obj.To_be_paid_out__c == true){
                //         countDbtConLoans ++;
                //     }
                // }
                // for(Other_loan_detail__c obj : otherloanDetails){
                //     if(obj.Eligible_for_Debt_Consolidation__c == true){
                //         countDbtConLoans ++;
                //     }
                // }
                // if(countDbtConLoans == 0){
                //     throw new CustomException(CpConstants.ADD_CC_OR_LOAN_FOR_DEBT_CON);
                // }

                // totalLoanAmount = 0;
                // totalLoanAmount = getTotalDebConsolidationCCAmount(ccRecords) + getTotalDebConsolidationOLAmount(otherloanDetails);

                // if(reqLoanAmount < totalLoanAmount){
                //     throw new CustomException(CpConstants.TOTAL_DEBT_AMOUNT_GREATER);
                // }             
            //}
        //}
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    **/
    public void updateBorrowerParty(){
        if(this.partyBorrower != null){
            this.partyBorrower.Do_you_have_any_credit_card__c = creditCard == true ? BPCreateQQActionConstants.YES : BPCreateQQActionConstants.NO;
            this.partyBorrower.Do_you_have_any_other_loans__c = otherLoan == true ? BPCreateQQActionConstants.YES : BPCreateQQActionConstants.NO;
            List<clcommon__party__c> borrowerPartyList = new List<clcommon__party__c>{this.partyBorrower};
            DMLUtil.updateSObjectList(borrowerPartyList, true);
            //update this.partyBorrower;
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param condition 
    * @param count 
    * @return Integer 
    **/
    public Integer updateCount(Boolean condition, Integer count){
        if(condition){
            return count+1;
        }
        return count;
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    **/
    public void upsertCC(){
        List<genesis__Monthly_Income_Expense_Info__c > creditCardInfo = new List<genesis__Monthly_Income_Expense_Info__c>();
        List<genesis__Monthly_Income_Expense_Info__c > newCreditCardInfo = new List<genesis__Monthly_Income_Expense_Info__c>();
        List<genesis__Monthly_Income_Expense_Info__c > oldCreditCardInfo = new List<genesis__Monthly_Income_Expense_Info__c>();
        if(String.isNotBlank(this.ccOtherJson)){
            try{
                creditCardInfo = (List<genesis__Monthly_Income_Expense_Info__c >) System.JSON.deserialize((this.ccOtherJson), List<genesis__Monthly_Income_Expense_Info__c>.class);
                totalLoanAmount += getTotalDebConsolidationCCAmount(creditCardInfo);
                
            }catch(Exception ex){
                throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.CRED_DET_JSON);
            }
        }
        ValidationUtil.validateObjectListNotNull(creditCardInfo,BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.CRED_DET_JSON);
        //if(creditCardInfo.size() > 0){
        RecordType rt = [SELECT Id 
                        FROM RecordType 
                        WHERE sobjecttype =: CpConstants.GENESIS_MONTHLY_INCOME_EXPENSE_INFO 
                        AND name in (:CpConstants.CREDIT_CARD)
                        WITH SYSTEM_MODE];
        List<genesis__Applications__c> appList = [SELECT id,
                                                        App_Submission_Count__c,
                                                        Product_Name__c,
                                                        is_cc_info_updated__c
                                                    FROM genesis__Applications__c
                                                    WHERE id = :appId
                                                    WITH SYSTEM_MODE];
        for(genesis__Monthly_Income_Expense_Info__c monthlyIncomeExpenseObj : creditCardInfo){
            if(String.isBlank(monthlyIncomeExpenseObj.Id)){
                monthlyIncomeExpenseObj.Id = null;
                monthlyIncomeExpenseObj.Application__c = this.appId;
                monthlyIncomeExpenseObj.Party__c = this.partyBorrower.Id;
                monthlyIncomeExpenseObj.RecordTypeId = rt.Id;
                monthlyIncomeExpenseObj.Total_Balance__c = monthlyIncomeExpenseObj.Credit_card_balance__c != null? monthlyIncomeExpenseObj.Credit_card_balance__c:0;
                newCreditCardInfo.add(monthlyIncomeExpenseObj);
            }else{
                monthlyIncomeExpenseObj.Application__c = this.appId;
                monthlyIncomeExpenseObj.Party__c = this.partyBorrower.Id;
                monthlyIncomeExpenseObj.RecordTypeId = rt.Id;
                oldCreditCardInfo.add(monthlyIncomeExpenseObj);
            }
        }
        if(oldCreditCardInfo.size() == 0){
                deleteCreditCard();
        }else{
            ValidationUtil.throwErrorOnCondition(!checkCreditCardDetails(oldCreditCardInfo,rt.Id),BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.CRED_DET_JSON);
            //if(checkCreditCardDetails(oldCreditCardInfo,rt.Id)){
            if(ValidationUtil.getAndResults(new List<Boolean>{!appList.isEmpty(),appList[0].App_Submission_Count__c >= 1,appList[0].Product_Name__c == BPCreateQQActionConstants.AUTO})){
                appList[0].is_cc_info_updated__c = true;
                DMLUtil.updateSObjectList(appList, true);
            }
            DMLUtil.updateSObjectList(oldCreditCardInfo, true);
            // if(appList.size() > 0){
            //     if(appList[0].App_Submission_Count__c >= 1 && appList[0].Product_Name__c == BPCreateQQActionConstants.AUTO ){
            //         appList[0].is_cc_info_updated__c = true;
            //         update appList;
            //     }    
            // }              
            //update oldCreditCardInfo;
            // }else{
            //     throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.CRED_DET_JSON);
            // }
        }
        //if(newCreditCardInfo.size() > 0){
        DMLUtil.insertSObjectList(newCreditCardInfo, true);
        //insert newCreditCardInfo;
        //}
        // }else{
        //     throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.CRED_DET_JSON);
        // }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    **/
    public void deleteCreditCard(){
        RecordType rt = [SELECT Id 
                            FROM RecordType 
                            WHERE sobjecttype =: CpConstants.GENESIS_MONTHLY_INCOME_EXPENSE_INFO 
                            AND Name in (:CpConstants.CREDIT_CARD)
                            WITH SYSTEM_MODE];
        if(String.isNotBlank(rt.Id)){
            List<genesis__Monthly_Income_Expense_Info__c > consolidatedList = [SELECT Id
                                                                                FROM genesis__Monthly_Income_Expense_Info__c
                                                                                WHERE Application__c =: appId
                                                                                AND Party__c =: partyBorrower.Id
                                                                                AND RecordTypeId =: rt.Id
                                                                                WITH SYSTEM_MODE];
            if(!consolidatedList.isEmpty()){
                DMLUtil.deleteSObjectList(consolidatedList, true);
                //delete consolidatedList;
            }
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param expenseInfoList 
    * @param rtId 
    * @return Boolean 
    **/
    public Boolean checkCreditCardDetails(List<genesis__Monthly_Income_Expense_Info__c > expenseInfoList, String rtId){
        List<genesis__Monthly_Income_Expense_Info__c > otherLoanDeleteList = new List<genesis__Monthly_Income_Expense_Info__c>();
        List<genesis__Monthly_Income_Expense_Info__c > otherLoanNotToDeleteList = new List<genesis__Monthly_Income_Expense_Info__c >();
        Boolean result = false;
        if(String.isBlank(rtId)){
            return result;
        }
        List<genesis__Monthly_Income_Expense_Info__c > consolidatedList = [SELECT Id
                                                                            FROM genesis__Monthly_Income_Expense_Info__c
                                                                            WHERE Application__c =: appId
                                                                            AND Party__c =: partyBorrower.Id
                                                                            AND RecordTypeId =: rtId
                                                                            WITH SYSTEM_MODE];
        if(!consolidatedList.isEmpty()){
            for(genesis__Monthly_Income_Expense_Info__c expenseInfoObj : expenseInfoList){
                Boolean isIdMatch = false;
                for(genesis__Monthly_Income_Expense_Info__c consolidateExpenseObj : consolidatedList){
                    if(compareIds(expenseInfoObj.id,consolidateExpenseObj.Id)){
                        isIdMatch = true;
                        otherLoanNotToDeleteList.add(consolidateExpenseObj);
                    }
                }
                // if(!isIdMatch){
                //     throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.CRED_DET_JSON+expenseInfoObj.Id);
                // }
                ValidationUtil.throwErrorOnCondition(!isIdMatch,BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.CRED_DET_JSON+expenseInfoObj.Id);
                //otherLoanNotToDeleteList = getOtherLoanNotToDeleteList(consolidatedList,consolidateExpenseObjDetails);
                result = true;
            }
        }
        for(genesis__Monthly_Income_Expense_Info__c consolidateExpenseObj : consolidatedList){
            if(!otherLoanNotToDeleteList.contains(consolidateExpenseObj)){
                otherLoanDeleteList.add(consolidateExpenseObj);
            }
        }
        //if(!otherLoanDeleteList.isEmpty()){
        DMLUtil.deleteSObjectList(otherLoanDeleteList, true);
            //delete otherLoanDeleteList;
        //}
        return result;
    }

    /**
    * @description | Upsert finnacier as party
    * @author Supriyo Seni | 12-18-2023 
    * @param accountNumber 
    * @param financier 
    **/
    public void upsertFinancierAsParty(String accountNumber,String financier){
        clcommon__Party__c partyObj = new clcommon__Party__c(); 
        deletePayee();
        List<clcommon__Party_Type__c> payeePartyTypeList = [SELECT Id, 
                                                                Name 
                                                        FROM clcommon__Party_Type__c 
                                                        WHERE Name =: BPCreateQQActionConstants.PAYEE 
                                                        WITH SYSTEM_MODE
                                                        LIMIT 1];
        List <genesis__applications__c> applicationList = [SELECT id,
                                                                    genesis__Contact__r.id, 
                                                                    genesis__Account__c
                                                            FROM genesis__applications__c 
                                                            WHERE id =: appId
                                                            WITH SYSTEM_MODE];
        List<clcommon__Party__c> partyTypeList = [SELECT id
                                                    FROM clcommon__Party__c
                                                    WHERE genesis__Application__c = :appId
                                                    AND clcommon__Account__r.Name =: BPCreateQQActionConstants.ROBERT_BELAN
                                                    AND clcommon__Type__r.Name =: BPCreateQQActionConstants.PAYEE
                                                    WITH SYSTEM_MODE];

        if(payeePartyTypeList.size() > 0 && partyTypeList.size() < 1){
            ValidationUtil.validateObjectListNotNull(applicationList,BPCreateQQActionConstants.APPLICATION_NOT_FOUND);
            partyObj.clcommon__Type__c = payeePartyTypeList[0].id;
            partyObj.clcommon__Account__c = financier ;
            partyObj.genesis__Application__c = appId;
            partyObj.clcommon__Contact__c = applicationList[0].genesis__Contact__r.id;
            partyObj.financier_Account_Number__c = accountNumber;
            List<clcommon__Party__c> newPartyList = new List<clcommon__Party__c>{partyObj};
            DMLUtil.insertSObjectList(newPartyList, true);
            //insert partyObj;
        }  
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    **/
    public void deleteTradeIn(){
        List<Trade_In__c> tradeInInfoList = [SELECT id
                                            FROM Trade_In__c
                                            WHERE Application__c = :appId
                                            WITH SYSTEM_MODE];

        if(!tradeInInfoList.isEmpty()){
            DMLUtil.deleteSObjectList(tradeInInfoList, true);
            //delete tradeInInfoList;
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    **/
    public void deletePayee(){
        List<clcommon__Party__c> payeeInfoList = [SELECT id
                                                FROM clcommon__Party__c
                                                WHERE genesis__Application__c = :appId
                                                AND clcommon__Type__r.Name =: BPCreateQQActionConstants.PAYEE
                                                WITH SYSTEM_MODE];

        if(!payeeInfoList.isEmpty()){
            DMLUtil.deleteSObjectList(tradeInInfoList, true);
            //delete payeeInfoList;
        }
    }

    /**
    * @description | This method can be used to insert or update other loan details
    * @author Supriyo Seni | 12-18-2023 
    **/
    public void upsertOtherLoan(){
        List<Other_Loan_Detail__c > otherLoanInfo = new List<Other_Loan_Detail__c>();
        List <genesis__applications__c> applicationList = [SELECT id,
                                                                    genesis__Contact__r.id, 
                                                                    genesis__Account__c,
                                                                    Loan_Purpose__c
                                                            FROM genesis__applications__c 
                                                            WHERE id =: appId 
                                                            WITH SYSTEM_MODE];
        if(String.isNotBlank(this.otherLoanJson)){
            Integer count = 0;
            Integer flag = -1;
            Integer flagID;
            Boolean flagCheck = false;
            // String FinancierId = '';
            otherLoanInfo = (List<Other_Loan_Detail__c>) System.JSON.deserialize((this.otherLoanJson), List<Other_Loan_Detail__c>.class);
            List<Id> autoInsutitutionIdList = new List<Id>();
            //Map<Id,Account> autoInsIdVsAcountMap = new Map<Id,Account>();
            for(Other_Loan_Detail__c otherLoanObj : otherLoanInfo){
                autoInsutitutionIdList.add(otherLoanObj.Auto_Financial_Institution__c);
            }
            Map<Id, Account> autoInsIdVsAcountMap = new Map<Id, Account>([SELECT id,
                                                                                Name
                                                                        FROM Account 
                                                                        WHERE id IN : autoInsutitutionIdList
                                                                        WITH SYSTEM_MODE
                                                                        LIMIT 1]);
            // for(Account accountObj : accListDet){
            //     autoInsIdVsAcountMap.put()
            // }
            
            for(Other_Loan_Detail__c othLoan : otherLoanInfo){
                flag++;
                // List <Account> accListDet = [SELECT id,
                //                                     Name
                //                             FROM Account 
                //                             WHERE id =: othLoan.Auto_Financial_Institution__c 
                //                             WITH SYSTEM_MODE
                //                             LIMIT 1];
                Account otherLoanAccountObj = autoInsIdVsAcountMap.get(othLoan.Auto_Financial_Institution__c );
                Boolean isLoanToBeRefinaced = ValidationUtil.getAndResults(new List<Boolean>{othLoan.Asset_being_refinanced__c,
                        (otherLoanAccountObj.Name == BPCreateQQActionConstants.LATITUDE_FINANCIAL),(applicationList[0].Loan_Purpose__c == BPCreateQQActionConstants.ASSESTREF)});
                ValidationUtil.throwErrorOnCondition(isLoanToBeRefinaced,BPCreateQQActionConstants.CANNOTBRREF);
                // if((othLoan.Asset_being_refinanced__c == true) && (accListDet[0].Name == BPCreateQQActionConstants.LATITUDE_FINANCIAL) && (applicationList[0].Loan_Purpose__c == BPCreateQQActionConstants.ASSESTREF) ){
                //     throw new CustomException(BPCreateQQActionConstants.CANNOTBRREF);
                // }
                if(ValidationUtil.getOrResults(new List<Boolean>{othLoan.Asset_being_traded_in__c,othLoan.Asset_being_refinanced__c})){
                    count++;
                }
                Boolean isAutoLoan = ValidationUtil.getAndResults(new List<Boolean>{othLoan.Asset_being_refinanced__c,othLoan.Loan_Type__c == BPCreateQQActionConstants.AUTO_LOAN,applicationList[0].Loan_Purpose__c == BPCreateQQActionConstants.ASSESTREF});
                Boolean isDealership = ValidationUtil.getAndResults(new List<Boolean>{othLoan.Asset_being_traded_in__c,(othLoan.Loan_Type__c == BPCreateQQActionConstants.AUTO_LOAN),(otherLoanAccountObj.Name == BPCreateQQActionConstants.LATITUDE_FINANCIAL),(applicationList[0].Loan_Purpose__c == BPCreateQQActionConstants.DEALERSHIP_PURCHASE)});
                if(ValidationUtil.getOrResults(new List<Boolean>{isAutoLoan,isDealership})){
                    flagID = flag;
                    flagCheck = true;  
                }
                // if(((othLoan.Asset_being_refinanced__c == true) && (othLoan.Loan_Type__c == BPCreateQQActionConstants.AUTO_LOAN) && (applicationList[0].Loan_Purpose__c == BPCreateQQActionConstants.ASSESTREF)) || ((othLoan.Asset_being_traded_in__c == true) && (othLoan.Loan_Type__c == BPCreateQQActionConstants.AUTO_LOAN) && (accListDet[0].Name == BPCreateQQActionConstants.LATITUDE_FINANCIAL) && (applicationList[0].Loan_Purpose__c == BPCreateQQActionConstants.DEALERSHIP_PURCHASE) )){
                //     flagID=flag;
                //     flagCheck=true;    
                // }
            }
            ValidationUtil.throwErrorOnCondition(count>1,BPCreateQQActionConstants.MULTIPLE_TRADEIN_NOT_ALLOWED);
            // if(count>1){
            //     throw new CustomException(BPCreateQQActionConstants.MULTIPLE_TRADEIN_NOT_ALLOWED);
            // }
            if(count<1){
                deleteTradeIn();
                deletePayee();
            }
            // if(flagCheck){
            //     upsertFinancierAsParty(otherLoanInfo[flagID].Account_number__c,otherLoanInfo[flagID].Auto_Financial_Institution__c);
            // }
            upsertFinancierAsPartyCall(flagCheck);
            totalLoanAmount += getTotalDebConsolidationOLAmount(otherLoanInfo);
        }
        handleUpdateOrDeletionOfOtherLoan(otherLoanInfo);
        //if(otherLoanInfo.size() > 0){
            // List<Other_Loan_Detail__c > newOtherLoanInfo = new List<Other_Loan_Detail__c>();
            // List<Other_Loan_Detail__c > oldOtherLoanInfo = new List<Other_Loan_Detail__c>();
            // for(Other_Loan_Detail__c ol : otherLoanInfo){
            //     if(String.isBlank(ol.Id)){
            //         ol.Id = null;
            //         ol.Application__c = this.appId;
            //         ol.Party__c = this.partyBorrower.Id;
            //         ol.Total_Balance__c = ol.Loan_Balance__c != null? ol.Loan_Balance__c:0;
            //         newOtherLoanInfo.add(ol);
            //     }else{
            //         ol.Party__c = this.partyBorrower.Id;
            //         ol.Total_Balance__c = ol.Loan_Balance__c != null? ol.Loan_Balance__c:0;
            //         oldOtherLoanInfo.add(ol);
            //     }
            // }
            // if(oldOtherLoanInfo.size() == 0){
            //     deleteOtherLoan();
            // }else{
            //     if(checkOtherLoanDetails(oldOtherLoanInfo)){
            //         List<genesis__Applications__c> appProdList = new List<genesis__Applications__c>();
            //         appProdList = [SELECT id,
            //                     App_Submission_Count__c,
            //                     Product_Name__c
            //                     FROM genesis__Applications__c
            //                     WHERE id = :appId];            
            //         update oldOtherLoanInfo;
            //     }else{
            //         throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.OTHER_LOAN_DET_JSON);
            //     }
            // }
            // if(newOtherLoanInfo.size() > 0){
            //     insert newOtherLoanInfo;
            // }
        //}else{
        //    throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.OTHER_LOAN_DET_JSON);
        //}
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param doCall 
    **/
    public void upsertFinancierAsPartyCall(Boolean doCall){
        if(doCall){
            upsertFinancierAsParty(otherLoanInfo[flagID].Account_number__c,otherLoanInfo[flagID].Auto_Financial_Institution__c);
        }
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-18-2023 
    * @param otherLoanList 
    **/
    public void handleUpdateOrDeletionOfOtherLoan(List<Other_Loan_Detail__c> otherLoanList){
        ValidationUtil.throwErrorOnCondition(otherLoanList.isEmpty(),BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.OTHER_LOAN_DET_JSON);
        List<Other_Loan_Detail__c > newOtherLoanInfo = new List<Other_Loan_Detail__c>();
        List<Other_Loan_Detail__c > oldOtherLoanInfo = new List<Other_Loan_Detail__c>();
        for(Other_Loan_Detail__c ol : otherLoanInfo){
            if(String.isBlank(ol.Id)){
                ol.Id = null;
                ol.Application__c = this.appId;
                ol.Party__c = this.partyBorrower.Id;
                ol.Total_Balance__c = ol.Loan_Balance__c != null? ol.Loan_Balance__c:0;
                newOtherLoanInfo.add(ol);
            }else{
                ol.Party__c = this.partyBorrower.Id;
                ol.Total_Balance__c = ol.Loan_Balance__c != null? ol.Loan_Balance__c:0;
                oldOtherLoanInfo.add(ol);
            }
        }
        if(oldOtherLoanInfo.isEmpty()){
            deleteOtherLoan();
        }else{
            ValidationUtil.throwErrorOnCondition(!checkOtherLoanDetails(oldOtherLoanInfo),BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.OTHER_LOAN_DET_JSON);
            // List<genesis__Applications__c> appProdList = [SELECT id,
            //                                                     App_Submission_Count__c,
            //                                                     Product_Name__c
            //                                                 FROM genesis__Applications__c
            //                                                 WHERE id = :appId
            //                                                 WITH SYSTEM_MODE];            
           // update oldOtherLoanInfo;
            DMLUtil.updateSObjectList(oldOtherLoanInfo, true);
        }
        if(!newOtherLoanInfo.isEmpty()){
            //insert newOtherLoanInfo;
            DMLUtil.insertSObjectList(newOtherLoanInfo, true);
        }
    } 
    /**
    * @description | Delete other loan
    * @author Supriyo Seni | 12-15-2023 
    **/
    public void deleteOtherLoan(){
        List<Other_Loan_Detail__c > consolidatedList = [SELECT Id
                                                            FROM Other_Loan_Detail__c
                                                            WHERE Application__c =: appId
                                                            AND Party__c =: partyBorrower.Id
                                                            WITH SYSTEM_MODE];
        // if(consolidatedList.size() > 0){
        //     delete consolidatedList;
        // }
        if(!consolidatedList.isEmpty()){
            DMLUtil.deleteSObjectList(consolidatedList, true);
            //delete otherLoanDeleteList;
        }
    }

    /**
    * @description | Other Loan Details Check
    * @author Supriyo Seni | 12-15-2023 
    * @param otherLoanInfo 
    * @return Boolean 
    **/
    public Boolean checkOtherLoanDetails(List<Other_Loan_Detail__c > otherLoanInfo){
        Boolean result = false;
        List<Other_Loan_Detail__c > otherLoanDeleteList = new List<Other_Loan_Detail__c>();
        List<Other_Loan_Detail__c > otherLoanNotToDeleteList = new List<Other_Loan_Detail__c>();
        List<Other_Loan_Detail__c > consolidatedList = [SELECT Id
                                                            FROM Other_Loan_Detail__c
                                                            WHERE Application__c =: appId
                                                            AND Party__c =: partyBorrower.Id
                                                            WITH SYSTEM_MODE];
        if(!consolidatedList.isEmpty()){
            for(Other_Loan_Detail__c otherLoanObj : otherLoanInfo){
                Boolean idMatch = false;
                for(Other_Loan_Detail__c otherLoanConsolObj : consolidatedList){
                    if(compareIds(otherLoanObj.id,otherLoanConsolObj.Id)){
                        idMatch = true;
                        otherLoanNotToDeleteList.add(otherLoanConsolObj);
                    }
                }
                ValidationUtil.throwErrorOnCondition(!idMatch,BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.OTHER_LOAN_DET_JSON+otherLoanObj.Id);
                // if(!idMatch){
                //     throw new CustomException(BPCreateQQActionConstants.INVALID_JSON+BPCreateQQActionConstants.OTHER_LOAN_DET_JSON+otherLoanObj.Id);
                // }
                result = true;
            }
        }
        for(Other_Loan_Detail__c otherLoanConsolObj : consolidatedList){
            if(!otherLoanNotToDeleteList.contains(otherLoanConsolObj)){
                otherLoanDeleteList.add(otherLoanConsolObj);
            }
        }
        if(!otherLoanDeleteList.isEmpty()){
            DMLUtil.deleteSObjectList(otherLoanDeleteList, true);
            //delete otherLoanDeleteList;
        }
        return result;
    }

    /**
    * @description | Update Account
    * @author Supriyo Seni | 12-15-2023 
    * @param resStatus 
    **/
    public void updateAccount(String resStatus){
        if(String.isBlank(this.partyBorrower.clcommon__Account__c)){
            return;
        }
        Account accountObj = new Account();
        accountObj.Id = this.partyBorrower.clcommon__Account__c;
        accountObj.Residential_Status__c = resStatus;
        accountList.add(accountObj);
        List<Account> accountList = new  List<Account>{accountObj}; 
        DMLUtil.insertSObjectList(accountList, true);
        //update accountObj;
    }
    /**
    * @description | Get total Deb consolidation cc amount
    * @author Supriyo Seni | 12-15-2023 
    * @param ccRecords 
    * @return Decimal 
    **/
    public Decimal getTotalDebConsolidationCCAmount(List<genesis__Monthly_Income_Expense_Info__c> ccRecords){
        Decimal totalAmount = 0.00;
        if(ccRecords != null && ccRecords.size() > 0){
            return 0.00;
        }
        for(genesis__Monthly_Income_Expense_Info__c rec : ccRecords){
            if(ValidationUtil.getAndResults(new List<Boolean>{rec.To_be_paid_out__c,ec.Credit_card_balance__c != null,rec.Credit_card_balance__c > 0})){
                totalAmount = totalAmount + rec.Credit_card_balance__c;
            }
        }
        return totalAmount;
    }

    /**
    * @description 
    * @author Supriyo Seni | 12-15-2023 
    * @param otherLoanRecords 
    * @return Decimal 
    **/
    public Decimal getTotalDebConsolidationOLAmount(List<Other_Loan_Detail__c> otherLoanRecords){
        Decimal totalAmount = 0.00;
        if(otherLoanRecords.isEmpty()){
            return 0;
        }
        for(Other_Loan_Detail__c rec : otherLoanRecords){
            if(ValidationUtil.getAndResults(new List<Boolean> {rec.Eligible_for_Debt_Consolidation__c,String.isNotBlank(rec.Loan_Type__c),
                    rec.Loan_Balance__c != null,rec.Loan_Balance__c > 0,ValidationUtil.getOrResults(new List<Boolean> {rec.Loan_Type__c.equalsIgnoreCase(CpConstants.PERSONAL_LOAN),
                        rec.Loan_Type__c.equalsIgnoreCase(CpConstants.AUTO_LOAN),rec.Loan_Type__c.equalsIgnoreCase(CpConstants.SMALL_CREDIT_LOAN)})})){
                totalAmount = totalAmount + rec.Loan_Balance__c;
            }else if(ValidationUtil.getAndResults(new List<Boolean>{rec.Eligible_for_Debt_Consolidation__c,String.isNotBlank(rec.Loan_Type__c),
                    rec.Loan_Limit__c != null,rec.Loan_Limit__c > 0,ValidationUtil.getOrResults(new List<Boolean>{rec.Loan_Type__c.equalsIgnoreCase(CpConstants.BUY_NOW_PAY_LATER),
                    rec.Loan_Type__c.equalsIgnoreCase(CpConstants.OVERDRAFT)})})){
                totalAmount = totalAmount + rec.Loan_Limit__c;
            }else if(ValidationUtil.getAndResults(new List<Boolean>{rec.Eligible_for_Debt_Consolidation__c,String.isNotBlank(rec.Loan_Type__c),
                    rec.Loan_Type__c.equalsIgnoreCase(CpConstants.LINE_OF_CREDIT_REVOLVING_LOAN),rec.Loan_Limit__c != null,rec.Loan_Limit__c > 0})){
                totalAmount = totalAmount;
            }
        }
        return totalAmount;
                // if(rec.Eligible_for_Debt_Consolidation__c == true && String.isNotBlank(rec.Loan_Type__c)
                //         && (rec.Loan_Type__c.equalsIgnoreCase(CpConstants.PERSONAL_LOAN) || rec.Loan_Type__c.equalsIgnoreCase(CpConstants.AUTO_LOAN) || rec.Loan_Type__c.equalsIgnoreCase(CpConstants.SMALL_CREDIT_LOAN))
                //         && rec.Loan_Balance__c != null && rec.Loan_Balance__c > 0){
                //             totalAmount = totalAmount + rec.Loan_Balance__c;
                // }
                // else if(rec.Eligible_for_Debt_Consolidation__c == true && String.isNotBlank(rec.Loan_Type__c)
                //         && (rec.Loan_Type__c.equalsIgnoreCase(CpConstants.BUY_NOW_PAY_LATER) || rec.Loan_Type__c.equalsIgnoreCase(CpConstants.OVERDRAFT))
                //         && rec.Loan_Limit__c != null && rec.Loan_Limit__c > 0){
                //             totalAmount = totalAmount + rec.Loan_Limit__c;
                // }
                // else if(rec.Eligible_for_Debt_Consolidation__c == true && String.isNotBlank(rec.Loan_Type__c)
                //         && rec.Loan_Type__c.equalsIgnoreCase(CpConstants.LINE_OF_CREDIT_REVOLVING_LOAN)
                //         && rec.Loan_Limit__c != null && rec.Loan_Limit__c > 0){
                //             totalAmount = totalAmount;
                // }
                
        //     }
        // }
        
    }

    /**
    * @description | Get CCR Record
    * @author Supriyo Seni | 12-15-2023 
    * @return List<genesis__Monthly_Income_Expense_Info__c> 
    **/
    public List<genesis__Monthly_Income_Expense_Info__c> getCCRecord(){
        List<RecordType> recordTypeList = [SELECT Id From RecordType 
                                            WHERE sobjecttype =: CpConstants.GENESIS_MONTHLY_INCOME_EXPENSE_INFO 
                                            AND name IN (:CpConstants.CREDIT_CARD)
                                            WITH SYSTEM_MODE];
        List<genesis__Monthly_Income_Expense_Info__c> consolidatedInsertList = [SELECT Id,
                                                                                    To_be_paid_out__c,
                                                                                    Credit_card_balance__c
                                                                                FROM genesis__Monthly_Income_Expense_Info__c
                                                                                WHERE Application__c =: appId
                                                                                AND party__c =: partyBorrower.id
                                                                                AND RecordTypeId =: recordTypeList[0].Id
                                                                                WITH SYSTEM_MODE];
        return consolidatedInsertList;
    }

    /**
    * @description | Get All CCR Record
    * @author Supriyo Seni | 12-15-2023 
    * @return List<genesis__Monthly_Income_Expense_Info__c> 
    **/
    public List<genesis__Monthly_Income_Expense_Info__c> getALLCCRecord(){
        List<RecordType> recordTypeList = [SELECT Id From RecordType 
                                            WHERE sobjecttype =: CpConstants.GENESIS_MONTHLY_INCOME_EXPENSE_INFO 
                                            AND name IN (:CpConstants.CREDIT_CARD)
                                            WITH SYSTEM_MODE];
        List<genesis__Monthly_Income_Expense_Info__c> consolidatedInsertList = [SELECT Id,
                                                                                    To_be_paid_out__c,
                                                                                    Credit_card_balance__c
                                                                                FROM genesis__Monthly_Income_Expense_Info__c
                                                                                WHERE Application__c =: appId
                                                                                AND RecordTypeId =: recordTypeList[0].Id
                                                                                WITH SYSTEM_MODE];
        return consolidatedInsertList;
    }
}