/*********************************************************************************************************
Class          : PricingManager
Description    : Utitlity class to generate pricing rates against ccrScore and loan Amount
Created Date   : 16/07/2018
Developer      : Kushal Basu
**********************************************************************************************************/

global inherited sharing class PricingManager {
    private static final String SCORE_OUT_OF_RANGE = 'Score out of Range - Score:-';
    private static final String SCORE_OUT_OF_RANGE = '';
    private static final String SCORE_OUT_OF_RANGE = '';
    private static final String SCORE_OUT_OF_RANGE = '';
    private static final String SCORE_OUT_OF_RANGE = '';
    private static final String SCORE_OUT_OF_RANGE = '';
    private static final String SCORE_OUT_OF_RANGE = '';
    private static final String SCORE_OUT_OF_RANGE = '';
    private static final String SCORE_OUT_OF_RANGE = '';

    global static boolean isStaffLoan = false;
    global static double staffLoanMinInt = System_Configuration__c.getInstance().Staff_Loan_Min_Interest__c;
    global static double staffLoanMaxInt = System_Configuration__c.getInstance().Staff_Loan_Max_Interest__c;
    global static Wrapper.PricingWrapper getIndicativePricing(double ccrScore,double loanAmount, String rate, String product){
        Wrapper.PricingWrapper pWrap = new Wrapper.PricingWrapper();
        if(ccrScore==null){
            ccrScore = 0;
        }
        pWrap.requestedLoanAmount = loanAmount;
        List<genesis__Credit_Rating_Matrix__c> genCrdMtrxList = [SELECT id,
                                                                 Name,
                                                                 Interest_Rate__c,
                                                                 LEF__c,
                                                                 Max_Score_Soft__c,
                                                                 Max_Loan_Amount__c,
                                                                 Min_Score_Soft__c,
                                                                 Broker_Max_Loan_Amount__c,
                                                                 Base_Rate__c,
                                                                 Margin_Rate__c,
                                                                 Total_Interest_Variable_Rate__c
                                                                 FROM genesis__Credit_Rating_Matrix__c
                                                                 WHERE Max_Score_Soft__c >=: ccrScore
                                                                 AND Min_Score_Soft__c <=: ccrScore
                                                                 AND Loan_Product__c INCLUDES (:product)];
        if(genCrdMtrxList.size()>0){
            
            genesis__Credit_Rating_Matrix__c genCrdMtrx = genCrdMtrxList.get(0);
            if(rate == 'Fixed'){
                pWrap.interestRate = genCrdMtrx.Interest_Rate__c;
            }else if (rate== 'Floating'){
                pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c;
                pWrap.marginRate = genCrdMtrx.Margin_Rate__c;
            }
            pWrap.genCreditRatingId = genCrdMtrx.id;
            pWrap.MaxLoanAmount = genCrdMtrx.Max_Loan_Amount__c;
            pWrap.brokerMaxLoanAmount = genCrdMtrx.Broker_Max_Loan_Amount__c;
            pWrap.tier = genCrdMtrx.Name;
            pWrap.loanEstablishmentFeePercent = genCrdMtrx.LEF__c;
            if(pWrap.requestedLoanAmount<=pWrap.MaxLoanAmount){
                pWrap.loanEstablishmentFeeAmount = pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                if(pWrap.loanEstablishmentFeeAmount > 1990) {
                    pWrap.loanEstablishmentFeeAmount = 1990;
                }
            }else{
                pWrap.loanEstablishmentFeeAmount = pWrap.MaxLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                if(pWrap.loanEstablishmentFeeAmount > 1990) {
                    pWrap.loanEstablishmentFeeAmount = 1990;
                }
            }
            if(pWrap.requestedLoanAmount<=pWrap.brokerMaxLoanAmount){
                pWrap.broker_loanEstFee = pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                if(pWrap.broker_loanEstFee > 1990) {
                    pWrap.broker_loanEstFee = 1990;
                }
            }else{
                pWrap.broker_loanEstFee = pWrap.brokerMaxLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                if(pWrap.broker_loanEstFee > 1990) {
                    pWrap.broker_loanEstFee = 1990;
                }
            }
            pWrap.status = 'Pricing generated';
            pWrap.statusCode = ConstantValues.statusOk;
        }else{
            pWrap.status = 'Score out of Range - Score:-'+ccrScore;
            pWrap.statusCode = ConstantValues.error;
        }
        //}
        return pWrap;
    }
    
    global static Wrapper.PricingWrapper getIndicativePricingV2(double ccrScore, double loanAmount, String rate, String product, String segment, String gecoGrade,String offercode){
        Wrapper.PricingWrapper pWrap = new Wrapper.PricingWrapper();
        List<genesis__Credit_Rating_Matrix__c> genCrdMtrxList = new List<genesis__Credit_Rating_Matrix__c>();
        List<Offer_Code_Action__mdt> OfferCodemdt = new List<Offer_Code_Action__mdt>();
        double minCredRate = 0.0;
        if(ccrScore==null){
            ccrScore = 0;
        }
        // if(product.contains('Auto')){
        //     product='Auto Loan';
        // } else {
        pWrap.requestedLoanAmount = loanAmount;
        if(String.isNotBlank(gecoGrade) && gecoGrade.equals(CpConstants.CR5)){
            genCrdMtrxList  = [SELECT id,
                               Name,
                               Interest_Rate__c,
                               LEF__c,
                               Max_Score_Soft__c,
                               Max_Loan_Amount__c,
                               Min_Score_Soft__c,
                               Broker_Max_Loan_Amount__c,
                               Base_Rate__c,
                               Margin_Rate__c,
                               Total_Interest_Variable_Rate__c,
                               Risk_Grade_Segment__c
                               FROM genesis__Credit_Rating_Matrix__c
                               WHERE Name =:CpConstants.TWELVE_THOUSAND_THREE_HUNDRED_STRING
                               AND Loan_Product__c INCLUDES (:product)
                               AND Risk_Grade_Segment__c INCLUDES (:segment)
                               AND Enabled__c = true
                               LIMIT 1];
            pWrap.riskGrade = CpConstants.TD;
        } else {
            genCrdMtrxList = [SELECT id,
                              Name,
                              Interest_Rate__c,
                              LEF__c,
                              Max_Score_Soft__c,
                              Max_Loan_Amount__c,
                              Min_Score_Soft__c,
                              Broker_Max_Loan_Amount__c,
                              Base_Rate__c,
                              Margin_Rate__c,
                              Total_Interest_Variable_Rate__c,
                              Risk_Grade_Segment__c
                              FROM genesis__Credit_Rating_Matrix__c
                              WHERE Max_Score_Soft__c >=: ccrScore
                              AND Min_Score_Soft__c <=: ccrScore
                              AND Loan_Product__c INCLUDES (:product)
                              AND Risk_Grade_Segment__c INCLUDES (:segment)
                              AND Enabled__c = true];
        }
        if(genCrdMtrxList.size()>0){
            
            genesis__Credit_Rating_Matrix__c genCrdMtrx = genCrdMtrxList.get(0);
            if(!String.isBlank(offercode) && offercode!=null){
                List<genesis__Credit_Rating_Matrix__c> minCredMatList = [ SELECT Id,
                                                                         Margin_Rate__c,
                                                                         Loan_Product__c,
                                                                         Interest_Rate__c,
                                                                         Total_Interest_Variable_Rate__c,
                                                                         LEF__c
                                                                         FROM genesis__Credit_Rating_Matrix__c 
                                                                         WHERE Name =: System.Label.min_credit_rating_tier
                                                                         AND (Loan_Product__c =:product  OR Loan_Product__c = '') AND Enabled__c = true
                                                                         LIMIT 1];
                if(minCredMatList.size()>0){
                    minCredRate = (minCredMatList[0].Loan_Product__c == null || minCredMatList[0].Loan_Product__c.contains('Fixed')) ? minCredMatList[0].Interest_Rate__c : minCredMatList[0].Total_Interest_Variable_Rate__c;
                }                                                            
                
                OfferCodemdt=[SELECT id, Label, Action_Type__c,Rate__c FROM Offer_Code_Action__mdt WHERE Offer_Code__r.Label =:offercode];
                
                if(OfferCodemdt.size()>0){
                    pWrap.loanEstablishmentFeePercent = genCrdMtrx.LEF__c == null ? 0 : genCrdMtrx.LEF__c;
                    pWrap.MaxLoanAmount = genCrdMtrx.Max_Loan_Amount__c == null ? 0 : genCrdMtrx.Max_Loan_Amount__c;
                    for(Offer_Code_Action__mdt actions : OfferCodemdt){
                        if(rate == CpConstants.FIXED_CONSTANT && actions.Action_Type__c==CpConstants.DISCOUNT){
                            if(isStaffLoan == true ){
                                if((genCrdMtrx.Interest_Rate__c-actions.Rate__c)>= staffLoanMinInt && (genCrdMtrx.Interest_Rate__c-actions.Rate__c)<=staffLoanMaxInt){
                                    pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : genCrdMtrx.Interest_Rate__c-actions.Rate__c;
                                    pwrap.DiscountRate=actions.Rate__c;
                                }else{
                                    if((genCrdMtrx.Interest_Rate__c-actions.Rate__c)<staffLoanMinInt){
                                        pWrap.interestRate=staffLoanMinInt;
                                        pwrap.DiscountRate=(staffLoanMinInt - genCrdMtrx.Interest_Rate__c) > 0 ? (staffLoanMinInt-genCrdMtrx.Interest_Rate__c) : (genCrdMtrx.Interest_Rate__c-staffLoanMinInt);
                                    }
                                    else{
                                        pWrap.interestRate=staffLoanMaxInt;
                                        pwrap.DiscountRate=(staffLoanMaxInt - genCrdMtrx.Interest_Rate__c) > 0 ? (staffLoanMaxInt - genCrdMtrx.Interest_Rate__c) : (genCrdMtrx.Interest_Rate__c-staffLoanMaxInt);
                                    }

                                }
                            }
                            else{
                                if((genCrdMtrx.Interest_Rate__c-actions.Rate__c)>minCredRate){
                                    pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : genCrdMtrx.Interest_Rate__c-actions.Rate__c;
                                    pwrap.DiscountRate=actions.Rate__c;
                                }else{
                                    pWrap.interestRate=minCredRate;
                                    pwrap.DiscountRate=(minCredRate-genCrdMtrx.Interest_Rate__c) > 0 ? (minCredRate-genCrdMtrx.Interest_Rate__c) : (genCrdMtrx.Interest_Rate__c-minCredRate);
                                        }
                            }
                        }else if(rate == CpConstants.FIXED_CONSTANT && actions.Action_Type__c==CpConstants.SPECIAL_RATE){
                            if(isStaffLoan == true ){
                                if(actions.Rate__c>=staffLoanMinInt && actions.Rate__c<=staffLoanMaxInt){
                                    pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : actions.Rate__c;
                                    pwrap.DiscountRate= genCrdMtrx.Interest_Rate__c > actions.Rate__c ? (genCrdMtrx.Interest_Rate__c - actions.Rate__c) : (actions.Rate__c - genCrdMtrx.Interest_Rate__c);
                                }else{
                                    if(actions.Rate__c<staffLoanMinInt){
                                        pWrap.interestRate=staffLoanMinInt;
                                        pwrap.DiscountRate=(staffLoanMinInt-genCrdMtrx.Interest_Rate__c) > 0 ? (staffLoanMinInt-genCrdMtrx.Interest_Rate__c) : (genCrdMtrx.Interest_Rate__c-staffLoanMinInt);
                                    }
                                    else{
                                        pWrap.interestRate=staffLoanMaxInt;
                                        pwrap.DiscountRate=(staffLoanMaxInt-genCrdMtrx.Interest_Rate__c) > 0 ? (staffLoanMaxInt-genCrdMtrx.Interest_Rate__c) : (genCrdMtrx.Interest_Rate__c-staffLoanMaxInt);
                                    }
                                }
                            }
                            else{
                                if(actions.Rate__c>minCredRate){
                                    pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : actions.Rate__c;
                                    pwrap.DiscountRate= genCrdMtrx.Interest_Rate__c > actions.Rate__c ? (genCrdMtrx.Interest_Rate__c - actions.Rate__c) : (actions.Rate__c - genCrdMtrx.Interest_Rate__c);
                                }else{
                                    pWrap.interestRate = minCredRate == null ? 0 : minCredRate;
                                    pwrap.DiscountRate= (minCredRate-genCrdMtrx.Interest_Rate__c) >0 ? (minCredRate-genCrdMtrx.Interest_Rate__c) : (genCrdMtrx.Interest_Rate__c-minCredRate);
                                        }
                            }
                        }else if(rate == CpConstants.FLOATING_CONSTANT && actions.Action_Type__c==CpConstants.DISCOUNT){
                            if(isStaffLoan == true){
                                if((genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c)>=staffLoanMinInt && (genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c)<=staffLoanMaxInt){
                                    pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c;
                                    pwrap.DiscountRate= genCrdMtrx.Interest_Rate__c > actions.Rate__c ? (genCrdMtrx.Interest_Rate__c - actions.Rate__c) : (actions.Rate__c - genCrdMtrx.Interest_Rate__c);
                                }else{
                                    if((genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c)<staffLoanMinInt){
                                        pWrap.interestRate= staffLoanMinInt;
                                        pwrap.DiscountRate=(staffLoanMinInt-genCrdMtrx.Total_Interest_Variable_Rate__c) > 0 ? (staffLoanMinInt-genCrdMtrx.Total_Interest_Variable_Rate__c) : (genCrdMtrx.Total_Interest_Variable_Rate__c-staffLoanMinInt);
                                        pWrap.marginRate=genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c-pwrap.DiscountRate;
                                    }
                                    else{
                                        pWrap.interestRate= staffLoanMaxInt;
                                        pwrap.DiscountRate=(staffLoanMaxInt-genCrdMtrx.Total_Interest_Variable_Rate__c) > 0 ? (staffLoanMaxInt-genCrdMtrx.Total_Interest_Variable_Rate__c) : (genCrdMtrx.Total_Interest_Variable_Rate__c-staffLoanMaxInt);
                                        pWrap.marginRate=genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c-pwrap.DiscountRate;
                                    }
                                }
                            }
                            else{
                                if((genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c)>minCredRate){
                                    pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c;
                                    pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c-actions.Rate__c;
                                    pwrap.DiscountRate=actions.Rate__c;    
                                }else{
                                    pWrap.interestRate= minCredRate;
                                    pwrap.DiscountRate=(minCredRate-genCrdMtrx.Total_Interest_Variable_Rate__c) > 0 ? (minCredRate-genCrdMtrx.Total_Interest_Variable_Rate__c) : (genCrdMtrx.Total_Interest_Variable_Rate__c-minCredRate);
                                        pWrap.marginRate=genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c-pwrap.DiscountRate;
                                }
                            }
                        }else if(rate== CpConstants.FLOATING_CONSTANT && actions.Action_Type__c==CpConstants.SPECIAL_RATE){
                            if(isStaffLoan == true){
                                if(actions.Rate__c>=staffLoanMinInt && actions.Rate__c<=staffLoanMaxInt){
                                    pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : actions.Rate__c;
                                    pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : actions.Rate__c-System_Configuration__c.getInstance().Base_Rate__c;
                                    pwrap.DiscountRate= genCrdMtrx.Total_Interest_Variable_Rate__c > actions.Rate__c ? (genCrdMtrx.Total_Interest_Variable_Rate__c - actions.Rate__c) : (actions.Rate__c - genCrdMtrx.Total_Interest_Variable_Rate__c);  
                                }else{
                                    if(actions.Rate__c<staffLoanMinInt){
                                        pWrap.interestRate = staffLoanMinInt;
                                        pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : staffLoanMinInt-System_Configuration__c.getInstance().Base_Rate__c;
                                        pwrap.DiscountRate= (genCrdMtrx.Total_Interest_Variable_Rate__c - staffLoanMinInt) > 0 ? (genCrdMtrx.Total_Interest_Variable_Rate__c - staffLoanMinInt) : (staffLoanMinInt - genCrdMtrx.Total_Interest_Variable_Rate__c);
                                    }
                                    else{
                                        pWrap.interestRate = staffLoanMaxInt;
                                        pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : staffLoanMaxInt-System_Configuration__c.getInstance().Base_Rate__c;
                                        pwrap.DiscountRate= (genCrdMtrx.Total_Interest_Variable_Rate__c - staffLoanMaxInt) > 0 ? (genCrdMtrx.Total_Interest_Variable_Rate__c - staffLoanMaxInt) : (staffLoanMaxInt - genCrdMtrx.Total_Interest_Variable_Rate__c);
                                    }
                                }
                            }
                            else{
                                if(actions.Rate__c>minCredRate){
                                    pWrap.interestRate = actions.Rate__c == null ? 0 : actions.Rate__c;
                                    pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : actions.Rate__c-System_Configuration__c.getInstance().Base_Rate__c;
                                    pwrap.DiscountRate= genCrdMtrx.Total_Interest_Variable_Rate__c > actions.Rate__c ? (genCrdMtrx.Total_Interest_Variable_Rate__c - actions.Rate__c) : (actions.Rate__c - genCrdMtrx.Total_Interest_Variable_Rate__c);  
                                }else{
                                    pWrap.interestRate = minCredRate == null ? 0 : minCredRate;
                                    pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : minCredRate-System_Configuration__c.getInstance().Base_Rate__c;
                                    pwrap.DiscountRate= (genCrdMtrx.Total_Interest_Variable_Rate__c - minCredRate) > 0 ? (genCrdMtrx.Total_Interest_Variable_Rate__c - minCredRate) : (minCredRate - genCrdMtrx.Total_Interest_Variable_Rate__c);
                                }
                            }
                        }else if(actions.Action_Type__c==CpConstants.LEF_WAIVER){
                            pWrap.loanEstablishmentFeePercent=0;
                            Decimal interestRate= (rate == CpConstants.FIXED_CONSTANT)? genCrdMtrx.Interest_Rate__c: genCrdMtrx.Total_Interest_Variable_Rate__c;
                            if(isStaffLoan == true){
                              if(interestRate>=staffLoanMinInt && interestRate<=staffLoanMaxInt)
                              {
                                    pWrap.loanEstablishmentFeeAmount = 0;
                                    pWrap.interestRate = interestRate;
                                    pWrap.marginRate=(rate == CpConstants.FIXED_CONSTANT) ? 0 : interestRate-System_Configuration__c.getInstance().Base_Rate__c;
                                    pWrap.lefDiscount=pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                              }
                              else{
                                    pWrap.loanEstablishmentFeeAmount = 0;
                                    pWrap.interestRate = interestRate<staffLoanMinInt?staffLoanMinInt:staffLoanMaxInt;
                                    pWrap.marginRate=(rate == CpConstants.FIXED_CONSTANT) ? 0 : (interestRate<staffLoanMinInt?staffLoanMinInt:staffLoanMaxInt)-System_Configuration__c.getInstance().Base_Rate__c;
                                    pWrap.lefDiscount=pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                              }
                            }
                            else{
                                pWrap.loanEstablishmentFeeAmount = 0;
                                pWrap.interestRate = interestRate;
                                pWrap.lefDiscount=pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                            }  
                        }
                    }
                }   
                
            }else{
                if(rate == CpConstants.FIXED_CONSTANT){
                    if(isStaffLoan == true){
                        if(genCrdMtrx.Interest_Rate__c <= staffLoanMaxInt && genCrdMtrx.Interest_Rate__c>=staffLoanMinInt){
                            pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : genCrdMtrx.Interest_Rate__c;
                        }
                        else{
                            if(genCrdMtrx.Interest_Rate__c<staffLoanMinInt){
                                pWrap.interestRate = staffLoanMinInt; 
                            }
                            else{
                                pWrap.interestRate = staffLoanMaxInt;
                            }
                        }
                    }
                    else{
                        pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : genCrdMtrx.Interest_Rate__c;
                    }
                }else if (rate== CpConstants.FLOATING_CONSTANT){
                    if(isStaffLoan == true){ 
                        if(genCrdMtrx.Total_Interest_Variable_Rate__c  >= staffLoanMinInt && genCrdMtrx.Total_Interest_Variable_Rate__c <=staffLoanMaxInt){
                            pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : genCrdMtrx.Total_Interest_Variable_Rate__c;
                            pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c;
                        }
                        else{
                            if(genCrdMtrx.Total_Interest_Variable_Rate__c  < staffLoanMinInt){
                                pWrap.interestRate = staffLoanMinInt;
                                pWrap.marginRate = staffLoanMinInt - System_Configuration__c.getInstance().Base_Rate__c;
                            }
                            else{
                                pWrap.interestRate = staffLoanMaxInt;
                                pWrap.marginRate = staffLoanMaxInt - System_Configuration__c.getInstance().Base_Rate__c;
                            }
                        }
                    }
                    else{
                        pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : genCrdMtrx.Total_Interest_Variable_Rate__c;
                        pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c;
                    }
                }
                if(isStaffLoan == true){
                    pWrap.loanEstablishmentFeePercent = 0;
                    pWrap.loanEstablishmentFeeAmount = 0;
                }
                else{
                    pWrap.loanEstablishmentFeePercent = genCrdMtrx.LEF__c == null ? 0 : genCrdMtrx.LEF__c;
                    pWrap.MaxLoanAmount = genCrdMtrx.Max_Loan_Amount__c == null ? 0 : genCrdMtrx.Max_Loan_Amount__c;
                    if(pWrap.requestedLoanAmount<=pWrap.MaxLoanAmount){
                        pWrap.loanEstablishmentFeeAmount = pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                        if(pWrap.loanEstablishmentFeeAmount > 1990) {
                            pWrap.loanEstablishmentFeeAmount = 1990;
                        }
                    }else{
                        pWrap.loanEstablishmentFeeAmount = pWrap.MaxLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                        if(pWrap.loanEstablishmentFeeAmount > 1990) {
                            pWrap.loanEstablishmentFeeAmount = 1990;
                        }
                    } 
                }
            }
            pWrap.genCreditRatingId = genCrdMtrx.id;
            pWrap.tier = genCrdMtrx.Name;
            pWrap.brokerMaxLoanAmount = genCrdMtrx.Broker_Max_Loan_Amount__c == null ? 0 : genCrdMtrx.Broker_Max_Loan_Amount__c;
            if(pWrap.requestedLoanAmount<=pWrap.brokerMaxLoanAmount){
                pWrap.broker_loanEstFee = pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                if(pWrap.broker_loanEstFee > 1990) {
                    pWrap.broker_loanEstFee = 1990;
                }
            }else{
                pWrap.broker_loanEstFee = pWrap.brokerMaxLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                if(pWrap.broker_loanEstFee > 1990) {
                    pWrap.broker_loanEstFee = 1990;
                }
            }
            pWrap.status = CpConstants.PRICING_GENERATED;
            pWrap.statusCode = ConstantValues.statusOk;
        }else{
            pWrap.status = CpConstants.SCORE_OUT_OF_RANGE+ccrScore;
            pWrap.statusCode = ConstantValues.error;
        }
        return pWrap;
    }
    
    /*public static Wrapper.PricingWrapper getAutoPricing( genesis__Quick_Quotes__c qObj){
Wrapper.PricingWrapper pWrap = new Wrapper.PricingWrapper();
try{
pWrap.requestedLoanAmount = qObj.Loan_Amount_Requested__c;
Double totalScore = qObj.Final_Score__c;
if( totalScore == null ){
throw new CustomException('Total score is null');
}
List<genesis__Credit_Rating_Matrix__c> genCrdMtrxList = [SELECT id,
Name,
Interest_Rate__c,
LEF__c,
Max_Score_Soft__c,
Max_Loan_Amount__c,
Loan_Product__c,
Min_Score_Soft__c,
Broker_Max_Loan_Amount__c,
Base_Rate__c,
Gemstone__c,
Broker_Initiated__c
FROM genesis__Credit_Rating_Matrix__c
WHERE Max_Score_Soft__c >=: totalScore
AND Min_Score_Soft__c <=: totalScore
AND Broker_Initiated__c = :qObj.Broker_Initiated__c
AND Loan_Product__c INCLUDES ('Motor Loan')];

System.debug('genCrdMtrxList===>'+genCrdMtrxList);
System.debug('totalScore===>'+totalScore);
System.debug('qObj.Broker_Initiated__c===>'+qObj.Broker_Initiated__c);
if(genCrdMtrxList.size()>0){
qObj.Credit_Rating_Matrix__c = genCrdMtrxList[0].Id;
update qObj;
String rateCardName ;
if( genCrdMtrxList[0].Broker_Initiated__c ){
if ( qobj.Recreational_Vehicles__c ){
rateCardName = 'Broker Recreational QQ Rate';
} else {
rateCardName = 'Broker Non-Recreational QQ Rate';
}
} else {
rateCardName = 'Auto Loan Online QQ Rate';
}
genesis__Rate_Card_Setup_Header__c rateCard = [ SELECT Id,
Name,
(SELECT Id,
Loan_Establishment_Fee_Amount__c, 
Loan_Establishment_Fee__c, 
genesis__Interest_Rate__c,
genesis__Credit_Rating__c,
genesis__Determining_Factor_Key_Value__c,
genesis__Use_Additional_Determining_Factors__c
FROM genesis__Rate_Card_Setup_Details__r 
WHERE genesis__Credit_Rating__c = :genCrdMtrxList[0].Id) ,
(SELECT Id,
genesis__Applicable_for_Quick_Quote__c, 
genesis__Evaluation_Operator__c, 
genesis__Quick_Quote_Field_Type__c,
genesis__Quick_Quote_Field_API_Name__c, 
genesis__Quick_Quote_Object_API_Name__c,
genesis__Required_for_Evaluation__c
FROM genesis__Additional_Determining_Factor__r 
WHERE genesis__Quick_Quote_Object_API_Name__c = 'genesis__Quick_Quotes__c' 
AND genesis__Applicable_for_Quick_Quote__c = TRUE )
FROM genesis__Rate_Card_Setup_Header__c
WHERE Name = :rateCardName 
LIMIT 1];
Map<String,List<String>> mapFact = new Map<String,List<String>>();
if( rateCard == null ){
throw new CustomException('Rate Card Not Found !!');
}
genesis__Rate_Card_Setup_Detail__c selectedDetail;
if( rateCardName != 'Auto Loan Online QQ Rate' ){
Set<String> fields = new Set<String>();
Map<String,Object> detFactors = new Map<String,Object>();
for(genesis__Additional_Determining_Factor__c detfact : rateCard.genesis__Additional_Determining_Factor__r){
detFactors.put(detfact.Id,detfact);
fields.add(detfact.genesis__Quick_Quote_Field_API_Name__c);
}
List<String> fieldSet=new List<String>();
fieldSet.addAll(fields);
String fieldStr=String.join(fieldSet,',');
Id qqId = qObj.Id;
String quer = 'SELECT Id,fields,Credit_Rating_Matrix__c,Indicative_Interest_Rate__c,Loan_Establishment_Fee_Percent__c,Loan_Establishment_Fee__c,Repayment_Amount__c from genesis__Quick_Quotes__c WHERE id=:qqId';
quer = quer.replace('fields',fieldStr);
try{
qObj=Database.query(quer);
} catch(Exception e){
throw new CustomException('query invalid : '+quer);
}
for(genesis__Rate_Card_Setup_Detail__c detail : rateCard.genesis__Rate_Card_Setup_Details__r){
List<String> listFactors = new List<String>();
if( !detail.genesis__Use_Additional_Determining_Factors__c ){
throw new CustomException('No determing factors found for Broker!!');
} 
listFactors = (detail.genesis__Determining_Factor_Key_Value__c).split(':|\\#');
if( math.mod(listFactors.size(),2) !=0 ){
throw new CustomException('Determining factors parsed wrong');
}
Boolean factCheck = true;
for(Integer index=0;index<listFactors.size();index+=2){
String key = listFactors[index];
String val = listFactors[index+1];
genesis__Additional_Determining_Factor__c detFactor = (genesis__Additional_Determining_Factor__c)detFactors.get(key);
factCheck = Test.isRunningTest()?true: factCheck && checkDetermingFactor(detFactor,val,qObj);
}
if( factCheck ){
selectedDetail = detail;
break;
}
}
} else {
if((rateCard.genesis__Rate_Card_Setup_Details__r).size()!=0){
selectedDetail = rateCard.genesis__Rate_Card_Setup_Details__r[0];
} else {
throw new CustomException('No rate card Detail for the given cred matrix'+genCrdMtrxList[0].Name);
}
}
if(selectedDetail == null){
pWrap.status = 'No details selected for - Score:-'+totalScore+'and matrix : '+genCrdMtrxList[0].Name;
pWrap.statusCode = ConstantValues.error;
return pWrap;
}
pWrap.MaxLoanAmount = 1000000.00;
pWrap.interestRate = selectedDetail.genesis__Interest_Rate__c;
pWrap.genCreditRatingId = genCrdMtrxList[0].Id;
pWrap.loanEstablishmentFeePercent = selectedDetail.Loan_Establishment_Fee__c;
if(pWrap.loanEstablishmentFeePercent != null && pWrap.loanEstablishmentFeePercent != 0 ){
pWrap.loanEstablishmentFeeAmount = pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
}else{
if(pWrap.loanEstablishmentFeeAmount == null || pWrap.loanEstablishmentFeeAmount == 0){
throw new CustomException('Neither of LEF Percent or LEF Amt is assigned');
}
pWrap.loanEstablishmentFeePercent = 0;
pWrap.loanEstablishmentFeeAmount = selectedDetail.Loan_Establishment_Fee_Amount__c;
}
pWrap.status = 'Pricing generated';
pWrap.statusCode = ConstantValues.statusOk;
} else {
pWrap.status = 'Score out of Range - Score:-'+totalScore;
pWrap.statusCode = ConstantValues.error;
}
} catch(Exception e){
ExceptionManager.manageException(e);
insert ExceptionManager.getClCommonLog(e, ConversionConstant.genesis);
if( e.getTypeName() == 'CustomException' ){
throw new CustomException(e.getLineNumber()+' : '+e.getMessage());
} else {
throw new CustomException('Something went wrong : '+e.getLineNumber()+'-'+e.getMessage());
}
}
return pWrap;
//System.debug('Gen Credit Rating Matrix=>'+genCrdMtrxList);
}*/
    public static Boolean checkDetermingFactor(genesis__Additional_Determining_Factor__c detFactor, String matchingValue, genesis__Quick_Quotes__c qqData){
        Boolean result;
        String fieldType = (detFactor.genesis__Quick_Quote_Field_Type__c).trim();
        String fieldAPIName = (detFactor.genesis__Quick_Quote_Field_API_Name__c).trim();
        String matchingType = (detFactor.genesis__Evaluation_Operator__c).trim();
        System.debug('Field Type : '+fieldType);
        if(fieldType.equalsIgnoreCase('DOUBLE') || fieldType.equalsIgnoreCase('CURRENCY') || fieldType.equalsIgnoreCase('PERCENT')){
            Decimal fieldValue;
            if(qqData.get(fieldAPIName) != null){
                fieldValue = (Decimal)qqData.get(fieldAPIName);
            }
            System.debug(fieldAPIName+' : '+fieldValue);
            if(matchingType.equals('<')){
                result = (fieldValue < Decimal.valueOf(matchingValue)) ? true : false;
            }else if(matchingType.equals('>')){
                result = (fieldValue > Decimal.valueOf(matchingValue)) ? true : false;
            }else if(matchingType.equals('<=')){
                result = (fieldValue <= Decimal.valueOf(matchingValue)) ? true : false;
            }else if(matchingType.equals('>=')){
                result = (fieldValue >= Decimal.valueOf(matchingValue)) ? true : false;
            }else if(matchingType.equals('==') && matchingValue != null){
                result = (fieldValue == Decimal.valueOf(matchingValue)) ? true : false;
            }else if(matchingType.equals('!=') && matchingValue != null){
                result = (fieldValue != Decimal.valueOf(matchingValue)) ? true : false;
            }else if(matchingType.equals('==') && matchingValue == null){
                result = (fieldValue == null) ? true : false;
            }else if(matchingType.equals('!=') && matchingValue == null){
                result = (fieldValue != null) ? true : false;
            }
        }else if(fieldType.equalsIgnoreCase('PICKLIST') || fieldType.equalsIgnoreCase('ENCRYPTEDSTRING') 
                 || fieldType.equalsIgnoreCase('STRING') || fieldType.equalsIgnoreCase('EMAIL')
                 || fieldType.equalsIgnoreCase('PHONE') || fieldType.equalsIgnoreCase('TEXTAREA')
                 || fieldType.equalsIgnoreCase('URL') || fieldType.equalsIgnoreCase('ID')){
                     String fieldValue = '';
                     if(qqData.get(fieldAPIName) != null){
                         fieldValue = (String)qqData.get(fieldAPIName);
                     }
                     System.debug(fieldAPIName+' : '+fieldValue);
                     if(matchingType.equals('==')){
                         result = (fieldValue.equals(matchingValue)) ? true : false;
                     }else if(matchingType.equals('!=')){
                         result = (fieldValue.equals(matchingValue)) ? false : true;
                     }else if(matchingType.equals('CONTAINS')){
                         result = (fieldValue.containsIgnoreCase(matchingValue)) ? true : false;
                     }else if(matchingType.equals('DOES NOT CONTAIN')){
                         result = (fieldValue.containsIgnoreCase(matchingValue)) ? false : true;
                     }else if(matchingType.equals('IN')){
                         result = (matchingValue.containsIgnoreCase(fieldValue)) ? true : false;
                     }else if(matchingType.equals('NOT IN')){
                         result = (matchingValue.containsIgnoreCase(fieldValue)) ? false : true;
                     }else if(matchingType.equals('STARTS WITH')){
                         result = (fieldValue.startsWithIgnoreCase(matchingValue)) ? true : false;
                     }else if(matchingType.equals('ENDS WITH')){
                         result = (fieldValue.endsWithIgnoreCase(matchingValue)) ? true : false;
                     }
                 }else if(fieldType.equalsIgnoreCase('BOOLEAN')){
                     Boolean fieldValue;
                     if(qqData.get(fieldAPIName) != null){
                         fieldValue = (Boolean)qqData.get(fieldAPIName);
                     }
                     System.debug(fieldAPIName+' : '+fieldValue);
                     if(matchingType.equals('==') && matchingValue != null){
                         result = (fieldValue == Boolean.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('!=') && matchingValue != null){
                         result = (fieldValue != Boolean.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('==') && matchingValue == null){
                         result = (fieldValue == null) ? true : false;
                     }else if(matchingType.equals('!=') && matchingValue == null){
                         result = (fieldValue != null) ? true : false;
                     }
                 }else if(fieldType.equalsIgnoreCase('DATE')){
                     Date fieldValue;
                     if(qqData.get(fieldAPIName) != null){
                         fieldValue = (Date)qqData.get(fieldAPIName);
                     }
                     System.debug(fieldAPIName+' : '+fieldValue);
                     if(matchingType.equals('<')){
                         result = (fieldValue < Date.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('>')){
                         result = (fieldValue > Date.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('<=')){
                         result = (fieldValue <= Date.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('>=')){
                         result = (fieldValue >= Date.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('==') && matchingValue != null){
                         result = (fieldValue == Date.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('!=') && matchingValue != null){
                         result = (fieldValue != Date.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('==') && matchingValue == null){
                         result = (fieldValue == null) ? true : false;
                     }else if(matchingType.equals('!=') && matchingValue == null){
                         result = (fieldValue != null) ? true : false;
                     }
                 }else if(fieldType.equalsIgnoreCase('DATETIME')){
                     Datetime fieldValue;
                     if(qqData.get(fieldAPIName) != null){
                         fieldValue = (Datetime)qqData.get(fieldAPIName);
                     }
                     System.debug(fieldAPIName+' : '+fieldValue);
                     if(matchingType.equals('<')){
                         result = (fieldValue < Datetime.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('>')){
                         result = (fieldValue > Datetime.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('<=')){
                         result = (fieldValue <= Datetime.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('>=')){
                         result = (fieldValue >= Datetime.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('==') && matchingValue != null){
                         result = (fieldValue == Datetime.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('!=') && matchingValue != null){
                         result = (fieldValue != Datetime.valueOf(matchingValue)) ? true : false;
                     }else if(matchingType.equals('==') && matchingValue == null){
                         result = (fieldValue == null) ? true : false;
                     }else if(matchingType.equals('!=') && matchingValue == null){
                         result = (fieldValue != null) ? true : false;
                     }
                 }
        return result;
    }
    @InvocableMethod
    public static void setCreditRatingOnApp(List<Id> appIdList){
        List<genesis__Applications__c> appList = [SELECT id, 
                                                  Final_Application_Score__c 
                                                  FROM genesis__Applications__c 
                                                  WHERE id in: appIdList];
        List<genesis__Applications__c> appUpdateList = new List<genesis__Applications__c>();
        for(genesis__Applications__c app : appList){
            if(app.Final_Application_Score__c!=null){
                app.genesis__Credit_Rating__c = getCreditRatingMatrixForScore(app.Final_Application_Score__c);
                appUpdateList.add(app);
            }
        }
        try{
            if(Schema.sObjectType.genesis__Applications__c.isUpdateable()){
               update appUpdateList;
            }else {
                throw new CustomException(CpConstants.DML_ACCESS_ERROR);
            }
        }catch(Exception ex){
            ExceptionManager.manageException(ex);
            insert ExceptionManager.getClCommonLog(ex,'setCreditRatingOnApp');
        }
    }
    
    global static id getCreditRatingMatrixForScore(Decimal score){
        List<genesis__Credit_Rating_Matrix__c> credList = [SELECT id,
                                                           Max_Score__c,
                                                           Min_Score__c
                                                           FROM genesis__Credit_Rating_Matrix__c
                                                           WHERE Max_Score__c>=:score 
                                                           AND Min_Score__c<=:score
                                                           LIMIT 1];
        if(credList.size()>0){
            id crdId = credList.get(0).id;
            //System.debug('Credit Rating Matrix ==>> '+crdId);
            return crdId;
        }else{
            return null;
        }
    }
    
    public static id setCreditRatingOnAppV2(genesis__Applications__c app){
        id creditRatingMatId;
        try{
            clcommon__CL_Product__c productName =[SELECT id, 
                                                  clcommon__Product_Name__c 
                                                  FROM clcommon__CL_Product__c 
                                                  WHERE id=:app.genesis__CL_Product__c 
                                                  LIMIT 1];
            if(app.Risk_Score__c!=null && app.Risk_Grade_Segment__c != null && productName.clcommon__Product_Name__c != null){
                creditRatingMatId = getCreditRatingMatrixForScoreV2(app.Risk_Score__c, app.Risk_Grade_Segment__c, productName.clcommon__Product_Name__c);
            } else {
                throw new CustomException('Risk Score or segment or product not defined in Application');
            }
        }catch(Exception ex){
            ExceptionManager.manageException(ex);
            insert ExceptionManager.getClCommonLog(ex,'setCreditRatingOnAppV2');
        }
        return creditRatingMatId;
    }
    
    global static id getCreditRatingMatrixForScoreV2(Decimal score, String segment, String loanProductName){
        List<genesis__Credit_Rating_Matrix__c> credList = [SELECT id,
                                                           Max_Score__c,
                                                           Min_Score__c,
                                                           Risk_Grade_Segment__c
                                                           FROM genesis__Credit_Rating_Matrix__c
                                                           WHERE Max_Score__c>=:score 
                                                           AND Min_Score__c<=:score
                                                           AND Risk_Grade_Segment__c INCLUDES (:segment)
                                                           AND Loan_Product__c INCLUDES (:loanProductName)
                                                           AND Enabled__c = true
                                                           LIMIT 1];
        if(credList.size()>0){
            id crdId = credList.get(0).id;
            //System.debug('Credit Rating Matrix ==>> '+crdId);
            return crdId;
        }else{
            return null;
        }
    }
    
    global static String getRateEstimate(id qqId){
        Boolean isMotor;
        List<genesis__Quick_Quotes__c> qqList;
        genesis__Quick_Quotes__c qqObj;
        Wrapper.PricingWrapper pWrap;
        qqList = [SELECT id, 
                  Loan_Amount_Requested__c,
                  genesis__Financed_Amount__c,
                  Interest_Type__c,
                  CCR_Score__c,
                  genesis__CL_Product__r.clcommon__Product_Name__c,
                  Margin_Rate__c,
                  Credit_Rating_Matrix__c,
                  Indicative_Interest_Rate__c,
                  Max_Loan_Amount__c,
                  Loan_Establishment_Fee_Percent__c,
                  genesis__Expected_Start_Date__c,
                  Loan_Establishment_Fee__c,
                  genesis__Status__c,
                  Failed_Reason__c,
                  Final_Score__c,
                  Risk_Score__c,
                  GECO_Grade__c,
                  Risk_Grade_Calculated__c,
                  Broker_Initiated__c,
                  Recreational_Vehicles__c,
                  IB_Relationship__c,
                  Monthly_Fee__c,
                  Quote_New_to_Bureau__c,
                  Sales_Channel__c,
                  offerCode__c,
                  Discount_Rate__c,
                  LEF_discount__c,
                  Staff_Loan__c,
                  CreatedDate
                  FROM genesis__Quick_Quotes__c
                  WHERE id =: qqId
                  LIMIT 1];
        if(!qqList.isEmpty()){
            qqObj = qqList[0];
        }
        isStaffLoan = qqObj.Staff_Loan__c;
        //generating the pricing wrapper based on the credit score of the Quick Quote
        if( qqObj.genesis__CL_Product__r.clcommon__Product_Name__c.contains(CpConstants.MOTOR) ){
            // pWrap = getAutoPricing(qqObj);
            // Commented above line and added Line 561-573
            isMotor = true;
            if(qqObj.Quote_New_to_Bureau__c){
                pWrap = PricingManager.getIndicativePricingForStranger( Double.valueOf(qqObj.Loan_Amount_Requested__c), 
                                                                       qqObj.Interest_Type__c, 
                                                                       qqObj.genesis__CL_Product__r.clcommon__Product_Name__c,
                                                                       qqObj.IB_Relationship__c,
                                                                       qqObj.GECO_Grade__c,qqObj.offerCode__c);
            }else{
                pWrap = PricingManager.getIndicativePricingV2(Double.valueOf(qqObj.Risk_Score__c), 
                                                              Double.valueOf(qqObj.Loan_Amount_Requested__c), 
                                                              qqObj.Interest_Type__c, 
                                                              qqObj.genesis__CL_Product__r.clcommon__Product_Name__c,
                                                              qqObj.IB_Relationship__c,
                                                              qqObj.GECO_Grade__c,qqObj.offerCode__c);
            }
        } else {
            /*
pWrap = PricingManager.getIndicativePricing(Double.valueOf(qqObj.Final_Score__c), 
Double.valueOf(qqObj.Loan_Amount_Requested__c), 
qqObj.Interest_Type__c, 
qqObj.genesis__CL_Product__r.clcommon__Product_Name__c);
*/
            isMotor = false;
            //This change was made on 20/07/2022 , so that a new pricing is assigned to new to bureau customers
            if(qqObj.Quote_New_to_Bureau__c){
                pWrap = PricingManager.getIndicativePricingForStranger( Double.valueOf(qqObj.Loan_Amount_Requested__c), 
                                                                       qqObj.Interest_Type__c, 
                                                                       qqObj.genesis__CL_Product__r.clcommon__Product_Name__c,
                                                                       qqObj.IB_Relationship__c,
                                                                       qqObj.GECO_Grade__c,qqObj.offerCode__c);
            }else{
                pWrap = PricingManager.getIndicativePricingV2(Double.valueOf(qqObj.Risk_Score__c), 
                                                              Double.valueOf(qqObj.Loan_Amount_Requested__c), 
                                                              qqObj.Interest_Type__c, 
                                                              qqObj.genesis__CL_Product__r.clcommon__Product_Name__c,
                                                              qqObj.IB_Relationship__c,
                                                              qqObj.GECO_Grade__c,qqObj.offerCode__c);
            }
        }
        // if(!Schema.sObjectType.genesis__Quick_Quotes__c.isUpdateable()){
        //      throw new CustomException(CpConstants.DML_ACCESS_ERROR);
        // }
        if(pWrap.status != CpConstants.SCORE_OUT_OF_RANGES && pWrap.interestRate != null && 
           pWrap.interestRate != 0.0 && pWrap.loanEstablishmentFeeAmount != null &&
           pWrap.loanEstablishmentFeePercent!= null){
               qqObj.genesis__Financed_Amount__c = Double.valueOf(qqObj.Loan_Amount_Requested__c) > pWrap.MaxLoanAmount ? pWrap.MaxLoanAmount : qqObj.Loan_Amount_Requested__c;
               qqObj.Credit_Rating_Matrix__c = pWrap.genCreditRatingId;
               qqObj.Indicative_Interest_Rate__c = pWrap.interestRate;
               if(pWrap.marginRate != null){
                   qqObj.Margin_Rate__c = pWrap.marginRate;
               }else{
                   qqObj.Margin_Rate__c = null;
               }
               qqObj.Max_Loan_Amount__c = pWrap.MaxLoanAmount;
               qqObj.Loan_Establishment_Fee_Percent__c = pWrap.loanEstablishmentFeePercent;
               qqObj.genesis__Expected_Start_Date__c = FlowfiUtil.currentSystemDate;
               qqObj.LEF_discount__c=pWrap.lefDiscount;
               qqObj.Discount_Rate__c=pwrap.DiscountRate;
               if(qqObj.Staff_Loan__c==false){
                   qqObj.Loan_Establishment_Fee__c = isMotor 
                                                        ? (qqObj.CreatedDate>=System_Configuration__c.getInstance().ML_Campaign_Start_Date__c 
                                                        && qqObj.CreatedDate<=System_Configuration__c.getInstance().ML_Campaign_End_Date__c)? 0: System_Configuration__c.getInstance().MotorBrokerLEF__c 
                                                        : (qqObj.CreatedDate>=System_Configuration__c.getInstance().PL_Campaign_Start_Date__c 
                                                        && qqObj.CreatedDate<=System_Configuration__c.getInstance().PL_Campaign_End_Date__c)? 0:System_Configuration__c.getInstance().BrokerLEF__c;
               }else{
                   qqObj.Loan_Establishment_Fee__c = pWrap.loanEstablishmentFeeAmount;
               }
               if(pWrap.riskGrade != null) {
                   qqObj.Risk_Grade_Calculated__c = pWrap.riskGrade;
               }
               qqObj.Monthly_Fee__c = System_Configuration__c.getInstance().Loan_Admin_Fee__c;
               update qqObj;
               //generating the EMI for the requested quick quote based on the pricing generated above. Also inserting the AMZ Schedule
               if(!Test.isRunningTest()){
                   EMICalculation.getQuickQuoteEmiNow(qqObj.id);
               }
               return ConstantValues.success;
           }else{
               qqObj.genesis__Status__c = ConstantValues.qqStatus_failed;
               qqObj.Failed_Reason__c = CpConstants.LOWCREDITSCORE;
               update qqObj;
               return ConstantValues.qqStatus_failed + ' - ' + CpConstants.LOWCREDITSCORE;
           }
    }
    
    @AuraEnabled
    public static string getRateEstimateForLWC(id qqId){
        String response;
        String respStr;
        List<genesis__Quick_Quotes__c> qqList;
        genesis__Quick_Quotes__c qqObj;
        System.Savepoint sp = Database.setSavepoint();
        try {
            response = getRateEstimate(qqId);
            if(response == ConstantValues.success){
                qqList = [SELECT id, 
                          Loan_Amount_Requested__c,
                          genesis__Financed_Amount__c,
                          Interest_Type__c,
                          Sales_Channel__c,
                          CCR_Score__c,
                          Credit_Rating_Matrix__r.Risk_Grade__c,
                          Indicative_Interest_Rate__c,
                          Max_Loan_Amount__c,
                          Loan_Establishment_Fee_Percent__c,
                          genesis__Expected_Start_Date__c,
                          CL_Product_Name__c,
                          Loan_Establishment_Fee__c,
                          genesis__Status__c,
                          Final_Score__c,
                          Repayment_Amount__c,
                          Underwriting_check__c,
                          Quick_Quote_Evaluated__c,
                          Failed_Reason__c
                          FROM genesis__Quick_Quotes__c
                          WHERE id =: qqId
                          LIMIT 1];
                
                if(!qqList.isEmpty()){
                    qqObj = qqList[0];
                    if(qqObj.Sales_Channel__c == EMICalculationConstants.OTP_CHANNEL && !qqObj.Quick_Quote_Evaluated__c){
                        throw new CustomException(EMICalculationConstants.UNDWERITING_ERROR_MSG);
                    }
                    if(qqObj.genesis__Status__c == ConstantValues.qqStatus_failed || qqObj.genesis__Status__c == ConstantValues.qqStatus_convertedToApp || qqObj.genesis__Status__c == ConstantValues.qqStatus_expired){
                        throw new CustomException(EMICalculationConstants.IMPROPER_STATUS_ERROR_MSG);
                    }
                }
                
                if(qqObj.CL_Product_Name__c == CpConstants.MOTOR ){
                    respStr = EMICalculationConstants.OUTPUT_TEXT_1 +  qqObj.Indicative_Interest_Rate__c + '%,' + EMICalculationConstants.OUTPUT_TEXT_2 + qqObj.Repayment_Amount__c;
                } else {
                    respStr = EMICalculationConstants.OUTPUT_TEXT_1 +  qqObj.Indicative_Interest_Rate__c + '%,' + EMICalculationConstants.OUTPUT_TEXT_2 + qqObj.Repayment_Amount__c;
                }
            }else{
                throw new CustomException(response);
            }
        }catch(Exception e) {
            Database.rollback(sp);
            ExceptionManager.manageException(e);
            insert ExceptionManager.getClCommonLog(e, ConversionConstant.genesis);
            throw new AuraHandledException(ResponseMessenger.somethingWentWrong + '-' + e.getMessage());
        }
        return respStr;
    }
    
    /**
    * getIndicativePricingForStranger : This method is used to calculate risk grade, geco grade and credit rating matrix for any quote which is new to bureau 
    according to requirements given by SYM-3127.
    * @modified on                    : 20/07/2022
    * @params                         : Double loanAmount, String rate, String product, String segment, String gecoGrade
    * @returnType                     : Wrapper.PricingWrapper
    **/
    
    global static Wrapper.PricingWrapper getIndicativePricingForStranger(Double loanAmount, String rate, String product, String segment, String gecoGrade,string offercode){
        Wrapper.PricingWrapper pWrap = new Wrapper.PricingWrapper();
        List<genesis__Credit_Rating_Matrix__c> genCrdMtrxList = new List<genesis__Credit_Rating_Matrix__c>();
        List<Offer_Code_Action__mdt> OfferCodemdt =new List<Offer_Code_Action__mdt>();
        double minCredRate = 0.0;
        pWrap.requestedLoanAmount = loanAmount;
        if(segment!=null && (segment==CpConstants.LFS_SIB || segment==CpConstants.LFS_COUSIN)){
            genCrdMtrxList = [SELECT id,
                              Name,
                              Interest_Rate__c,
                              LEF__c,
                              Max_Score_Soft__c,
                              Max_Loan_Amount__c,
                              Min_Score_Soft__c,
                              Broker_Max_Loan_Amount__c,
                              Base_Rate__c,
                              Margin_Rate__c,
                              Total_Interest_Variable_Rate__c
                              FROM genesis__Credit_Rating_Matrix__c
                              WHERE Name =:CpConstants.STTRANGER_MATRIX_NAME
                              AND Loan_Product__c =:product
                              AND Risk_Grade_Segment__c =:CpConstants.LFS_COUSIN_OR_SIBLING
                              AND Enabled__c = true
                              LIMIT 1];
        }else {
            genCrdMtrxList = [SELECT id,
                              Name,
                              Interest_Rate__c,
                              LEF__c,
                              Max_Score_Soft__c,
                              Max_Loan_Amount__c,
                              Min_Score_Soft__c,
                              Broker_Max_Loan_Amount__c,
                              Base_Rate__c,
                              Margin_Rate__c,
                              Total_Interest_Variable_Rate__c
                              FROM genesis__Credit_Rating_Matrix__c
                              WHERE Name =:CpConstants.STTRANGER_MATRIX_NAME
                              AND Loan_Product__c =:product
                              AND Risk_Grade_Segment__c =:segment
                              AND Enabled__c = true
                              LIMIT 1];
        }
        if(genCrdMtrxList.size()>0){
            genesis__Credit_Rating_Matrix__c genCrdMtrx = genCrdMtrxList.get(0);
            if(!String.isBlank(offercode) && offercode!=null){
                List<genesis__Credit_Rating_Matrix__c> minCredMatList = [ SELECT Id,
                                                                         Margin_Rate__c,
                                                                         Loan_Product__c,
                                                                         Interest_Rate__c,
                                                                         Total_Interest_Variable_Rate__c,
                                                                         LEF__c
                                                                         FROM genesis__Credit_Rating_Matrix__c 
                                                                         WHERE Name =: System.Label.min_credit_rating_tier
                                                                         AND (Loan_Product__c =:product  OR Loan_Product__c = '') AND Enabled__c = true
                                                                         LIMIT 1];
                if(minCredMatList.size()>0){
                    minCredRate = (minCredMatList[0].Loan_Product__c == null || minCredMatList[0].Loan_Product__c.contains('Fixed')) ? minCredMatList[0].Interest_Rate__c : minCredMatList[0].Total_Interest_Variable_Rate__c;    
                }                                                                
                OfferCodemdt=[SELECT id, Label, Action_Type__c,Rate__c FROM Offer_Code_Action__mdt WHERE Offer_Code__r.Label =:offercode];
                if(OfferCodemdt.size()>0){
                    pWrap.MaxLoanAmount = genCrdMtrx.Max_Loan_Amount__c == null ? 0 : genCrdMtrx.Max_Loan_Amount__c;
                    pWrap.loanEstablishmentFeePercent = genCrdMtrx.LEF__c == null ? 0 : genCrdMtrx.LEF__c;
                    for(Offer_Code_Action__mdt actions : OfferCodemdt){
                        if(rate == CpConstants.FIXED_CONSTANT && actions.Action_Type__c==CpConstants.DISCOUNT){
                            if(isStaffLoan == true){
                                if((genCrdMtrx.Interest_Rate__c-actions.Rate__c)>=staffLoanMinInt && (genCrdMtrx.Interest_Rate__c-actions.Rate__c)<=staffLoanMaxInt){
                                    pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : genCrdMtrx.Interest_Rate__c-actions.Rate__c;
                                    pwrap.DiscountRate=actions.Rate__c;
                                }
                                else{
                                    if((genCrdMtrx.Interest_Rate__c-actions.Rate__c)<staffLoanMinInt){
                                        pWrap.interestRate = staffLoanMinInt;
                                        pwrap.DiscountRate=(genCrdMtrx.Interest_Rate__c-staffLoanMinInt)>0 ? (genCrdMtrx.Interest_Rate__c-staffLoanMinInt) : (staffLoanMinInt-genCrdMtrx.Interest_Rate__c);
                                    }
                                    else{
                                        system.debug('---> '+ staffLoanMaxInt+ '-----> '+genCrdMtrx.Interest_Rate__c);
                                        pWrap.interestRate = staffLoanMaxInt;
                                        pwrap.DiscountRate=(genCrdMtrx.Interest_Rate__c-staffLoanMaxInt)>0 ? (genCrdMtrx.Interest_Rate__c-staffLoanMaxInt) : (staffLoanMaxInt-genCrdMtrx.Interest_Rate__c);
                                    }
                                }
                            }
                            else{
                                if((genCrdMtrx.Interest_Rate__c-actions.Rate__c)>minCredRate){
                                    pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : genCrdMtrx.Interest_Rate__c-actions.Rate__c;
                                    pwrap.DiscountRate=actions.Rate__c;
                                }else{
                                    pWrap.interestRate=minCredRate;
                                    pwrap.DiscountRate=(minCredRate-genCrdMtrx.Interest_Rate__c) > 0 ? (minCredRate-genCrdMtrx.Interest_Rate__c) : (genCrdMtrx.Interest_Rate__c-minCredRate);
                                        }
                            }
                        }else if(rate == CpConstants.FIXED_CONSTANT && actions.Action_Type__c==CpConstants.SPECIAL_RATE){
                            if(isStaffLoan == true){
                                if(actions.Rate__c >= staffLoanMinInt && actions.Rate__c <= staffLoanMaxInt){
                                    pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : actions.Rate__c;
                                    pwrap.DiscountRate= genCrdMtrx.Interest_Rate__c > actions.Rate__c ? (genCrdMtrx.Interest_Rate__c - actions.Rate__c) : (actions.Rate__c - genCrdMtrx.Interest_Rate__c);
                                }
                                else{
                                    if(actions.Rate__c < staffLoanMinInt){
                                        pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : staffLoanMinInt;
                                        pwrap.DiscountRate= genCrdMtrx.Interest_Rate__c > staffLoanMinInt ? (genCrdMtrx.Interest_Rate__c - staffLoanMinInt) : (staffLoanMinInt - genCrdMtrx.Interest_Rate__c);
                                    }
                                    else{
                                        pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : staffLoanMaxInt;
                                        pwrap.DiscountRate= genCrdMtrx.Interest_Rate__c > staffLoanMaxInt ? (genCrdMtrx.Interest_Rate__c - staffLoanMaxInt) : (staffLoanMaxInt - genCrdMtrx.Interest_Rate__c);
                                    }
                                }
                            }
                            else{
                                if(actions.Rate__c>minCredRate){
                                    pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : actions.Rate__c;
                                    pwrap.DiscountRate= genCrdMtrx.Interest_Rate__c > actions.Rate__c ? (genCrdMtrx.Interest_Rate__c - actions.Rate__c) : (actions.Rate__c - genCrdMtrx.Interest_Rate__c);
                                        }else{
                                            pWrap.interestRate = minCredRate == null ? 0 : minCredRate;
                                            pwrap.DiscountRate= (minCredRate-genCrdMtrx.Interest_Rate__c) >0 ? (minCredRate-genCrdMtrx.Interest_Rate__c) : (genCrdMtrx.Interest_Rate__c-minCredRate);
                                                }
                            }
                        }else if(rate == CpConstants.FLOATING_CONSTANT && actions.Action_Type__c==CpConstants.DISCOUNT){
                            if(isStaffLoan == true){
                                if((genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c) >= staffLoanMinInt && (genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c)<= staffLoanMaxInt){
                                    pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c;
                                    pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c-actions.Rate__c;
                                    pwrap.DiscountRate=actions.Rate__c;
                                }
                                else{
                                    if((genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c)<staffLoanMinInt){
                                        pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : staffLoanMinInt;
                                        pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 :staffLoanMinInt - System_Configuration__c.getInstance().Base_Rate__c;
                                        pwrap.DiscountRate = genCrdMtrx.Total_Interest_Variable_Rate__c - staffLoanMinInt;
                                    }
                                    else{
                                        pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : staffLoanMaxInt;
                                        pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : staffLoanMaxInt - System_Configuration__c.getInstance().Base_Rate__c;
                                        pwrap.DiscountRate = genCrdMtrx.Total_Interest_Variable_Rate__c - staffLoanMaxInt;
                                    }
                                }
                            }
                            else{
                                if((genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c)>minCredRate){
                                    pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : genCrdMtrx.Total_Interest_Variable_Rate__c-actions.Rate__c;
                                    pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c-actions.Rate__c;
                                    pwrap.DiscountRate=actions.Rate__c;    
                                }else{
                                    pWrap.interestRate= minCredRate;
                                    pwrap.DiscountRate=(minCredRate-genCrdMtrx.Total_Interest_Variable_Rate__c) > 0 ? (minCredRate-genCrdMtrx.Total_Interest_Variable_Rate__c) : (genCrdMtrx.Total_Interest_Variable_Rate__c-minCredRate);
                                        pWrap.marginRate=genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c-pwrap.DiscountRate;
                                }
                            }
                        }else if (rate== CpConstants.FLOATING_CONSTANT && actions.Action_Type__c==CpConstants.SPECIAL_RATE){
                            if(isStaffLoan == true){
                                if(actions.Rate__c>=staffLoanMinInt && actions.Rate__c<=staffLoanMaxInt){
                                    pWrap.interestRate = actions.Rate__c == null ? 0 : actions.Rate__c;
                                    pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : actions.Rate__c-System_Configuration__c.getInstance().Base_Rate__c;
                                    pwrap.DiscountRate= genCrdMtrx.Total_Interest_Variable_Rate__c > actions.Rate__c ? (genCrdMtrx.Total_Interest_Variable_Rate__c - actions.Rate__c) : (actions.Rate__c - genCrdMtrx.Total_Interest_Variable_Rate__c);
                                }
                                else{
                                    if(actions.Rate__c<staffLoanMinInt){
                                        pWrap.interestRate = staffLoanMinInt;
                                        pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : staffLoanMinInt-System_Configuration__c.getInstance().Base_Rate__c;
                                        pwrap.DiscountRate= genCrdMtrx.Total_Interest_Variable_Rate__c > staffLoanMinInt ? (genCrdMtrx.Total_Interest_Variable_Rate__c - staffLoanMinInt) : (staffLoanMinInt - genCrdMtrx.Total_Interest_Variable_Rate__c);
                                    }
                                    else{
                                        pWrap.interestRate = staffLoanMaxInt;
                                        pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : staffLoanMaxInt-System_Configuration__c.getInstance().Base_Rate__c;
                                        pwrap.DiscountRate= genCrdMtrx.Total_Interest_Variable_Rate__c > staffLoanMaxInt ? (genCrdMtrx.Total_Interest_Variable_Rate__c - staffLoanMaxInt) : (staffLoanMaxInt - genCrdMtrx.Total_Interest_Variable_Rate__c);
                                    }
                                }
                            }
                            else{
                                if(actions.Rate__c>minCredRate){
                                    pWrap.interestRate = actions.Rate__c == null ? 0 : actions.Rate__c;
                                    pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : actions.Rate__c-System_Configuration__c.getInstance().Base_Rate__c;
                                    pwrap.DiscountRate= genCrdMtrx.Total_Interest_Variable_Rate__c > actions.Rate__c ? (genCrdMtrx.Total_Interest_Variable_Rate__c - actions.Rate__c) : (actions.Rate__c - genCrdMtrx.Total_Interest_Variable_Rate__c);  
                                }else{
                                    pWrap.interestRate = minCredRate == null ? 0 : minCredRate;
                                    pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : minCredRate-System_Configuration__c.getInstance().Base_Rate__c;
                                    pwrap.DiscountRate= (genCrdMtrx.Total_Interest_Variable_Rate__c - minCredRate) > 0 ? (genCrdMtrx.Total_Interest_Variable_Rate__c - minCredRate) : (minCredRate - genCrdMtrx.Total_Interest_Variable_Rate__c);
                                }
                            }
                        }else if(actions.Action_Type__c==CpConstants.LEF_WAIVER){
                            pWrap.loanEstablishmentFeePercent=0;
                            Decimal interestRate= (rate == CpConstants.FIXED_CONSTANT)? genCrdMtrx.Interest_Rate__c: genCrdMtrx.Total_Interest_Variable_Rate__c;
                            if(isStaffLoan == true){
                              if(interestRate>=staffLoanMinInt && interestRate<=staffLoanMaxInt)
                              {
                                    pWrap.loanEstablishmentFeeAmount = 0;
                                    pWrap.interestRate = interestRate;
                                    pWrap.marginRate=(rate == CpConstants.FIXED_CONSTANT) ? 0 :interestRate-System_Configuration__c.getInstance().Base_Rate__c;
                                    pWrap.lefDiscount=pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                              }
                              else{
                                    pWrap.loanEstablishmentFeeAmount = 0;
                                    pWrap.interestRate = interestRate<staffLoanMinInt?staffLoanMinInt:staffLoanMaxInt;
                                    pWrap.marginRate=(rate == CpConstants.FIXED_CONSTANT) ? 0 : (interestRate<staffLoanMinInt?staffLoanMinInt:staffLoanMaxInt)-System_Configuration__c.getInstance().Base_Rate__c;
                                    pWrap.lefDiscount=pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                                          
                              }
                            }
                            else{
                                pWrap.loanEstablishmentFeeAmount = 0;
                                pWrap.interestRate = interestRate;
                                pWrap.lefDiscount=pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                            }  
                        }
                    }
                }
                
            }else{
                if(rate == CpConstants.FIXED_CONSTANT){
                    if(isStaffLoan){
                        if(genCrdMtrx.Interest_Rate__c >= staffLoanMinInt && genCrdMtrx.Interest_Rate__c <= staffLoanMaxInt){
                            pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : genCrdMtrx.Interest_Rate__c;
                        }
                        else{
                            if(genCrdMtrx.Interest_Rate__c < staffLoanMinInt){
                                pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : staffLoanMinInt; 
                            }
                            else{
                                pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : staffLoanMaxInt;
                            }
                        }
                    }
                    else{
                        pWrap.interestRate = genCrdMtrx.Interest_Rate__c == null ? 0 : genCrdMtrx.Interest_Rate__c;
                    }
                }else if (rate== CpConstants.FLOATING_CONSTANT){
                    if(isStaffLoan == true){
                        if(genCrdMtrx.Total_Interest_Variable_Rate__c >= staffLoanMinInt && genCrdMtrx.Total_Interest_Variable_Rate__c <=staffLoanMaxInt){
                            pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : genCrdMtrx.Total_Interest_Variable_Rate__c;
                            pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c;
                        }
                        else {
                           if(genCrdMtrx.Total_Interest_Variable_Rate__c < staffLoanMinInt){
                            pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : staffLoanMinInt;
                            pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : staffLoanMinInt - System_Configuration__c.getInstance().Base_Rate__c;
                           }
                           else{
                            pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : staffLoanMaxInt;
                            pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : staffLoanMaxInt - System_Configuration__c.getInstance().Base_Rate__c;
                           }
                        }
                    }
                    else{
                        pWrap.interestRate = genCrdMtrx.Total_Interest_Variable_Rate__c == null ? 0 : genCrdMtrx.Total_Interest_Variable_Rate__c;
                        pWrap.marginRate = genCrdMtrx.Margin_Rate__c == null ? 0 : genCrdMtrx.Margin_Rate__c;
                    }
                }
                if(isStaffLoan ==true){
                    pWrap.loanEstablishmentFeePercent = 0;
                    pWrap.loanEstablishmentFeeAmount = 0;
                }
                else{
                    pWrap.MaxLoanAmount = genCrdMtrx.Max_Loan_Amount__c == null ? 0 : genCrdMtrx.Max_Loan_Amount__c;
                    pWrap.loanEstablishmentFeePercent = genCrdMtrx.LEF__c == null ? 0 : genCrdMtrx.LEF__c;
                    if(pWrap.requestedLoanAmount<=pWrap.MaxLoanAmount){
                        pWrap.loanEstablishmentFeeAmount = pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                        if(pWrap.loanEstablishmentFeeAmount > 1990) {
                            pWrap.loanEstablishmentFeeAmount = 1990;
                        }
                    }else{
                        pWrap.loanEstablishmentFeeAmount = pWrap.MaxLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                        if(pWrap.loanEstablishmentFeeAmount > 1990) {
                            pWrap.loanEstablishmentFeeAmount = 1990;
                        }
                    }
                } 
            }
           
            pWrap.brokerMaxLoanAmount = genCrdMtrx.Broker_Max_Loan_Amount__c == null ? 0 : genCrdMtrx.Broker_Max_Loan_Amount__c;
            pWrap.genCreditRatingId = genCrdMtrx.id;
            pWrap.tier = genCrdMtrx.Name;
            if(pWrap.requestedLoanAmount<=pWrap.brokerMaxLoanAmount){
                pWrap.broker_loanEstFee = pWrap.requestedLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                if(pWrap.broker_loanEstFee > 1990) {
                    pWrap.broker_loanEstFee = 1990;
                }
            }else{
                pWrap.broker_loanEstFee = pWrap.brokerMaxLoanAmount * (pWrap.loanEstablishmentFeePercent/100);
                if(pWrap.broker_loanEstFee > 1990) {
                    pWrap.broker_loanEstFee = 1990;
                }
            }
            pWrap.status = CpConstants.PRICING_GENERATED;
            pWrap.statusCode = ConstantValues.statusOk;
        }else{
            pWrap.status = CpConstants.PRICING_NOT_GENERATED;
            pWrap.statusCode = ConstantValues.error;
        }
        return pWrap;
    }
    
    
}