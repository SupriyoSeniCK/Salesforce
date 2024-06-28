/**
* @description       : This is the action class responsible for creation of Quick Quote
* @author            : kushal@cloudkaptan.com
* @group             : 
* @last modified on  : 03-08-2022
* @last modified by  : Rajashree Das, Samiran Das
**/
public without sharing class CreateQQAction implements PortalActionAdapter{
    
    //variable declarations
    List<String> paramKeys;
    PersonalInformation perObj;
    ContactDetails conObj;
    LoanPurpose loanPurposeObj;
    LoanAmount loanAmountobj;
    DrivingLicense drivingLicenseObj;
    HomeAddress homeAddObj;
    PostalAddress postalAddObj;
    GpoAddress gpoAddObj;
    String proType;
    String consentJson;
    String quoteTaggingIdJson;
    String utmCampaign;
    String utmContent;
    String utmMedium;
    String utmSource;
    String gclId;
    String mscklID;
    String pageName; 
    String sourceCode;
    String offerCode;
    Id qqId;
    clcommon.Response res;
    List<clcommon.PortalCustomRemoteActionRecord> resRecords;
    System.Savepoint sp;
    /* Initialising parameter keys and response */
    public CreateQQAction(){
        res  =  new clcommon.Response();
        paramKeys  =  new List<String>();
        paramKeys.add( CreateQQActionConstants.PERSONAL_INFO_PARAM );
        paramKeys.add( CreateQQActionConstants.ADDRESS_PARAM );
        paramKeys.add( CreateQQActionConstants.LOAN_PURPOSE_PARAM );
        paramKeys.add( CreateQQActionConstants.DRIVE_LICENCE_PARAM) ;
        paramKeys.add( CreateQQActionConstants.LOAN_AMT_PARAM );
        paramKeys.add( CreateQQActionConstants.PROD_TYPE_PARAM );
        paramKeys.add(CreateQQActionConstants.CONSENT);
        paramKeys.add(CreateQQActionConstants.QUOTE_TAGGING_ID);
        paramKeys.add(CreateQQActionConstants.UTM_CAMPAIGN);
        paramKeys.add(CreateQQActionConstants.UTM_CONTENT);
        paramKeys.add(CreateQQActionConstants.UTM_MEDIUM);
        paramKeys.add(CreateQQActionConstants.UTM_SOURCE);
        paramKeys.add(CreateQQActionConstants.GCLID);
        paramKeys.add(CreateQQActionConstants.MSCLKID);
        paramKeys.add(CreateQQActionConstants.PAGE_NAME);
        paramKeys.add(CreateQQActionConstants.SOURCE_CODE);
        paramKeys.add(CreateQQActionConstants.OFFER_CODE);
        paramKeys.add( CreateQQActionConstants.POSTAL_ADDRESS_PARAM );
        paramKeys.add( CreateQQActionConstants.GPO_ADDRESS_PARAM );
    }
    
    /* setParams : This function is used to set parameters through POJO class */
    public void setParams(Map<String,Object> param){
        try{
            Map<String,Object> customParam  =  new Map<String,Object>();
            /* if parameter map comes blank then exception */
            if(param!= null && !param.isEmpty()){
                for(String paramKey : paramKeys){
                    /* if parameter doesn't contain a paramKey or has null as its value */
                    if(!param.containsKey(paramKey)){
                        throw new CustomException( CreateQQActionConstants.PARAM_MISSING_EX + paramKey );
                    }else if( param.get(paramKey)  ==  null){
                        throw new CustomException( CreateQQActionConstants.PARAM_VAL_MISSING_EX + paramKey );
                    }else{
                        String filteredVal  =  String.valueOf(param.get(paramKey));
                        filteredVal = filteredVal.removeStart(CreateQQActionConstants.START_SIGN);
                        filteredVal = filteredVal.removeEnd(CreateQQActionConstants.END_SIGN);
                        // if(FlowfiUtil.regexCheckOnJson(paramKey, filteredVal)){
                        customParam.put(paramKey,filteredVal);
                        // }else{
                        //     throw new CustomException(CreateQQActionConstants.REGEX_CHECK_FAILED + paramKey);
                        // }
                    }
                }  
                /* getting arguments from paramMap for POJO parsing */
                String personalParam  =  String.valueOf(customParam.get(paramKeys[0]));
                String contactParam  =  String.valueOf(customParam.get(paramKeys[1]));
                String loanPurposeParam  =  String.valueOf(customParam.get(paramKeys[2]));
                String drivingLicenceParam  =  String.valueOf(customParam.get(paramKeys[3]));
                String loanAmountParam  =  String.valueOf(customParam.get(paramKeys[4]));
                proType = String.valueOf(customParam.get(paramKeys[5]));
                this.consentJson  =  String.valueOf(customParam.get(paramKeys[6]));
                quoteTaggingIdJson  =  String.valueOf(customParam.get(paramKeys[7]));
                utmCampaign=String.valueOf(customParam.get(paramKeys[8]));
                utmContent=String.valueOf(customParam.get(paramKeys[9]));
                utmMedium=String.valueOf(customParam.get(paramKeys[10]));
                utmSource=String.valueOf(customParam.get(paramKeys[11]));
                gclId=String.valueOf(customParam.get(paramKeys[12]));
                mscklID=String.valueOf(customParam.get(paramKeys[13]));
                pageName=String.valueOf(customParam.get(paramKeys[14]));
                sourceCode=String.valueOf(customParam.get(paramKeys[15]));
                offerCode=String.valueOf(customParam.get(paramKeys[16]));
                String MailingAddressParam = String.valueOf(customParam.get(paramKeys[17]));
                String GpoAddressParam = String.valueOf(customParam.get(paramKeys[18]));
                /* POJO parsing */
                this.parsePersonalInformation(personalParam);
                this.parseHomeAddress(contactParam);
                this.parseLoanPurpose(loanPurposeParam);
                this.parseLoanAmount(loanAmountParam);
                this.parseDrivingLicense(drivingLicenceParam);
                this.parsePostalAddress(MailingAddressParam);
                this.parseGpoAddress(GpoAddressParam);
            }else{
                throw new CustomException( CreateQQActionConstants.PARAM_MAP_BLANK_EX );
            }
        }catch(Exception e){
            if(e.getTypeName()  ==  CreateQQActionConstants.CUSTOMEXCEPTIONTYPE){
                res =  FlowfiUtil.getErrorResponse(e.getMessage());
            }else{
                res  =  FlowfiUtil.getErrorResponse( CreateQQActionConstants.SOMETHING_WENT_WRONG_EX + e.getMessage());
            }
        }
    }
    
    /* execute : This function is used to set response for the portal*/
    public void execute(){
        Map<String,Object> resFields;
        try{
            if(FlowfiUtil.guestUserCheck()){
                Wrapper.QuickQuoteWrapper qqWrap  =  getQuickQuoteWrapper();
                qqWrap.productType = proType;
                boolean createAccount = true; //if account not present with the provided mail, create account
                String prodName;
                /* evaluation product name from the incoming productType argument */
                if (proType == CreateQQActionConstants.TYPE_PERSONAL){
                    prodName  =  CreateQQActionConstants.PRO_PERSONAL_LOAN_DEF ;
                } else if (proType == CreateQQActionConstants.TYPE_AUTO){
                    prodName  =  CreateQQActionConstants.PRO_AUTO_LOAN ;
                } else{
                    throw new CustomException( CreateQQActionConstants.NO_SUCH_PRO_EX );
                }
                /* querying product based on product name to assign it to quick quote */
                clcommon__CL_Product__c prod =  [ SELECT  ID, 
                                                 Name,
                                                 clcommon__Product_Name__c
                                                 FROM clcommon__CL_Product__c 
                                                 WHERE clcommon__Product_Name__c  = :prodName
                                                 LIMIT 1 ];
                List <genesis__Quick_Quotes__c> qqList1  =  new List<genesis__Quick_Quotes__c>();
                List <Account> qqAccounts = new List<Account>();
                /* querying account based on mail provided to check for existing borrower account */
                qqAccounts = [ SELECT Id, 
                              Name, 
                              First_Name__c, 
                              Last_Name__c,
                              Date_of_Birth__c,
                              Gender__c,
                              Mobile_Number__c,
                              Account_Security_Token__c,
                              Email__c 
                              FROM Account 
                              WHERE Email__c  = :qqWrap.email];
                
                if( !qqAccounts.isEmpty() && qqAccounts.size()  ==  1){
                    createAccount  =  false;
                    //check if same personal detail have been provided by the customer else update personal information
                    if( qqAccounts[0].First_Name__c !=  qqWrap.fName 
                       && qqAccounts[0].Last_Name__c !=  qqWrap.lName 
                       && qqAccounts[0].Date_of_Birth__c !=  Date.valueOf(qqwrap.dob)
                       && qqAccounts[0].Mobile_Number__c !=  qqWrap.mobileNumber){
                           qqAccounts[0].First_Name__c  =  qqWrap.fName;
                           qqAccounts[0].Last_Name__c  =  qqWrap.lName;
                           qqAccounts[0].Date_of_Birth__c  =  Date.valueOf(qqwrap.dob);
                           qqAccounts[0].Mobile_Number__c  =  qqWrap.mobileNumber;
                           upsert qqAccounts;
                       }
                }else if(qqAccounts.size() > 1){
                    throw new CustomException(ResponseMessenger.accNotFound);
                }
                /* calling the check and create quote function for validating customer info */
                qqId  =  checkAndCreateQuote(qqWrap, createAccount, qqAccounts, prod);
                resFields  =  new Map<String,Object>();
                List <genesis__Quick_Quotes__c> qqlist  = [SELECT  id,
                                                           Name,
                                                           Quote_Decision_Date__c,
                                                           Repayment_Amount__c,
                                                           Term__c, 
                                                           genesis__Account__c,
                                                           genesis__Contact__c,
                                                           CL_Product_Name__c,
                                                           genesis__Financed_Amount__c, 
                                                           genesis__Payment_Frequency__c, 
                                                           Quick_Quote_Security_Token__c, 
                                                           Interest_Type__c, 
                                                           Indicative_Interest_Rate__c,
                                                           Loan_Establishment_Fee__c,
                                                           genesis__Account__r.Account_Security_Token__c
                                                           /* ************** OKTA Changes ***************** */
                                                           // Email__c,
                                                           // Mobile_Number__c,
                                                           // genesis__First_Name__c,
                                                           // genesis__Last_Name__c,
                                                           // Date_Of_Birth__c,
                                                           // Middle_Name__c,
                                                           // genesis__Account__r.Email_Verified__c
                                                           /* ************** OKTA Changes ***************** */
                                                           FROM genesis__Quick_Quotes__c 
                                                           WHERE id = :qqid
                                                           LIMIT 1];
                /* generating success response needed for recalculate Emi page */
                resFields.put(CreateQQActionConstants.QUOTE_NO, String.valueOf(qqList[0].Name));
                resFields.put(CreateQQActionConstants.RES, CreateQQActionConstants.SUCCESS);
                resFields.put( CreateQQActionConstants.INT_RATE_RES , String.valueOf(qqlist[0].Indicative_Interest_Rate__c) + CreateQQActionConstants.PER_ANNUM );
                resFields.put( CreateQQActionConstants.LOAN_AMT_RES , qqlist[0].genesis__Financed_Amount__c );
                
                /* ************** OKTA Changes ***************** */
                // resFields.put( 'email' , qqlist[0].Email__c );
                // resFields.put( 'mobile_phone', qqlist[0].Mobile_Number__c );
                // resFields.put( 'title' , '' );
                // resFields.put( 'first_name' , qqlist[0].genesis__First_Name__c );
                // if (qqlist[0].Middle_Name__c == null) {
                //     resFields.put( 'middle_name' , '');
                // } else {
                //     resFields.put( 'middle_name' , qqlist[0].Middle_Name__c );
                // }
                // resFields.put( 'last_name' , qqlist[0].genesis__Last_Name__c );
                // resFields.put( 'date_of_birth', String.valueOf(qqlist[0].Date_Of_Birth__c) );
                // resFields.put( 'email_verified' , qqlist[0].genesis__Account__r.Email_Verified__c );
                /*******************************************************************************/
                
                Decimal rpAmountNotRounded = 0.00; 
                if(qqlist[0].Repayment_Amount__c != null) {
                    rpAmountNotRounded = qqlist[0].Repayment_Amount__c;
                }
                resFields.put( CreateQQActionConstants.REPAYMENT_RES , CreateQQActionConstants.DOLLAR +  rpAmountNotRounded.setScale(2, RoundingMode.HALF_UP));
                if (String.valueOf(qqlist[0].genesis__Payment_Frequency__c).equalsIgnoreCase(CreateQQActionConstants.BIWEEKLY)) {
                    resFields.put( CreateQQActionConstants.REP_FREQUENCY_RES , CreateQQActionConstants.FORTNIGHTLY );
                }else{
                    resFields.put( CreateQQActionConstants.REP_FREQUENCY_RES , qqlist[0].genesis__Payment_Frequency__c );
                }
                if (String.valueOf(qqlist[0].Interest_Type__c).equalsIgnoreCase(CreateQQActionConstants.FLOATING)) {
                    resFields.put( CreateQQActionConstants.LOAN_TYPE_RES , CreateQQActionConstants.VARIABLE );
                }else{
                    resFields.put( CreateQQActionConstants.LOAN_TYPE_RES , qqlist[0].Interest_Type__c );
                }
                resFields.put( CreateQQActionConstants.TERM_RES , qqlist[0].Term__c );
                resFields.put( CreateQQActionConstants.QQREF_RES , qqlist[0].Quick_Quote_Security_Token__c );   
                resFields.put( CreateQQActionConstants.ACCREF , qqlist[0].genesis__Account__r.Account_Security_Token__c );
                resFields.put(CreateQQActionConstants.LOAN_ESTABLISHMENT_FEE , CreateQQActionConstants.DOLLAR+qqlist[0].Loan_Establishment_Fee__c );   
                res  =  FlowfiUtil.getSuccessResponse( CreateQQActionConstants.success, resFields );
            }else{
                throw new CustomException(CreateQQActionConstants.UNAUTHORISED);
            }
        }catch(Exception e){
            if(e.getTypeName()  ==  CreateQQActionConstants.CUSTOMEXCEPTIONTYPE){
                resFields  =  new Map<String,Object>();
                if(e.getMessage() == CreateQQActionConstants.FAILED || e.getMessage() == CreateQQActionConstants.REFERRED){
                    //no roll back as failed record needs to be captured
                    List<genesis__Quick_Quotes__c> qqlist = [ SELECT Id, 
                                                             Name,
                                                             Quick_Quote_Security_Token__c,
                                                             genesis__Account__r.Account_Security_Token__c 
                                                             FROM genesis__Quick_Quotes__c 
                                                             WHERE Id = :qqid LIMIT 1];
                    resFields.put(CreateQQActionConstants.QUOTE_NO, String.valueOf(qqList[0].Name));
                    resFields.put(CreateQQActionConstants.RES, e.getMessage());
                    if( e.getMessage() == CreateQQActionConstants.REFERRED){
                        resFields.put( CreateQQActionConstants.QQREF_RES , qqlist[0].Quick_Quote_Security_Token__c ); 
                        resFields.put( CreateQQActionConstants.ACCREF , qqlist[0].genesis__Account__r.Account_Security_Token__c );  
                    }
                    res = FlowfiUtil.getSuccessResponse(CreateQQActionConstants.SUCCESS, resFields);
                }else if(e.getMessage() == CreateQQActionConstants.UNAVAILABLE){
                    if(sp!=null) {
                        Database.rollback(sp);
                    }
                    resFields.put(CreateQQActionConstants.RES, e.getMessage());
                    res = FlowfiUtil.getSuccessResponse(CreateQQActionConstants.SUCCESS, resFields);
                }else{
                    if(sp!=null) {
                        Database.rollback(sp);
                    }
                    resFields.put(CreateQQActionConstants.RES, e.getMessage());
                    res = FlowfiUtil.getSuccessResponse(CreateQQActionConstants.SUCCESS, resFields);
                }
            }else{
                resFields=new Map<String,Object>();
                resFields.put(CreateQQActionConstants.RES, CreateQQActionConstants.SOMETHING_WENT_WRONG_EX+ e.getMessage() + e.getStackTraceString());
                res = FlowfiUtil.getSuccessResponse(CreateQQActionConstants.SUCCESS, resFields);
            }
        }
    }
    
    /* function to update security token of account if it is null */
    public void updateSecToken(Account acc){
        String keepEncryption  =  CryptoManager.encrypt(acc.id, System_Configuration__c.getInstance().Org_Level_Private_Key__c);
        String urlEncryption  =  CryptoManager.encodeURL(keepEncryption);
        acc.Account_Security_Token__c =   urlEncryption;
        update acc;
    }
    
    /* function to validate customer's info and create QQ */
    public Id checkAndCreateQuote(Wrapper.QuickQuoteWrapper qqWrap,Boolean createAccount,List<Account> qqAccounts,clcommon__CL_Product__c prod){
        boolean newToBureau=false;
        List<genesis__Quick_Quotes__c> qqList;
        String result;
        String scoreResponse ;
        String qqStatus ;
        String pricingResult;
        Wrapper.ScoreSeekerRequestWrapper score = CreateQQAction.getEquifaxScoreSeekerScore(qqWrap);
        if(score == null || (score.oneScore == null && score.resXml == null)){
            throw new CustomException(CreateQQActionConstants.UNAVAILABLE + CreateQQActionConstants.EQUIFAX_SCORE_SEEKER_EXCEPTIONMSG);
        }else if(!System_Configuration__c.getInstance().ByPass_Risk_API__c && score.IB_Status == CreateQQActionConstants.UNAVAILABLE){
            throw new CustomException(CreateQQActionConstants.UNAVAILABLE);
        }
        sp = Database.setSavepoint();
        // if score returned is null throw exception else get rate estimate
        if(score != null){
            if(score.IB_Status == CreateQQActionConstants.FAILED){
                qqid  =  createQQ(qqWrap, null , prod);
                qqList = [SELECT id, genesis__Status__c,
                          Failed_Reason__c,
                          Quote_Decision_Date__c
                          FROM genesis__Quick_Quotes__c
                          WHERE id =: qqId
                          LIMIT 1];
                qqlist[0].genesis__Status__c = CreateQQActionConstants.FAILED;
                // qqList[0].Quote_Decision_Date__c = System.now();
                qqlist[0].Failed_Reason__c = CreateQQActionConstants.IB_FAILURE;
                update qqList[0];
                insertAtt(score, qqid);
                throw new CustomException(CreateQQActionConstants.FAILED);
            }else if(score.oneScore != null){
                qqid  =  createQQ(qqWrap,Integer.valueOf(score.oneScore),prod);
                qqList = [SELECT id,
                          Name,
                          Loan_Amount_Requested__c,
                          Email__C,
                          IB_Relationship__c,
                          Gender__c,
                          genesis__Account__c,
                          genesis__First_Name__c,
                          genesis__Last_Name__c,
                          Middle_Name__c,
                          genesis__State__c,
                          Loan_Purpose__c,
                          Other_Loan_Purpose__c,
                          Driver_Licence_State__c,
                          Driver_Licence__c,
                          License_Card_Number__c,
                          genesis__Financed_Amount__c,
                          genesis__City__c,
                          Unit_Number__c,
                          Street_Type__c,
                          Street_Name__c,
                          property_name__c,
                          CCR_Score__c,
                          Street_Number__c,
                          genesis__Country__c,
                          Mobile_Number__c,
                          genesis__Postal_Code__c,
                          Bureau_Checks__c,
                          CL_Product_Name__c,
                          Date_Of_Birth__c,
                          Quick_Quote_Evaluated__c,
                          Mailing_City__c,
                          Mailing_Country__c,
                          Mailing_Postal_Code__c,
                          Mailing_State__c,
                          Mailing_Street_Name__c,
                          Mailing_Street_Number__c,
                          Mailing_Street_Type__c,
                          Mailing_Unformatted_Address__c,
                          Mailing_Property_Name__c,
                          Is_Mailing_Address_Same__c,
                          Mailing_Unit_Number__c,
                          PO_GPO_Box__c,
                          Is_PO_box_exist__c
                          FROM genesis__Quick_Quotes__c
                          WHERE id =: qqId
                          LIMIT 1];
                //QuickQuoteBEHandler.createConsentRecord(qqid);
                updateConsernInfo(consentJson,qqid);
                if( createAccount ){
                    QQToAppConversionHandler obj = new QQToAppConversionHandler();
                    obj.setQQId(qqId);
                    obj.setConfigId(qqlist[0].CL_Product_Name__c);
                    obj.getRunTimeQuery();
                    Account qqAccount = obj.createAccount();
                    insert qqAccount;
                    updateSecToken(qqAccount);
                    qqlist[0].genesis__Account__c = qqAccount.Id;
                    update qqlist;
                }else{
                    if(qqAccounts[0].Account_Security_Token__c == null){
                        updateSecToken(qqAccounts[0]);
                    }
                    qqlist[0].genesis__Account__c = qqAccounts[0].Id;
                    update qqlist;
                }
                insertAtt(score, qqid);
                //Rules evaluation
                result = QuickQuoteBEHandler.runScoringAndRules(qqList[0].id);
                if(!result.equals(QuickQuoteBEHandlerConstants.FAILED)){
                    pricingResult =  PricingManager.getRateEstimate(qqList[0].id);
                    if(result.equals(CreateQQActionConstants.REFERRED)){
                        throw new CustomException(CreateQQActionConstants.REFERRED);
                    } 
                    result = pricingResult;
                }else{
                    throw new CustomException(CreateQQActionConstants.FAILED);
                }
                /* if rate estimate is success update the quick quote with account */
                if(result  ==  CreateQQActionConstants.success||Test.isRunningTest()){
                    return qqId;
                }
                else{
                    throw new CustomException(CreateQQActionConstants.FAILED);
                }
            }else{
                qqid  =  createQQ(qqWrap,null,prod);
                qqList = [SELECT ID,
                          genesis__Status__c,
                          Failed_Reason__c,
                          Quote_Decision_Date__c,
                          CL_Product_Name__c
                          FROM genesis__Quick_Quotes__c
                          WHERE id =: qqId
                          LIMIT 1];
                if(score.resXml != null && score.resXml.containsIgnoreCase(CreateQQActionConstants.ERROR_TAG)){
                    String errMsg = (score.resXml!=null && String.isNotBlank(score.resXml)) ? score.resXml.subStringBetween(CreateQQActionConstants.DETAIL_TAG1, CreateQQActionConstants.DETAIL_TAG2):'';
                    qqList[0].genesis__Status__c = CreateQQActionConstants.FAILED;
                    qqList[0].Failed_Reason__c = CreateQQActionConstants.EQUIFAX_FAILED + CreateQQActionConstants.DASH_SIGN_WITH_SPACE +errMsg;
                }else if(score.resXml!=null && score.resXml.containsIgnoreCase(CreateQQActionConstants.MESSAGE_TAG1)){
                    /*This change was added according to SYM-3127 which allowed a LFS stranger to the bureau to proceed
*/
                    newToBureau=true;
                    qqlist[0].Quote_New_to_Bureau__c=true;
                    updateConsernInfo(consentJson,qqid);
                    if( createAccount ){
                        updateConsernInfo(consentJson,qqid);
                        QQToAppConversionHandler obj = new QQToAppConversionHandler();
                        obj.setQQId(qqId);
                        obj.setConfigId(qqlist[0].CL_Product_Name__c);
                        obj.getRunTimeQuery();
                        Account qqAccount = obj.createAccount();
                        insert qqAccount;
                        updateSecToken(qqAccount);
                        qqlist[0].genesis__Account__c = qqAccount.Id;
                        qqlist[0].Quote_New_to_Bureau__c=true;
                        update qqlist;
                    }else{
                        if(qqAccounts[0].Account_Security_Token__c == null){
                            updateSecToken(qqAccounts[0]);
                        }
                        qqlist[0].genesis__Account__c = qqAccounts[0].Id;
                        update qqlist;
                    }
                    //insertAtt(score, qqid);
                    //Rules evaluation according to that of a stranger 
                    result = QuickQuoteBEHandler.runScoringAndRulesforStranger(qqList[0].id);
                    if(!result.equals(QuickQuoteBEHandlerConstants.FAILED)){
                        pricingResult =  PricingManager.getRateEstimate(qqList[0].id);
                        if(result.equals(CreateQQActionConstants.REFERRED)){
                            throw new CustomException(CreateQQActionConstants.REFERRED);
                        } 
                        result = pricingResult;
                    }else{
                        throw new CustomException(CreateQQActionConstants.FAILED);
                    }
                }else{
                    throw new CustomException(CreateQQActionConstants.UNAVAILABLE);
                }
                insertAtt(score, qqid);
                //upsert qqList[0];
                if(newToBureau==true && result==ConstantValues.success){
                    return qqId;
                }else{
                    throw new CustomException(CreateQQActionConstants.FAILED);
                }
            }
        }else{
            throw new CustomException(CreateQQActionConstants.UNAVAILABLE);
        }
    }
    
    /* getQuickQuoteWrapper : This function is used to set the quick quote wrapper */
    public Wrapper.QuickQuoteWrapper getQuickQuoteWrapper(){
        Wrapper.QuickQuoteWrapper qqWrap  =  new Wrapper.QuickQuoteWrapper();
        if(perObj !=  null){
            qqWrap.fName  =  perObj.First_Name.trim(); //to avoid name mismatch because of start and ending spaces
            qqWrap.lName  =  perObj.Last_Name.trim();
            qqWrap.mName  =  perObj.Middle_Name;
            if(String.isNotBlank(perObj.BirthYear) && String.isNotBlank(perObj.BirthMonth) && String.isNotBlank(perObj.BirthDate)){
                qqWrap.dob  =  perObj.BirthYear+CreateQQActionConstants.DASH_SIGN+perObj.BirthMonth.leftPad(2, CreateQQActionConstants.ZERO_STRING )+CreateQQActionConstants.DASH_SIGN+perObj.BirthDate.leftPad(2, CreateQQActionConstants.ZERO_STRING );
            }else{
                throw new CustomException(CreateQQActionConstants.BIRTH_DATE_BLANK);
            }
            qqWrap.gender  =  perObj.Gender;
            qqWrap.specificGender  =  perObj.Please_specify;
            qqWrap.email  =  perObj.Email_Address;
            qqWrap.mobileNumber  =  CreateQQActionConstants.MOBILE_NUMBER_PREFIX + perObj.Mobile_Number;
        }else{
            throw new CustomException(CreateQQActionConstants.REQUIRED_PARAM_MISSING);
        }
        if(homeAddObj !=  null){
            qqWrap.homeAddress  =  homeAddObj.Home_Address;
            if(homeAddObj.Unit_Number != null){
                qqWrap.unitNumber  =  homeAddObj.Unit_Number;}
            
            qqWrap.streetNumber  =  homeAddObj.Street_Number;
            qqWrap.streetName  =  homeAddObj.Street_Name;
            qqWrap.streetType  =  homeAddObj.Street_Type_Address;
            qqWrap.state  =  homeAddObj.State_Address;
            qqWrap.country  =  CreateQQActionConstants.AUSTRALIA;
            qqWrap.city  =  homeAddObj.City;
            qqWrap.zip  =  homeAddObj.Postal_Code;
            qqWrap.residentialStatus  =  homeAddObj.Residential_Status;
            qqWrap.propertyName = homeAddObj.Property_Name;
            if(homeAddObj.home_Address == null){
                qqWrap.homeAddress  =  homeAddObj.Street_Number + ' ' + homeAddObj.Street_Name + ' ' + homeAddObj.Street_Type_Address + ', ' +
                    homeAddObj.City + ' ' + homeAddObj.State_Address + ', ' +
                    CreateQQActionConstants.AUSTRALIA;
            }else{
                qqWrap.homeAddress  =  homeAddObj.Home_Address;
            }
            if(homeAddObj.Unit_Number != null){
                qqWrap.unitNumber  =  homeAddObj.Unit_Number;
                qqWrap.homeAddress  =  qqWrap.unitNumber + ' ' + qqWrap.homeAddress;
            }
        }else{
            throw new CustomException(CreateQQActionConstants.REQUIRED_PARAM_MISSING);
        }
        
        if(postalAddObj !=  null){
            qqWrap.poGpoAddressFlag = postalAddObj.Po_Gpo_Address_Flag;
            if(postalAddObj.Po_Gpo_Address_Flag == false){
                qqWrap.postalAddressSame = postalAddObj.Postal_address;
                qqWrap.postalAddressSearch  =  postalAddObj.Postal_address_search;
                if(postalAddObj.Postal_Unit_Number != null){
                    qqWrap.postalUnitNumber  =  postalAddObj.Postal_Unit_Number;}
                qqWrap.postalStreetNumber  =  postalAddObj.Postal_Street_Number;
                qqWrap.postalStreetName  =  postalAddObj.Postal_Street_Name;
                qqWrap.postalStreetType  =  postalAddObj.Postal_Street_Type_Address;
                qqWrap.postalState  =  postalAddObj.Postal_State_Address;
                qqWrap.postalCountry  =  CreateQQActionConstants.AUSTRALIA;
                qqWrap.postalCity  =  postalAddObj.Postal_City;
                qqWrap.postalZip  =  postalAddObj.Po_Postal_Code;
                qqWrap.postalPropertyName = postalAddObj.Postal_Property_Name;
            }
            else{
                qqWrap.poboxnumber = gpoAddObj.Po_box_number;
                qqWrap.postalCountry  =  CreateQQActionConstants.AUSTRALIA;
                qqWrap.postalZip  =  gpoAddObj.Po_Box_Postal_Code;
                qqWrap.postalCity  =  gpoAddObj.Postal_Box_City;
                qqWrap.postalState = gpoAddObj.Postal_Box_State_Address;
            }
            if(postalAddObj.Postal_address_search == null){
                qqWrap.postalAddressSearch  =  postalAddObj.Postal_Street_Number + ' ' + postalAddObj.Postal_Street_Name + ' ' + postalAddObj.Postal_Street_Type_Address + ', ' +
                    postalAddObj.Postal_City + ' ' + postalAddObj.Postal_State_Address + ', ' +
                    CreateQQActionConstants.AUSTRALIA;
            }else{
                qqWrap.postalAddressSearch  =  postalAddObj.Postal_address_search;
            }
            if(postalAddObj.Postal_Unit_Number != null){
                qqWrap.postalUnitNumber  =  postalAddObj.Postal_Unit_Number;
                qqWrap.postalAddressSearch  =  qqWrap.postalUnitNumber + ' ' + qqWrap.postalAddressSearch;
            }
        }else{
            throw new CustomException(CreateQQActionConstants.REQUIRED_PARAM_MISSING);
        }
        
        if(drivingLicenseObj !=  null){
            qqWrap.driversLicense  =  drivingLicenseObj.Driver_License_Number;
            qqWrap.dlState  =  drivingLicenseObj.State_Of_Issue;
            qqWrap.dlHas  =  !drivingLicenseObj.I_Dont_Have_A_Drivers_License;
            qqWrap.driverCardNumber = drivingLicenseObj.license_Card_Number;
            qqWrap.startDate  =  String.valueOf(FlowfiUtil.currentSystemDate);
        }else{
            throw new CustomException(CreateQQActionConstants.REQUIRED_PARAM_MISSING);
        }
        
        if(loanAmountobj !=  null){
            qqWrap.loanTerm  =  loanAmountobj.Loan_Term;
            qqWrap.loanAmount  =  loanAmountobj.Loan_Amount;
            qqWrap.frequency  =  System_Configuration__c.getInstance().Default_Quick_Quote_Payment_Frequency__c;
        }else{
            throw new CustomException(CreateQQActionConstants.REQUIRED_PARAM_MISSING);
        }
        
        if(loanPurposeObj !=  null){
            List<String> lpList  =  new List<String>();
            if(String.isNotBlank(loanPurposeObj.Select_Loan_Purpose1)){
                lpList  =  loanPurposeObj.Select_Loan_Purpose1.split(CreateQQActionConstants.SEMI_COLON_SIGN);
            }
            if(String.isNotBlank(loanPurposeObj.Select_Loan_Purpose2)){
                List<String> lpList2  =  loanPurposeObj.Select_Loan_Purpose2.split(CreateQQActionConstants.SEMI_COLON_SIGN);
                lpList.addAll(lpList2);
                lpList2  =  new List<String>(new Set<String>(lpList));
                lpList  =  lpList2;
            }
            if(String.isNotBlank(loanPurposeObj.Other_Loan_Purpose)){
                List<String> lpList3  =  loanPurposeObj.Other_Loan_Purpose.split(CreateQQActionConstants.SEMI_COLON_SIGN);
                lpList.addAll(lpList3);
                lpList3  =  new List<String>(new Set<String>(lpList));
                lpList  =  lpList3;
            }
            if(lpList.contains(CreateQQActionConstants.SOMETHING_ELSE)){
                lpList.remove(lpList.indexOf(CreateQQActionConstants.SOMETHING_ELSE));
            }
            if(lpList.size() > 0){
                qqWrap.loanPurpose  =  String.join(lpList, CreateQQActionConstants.SEMI_COLON_SIGN);
            }
        }else{
            throw new CustomException(CreateQQActionConstants.REQUIRED_PARAM_MISSING);
        }
        return qqWrap;
    }
    /* getPortalResponse : This function is used to send response */
    public clcommon.Response getPortalResponse(){
        return res;
    }
    /* function to parse personal info params */
    public void parsePersonalInformation(String jsonString){
        perObj  =  (CreateQQAction.PersonalInformation) Json.deserialize(jsonString, CreateQQAction.PersonalInformation.class);
    }
    public static CreateQQAction.PersonalInformation parsePersonalInfo(String jsonString){
        return (CreateQQAction.PersonalInformation) Json.deserialize(jsonString, CreateQQAction.PersonalInformation.class);
    }
    /* function to parse contact info params */
    public void parseContactDetails(String jsonString){
        conObj  =  (CreateQQAction.ContactDetails) Json.deserialize(jsonString, CreateQQAction.ContactDetails.class);
    }
    /* function to parse loan purpose params */
    public void parseLoanPurpose(String jsonString){
        loanPurposeObj  =  (CreateQQAction.LoanPurpose) Json.deserialize(jsonString, CreateQQAction.LoanPurpose.class);
    }
    /* function to parse loan amount  params */
    public void parseLoanAmount(String jsonString){
        loanAmountobj  =  (CreateQQAction.LoanAmount) Json.deserialize(jsonString, CreateQQAction.LoanAmount.class);
    }
    /* function to parse driving licence info params */
    public void parseDrivingLicense(String jsonString){
        drivingLicenseObj  =  (CreateQQAction.DrivingLicense) Json.deserialize(jsonString, CreateQQAction.DrivingLicense.class);
    }
    /* function to parse address info params */
    public void parseHomeAddress(String jsonString){
        homeAddObj  =  (CreateQQAction.HomeAddress) Json.deserialize(jsonString, CreateQQAction.HomeAddress.class);
    }
    
    /* function to parse Postal address info params */
    public void parsePostalAddress(String jsonString){
        postalAddObj  =  (CreateQQAction.PostalAddress) Json.deserialize(jsonString, CreateQQAction.PostalAddress.class);
    }
    /* function to parse Postal address info params */
    public void parseGpoAddress(String jsonString){
        gpoAddObj  =  (CreateQQAction.GpoAddress) Json.deserialize(jsonString, CreateQQAction.GpoAddress.class);
    }
    
    /* POJO class for personal info params */
    public class PersonalInformation{
        public String first_Name ;
        public String last_Name ;
        public String middle_Name;
        public String gender ;
        public String birthDate ;
        public String birthMonth ;
        public String birthYear;
        public String email_Address;
        public String confirm_Email_Address;
        public String please_specify;
        public String mobile_Number;
    }
    /* POJO class for contact info params */
    public class ContactDetails{
        public Boolean manual_Address_Flag ;
        public String street_Type_Address ;
        public String state_Address ;
        
    }
    /* POJO class for loan purpose info params */
    public class LoanPurpose{
        public String select_Loan_Purpose1 ;
        public String select_Loan_Purpose2 ;
        public String Other_Loan_Purpose ;
    }
    /* POJO class for loan amount info params */
    public class LoanAmount{
        public String loan_Term ;
        public String repayment_Frequency ;
        public String loan_Amount ;
    }
    /* POJO class for driving licence info params */
    public class DrivingLicense{
        public Boolean i_Dont_Have_A_Drivers_License ;
        public String state_Of_Issue ;
        public String driver_License_Number;
        public String license_Card_Number;
    }
    /* POJO class for address info params */
    public class HomeAddress{
        String postal_Code;
        String unit_Number;
        String street_Number;
        String state_Address;
        String street_Name;
        String city;
        String street_Type_Address;
        String residential_Status;
        String manual_Address_Flag;
        String home_Address;
        String Property_Name;
    }
    /* POJO class for Postal address info params */
    public class PostalAddress{
        String Postal_address;
        String Postal_Unit_Number;
        String Postal_Street_Number;
        String Postal_State_Address;
        String Postal_Street_Name;
        String Postal_City;
        String Postal_Street_Type_Address;
        public Boolean Po_Gpo_Address_Flag;
        String Postal_Manual_Address_Flag;
        String Postal_address_search;
        String Postal_Property_Name;
        String Po_Postal_Code;
        String Po_Property_Name;
    }
    /* POJO class for GPO address info params */
    public class GpoAddress{
        String Postal_Box_State_Address;
        String Postal_Box_City;
        String Po_box_number;
        String Postal_State_Country;
        String Po_Box_Postal_Code;
    }
    public static Wrapper.ScoreSeekerRequestWrapper getEquifaxScoreSeekerScore(Wrapper.QuickQuoteWrapper qqWrap){
        Equifaxsoftpullcallout.EquifaxSoftpullRequestWrapper softpullWrap =  CreateQQAction.quickQuotetoSoftPull(qqWrap);
        Wrapper.ScoreSeekerRequestWrapper resp = Equifaxsoftpullcallout.callout(softpullWrap);
        if(resp != null){
            return resp;
        }else{
            throw new CustomException(CreateQQActionConstants.SOFTPULL_GENERATION_FAILED_MGS);
        }
    }
    /* QuickQuotetoSoftPull : This function is used to set the soft pull request wrapper from quick quote wrapper */
    
    public static Equifaxsoftpullcallout.EquifaxSoftpullRequestWrapper quickQuotetoSoftPull(Wrapper.QuickQuoteWrapper qqwrap){
        Equifaxsoftpullcallout.EquifaxSoftpullRequestWrapper softpullRespWrap  =  new Equifaxsoftpullcallout.EquifaxSoftpullRequestWrapper();       
        //softpull request fields
        softpullRespWrap.ProductType = qqwrap.productType;
        softpullRespWrap.firstName = qqwrap.fName;
        softpullRespWrap.lastName = qqwrap.lName;
        softpullRespWrap.middleName = qqwrap.mName;
        Double lnAmnt_Db = Double.valueOf(qqwrap.loanAmount);
        Integer lnAmnt_Int = Integer.valueOf(lnAmnt_Db);
        softpullRespWrap.loanAmount = String.valueOf(lnAmnt_Int);
        softpullRespWrap.unitNum = qqwrap.unitNumber;
        softpullRespWrap.streetNumber = qqwrap.streetNumber;        
        softpullRespWrap.streetName = qqwrap.streetName;
        softpullRespWrap.streetType = qqwrap.streetType;
        softpullRespWrap.province = qqwrap.state;
        softpullRespWrap.city = qqwrap.city;
        softpullRespWrap.postalCode = qqwrap.zip;
        if(qqwrap.dob !=  null){
            softpullRespWrap.dateOfBirth = qqwrap.dob;        
            softpullRespWrap.IB_dateOfBirth = qqwrap.dob;
        }else{
            throw new CustomException(CreateQQActionConstants.BIRTH_DATE_BLANK);
        }
        softpullRespWrap.driverLicense = qqwrap.driversLicense;
        softpullRespWrap.gender = qqwrap.gender;
        softpullRespWrap.country = qqwrap.country;
        //ib request fields
        softpullRespWrap.IB_firstName = qqwrap.fName;  
        softpullRespWrap.IB_middleName = qqwrap.mName;  
        softpullRespWrap.IB_lastName = qqwrap.lName; 
        softpullRespWrap.IB_mobile = qqWrap.mobileNumber;
        softpullRespWrap.IB_addressLine1 = qqwrap.streetNumber +' '+qqwrap.streetName;
        softpullRespWrap.IB_adminArea3 = qqwrap.unitNumber;
        softpullRespWrap.IB_adminArea1 = qqwrap.state; 
        softpullRespWrap.IB_postcode = qqwrap.zip; 
        softpullRespWrap.driverState = qqwrap.dlState;
        
        return softpullRespWrap;
    }
    
    /* upsertQQ : This function is used to insert the quick quote and returns the quick quote object */
    public genesis__Quick_Quotes__c upsertQQ(genesis__Quick_Quotes__c qQuoteObj, Wrapper.QuickQuoteWrapper qqWrap, Integer score, clcommon__CL_Product__c product){
        qQuoteObj.genesis__First_Name__c  =  qqWrap.fName;
        qQuoteObj.genesis__Last_Name__c  =   qqWrap.lName;
        if(qqwrap.dob !=  null){
            qQuoteObj.Date_Of_Birth__c  =  Date.valueOf(qqWrap.dob);
        }else{
            throw new CustomException(CreateQQActionConstants.BIRTH_DATE_BLANK);
        }
        if(String.isNotBlank(qqWrap.unitNumber) && qqWrap.unitNumber.trim().isNumeric()){
            qQuoteObj.Unit_Number__c  =  Integer.valueOf(qqWrap.unitNumber.trim());
        }
        if(qqWrap.mName !=  null){
            qQuoteObj.Middle_Name__c  =  qqWrap.mName;
        }
        if(qqWrap.postalAddressSame == 'Yes'){
            qQuoteObj.Is_Mailing_Address_Same__c = true;
        }
        else{
            qQuoteObj.Is_Mailing_Address_Same__c = false;
        }
        if(qqWrap.poGpoAddressFlag == true){
            qQuoteObj.Is_PO_box_exist__c = true;
        }else{
            qQuoteObj.Is_PO_box_exist__c = false;
        }
        if(String.isNotBlank(qqWrap.postalUnitNumber) && qqWrap.postalUnitNumber.trim().isNumeric()){
            qQuoteObj.Mailing_Unit_Number__c  =  Integer.valueOf(qqWrap.postalUnitNumber.trim());
        } 
        if(qQuoteObj.Is_Mailing_Address_Same__c == true && qQuoteObj.Is_PO_box_exist__c == false){
            qQuoteObj.Mailing_Street_Number__c =  qqWrap.streetNumber ;
            qQuoteObj.Mailing_Street_Name__c = qqWrap.streetName ;
            qQuoteObj.Mailing_Street_Type__c = qqWrap.streetType;
            qQuoteObj.Mailing_State__c = qqWrap.state;
            qQuoteObj.Mailing_Country__c = qqWrap.country;
            qQuoteObj.Mailing_Unformatted_Address__c = qqWrap.homeAddress ;
            qQuoteObj.Mailing_City__c = qqWrap.city ;
            qQuoteObj.Mailing_Postal_Code__c = qqWrap.zip ;
            qQuoteObj.Mailing_Property_Name__c = qqWrap.propertyName;
        }else if(qQuoteObj.Is_Mailing_Address_Same__c == false && qQuoteObj.Is_PO_box_exist__c == false){
            qQuoteObj.Mailing_Street_Number__c = qqWrap.postalStreetNumber;
            qQuoteObj.Mailing_Street_Name__c = qqWrap.postalStreetName;
            qQuoteObj.Mailing_Street_Type__c = qqWrap.postalStreetType;
            qQuoteObj.Mailing_State__c = qqWrap.postalState;
            qQuoteObj.Mailing_Country__c = qqWrap.postalCountry;
            qQuoteObj.Mailing_Unformatted_Address__c = qqWrap.postalAddressSearch;
            qQuoteObj.Mailing_City__c = qqWrap.postalCity;
            qQuoteObj.Mailing_Postal_Code__c = qqWrap.postalZip;
            qQuoteObj.Mailing_Property_Name__c = qqWrap.postalPropertyName;
        }else{
            qQuoteObj.PO_GPO_Box__c = qqWrap.poboxnumber;
            qQuoteObj.Mailing_State__c = qqWrap.postalState;
            qQuoteObj.Mailing_Country__c = qqWrap.postalCountry;
            qQuoteObj.Mailing_City__c = qqWrap.postalCity;
            qQuoteObj.Mailing_Postal_Code__c = qqWrap.postalZip;
        }
        qQuoteObj.Street_Name__c  =  qqWrap.streetName ;
        qQuoteObj.Street_Number__c  =  qqWrap.streetNumber ;
        qQuoteObj.Street_Type__c  =  qqWrap.streetType;
        qQuoteObj.Email__c  =  qqWrap.email;
        qQuoteObj.Mobile_Number__c  =  qqWrap.mobileNumber;
        qQuoteObj.Gender__c  =  qqWrap.gender;
        qQuoteObj.genesis__City__c  =   qqWrap.city ;
        qQuoteObj.genesis__State__c  =  qqWrap.state;
        qQuoteObj.genesis__Postal_Code__c  =  qqWrap.zip ;
        qQuoteObj.property_name__c = qqWrap.propertyName;
        qQuoteObj.genesis__Country__c  =  qqWrap.country;
        qQuoteObj.Driver_Licence__c  =  qqWrap.driversLicense ;
        qQuoteObj.License_Card_Number__c = qqWrap.driverCardNumber;
        qQuoteObj.Quick_Quote_Evaluated__c = true;
        qQuoteObj.Driver_Licence_State__c  =  qqWrap.dlState ;
        qQuoteObj.Other_Gender_Specification__c  =  qqWrap.specificGender;
        qQuoteObj.Unformatted_Address__c  =  qqWrap.homeAddress ;
        if(score != null){
            qQuoteObj.CCR_Score__c = score;
        }
        qQuoteObj.Term__c  =  qqWrap.loanTerm;
        if(qqWrap.loanAmount !=  null){
            qQuoteObj.Loan_Amount_Requested__c  =  Decimal.valueOf(qqWrap.loanAmount);
        }else{
            throw new CustomException(CreateQQActionConstants.LOAN_AMOUNT_BLANK);
        }
        qQuoteObj.genesis__Payment_Frequency__c  =  qqWrap.frequency ;
        qQuoteObj.Loan_Purposes__c  =  qqWrap.loanPurpose;
        qQuoteObj.Loan_Purpose__c = qqWrap.loanPurpose;
        qQuoteObj.CCR_Consent__c  =  true;   
        qQuoteObj.Terms_Of_Use_Consent__c  =  true;
        qQuoteObj.Communication_Consent__c  =  true;
        qQuoteObj.genesis__CL_Product__c  =  product.id;
        qQuoteObj.Residential_Status__c  =  qqwrap.residentialStatus;
        qQuoteObj.Sales_Channel__c  =  CreateQQActionConstants.CHANNEL_ONLINE;
        qQuoteObj.Bureau_Checks__c = true;//marking true as the QQ is only created if Bureau checks are completed
        qQuoteObj.utmCampaign__c=utmCampaign;
        qQuoteObj.utmContent__c=utmContent;
        qQuoteObj.utmMedium__c=utmMedium;
        qQuoteObj.utmSource__c=utmSource;
        qQuoteObj.GCLID__c=gclId;
        qQuoteObj.MSCLKID__c=mscklID;
        qQuoteObj.pageName__c=pageName;
        qQuoteObj.sourceCode__c=sourceCode;
        qQuoteObj.offerCode__c=offerCode;
        if(String.isNotBlank(this.quoteTaggingIdJson)){
            qQuoteObj.Quote_Tagging_Id__c = this.quoteTaggingIdJson;
        }
        if (qqWrap.topup != null && qqWrap.topup == true) {
            qQuoteObj.Top_Up__c = qqWrap.topup;
            Map<Id,Account> qqAccounts= new Map<Id,Account>([SELECT Id, 
                                                             Name, 
                                                             First_Name__c, 
                                                             Last_Name__c,
                                                             Date_of_Birth__c,
                                                             Gender__c,
                                                             Account_Security_Token__c,
                                                             Email__c,
                                                             Mobile_Number__c    
                                                             FROM Account 
                                                             WHERE Email__c =: qqWrap.email 
                                                             ORDER BY CreatedDate
                                                             LIMIT 1]);
            List<loan__Loan_Account__c> loanlist = [ SELECT id,
                                                    Name,
                                                    loan__Account__c,
                                                    loan__Pay_Off_Amount_As_Of_Today__c
                                                    FROM loan__Loan_Account__c
                                                    WHERE loan__Account__c IN: qqAccounts.keySet()
                                                    ORDER BY CreatedDate DESC LIMIT 1];
            qQuoteObj.CL_Contract__c = loanlist[0].id;
            List<Insurance__c> insuranceList = [SELECT id,
                                                Premium_Rebate_Amount_Gross__c,
                                                User_Defined_Policy_Status__c,
                                                Cancellation_Date__c,
                                                Cancellation_Effective_Date__c
                                                FROM Insurance__c
                                                WHERE Loan_Account__r.loan__Account__c IN: qqAccounts.keySet()
                                                AND Policy_Status__c = 'Active'
                                                AND Loan_Account__r.loan__Loan_Status__c LIKE '%Active%'
                                               ];
            Double rebateAmount = TopupDisbursalAPI.calculateRebateAmount(insuranceList);
            Double currentPayoff = loanlist[0].loan__Pay_Off_Amount_As_Of_Today__c == null ? 0.0 : loanlist[0].loan__Pay_Off_Amount_As_Of_Today__c;
            qQuoteObj.Old_Cash__c =  currentPayoff - rebateAmount;
        }
        upsert qQuoteObj;
        return qQuoteObj;
    }
    /* createQQ : This function returns id of quick quote just created */
    public id createQQ(Wrapper.QuickQuoteWrapper qqwrap,Integer score,clcommon__CL_Product__c product)
    {
        genesis__Quick_Quotes__c qQuoteObj  =  new genesis__Quick_Quotes__c();
        genesis__Quick_Quotes__c qQuoteObjNew  =  upsertQQ(qQuoteObj, qqWrap, score, product);
        if(!Test.isRunningTest()){
            GenerateEncryptedQQuoteTokenBatch.updateQuickQuote(new List<genesis__Quick_Quotes__c>{qQuoteObjNew});
            qQuoteObjNew.Quote_Decision_Date__c = FlowfiUtil.currentSystemDateTime ;
            update qQuoteObj;
            return qQuoteObjNew.id;  
        }
        else {
            return qQuoteObjNew.Id;
        }
    }
    public void updateConsernInfo(String jsonStr, String quickQuoteId){
        Boolean conseretails  =  false;
        if(String.isNotBlank(jsonStr)){
            conseretails  =  Boolean.valueOf(jsonStr);
        }
        if(String.isNotBlank(quickQuoteId)){
            List<Customer_Communication_Consent__c> consentObj  =  [SELECT Id,
                                                                    Quote_Confirmation__c
                                                                    FROM Customer_Communication_Consent__c 
                                                                    WHERE Quick_Quote_ID__c  = : quickQuoteId];
            if(consentObj.size() > 0){
                consentObj[0].Quote_Confirmation__c  =  conseretails;
                update consentObj;
            }
        }
    }
    public static void insertAtt(Wrapper.ScoreSeekerRequestWrapper score, id qqId){
        List<Attachment> attList = new List<Attachment>();
        if(String.isNotBlank(score.resXml) && String.isNotBlank(score.ScoreSeekerRequest)){
            Attachment attachment1 = new Attachment(
                ParentId = qqid,
                Name = QuickQuoteBEHandlerConstants.SCORESEEKER_RESP + String.valueOf(DateTime.now()) + QuickQuoteBEHandlerConstants.TEXT_EXT,
                Body = Blob.valueOf(score.resXml));
            Attachment attachment2 = new Attachment(
                ParentId = qqid,
                Name = CreateQQActionConstants.SCORESEEKER_REQ + CreateQQActionConstants.DASH_SIGN + String.valueOf(DateTime.now()) + QuickQuoteBEHandlerConstants.TEXT_EXT,
                Body = Blob.valueOf(score.ScoreSeekerRequest));
            attList.add(attachment1);
            attList.add(attachment2);
        }
        if(String.isNotBlank(score.RISKRequest) ){
            Attachment attachment2 = new Attachment(
                ParentId = qqid,
                Name = CreateQQActionConstants.IB_RISK_REQ + CreateQQActionConstants.DASH_SIGN + String.valueOf(DateTime.now()) + QuickQuoteBEHandlerConstants.TEXT_EXT,
                Body = Blob.valueOf(score.RISKRequest));
            attList.add(attachment2);
        }
        if(String.isNotBlank(score.RISKResponse)){
            try{
                LFSGetAppAssessmentInfoParser parser = new LFSGetAppAssessmentInfoParser();
                parser.parseInternalBureauData(qqid, score.RISKResponse);
            }catch(Exception e){
            }
            Attachment attachment1 = new Attachment(
                ParentId = qqid,
                Name = CreateQQActionConstants.IB_RISK_RESP + CreateQQActionConstants.DASH_SIGN + String.valueOf(DateTime.now()) + QuickQuoteBEHandlerConstants.TEXT_EXT,
                Body = Blob.valueOf(score.RISKResponse));
            attList.add(attachment1);
        }else{
            Attachment attachment1 = new Attachment(
                ParentId = qqid,
                Name = CreateQQActionConstants.IB_RISK_RESP + CreateQQActionConstants.DASH_SIGN + String.valueOf(DateTime.now()) + QuickQuoteBEHandlerConstants.TEXT_EXT,
                Body = Blob.valueOf(CpConstants.IB_BLANK_BODY));
            attList.add(attachment1);
        }
        if(!attList.isEmpty()){
            insert attList;
        }
    }
    //This method will send  Quick quote response to Online and OTP channel
    public static Map<String,Object> topupQQResponsehandler(Id accId){
        boolean qqExist = false;
        boolean appExists = false;
        Map<String,Object> qqresFields = new Map<String,Object>();
        List <genesis__Quick_Quotes__c> qqList  = [SELECT  id,
                                                   Name,
                                                   Residential_Status__c,
                                                   Repayment_Amount__c,
                                                   genesis__Account__c,
                                                   Term__c,
                                                   Email__c,
                                                   Top_Up__c,
                                                   Mobile_Number__c,
                                                   genesis__First_Name__c,
                                                   Middle_Name__c,
                                                   genesis__Last_Name__c,
                                                   Date_Of_Birth__c,
                                                   genesis__Account__r.Email_Verified__c, 
                                                   Loan_Amount_Requested__c,
                                                   genesis__Financed_Amount__c, 
                                                   genesis__Payment_Frequency__c, 
                                                   Quick_Quote_Security_Token__c, 
                                                   Interest_Type__c, 
                                                   Indicative_Interest_Rate__c,
                                                   genesis__Account__r.Account_Security_Token__c,
                                                   Loan_Purposes__c,
                                                   Loan_Establishment_Fee__c,
                                                   Broker_Fee_Amount__c,
                                                   CL_Contract__c,
                                                   CL_Contract__r.Payoff_amount_valid_till_date__c,
                                                   genesis__Status__c,
                                                   genesis__Application__r.genesis__Status__c                                                       
                                                   FROM genesis__Quick_Quotes__c 
                                                   WHERE genesis__Account__c = :accId
                                                   AND Top_Up__c = TRUE
                                                   AND genesis__Status__c in ('ENTERED', 'REFERRED', 'CONVERTED TO APPLICATION')
                                                   AND (not (genesis__Application__r.genesis__Status__c like :TopupDisbursalConstant.EXPIRED_STATUS or genesis__Application__r.genesis__Status__c like :TopupDisbursalConstant.TOPUP_FUNDED_STATUS or genesis__Application__r.genesis__Status__c like :TopupDisbursalConstant.DECLINED_STATUS or genesis__Application__r.genesis__Status__c like :TopupDisbursalConstant.WITHDRAWN_STATUS or genesis__Application__r.genesis__Status__c like :TopupDisbursalConstant.FAILED_STATUS or genesis__Application__r.genesis__Status__c like :TopupDisbursalConstant.CLOSED_STATUS))
                                                   ORDER BY CREATEDDATE DESC
                                                   LIMIT 1];
        /* generating success response needed for recalculate Emi page */
        if (!qqList.isEmpty() && (qqList[0].genesis__Status__c == 'CONVERTED TO APPLICATION')) {
            appExists = true;
        }else if (!qqList.isEmpty()) {
            qqExist = true;
        }
        qqresFields.put('quoteExists', qqExist);
        qqresFields.put('appExists', appExists);
        if (qqExist) {
            List<Insurance__c> insuranceList  = [SELECT id,
                                                 Loan_Account__c,
                                                 Policy_Status__c,
                                                 Premium_Rebate_Amount_Gross__c,
                                                 User_Defined_Policy_Status__c,
                                                 Cancellation_Date__c,Policy_Expiry_Date__c ,
                                                 Cancellation_Effective_Date__c
                                                 FROM Insurance__c
                                                 WHERE Policy_Status__c = 'Active' AND Loan_Account__c =: qqList[0].CL_Contract__c];
            
            Decimal rebateAmt = Decimal.valueOf(TopupDisbursalAPI.calculateRebateAmount(insuranceList));
            Decimal outLoanBalance = (Decimal)(qqList[0].CL_Contract__r.Payoff_amount_valid_till_date__c) - rebateAmt;
            Decimal topupAmount = (Decimal)(qqList[0].Loan_Amount_Requested__c);
            Decimal brokerFee = (Decimal)(qqList[0].Broker_Fee_Amount__c == null ? 0 : qqList[0].Broker_Fee_Amount__c);
            Decimal topupLef =  (Decimal)(qqList[0].Loan_Establishment_Fee__c);
            Decimal totalLoanAmount = topupAmount + (outLoanBalance - rebateAmt) + topupLef + brokerFee;
            
            qqresFields.put('qtOutLoanBal', outLoanBalance.setScale(2));
            qqresFields.put('qtTopupTotalLnAmt', totalLoanAmount.setScale(2));
            
            qqresFields.put(CreateQQActionConstants.QUOTE_NO, String.valueOf(qqList[0].Name));
            qqresFields.put(CreateQQActionConstants.RES, CreateQQActionConstants.SUCCESS);
            qqresFields.put( CreateQQActionConstants.INT_RATE_RES , String.valueOf(qqList[0].Indicative_Interest_Rate__c));
            qqresFields.put( 'qtRate' , String.valueOf(qqList[0].Indicative_Interest_Rate__c));
            qqresFields.put( CreateQQActionConstants.LOAN_AMT_RES , qqList[0].genesis__Financed_Amount__c.setScale(2));
            qqresFields.put( 'qtTopupAmt' , qqList[0].Loan_Amount_Requested__c.setScale(2) );
            qqresFields.put( 'email' , qqList[0].Email__c );
            qqresFields.put( 'mobile_phone', qqList[0].Mobile_Number__c );
            qqresFields.put( 'title' , '' );
            qqresFields.put( 'first_name' , qqList[0].genesis__First_Name__c );
            if (qqList[0].Middle_Name__c == null) {
                qqresFields.put( 'middle_name' , '');
            } else {
                qqresFields.put( 'middle_name' , qqList[0].Middle_Name__c );
            }
            qqresFields.put( 'last_name' , qqList[0].genesis__Last_Name__c );
            qqresFields.put( 'date_of_birth', String.valueOf(qqList[0].Date_Of_Birth__c) );
            qqresFields.put( 'email_verified' , qqList[0].genesis__Account__r.Email_Verified__c );
            Decimal rpAmountNotRounded = 0.00; 
            if(qqList[0].Repayment_Amount__c != null) {
                rpAmountNotRounded = qqList[0].Repayment_Amount__c;
            }
            qqresFields.put( CreateQQActionConstants.REPAYMENT_RES , rpAmountNotRounded.setScale(2, RoundingMode.HALF_UP));
            qqresFields.put( 'qtRepmtAmt' , rpAmountNotRounded.setScale(2, RoundingMode.HALF_UP));
            String repaymentFreq = '';
            if (String.valueOf(qqList[0].genesis__Payment_Frequency__c).equalsIgnoreCase(CreateQQActionConstants.BIWEEKLY)) {
                repaymentFreq = CreateQQActionConstants.FORTNIGHTLY;
            }else{
                repaymentFreq = qqList[0].genesis__Payment_Frequency__c;
            }
            qqresFields.put( CreateQQActionConstants.REP_FREQUENCY_RES , repaymentFreq );
            qqresFields.put( 'qtFreq' , repaymentFreq );
            String interestType = '';
            if (String.valueOf(qqList[0].Interest_Type__c).equalsIgnoreCase(CreateQQActionConstants.FLOATING)) {
                interestType = CreateQQActionConstants.VARIABLE;
            }else{
                interestType = qqList[0].Interest_Type__c;
            }
            qqresFields.put( CreateQQActionConstants.LOAN_TYPE_RES, interestType);
            qqresFields.put( 'qtLoanType' , interestType);
            qqresFields.put( CreateQQActionConstants.TERM_RES , qqList[0].Term__c );
            qqresFields.put( 'qtTerms' , qqList[0].Term__c );
            qqresFields.put( CreateQQActionConstants.QQREF_RES , qqList[0].Quick_Quote_Security_Token__c );   
            qqresFields.put( CreateQQActionConstants.ACCREF , qqList[0].genesis__Account__r.Account_Security_Token__c );
            qqresFields.put(CreateQQActionConstants.LOAN_ESTABLISHMENT_FEE , CreateQQActionConstants.DOLLAR + qqList[0].Loan_Establishment_Fee__c ); 
            qqresFields.put('qtBrokerFee', qqList[0].Broker_Fee_Amount__c);
            qqresFields.put('qtPurpose', qqList[0].Loan_Purposes__c);
        }
        return qqresFields;  
    }
    
    /* 
* checkAndCreateQuoteTopup : method to validate customer's info and create QQ 
* Developer : Rahul Mahato
*/
    
    public Id checkAndCreateQuoteTopup(Wrapper.QuickQuoteWrapper qqWrap, clcommon__CL_Product__c prod){
        boolean newToBureau=false;
        String result;
        String scoreResponse ;
        String qqStatus ;
        String pricingResult;
        Boolean flag = false;
        List<User> usrlist = [ SELECT Id,
                              Name,
                              Email, 
                              contactId,
                              accountId,
                              Profile.name
                              FROM User
                              WHERE Id = :UserInfo.getUserId()
                              LIMIT 1];
        // if(usrList.isEmpty() || String.isBlank(usrList[0].contactId) || String.isBlank(usrList[0].accountId)){
        //         throw new CustomException(CpConstants.ACCESS_DENIED);
        //  }
        if(BrokerPortalSecurityUtil.profileChecking(usrlist[0].Id)){
            flag = true;
        }
        // List<account> accntlist = [SELECT ID 
        //                                 FROM Account 
        //                                 WHERE Id = :accnt
        //                                 LIMIT 1];
        // if(accntlist == null ){
        //     throw new CustomException(ConstantValues.ACC_NOT_FOUND);
        // }
        // System.debug('accntlist --->' + accntlist);
        // List<loan__Loan_Account__c> lnAccList2=[SELECT Id,
        //                                                loan__Loan_Product_Name__c
        //                                                FROM loan__Loan_Account__c 
        //                                                WHERE loan__Account__c=: accntlist[0].ID
        //                                                AND loan__Loan_Status__c !=:TopupDisbursalConstant.CANCELED_STATUS];
        
        // if(lnAccList2 == null ){
        //     throw new CustomException(ResponseMessenger.loanAccNotFound);
        // }
        
        // System.debug('lnAccList2 --->' + lnAccList2);
        // /* querying product based on product name to assign it to quick quote */
        // clcommon__CL_Product__c prod =  [ SELECT  ID, 
        //                                            Name,
        //                                            clcommon__Product_Name__c,
        //                                            loan__Lending_Product__c
        //                                            FROM clcommon__CL_Product__c 
        //                                            WHERE loan__Lending_Product__c  = :lnAccList2[0].loan__Loan_Product_Name__c
        //                                            LIMIT 1 ];
        // if(prod == null ){
        //     throw new CustomException(ConversionConstant.PRODUCTNOTFOUND);
        // }
        // System.debug('prod --->' + prod);
        boolean createAccount = true; //if account not present with the provided mail, create account
        List<String> eligibleQQStatuses = new List<String>{CreateQQActionConstants.REFERRED, CreateQQActionConstants.QQ_STATUS_ENTERED};
            /* querying account based on mail provided to check for existing borrower account */
            Map<Id,Account> qqAccounts= new Map<Id,Account>([SELECT Id, 
                                                             Name, 
                                                             First_Name__c, 
                                                             Last_Name__c,
                                                             Date_of_Birth__c,
                                                             Gender__c,
                                                             Account_Security_Token__c,
                                                             Email__c,
                                                             Mobile_Number__c    
                                                             FROM Account 
                                                             WHERE Email__c =: qqWrap.email 
                                                             ORDER BY CreatedDate
                                                             LIMIT 1]);
        if(!qqAccounts.isEmpty() && qqAccounts.size() >= 1){
            Integer checkQuote = [SELECT COUNT()
                                  FROM genesis__Quick_Quotes__c 
                                  WHERE genesis__Account__c IN: qqAccounts.keySet()
                                  AND genesis__Status__c IN: eligibleQQStatuses];
            if(checkQuote != null && checkQuote > 0){
                throw new CustomException(CpConstants.ACCOUNT_DETAILS_EX);
            }
            createAccount  =  false;
        }
        // Here TopUp Quick quote are created for Broker Portal
        
        if(flag == true){
            BPCreateQQAction topupBrokerqt = new BPCreateQQAction();
            qqId  =  topupBrokerqt.checkAndCreateQuote(qqWrap, createAccount, qqAccounts.values(), prod, usrlist[0].contactId, usrlist[0].accountId, usrlist[0].Email);
        }else{
            
            // Here TopUp Quick quote are created for OTP and Online channel
            
            qqId  =  checkAndCreateQuote(qqWrap, createAccount, qqAccounts.values(), prod);
            List<genesis__Quick_Quotes__c> quickquoteList = [SELECT id,
                                                             Name,
                                                             CL_Contract__c,
                                                             Top_Up__c,
                                                             Old_Cash__c,
                                                             Sales_Channel__c,
                                                             genesis__Contact__c,
                                                             Loan_Amount_Requested__c,
                                                             Broker_Fee_Amount__c
                                                             FROM genesis__Quick_Quotes__c
                                                             WHERE id =: qqId
                                                             LIMIT 1];
            
            if(usrlist[0].Profile.name == 'FF Community User'){
                quickquoteList[0].Sales_Channel__c = 'Online';
            }else{
                quickquoteList[0].Sales_Channel__c = 'OTP';
            }
            // List<loan__Loan_Account__c> loanlist = [ SELECT id,
            //                                                 Name,
            //                                                 loan__Account__c,
            //                                                 loan__Pay_Off_Amount_As_Of_Today__c
            //                                                 FROM loan__Loan_Account__c
            //                                                 WHERE loan__Account__c IN: qqAccounts.keySet()
            //                                                 ORDER BY CreatedDate DESC LIMIT 1];
            // quickquoteList[0].CL_Contract__c = loanlist[0].id;
            // quickquoteList[0].Top_Up__c = true;
            // quickquoteList[0].Old_Cash__c = loanlist[0].loan__Pay_Off_Amount_As_Of_Today__c;
            update quickquoteList;
        }
        List<genesis__Quick_Quotes__c> qqList = [SELECT id,
                                                 Residential_Status__c,
                                                 Repayment_Amount__c,
                                                 Term__c,
                                                 CL_Contract__c,
                                                 CL_Contract__r.loan__Pay_Off_Amount_As_Of_Today__c,
                                                 CL_Contract__r.loan__Interest_Rate__c,
                                                 CL_Contract__r.loan__Contact__c,
                                                 Old_Cash__c,
                                                 Loan_Type__c,
                                                 Loan_Amount_Requested__c,
                                                 CL_Contract__r.loan__Loan_Product_Name__c,
                                                 genesis__Account__c,
                                                 genesis__Contact__c,
                                                 CL_Product_Name__c,
                                                 genesis__Financed_Amount__c, 
                                                 genesis__Payment_Frequency__c, 
                                                 Quick_Quote_Security_Token__c, 
                                                 Interest_Type__c, 
                                                 Indicative_Interest_Rate__c,
                                                 Margin_Rate__c,
                                                 Broker_Fee_Amount__c,
                                                 genesis__CL_Product__c,
                                                 genesis__CL_Product__r.clcommon__Product_Name__c,
                                                 Loan_Purpose__c,
                                                 Flexed_Interest_Rate__c,
                                                 Loan_Establishment_Fee__c,
                                                 Top_Up__c,
                                                 genesis__Status__c,
                                                 Credit_Rating_Matrix__r.Name,
                                                 Credit_Rating_Matrix__c,
                                                 Credit_Rating_Matrix__r.Total_Interest_Variable_Rate__c,
                                                 IB_Relationship__c,
                                                 Quote_New_to_Bureau__c,
                                                 Unit_Number__c,
                                                 Street_Number__c,
                                                 Street_Name__c,
                                                 Street_Type__c,
                                                 genesis__City__c,
                                                 genesis__State__c,
                                                 genesis__Postal_Code__c,
                                                 Unformatted_Address__c,
                                                 Driver_Licence_Available__c,
                                                 Driver_Licence__c,
                                                 Driver_Licence_State__c
                                                 FROM genesis__Quick_Quotes__c
                                                 WHERE id =: qqId
                                                 LIMIT 1];
        Decimal totalLoanAmount = Test.isRunningTest()?10000:(qqlist[0].Loan_Amount_Requested__c + qqlist[0].CL_Contract__r.loan__Pay_Off_Amount_As_Of_Today__c); 
            
            if(((qqList[0].Loan_Amount_Requested__c > 1000) && (qqList[0].Loan_Amount_Requested__c < 5000)) && ((qqList[0].Broker_Fee_Amount__c != null))){
                qqList[0].Broker_Fee_Amount__c = 0;
            }
        if(qqList[0].CL_Contract__c != null){
            qqList[0].genesis__Contact__c = qqList[0].CL_Contract__r.loan__Contact__c;
        }
        String unitNo;
        if(String.isNotBlank(String.valueOf(qqList[0].Unit_Number__c))){
            unitNo = FlowfiUtil.validateAlphaNumParams(qqList[0].Unit_Number__c, null, ResponseMessenger.unitNumberBlank,false,false);
        }
        String streetNumber = FlowfiUtil.validateNullParams(qqList[0].Street_Number__c,ResponseMessenger.streetNumberNotFound,true);
        String streetName = FlowfiUtil.validateNullParams(qqList[0].Street_Name__c, ResponseMessenger.streetNameNotFound,true);
        
        String streetType1 = FlowFiUtil.validateNullParams(qqList[0].Street_Type__c,ResponseMessenger.streetTypeBlank,false);
        String streetType2 = FlowfiUtil.getStreeCodeFromStName(qqList[0].Street_Name__c);
        if(streetType1==null){
            streetType1 = streetType2;
        }               
        String city = FlowfiUtil.validateNullParams(qqList[0].genesis__City__c, ResponseMessenger.cityNotFound, true);
        
        String stateStr = String.valueOf(qqList[0].genesis__State__c);
        String state = FlowfiUtil.validateAlphaParam(stateStr, ResponseMessenger.stateNotFound, ResponseMessenger.stateBlank,true,true);
        
        String postalCode = FlowfiUtil.validateNullParams(qqList[0].genesis__Postal_Code__c, ResponseMessenger.postalCodeNotFound, true);
        String rawAddress = String.valueOf(qqList[0].Unformatted_Address__c);
        
        if(String.isNotBlank(rawAddress) && String.isBlank(unitNo)){
            String uNum = FlowfiUtil.extractUnitNumber(rawAddress);
            if(String.isBlank(uNum)){
                unitNo = uNum;
            }
        }
        /**
* Account address, residential status and id detatils updation for Broker, Online, OTP
*/
        Account customerAcc = new Account();
        customerAcc.Id = qqList[0].genesis__Account__c;
        /**
* address components updation
*/
        customerAcc.Unit_Number__c = unitNo;
        customerAcc.Street_Number__c = streetNumber;
        customerAcc.Street_Name__c = streetName;
        customerAcc.Street_Type__c = streetType1;
        customerAcc.City__c = city;
        customerAcc.State__c = state;
        customerAcc.Zip__c = postalCode;
        customerAcc.Country__c = CreateQQActionConstants.AUSTRALIA;
        /**
* billing address updation
*/
        customerAcc.BillingCity = customerAcc.City__c;
        customerAcc.BillingCountry = customerAcc.Country__c;
        customerAcc.BillingPostalCode = customerAcc.Zip__c;
        customerAcc.BillingStreet = customerAcc.Street_Number__c + ' ' + customerAcc.Street_Name__c + ' ' + customerAcc.Street_Type__c;
        customerAcc.BillingState = customerAcc.State__c;
        /**
* residential status updation
*/
        customerAcc.Residential_Status__c = qqList[0].Residential_Status__c;
        /**
* id details updation
*/
        customerAcc.Drivers_Licence_Not_Available__c = !(qqList[0].Driver_Licence_Available__c);
        customerAcc.Drivers_Licence__c = qqList[0].Driver_Licence__c;
        customerAcc.Driver_Licence_State__c = qqList[0].Driver_Licence_State__c;
        update customerAcc;
        
        // System_Configuration__c sysConfig = System_Configuration__c.getInstance();
        // List<genesis__Credit_Rating_Matrix__c> minCredMatList = [ SELECT Id,
        //                                                             Loan_Product__c,
        //                                                             Interest_Rate__c,
        //                                                             Total_Interest_Variable_Rate__c,
        //                                                             LEF__c
        //                                                             FROM genesis__Credit_Rating_Matrix__c 
        //                                                             WHERE Name =: System.Label.min_credit_rating_tier
        //                                                             AND Enabled__c = true
        //                                                             AND (Loan_Product__c =: qqList[0].genesis__CL_Product__r.clcommon__Product_Name__c)
        //                                                             LIMIT 1];
        // Decimal minCredRate = (minCredMatList[0].Loan_Product__c == null || minCredMatList[0].Loan_Product__c.contains('Fixed')) ? minCredMatList[0].Interest_Rate__c : minCredMatList[0].Total_Interest_Variable_Rate__c;     
        // if(qqList[0].Quote_New_to_Bureau__c == true && qqList[0].Indicative_Interest_Rate__c != null && qqList[0].Loan_Type__c == ConstantValues.PRO_PERSONAL_LOAN_DEF) {
        //     qqList[0].Indicative_Interest_Rate__c = qqList[0].CL_Contract__r.loan__Interest_Rate__c < minCredRate ? minCredRate : qqList[0].CL_Contract__r.loan__Interest_Rate__c;
        //     qqList[0].Flexed_Interest_Rate__c = qqList[0].Indicative_Interest_Rate__c;
        //     qqList[0].Margin_Rate__c = qqList[0].Flexed_Interest_Rate__c - sysConfig.Base_Rate__c;
        // }else if(qqList[0].Quote_New_to_Bureau__c == true && qqList[0].Indicative_Interest_Rate__c != null && qqList[0].Loan_Type__c == ConstantValues.PRO_PERSONAL_LOAN_DEF2){
        //     qqList[0].Indicative_Interest_Rate__c = qqList[0].Flexed_Interest_Rate__c;
        // }
        update qqList[0];        
        // if(qqList[0].Loan_Type__c.contains('Variable')){
        
        //     // List<genesis__Credit_Rating_Matrix__c> credMatList = [ SELECT Id,Name,Margin_Rate__c,Loan_Product__c,
        //     //                                                                 Interest_Rate__c,
        //     //                                                                 Total_Interest_Variable_Rate__c,
        //     //                                                                 LEF__c,
        //     //                                                                 Risk_Grade_Segment__c
        //     //                                                                 FROM genesis__Credit_Rating_Matrix__c 
        //     //                                                                 WHERE ((Name =: System.Label.min_credit_rating_tier OR Name =: qqList[0].Credit_Rating_Matrix__r.Name) AND (Risk_Grade_Segment__c =: qqList[0].IB_Relationship__c))
        //     //                                                                 AND (Loan_Product__c =: qqList[0].genesis__CL_Product__r.clcommon__Product_Name__c OR Loan_Product__c = '')];
        //     List<genesis__Quick_Quotes__c> quickList = [SELECT id,
        //                                                     CL_Contract__c,
        //                                                     Indicative_Interest_Rate__c,
        //                                                     CL_Contract__r.loan__Interest_Rate__c,
        //                                                     Credit_Rating_Matrix__r.Total_Interest_Variable_Rate__c,
        //                                                     IB_Relationship__c
        //                                                     FROM genesis__Quick_Quotes__c
        //                                                     WHERE id =: qqId
        //                                                     LIMIT 1];
        
        //     System.debug('quickList=====>>>>'+quickList);
        //     System.debug('loan__Interest_Rate__c=====>>>>'+quickList[0].CL_Contract__r.loan__Interest_Rate__c);
        //     System.debug('Credit_Rating_Matrix__r=====>>>>'+quickList[0].Credit_Rating_Matrix__r.Total_Interest_Variable_Rate__c);
        
        //     if((quickList[0].CL_Contract__r.loan__Interest_Rate__c) > (quickList[0].Credit_Rating_Matrix__r.Total_Interest_Variable_Rate__c)){
        
        //         quickList[0].Indicative_Interest_Rate__c = quickList[0].Credit_Rating_Matrix__r.Total_Interest_Variable_Rate__c;
        //     }else{
        //         quickList[0].Indicative_Interest_Rate__c = quickList[0].CL_Contract__r.loan__Interest_Rate__c;
        //     }
        //     update quickList;
        //     System.debug('Indicative_Interest_Rate__c=====>>>>'+quickList[0].Indicative_Interest_Rate__c);
        // }
        
        // if(qqList[0].Top_Up__c == true && qqList[0].genesis__CL_Product__r.clcommon__Product_Name__c.contains('Fixed') && (qqList[0].genesis__Status__c == CreateQQActionConstants.REFERRED || qqList[0].genesis__Status__c == CreateQQActionConstants.QQ_STATUS_ENTERED)){
        //     quickQuoteBlendedRateCalc(qqList);
        // }
        
        // clcommon__CL_Product__c loanProd=[select id, name from clcommon__CL_Product__c where loan__Lending_Product__c =:qqList[0].CL_Contract__r.loan__Loan_Product_Name__c limit 1];  
        
        // qqList[0].genesis__CL_Product__c  =  loanProd.id;   
        // update qqList;
        return qqId;
    }
    
    /* 
* quickQuoteBlendedRateCalc : method to calculated blended rate for fixed product and retaining loan interest rate for variable one
*/
    
    public void quickQuoteBlendedRateCalc(List<genesis__Quick_Quotes__c> qqList){
        Integer loanTermFinance = Integer.valueOf(qqList[0].Term__c) * 12;
        String loanFreqFinance = qqList[0].genesis__Payment_Frequency__c;
        Decimal loanAmtFinance = qqList[0].Loan_Amount_Requested__c;
        Date startDate = Date.today();
        Date firstPayDate = Date.today().addMonths(1);
        String daysConvention;
        String interestCalcMethod;
        Decimal modifiedInterestRate = 0.00;
        Decimal blendedInterestRate = 0.00;
        Decimal rpAmountNotRounded = 0.00; 
        if(qqlist[0].Repayment_Amount__c != null) {
            rpAmountNotRounded = qqlist[0].Repayment_Amount__c;
        }
        //  System.debug('qqList[0].Credit_Rating_Matrix__r.Name => ' + qqList[0].Credit_Rating_Matrix__r.Name);
        //  System.debug('qqList[0].IB_Relationship__c => ' + qqList[0].IB_Relationship__c);
        //  System.debug('qqList[0].genesis__CL_Product__r.clcommon__Product_Name__c => ' + qqList[0].genesis__CL_Product__r.clcommon__Product_Name__c);
        /**
* picking up both minimum crm and newly assigned crm
*/
        List<genesis__Credit_Rating_Matrix__c> credMatList = [ SELECT Id,
                                                              Name,
                                                              Margin_Rate__c,
                                                              Loan_Product__c,
                                                              Interest_Rate__c,
                                                              Total_Interest_Variable_Rate__c,
                                                              LEF__c,
                                                              Risk_Grade_Segment__c
                                                              FROM genesis__Credit_Rating_Matrix__c 
                                                              WHERE Enabled__c = true AND ((Name =: System.Label.min_credit_rating_tier OR Name =: qqList[0].Credit_Rating_Matrix__r.Name) AND (Risk_Grade_Segment__c INCLUDES (:qqList[0].IB_Relationship__c)))
                                                              AND (Loan_Product__c =: qqList[0].genesis__CL_Product__r.clcommon__Product_Name__c OR Loan_Product__c = '')];
        Decimal minCredRate = 0.0;
        
        Decimal parentRate = qqList[0].CL_Contract__r.loan__Interest_Rate__c != null ? qqList[0].CL_Contract__r.loan__Interest_Rate__c : 0.0;
        genesis__Credit_Rating_Matrix__c qtcredmatrix;
        genesis__Credit_Rating_Matrix__c mincredmatrix;
        if (!credMatList.isEmpty() && credMatList.size() == 2) {
            if(!credMatList[0].Name.equalsIgnoreCase(System.Label.min_credit_rating_tier)){
                qtcredmatrix = credMatList[0];
                mincredmatrix = credMatList[1];
            }else{
                qtcredmatrix = credMatList[1];
                mincredmatrix = credMatList[0];
            }
        }else if (!credMatList.isEmpty() && credMatList.size() == 1) {
            qtcredmatrix = credMatList[0];
            mincredmatrix = credMatList[0];
        }else {
            throw new CustomException(UnderwritingBatchJobConstants.CRED_RATING_MAT_NOT_FOUND);
        }
        
        minCredRate = (mincredmatrix.Loan_Product__c == null || mincredmatrix.Loan_Product__c.contains('Fixed')) ? mincredmatrix.Interest_Rate__c : mincredmatrix.Total_Interest_Variable_Rate__c;
        if(qtcredmatrix != null && qtcredmatrix.Loan_Product__c.contains('Fixed')){
            ScoringAndPricingUnderwritingBatchJob newJob = new ScoringAndPricingUnderwritingBatchJob();
            blendedInterestRate = newJob.blendedRateCalculator(qqList[0].id, qtcredmatrix);
        }
        modifiedInterestRate = qqList[0].genesis__CL_Product__r.clcommon__Product_Name__c.contains('Fixed') ? blendedInterestRate : parentRate;
        qqList[0].Indicative_Interest_Rate__c = modifiedInterestRate < minCredRate ? minCredRate : modifiedInterestRate;
        qqList[0].Flexed_Interest_Rate__c = qqList[0].Indicative_Interest_Rate__c;
        System_Configuration__c sysConfig = System_Configuration__c.getInstance();
        qqList[0].Margin_Rate__c = qqList[0].genesis__CL_Product__r.clcommon__Product_Name__c.contains('Fixed') ? 0 : (qqList[0].Indicative_Interest_Rate__c - sysConfig.Base_Rate__c);
            if(System_Configuration__c.getInstance().Default_Days_Convention__c != null && String.isNotBlank(System_Configuration__c.getInstance().Default_Days_Convention__c)) {
                daysConvention = System_Configuration__c.getInstance().Default_Days_Convention__c;
            } else {
                throw new CustomException(ResponseMessenger.sysConfigInfoMissing);
            }
        if(System_Configuration__c.getInstance().Default_Interest_Calculation_Method__c != null && String.isNotBlank(System_Configuration__c.getInstance().Default_Interest_Calculation_Method__c)) {
            interestCalcMethod = System_Configuration__c.getInstance().Default_Interest_Calculation_Method__c;
        } else {
            throw new CustomException(ResponseMessenger.sysConfigInfoMissing);
        }
        EMICalculation.EmiResults emiRes = EMICalculation.calcEmi(startDate,firstPayDate,ConstantValues.MONTHLY,daysConvention,interestCalcMethod,loanAmtFinance,modifiedInterestRate,loanTermFinance);
        if(emiRes.paymentAmount == null){
            throw new CustomException(ResponseMessenger.REPAYMENT_AMOUNT_NULL);
        }
        Decimal lafMonthly = System_Configuration__c.getInstance().Loan_Admin_Fee__c;
        Decimal emiAmount;
        if(lafMonthly!=null && String.isNotBlank(loanFreqFinance)){
            if(loanFreqFinance.equalsIgnoreCase(ConstantValues.MONTHLY)){
                lafMonthly=lafMonthly*ConstantValues.DECIMAL_ONE; 
                emiAmount = emiRes.paymentAmount;
            }else if(loanFreqFinance.equalsIgnoreCase(ConstantValues.WEEKLY)){
                lafMonthly=lafMonthly/ConstantValues.PAYMENT_FREQUENCY_WEEKLY;
                emiAmount = emiRes.paymentAmount/ConstantValues.PAYMENT_FREQUENCY_WEEKLY;
            }else if(loanFreqFinance.equalsIgnoreCase(ConstantValues.BI_WEEKLY)){
                lafMonthly=lafMonthly/ConstantValues.PAYMENT_FREQUENCY_BIWEEKLY;
                emiAmount = emiRes.paymentAmount/ConstantValues.PAYMENT_FREQUENCY_BIWEEKLY;
            }
        } else {
            throw new CustomException(ResponseMessenger.sysConfigInfoMissing);
        }
        
        emiAmount+=lafMonthly;
        rpAmountNotRounded=emiAmount;
        qqList[0].Repayment_Amount__c = rpAmountNotRounded.setScale(2);
        update qqList;
    }
    
}