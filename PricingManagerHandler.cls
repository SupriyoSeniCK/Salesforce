/*********************************************************************************************************
@Class          : RiskIntegrationParser
@Description    : Parser class for getting application assessment info from LFS IB Api
@Created Date   : 25/02/2022
@Developer      : Barnojit Sharma
@LastModified By: Rahul Raut
@last date      :
**********************************************************************************************************/

public without sharing class RiskIntegrationParser {

    public ints__Credit_Report__c creditReport = new ints__Credit_Report__c();
    public ints__Credit_File__c creditFile = new ints__Credit_File__c();
    public void parseInternalBureauData(Id objId, String ibResponse){
        if(String.isNotBlank(objId) && String.isNotBlank(ibResponse)){
            IBWrapper wrapper = this.ibParser(ibResponse);
            if(wrapper!=null){
                this.creditReport.ints__CreditBureauName__c = EMICalculationConstants.LFS_BUREAU_NAME;
                this.creditReport.LFS_customer_Id__c = wrapper.customer_id;
                this.creditReport.First_Name__c = wrapper.first_Name;
                this.creditReport.Last_Name__c = wrapper.last_Name;
                this.creditReport.Middle_Name__c = wrapper.middle_Name;
                this.creditReport.Date_of_birth__c = wrapper.dateOfBirth;
            }
            String sObjName = objId.getSObjectType().getDescribe().getName();
            if(sObjName == EMICalculationConstants.QUOTE_OBJECT){
                this.creditReport.Quick_Quote__c = objId;
            } else if(sObjName == EMICalculationConstants.PARTY_OBJECT){
                this.creditReport.Party__c = objId;
            }
            Map<String,List<Risk_Variables__mdt>> ibMetadata = this.getIBMetadata();
            this.ibDataWrapper(wrapper,ibMetadata);
            insert this.creditReport;
            this.creditFile.ints__Credit_Report__c = this.creditReport.id;
            insert this.creditFile;

            if(sObjName == EMICalculationConstants.PARTY_OBJECT){
                this.creditReport.Party__c = objId;
                clcommon__Party__c party = new clcommon__Party__c(id = objId,
                                                                    Match_IB_Score_28__c = this.creditFile.Match_IB_Score_28__c);
                update party;
            }  
        }
    }
    public IBWrapper ibParser(String jsonResponse){
        IBWrapper wrapper = new IBWrapper();
        try{
            if(String.isNotBlank(jsonResponse) && jsonResponse.contains(EMICalculationConstants.RISKPROFILERAW)){
                System.JSONParser jsonParserObj = JSON.createParser(jsonResponse);
                While(jsonParserObj != null && jsonParserObj.nextToken() != JSONToken.END_ARRAY){
                    if(jsonParserObj.hasCurrentToken() && jsonParserObj.getCurrentToken() != JSONToken.END_OBJECT){
                        String attribute = jsonParserObj.getText();
                        if(String.isNotBlank(attribute) && attribute.equalsIgnoreCase(EMICalculationConstants.ID_NAME)
                                && jsonParserObj.nextToken() != JSONToken.END_ARRAY){
                            wrapper.customer_id = jsonParserObj.getText();
                        }
                        if(String.isNotBlank(attribute) && attribute.equalsIgnoreCase(EMICalculationConstants.FIRSTNAME)
                                && jsonParserObj.nextToken() != JSONToken.END_ARRAY){
                            wrapper.first_Name = jsonParserObj.getText();
                        }
                        if(String.isNotBlank(attribute) && attribute.equalsIgnoreCase(EMICalculationConstants.MIDDLENAME)
                                && jsonParserObj.nextToken() != JSONToken.END_ARRAY){
                            wrapper.middle_Name = jsonParserObj.getText();
                        }
                        if(String.isNotBlank(attribute) && attribute.equalsIgnoreCase(EMICalculationConstants.LASTNAME)
                                && jsonParserObj.nextToken() != JSONToken.END_ARRAY){
                            wrapper.last_Name = jsonParserObj.getText();
                        }
                        if(String.isNotBlank(attribute) && attribute.equalsIgnoreCase(EMICalculationConstants.DATEOFBIRTH)
                                && jsonParserObj.nextToken() != JSONToken.END_ARRAY){
                            wrapper.dateOfBirth = jsonParserObj.getText();
                        }
                        if(String.isNotBlank(attribute) && attribute.equalsIgnoreCase(EMICalculationConstants.RISKPROFILERAW) 
                                && jsonParserObj.nextToken() != JSONToken.END_ARRAY){
                            Map<String,String> riskMap;
                            try{
                                System.debug('json---'+jsonParserObj);
                                wrapper.riskProfileRaw = (Map<String,String>) jsonParserObj.readValueAs(Map<String,String>.class);
                                System.debug('risk profile---'+wrapper.riskProfileRaw);
                            }catch(Exception ex){
                                wrapper.riskProfileRaw = new Map<String,String>();
                            }
                            break;
                        }
                    }
                }
            }
        }catch(Exception e){
            ExceptionManager.manageException(e);
            insert ExceptionManager.getCLCommonLog(e, ScorecardCalculationConstants.GENESIS);
        }
        return wrapper;
    }
    public Map<String,List<Risk_Variables__mdt>> getIBMetadata(){
        Map<String,List<Risk_Variables__mdt>> resultMap = new Map<String,List<Risk_Variables__mdt>>();
        Map<Id, Integration_Bureau_Data__mdt> ibMetadata = 
                new Map<Id, Integration_Bureau_Data__mdt>([SELECT Id, 
                                                                    DeveloperName 
                                                            FROM Integration_Bureau_Data__mdt]);
        if(ibMetadata != null & !ibMetadata.isEmpty()){
            List<Risk_Variables__mdt> riskVarList = [SELECT Id,
                                                            DeveloperName,
                                                            Field_API_Name__c,
                                                            Integration_Bureau_Data__c,
                                                            Start_Index__c,
                                                            End_Index__c,
                                                            Number_of_Digits__c,
                                                            Enable_Zero_Padding__c
                                                        FROM Risk_Variables__mdt
                                                        WHERE Integration_Bureau_Data__c IN: ibMetadata.keySet()];
            for(Risk_Variables__mdt rVar : riskVarList){
                String ibValName = ibMetadata.get(rVar.Integration_Bureau_Data__c).DeveloperName;
                List<Risk_Variables__mdt> riskVar;
                if(resultMap.isEmpty() || !resultMap.containsKey(ibValName)){
                    riskVar = new List<Risk_Variables__mdt>{rVar};
                }else{
                    riskVar = resultMap.get(ibValName);
                    riskVar.add(rVar);
                }
                resultMap.put(ibValName,riskVar);
            }
        }
        return resultMap;
    }
    public class IBWrapper{
        String customer_id;
        String first_Name;
        String last_Name;
        String middle_Name;
        String dateOfBirth;
        Map<String,String> riskProfileRaw;
    }
    public void ibDataWrapper(IBWrapper wrapper, Map<String,List<Risk_Variables__mdt>> ibMetadata){
        try{
            if(wrapper != null && wrapper.riskProfileRaw != null && wrapper.riskProfileRaw.size() > 0
                    && ibMetadata != null && ibMetadata.size() > 0){
                        for(String ibParam : wrapper.riskProfileRaw.keySet()){
                            if(ibMetadata.containsKey(ibParam) && ibMetadata.get(ibParam) != null && 
                            ibMetadata.get(ibParam).size() > 0){
                                        try{
                                            this.getRiskValues(wrapper.riskProfileRaw.get(ibParam),ibMetadata.get(ibParam));
                                        }catch(Exception exp){
                                            continue;
                                        }
                            }
                        }
            }
        }catch(Exception ex){}
    }
    public void getRiskValues(String ibvalue, List<Risk_Variables__mdt> riskMetadata){
        if(String.isNotBlank(ibvalue) && riskMetadata!= null && riskMetadata.size() > 0){
            for(Risk_Variables__mdt riskParam : riskMetadata){
                String paddedVal;
                if(riskParam.Enable_Zero_Padding__c){
                    try{
                        paddedVal = this.addPadding(ibvalue);
                    }catch(Exception exp){
                        continue;
                    }
                } else {
                    paddedVal = ibValue;
                }
                Integer statIndex = Integer.valueOf(riskParam.Start_Index__c);
                Integer endIndex = Integer.valueOf(riskParam.End_Index__c);
                Decimal fieldval ;
                if( endIndex == 999 ){
                    fieldval = Decimal.valueOf(paddedVal.substring(statIndex));
                } else {
                    fieldval = Decimal.valueOf(paddedVal.substring(statIndex,endIndex));
                }
                this.creditFile.put(riskParam.Field_API_Name__c,fieldval);
            }
        }
    }
    public String addPadding(String ibvalue){
        if(String.isNotBlank(ibvalue) && ibvalue.contains('.')){
            Integer indx = ibvalue.indexOf('.');
            ibvalue = ibvalue.substring(0,indx);
            ibvalue = ibvalue.trim().replace(' ', '');
            ibvalue =  ibvalue.leftPad(19,'0');
        }else if(String.isNotBlank(ibvalue) && ibvalue.length() < 19){
            ibvalue = ibvalue.trim().replace(' ', '');
            ibvalue =  ibvalue.leftPad(19,'0');
        }
        return ibvalue;
    }

}