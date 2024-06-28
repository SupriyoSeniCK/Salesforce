/*********************************************************************************************************
Class            : EquifaxVedaResponseParser
Description      : Parser Class for Equifax Hardpull Integration to parse equifax response into veda comprehensive
Created Date     : 26/07/2023
Developer        : Supriyo Seni
Last Modified By : Supriyo Seni
**********************************************************************************************************/

global with sharing class EquifaxResponseParser{

    /**************************************************************************
     * @Description  : This method creates veda Comprehensive response from responsebody which will be used for existing equifax parsing class
     * @params       : xml response body as string
     * @returnType   : ints.VedaComprehensiveResponse
    ******************************************************************************/ 	
    global static Wrapper.EquifaxHardpullDataWrapper2 createVedaResponse(String xmlResBody){
        //ints.VedaComprehensiveResponse veda = new ints.VedaComprehensiveResponse();
        Wrapper.EquifaxHardpullDataWrapper2 eqWrap = new Wrapper.EquifaxHardpullDataWrapper2();
        Dom.Document doc = new Dom.Document();
        if(xmlResBody == null || String.isBlank(xmlResBody)){
            throw new CustomException(EquifaxIntegrationConstants.RESPONSE_BODY_IS_BLANK);
        }
        doc.load(xmlResBody);
		Map<String, Object> resMap = intframework.XmlToJson.parseDocumentToMap(doc);
        if(resMap != null && resMap.containsKey(EquifaxIntegrationConstants.ENVELOPE)){
            Map<String, Object> envResMap = (Map<String, Object>)resMap.get(EquifaxIntegrationConstants.ENVELOPE);
            if(envResMap != null && envResMap.containsKey(EquifaxIntegrationConstants.BODY)){
                Map<String, Object> bodyResMap = (Map<String, Object>)envResMap.get(EquifaxIntegrationConstants.BODY);
                if(bodyResMap != null && bodyResMap.containsKey(EquifaxIntegrationConstants.RESPONSE)){
                    Map<String, Object> resResMap = (Map<String, Object>)bodyResMap.get(EquifaxIntegrationConstants.RESPONSE);
                    if(resResMap != null &&  resResMap.containsKey(EquifaxIntegrationConstants.PRODUCT_HEADER)){
                        Map<String, Object> pdtHeadResMap = (Map<String, Object>)resResMap.get(EquifaxIntegrationConstants.PRODUCT_HEADER);
                        if(pdtHeadResMap != null && pdtHeadResMap.containsKey('enquiry-id')){
                            
                        }
                    }
                    if(resResMap != null && resResMap.containsKey(EquifaxIntegrationConstants.PRODUCT_DATA)){
                        Map<String, Object> pdtDataResMap = (Map<String, Object>)resResMap.get(EquifaxIntegrationConstants.PRODUCT_DATA);
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.ENQ_REPORT)){
                            eqWrap = getVedaEnquiryReport(pdtDataResMap,eqWrap);
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.SUMM_DATA)){
                            eqWrap = getVedaSummaryData(pdtDataResMap,eqWrap);
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.SCORE_DATA)){
                            eqWrap = getVedaScoreData(pdtDataResMap,eqWrap);   
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.POSSIBLE_MATCHES)){
                            eqWrap = getVedaPossibleMatches(pdtDataResMap,eqWrap);                     
                        }
                        if(pdtDataResMap != null && pdtDataResMap.containsKey(EquifaxIntegrationConstants.FILE_BAN_REPORT)){
                            eqWrap = getVedaFileBanReport(pdtDataResMap,eqWrap);
                        }
                    }
                    if(resResMap != null && resResMap.containsKey(EquifaxIntegrationConstants.ERRORS)){
                        eqWrap = getVedaResErrors(resResMap,eqWrap);
                    }  
                }
                if(bodyResMap != null && bodyResMap.containsKey(EquifaxIntegrationConstants.FAULT)){
                    eqWrap =  getVedaErrors(bodyResMap,eqWrap);
                }    
            }
        }
        // veda.xmlRequest = null;
        // veda.xmlResponse = xmlResBody;
        return eqWrap;
    }
    
    /**************************************************************************
     * @Description  : This method updates veda Comprehensive response with the enquiry report details of the response
     * @params       : Map of String and Object AND veda instance
     * @returnType   : ints.VedaComprehensiveResponse
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper2 getVedaEnquiryReport(Map<String,Object> pdtDataResMap,Wrapper.EquifaxHardpullDataWrapper2 eqWrap){
        Map<String, Object> enRepResMap = (Map<String, Object>)pdtDataResMap.get(EquifaxIntegrationConstants.ENQ_REPORT);
        if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.PRIMARY_MATCH)){
            Equifax_Credit_Report__c ecr = getPrimaryMatchDetails(enRepResMap);
            if(ecr != null){
                eqWrap.ecr = ecr;
            }
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.OTHER_IDEN)){
            List<Other_Identity__c> othIdenList = getVedaOtherIdentities(enRepResMap);
            if(othIdenList != null && othIdenList.size()>0){
                for(Other_Identity__c othIden : othIdenList){
                    eqWrap.othList.add(othIden);
                }  
            }  
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.ADDRESSES)){
            eqWrap =  getVedaAddresses(enRepResMap, eqWrap);
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.EMPLOYMENT)){
            eqWrap = getVedaEmployments(enRepResMap,eqWrap);
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.CONSUMER_CREDIT_FILE)){
            Map<String, Object> conCreFileMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.CONSUMER_CREDIT_FILE);
            if(conCreFileMap != null && conCreFileMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQS)){
                eqWrap = getVedaConsumerCreditEnquiries(conCreFileMap,eqWrap);
            }if(conCreFileMap != null && conCreFileMap.containsKey(EquifaxIntegrationConstants.ACCOUNTS)){
                eqWrap = getVedaAccounts(conCreFileMap,eqWrap);
            }
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.COMMERCIAL_CREDIT_FILE)){
            Map<String, Object> comCreFileMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.COMMERCIAL_CREDIT_FILE);
            if(comCreFileMap != null && comCreFileMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQS)){
                eqWrap = getVedaCommercialCreditEnquiries(enRepResMap,eqWrap);
            }if(comCreFileMap != null && comCreFileMap.containsKey(EquifaxIntegrationConstants.FILE_NOTES)){
                eqWrap = getVedaFileNotes(comCreFileMap,eqWrap);
            }     
        }if(enRepResMap != null && enRepResMap.containsKey(EquifaxIntegrationConstants.PUB_REC_OR_CONSUMER_CRED_INFO)){
            Map<String, Object> pubRecConCreMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.PUB_REC_OR_CONSUMER_CRED_INFO);
            if(pubRecConCreMap != null && pubRecConCreMap.containsKey(EquifaxIntegrationConstants.DIRECTORSHIPS)){
                eqWrap = getVedaDirectorships(pubRecConCreMap,eqWrap);
            }
            if(pubRecConCreMap != null && pubRecConCreMap.containsKey(EquifaxIntegrationConstants.BUSS_NAMES)){
                eqWrap = getVedaBusinessNames(pubRecConCreMap,eqWrap);
            }
            if(pubRecConCreMap != null && pubRecConCreMap.containsKey(EquifaxIntegrationConstants.PERSONAL_INSOVENCIES)){
                eqWrap = getVedaPerosnalInsolvencies(pubRecConCreMap,eqWrap);
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda erros from the response error map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Error
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaResErrors(Map<String,Object> resErrorMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        List<Map<String, Object>> errMapList = new List<Map<String, Object>>(); 
        eqWrap.errList = new List<Error__c>();
        Map<String, Object> errMap = (Map<String, Object>)resErrorMap.get(EquifaxIntegrationConstants.ERRORS);
        if(errMap != null && errMap.containsKey(EquifaxIntegrationConstants.ERROR)){
            errMapList = getListOfMaps(errMap,EquifaxIntegrationConstants.ERROR);
            if(errMapList != null && errMapList.size()>0){
                for(Map<String, Object> errResMap : errMapList){
                    Error__c err = new Error__c();
                    Map<String, Object> faultCodeMap = (Map<String, Object>)errResMap.get(EquifaxIntegrationConstants.FAULT_CODE);
                    Map<String, Object> faultStringMap = (Map<String, Object>)errResMap.get(EquifaxIntegrationConstants.FAULT_STRING);
                    Map<String, Object> faultAacMap = (Map<String, Object>)errResMap.get(EquifaxIntegrationConstants.FAULT_ACTOR);
                    Map<String, Object> faultDetailMap = (Map<String, Object>)errResMap.get(EquifaxIntegrationConstants.DETAIL);
                    if(faultDetailMap != null && faultDetailMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        err.Detail__c  = String.valueOf(faultDetailMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(faultAacMap != null && faultAacMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        err.Fault_Actor__c  = String.valueOf(faultAacMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(faultCodeMap != null && faultCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        err.Fault_Code__c  = String.valueOf(faultCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(faultStringMap != null && faultStringMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        err.Fault_String__c  = String.valueOf(faultStringMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(err != null){
                        eqWrap.errList.add(err);
                    }
                }
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda personalInsolvencies from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.personalInsolvency
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaPerosnalInsolvencies(Map<String,Object> pubRecConCreMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        List<Map<String, Object>> perInsMapList = new List<Map<String, Object>>(); 
        Map<String, Object> insolMap = (Map<String, Object>)pubRecConCreMap.get(EquifaxIntegrationConstants.PERSONAL_INSOVENCIES);
        if(insolMap != null && insolMap.containsKey(EquifaxIntegrationConstants.PERSONAL_INSOVENCY)){
            perInsMapList = getListOfMaps(insolMap,EquifaxIntegrationConstants.PERSONAL_INSOVENCY);
            if(perInsMapList != null){
                eqWrap.ecr.Bankruptcy__c = perInsMapList.size();
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda businessNames from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.businessName
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaBusinessNames(Map<String,Object> pubRecConCreMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        List<Map<String, Object>> busNamesList = new List<Map<String, Object>>(); 
        eqWrap.bsnList = new List<Business_Name__c>();
        eqWrap.bsnMap = new List<Wrapper.CustomMap>();
        Map<String, Object> busNamesMap = (Map<String, Object>)pubRecConCreMap.get(EquifaxIntegrationConstants.BUSS_NAMES);
        if(busNamesMap != null && busNamesMap.containsKey(EquifaxIntegrationConstants.BUSS_NAME)){
            busNamesList = getListOfMaps(busNamesMap,EquifaxIntegrationConstants.BUSS_NAME);
            if(busNamesList != null && busNamesList.size()>0){
                for(Map<String, Object> busNameMap : busNamesList){
                    Business_Name__c vedaBusName = new Business_Name__c();
                    Wrapper.CustomMap cmBsn = new Wrapper.CustomMap();
                    Map<String, Object> idRefMap = (Map<String, Object>)busNameMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        cmBsn.sObjKey = vedaBusName;
                        cmBsn.sObjList = getIdReferences(idRefMap);
                        eqWrap.bsnMap.add(cmBsn);
                    }
                    Map<String, Object> busStartDateMap = (Map<String, Object>)busNameMap.get(EquifaxIntegrationConstants.START_DATE);
                    if(busStartDateMap != null && busStartDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaBusName.Start_Date__c = String.valueOf(busStartDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(busNameMap != null && busNameMap.containsKey(EquifaxIntegrationConstants.LAST_EXTRACT_DATE)){
                        vedaBusName.Last_Extract_Date__c = String.valueOf(busNameMap.get(EquifaxIntegrationConstants.LAST_EXTRACT_DATE));
                    }
                    if(busNameMap != null && busNameMap.containsKey(EquifaxIntegrationConstants.LAST_EXTRACT_TIME)){
                        vedaBusName.Last_Extract_Time__c = String.valueOf(busNameMap.get(EquifaxIntegrationConstants.LAST_EXTRACT_TIME));
                    }
                    if(busNameMap != null && busNameMap.containsKey(EquifaxIntegrationConstants.LAST_UPDATE_DATE)){
                        vedaBusName.Last_Update_Date__c = String.valueOf(busNameMap.get(EquifaxIntegrationConstants.LAST_UPDATE_DATE));
                    }
                    if(busNameMap != null && busNameMap.containsKey(EquifaxIntegrationConstants.LAST_UPDATE_TIME)){
                        vedaBusName.Last_Update_Time__c = String.valueOf(busNameMap.get(EquifaxIntegrationConstants.LAST_UPDATE_TIME));
                    }
                    Map<String, Object> bussMap = (Map<String, Object>)busNameMap.get(EquifaxIntegrationConstants.BUSINESS);
                    if(bussMap != null){
                        Map<String, Object> bussBrMap = (Map<String, Object>)bussMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
                        Map<String, Object> bussNameMap = (Map<String, Object>)bussMap.get(EquifaxIntegrationConstants.NAME);
                        Map<String, Object> bussAbnMap = (Map<String, Object>)bussMap.get(EquifaxIntegrationConstants.ABN);
                        Map<String, Object> bussPredTerMap = (Map<String, Object>)bussMap.get(EquifaxIntegrationConstants.PREV_STATE_OR_TERRITORY_REGISTRATION);
                        if(bussBrMap != null && bussBrMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaBusName.Bureau_Reference__c = String.valueOf(bussBrMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(bussNameMap != null && bussNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaBusName.Name__c = String.valueOf(bussNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        } 
                        if(bussAbnMap != null && bussAbnMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaBusName.ABN__c = String.valueOf(bussAbnMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(bussPredTerMap != null){
                            Map<String, Object> bussStateMap = (Map<String, Object>)bussPredTerMap.get(EquifaxIntegrationConstants.STATE);
                            Map<String, Object> bussNumberMap = (Map<String, Object>)bussPredTerMap.get(EquifaxIntegrationConstants.NUMBER_STR);
                            if(bussStateMap != null && bussStateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaBusName.Previous_State_Or_Territory_Registration__c = String.valueOf(bussStateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            } 
                            if(bussNumberMap != null && bussNumberMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                vedaBusName.Number__c = String.valueOf(bussNumberMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                        }
                    }
                    if(vedaBusName != null){
                        eqWrap.bsnList.add(vedaBusName);
                    }
                }
            }
        }
        return vedaBusNameList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda Directorships from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Directorship
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaDirectorships(Map<String,Object> pubRecConCreMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        List<Map<String, Object>> DirecList = new List<Map<String, Object>>(); 
        eqWrap.dsList = new List<Directorship__c>();
        eqWrap.dsMap = new List<Wrapper.CustomMap>();
        Map<String, Object> directMap = (Map<String, Object>)pubRecConCreMap.get(EquifaxIntegrationConstants.DIRECTORSHIPS);
        if(directMap != null && directMap.containsKey(EquifaxIntegrationConstants.DIRECTORSHIP)){
            DirecList = getListOfMaps(directMap,EquifaxIntegrationConstants.DIRECTORSHIP);
            if(DirecList != null && DirecList.size()>0){
                for(Map<String, Object> direct : DirecList){
                    Directorship__c dsObj = new Directorship__c();
                    Wrapper.CustomMap cmDs = new Wrapper.CustomMap();
                    Map<String, Object> idRefMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        cmDs.sObjKey = dsObj;
                        cmDs.sObjList = (List<SObject>)getIdReferences(idRefMap);
                        eqWrap.dsMap.add(cmDs);
                    }
                    Map<String, Object> dirDateAppMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.DATE_APPOINTED);
                    if(dirDateAppMap != null && dirDateAppMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        dsObj.Date_Appointed__c = String.valueOf(dirDateAppMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> dirDateCeaMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.DATE_CEASED);
                    if(dirDateCeaMap != null && dirDateCeaMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        dsObj.Date_Ceased__c = String.valueOf(dirDateCeaMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> dirDatelasDMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.DATE_LAST_KNOWN_AS_DIRECTOR);
                    if(dirDatelasDMap != null && dirDatelasDMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        dsObj.Date_Last_Known_as_Director__c = String.valueOf(dirDatelasDMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.LAST_EXTRACT_DATE)){
                        dsObj.Last_Extract_Date__c = String.valueOf(direct.get(EquifaxIntegrationConstants.LAST_EXTRACT_DATE));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.LAST_EXTRACT_TIME)){
                        dsObj.Last_Extract_Time__c = String.valueOf(direct.get(EquifaxIntegrationConstants.LAST_EXTRACT_TIME));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.LAST_UPDATE_DATE)){
                        dsObj.Last_Update_Date__c = String.valueOf(direct.get(EquifaxIntegrationConstants.LAST_UPDATE_DATE));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.LAST_UPDATE_TIME)){
                        dsObj.Last_Update_Time__c = String.valueOf(direct.get(EquifaxIntegrationConstants.LAST_UPDATE_TIME));
                    }
                    if(direct != null && direct.containsKey(EquifaxIntegrationConstants.TYPE)){
                        dsObj.Type__c = String.valueOf(direct.get(EquifaxIntegrationConstants.TYPE));
                    }

                    Map<String, Object> dirOrgMap = (Map<String, Object>)direct.get(EquifaxIntegrationConstants.ORGANISATION);
                    if(dirOrgMap != null){
                        Map<String, Object> dirOrgBrMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
                        Map<String, Object> dirOrgNameMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.NAME);
                        Map<String, Object> orgStartDateMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.NAME_START_DATE);
                        Map<String, Object> dirOrgTypeMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.TYPE);
                        Map<String, Object> dirOrgStatusMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.STATUS);
                        Map<String, Object> dirOrgNumberMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.ORG_NUMBER);
                        Map<String, Object> dirOrgAbnMap = (Map<String, Object>)dirOrgMap.get(EquifaxIntegrationConstants.ABN);
                        if(dirOrgBrMap != null && dirOrgBrMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            dsObj.Organization_Bureau_Reference__c = String.valueOf(dirOrgBrMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgAbnMap != null && dirOrgAbnMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            dsObj.Organization_ABN__c = String.valueOf(dirOrgAbnMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgNameMap != null && dirOrgNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            dsObj.Organizaion_Name__c = String.valueOf(dirOrgNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(orgStartDateMap != null && orgStartDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            dsObj.Name_Start_Date__c = String.valueOf(orgStartDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgNumberMap != null && dirOrgNumberMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            dsObj.Organization_Number__c = String.valueOf(dirOrgNumberMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgStatusMap != null && dirOrgStatusMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            dsObj.Organization_Status__c = String.valueOf(dirOrgStatusMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgStatusMap != null && dirOrgStatusMap.containsKey(EquifaxIntegrationConstants.CODE)){
                            dsObj.Organization_Status_Code__c = String.valueOf(dirOrgStatusMap.get(EquifaxIntegrationConstants.CODE));
                        }
                        if(dirOrgTypeMap != null && dirOrgTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            dsObj.Organization_Type__c = String.valueOf(dirOrgTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dirOrgTypeMap != null && dirOrgTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
                            dsObj.Organization_Type_Code__c = String.valueOf(dirOrgTypeMap.get(EquifaxIntegrationConstants.CODE));
                        }
                    }
                    if(dsObj != null){
                        eqWrap.dsList.add(dsObj);
                    }
                }
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda FileNotes from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Directorship
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaFileNotes(Map<String,Object> comCreFileMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        List<Map<String, Object>> fileNoteMapList = new List<Map<String, Object>>(); 
        eqWrap.fnList = new List<File_Note__c>();
        eqWrap.fnMap = new List<Wrapper.CustomMap>();
        Map<String, Object> fileNoteMap = (Map<String, Object>)comCreFileMap.get(EquifaxIntegrationConstants.FILE_NOTES);
        if(fileNoteMap != null && fileNoteMap.containsKey(EquifaxIntegrationConstants.FILE_NOTE)){
            fileNoteMapList = getListOfMaps(fileNoteMap,EquifaxIntegrationConstants.FILE_NOTE);
            if(fileNoteMapList != null && fileNoteMapList.size()>0){
                for(Map<String, Object> fnMap : fileNoteMapList){
                    File_Note__c fnObj = new File_Note__c();
                    Wrapper.CustomMap cmFn = new Wrapper.CustomMap();
                    Map<String, Object> idRefMap = (Map<String, Object>)fnMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        cmFn.sObjKey = fnObj;
                        cmFn.sObjList = (List<SObject>)getIdReferences(idRefMap);
                        eqWrap.fnMap.add(cmFn);
                    }
                    if(fnMap != null && fnMap.containsKey(EquifaxIntegrationConstants.DATE_RECORDED)){
                        fnObj.Date_Recorded__c = String.valueOf(fnMap.get(EquifaxIntegrationConstants.DATE_RECORDED));
                    }
                    Map<String, Object> fnNoteMap = (Map<String, Object>)fnMap.get(EquifaxIntegrationConstants.NOTE);
                    if(fnNoteMap != null && fnNoteMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        fnObj.Note__c = String.valueOf(fnNoteMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(fnObj != null){
                        eqWrap.fnList.add(fnObj);
                    }
                }
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method updates the veda comprehensive response with file ban report received in Equifax response body
     * @params       : Map of String and Object and veda instance
     * @returnType   : nts.VedaComprehensiveResponse
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaFileBanReport(Map<String,Object> pdtDataResMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        Map<String,Object> fileBanRepMap = (Map<String,Object>)pdtDataResMap.get('file-ban-report');
        if(fileBanRepMap != null){
            Map<String,Object> repDateMap = (Map<String,Object>)pdtDataResMap.get(EquifaxIntegrationConstants.REPORTED_DATE);
            Map<String,Object> isExtendedMap = (Map<String,Object>)pdtDataResMap.get(EquifaxIntegrationConstants.IS_EXTENDED);
            Map<String,Object> endDateMap = (Map<String,Object>)pdtDataResMap.get(EquifaxIntegrationConstants.END_DATE);
            if(repDateMap != null && repDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                eqWrap.ecr.File_BAn_Reported_Date__c = String.valueOf(repDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(isExtendedMap != null && isExtendedMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                eqWrap.ecr.File_Ban_Is_Extended__c = String.valueOf(isExtendedMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(endDateMap != null && endDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                eqWrap.ecr.File_Ban_End_Date__c = String.valueOf(endDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            eqWrap.ecr.Is_FileBan__c = true;
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda possibleMatchs from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.possibleMatch
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaPossibleMatches(Map<String,Object> pdtDataResMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        List<Map<String, Object>> possMatMapList = new List<Map<String, Object>>(); 
        eqWrap.posMatchList = new List<Possible_Match__c>();
        eqWrap.posMatchMap = new List<Wrapper.CustomMap>();
        Map<String, Object> possMatMap = (Map<String, Object>)pdtDataResMap.get(EquifaxIntegrationConstants.POSSIBLE_MATCHES);
        if(possMatMap != null && possMatMap.containsKey(EquifaxIntegrationConstants.POSSIBLE_MATCH)){
            possMatMapList = getListOfMaps(possMatMap,EquifaxIntegrationConstants.POSSIBLE_MATCH);
            if(possMatMapList != null && possMatMapList.size()>0){
                for(Map<String, Object> possMat : possMatMapList){
                    Wrapper.CustomMap cmPb = new Wrapper.CustomMap();
                    Possible_Match__c possMatch = new Possible_Match__c();
                    cmPb.sObjKey = possMatch;
                    Map<String, Object> prMatResMap = (Map<String, Object>)possMat.get(EquifaxIntegrationConstants.IDENTITY);
                    if(prMatResMap != null){
                        Map<String, Object> buRefResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
                        Map<String, Object> indNameResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.INDIVIDUAL_NAME);
                        Map<String, Object> genResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.GENDER_STR);
                        Map<String, Object> dobResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.DOB);
                        Map<String, Object> isDecResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.IS_DECEASED);
                        Map<String, Object> driLicResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.DRIVER_LICENCE);
                        Map<String, Object> lodgeResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.LODGED_COMPLAINT);
                        if(indNameResMap != null){
                            Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FAMILY_NAME);
                            Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FIRST_GIVEN_NAME);
                            Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.OTHER_GIVEN_NAME);
                            if(firstNameResMap != null && firstNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                possMatch.First_Name__c = String.valueOf(firstNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                            if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                                possMatch.Name_First_Reported_Date__c = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                            }
                            if(famNameResMap != null && famNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                possMatch.Last_Name__c = String.valueOf(famNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                            if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                                possMatch.Name_Last_Reported_Date__c = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                            }
                            if(otherNameResMap != null && otherNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                possMatch.Middle_Name__c = String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                            if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_CREDIT_ENQ_DATE)){
                                possMatch.individualNameLastCreditEnquiryDate = String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.LAST_CREDIT_ENQ_DATE));
                            }
                        }
                        if(buRefResMap != null && buRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            possMatch.Bureau_Reference_Number__c = String.valueOf(buRefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            possMatch.Date_Of_Birth__c = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                            possMatch.DOB_First_Reported_Date__c = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                        }
                        if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                            possMatch.DOB_Last_Reported_Date__c = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                        }
                        if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                            possMatch.DL_First_Reported_Date__c = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                        }
                        if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                            possMatch.DL_Last_Reported_Date__c = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                        }
                        if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.NUMBER_STR)){
                            Map<String, Object> driLicNameMap = (Map<String, Object>)driLicResMap.get(EquifaxIntegrationConstants.NUMBER_STR);
                            if(driLicNameMap != null && driLicNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                                possMatch.Drivers_Licence_Number__c = String.valueOf(driLicNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                            }
                        }
                        if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            possMatch.Gender__c = String.valueOf(genResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.CODE)){
                            possMatch.Gender_Code__c = String.valueOf(genResMap.get(EquifaxIntegrationConstants.CODE));
                        }
                        if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            possMatch.Is_Deceased__c = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.REPORTED_DATE)){
                            possMatch.Is_Deceased_Reported_Date__c = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                        }
                        if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            possMatch.Lodged_Complaint__c = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            possMatch.Lodge_Complaint_Date__c = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                        }
                        if(prMatResMap != null && prMatResMap.containsKey(EquifaxIntegrationConstants.ID_INDEX)){
                            possMatch.Id_Index__c = String.valueOf(prMatResMap.get(EquifaxIntegrationConstants.ID_INDEX));
                        }    
                    }
                    if(possMat != null && possMat.containsKey(EquifaxIntegrationConstants.ADDRESSES)){
                        List<Address_for_Possible_Match__c> addList = getAddressesForOtherIden(possMat);
                        for(Address_for_Possible_Match__c addPos : addList){
                            cmPb.sObjList.add(addPos);
                        }
                    }
                    if(possMat != null && possMat.containsKey(EquifaxIntegrationConstants.EMPLOYMENT)){
                        List<Possible_Matches_Employer__c> empList = getEmployments(possMat);
                        for(Possible_Matches_Employer__c emp : empList){
                            cmPb.sObjList.add(emp);
                        }
                        //vedaPossMat.employment = getVedaEmployments(possMat);
                    }
                    if(possMat != null){
                        eqWrap.posMatchList.add(possMatch);
                        eqWrap.posMatchMap.add(cmPb);
                    }
                }
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda datablocks from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.DataBlock
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaSummaryData(Map<String,Object> resSummDataMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        eqWrap.dbList = new List<Data_Block__c>();
        eqWrap.dbMap = new List<Wrapper.CustomMap>();
        List<Map<String, Object>> dataBlockMapList = new List<Map<String, Object>>(); 
        Map<String, Object> dataBlockMap = (Map<String, Object>)resSummDataMap.get(EquifaxIntegrationConstants.SUMM_DATA);
        if(dataBlockMap != null && dataBlockMap.containsKey(EquifaxIntegrationConstants.DATA_BLOCK)){
            dataBlockMapList = getListOfMaps(dataBlockMap,EquifaxIntegrationConstants.DATA_BLOCK);
            if(dataBlockMapList != null && dataBlockMapList.size()>0){
                for(Map<String, Object> dBMap : dataBlockMapList){
                    Data_Block__c dBlock = new Data_Block__c();
                    if(dBMap != null && dBMap.containsKey(EquifaxIntegrationConstants.NAME)){
                        dBlock.Name__c = String.valueOf(dBMap.get(EquifaxIntegrationConstants.NAME));
                    }
                    if(dBMap != null && dBMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                        dBlock.Type__c = String.valueOf(dBMap.get(EquifaxIntegrationConstants.TYPE));
                    }
                    if(dBMap != null && dBMap.containsKey(EquifaxIntegrationConstants.CHARACTERISTIC)){
                        Wrapper.CustomMap cmDb = new Wrapper.CustomMap();
                        cmDb.sObjKey = dBlock;
                        cmDb.sObjList = getDataBlockCharacteristics(dBMap);
                        eqWrap.dbMap.add(cmDb);
                    }
                    if(dBlock != null){
                        eqWrap.dbList.add(dBlock);
                    }
                }
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda datablock characteristics from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Characteristic
    ******************************************************************************/ 
    public static List<Characteristic__c> getDataBlockCharacteristics(Map<String,Object> dBMap){
        List<Characteristic__c> vedaDbCharList = new  List<Characteristic__c> ();
        List<Map<String, Object>> dBcharMapList = new List<Map<String, Object>>(); 
        dBcharMapList = getListOfMaps(dBMap,EquifaxIntegrationConstants.CHARACTERISTIC);
        if(dBcharMapList != null && dBcharMapList.size()>0){
            for(Map<String, Object> dBCharMap : dBcharMapList){
                Characteristic__c vedaDbChar = new Characteristic__c();
                Map<String, Object> charVarNameMap = (Map<String, Object>)dBCharMap.get(EquifaxIntegrationConstants.VARIABLE_NAME);
                Map<String, Object> charDescMap = (Map<String, Object>)dBCharMap.get(EquifaxIntegrationConstants.DESCRIPTION);
                Map<String, Object> charValueMap = (Map<String, Object>)dBCharMap.get(EquifaxIntegrationConstants.VALUE);
                Map<String, Object> charDataLevelMap = (Map<String, Object>)dBCharMap.get(EquifaxIntegrationConstants.DATA_LEVEL);
                if(charDataLevelMap != null && charDataLevelMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.Data_Level__c = String.valueOf(charDataLevelMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(charDataLevelMap != null && charDataLevelMap.containsKey(EquifaxIntegrationConstants.CODE)){
                    vedaDbChar.Code_For_Data_Level__c = String.valueOf(charDataLevelMap.get(EquifaxIntegrationConstants.CODE));
                }
                if(charDescMap != null && charDescMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.Description__c = String.valueOf(charDescMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(dBCharMap != null && dBCharMap.containsKey(EquifaxIntegrationConstants.ID)){
                    vedaDbChar.Id__c = String.valueOf(dBCharMap.get(EquifaxIntegrationConstants.ID));
                }
                if(dBCharMap != null && dBCharMap.containsKey(EquifaxIntegrationConstants.KEY_CHARACTERISTIC)){
                    vedaDbChar.Key_Characteristic__c = String.valueOf(dBCharMap.get(EquifaxIntegrationConstants.KEY_CHARACTERISTIC));
                }
                if(charValueMap != null && charValueMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.Value__c = String.valueOf(charValueMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(charValueMap != null && charValueMap.containsKey(EquifaxIntegrationConstants.UNIT)){
                    vedaDbChar.Unit_For_Value__c = String.valueOf(charValueMap.get(EquifaxIntegrationConstants.UNIT));
                }
                if(charVarNameMap != null && charVarNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    vedaDbChar.Variable_Name__c = String.valueOf(charVarNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(vedaDbChar != null){
                    vedaDbCharList.add(vedaDBChar);
                }
            }
        }
        return vedaDbCharList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda scores from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Score
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaScoreData(Map<String,Object> resScoreMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        eqWrap.scrList = new List<Scorecard__c>();      
        eqWrap.scrConFacMap = new List<Wrapper.CustomMap>();
        Map<String, Object> scoreMap = (Map<String, Object>)resScoreMap.get(EquifaxIntegrationConstants.SCORE_DATA);
        if(scoreMap != null && scoreMap.containsKey(EquifaxIntegrationConstants.SCORE)){
            List<Map<String, Object>> scoreResMapList = getListOfMaps(scoreMap,EquifaxIntegrationConstants.SCORE);
            if(scoreResMapList != null && scoreResMapList.size()>0){
                for(Map<String, Object> scoreResMap : scoreResMapList){
                    Scorecard__c scoreCard = new Scorecard__c();
                    Map<String, Object> scoreCardMap = (Map<String, Object>)scoreResMap.get(EquifaxIntegrationConstants.SCORECARD);
                    if(scoreCardMap != null){
                        Map<String, Object> scoreCardName = (Map<String, Object>)scoreCardMap.get(EquifaxIntegrationConstants.NAME);
                        Map<String, Object> scoreCardVersion = (Map<String, Object>)scoreCardMap.get(EquifaxIntegrationConstants.VERSION);
                        Map<String, Object> scoreCardType = (Map<String, Object>)scoreCardMap.get(EquifaxIntegrationConstants.TYPE);
                        Map<String, Object> scoreCardDateLevel = (Map<String, Object>)scoreCardMap.get(EquifaxIntegrationConstants.DATA_LEVEL);
                        if(scoreCardDateLevel != null && scoreCardDateLevel.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            scoreCard.Data_Level__c = String.valueOf(scoreCardDateLevel.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(scoreCardDateLevel != null && scoreCardDateLevel.containsKey(EquifaxIntegrationConstants.CODE)){
                            scoreCard.Code_Associated_with_Data_Level__c = String.valueOf(scoreCardDateLevel.get(EquifaxIntegrationConstants.CODE));
                        }
                        if(scoreCardMap.containsKey(EquifaxIntegrationConstants.ID)){
                            scoreCard.Id__c = String.valueOf(scoreCardMap.get(EquifaxIntegrationConstants.ID));
                        }
                        if(scoreCardName != null && scoreCardName.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            scoreCard.Name__c = String.valueOf(scoreCardName.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(scoreCardVersion != null && scoreCardVersion.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            scoreCard.Version__c = String.valueOf(scoreCardVersion.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                        if(scoreCardType != null && scoreCardType.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            scoreCard.Type__c = String.valueOf(scoreCardType.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    Map<String, Object> riskOddsMap = (Map<String, Object>)scoreResMap.get(EquifaxIntegrationConstants.RISK_ODDS);
                    if(riskOddsMap != null && riskOddsMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        eqWrap.ecr.Risk_Odds__c = String.valueOf(riskOddsMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> scoreMasScaleMap = (Map<String, Object>)scoreResMap.get(EquifaxIntegrationConstants.SCORE_MASTERSCALE);
                    if(scoreMasScaleMap != null && scoreMasScaleMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        eqWrap.ecr.Score_Masterscale__c = String.valueOf(scoreMasScaleMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> conFactorsMap = (Map<String, Object>)scoreResMap.get(EquifaxIntegrationConstants.KEY_CONTRIBUTING_FACTORS);
                    if(conFactorsMap != null){
                        Wrapper.CustomMap cmScr = new Wrapper.CustomMap(); 
                        cmScr.sObjKey = scoreCard;
                        cmScr.sObjList= getScoreConFactors(conFactorsMap);
                        eqWrap.scrConFacMap.add(cmScr);                   
                    }
                    if(scoreCard != null){
                        eqWrap.scrList.add(scoreCard);
                    }
                }
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda score contributing factors from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.ContributingFactor
    ******************************************************************************/ 
    public static List<Score_Contributing_Factor__c> getScoreConFactors(Map<String,Object> conFactorsMap){
        List<Score_Contributing_Factor__c> vedaConFacList = new List<Score_Contributing_Factor__c>(); 
        if(conFactorsMap != null && conFactorsMap.containsKey(EquifaxIntegrationConstants.CONTRIBUTING_FACTOR)){
            List<Map<String, Object>> vedaMapList = getListOfMaps(conFactorsMap,EquifaxIntegrationConstants.CONTRIBUTING_FACTOR);
            if(vedaMapList != null && vedaMapList.size()>0){
                for(Map<String, Object> conFacMap : vedaMapList){
                    Score_Contributing_Factor__c vedaConFac = new Score_Contributing_Factor__c();
                    Map<String, Object> conFacNameMap = (Map<String, Object>)conFacMap.get(EquifaxIntegrationConstants.NAME);
                    Map<String, Object> conFacDesMap = (Map<String, Object>)conFacMap.get(EquifaxIntegrationConstants.DESCRIPTION);
                    Map<String, Object> conFaScoImpMap = (Map<String, Object>)conFacMap.get(EquifaxIntegrationConstants.SCORE_IMPACTOR);
                    if(conFacNameMap != null && conFacNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaConFac.Name__c = String.valueOf(conFacNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(conFacDesMap != null && conFacDesMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaConFac.Description__c = String.valueOf(conFacDesMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(conFaScoImpMap != null && conFaScoImpMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaConFac.Score_Impactor__c = String.valueOf(conFaScoImpMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(conFacMap != null && conFacMap.containsKey(EquifaxIntegrationConstants.ID)){
                        vedaConFac.Id__c = String.valueOf(conFacMap.get(EquifaxIntegrationConstants.ID));
                    }
                    if(conFacMap != null){
                        vedaConFacList.add(vedaConFac);
                    }
                }
            }
        }
        return vedaConFacList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda OtherIdentities from the equifax response
     * @params       : Map of String and Object
     * @returnType   : List of Other_Identity__c
    ******************************************************************************/ 
    public static List<Other_Identity__c> getVedaOtherIdentities(Map<String,Object> vedaOtherIdenMap){
        List<Other_Identity__c> othIdenList = new List<Other_Identity__c>(); 
        Map<String, Object> othIdenMap = (Map<String, Object>)vedaOtherIdenMap.get(EquifaxIntegrationConstants.OTHER_IDEN);
        if(othIdenMap != null && othIdenMap.containsKey(EquifaxIntegrationConstants.OTHER_IDENTITY)){
            List<Map<String, Object>> vedaMapList = getListOfMaps(othIdenMap,EquifaxIntegrationConstants.OTHER_IDENTITY);
            for(Map<String, Object> otherIdenMap : vedaMapList){
                Other_Identity__c iden = new Other_Identity__c();
                Map<String, Object> buRefResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
                Map<String, Object> indNameResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.INDIVIDUAL_NAME);
                Map<String, Object> genResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.GENDER_STR);
                Map<String, Object> dobResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.DOB);
                Map<String, Object> isDecResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.IS_DECEASED);
                Map<String, Object> driLicResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.DRIVER_LICENCE);
                Map<String, Object> lodgeResMap = (Map<String, Object>)otherIdenMap.get(EquifaxIntegrationConstants.LODGED_COMPLAINT);
                if(indNameResMap != null){
                    Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FAMILY_NAME);
                    Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FIRST_GIVEN_NAME);
                    Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.OTHER_GIVEN_NAME);
                    if(firstNameResMap != null && firstNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        iden.First_Name__c = String.valueOf(firstNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                        iden.Name_First_Reported_Date__c = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                    }
                    if(famNameResMap != null && famNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        iden.Last_Name__c = String.valueOf(famNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                        iden.Name_Last_Reported_Date__c = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                    }
                    if(otherNameResMap != null && otherNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        iden.Middle_Name__c = String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_CREDIT_ENQ_DATE)){
                        iden.Last_Enquiry_Date__c = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.LAST_CREDIT_ENQ_DATE));
                    }
                }
                if(buRefResMap != null && buRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    iden.Bureau_Reference_Number__c = String.valueOf(buRefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    iden.Date_of_Birth__c = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                    iden.DOB_First_Reported_Date__c = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                }
                if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                    iden.DOB_Last_Reported_Date__c = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                }
                if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                    iden.DL_First_Reported_Date__c = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                }
                if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                    iden.DL_Last_Reported_Date__c = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                }
                if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.NUMBER_STR)){
                    Map<String, Object> driLicNameMap = (Map<String, Object>)driLicResMap.get(EquifaxIntegrationConstants.NUMBER_STR);
                    if(driLicNameMap != null && driLicNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        iden.Drivers_Licence_Number__c = String.valueOf(driLicNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                }
                if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    iden.Gender__c = String.valueOf(genResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.CODE)){
                    iden.Gender_Code__c = String.valueOf(genResMap.get(EquifaxIntegrationConstants.CODE));
                }
                if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    iden.Is_Deceased__c = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.REPORTED_DATE)){
                    iden.Is_Deceased_Reported_Date__c = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                }
                if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    iden.Lodged_Complaint__c = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    iden.Lodge_Complaint_Date__c = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
                }
                if(iden != null){
                    othIdenList.add(iden);
                }
            }    
        }
        return othIdenList;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda addresses from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of Address__c
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper2 getVedaAddresses(Map<String,Object> resAddMap,Wrapper.EquifaxHardpullDataWrapper2 eqWrap){
        Map<String, Object> addMap = (Map<String, Object>)resAddMap.get(EquifaxIntegrationConstants.ADDRESSES);
        eqWrap.addList = new List<Address__c>();
        eqWrap.addIdRefMap = new List<Wrapper.CustomMap>();
        if(addMap != null && addMap.containsKey(EquifaxIntegrationConstants.ADDRESS)){
            List<Map<String, Object>> addResMapList = getListOfMaps(addMap,EquifaxIntegrationConstants.ADDRESS); 
            if(addResMapList != null){
                for(Map<String, Object> addResMap : addResMapList){
                    Address__c add = new Address__c();
                    Wrapper.CustomMap cmAdd = new Wrapper.CustomMap();
                    Map<String, Object> unitNumMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.UNIT_NUMBER_STR);
                    Map<String, Object> stNumMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STREET_NUMBER_STR);
                    Map<String, Object> stNameMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STREET_NAME_STR);
                    Map<String, Object> stTypeMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STREET_TYPE_STR);
                    Map<String, Object> subMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.SUBURB_STR);
                    Map<String, Object> stateMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STATE);
                    Map<String, Object> postCodeMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.POSTCODE_STR);
                    Map<String, Object> conCodeMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.COUNTRY_CODE_STR);
                    Map<String, Object> propertyMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.PROPERTY_STR);
                    Map<String, Object> idRefMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        cmAdd.sObjKey = add;
                        cmAdd.sObjList = (List<SObject>)getIdReferences(idRefMap);  
                        eqWrap.addIdRefMap.add(cmAdd);
                    }
                    if(conCodeMap != null && conCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Country_Code__c = String.valueOf(conCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(addResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                        add.First_Reported_Date__c = String.valueOf(addResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                    }
                    if(addResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                        add.Last_Reported_Date__c = String.valueOf(addResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                    }
                    if(postCodeMap != null && postCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Post_Code__c = String.valueOf(postCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(propertyMap != null && propertyMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Property__c = String.valueOf(propertyMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stateMap != null && stateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.State__c = String.valueOf(stateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stNameMap != null && stNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Street_Name__c = String.valueOf(stNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stNumMap != null && stNumMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Street_Number__c = String.valueOf(stNumMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stTypeMap != null && stTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Street_Type__c = String.valueOf(stTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(subMap != null && subMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Suburb__c = String.valueOf(subMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(addResMap != null && addResMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                        add.Type__c = String.valueOf(addResMap.get(EquifaxIntegrationConstants.TYPE));
                    }
                    if(unitNumMap != null && unitNumMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Unit_Number__c = String.valueOf(unitNumMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(add != null){
                        eqWrap.addList.add(add);
                    }
                }
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda addresses from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of Address__c
    ******************************************************************************/ 
    public static List<Address_for_Possible_Match__c> getAddressesForOtherIden(Map<String,Object> resAddMap){
        Map<String, Object> addMap = (Map<String, Object>)resAddMap.get(EquifaxIntegrationConstants.ADDRESSES);
        List<Address_for_Possible_Match__c> addList = new List<Address_for_Possible_Match__c>();
        if(addMap != null && addMap.containsKey(EquifaxIntegrationConstants.ADDRESS)){
            List<Map<String, Object>> addResMapList = getListOfMaps(addMap,EquifaxIntegrationConstants.ADDRESS); 
            if(addResMapList != null){
                for(Map<String, Object> addResMap : addResMapList){
                    Address_for_Possible_Match__c add = new Address_for_Possible_Match__c();
                    Map<String, Object> unitNumMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.UNIT_NUMBER_STR);
                    Map<String, Object> stNumMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STREET_NUMBER_STR);
                    Map<String, Object> stNameMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STREET_NAME_STR);
                    Map<String, Object> stTypeMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STREET_TYPE_STR);
                    Map<String, Object> subMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.SUBURB_STR);
                    Map<String, Object> stateMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.STATE);
                    Map<String, Object> postCodeMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.POSTCODE_STR);
                    Map<String, Object> conCodeMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.COUNTRY_CODE_STR);
                    Map<String, Object> propertyMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.PROPERTY_STR);
                    Map<String, Object> idRefMap = (Map<String, Object>)addResMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(conCodeMap != null && conCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Country_Code__c = String.valueOf(conCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(addResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                        add.First_Reported_Date__c = String.valueOf(addResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                    }
                    if(addResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                        add.Last_Reported_Date__c = String.valueOf(addResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                    }
                    if(postCodeMap != null && postCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Post_Code__c = String.valueOf(postCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(propertyMap != null && propertyMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Property__c = String.valueOf(propertyMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stateMap != null && stateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.State__c = String.valueOf(stateMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stNameMap != null && stNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Street_Name__c = String.valueOf(stNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stNumMap != null && stNumMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Street_Number__c = String.valueOf(stNumMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(stTypeMap != null && stTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Street_Type__c = String.valueOf(stTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(subMap != null && subMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Suburb__c = String.valueOf(subMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(addResMap != null && addResMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                        add.Type__c = String.valueOf(addResMap.get(EquifaxIntegrationConstants.TYPE));
                    }
                    if(unitNumMap != null && unitNumMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        add.Unit_Number__c = String.valueOf(unitNumMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(add != null){
                        addList.add(add);
                    }
                }
            }
        }
        return addList;
    }

        /**************************************************************************
     * @Description  : This method returns the list of veda employments from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Employer
    ******************************************************************************/ 
    public static List<Possible_Matches_Employer__c> getEmployments(Map<String,Object> resEmpMap){
        List<Possible_Matches_Employer__c> empList = new List<Possible_Matches_Employer__c>(); 
        Map<String, Object> empMap = (Map<String, Object>)resEmpMap.get(EquifaxIntegrationConstants.EMPLOYMENT);
        if(empMap != null && empMap.containsKey(EquifaxIntegrationConstants.EMPLOYER)){
            List<Map<String, Object>> empMapList = getListOfMaps(empMap,EquifaxIntegrationConstants.EMPLOYER); 
            if(empMapList != null){
                for(Map<String, Object> empResMap : empMapList){
                    Possible_Matches_Employer__c emp = new Possible_Matches_Employer__c();
                    if(empResMap != null && empResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                        emp.First_Reported_Date__c = String.valueOf(empResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                    }
                    if(empResMap != null && empResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                        emp.Last_Reported_Date__c = String.valueOf(empResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                    }
                    if(empResMap != null && empResMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                        emp.Employement_Type__c = String.valueOf(empResMap.get(EquifaxIntegrationConstants.TYPE));
                    }
                    Map<String, Object> empNameMap = (Map<String, Object>)empResMap.get(EquifaxIntegrationConstants.NAME);
                    if(empNameMap != null && empNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        emp.Employer_Name__c = String.valueOf(empNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> empOccMap = (Map<String, Object>)empResMap.get(EquifaxIntegrationConstants.OCCUPATION);
                    if(empOccMap != null && empOccMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        emp.Occupation_Description__c = String.valueOf(empOccMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(emp != null){
                        empList.add(emp);
                    }
                }
            }
        }
        return empList;
    }



    /**************************************************************************
     * @Description  : This method returns the list of veda employments from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Employer
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaEmployments(Map<String,Object> resEmpMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        List<Employer__c> empList = new List<Employer__c>();
        eqWrap.empIdRefMap = new List<Wrapper.CustomMap>();
        Map<String, Object> empMap = (Map<String, Object>)resEmpMap.get(EquifaxIntegrationConstants.EMPLOYMENT);
        if(empMap != null && empMap.containsKey(EquifaxIntegrationConstants.EMPLOYER)){
            List<Map<String, Object>> empMapList = getListOfMaps(empMap,EquifaxIntegrationConstants.EMPLOYER); 
            if(empMapList != null){
                for(Map<String, Object> empResMap : empMapList){
					Employer__c vedaEmpRes = new Employer__c();
                    if(empResMap != null && empResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                        vedaEmpRes.First_Reported_Date__c = String.valueOf(empResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                    }
                    if(empResMap != null && empResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                        vedaEmpRes.Last_Reported_Date__c = String.valueOf(empResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                    }
                    if(empResMap != null && empResMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                        vedaEmpRes.Employment_Type__c = String.valueOf(empResMap.get(EquifaxIntegrationConstants.TYPE));
                    }
                    Map<String, Object> empNameMap = (Map<String, Object>)empResMap.get(EquifaxIntegrationConstants.NAME);
                    if(empNameMap != null && empNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaEmpRes.Employer_Name__c = String.valueOf(empNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> empOccMap = (Map<String, Object>)empResMap.get(EquifaxIntegrationConstants.OCCUPATION);
                    if(empOccMap != null && empOccMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaEmpRes.Occupation_Description__c = String.valueOf(empOccMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    Map<String, Object> idRefMap = (Map<String, Object>)empResMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        Wrapper.CustomMap cmEmp = new Wrapper.CustomMap();
                        cmEmp.sObjKey = vedaEmpRes;
                        cmEmp.sObjList = (List<SObject> )getIdReferences(idRefMap);  
                        eqWrap.empIdRefMap.add(cmEmp); 
                    }
                    if(vedaEmpRes != null){
                        empList.add(vedaEmpRes);
                    }
                }
            }
        }
        eqWrap.empList = empList;
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda consumer credit enquiries from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.CreditEnquiry
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper getVedaConsumerCreditEnquiries(Map<String, Object> conCreFileMap,Wrapper.EquifaxHardpullDataWrapper eqWrap){
        eqWrap.credEnqList = new List<Credit_Enquiry__c>();
        eqWrap.credEnqIdRefMap = new List<Wrapper.CustomMap>();
        Map<String, Object> creEnqMap = (Map<String, Object>)conCreFileMap.get(EquifaxIntegrationConstants.CREDIT_ENQS);
        if(creEnqMap != null && creEnqMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQUIRY)){
            List<Map<String, Object>> creEnqMapList = getListOfMaps(creEnqMap,EquifaxIntegrationConstants.CREDIT_ENQUIRY); 
            if(creEnqMapList != null){
                for(Map<String, Object> creEnq : creEnqMapList){
					Credit_Enquiry__c vedaCredEnq = new Credit_Enquiry__c();
                    Map<String, Object> accTypeMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ACCOUNT_TYPE);
                    Map<String, Object> enqAmtMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ENQUIRY_AMOUNT_STR);
                    Map<String, Object> relMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.RELATIONSHIP);
                    Map<String, Object> creEnqrMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.CREDIT_ENQUIRED);
                    Map<String, Object> creCliRefMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ENQUIRY_CILENT_REFERENCE);
                    Map<String, Object> idRefMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ID_REFERENCES);
                    Map<String, Object> coBorrowerMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.COBORROWER);
                    if(creEnqrMap != null && creEnqrMap.containsKey(EquifaxIntegrationConstants.NAME)){
                        Map<String, Object> creEnqrNameMap = (Map<String, Object>)creEnqrMap.get(EquifaxIntegrationConstants.NAME);
                        if(creEnqrNameMap != null && creEnqrNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaCredEnq.Credit_Enquirer_Name__c = String.valueOf(creEnqrNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(creEnqrMap != null && creEnqrMap.containsKey(EquifaxIntegrationConstants.CLASSIFICATION)){
                        Map<String, Object> creEnqrClasMap = (Map<String, Object>)creEnqrMap.get(EquifaxIntegrationConstants.CLASSIFICATION);
                        if(creEnqrClasMap != null && creEnqrClasMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                            vedaCredEnq.Credit_Enquirer_Classification__c = String.valueOf(creEnqrClasMap.get(EquifaxIntegrationConstants.NODEVALUE));
                        }
                    }
                    if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
                        Wrapper.CustomMap cmCredEnq = new Wrapper.CustomMap();
						cmCredEnq.sObjKey = credEnqObj;
                        cmCredEnq.sObjList = (List<SObject>)getIdReferences(idRefMap);   
                        eqWrap.credEnqIdRefMap.add(cmCredEnq);
                    }
                    if(coBorrowerMap != null && coBorrowerMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaCredEnq.Co_Borrower__c = String.valueOf(coBorrowerMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaCredEnq.Account_Type__c = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
                        vedaCredEnq.Code__c = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.CODE));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
                        vedaCredEnq.Currency_Code__c = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
                    }
                    if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        vedaCredEnq.Enquiry_Amount__c = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
                    }
                    if(creEnq != null && creEnq.containsKey(EquifaxIntegrationConstants.ENQUIRY_DATE)){
                        vedaCredEnq.Enquiry_Date__c = String.valueOf(creEnq.get(EquifaxIntegrationConstants.ENQUIRY_DATE));
                    }
                    if(creEnq != null && creEnq.containsKey(EquifaxIntegrationConstants.TYPE)){
                        vedaCredEnq.Type__c = String.valueOf(creEnq.get(EquifaxIntegrationConstants.TYPE));
                    }
                    if(vedaCredEnq != null){
                        eqWrap.credEnqList.add(vedaCredEnq);
                    }
                }
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the list of veda commercial credit enquiries from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.CreditEnquiry
    ******************************************************************************/ 
    // public static List<ints.VedaComprehensiveResponse.CreditEnquiry> getVedaCommercialCreditEnquiries(Map<String, Object> comCreFileMap){
    //     List<ints.VedaComprehensiveResponse.CreditEnquiry> vedaCredEnqList = new List<ints.VedaComprehensiveResponse.CreditEnquiry>();
    //     Map<String, Object> creEnqMap = (Map<String, Object>)comCreFileMap.get(EquifaxIntegrationConstants.CREDIT_ENQS);
    //     if(creEnqMap != null && creEnqMap.containsKey(EquifaxIntegrationConstants.CREDIT_ENQUIRY)){
    //         List<Map<String, Object>> creEnqMapList = getListOfMaps(creEnqMap,EquifaxIntegrationConstants.CREDIT_ENQUIRY);
    //         if(creEnqMapList != null){
    //             for(Map<String, Object> creEnq : creEnqMapList){
    //                 ints.VedaComprehensiveResponse.CreditEnquiry vedaComCredEnq= new ints.VedaComprehensiveResponse.CreditEnquiry();
    //                 Map<String, Object> accTypeMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ACCOUNT_TYPE);
    //                 Map<String, Object> enqAmtMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ENQUIRY_AMOUNT_STR);
    //                 Map<String, Object> relMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.RELATIONSHIP);
    //                 Map<String, Object> creEnqrMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.CREDIT_ENQUIRED);
    //                 Map<String, Object> creCliRefMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ENQUIRY_CILENT_REFERENCE);
    //                 Map<String, Object> idRefMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.ID_REFERENCES);
    //                 Map<String, Object> coBorrowerMap = (Map<String, Object>)creEnq.get(EquifaxIntegrationConstants.COBORROWER);
    //                 if(creEnqrMap != null && creEnqrMap.containsKey(EquifaxIntegrationConstants.NAME)){
    //                     Map<String, Object> creEnqrNameMap = (Map<String, Object>)creEnqrMap.get(EquifaxIntegrationConstants.NAME);
    //                     if(creEnqrNameMap != null && creEnqrNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                         vedaComCredEnq.creditEnquirerName = String.valueOf(creEnqrNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                     }
    //                 }
    //                 if(creEnqrMap != null && creEnqrMap.containsKey(EquifaxIntegrationConstants.CLASSIFICATION)){
    //                     Map<String, Object> creEnqrClasMap = (Map<String, Object>)creEnqrMap.get(EquifaxIntegrationConstants.CLASSIFICATION);
    //                     if(creEnqrClasMap != null && creEnqrClasMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                         vedaComCredEnq.creditEnquirerClassification = String.valueOf(creEnqrClasMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                     }
    //                 }
    //                 if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
    //                     vedaComCredEnq.idReferences = getIdReferences(idRefMap);
    //                 }
    //                 if(coBorrowerMap != null && coBorrowerMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaComCredEnq.coBorrower = String.valueOf(coBorrowerMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaComCredEnq.accountType = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
    //                     vedaComCredEnq.accountTypeCode = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.CODE));
    //                 }
    //                 if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
    //                     vedaComCredEnq.enquiryAmountCurrencyCode = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
    //                 }
    //                 if(enqAmtMap != null && enqAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaComCredEnq.enquiryAmount = String.valueOf(enqAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(creEnq != null && creEnq.containsKey(EquifaxIntegrationConstants.ENQUIRY_DATE)){
    //                     vedaComCredEnq.enquiryDate = String.valueOf(creEnq.get(EquifaxIntegrationConstants.ENQUIRY_DATE));
    //                 }
    //                 if(creEnq != null && creEnq.containsKey(EquifaxIntegrationConstants.TYPE)){
    //                     vedaComCredEnq.type = String.valueOf(creEnq.get(EquifaxIntegrationConstants.TYPE));
    //                 }
    //                 if(vedaComCredEnq != null){
    //                     vedaCredEnqList.add(vedaComCredEnq);
    //                 }
    //             }
    //         }
    //     }
    //     return vedaCredEnqList;
    // }

    // /**************************************************************************
    //  * @Description  : This method returns the list of veda Accounts from equifax response map
    //  * @params       : Map of String and Object
    //  * @returnType   : List of ints.VedaComprehensiveResponse.account
    // ******************************************************************************/ 
    // public static List<ints.VedaComprehensiveResponse.account> getVedaAccounts(Map<String, Object> conCreFileMap){
    //     List<ints.VedaComprehensiveResponse.account> vedaAccList = new List<ints.VedaComprehensiveResponse.account>();
    //     Map<String, Object> accountsMap = (Map<String, Object>)conCreFileMap.get(EquifaxIntegrationConstants.ACCOUNTS);
    //     if(accountsMap != null && accountsMap.containsKey(EquifaxIntegrationConstants.ACCOUNT)){
    //         List<Map<String, Object>> accMapList = getListOfMaps(accountsMap,EquifaxIntegrationConstants.ACCOUNT);
    //         if(accMapList != null){
    //             for(Map<String, Object> accMap : accMapList){
    //                 ints.VedaComprehensiveResponse.account vedaAcc = new ints.VedaComprehensiveResponse.account();
    //                 Map<String, Object> accTypeMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_TYPE);
    //                 Map<String, Object> accIdMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_ID);
    //                 Map<String, Object> oriCredProMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ORIGINAL_CREDIT_PROVIDER);
    //                 Map<String, Object> relMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.RELATIONSHIP);
    //                 Map<String, Object> accHolderCntMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_HOLDER_COUNT);
    //                 Map<String, Object> accOpenDateMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_OPEN_DATE);
    //                 Map<String, Object> accReOpenDateMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_RE_OPEN_DATE);
    //                 Map<String, Object> loanPayMetMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.LOAN_PAYMENT_METHOD);
    //                 Map<String, Object> termTypeMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.TERM_TYPE);
    //                 Map<String, Object> secCreditMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.SECURED_CREDIT);
    //                 Map<String, Object> termOfLoanMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.TERM_OF_LOAN);
    //                 Map<String, Object> latMaxAmtCreMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.LATEST_MAX_AMT_CREDIT);
    //                 Map<String, Object> isUnlimCreditMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.IS_UNLIMITED_CREDIT);
    //                 Map<String, Object> accClosedDateMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ACCOUNT_CLOSED_DATE);
    //                 Map<String, Object> dateLatChangedMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.DATE_LAST_CHANGED);
    //                 Map<String, Object> oriMaxAmtCreditMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ORIGINAL_MAXIMUM_AMT_CREDIT);
    //                 Map<String, Object> assInfoMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ASSOCIATION_INFO);
    //                 Map<String, Object> idRefMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.ID_REFERENCES);
    //                 if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
    //                     vedaAcc.idReferences = getIdReferences(idRefMap);  
    //                 }
    //                 if(oriCredProMap != null && oriCredProMap.containsKey(EquifaxIntegrationConstants.NAME)){
    //                     Map<String, Object> oriCredProNameMap = (Map<String, Object>)oriCredProMap.get(EquifaxIntegrationConstants.NAME);
    //                     vedaAcc.originalCreditProviderName = String.valueOf(oriCredProNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(oriCredProMap != null && oriCredProMap.containsKey(EquifaxIntegrationConstants.CLASSIFICATION)){
    //                     Map<String, Object> oriCredProClassMap = (Map<String, Object>)oriCredProMap.get(EquifaxIntegrationConstants.CLASSIFICATION);
    //                     vedaAcc.originalCreditProviderClassification = String.valueOf(oriCredProClassMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(oriCredProMap != null && oriCredProMap.containsKey(EquifaxIntegrationConstants.IS_LICENSEE)){
    //                     Map<String, Object> oriCredProLiceMap = (Map<String, Object>)oriCredProMap.get(EquifaxIntegrationConstants.IS_LICENSEE);
    //                     vedaAcc.originalCreditProviderIsLicensee = String.valueOf(oriCredProLiceMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 Map<String, Object> latCredProMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.LATEST_CREDIT_PROVIDER);
    //                 if(latCredProMap != null && latCredProMap.containsKey(EquifaxIntegrationConstants.NAME)){
    //                     Map<String, Object> latCredProNameMap = (Map<String, Object>)latCredProMap.get(EquifaxIntegrationConstants.NAME);
    //                     vedaAcc.latestCreditProviderName = String.valueOf(latCredProNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(latCredProMap != null && latCredProMap.containsKey(EquifaxIntegrationConstants.CLASSIFICATION)){
    //                     Map<String, Object> latCredProClassMap = (Map<String, Object>)latCredProMap.get(EquifaxIntegrationConstants.CLASSIFICATION);
    //                 }
    //                 if(latCredProMap != null && latCredProMap.containsKey(EquifaxIntegrationConstants.IS_LICENSEE)){
    //                     Map<String, Object> latCredProLiceMap = (Map<String, Object>)latCredProMap.get(EquifaxIntegrationConstants.IS_LICENSEE);
    //                 }
    //                 if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.LATEST_START_DATE)){
    //                     Map<String, Object> assInfoStDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.LATEST_START_DATE);
    //                     vedaAcc.associationInformationLatestStartDate = String.valueOf(assInfoStDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.IS_SERIOUS_CREDIT_INFRINGEMENT)){
    //                     Map<String, Object> assInfoIsSeCreInfriMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.IS_SERIOUS_CREDIT_INFRINGEMENT);
    //                     vedaAcc.associationInformationIsSeriousCreditInfringement = String.valueOf(assInfoIsSeCreInfriMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.LATEST_CEASED_DATE)){
    //                     Map<String, Object> assInfoCeaseDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.LATEST_CEASED_DATE);
    //                     vedaAcc.associationInformationLatestCeasedDate = String.valueOf(assInfoCeaseDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.DEFAULT_ASSOCIATION_CEASE_DATE)){
    //                     Map<String, Object> assInfodefAssCeaseDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.DEFAULT_ASSOCIATION_CEASE_DATE);
    //                     vedaAcc.associationInformationDefaultAssociationCeaseDate = String.valueOf(assInfodefAssCeaseDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.DEFAULT_ASSOCIATION_START_DATE)){
    //                     Map<String, Object> assInfodefAssStartDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.DEFAULT_ASSOCIATION_START_DATE);
    //                     vedaAcc.associationInformationDefaultAssociationStartDate = String.valueOf(assInfodefAssStartDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.SCI_DATE)){
    //                     Map<String, Object> assInfoSciDateMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.SCI_DATE);
    //                     vedaAcc.associationInformationSciDate = String.valueOf(assInfoSciDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(assInfoMap != null && assInfoMap.containsKey(EquifaxIntegrationConstants.IS_LICENSEE)){
    //                     Map<String, Object> latCredProLiceMap = (Map<String, Object>)assInfoMap.get(EquifaxIntegrationConstants.IS_LICENSEE);
    //                 }
    //                 Map<String, Object> payHistoryMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.REPAYMENT_HISTORY);
    //                 if(payHistoryMap != null && payHistoryMap.containsKey(EquifaxIntegrationConstants.PAYMENT)){
    //                     vedaAcc.repaymentHistory =  getVedaAccPayments(payHistoryMap);  
    //                 }
    //                 Map<String, Object> defaultsMap = (Map<String, Object>)accMap.get(EquifaxIntegrationConstants.DEFAULTS);
    //                 if(defaultsMap != null && defaultsMap.containsKey(EquifaxIntegrationConstants.DEFAULT_STR)){
    //                     vedaAcc.defaults = getVedaAccDefaults(defaultsMap);  
    //                 }
    //                 if(accClosedDateMap != null && accClosedDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.accountClosedDate = String.valueOf(accClosedDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(accOpenDateMap != null && accOpenDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.accountClosedDate = String.valueOf(accOpenDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(accReOpenDateMap != null && accReOpenDateMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.accountClosedDate = String.valueOf(accReOpenDateMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(accMap != null && accMap.containsKey(EquifaxIntegrationConstants.ACCOUNT_DATA_LEVEL)){
    //                     vedaAcc.accountDataLevel = String.valueOf(accMap.get(EquifaxIntegrationConstants.ACCOUNT_DATA_LEVEL));
    //                 }
    //                 if(accHolderCntMap != null && accHolderCntMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.accountHolderCount = String.valueOf(accHolderCntMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(accIdMap != null && accIdMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.accountId = String.valueOf(accIdMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
    //                     vedaAcc.accountTypeCode = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.CODE));
    //                 }
    //                 if(accTypeMap != null && accTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.accountType = String.valueOf(accTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(dateLatChangedMap != null && dateLatChangedMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.dateLastChanged = String.valueOf(dateLatChangedMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(isUnlimCreditMap != null && isUnlimCreditMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.isUnlimitedCredit = String.valueOf(isUnlimCreditMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(latMaxAmtCreMap != null && latMaxAmtCreMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.latestMaximumAmountCredit = String.valueOf(latMaxAmtCreMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(latMaxAmtCreMap != null && latMaxAmtCreMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
    //                     vedaAcc.latestMaximumAmountCreditCurrencyCode = String.valueOf(latMaxAmtCreMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
    //                 }
    //                 if(accMap != null && accMap.containsKey(EquifaxIntegrationConstants.LATEST_UPDATE_DATE)){
    //                     vedaAcc.latestUpdateDate = String.valueOf(accMap.get(EquifaxIntegrationConstants.LATEST_UPDATE_DATE));
    //                 }
    //                 if(loanPayMetMap != null && loanPayMetMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.loanPaymentMethod = String.valueOf(loanPayMetMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(loanPayMetMap != null && loanPayMetMap.containsKey(EquifaxIntegrationConstants.CODE)){
    //                     vedaAcc.loanPaymentMethodCode = String.valueOf(loanPayMetMap.get(EquifaxIntegrationConstants.CODE));
    //                 }
    //                 if(oriMaxAmtCreditMap != null && oriMaxAmtCreditMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.originalMaximumAmountCredit = String.valueOf(oriMaxAmtCreditMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(oriMaxAmtCreditMap != null && oriMaxAmtCreditMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
    //                     vedaAcc.originalMaximumAmountCreditCurrencyCode = String.valueOf(oriMaxAmtCreditMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
    //                 }
    //                 if(relMap != null && relMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.relationship = String.valueOf(relMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(relMap != null && relMap.containsKey(EquifaxIntegrationConstants.CODE)){
    //                     vedaAcc.relationshipCode = String.valueOf(relMap.get(EquifaxIntegrationConstants.CODE));
    //                 }
    //                 if(secCreditMap != null && secCreditMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.securedCredit = String.valueOf(secCreditMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(secCreditMap != null && secCreditMap.containsKey(EquifaxIntegrationConstants.CODE)){
    //                     vedaAcc.securedCreditCode = String.valueOf(secCreditMap.get(EquifaxIntegrationConstants.CODE));
    //                 }
    //                 if(termOfLoanMap != null && termOfLoanMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.termOfLoan = String.valueOf(termOfLoanMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(termTypeMap != null && termTypeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaAcc.termType = String.valueOf(termTypeMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(termTypeMap != null && termTypeMap.containsKey(EquifaxIntegrationConstants.CODE)){
    //                     vedaAcc.termTypeCode = String.valueOf(termTypeMap.get(EquifaxIntegrationConstants.CODE));
    //                 }
    //                 if(vedaAcc != null){
    //                     vedaAccList.add(vedaAcc);
    //                 }
    //             }
    //         }
    //     }
    //     return vedaAccList;   
    // }

    // /**************************************************************************
    //  * @Description  : This method returns the list of veda Account Payments from equifax response map
    //  * @params       : Map of String and Object
    //  * @returnType   : List of ints.VedaComprehensiveResponse.payment
    // ******************************************************************************/ 
    // public static List<ints.VedaComprehensiveResponse.payment> getVedaAccPayments(Map<String,Object> payHistoryMap){
    //     List<ints.VedaComprehensiveResponse.payment> vedaAccPayList = new List<ints.VedaComprehensiveResponse.payment>();
    //     List<Map<String, Object>> paymentList = getListOfMaps(payHistoryMap,EquifaxIntegrationConstants.PAYMENT);
    //     if(paymentList != null && paymentList.size()>0){
    //         for(Map<String, Object>  paymentMap : paymentList){
    //             ints.VedaComprehensiveResponse.payment vedaPayHistory = new ints.VedaComprehensiveResponse.payment();
    //             if(paymentMap.containsKey(EquifaxIntegrationConstants.PERIOD)){
    //                 Map<String, Object> payPeriodMap = (Map<String, Object>)paymentMap.get(EquifaxIntegrationConstants.PERIOD);
    //                 vedaPayHistory.period = String.valueOf(payPeriodMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //             }
    //             if(paymentMap.containsKey(EquifaxIntegrationConstants.STATUS)){
    //                 Map<String, Object> payStatusMap = (Map<String, Object>)paymentMap.get(EquifaxIntegrationConstants.STATUS);
    //                 vedaPayHistory.status = String.valueOf(payStatusMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //             }
    //             if(vedaPayHistory != null){
    //                 vedaAccPayList.add(vedaPayHistory);
    //             }
    //         }
    //     } 
    //     return vedaAccPayList;
    // }

    // /**************************************************************************
    //  * @Description  : This method returns the list of veda Account defaults from equifax response map
    //  * @params       : Map of String and Object
    //  * @returnType   : List of ints.VedaComprehensiveResponse.VedaComprehensivedefault
    // ******************************************************************************/ 
    // public static List<ints.VedaComprehensiveResponse.VedaComprehensivedefault> getVedaAccDefaults(Map<String,Object> defaultsMap){
    //     List<ints.VedaComprehensiveResponse.VedaComprehensivedefault> vedaDefList = new List<ints.VedaComprehensiveResponse.VedaComprehensivedefault>();
    //     List<Map<String, Object>> defaultMapList= getListOfMaps(defaultsMap,EquifaxIntegrationConstants.DEFAULT_STR);
    //     if(defaultMapList != null && defaultMapList.size()>0){
    //         for(Map<String, Object>  defaultMap : defaultMapList){
    //             ints.VedaComprehensiveResponse.VedaComprehensivedefault vedaDef = new ints.VedaComprehensiveResponse.VedaComprehensivedefault();       
    //             if(defaultMap.containsKey(EquifaxIntegrationConstants.STATUS)){
    //                 Map<String, Object> defStatusMap = (Map<String, Object>)defaultMap.get(EquifaxIntegrationConstants.STATUS);
    //                 if(defStatusMap != null && defStatusMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                     vedaDef.status = String.valueOf(defStatusMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                 }
    //                 if(defStatusMap != null && defStatusMap.containsKey(EquifaxIntegrationConstants.CODE)){
    //                     vedaDef.statusCode = String.valueOf(defStatusMap.get(EquifaxIntegrationConstants.CODE));
    //                 }
    //             }
    //             if(defaultMap.containsKey(EquifaxIntegrationConstants.ORIGINAL_DEFAULT)){                                                    
    //                 Map<String, Object> oriDefMap = (Map<String, Object>)defaultMap.get(EquifaxIntegrationConstants.ORIGINAL_DEFAULT);
    //                 if(oriDefMap != null){
    //                     Map<String, Object> oriDefDateRecMap = (Map<String, Object>)oriDefMap.get(EquifaxIntegrationConstants.DATE_RECORDED);
    //                     Map<String, Object> oriDefAmtMap = (Map<String, Object>)oriDefMap.get(EquifaxIntegrationConstants.DEFAULT_AMOUNT);
    //                     Map<String, Object> oriDefResMap = (Map<String, Object>)oriDefMap.get(EquifaxIntegrationConstants.REASON_TO_REPORT);
    //                     if(oriDefDateRecMap != null && oriDefDateRecMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                         vedaDef.originalDefaultDateRecorded = String.valueOf(oriDefDateRecMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                     }
    //                     if(oriDefResMap != null && oriDefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                         vedaDef.originalDefaultDefaultReasonToReport = String.valueOf(oriDefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                     }
    //                     if(oriDefResMap != null && oriDefResMap.containsKey(EquifaxIntegrationConstants.CODE)){
    //                         vedaDef.originalDefaultDefaultReasonToReportCode = String.valueOf(oriDefResMap.get(EquifaxIntegrationConstants.CODE));
    //                     }
    //                     if(oriDefAmtMap != null && oriDefAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                         vedaDef.originalDefaultDefaultAmount = String.valueOf(oriDefAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                     }
    //                     if(oriDefAmtMap != null && oriDefAmtMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
    //                         vedaDef.originalDefaultDefaultAmountCurrencyCode = String.valueOf(oriDefAmtMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
    //                     }
    //                 }
    //             }
    //             if(defaultMap.containsKey(EquifaxIntegrationConstants.CURRENT_DEFAULT)){                                                    
    //                 Map<String, Object> currDefMap = (Map<String, Object>)defaultMap.get(EquifaxIntegrationConstants.CURRENT_DEFAULT);
    //                 if(currDefMap != null){
    //                     Map<String, Object> currDefDateRecMap = (Map<String, Object>)currDefMap.get(EquifaxIntegrationConstants.DATE_RECORDED);
    //                     Map<String, Object> currDefAmtMap = (Map<String, Object>)currDefMap.get(EquifaxIntegrationConstants.DEFAULT_AMOUNT);
    //                     Map<String, Object> currDefResMap = (Map<String, Object>)currDefMap.get(EquifaxIntegrationConstants.REASON_TO_REPORT);
    //                     if(currDefDateRecMap != null && currDefDateRecMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                         vedaDef.currentDefaultDateRecorded = String.valueOf(currDefDateRecMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                     }
    //                     if(currDefResMap != null && currDefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                         vedaDef.currentDefaultReasonToReport = String.valueOf(currDefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                     }
    //                     if(currDefResMap != null && currDefResMap.containsKey(EquifaxIntegrationConstants.CODE)){
    //                         vedaDef.currentDefaultReasonToReportCode = String.valueOf(currDefResMap.get(EquifaxIntegrationConstants.CODE));
    //                     }
    //                     if(currDefAmtMap != null && currDefAmtMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
    //                         vedaDef.currentDefaultDefaultAmount = String.valueOf(currDefAmtMap.get(EquifaxIntegrationConstants.NODEVALUE));
    //                     }
    //                     if(currDefAmtMap != null && currDefAmtMap.containsKey(EquifaxIntegrationConstants.CURRENCY_CODE)){
    //                         vedaDef.currentDefaultDefaultAmountCurrencyCode = String.valueOf(currDefAmtMap.get(EquifaxIntegrationConstants.CURRENCY_CODE));
    //                     }
    //                 }
    //             }
    //             if(vedaDef != null){
    //                 vedaDefList.add(vedaDef);
    //             }
    //         }
    //     }
    //     return vedaDefList;
    // }

    /**************************************************************************
     * @Description  : This method returns the list of veda erros from equifax response map
     * @params       : Map of String and Object
     * @returnType   : List of ints.VedaComprehensiveResponse.Error
    ******************************************************************************/ 
    public static Wrapper.EquifaxHardpullDataWrapper2 getVedaErrors(Map<String,Object> resErrorMap,Wrapper.EquifaxHardpullDataWrapper2 eqWrap){
        Map<String, Object> faultResMap = (Map<String, Object>)resErrorMap.get(EquifaxIntegrationConstants.FAULT);
        Error__c err = new Error__c();
        if(faultResMap != null){
            Map<String, Object> faultCodeMap = (Map<String, Object>)faultResMap.get(EquifaxIntegrationConstants.FAULTCODE);
            Map<String, Object> faultStringMap = (Map<String, Object>)faultResMap.get(EquifaxIntegrationConstants.FAULTSTRING);
            Map<String, Object> faultAacMap = (Map<String, Object>)faultResMap.get(EquifaxIntegrationConstants.FAULTFACTOR);
            Map<String, Object> faultDetailMap = (Map<String, Object>)faultResMap.get(EquifaxIntegrationConstants.DETAIL);
            if(faultDetailMap != null && faultDetailMap.containsKey(EquifaxIntegrationConstants.POLICYRESULT)){
                Map<String, Object> faultPolResMap = (Map<String, Object>)faultDetailMap.get(EquifaxIntegrationConstants.POLICYRESULT);
                if(faultPolResMap != null && faultPolResMap.containsKey(EquifaxIntegrationConstants.STATUS)){
                    err.Detail__c  = String.valueOf(faultPolResMap.get(EquifaxIntegrationConstants.STATUS));
                }
            }
            if(faultAacMap != null && faultAacMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                err.Fault_Actor__c  = String.valueOf(faultAacMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(faultCodeMap != null && faultCodeMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                err.Fault_Code__c  = String.valueOf(faultCodeMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(faultStringMap != null && faultStringMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                err.Fault_String__c  = String.valueOf(faultStringMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(err != null){
                eqWrap.errList.add(err);
            }
        }
        return eqWrap;
    }

    /**************************************************************************
     * @Description  : This method returns the primary match details from equifax response map
     * @params       : Map of String and Object
     * @returnType   : ints.VedaComprehensiveResponse
    ******************************************************************************/ 
    public static Equifax_Credit_Report__c getPrimaryMatchDetails(Map<String,Object> enRepResMap){
		Equifax_Credit_Report__c ecr  = new Equifax_Credit_Report__c();
        Map<String, Object> prMatResMap = (Map<String, Object>)enRepResMap.get(EquifaxIntegrationConstants.PRIMARY_MATCH);
        if(prMatResMap != null){
            Map<String, Object> buRefResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.BUREAU_REFERENCE);
            Map<String, Object> indNameResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.INDIVIDUAL_NAME);
            Map<String, Object> genResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.GENDER_STR);
            Map<String, Object> dobResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.DOB);
            Map<String, Object> isDecResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.IS_DECEASED);
            Map<String, Object> driLicResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.DRIVER_LICENCE);
            Map<String, Object> lodgeResMap = (Map<String, Object>)prMatResMap.get(EquifaxIntegrationConstants.LODGED_COMPLAINT);
            if(indNameResMap != null){
                Map<String, Object> famNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FAMILY_NAME);
                Map<String, Object> firstNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.FIRST_GIVEN_NAME);
                Map<String, Object> otherNameResMap = (Map<String, Object>)indNameResMap.get(EquifaxIntegrationConstants.OTHER_GIVEN_NAME);
                if(firstNameResMap != null && firstNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    ecr.First_Name__c = String.valueOf(firstNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                    ecr.First_Reported_Date__c = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
                }
                if(famNameResMap != null && famNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    ecr.Last_Name__c = String.valueOf(famNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
                if(indNameResMap != null && indNameResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                    ecr.Last_Reported_Date__c = String.valueOf(indNameResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
                }
                if(otherNameResMap != null && otherNameResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    ecr.Middle_Name__c = String.valueOf(otherNameResMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
            }
            if(buRefResMap != null && buRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                ecr.Bureau_Reference_Number__c = String.valueOf(buRefResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                ecr.Date_Of_Birth__c = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                ecr.DOB_First_Reported_Date__c = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
            }
            if(dobResMap != null && dobResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                ecr.DOB_Last_Reported_Date__c = String.valueOf(dobResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
            }
            if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.FIRST_REPORTED_DATE)){
                ecr.DL_First_Reported_Date__c = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.FIRST_REPORTED_DATE));
            }
            if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.LAST_REPORTED_DATE)){
                ecr.DL_Last_Reported_Date__c = String.valueOf(driLicResMap.get(EquifaxIntegrationConstants.LAST_REPORTED_DATE));
            }
            if(driLicResMap != null && driLicResMap.containsKey(EquifaxIntegrationConstants.NUMBER_STR)){
                Map<String, Object> driLicNameMap = (Map<String, Object>)driLicResMap.get(EquifaxIntegrationConstants.NUMBER_STR);
                if(driLicNameMap != null && driLicNameMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                    ecr.Drivers_Licence_Number__c = String.valueOf(driLicNameMap.get(EquifaxIntegrationConstants.NODEVALUE));
                }
            }
            if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                ecr.Gender__c = String.valueOf(genResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(genResMap != null && genResMap.containsKey(EquifaxIntegrationConstants.CODE)){
                ecr.Gender_Code__c = String.valueOf(genResMap.get(EquifaxIntegrationConstants.CODE));
            }
            if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                ecr.Is_Deceased__c = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(isDecResMap != null && isDecResMap.containsKey(EquifaxIntegrationConstants.REPORTED_DATE)){
                ecr.Is_Deceased_Reported_Date__c = String.valueOf(isDecResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
            }
            if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                ecr.Lodged_Complaint__c = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.NODEVALUE));
            }
            if(lodgeResMap != null && lodgeResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                ecr.Complaint_Reported_Date__c = String.valueOf(lodgeResMap.get(EquifaxIntegrationConstants.REPORTED_DATE));
            }
            if(prMatResMap != null && prMatResMap.containsKey(EquifaxIntegrationConstants.ID_INDEX)){
                ecr.Primary_Match_Id_Index__c = String.valueOf(prMatResMap.get(EquifaxIntegrationConstants.ID_INDEX));
            }
            if(prMatResMap != null && prMatResMap.containsKey(EquifaxIntegrationConstants.TYPE)){
                ecr.Primary_Match_Type__c = String.valueOf(prMatResMap.get(EquifaxIntegrationConstants.TYPE));
            }
            ecr.Bankruptcy__c = 0;
        }
        return ecr;
    }

    /**************************************************************************
     * @Description  : This method is used to check whether the input object is a list or not.
     * @params       : Object param
     * @returnType   : Boolean
    ******************************************************************************/ 
    public static Boolean isCollection(Object inputObj){
        Object obj;
        try{
            obj = (List<Object>)inputObj;
            return true;
        }
        catch(System.TypeException ex){}
        return false;
    }

    /**************************************************************************
     * @Description  : This method is used to return the List of maps from input map values with a specified key
     * @params       : Map of String and object AND string
     * @returnType   : List of Map of String and object 
    ******************************************************************************/
    public static List<Map<String,Object>> getListOfMaps(Map<String,Object> inputMap, string mapKey){
        List<Map<String,Object>> mapList = new List<Map<String,Object>>();
        if(inputMap !=  null && inputMap.containsKey(mapKey) && inputMap.get(mapKey) != null){
            if(isCollection(inputMap.get(mapKey))){
                for(Object scoreObj : (List<Object>)inputMap.get(mapKey)){
                    mapList.add((Map<String, Object>)scoreObj);
                }
            }else{
                mapList.add((Map<String, Object>)inputMap.get(mapKey));
            }
        }else{
            return null;
        }
        return mapList;
    }

    /**************************************************************************
     * @Description  : This method is used to return the List of id-references from input reference map
     * @params       : Map of String and object
     * @returnType   : List of String
    ******************************************************************************/
    public static List<String> getIdReferences(Map<String,Object> idRefMap){
        List<String> idRefList = new List<String>(); 
        if(idRefMap != null && idRefMap.containsKey(EquifaxIntegrationConstants.ID_REFERENCE)){
            List<Map<String, Object>> idRefResMapList = getListOfMaps(idRefMap,EquifaxIntegrationConstants.ID_REFERENCE);
            if(idRefResMapList != null && idRefResMapList.size()>0){
                for(Map<String, Object> idRefResMap : idRefResMapList){
                    if(idRefResMap != null && idRefResMap.containsKey(EquifaxIntegrationConstants.NODEVALUE)){
                        idRefList.add(String.valueOf(idRefResMap.get(EquifaxIntegrationConstants.NODEVALUE)));
                    }
                }
            }    
        }
        return idRefList;
    }
}