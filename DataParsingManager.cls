/*********************************************************************************************************
Class            : DataParsingManager
Description      : Response Parser for Equifax Hardpull Integration
Created Date     : 19/06/2018
Developer        : Kushal Basu
Last modified by : Chayan
Last modified on : 28/09/2022
History          : Custom method for parsing fhi information
**********************************************************************************************************/

global class DataParsingManager{
    //Entry point method
    //Execution starts from here
    //takes parameter as an input
	global static Wrapper.EquifaxHardpullDataWrapper parseVedaResponse(ints.VedaComprehensiveResponse res){
			Wrapper.EquifaxHardpullDataWrapper eqWrap = new Wrapper.EquifaxHardpullDataWrapper();
			//declaring data model to store response
			Equifax_Credit_Report__c ecr;
			List<Address__c> addrList;
			List<Error__c> errList;
			List<Employer__c> empList;
			List<Other_Identity__c> othList;
	
			Map<Address__c,List<Address_Id_Reference__c>> addressIdRefMap = new  Map<Address__c,List<Address_Id_Reference__c>>();
			Map<Credit_Enquiry__c,List<Credit_Enquiry_Id_Reference__c>> credEnqRefIdMap = new Map<Credit_Enquiry__c,List<Credit_Enquiry_Id_Reference__c>>();
			Map<Equifax_Credit_Account__c,List<Equifax_Default__c>> accdefaultMap = new Map<Equifax_Credit_Account__c,List<Equifax_Default__c>>();
			Map<Equifax_Credit_Account__c,List<Repayment_History__c>> accRepayHistoryMap = new Map<Equifax_Credit_Account__c,List<Repayment_History__c>>();
			Map<Scorecard__c,List<Score_Contributing_Factor__c>> scoreAndFactorMap = new Map<Scorecard__c,List<Score_Contributing_Factor__c>>();
			Map<Data_Block__c,List<Characteristic__c>> dataVSCharacteristicsMap = new Map<Data_Block__c,List<Characteristic__c>>();
			
			if(res!=null){
				if(System_Configuration__c.getInstance().Save_Equifax_Hardpull_Request__c){//Checks org level permission to store raw request
					eqWrap.reqXml = res.xmlRequest;
				}
				if(System_Configuration__c.getInstance().Save_Equifax_Hardpull_Response__c){//Checks org level permisson to store raw response
					eqWrap.resXml = res.xmlResponse;
				}
			ecr  = new Equifax_Credit_Report__c();
			if(res.personalInsolvencies!=null){
				integer bankruptcy = res.personalInsolvencies.size();
				ecr.Bankruptcy__c = bankruptcy;
			}
      		//System.debug('id===> ' + res.enquiryId);
      		ecr.Enquiry_ID__c= String.valueOf(res.enquiryId);
      		//System.debug('mappedid===> ' + ecr.Enquiry_ID__c);
			ecr.Bureau_Reference_Number__c = res.bureauReference;
			ecr.Complaint_Reported_Date__c = res.lodgedComplaintReportedDate;
			ecr.Date_Of_Birth__c = res.dateOfBirth;
			ecr.DL_First_Reported_Date__c = res.driversLicenceFirstReportedDate;
			ecr.DL_Last_Reported_Date__c = res.driversLicenceLastReportedDate;
			ecr.DOB_First_Reported_Date__c = res.dateOfBirthFirstReportedDate;
			ecr.DOB_Last_Reported_Date__c = res.dateOfBirthLastReportedDate;
			ecr.Drivers_Licence_Number__c = res.driversLicenceNumber;
			ecr.First_Name__c = res.firstGivenName;
			ecr.First_Reported_Date__c = res.individualNameFirstReportedDate;
			ecr.Gender__c = res.gender;
			ecr.Gender_Code__c = res.genderCode;
			ecr.Is_Deceased__c = res.isDeceased;
			ecr.Is_Deceased_Reported_Date__c = res.isDeceasedReportedDate;
			ecr.Last_Name__c = res.familyName;
			ecr.Last_Reported_Date__c = res.individualNameLastReportedDate;
			ecr.Lodged_Complaint__c = res.lodgedComplaint;
			ecr.Middle_Name__c = res.OtherGivenName!=null && res.OtherGivenName.size()>0?res.OtherGivenName.get(0):null;
			ecr.Primary_Match_Id_Index__c = res.primaryMatchIdIndex;
			ecr.Primary_Match_Type__c =res.primaryMatchType;
			
			//Parsing Address
			if(res.addresses!=null && res.addresses.size()>0){
					eqWrap.addList = new List<Address__c>();
					eqWrap.addIdRefMap = new List<Wrapper.CustomMap>();
					for(ints.VedaComprehensiveResponse.Address addRes : res.addresses){
						Address__c add = new Address__c();
						add.Country_Code__c = addRes.countryCode;
						add.First_Reported_Date__c = addRes.firstReportedDate;
						add.Last_Reported_Date__c = addRes.lastReportedDate;
						add.Post_Code__c = addRes.postcode;
						add.Property__c = addRes.property;
						add.State__c = addRes.state;
						add.Street_Name__c = addRes.streetName;
						add.Street_Number__c = addRes.streetNumber;
						add.Street_Type__c = addRes.streetType;
						add.Suburb__c = addRes.suburb;
						add.Type__c = addRes.type;
						add.Unit_Number__c = addRes.unitNumber;
						eqWrap.addList.add(add);
						//addressIdRefMap.put(add,new List<Address_Id_Reference__c>());
						if(addRes.idReference!=null && addRes.idReference.size()>0){
							Wrapper.CustomMap cmAdd = new Wrapper.CustomMap();
							cmAdd.sObjKey = add;
							for(String idRef : addRes.idReference){
									Address_Id_Reference__c addIdRef = new Address_Id_Reference__c();
									addIdRef.Value__c = idRef;
									//addressIdRefMap.get(add).add(addIdRef);
									cmAdd.sObjList.add(addIdRef);
							}
							eqWrap.addIdRefMap.add(cmAdd);
						}
					}
			}
			//Parsing error records
			if(res.errors!=null && res.errors.size()>0){
					errList = new List<Error__c>();
					for(ints.VedaComprehensiveResponse.Error errRes : res.errors){
						Error__c err = new Error__c();
						err.Detail__c = errRes.detail;
						err.Fault_Actor__c = errRes.faultActor;
						err.Fault_Code__c = errRes.faultCode;
						err.Fault_String__c = errRes.faultString;
						errList.add(err);
					}
					eqWrap.errList = errList;
			}

			if(res.generalMessages!=null){
					ecr.General_Message__c = res.generalMessages.message;
					ecr.General_Message_Code__c = res.generalMessages.message;
			}
			//Parsing credit enquiries
			if(res.creditEnquiries!=null && res.creditEnquiries.size()>0){
					eqWrap.credEnqList = new List<Credit_Enquiry__c>();
					eqWrap.credEnqIdRefMap = new List<Wrapper.CustomMap>();
					for(ints.VedaComprehensiveResponse.CreditEnquiry credEnqRes : res.creditEnquiries){
						Credit_Enquiry__c credEnqObj = new Credit_Enquiry__c();
						credEnqObj.Credit_Enquirer_Name__c = credEnqRes.creditEnquirerName;
						credEnqObj.Credit_Enquirer_Classification__c = credEnqRes.creditEnquirerClassification;
						credEnqObj.Co_Borrower__c = credEnqRes.coBorrower;
						credEnqObj.Account_Type__c = credEnqRes.accountType;
						credEnqObj.Code__c = credEnqRes.accountTypeCode;
						credEnqObj.Currency_Code__c = credEnqRes.enquiryAmountCurrencyCode;
						credEnqObj.Enquiry_Amount__c = credEnqRes.enquiryAmount;
						credEnqObj.Enquiry_Date__c = credEnqRes.enquiryDate;
						credEnqObj.Type__c = credEnqRes.type;
						eqWrap.credEnqList.add(credEnqObj);
						if(credEnqRes.idReferences!=null && credEnqRes.idReferences.size()>0){
							Wrapper.CustomMap cmCredEnq = new Wrapper.CustomMap();
							cmCredEnq.sObjKey = credEnqObj;
							for(String idRef : credEnqRes.idReferences){
									Credit_Enquiry_Id_Reference__c credEnqIdRefObj = new Credit_Enquiry_Id_Reference__c();
									credEnqIdRefObj.Value__c = idRef;
									cmCredEnq.sObjList.add(credEnqIdRefObj);
							}
							eqWrap.credEnqIdRefMap.add(cmCredEnq);
						}
					}
			}
			//Parsing Commercial Credit Eqnquiries
			if(res.commercialCreditFileCreditEnquiries!=null && res.commercialCreditFileCreditEnquiries.size()>0){
					//eqWrap.credEnqList = new List<Credit_Enquiry__c>();
					//eqWrap.credEnqIdRefMap = new List<Wrapper.CustomMap>();
					for(ints.VedaComprehensiveResponse.CreditEnquiry credEnqRes : res.commercialCreditFileCreditEnquiries){
						Credit_Enquiry__c credEnqObj = new Credit_Enquiry__c();
						credEnqObj.Credit_Enquirer_Name__c = credEnqRes.creditEnquirerName;
						credEnqObj.Credit_Enquirer_Classification__c = credEnqRes.creditEnquirerClassification;
						credEnqObj.Co_Borrower__c = credEnqRes.coBorrower;
						credEnqObj.Account_Type__c = credEnqRes.accountType;
						credEnqObj.Code__c = credEnqRes.accountTypeCode;
						credEnqObj.Currency_Code__c = credEnqRes.enquiryAmountCurrencyCode;
						credEnqObj.Enquiry_Amount__c = credEnqRes.enquiryAmount;
						credEnqObj.Enquiry_Date__c = credEnqRes.enquiryDate;
						credEnqObj.Type__c = credEnqRes.type;
						eqWrap.credEnqList.add(credEnqObj);
						if(credEnqRes.idReferences!=null && credEnqRes.idReferences.size()>0){
							Wrapper.CustomMap cmCredEnq = new Wrapper.CustomMap();
							cmCredEnq.sObjKey = credEnqObj;
							for(String idRef : credEnqRes.idReferences){
									Credit_Enquiry_Id_Reference__c credEnqIdRefObj = new Credit_Enquiry_Id_Reference__c();
									credEnqIdRefObj.Value__c = idRef;
									cmCredEnq.sObjList.add(credEnqIdRefObj);
							}
							eqWrap.credEnqIdRefMap.add(cmCredEnq);
						}
					}
			}

			//Parsing employer info
			if(res.employers!=null && res.employers.size()>0){
					empList = new List<Employer__c>();
					eqWrap.empIdRefMap = new List<Wrapper.CustomMap>();
					for(ints.VedaComprehensiveResponse.Employer empRes : res.employers){
						Employer__c empObj = new Employer__c();
						empObj.Employer_Name__c = empRes.name;
						empObj.Employment_Type__c = empRes.type;
						empObj.First_Reported_Date__c = empRes.firstReportedDate;
						empObj.Last_Reported_Date__c = empRes.lastReportedDate;
						empObj.Occupation_Description__c = empRes.occupation;
						empList.add(empObj);
						if(empRes.idReferences!=null && empRes.idReferences.size()>0){
							Wrapper.CustomMap cmEmp = new Wrapper.CustomMap();
							cmEmp.sObjKey = empObj;
							for(String idRef : empRes.idReferences){
							Employer_Id_Reference__c empIdRef = new Employer_Id_Reference__c();
							empIdRef.id__c = idRef;
							cmEmp.sObjList.add(empIdRef);
							}
							eqWrap.empIdRefMap.add(cmEmp);
						}
					}
				eqWrap.empList = empList;
			}
			//Parsing other identities
			if(res.otherIdentities!=null && res.otherIdentities.size()>0){
					othList = new List<Other_Identity__c>();
					for(ints.VedaComprehensiveResponse.OtherIdentity othRes : res.otherIdentities){
						Other_Identity__c oth = new Other_Identity__c();
						oth.First_Name__c = othRes.individualNameFirstGivenName;
						oth.Gender__c = othRes.gender;
						oth.Gender_Code__c = othRes.genderCode;
						oth.Is_Deceased__c = othRes.isDeceased;
						oth.Last_Name__c = othRes.individualNameFamilyName;
						if(othRes.individualNameOtherGivenName!=null && othRes.individualNameOtherGivenName.size()>0){
							oth.Middle_Name__c = othRes.individualNameOtherGivenName.get(0);
						}
						oth.Bureau_Reference_Number__c = othRes.bureauReference;
						oth.Date_of_Birth__c = othRes.dateOfBirth;
						oth.DL_First_Reported_Date__c = othRes.driversLicenceFirstReportedDate;
						oth.DL_Last_Reported_Date__c = othRes.driversLicenceLastReportedDate;
						oth.DOB_First_Reported_Date__c = othRes.dateOfBirthFirstReportedDate;
						oth.DOB_Last_Reported_Date__c = othRes.dateOfBirthLastReportedDate;
						oth.Drivers_Licence_Number__c = othRes.driversLicenceNumber;
						oth.Is_Deceased_Reported_Date__c = othRes.isDeceasedReportedDate;
						oth.Lodge_Complaint_Date__c = othRes.lodgedComplaintReportedDate;
						oth.Lodged_Complaint__c = othRes.lodgedComplaint;
						oth.Name_First_Reported_Date__c = othRes.individualNameFirstReportedDate;
						oth.Name_Last_Reported_Date__c = othRes.individualNameLastReportedDate;
						oth.Last_Enquiry_Date__c = othRes.individualNameLastCreditEnquiryDate;
						othList.add(oth);
					}
					eqWrap.othList = othList;
			}
			//Parsing accounts
			if(res!=NULL && res.accounts!=NULL && res.accounts.size()>0){
				eqWrap.eqCredAccList = new List<Equifax_Credit_Account__c>();
				eqWrap.eqCredAccMap = new List<Wrapper.CustomMap>();
				for(ints.VedaComprehensiveResponse.account acc:res.accounts){
						Equifax_Credit_Account__c Acct=new Equifax_Credit_Account__c();
						Acct.Account_Closed_Date__c=acc.accountClosedDate;
						Acct.Account_Data_Level__c=acc.accountDataLevel;
						Acct.Account_Holder_Count__c    =acc.accountHolderCount;
						Acct.Account_Id__c=acc.accountId;
						Acct.Account_Open_Date__c=acc.accountOpenDate;
						Acct.Account_Reopen_Date__c=acc.accountReopenDate;
						Acct.Account_Code__c=acc.accountTypeCode;
						Acct.Account_Type__c=acc.accountType;
						Acct.Association_Info_Latest_Ceased_Date__c=acc.associationInformationLatestCeasedDate;
						Acct.Association_Info_Latest_Start_Date__c=acc.associationInformationLatestStartDate;
						Acct.Association_Default_Cease_Date__c=acc.associationInformationDefaultAssociationCeaseDate;
						Acct.Association_Default_Start_Date__c=acc.associationInformationDefaultAssociationStartDate;
						Acct.Association_Info_Sci_Date__c=acc.associationInformationSciDate;
						Acct.Association_Info_Serious_Credit_Infrngmt__c=acc.associationInformationIsSeriousCreditInfringement;
						Acct.Date_Last_Changed__c=acc.dateLastChanged;
						Acct.Is_Unlimited_Credit__c=acc.isUnlimitedCredit;
						Acct.Name_of_Latest_Credit_Provider__c=acc.latestCreditProviderName;
						Acct.Latest_Max_Amount_Credit__c=acc.latestMaximumAmountCredit;
						Acct.Currency_Code_for_Latest_Max_Amt_Crdt__c=acc.latestMaximumAmountCreditCurrencyCode;
						Acct.Latest_Update_Date__c=acc.latestUpdateDate;
						Acct.Loan_Payment_Method__c=acc.loanPaymentMethod;
						Acct.Code_for_Loan_Payment_Method__c=acc.loanPaymentMethodCode;
						Acct.Classification_Original_Credit_Provider__c=acc.originalCreditProviderClassification;
						Acct.Is_License_of_Original_Credit_Provider__c=acc.originalCreditProviderIsLicensee;
						Acct.Name_Of_Original_Credit_Provider__c=acc.originalCreditProviderName;
						Acct.Original_Max_Amount_Credit__c=acc.originalMaximumAmountCredit;
						Acct.Currency_Code_for_Original_Max_Amt_Crdt__c=acc.originalMaximumAmountCreditCurrencyCode;
						Acct.Relation_of_Account_with_Individual__c=acc.relationship;
						Acct.Relationship_Code__c=acc.relationshipCode;
						Acct.Secured_Credit__c=acc.securedCredit;
						Acct.Code_for_Secured_Credit__c=acc.securedCreditCode;
						Acct.Term_of_Loan__c=acc.termOfLoan;
						Acct.Term_Type__c=acc.termType;
						Acct.Term_Code__c=acc.termTypeCode;
						eqWrap.eqCredAccList.add(acct);
						Wrapper.CustomMap cmCredAcc;
						//Parsing account defaults
						if(acc!=NULL && acc.defaults!=NULL && acc.defaults.size()>0){
							cmCredAcc = new Wrapper.CustomMap();
							cmCredAcc.sObjKey = acct;
							for(ints.VedaComprehensiveResponse.VedaComprehensivedefault VedaDef:acc.defaults){
								Equifax_Default__c EqFxDf= new Equifax_Default__c();
								EqFxDf.Code_for_Equifax_Default_Status__c=VedaDef.statusCode;
								EqFxDf.Current_Default_Amount__c=VedaDef.currentDefaultDefaultAmount;
								EqFxDf.Current_Default_Currency_Code__c=VedaDef.currentDefaultDefaultAmountCurrencyCode;
								EqFxDf.Current_Default_Date_Recorded__c=VedaDef.currentDefaultDateRecorded;
								EqFxDf.Current_Default_Reason_To_Report__c=VedaDef.currentDefaultReasonToReport;
								EqFxDf.Current_Default_Reason_To_Report_Code__c=VedaDef.currentDefaultReasonToReportCode;
								EqFxDf.Equifax_Default_Status_Date__c=VedaDef.statusDate;
								EqFxDf.Orginal_Default_Reason_To_Report__c=VedaDef.originalDefaultDefaultReasonToReport;
								EqFxDf.Original_Default_Amount__c=VedaDef.originalDefaultDefaultAmount;
								EqFxDf.Original_Default_Currency_Code__c=VedaDef.originalDefaultDefaultAmountCurrencyCode;
								EqFxDf.Original_Default_Date_Recorded__c=VedaDef.originalDefaultDateRecorded;
								EqFxDf.Original_Default_Reason_To_Report_Code__c=VedaDef.originalDefaultDefaultReasonToReportCode;
								EqFxDf.Status_of_Equifax_Default__c=VedaDef.status;     
								cmCredAcc.sObjList.add(EqFxDf);
							}
						}
						//Parsing account repayment history
						System.debug('Parsing Repayment history');
						if(acc!=NULL && acc.repaymentHistory!=NULL && acc.repaymentHistory.size()>0){
							System.debug('Repayment history => '+acc.repaymentHistory);
							if(cmCredAcc==null){
								cmCredAcc = new Wrapper.CustomMap();
								cmCredAcc.sObjKey = acct;
							}
							for(ints.VedaComprehensiveResponse.payment payHistory:acc.repaymentHistory){
								Repayment_History__c RepayH =new Repayment_History__c();
								RepayH.Status__c=payHistory.status;
								RepayH.Period__c=payHistory.period;
								cmCredAcc.sObjList.add(RepayH);     
							}
						}
						if(cmCredAcc!=null){
							eqWrap.eqCredAccMap.add(cmCredAcc);
							System.debug('eqWrap.eqCredAccMap.size() ==>> '+eqWrap.eqCredAccMap.size());
						}                                                                                                                
					}
				}
				//Parsing Score data
				if(res!=NULL && res.scoreData!=NULL && res.scoreData.size()>0){
					eqWrap.scrList = new List<Scorecard__c>();      
					eqWrap.scrConFacMap = new List<Wrapper.CustomMap>();
					for(ints.VedaComprehensiveResponse.Score sData:res.scoreData){       
					Scorecard__c scoreC=new Scorecard__c();
					scoreC.Data_Level__c=sData.scoreDataLevel;
					scoreC.Code_Associated_with_Data_Level__c=sData.scoreDataLevelCode;
					scoreC.Id__c=sData.scoreId;
					scoreC.Name__c=sData.scoreName;
					scoreC.Version__c=sData.scoreVersion;
					scoreC.Type__c=sData.scorType;
					ecr.Risk_Odds__c=sData.riskOdds;
					ecr.Score_Masterscale__c=sData.scoreMasterscale;
					eqWrap.scrList.add(scoreC);
					//Parsing contributing factors
					if(sData!=NULL && sData.contributingFactor!=NULL && sData.contributingFactor.size()>0){
						Wrapper.CustomMap cmScr = new Wrapper.CustomMap(); 
						cmScr.sObjKey = scoreC;
						for(ints.VedaComprehensiveResponse.ContributingFactor conFact: sData.contributingFactor){
							Score_Contributing_Factor__c factor= new Score_Contributing_Factor__c();
							factor.Description__c=conFact.description;
							factor.Id__c=conFact.contributingFactorId;
							factor.Name__c=conFact.name;
							factor.Score_Impactor__c=conFact.scoreImpactor;
							cmScr.sObjList.add(factor);
						}
						eqWrap.scrConFacMap.add(cmScr);                   
					}
					}
				}
			//Parsing summary data
			if(res.summaryData!=NULL && res!=NULL && res.summaryData.size()>0){
			eqWrap.dbList = new List<Data_Block__c>();
			eqWrap.dbMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.DataBlock dB : res.summaryData){
				Data_Block__c DBlock= new Data_Block__c();
				DBlock.Name__c=dB.name;
				DBlock.Type__c=dB.type;
				eqWrap.dbList.add(dBlock);
				if(dB.characteristic!=NULL && dB!=NULL && dB.characteristic.size()>0){
					Wrapper.CustomMap cmDb = new Wrapper.CustomMap();
					cmDb.sObjKey = dBlock;
					for(ints.VedaComprehensiveResponse.Characteristic cha:dB.characteristic){
						Characteristic__c chara=new Characteristic__c();
						chara.Code_For_Data_Level__c=cha.dataLevelCode;
						chara.Data_Level__c=cha.dataLevel;
						chara.Description__c=cha.description;
						chara.Id__c=cha.characteristicId;
						chara.Key_Characteristic__c=cha.keyCharacteristic;
						chara.Unit_For_Value__c=cha.unit;
						chara.Value__c=cha.value;
						chara.Variable_Name__c=cha.variableName;
						cmDb.sObjList.add(chara);
					}
					eqWrap.dbMap.add(cmDb);
					}
				}
			}
			//Parsing other possible matches
			if(res.possibleMatches!=null && res.possibleMatches.size()>0){
				eqWrap.posMatchList = new List<Possible_Match__c>();
				eqWrap.posMatchMap = new List<Wrapper.CustomMap>();
				for(ints.VedaComprehensiveResponse.possibleMatch pbRes : res.possibleMatches){
					Wrapper.CustomMap cmPb = new Wrapper.CustomMap();
					Possible_Match__c pbObj = new Possible_Match__c();
					cmPb.sObjKey = pbObj;
					if(pbRes.identity!=null){
					pbObj.Bureau_Reference_Number__c = pbRes.identity.bureauReference;
					pbObj.Date_Of_Birth__c = pbRes.identity.dateOfBirth;
					pbObj.DL_First_Reported_Date__c = pbRes.identity.driversLicenceFirstReportedDate;
					pbObj.DL_Last_Reported_Date__c = pbRes.identity.driversLicenceLastReportedDate;
					pbObj.DOB_First_Reported_Date__c = pbRes.identity.dateOfBirthFirstReportedDate;
					pbObj.DOB_Last_Reported_Date__c = pbRes.identity.dateOfBirthFirstReportedDate;
					pbObj.Drivers_Licence_Number__c = pbRes.identity.driversLicenceNumber;
					pbObj.First_Name__c = pbRes.identity.individualNameFirstGivenName;
					pbObj.Gender__c = pbRes.identity.gender;
					pbObj.Gender_Code__c = pbRes.identity.genderCode;
					pbObj.Id_Index__c = pbRes.identity.idIndex;
					pbObj.Is_Deceased__c = pbRes.identity.isDeceased;
					pbObj.Is_Deceased_Reported_Date__c = pbRes.identity.isDeceasedReportedDate;
					pbObj.Last_Enquiry_Date__c = pbRes.identity.individualNameLastCreditEnquiryDate;
					pbObj.Last_Name__c = pbRes.identity.individualNameFamilyName;
					pbObj.Lodge_Complaint_Date__c = pbRes.identity.lodgedComplaintReportedDate;
					pbObj.Lodged_Complaint__c = pbRes.identity.lodgedComplaint;
					pbObj.Middle_Name__c = pbRes.identity.individualNameOtherGivenName!=null && pbRes.identity.individualNameOtherGivenName.size()>0?pbRes.identity.individualNameOtherGivenName.get(0):null;
					pbObj.Name_First_Reported_Date__c = pbRes.identity.individualNameFirstReportedDate;
					pbObj.Name_Last_Reported_Date__c = pbRes.identity.individualNameLastReportedDate;
					eqWrap.posMatchList.add(pbObj);
				}
					//Parsing addresses for other Posssible matches
					if(pbRes.addresses!=null && pbRes.addresses.size()>0){
					for(ints.VedaComprehensiveResponse.Address addRes : pbRes.addresses){
						Address_for_Possible_Match__c addObj = new Address_for_Possible_Match__c();
						addObj.Country_Code__c = addRes.countryCode;
						addObj.First_Reported_Date__c = addRes.firstReportedDate;
						addObj.Last_Reported_Date__c = addRes.lastReportedDate;
						addObj.Post_Code__c = addRes.postcode;
						addObj.Property__c = addRes.property;
						addObj.State__c = addRes.state;
						addObj.Street_Name__c = addRes.streetName;
						addObj.Street_Number__c = addRes.streetNumber;
						addObj.Street_Type__c = addRes.streetType;
						addObj.Suburb__c = addRes.suburb;
						addObj.Type__c = addRes.type;
						addObj.Unit_Number__c = addRes.unitNumber;
						cmPb.sObjList.add(addObj);
					}
					}
					//Parsing employment details for other possible matches
					if(pbRes.employment!=null && pbRes.employment.size()>0){
					for(ints.VedaComprehensiveResponse.Employer empRes : pbRes.employment){
						Possible_Matches_Employer__c pbEmpObj = new Possible_Matches_Employer__c();
						pbEmpObj.Employement_Type__c = empRes.type;
						pbEmpObj.Employer_Name__c = empRes.name;
						pbEmpObj.First_Reported_Date__c = empRes.firstReportedDate;
						pbEmpObj.Last_Reported_Date__c = empRes.lastReportedDate;
						pbEmpObj.Occupation_Description__c = empRes.occupation;
						cmPb.sObjList.add(pbEmpObj);
					}
					}
					eqWrap.posMatchMap.add(cmPb);
				}
			}
			//Parsing fileNotes
			if(res.fileNotes!=null && res.fileNotes.size()>0){
				eqWrap.fnList = new List<File_Note__c>();
				eqWrap.fnMap = new List<Wrapper.CustomMap>();
				for(ints.VedaComprehensiveResponse.FileNote fnRes : res.fileNotes){
					if(fnRes!=null){
					File_Note__c fnObj = new File_Note__c();
					fnObj.Date_Recorded__c = fnRes.dateRecorded;
					fnObj.Note__c = fnRes.note;
					eqWrap.fnList.add(fnObj);
					if(fnRes.idReferences!=null && fnRes.idReferences.size()>0){
						Wrapper.CustomMap cmFn = new Wrapper.CustomMap();
						cmFn.sObjKey = fnObj;
						for(String idRef : fnRes.idReferences){
							File_Note_Id_Reference__c fnIdRef = new File_Note_Id_Reference__c();
							fnIdRef.Id__c = idRef;
							cmFn.sObjList.add(fnIdRef);
						}
						eqWrap.fnMap.add(cmFn);
					}
					}
				}
			}
			//Parsing business names
			if(res.businessNames!=null && res.businessNames.size()>0){
				eqWrap.bsnList = new List<Business_Name__c>();
				eqWrap.bsnMap = new List<Wrapper.CustomMap>();
				for(ints.VedaComprehensiveResponse.businessName bsnRes: res.businessNames){
					Business_Name__c bsnObj = new Business_Name__c();
					bsnObj.ABN__c = bsnRes.businessABN;
					bsnObj.Bureau_Reference__c = bsnRes.businessBureauReference;
					bsnObj.Last_Extract_Date__c = bsnRes.lastExtractDate;
					bsnObj.Last_Extract_Time__c = bsnRes.lastExtractTime;
					bsnObj.Last_Update_Date__c = bsnRes.lastUpdateDate;
					bsnObj.Last_Update_Time__c = bsnRes.lastUpdateTime;
					bsnObj.Name__c = bsnRes.businessName;
					bsnObj.Number__c = bsnRes.businessNumber;
					bsnObj.Previous_State_Or_Territory_Registration__c   = bsnRes.businessPreviousStateOrTerritoryRegistrationState;
					bsnObj.Start_Date__c = bsnRes.startDate;
					eqWrap.bsnList.add(bsnObj);
					if(bsnRes.idReferences!=null && bsnRes.idReferences.size()>0){
					Wrapper.CustomMap cmBsn = new Wrapper.CustomMap();
					cmBsn.sObjKey = bsnObj;
					for(String idRef : bsnRes.idReferences){
						Business_Name_Id_Reference__c bsnIdRef = new Business_Name_Id_Reference__c();
						bsnIdRef.Id__c = idRef;
						cmBsn.sObjList.add(bsnIdRef);
					}
					eqWrap.bsnMap.add(cmBsn);
					}
				}
			}
			//Parsing directorship
			if(res.directorships!=null && res.directorships.size()>0){
				eqWrap.dsList = new List<Directorship__c>();
				eqWrap.dsMap = new List<Wrapper.CustomMap>();
				for(ints.VedaComprehensiveResponse.Directorship dsRes : res.directorships){
					Directorship__c dsObj = new Directorship__c();
					dsObj.Date_Appointed__c = dsRes.dateAppointed;
					dsObj.Date_Ceased__c = dsRes.dateCeased;
					dsObj.Date_Last_Known_as_Director__c = dsRes.dateLastKnownAsDirector;
					dsObj.Last_Extract_Date__c = dsRes.lastExtractDate;
					dsObj.Last_Extract_Time__c = dsRes.lastExtractTime;
					dsObj.Last_Update_Date__c = dsRes.lastUpdateDate;
					dsObj.Last_Update_Time__c = dsRes.lastUpdateTime;
					dsObj.Name_Start_Date__c = dsRes.organisationABN;
					dsObj.Organizaion_Name__c = dsRes.organisationBureauReference;
					dsObj.Organization_ABN__c = dsRes.organisationName;
					dsObj.Organization_Bureau_Reference__c = dsRes.organisationNameStartDate;
					dsObj.Organization_Number__c = dsRes.organisationOrganisationNumber;
					dsObj.Organization_Status__c = dsRes.organisationStatus;
					dsObj.Organization_Status_Code__c = dsRes.organisationStatusCode;
					dsObj.Organization_Type__c = dsRes.organisationType;
					dsObj.Organization_Type_Code__c = dsRes.organisationTypeCode;
					dsObj.Type__c = dsRes.type;
					eqWrap.dsList.add(dsObj);
					if(dsRes.idReferences!=null && dsRes.idReferences.size()>0){
					Wrapper.CustomMap cmDs = new Wrapper.CustomMap();
					cmDs.sObjKey = dsObj;
					for(String idRef : dsRes.idReferences){
						Directorship_Id_Reference__c dsIdRef = new Directorship_Id_Reference__c();
						dsIdRef.Id__c = idRef;
						cmDs.sObjList.add(dsIdRef);
					}
					eqWrap.dsMap.add(cmDs);
					}
				}
			}
			//Parsing file ban report
			if(res.fileBanReport!=null){
				ecr.Is_FileBan__c = true;
				ecr.File_Ban_End_Date__c = res.fileBanReport.endDate;
				ecr.File_Ban_Is_Extended__c = res.fileBanReport.isExtended;
				ecr.File_BAn_Reported_Date__c = res.fileBanReport.reportedDate;
			}
			eqWrap.ecr = ecr;
		}
		return eqWrap;
	}

	//Edited prev method for party level 
	global static Wrapper.EquifaxHardpullDataWrapper2 parseVedaResponse2(ints.VedaComprehensiveResponse res){
	Wrapper.EquifaxHardpullDataWrapper2 eqWrap = new Wrapper.EquifaxHardpullDataWrapper2();
	//declaring data model to store response
	Equifax_Credit_Report__c ecr;
	List<Address__c> addrList;
	List<Error__c> errList;
	List<Employer__c> empList;
	List<Other_Identity__c> othList;
	Map<String,Object> fhiInfo = getfhiMap(res.xmlResponse);
	Map<Address__c,List<Address_Id_Reference__c>> addressIdRefMap = new  Map<Address__c,List<Address_Id_Reference__c>>();
	Map<Credit_Enquiry__c,List<Credit_Enquiry_Id_Reference__c>> credEnqRefIdMap = new Map<Credit_Enquiry__c,List<Credit_Enquiry_Id_Reference__c>>();
	Map<Equifax_Credit_Account__c,List<Equifax_Default__c>> accdefaultMap = new Map<Equifax_Credit_Account__c,List<Equifax_Default__c>>();
	Map<Equifax_Credit_Account__c,List<Repayment_History__c>> accRepayHistoryMap = new Map<Equifax_Credit_Account__c,List<Repayment_History__c>>();
	Map<Scorecard__c,List<Score_Contributing_Factor__c>> scoreAndFactorMap = new Map<Scorecard__c,List<Score_Contributing_Factor__c>>();
	Map<Data_Block__c,List<Characteristic__c>> dataVSCharacteristicsMap = new Map<Data_Block__c,List<Characteristic__c>>();
	
		if(res!=null){
			if(System_Configuration__c.getInstance().Save_Equifax_Hardpull_Request__c){//Checks org level permission to store raw request
			eqWrap.reqXml = res.xmlRequest;
			}
			if(System_Configuration__c.getInstance().Save_Equifax_Hardpull_Response__c){//Checks org level permisson to store raw response
			eqWrap.resXml = res.xmlResponse;
			}
		ecr  = new Equifax_Credit_Report__c();
		if(res.personalInsolvencies!=null){
			integer bankruptcy = res.personalInsolvencies.size();
			ecr.Bankruptcy__c = bankruptcy;
		}
		//System.debug('id===> ' + res.enquiryId);
      	ecr.Enquiry_ID__c= String.valueOf(res.enquiryId); // lmb-30
      	//System.debug('mappedid===> ' + ecr.Enquiry_ID__c);           
		ecr.Bureau_Reference_Number__c = res.bureauReference;
		ecr.Complaint_Reported_Date__c = res.lodgedComplaintReportedDate;
		ecr.Date_Of_Birth__c = res.dateOfBirth;
		ecr.DL_First_Reported_Date__c = res.driversLicenceFirstReportedDate;
		ecr.DL_Last_Reported_Date__c = res.driversLicenceLastReportedDate;
		ecr.DOB_First_Reported_Date__c = res.dateOfBirthFirstReportedDate;
		ecr.DOB_Last_Reported_Date__c = res.dateOfBirthLastReportedDate;
		ecr.Drivers_Licence_Number__c = res.driversLicenceNumber;
		ecr.First_Name__c = res.firstGivenName;
		ecr.First_Reported_Date__c = res.individualNameFirstReportedDate;
		ecr.Gender__c = res.gender;
		ecr.Gender_Code__c = res.genderCode;
		ecr.Is_Deceased__c = res.isDeceased;
		ecr.Is_Deceased_Reported_Date__c = res.isDeceasedReportedDate;
		ecr.Last_Name__c = res.familyName;
		ecr.Last_Reported_Date__c = res.individualNameLastReportedDate;
		ecr.Lodged_Complaint__c = res.lodgedComplaint;
		ecr.Middle_Name__c = res.OtherGivenName!=null && res.OtherGivenName.size()>0?res.OtherGivenName.get(0):null;
		ecr.Primary_Match_Id_Index__c = res.primaryMatchIdIndex;
		ecr.Primary_Match_Type__c =res.primaryMatchType;
		
		//Parsing Address
		if(res.addresses!=null && res.addresses.size()>0){
			eqWrap.addList = new List<Address__c>();
			eqWrap.addIdRefMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.Address addRes : res.addresses){
					Address__c add = new Address__c();
					add.Country_Code__c = addRes.countryCode;
					add.First_Reported_Date__c = addRes.firstReportedDate;
					add.Last_Reported_Date__c = addRes.lastReportedDate;
					add.Post_Code__c = addRes.postcode;
					add.Property__c = addRes.property;
					add.State__c = addRes.state;
					add.Street_Name__c = addRes.streetName;
					add.Street_Number__c = addRes.streetNumber;
					add.Street_Type__c = addRes.streetType;
					add.Suburb__c = addRes.suburb;
					add.Type__c = addRes.type;
					add.Unit_Number__c = addRes.unitNumber;
					eqWrap.addList.add(add);
					//addressIdRefMap.put(add,new List<Address_Id_Reference__c>());
					if(addRes.idReference!=null && addRes.idReference.size()>0){
						Wrapper.CustomMap cmAdd = new Wrapper.CustomMap();
						cmAdd.sObjKey = add;
						for(String idRef : addRes.idReference){
							Address_Id_Reference__c addIdRef = new Address_Id_Reference__c();
							addIdRef.Value__c = idRef;
							//addressIdRefMap.get(add).add(addIdRef);
							cmAdd.sObjList.add(addIdRef);
						}
						eqWrap.addIdRefMap.add(cmAdd);
					}
			}
		}
		//Parsing error records
		if(res.errors!=null && res.errors.size()>0){
			errList = new List<Error__c>();
			for(ints.VedaComprehensiveResponse.Error errRes : res.errors){
			Error__c err = new Error__c();
			err.Detail__c = errRes.detail;
			err.Fault_Actor__c = errRes.faultactor;
			err.Fault_Code__c = errRes.faultcode;
			err.Fault_String__c = errRes.faultstring;
			errList.add(err);
			}
			eqWrap.errList = errList;
		}

		if(res.generalMessages!=null){
			ecr.General_Message__c = res.generalMessages.message;
			ecr.General_Message_Code__c = res.generalMessages.message;
		}
		//Parsing credit enquiries
		if(res.creditEnquiries!=null && res.creditEnquiries.size()>0){
			eqWrap.credEnqList = new List<Credit_Enquiry__c>();
			eqWrap.credEnqIdRefMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.CreditEnquiry credEnqRes : res.creditEnquiries){
					Credit_Enquiry__c credEnqObj = new Credit_Enquiry__c();
					credEnqObj.Credit_Enquirer_Name__c = credEnqRes.creditEnquirerName;
					credEnqObj.Credit_Enquirer_Classification__c = credEnqRes.creditEnquirerClassification;
					credEnqObj.Co_Borrower__c = credEnqRes.coBorrower;
					credEnqObj.Account_Type__c = credEnqRes.accountType;
					credEnqObj.Code__c = credEnqRes.accountTypeCode;
					credEnqObj.Currency_Code__c = credEnqRes.enquiryAmountCurrencyCode;
					credEnqObj.Enquiry_Amount__c = credEnqRes.enquiryAmount;
					credEnqObj.Enquiry_Date__c = credEnqRes.enquiryDate;
					credEnqObj.Type__c = credEnqRes.type;
					eqWrap.credEnqList.add(credEnqObj);
					if(credEnqRes.idReferences!=null && credEnqRes.idReferences.size()>0){
						Wrapper.CustomMap cmCredEnq = new Wrapper.CustomMap();
						cmCredEnq.sObjKey = credEnqObj;
						for(String idRef : credEnqRes.idReferences){
							Credit_Enquiry_Id_Reference__c credEnqIdRefObj = new Credit_Enquiry_Id_Reference__c();
							credEnqIdRefObj.Value__c = idRef;
							cmCredEnq.sObjList.add(credEnqIdRefObj);
						}
						eqWrap.credEnqIdRefMap.add(cmCredEnq);
					}
			}
		}
		//Parsing Commercial Credit Eqnquiries
		if(res.commercialCreditFileCreditEnquiries!=null && res.commercialCreditFileCreditEnquiries.size()>0){
			//eqWrap.credEnqList = new List<Credit_Enquiry__c>();
			//eqWrap.credEnqIdRefMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.CreditEnquiry credEnqRes : res.commercialCreditFileCreditEnquiries){
					Credit_Enquiry__c credEnqObj = new Credit_Enquiry__c();
					credEnqObj.Credit_Enquirer_Name__c = credEnqRes.creditEnquirerName;
					credEnqObj.Credit_Enquirer_Classification__c = credEnqRes.creditEnquirerClassification;
					credEnqObj.Co_Borrower__c = credEnqRes.coBorrower;
					credEnqObj.Account_Type__c = credEnqRes.accountType;
					credEnqObj.Code__c = credEnqRes.accountTypeCode;
					credEnqObj.Currency_Code__c = credEnqRes.enquiryAmountCurrencyCode;
					credEnqObj.Enquiry_Amount__c = credEnqRes.enquiryAmount;
					credEnqObj.Enquiry_Date__c = credEnqRes.enquiryDate;
					credEnqObj.Type__c = credEnqRes.type;
					eqWrap.credEnqList.add(credEnqObj);
					if(credEnqRes.idReferences!=null && credEnqRes.idReferences.size()>0){
						Wrapper.CustomMap cmCredEnq = new Wrapper.CustomMap();
						cmCredEnq.sObjKey = credEnqObj;
						for(String idRef : credEnqRes.idReferences){
							Credit_Enquiry_Id_Reference__c credEnqIdRefObj = new Credit_Enquiry_Id_Reference__c();
							credEnqIdRefObj.Value__c = idRef;
							cmCredEnq.sObjList.add(credEnqIdRefObj);
						}
						eqWrap.credEnqIdRefMap.add(cmCredEnq);
					}
			}
		}

		//Parsing employer info
		if(res.employers!=null && res.employers.size()>0){
			empList = new List<Employer__c>();
			eqWrap.empIdRefMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.Employer empRes : res.employers){
					Employer__c empObj = new Employer__c();
					empObj.Employer_Name__c = empRes.name;
					empObj.Employment_Type__c = empRes.type;
					empObj.First_Reported_Date__c = empRes.firstReportedDate;
					empObj.Last_Reported_Date__c = empRes.lastReportedDate;
					empObj.Occupation_Description__c = empRes.occupation;
					empList.add(empObj);
					if(empRes.idReferences!=null && empRes.idReferences.size()>0){
					Wrapper.CustomMap cmEmp = new Wrapper.CustomMap();
					cmEmp.sObjKey = empObj;
					for(String idRef : empRes.idReferences){
						Employer_Id_Reference__c empIdRef = new Employer_Id_Reference__c();
						empIdRef.id__c = idRef;
						cmEmp.sObjList.add(empIdRef);
					}
					eqWrap.empIdRefMap.add(cmEmp);
					}
			}
			eqWrap.empList = empList;
		}
		//Parsing other identities
		if(res.otherIdentities!=null && res.otherIdentities.size()>0){
			othList = new List<Other_Identity__c>();
			for(ints.VedaComprehensiveResponse.OtherIdentity othRes : res.otherIdentities){
					Other_Identity__c oth = new Other_Identity__c();
					oth.First_Name__c = othRes.individualNameFirstGivenName;
					oth.Gender__c = othRes.gender;
					oth.Gender_Code__c = othRes.genderCode;
					oth.Is_Deceased__c = othRes.isDeceased;
					oth.Last_Name__c = othRes.individualNameFamilyName;
					if(othRes.individualNameOtherGivenName!=null && othRes.individualNameOtherGivenName.size()>0){
						oth.Middle_Name__c = othRes.individualNameOtherGivenName.get(0);
					}
					oth.Bureau_Reference_Number__c = othRes.bureauReference;
					oth.Date_of_Birth__c = othRes.dateOfBirth;
					oth.DL_First_Reported_Date__c = othRes.driversLicenceFirstReportedDate;
					oth.DL_Last_Reported_Date__c = othRes.driversLicenceLastReportedDate;
					oth.DOB_First_Reported_Date__c = othRes.dateOfBirthFirstReportedDate;
					oth.DOB_Last_Reported_Date__c = othRes.dateOfBirthLastReportedDate;
					oth.Drivers_Licence_Number__c = othRes.driversLicenceNumber;
					oth.Is_Deceased_Reported_Date__c = othRes.isDeceasedReportedDate;
					oth.Lodge_Complaint_Date__c = othRes.lodgedComplaintReportedDate;
					oth.Lodged_Complaint__c = othRes.lodgedComplaint;
					oth.Name_First_Reported_Date__c = othRes.individualNameFirstReportedDate;
					oth.Name_Last_Reported_Date__c = othRes.individualNameLastReportedDate;
					oth.Last_Enquiry_Date__c = othRes.individualNameLastCreditEnquiryDate;
					othList.add(oth);
			}
			eqWrap.othList = othList;
		}
		//Parsing accounts
		if(res!=NULL && res.accounts!=NULL && res.accounts.size()>0){
			eqWrap.eqCredAccList = new List<Equifax_Credit_Account__c>();
			eqWrap.eqCredAccMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.account acc:res.accounts){
					String accountId=acc.accountId;
					Equifax_Credit_Account__c Acct=new Equifax_Credit_Account__c();
					Acct.Account_Closed_Date__c=acc.accountClosedDate;
					Acct.Account_Data_Level__c=acc.accountDataLevel;
					Acct.Account_Holder_Count__c    =acc.accountHolderCount;
					Acct.Account_Id__c=acc.accountId;
					Acct.Account_Open_Date__c=acc.accountOpenDate;
					Acct.Account_Reopen_Date__c=acc.accountReopenDate;
					Acct.Account_Code__c=acc.accountTypeCode;
					Acct.Account_Type__c=acc.accountType;
					Acct.Association_Info_Latest_Ceased_Date__c=acc.associationInformationLatestCeasedDate;
					Acct.Association_Info_Latest_Start_Date__c=acc.associationInformationLatestStartDate;
					Acct.Association_Default_Cease_Date__c=acc.associationInformationDefaultAssociationCeaseDate;
					Acct.Association_Default_Start_Date__c=acc.associationInformationDefaultAssociationStartDate;
					Acct.Association_Info_Sci_Date__c=acc.associationInformationSciDate;
					Acct.Association_Info_Serious_Credit_Infrngmt__c=acc.associationInformationIsSeriousCreditInfringement;
					Acct.Date_Last_Changed__c=acc.dateLastChanged;
					Acct.Is_Unlimited_Credit__c=acc.isUnlimitedCredit;
					Acct.Name_of_Latest_Credit_Provider__c=acc.latestCreditProviderName;
					Acct.Latest_Max_Amount_Credit__c=acc.latestMaximumAmountCredit;
					Acct.Currency_Code_for_Latest_Max_Amt_Crdt__c=acc.latestMaximumAmountCreditCurrencyCode;
					Acct.Latest_Update_Date__c=acc.latestUpdateDate;
					Acct.Loan_Payment_Method__c=acc.loanPaymentMethod;
					Acct.Code_for_Loan_Payment_Method__c=acc.loanPaymentMethodCode;
					Acct.Classification_Original_Credit_Provider__c=acc.originalCreditProviderClassification;
					Acct.Is_License_of_Original_Credit_Provider__c=acc.originalCreditProviderIsLicensee;
					Acct.Name_Of_Original_Credit_Provider__c=acc.originalCreditProviderName;
					Acct.Original_Max_Amount_Credit__c=acc.originalMaximumAmountCredit;
					Acct.Currency_Code_for_Original_Max_Amt_Crdt__c=acc.originalMaximumAmountCreditCurrencyCode;
					Acct.Relation_of_Account_with_Individual__c=acc.relationship;
					Acct.Relationship_Code__c=acc.relationshipCode;
					Acct.Secured_Credit__c=acc.securedCredit;
					Acct.Code_for_Secured_Credit__c=acc.securedCreditCode;
					Acct.Term_of_Loan__c=acc.termOfLoan;
					Acct.Term_Type__c=acc.termType;
					Acct.Term_Code__c=acc.termTypeCode;
					eqWrap.eqCredAccList.add(acct);
					Wrapper.CustomMap cmCredAcc;
					//Parsing account defaults
					if(acc!=NULL && acc.defaults!=NULL && acc.defaults.size()>0){
						cmCredAcc = new Wrapper.CustomMap();
						cmCredAcc.sObjKey = acct;
						for(ints.VedaComprehensiveResponse.VedaComprehensivedefault VedaDef:acc.defaults){
							Equifax_Default__c EqFxDf= new Equifax_Default__c();
							EqFxDf.Code_for_Equifax_Default_Status__c=VedaDef.statusCode;
							EqFxDf.Current_Default_Amount__c=VedaDef.currentDefaultDefaultAmount;
							EqFxDf.Current_Default_Currency_Code__c=VedaDef.currentDefaultDefaultAmountCurrencyCode;
							EqFxDf.Current_Default_Date_Recorded__c=VedaDef.currentDefaultDateRecorded;
							EqFxDf.Current_Default_Reason_To_Report__c=VedaDef.currentDefaultReasonToReport;
							EqFxDf.Current_Default_Reason_To_Report_Code__c=VedaDef.currentDefaultReasonToReportCode;
							EqFxDf.Equifax_Default_Status_Date__c=VedaDef.statusDate;
							EqFxDf.Orginal_Default_Reason_To_Report__c=VedaDef.originalDefaultDefaultReasonToReport;
							EqFxDf.Original_Default_Amount__c=VedaDef.originalDefaultDefaultAmount;
							EqFxDf.Original_Default_Currency_Code__c=VedaDef.originalDefaultDefaultAmountCurrencyCode;
							EqFxDf.Original_Default_Date_Recorded__c=VedaDef.originalDefaultDateRecorded;
							EqFxDf.Original_Default_Reason_To_Report_Code__c=VedaDef.originalDefaultDefaultReasonToReportCode;
							EqFxDf.Status_of_Equifax_Default__c=VedaDef.status;     
							cmCredAcc.sObjList.add(EqFxDf);
						}
					}
					//Parsing account repayment history
					System.debug('Parsing Repayment history');
					if(acc!=NULL && acc.repaymentHistory!=NULL && acc.repaymentHistory.size()>0){
						System.debug('Repayment history => '+acc.repaymentHistory.size());
					if(cmCredAcc==null){
							cmCredAcc = new Wrapper.CustomMap();
							cmCredAcc.sObjKey = acct;
					}
					for(ints.VedaComprehensiveResponse.payment payHistory:acc.repaymentHistory){
							Repayment_History__c RepayH =new Repayment_History__c();
							//This block was added as a part of SYM-3473 to capture the fhi info corresponding to the repayment period using the map returned from the function 
							Map<String,Object> mMap= (Map<String,Object>)fhiInfo.get(accountId);
							//Mmap gives us the repayment period and the fhi indicator
							if(mMap!=null){
								String period=payHistory.period;
								//If that particular repayment period has an indicator, we capture it in our system
								String val =(String)mMap.get(period);
								if(val!=null){
									RepayH.Fhi__c=val;
								}
							}
							RepayH.Status__c=payHistory.status;
							RepayH.Period__c=payHistory.period;
							cmCredAcc.sObjList.add(RepayH);     
					   }
					}
					if(cmCredAcc!=null){
						eqWrap.eqCredAccMap.add(cmCredAcc);
						System.debug('eqWrap.eqCredAccMap.size() ==>> '+eqWrap.eqCredAccMap.size());
					}                                                                                                                
				}
		}
		//Parsing Score data
		if(res!=NULL && res.scoreData!=NULL && res.scoreData.size()>0){
			eqWrap.scrList = new List<Scorecard__c>();      
			eqWrap.scrConFacMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.Score sData:res.scoreData){       
				Scorecard__c scoreC=new Scorecard__c();
				scoreC.Data_Level__c=sData.scoreDataLevel;
				scoreC.Code_Associated_with_Data_Level__c=sData.scoreDataLevelCode;
				scoreC.Id__c=sData.scoreId;
				scoreC.Name__c=sData.scoreName;
				scoreC.Version__c=sData.scoreVersion;
				scoreC.Type__c=sData.scorType;
				ecr.Risk_Odds__c=sData.riskOdds;
				ecr.Score_Masterscale__c=sData.scoreMasterscale;
				eqWrap.scrList.add(scoreC);
				//Parsing contributing factors
				if(sData!=NULL && sData.contributingFactor!=NULL && sData.contributingFactor.size()>0){
					Wrapper.CustomMap cmScr = new Wrapper.CustomMap(); 
					cmScr.sObjKey = scoreC;
					for(ints.VedaComprehensiveResponse.ContributingFactor conFact: sData.contributingFactor){
						Score_Contributing_Factor__c factor= new Score_Contributing_Factor__c();
						factor.Description__c=conFact.description;
						factor.Id__c=conFact.contributingFactorId;
						factor.Name__c=conFact.name;
						factor.Score_Impactor__c=conFact.scoreImpactor;
						cmScr.sObjList.add(factor);
					}
					eqWrap.scrConFacMap.add(cmScr);                   
				}
			}
		}
		//Parsing summary data
		if(res.summaryData!=NULL && res!=NULL && res.summaryData.size()>0){
			eqWrap.dbList = new List<Data_Block__c>();
			eqWrap.dbMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.DataBlock dB : res.summaryData){
			Data_Block__c DBlock= new Data_Block__c();
			DBlock.Name__c=dB.name;
			DBlock.Type__c=dB.type;
			eqWrap.dbList.add(dBlock);
			if(dB.characteristic!=NULL && dB!=NULL && dB.characteristic.size()>0){
				Wrapper.CustomMap cmDb = new Wrapper.CustomMap();
				cmDb.sObjKey = dBlock;
				for(ints.VedaComprehensiveResponse.Characteristic cha:dB.characteristic){
					Characteristic__c chara=new Characteristic__c();
					chara.Code_For_Data_Level__c=cha.dataLevelCode;
					chara.Data_Level__c=cha.dataLevel;
					chara.Description__c=cha.description;
					chara.Id__c=cha.characteristicId;
					chara.Key_Characteristic__c=cha.keyCharacteristic;
					chara.Unit_For_Value__c=cha.unit;
					chara.Value__c=cha.value;
					chara.Variable_Name__c=cha.variableName;
					cmDb.sObjList.add(chara);
				}
				eqWrap.dbMap.add(cmDb);
			}
			}
		}
		//Parsing other possible matches
		if(res.possibleMatches!=null && res.possibleMatches.size()>0){
			eqWrap.posMatchList = new List<Possible_Match__c>();
			eqWrap.posMatchMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.possibleMatch pbRes : res.possibleMatches){
			Wrapper.CustomMap cmPb = new Wrapper.CustomMap();
			Possible_Match__c pbObj = new Possible_Match__c();
			cmPb.sObjKey = pbObj;
			if(pbRes.identity!=null){
				pbObj.Bureau_Reference_Number__c = pbRes.identity.bureauReference;
				pbObj.Date_Of_Birth__c = pbRes.identity.dateOfBirth;
				pbObj.DL_First_Reported_Date__c = pbRes.identity.driversLicenceFirstReportedDate;
				pbObj.DL_Last_Reported_Date__c = pbRes.identity.driversLicenceLastReportedDate;
				pbObj.DOB_First_Reported_Date__c = pbRes.identity.dateOfBirthFirstReportedDate;
				pbObj.DOB_Last_Reported_Date__c = pbRes.identity.dateOfBirthFirstReportedDate;
				pbObj.Drivers_Licence_Number__c = pbRes.identity.driversLicenceNumber;
				pbObj.First_Name__c = pbRes.identity.individualNameFirstGivenName;
				pbObj.Gender__c = pbRes.identity.gender;
				pbObj.Gender_Code__c = pbRes.identity.genderCode;
				pbObj.Id_Index__c = pbRes.identity.idIndex;
				pbObj.Is_Deceased__c = pbRes.identity.isDeceased;
				pbObj.Is_Deceased_Reported_Date__c = pbRes.identity.isDeceasedReportedDate;
				pbObj.Last_Enquiry_Date__c = pbRes.identity.individualNameLastCreditEnquiryDate;
				pbObj.Last_Name__c = pbRes.identity.individualNameFamilyName;
				pbObj.Lodge_Complaint_Date__c = pbRes.identity.lodgedComplaintReportedDate;
				pbObj.Lodged_Complaint__c = pbRes.identity.lodgedComplaint;
				pbObj.Middle_Name__c = pbRes.identity.individualNameOtherGivenName!=null && pbRes.identity.individualNameOtherGivenName.size()>0?pbRes.identity.individualNameOtherGivenName.get(0):null;
				pbObj.Name_First_Reported_Date__c = pbRes.identity.individualNameFirstReportedDate;
				pbObj.Name_Last_Reported_Date__c = pbRes.identity.individualNameLastReportedDate;
				eqWrap.posMatchList.add(pbObj);
			}
			//Parsing addresses for other Posssible matches
			if(pbRes.addresses!=null && pbRes.addresses.size()>0){
				for(ints.VedaComprehensiveResponse.Address addRes : pbRes.addresses){
					Address_for_Possible_Match__c addObj = new Address_for_Possible_Match__c();
					addObj.Country_Code__c = addRes.countryCode;
					addObj.First_Reported_Date__c = addRes.firstReportedDate;
					addObj.Last_Reported_Date__c = addRes.lastReportedDate;
					addObj.Post_Code__c = addRes.postcode;
					addObj.Property__c = addRes.property;
					addObj.State__c = addRes.state;
					addObj.Street_Name__c = addRes.streetName;
					addObj.Street_Number__c = addRes.streetNumber;
					addObj.Street_Type__c = addRes.streetType;
					addObj.Suburb__c = addRes.suburb;
					addObj.Type__c = addRes.type;
					addObj.Unit_Number__c = addRes.unitNumber;
					cmPb.sObjList.add(addObj);
				}
			}
			//Parsing employment details for other possible matches
			if(pbRes.employment!=null && pbRes.employment.size()>0){
				for(ints.VedaComprehensiveResponse.Employer empRes : pbRes.employment){
					Possible_Matches_Employer__c pbEmpObj = new Possible_Matches_Employer__c();
					pbEmpObj.Employement_Type__c = empRes.type;
					pbEmpObj.Employer_Name__c = empRes.name;
					pbEmpObj.First_Reported_Date__c = empRes.firstReportedDate;
					pbEmpObj.Last_Reported_Date__c = empRes.lastReportedDate;
					pbEmpObj.Occupation_Description__c = empRes.occupation;
					cmPb.sObjList.add(pbEmpObj);
				}
			}
			eqWrap.posMatchMap.add(cmPb);
			}
		}
		//Parsing fileNotes
		if(res.fileNotes!=null && res.fileNotes.size()>0){
			eqWrap.fnList = new List<File_Note__c>();
			eqWrap.fnMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.FileNote fnRes : res.fileNotes){
			if(fnRes!=null){
				File_Note__c fnObj = new File_Note__c();
				fnObj.Date_Recorded__c = fnRes.dateRecorded;
				fnObj.Note__c = fnRes.note;
				eqWrap.fnList.add(fnObj);
				if(fnRes.idReferences!=null && fnRes.idReferences.size()>0){
					Wrapper.CustomMap cmFn = new Wrapper.CustomMap();
					cmFn.sObjKey = fnObj;
					for(String idRef : fnRes.idReferences){
					File_Note_Id_Reference__c fnIdRef = new File_Note_Id_Reference__c();
					fnIdRef.Id__c = idRef;
					cmFn.sObjList.add(fnIdRef);
					}
					eqWrap.fnMap.add(cmFn);
				}
			}
			}
		}
		//Parsing business names
		if(res.businessNames!=null && res.businessNames.size()>0){
			eqWrap.bsnList = new List<Business_Name__c>();
			eqWrap.bsnMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.businessName bsnRes: res.businessNames){
			Business_Name__c bsnObj = new Business_Name__c();
			bsnObj.ABN__c = bsnRes.businessABN;
			bsnObj.Bureau_Reference__c = bsnRes.businessBureauReference;
			bsnObj.Last_Extract_Date__c = bsnRes.lastExtractDate;
			bsnObj.Last_Extract_Time__c = bsnRes.lastExtractTime;
			bsnObj.Last_Update_Date__c = bsnRes.lastUpdateDate;
			bsnObj.Last_Update_Time__c = bsnRes.lastUpdateTime;
			bsnObj.Name__c = bsnRes.businessName;
			bsnObj.Number__c = bsnRes.businessNumber;
			bsnObj.Previous_State_Or_Territory_Registration__c   = bsnRes.businessPreviousStateOrTerritoryRegistrationState;
			bsnObj.Start_Date__c = bsnRes.startDate;
			eqWrap.bsnList.add(bsnObj);
			if(bsnRes.idReferences!=null && bsnRes.idReferences.size()>0){
				Wrapper.CustomMap cmBsn = new Wrapper.CustomMap();
				cmBsn.sObjKey = bsnObj;
				for(String idRef : bsnRes.idReferences){
					Business_Name_Id_Reference__c bsnIdRef = new Business_Name_Id_Reference__c();
					bsnIdRef.Id__c = idRef;
					cmBsn.sObjList.add(bsnIdRef);
				}
				eqWrap.bsnMap.add(cmBsn);
			}
			}
		}
		//Parsing directorship
		if(res.directorships!=null && res.directorships.size()>0){
			eqWrap.dsList = new List<Directorship__c>();
			eqWrap.dsMap = new List<Wrapper.CustomMap>();
			for(ints.VedaComprehensiveResponse.Directorship dsRes : res.directorships){
			Directorship__c dsObj = new Directorship__c();
			dsObj.Date_Appointed__c = dsRes.dateAppointed;
			dsObj.Date_Ceased__c = dsRes.dateCeased;
			dsObj.Date_Last_Known_as_Director__c = dsRes.dateLastKnownAsDirector;
			dsObj.Last_Extract_Date__c = dsRes.lastExtractDate;
			dsObj.Last_Extract_Time__c = dsRes.lastExtractTime;
			dsObj.Last_Update_Date__c = dsRes.lastUpdateDate;
			dsObj.Last_Update_Time__c = dsRes.lastUpdateTime;
			dsObj.Name_Start_Date__c = dsRes.organisationABN;
			dsObj.Organizaion_Name__c = dsRes.organisationBureauReference;
			dsObj.Organization_ABN__c = dsRes.organisationName;
			dsObj.Organization_Bureau_Reference__c = dsRes.organisationNameStartDate;
			dsObj.Organization_Number__c = dsRes.organisationOrganisationNumber;
			dsObj.Organization_Status__c = dsRes.organisationStatus;
			dsObj.Organization_Status_Code__c = dsRes.organisationStatusCode;
			dsObj.Organization_Type__c = dsRes.organisationType;
			dsObj.Organization_Type_Code__c = dsRes.organisationTypeCode;
			dsObj.Type__c = dsRes.type;
			eqWrap.dsList.add(dsObj);
			if(dsRes.idReferences!=null && dsRes.idReferences.size()>0){
				Wrapper.CustomMap cmDs = new Wrapper.CustomMap();
				cmDs.sObjKey = dsObj;
				for(String idRef : dsRes.idReferences){
					Directorship_Id_Reference__c dsIdRef = new Directorship_Id_Reference__c();
					dsIdRef.Id__c = idRef;
					cmDs.sObjList.add(dsIdRef);
				}
				eqWrap.dsMap.add(cmDs);
			}
			}
		}
		//Parsing file ban report
		if(res.fileBanReport!=null){
			ecr.Is_FileBan__c = true;
			ecr.File_Ban_End_Date__c = res.fileBanReport.endDate;
			ecr.File_Ban_Is_Extended__c = res.fileBanReport.isExtended;
			ecr.File_BAn_Reported_Date__c = res.fileBanReport.reportedDate;
		}
		eqWrap.ecr = ecr;
	}
	return eqWrap;
}

	//Function that puts master record id in the child records
	global static List<SObject> mapChildWithParents(List<SObject> parSObjList, List<Wrapper.CustomMap> customMapList, id parentMasterId, String parentMasterFieldName, String childMasterFieldName){
	List<SOBJECT> childSObjList = new List<SObject>();
	if(parSObjList!=null && parSObjList.size()>0){
		for(SObject parSobj : parSObjList){
			parSobj.put(parentMasterFieldName, parentMasterId);
		}
		insert parSObjList;
		if(customMapList!=null && customMapList.size()>0){
			for(Wrapper.CustomMap cm : customMapList){
			for(SObject childSObj : cm.SObjList){
				childSObj.put(childMasterFieldName,cm.SObjKey.Id);
				childSObjList.add(childSObj);
			}
			}
		}
	}
	return childSObjList;
	}
	//Accepts parsed in a wrapper and inserts data model
	global static void createEquifaxHardpullResponseRecord(Wrapper.EquifaxHardpullDataWrapper eqWrap){
	if(eqWrap!=null){
		if(eqWrap.ecr!=null){
			eqWrap.ecr.Application__c = eqWrap.appId; //Mapping application record id with credit report record
			eqWrap.ecr.Account__c = eqWrap.accId; //Mapping account record id with credit report record
			insert eqWrap.ecr;//inserts record
			//EquifaxCreditPullCallout.searchHits(eqWrap.ecr.id); // lmb-30
			if(eqWrap.resXml!=null){
			//gets attachment record for raw response body.
			eqWrap.reqResXml.add(FlowfiUtil.getAttachment(eqWrap.appId, 'text/xml','Equifax Response '+DateTime.Now()+'.xml',eqWrap.resXml));
			}
			if(eqWrap.reqXml!=null){
			//gets attachment record for raw request body.
			eqWrap.reqResXml.add(FlowfiUtil.getAttachment(eqWrap.appId, 'text/xml','Equifax Request '+DateTime.Now()+'.xml',eqWrap.reqXml));
			}
			if(eqWrap.reqResXml.size()>0){
			//insertion of attachment records
			try{
				insert eqWrap.reqResXml;
			} catch (Exception e){
				ExceptionManager.manageException(e);
				insert ExceptionManager.getClCommonLog(e, ResponseMessenger.genesis);
			}
			
			}
			if(eqWrap.errList!=null && eqWrap.errList.size()>0){
			//checks for available error list
			for(Error__c err : eqWrap.errList){
				err.Equifax_Credit_Report__c = eqWrap.ecr.id;
			}
			insert eqWrap.errList;
			}
			if(eqWrap.othList!=null && eqWrap.othList.size()>0){
			//checks for available Other Identity list
			for(Other_Identity__c oth : eqWrap.othList){
				oth.Equifax_Credit_Report__c = eqWrap.ecr.id;
			}
			insert eqWrap.othList;
			}
			List<Sobject> sobjList1 = new List<SObject>();
			List<Sobject> sobjList2 = new List<SObject>();
			//adds up all the child records in a single list to minimise soql statement
			sobjList1.addAll(mapChildWithParents(eqWrap.empList,eqWrap.empIdRefMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Employer__c'));
			sobjList1.addAll(mapChildWithParents(eqWrap.addList,eqWrap.addIdRefMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Address__c'));
			sobjList1.addAll(mapChildWithParents(eqWrap.credEnqList,eqWrap.credEnqIdRefMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Credit_Enquiry__c'));
			sobjList1.addAll(mapChildWithParents(eqWrap.scrList,eqWrap.scrConFacMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Scorecard__c'));
			sobjList1.addAll(mapChildWithParents(eqWrap.dbList,eqWrap.dbMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Data_Block__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.eqCredAccList,eqWrap.eqCredAccMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Equifax_Credit_Account__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.posMatchList,eqWrap.posMatchMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Possible_Match__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.fnList,eqWrap.fnMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','File_Note__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.bsnList,eqWrap.bsnMap,eqWrap.ecr.id,'Equifax_Credit_Report__c','Business_Name__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.dsList,eqWrap.dsMap,eqWrap.ecr.id,'Equifax_Credit_Report__c','Directorship__c'));
			
			if(sobjList1.size()>0)
			insert sobjList1;
			if(sobjList2.size()>0)
			insert sobjList2;
		}
	}
	}
	//EquifaxHardpullResponseRecord2 in used for party level access
	global static void createEquifaxHardpullResponseRecord2(Wrapper.EquifaxHardpullDataWrapper2 eqWrap){
	if(eqWrap!=null){
		if(eqWrap.ecr!=null){
			eqWrap.ecr.Application__c = eqWrap.appId; //Mapping application record id with credit report record
			eqWrap.ecr.Account__c = eqWrap.accId; //Mapping account record id with credit report record
			eqWrap.ecr.Party__c = eqWrap.partyId; //Mapping party record id with credit report record
			insert eqWrap.ecr;//inserts record
			//EquifaxCreditPullCallout.searchHits(eqWrap.ecr.id); // lmb-30
			if(eqWrap.resXml!=null){
			//gets attachment record for raw response body.
			eqWrap.reqResXml.add(FlowfiUtil.getAttachment(eqWrap.partyId, 'text/xml','Equifax Response '+eqWrap.accName+' '+DateTime.Now()+'.xml',eqWrap.resXml));
			System.debug('resXML added');
			}
			if(eqWrap.reqXml!=null){
			//gets attachment record for raw request body.
			try{
				eqWrap.reqResXml.add(FlowfiUtil.getAttachment(eqWrap.partyId, 'text/xml','Equifax Request '+eqWrap.accName+' '+DateTime.Now()+'.xml',eqWrap.reqXml));
			}catch(Exception e){
				ExceptionManager.manageException(e);
				insert ExceptionManager.getClCommonLog(e,ResponseMessenger.Genesis);
			}
			System.debug('reqXML added');
			}
			if(eqWrap.reqResXml.size()>0){
			//insertion of attachment records
			try{
			insert eqWrap.reqResXml;
			} catch(Exception e){
				ExceptionManager.manageException(e);
				insert ExceptionManager.getClCommonLog(e,ResponseMessenger.Genesis);
			}
			System.debug('reqResXML inserted at ===> ' + eqWrap.appId);
			}
			if(eqWrap.errList!=null && eqWrap.errList.size()>0){
			//checks for available error list
			for(Error__c err : eqWrap.errList){
				err.Equifax_Credit_Report__c = eqWrap.ecr.id;
			}
			insert eqWrap.errList;
			}
			if(eqWrap.othList!=null && eqWrap.othList.size()>0){
			//checks for available Other Identity list
			for(Other_Identity__c oth : eqWrap.othList){
				oth.Equifax_Credit_Report__c = eqWrap.ecr.id;
			}
			insert eqWrap.othList;
			}
			List<Sobject> sobjList1 = new List<SObject>();
			List<Sobject> sobjList2 = new List<SObject>();
			//adds up all the child records in a single list to minimise soql statement
			sobjList1.addAll(mapChildWithParents(eqWrap.empList,eqWrap.empIdRefMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Employer__c'));
			sobjList1.addAll(mapChildWithParents(eqWrap.addList,eqWrap.addIdRefMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Address__c'));
			sobjList1.addAll(mapChildWithParents(eqWrap.credEnqList,eqWrap.credEnqIdRefMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Credit_Enquiry__c'));
			sobjList1.addAll(mapChildWithParents(eqWrap.scrList,eqWrap.scrConFacMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Scorecard__c'));
			sobjList1.addAll(mapChildWithParents(eqWrap.dbList,eqWrap.dbMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Data_Block__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.eqCredAccList,eqWrap.eqCredAccMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Equifax_Credit_Account__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.posMatchList,eqWrap.posMatchMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','Possible_Match__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.fnList,eqWrap.fnMap,eqWrap.ecr.Id,'Equifax_Credit_Report__c','File_Note__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.bsnList,eqWrap.bsnMap,eqWrap.ecr.id,'Equifax_Credit_Report__c','Business_Name__c'));
			sobjList2.addAll(mapChildWithParents(eqWrap.dsList,eqWrap.dsMap,eqWrap.ecr.id,'Equifax_Credit_Report__c','Directorship__c'));
			
			if(sobjList1.size()>0)
			insert sobjList1;
			if(sobjList2.size()>0)
			insert sobjList2;
		}
	}
	}

	/**
   * getfhiMap      : This method was added as a part of SYM-3473 to parse FHI Information in repayment list of Equifax accounts.
	* @modified on   : 10/08/2022
	* @params        : String param
	* @returnType    : Map<String,Object>
	**/

	global static Map<String,Object> getfhiMap(String apiPayload){
		Map<String,Object> fhiInfo = new Map<String,Object>();
		try{
			Dom.Document doc = new Dom.Document();
			//We add the request body in a DOM object to use the framework's method XmlToJson to parse the document into a map
			doc.load(apiPayload);
			Map<String, Object> responseMap = intframework.XmlToJson.parseDocumentToMap(doc);
			Map<String,Object> transitMap = new Map<String,Object>();
			Map<String,Object> Body = new Map<String,Object>();
			Map<String,Object> response = new Map<String,Object>();
			Map<String,Object> proddata = new Map<String,Object>();
			Map<String,Object> enquiryreport = new Map<String,Object>();
			Map<String,Object> consumercreditfile  = new Map<String,Object>();
			Map<String,Object> accounts  = new Map<String,Object>();
			List<Object> accountList = new List<Object>();
			if(responseMap!=null){
				transitMap = (Map<String,Object>)responseMap.get(CpConstants.ENVELOPE);
		   }
			if(transitMap!=null){
				Body = (Map<String,Object>)transitMap.get(CpConstants.BODY);
		   }
			if(Body!=null){
				response =(Map<String,Object>)Body.get(CpConstants.response);
		   }
			if(response!=null){
				proddata =(Map<String,Object>)response.get(CpConstants.PRODUCT_DATA);
		   }
			if(proddata!=null){
				enquiryreport =(Map<String,Object>)proddata.get(CpConstants.ENQUIRYREPORT);
		   }
			if(enquiryreport!=null){
				consumercreditfile =(Map<String,Object>)enquiryreport.get(CpConstants.CONSUMERCREDITFILE);
		   }
			if(consumercreditfile!=null){
				accounts =(Map<String,Object>)consumercreditfile.get(CpConstants.ACCOUNTS);
		    }
			if(accounts!=null){
				try{
					accountList = (List<Object>)accounts.get(CpConstants.ACCOUNT);
				}catch (Exception e){
					Map<String,Object> account =(Map<String,Object>)accounts.get(CpConstants.ACCOUNT);
					accountList.add(account);
				}
		    }
			if(accountList.size()>0){
				for(Object o: accountList){
					//We shall parse all the Equifax accounts from the response received
					Map<String,Object> account = (Map<String,Object>)o;
					Map<String,String> periodFhi = new Map<String,String>();
					Boolean fhiPresent=false;//This variable is used to mark if any fhi indicator is there, on the basis of this we return a map to our main parsing function
					Map<String,Object> accIdNode= (Map<String,Object>)account.get(CpConstants.ACCOUNTID);
					Map<String,Object> repayment = new Map<String,Object>();
					List<Object> repaymentlist= new List<Object>();
					String accountid;
					if(accIdNode!=null){
						accountid= (String)accIdNode.get(CpConstants.NODEVALUE);
					}
					if(String.isNotBlank(accountid)){
						repayment = (Map<String,Object>)account.get(CpConstants.REPAYMENTHISTORY);
					}
					if(repayment!=null){
						repaymentlist = (List<Object>)repayment.get(CpConstants.PAYMENT);
					}
					if(repaymentlist.size()>0){
						for(Object rep: repaymentlist){
							//We parse through all the repayment objects of the current account
							Map<String,Object> repaymenteach = (Map<String,Object>)rep;
							if(repaymenteach!=null){
								if(repaymenteach.keySet().size()>3){
									//Here, if the there are more than 3 keys, it implies that we have fhi information, which needs to be parsed
									Map<String,Object> additionaldatafields = (Map<String,Object>)repaymenteach.get(CpConstants.ADDITIONALDATAFIELD);
									Map<String,Object> datafield = new Map<String,Object>();
									Map<String,Object> key = new Map<String,Object>();
									String  keyVal;
									if(additionaldatafields!=null){
										datafield = (Map<String,Object>)additionaldatafields.get(CpConstants.DATAFIELD);
									}
									if(datafield!=null){
										key = (Map<String,Object>)datafield.get(CpConstants.KEY);
									}
									if(key!=null){
										keyVal = (String)key.get(CpConstants.NODEVALUE);
									}
									if(String.isNotBlank(keyVal)){
										if(keyVal.equals(CpConstants.FINHARDSHIP)){
											//If the key has the parameter of financial hardship, then only we add the details in the map
											fhiPresent=true; //This variable just indicates thet our response has a harship information
											Map<String,Object> val = (Map<String,Object>)datafield.get(CpConstants.VALUE);
											Map<String,Object> period = (Map<String,Object>)repaymenteach.get(CpConstants.PERIOD);
											String  periodVal;
											if(period!=null){
												periodVal = (String)period.get(CpConstants.NODEVALUE);
											}
											if(val!=null){
												String  Value = (String)val.get(CpConstants.NODEVALUE);
												// We add period value as key and corresponding Harship indicator because periods are unique to the repayment information to each account
												periodFhi.put(periodVal,Value);
											}
										}									
									}	
								}							
							}
						}					
					}if(fhiPresent){
						//Finally, if the harship information is there, we add the map of harship period and the indicator to each account
						fhiInfo.put(accountid,periodFhi);
					}
				}		  
			}
		}catch (Exception ex) {
			ExceptionManager.manageException(ex);
			insert ExceptionManager.getCLCommonLog(ex,ResponseMessenger.INTFRAMEWORK);
	   }
		return fhiInfo;
	}
}