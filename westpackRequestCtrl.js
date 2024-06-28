/** ****************************************************************************************************************
 * Name                 :   westpackRequestCtrl
 * Description          :   This controller will handle the SF request for Westpack file parsing and recod manupulation.
 * Developer            :   Kiranmoy Pradhan
 * Last Modified By     :   Kiranmoy Pradhan
 * Created Date         :   16/02/2023
 ***************************************************************************************************************** */

 import fs from "fs";
 import readline from "readline";
 import {
   genApiResponse,
   genErrorDetailsStr,
 } from "../../services/utils/helperUtilService";
 import { handleResponseStringified } from "../../services/web/responseWebService";
 import {
   crtBpayRecordApiCall,
   crtLptReversalRecordApiCall,
   wpGetLoanAccListApiCall,
   getLptListApiCall,
   getWpDocumentApiCall,
   updateLptListApiCall,
   wpLogRecUpdateApiCall,
   wpTriggerBatchExeSfPltEveApiCall,
   getBpayRecordTypeApiCall,
 } from "../../services/web/api/westpack-api/westpacApiCall";
 import {
   BA_ID_STR,
   BLANK_STR,
   BPAY_HEADER_ORG_NAME,
   BPAY_MODE,
   CRN_ID_STR,
   DEEDS_STR,
   DERPS_STR,
   DE_RET_LPT_DATA_TYPE,
   DE_RET_DDI_DATA_TYPE,
   DE_RET_SBI_DATA_TYPE,
   FILE_READ_LINE_EVENTS,
   INT_10_STR,
   INT_6_STR,
   REGEX_NEW_LINE,
   SENT_EMAIL_TO_CUSTOMER,
   SENT_EMAIL_TO_DEVELOPER,
   SERVICE_NAME_WESTPAC,
   SF_BPAY_PROCESS_BATCH_NAME,
   SF_LPT_REVERSAL_BATCH_NAME,
   SPACE_STR,
   SUCCESS_STR,
   UTF_8_STR,
   WP_BANK_REJECT_REPORT_NAME,
   WP_DDI_REVERSAL_CSV_REPORT_HEADERS,
   WP_DDI_STR,
   WP_FILE_TYPE_BPAY,
   WP_FILE_TYPE_DE_EXCP,
   WP_FILE_TYPE_DE_RET,
   WP_LOCAL_FILES_ROOT_DIRECTORY,
   WP_PASS_CODE,
   WP_REFUND_REVERSAL_CSV_REPORT_HEADERS,
   WP_REVERSAL_CODE,
   WP_WERPS_CODE_DETAILS,
   REJECTED_TXN_DATA_STORE_REC_TYPE,
   BPAY_TXN_DATA_STORE_REC_TYPE,
   DIRECT_CREDIT,
   CRN_NOT_FOUND_IN_LOAN,
   WP_FILE_TYPE_BPAY_RECALL,
   SERVICE_NAME_REPORT,
   SF_LOAN_DISBURSAL_TXN_DISTRIBUTION_QUERY,
   COMMA_INSIDE_SINGLE_INV_STR,
   SF_LOAN_BANK_ACC_USING_BSB_NUM_QUERY,
   SF_LOAN_OTHER_TRAN_USING_LOAN_ACC_QUERY,
   LOAN_TRAN_TYPE_REFUND_STR,
   SF_LOAN_ACC_FETCH_USING_CRN_QUERY,
   SF_LOAN_ACC_FETCH_USING_BOR_ACH_QUERY,
 } from "../../services/utils/constantUtilService";
 import {
   getCurrSysDateApiCall,
   reportInsertInDocumentApiCall,
   sfLoggingEventTriggerApiCall,
 } from "../../services/web/api/utils-api/sfUtilApiCall";
 import logger from "../../services/utils/loggerUtilService";
 import {
   createDirectorySyncInLocal,
   isFileOrFolderPresent,
   writeFileSyncInLocal,
 } from "../../services/utils/fileOperationsUtilService";
 import { BadRequest, BaseError } from "../../services/web/errorWebService";
 import {
   CURRENT_SYSTEM_DATE_NOT_FOUND_MSG,
   FAILED_TO_READ_FILE_MSG,
   REPORT_GEN_FAILED_MSG,
   WP_BATCH_EXECUTION_SF_EVENT_TRIGGER_FAILED_MSG,
   WP_DOCUMENT_NOT_FOUND_MSG,
   WP_LPT_REVERSAL_RECORD_INSERTION_FAILED_MSG,
   WP_WPFILE_PARSED_DATA_ARRAY_EMPTY_MSG,
   WP_WPLOG_UPDATE_FAILED_MSG,
   BULK_DATA_QUERY_FAILED,
 } from "../../services/utils/msgUtilService";
 import { generateCsvFileString } from "../../services/utils/csvGeneratorUtilService";
 import { sfAsyncQueryHugeDataAndProcess } from "../../services/web/requestWebService";
 
 /** ********
  // VARIABLES
 *********** */
 
 let ddiReportInsertStatus;
 let wpApiReqParamsForDdi;
 let dateFromDocHeaderForRep;
 let deRateLptRevInsertStatus;
 let deRateSbiRefReportStatus;
 const ddiDetArr = [];
 const sbiRefDetArr = [];
 
 /** ********
     // HELPERS
     *********** */
 
 /* ERROR HANDLER */
 const hugeDataQueryErrHandler = (err) => {
   logger.info("***** hugeDataQueryErrHandler() START *****");
   if (err) {
     logger.error(`MSG: DATA QUERY FAILED. ERROR : ${err?.message}`);
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_REPORT,
       genErrorDetailsStr(
         hugeDataQueryErrHandler.name,
         BULK_DATA_QUERY_FAILED,
         `DDI_Reversal Report`
       )
     );
   }
 };
 
 /** ******
   // UTILS
  ********* */
 /* WP FILE CONTENT HEADER CONTENT CHECK */
 const isHeader = (dataStr) => {
   try {
     if (!dataStr || dataStr.length <= 0) return false;
     // eslint-disable-next-line no-plusplus
     for (let index = 0; index < BPAY_HEADER_ORG_NAME.length; index++) {
       if (dataStr.includes(BPAY_HEADER_ORG_NAME[index])) {
         // Return true if the file data is a part of file footer section
         return true;
       }
     }
     return false;
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(isHeader.name, exp.message, dataStr)
     );
     return false;
   }
 };
 
 /* WP FILE CONTENT FOOTER CONTENT CHECK */
 const isFooter = (dataStr) => {
   try {
     // Return true if the file data is a part of file footer section
     return dataStr && !dataStr?.substring(0, 109)?.includes(SPACE_STR);
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(isFooter.name, exp.message, dataStr)
     );
     return false;
   }
 };
 
 /* SAVE WP FILE CONTENT IN LOCAL */
 const saveWpFileContentInLocalFile = (
   wpFileContent,
   wpFileName,
   wpFileCreationDate
 ) => {
   logger.info("***** saveWpFileContentInLocalFile() START *****");
   try {
     // Date wise directory create
     const dateWiseDirectory = `${WP_LOCAL_FILES_ROOT_DIRECTORY}/${wpFileCreationDate}`;
     // Craete file name wise local file path
     const filePath = `${dateWiseDirectory}/${wpFileName}`;
     if (!isFileOrFolderPresent(dateWiseDirectory)) {
       // Create WP files root container directory
       if (!isFileOrFolderPresent(WP_LOCAL_FILES_ROOT_DIRECTORY))
         createDirectorySyncInLocal(WP_LOCAL_FILES_ROOT_DIRECTORY);
       // Create date wise directory
       createDirectorySyncInLocal(dateWiseDirectory);
     }
     // Write data in file and retrun, if process gets success
     return writeFileSyncInLocal(filePath, wpFileContent);
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         saveWpFileContentInLocalFile.name,
         exp.message,
         wpFileName
       )
     );
     return null;
   }
 };
 
 /* CREATE DATA BY SPLITTING DOCUMENT CONTENT STRING */
 // eslint-disable-next-line no-unused-vars
 const getDataFromFileContentStr = (wpDoc) => {
   logger.info("***** getDataFromFileContentStr() START *****");
   try {
     const fileContentParsedDataArr = [];
     // Reading file content and data array prepare
     const wpDocContents = wpDoc?.toString(UTF_8_STR)?.split(REGEX_NEW_LINE);
     wpDocContents?.forEach((eachContent) => {
       fileContentParsedDataArr.push(eachContent.trim());
     });
     return fileContentParsedDataArr;
   } catch (exp) {
     logger.error(
       `MSG: ERROR INSIDE getDataFromFileContentStr() METHOD: ${exp.message}`
     );
     return null;
   }
 };
 
 /** ***********************************************
   // DE_EXCP, DE_RET, BPAY DATA PROCESSING HELPERS
  *************************************************** */
 
 /* WP LPT REVERSAL RECORD INSERT */
 const wpLptRevInsert = async (createdFrom, wpFileName, revLptListArr = []) => {
   logger.info("***** wpLptRevInsert() START *****");
   try {
     let lptInsertStatus;
     const lptRefMsgMap = new Map();
     if (revLptListArr && revLptListArr.length > 0) {
       // Create the lpt reference list for query details of LPTs.
       const lptRefList = revLptListArr.map((eachRevLpt) => eachRevLpt.lptRef);
       // Create a list of all the messages for each LPT reference.
       revLptListArr.forEach((eachRevLpt) => {
         lptRefMsgMap.set(eachRevLpt.lptRef, eachRevLpt.revMsg);
       });
       // Query the LPTs
       const queriedLptList = await getLptListApiCall(lptRefList);
       if (queriedLptList && queriedLptList.length > 0) {
         // Loope through the LPT list and craete LPT reversal record object.
         const lptRevListToInsert = queriedLptList.map((eachLpt) => ({
           Loan_Payment_Transaction__c: eachLpt.Id,
           Reason_Codes__c: lptRefMsgMap.get(eachLpt.Name),
           Created_From__c: createdFrom,
           CL_Contract__c: eachLpt.loan__Loan_Account__c,
           File_Name__c: wpFileName,
         }));
         // Insert LPT Reversal records
         const lptInsertApiRes = await crtLptReversalRecordApiCall(
           lptRevListToInsert
         );
         if (lptInsertApiRes) {
           lptInsertStatus = SUCCESS_STR;
         } else {
           // Throw error if lpt reversal record creation failed
           logger.info("MSG: LPT REVERSAL RECORD CREATION FAILED");
           throw new BaseError(WP_LPT_REVERSAL_RECORD_INSERTION_FAILED_MSG);
         }
       } else if (queriedLptList && queriedLptList.length === 0) {
         logger.info("MSG: NO LPT FOUND FOR LPT REVERSAL RECORD CREATION");
         // set success status if no lpt found
         lptInsertStatus = SUCCESS_STR;
       }
     } else if (revLptListArr && revLptListArr.length === 0) {
       // Set success message if the data array is empty
       logger.info("MSG: EMPTY ARRAY FOR LPT REVERSAL RECORD CREATION");
       lptInsertStatus = SUCCESS_STR;
     }
     return lptInsertStatus;
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(wpLptRevInsert.name, exp.message, wpFileName)
     );
     return null;
   }
 };
 
 /* WP LPT UPDATE */
 const wpLptUpdate = async (currSysDateTime, wpFileName, passedLptArr = []) => {
   logger.info("***** wpLptUpdate() START *****");
   try {
     let lptUpdateStatus;
     if (passedLptArr && passedLptArr.length > 0) {
       // Call Lpt retrieve api
       const lptList = await getLptListApiCall(passedLptArr);
       if (lptList && lptList.length > 0) {
         // Updated LPT list prepare for update
         const updatedLptList = lptList.map((eachLpt) => ({
           Id: eachLpt.Id,
           Passed_DEEDS_Excp__c: true,
           DEEDS_Exc_Reported_On__c: currSysDateTime,
         }));
         // Call lpt update api
         const lptUpdateApiRes = await updateLptListApiCall(updatedLptList);
         if (lptUpdateApiRes) lptUpdateStatus = SUCCESS_STR;
       }
     } else {
       // Set success is the lpt data array listis empty
       lptUpdateStatus = SUCCESS_STR;
     }
     return lptUpdateStatus;
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(wpLptUpdate.name, exp.message, wpFileName)
     );
     return null;
   }
 };
 
 /* WP LOG UPDATE & BATCH EXECUTION SF PLATFORM EVENT TRIGGER */
 const wpLogUpdtAndSfPltEveTrigger = async (
   wpLogId,
   currSysDateTime,
   sfPltEveBatchName = null
 ) => {
   logger.info("***** wpLogUpdtAndSfPltEveTrigger() START *****");
   try {
     // Checking for batch related SF platform event publish
     if (sfPltEveBatchName) {
       // Batch execution SF platform event trigger
       const sfPltEventDet = {
         Batch_Size__c: 1,
         Batch_Name__c: sfPltEveBatchName,
       };
       // SF batch execution event trigger api call
       const sfBatchExePltEveApiRes = await wpTriggerBatchExeSfPltEveApiCall(
         sfPltEventDet
       );
       logger.info(
         `MSG: ${sfPltEveBatchName} - BATCH EXECUTION PLATFORM EVENT ${
           sfBatchExePltEveApiRes ? "INSERTED" : "INSERTION FAILED"
         }`
       );
       if (!sfBatchExePltEveApiRes) {
         // Log insert event trigger
         sfLoggingEventTriggerApiCall(
           SENT_EMAIL_TO_DEVELOPER,
           SERVICE_NAME_WESTPAC,
           genErrorDetailsStr(
             wpLogUpdtAndSfPltEveTrigger.name,
             WP_BATCH_EXECUTION_SF_EVENT_TRIGGER_FAILED_MSG,
             `${wpLogId},${sfPltEveBatchName}`
           )
         );
       }
     } else {
       logger.info("MSG: BATCH EXECUTION EVENT TRIGGER NOT ENABLED");
     }
     // WP log process related details update
     const wpLogRecToUpdate = {
       Id: wpLogId,
       Processed_On__c: currSysDateTime,
       Processed__c: true,
     };
     // WP log update api call
     const wpLogUpdtApiRes = await wpLogRecUpdateApiCall(wpLogRecToUpdate);
     logger.info(
       `MSG: WP LOG UPDATE ${
         wpLogUpdtApiRes ? "COMPLETED" : "FAILED"
       } FOR LOG ID ${wpLogId}`
     );
     if (!wpLogUpdtApiRes) {
       // Throe error wp log update failed
       throw new BaseError(WP_WPLOG_UPDATE_FAILED_MSG);
     }
     return wpLogUpdtApiRes;
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         wpLogUpdtAndSfPltEveTrigger.name,
         exp.message,
         `${wpLogId},${sfPltEveBatchName}`
       )
     );
     return null;
   }
 };
 
 /* WP BPAY RECORD CREATION */
 const wpBpayRecordInsert = async (wpApiReqParams, bpayDataArr = []) => {
   logger.info("***** wpBpayRecordInsert() START *****");
   const { wpFileName, modeId, currSysDateTime } = wpApiReqParams;
   try {
     let bpayRecordInsertStatus;
     let allBpayRecToInstArr = [];
     let allowedCrnIdsArr = [];
     const crnIdLoanAmtMap = new Map();
     const crnIdBpayRNoMap = new Map();
     if (bpayDataArr && bpayDataArr.length > 0) {
       // Create the crn id list for query details of loan account
       const crnIdList = bpayDataArr.map((eachBpayData) => eachBpayData.crnId);
       // Create a map of all the bpay RN No for each crn id
       bpayDataArr.forEach((eachBpayData) => {
         crnIdBpayRNoMap.set(eachBpayData.crnId, eachBpayData.bpayRNo);
       });
       // Create a map of all the amount for each crn id
       bpayDataArr.forEach((eachBpayData) => {
         if (crnIdLoanAmtMap.has(eachBpayData.crnId)) {
           const amounts = crnIdLoanAmtMap.get(eachBpayData.crnId);
           amounts.push(eachBpayData.loanAmt);
           crnIdLoanAmtMap.set(eachBpayData.crnId, amounts);
         } else {
           const amounts = [];
           amounts.push(eachBpayData.loanAmt);
           crnIdLoanAmtMap.set(eachBpayData.crnId, amounts);
         }
       });
       // Query the loan account against crn id list
       const queriedLoanAccList =
         (await wpGetLoanAccListApiCall(CRN_ID_STR, crnIdList)) ?? [];
       if (queriedLoanAccList && queriedLoanAccList.length > 0) {
         // Query the record type
         const bpayTxnRecTypeId = await getBpayRecordTypeApiCall(
           BPAY_TXN_DATA_STORE_REC_TYPE
         );
         // Create an array for bpay record that are found in BE insertion
         const loanBpayRecordToInsert = [];
         queriedLoanAccList.forEach((eachLoanAcc) => {
           const amounts = crnIdLoanAmtMap.get(eachLoanAcc.CRN_Number__c);
           if (amounts) {
             amounts.forEach((amount) => {
               loanBpayRecordToInsert.push({
                 Source_Type__c: BPAY_MODE,
                 Transaction_Date__c: currSysDateTime,
                 ModeId__c: modeId,
                 ParentId__c: eachLoanAcc.Id,
                 Amount__c: amount,
                 Payment_Code__c: crnIdBpayRNoMap.get(eachLoanAcc.CRN_Number__c),
                 RecordTypeId: bpayTxnRecTypeId,
               });
             });
           }
         });
         // List of CRN Ids found in system
         const loanCrnIdArr = queriedLoanAccList.map(
           (eachLoanAcc) => eachLoanAcc.CRN_Number__c
         );
         allowedCrnIdsArr = [...loanCrnIdArr];
         allBpayRecToInstArr = [...loanBpayRecordToInsert];
       }
       // Extracting Unique CRN Ids from Map
       const uniqueCRNList = Array.from(crnIdLoanAmtMap.keys());
       // List of rejected CRN Ids (not in system)
       const rejCrnIdsList = uniqueCRNList.filter(
         (eachCrn) => !allowedCrnIdsArr.includes(eachCrn)
       );
       if (rejCrnIdsList && rejCrnIdsList.length > 0) {
         // Query the record type
         const rejectedTxnRecTypeId = await getBpayRecordTypeApiCall(
           REJECTED_TXN_DATA_STORE_REC_TYPE
         );
         // Create an array for bpay record insertion of record type - rejected
         const rejBpayRecordToInsert = [];
         rejCrnIdsList.forEach((eachCrn) => {
           const amounts = crnIdLoanAmtMap.get(eachCrn);
           if (amounts) {
             amounts.forEach((amount) => {
               rejBpayRecordToInsert.push({
                 Source_Type__c: BPAY_MODE,
                 CRN_Number__c: eachCrn.toString(),
                 Transaction_Date__c: currSysDateTime,
                 Amount__c: amount,
                 Payment_Code__c: crnIdBpayRNoMap.get(eachCrn),
                 Payment_Type__c: DIRECT_CREDIT,
                 ParentId__c: BLANK_STR,
                 ModeId__c: BLANK_STR,
                 Error_Message__c: CRN_NOT_FOUND_IN_LOAN,
                 File_Name__c: wpFileName,
                 RecordTypeId: rejectedTxnRecTypeId,
               });
             });
           }
         });
         allBpayRecToInstArr = [
           ...rejBpayRecordToInsert,
           ...allBpayRecToInstArr,
         ];
       }
       // Insert bpay record
       const bpayInsertApires = await crtBpayRecordApiCall(allBpayRecToInstArr);
       if (bpayInsertApires) {
         bpayRecordInsertStatus = SUCCESS_STR;
       } else {
         logger.info("MSG: BPAY RECORD CREATION FAILED");
       }
     } else if (bpayDataArr && bpayDataArr.length <= 0) {
       // Set the success status if the data array is blank
       logger.info("MSG: EMPTY ARRAY FOR BPAY RECORD CREATION");
       bpayRecordInsertStatus = SUCCESS_STR;
     }
     return bpayRecordInsertStatus;
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(wpBpayRecordInsert.name, exp.message, `${wpFileName}`)
     );
     return null;
   }
 };
 /* DE_RET FILE: GENERATE LPT/SBI/OTHER REF DETAILS */
 const getDpRetRefDataDetails = (wpFileName, deRateData, deRateDataType) => {
   try {
     let dpRetRefDataDetails = {};
     if (deRateDataType === DE_RET_LPT_DATA_TYPE) {
       // lpt reversal record creation related data array prepare
       const errCode = deRateData?.substring(17, 18)?.trim();
       dpRetRefDataDetails = {
         lptRef: deRateData?.substring(62, 77)?.trim(),
         revMsg: errCode ? WP_WERPS_CODE_DETAILS[errCode] : errCode,
       };
     } else {
       // Data extract from SBI/DDI type file data string
       dpRetRefDataDetails = {
         custName: deRateData?.substring(30, 62)?.trim(),
         bankDetails: deRateData?.substring(80, 96)?.trim(),
         errorCode: deRateData?.substring(17, 18)?.trim(),
         exceptionReason: deRateData?.substring(17, 18)?.trim(),
         amount: `${deRateData?.substring(20, 28)?.trim()}.${deRateData
           ?.substring(28, 30)
           ?.trim()}`,
         reversalDate: deRateData?.substring(146, 152)?.trim(),
         ...(deRateDataType === DE_RET_SBI_DATA_TYPE && {
           bsb: `${deRateData?.substring(80, 83)?.trim()}${deRateData
             ?.substring(84, 87)
             ?.trim()}`,
           otherRef: deRateData?.substring(62, 80)?.trim(),
           bankAcc: deRateData?.substring(88, 96)?.trim(),
         }),
         ...(deRateDataType === DE_RET_DDI_DATA_TYPE && {
           ddiName: deRateData?.substring(62, 80)?.trim(),
         }),
       };
       // Reversal data retrieve
       dpRetRefDataDetails.reversalDate = `${dpRetRefDataDetails?.reversalDate?.substring(
         0,
         2
       )}/${dpRetRefDataDetails?.reversalDate?.substring(
         2,
         4
       )}/20${dpRetRefDataDetails?.reversalDate?.substring(4)}`;
       // Set exception reason from error code
       dpRetRefDataDetails.exceptionReason =
         dpRetRefDataDetails?.errorCode === INT_6_STR
           ? WP_WERPS_CODE_DETAILS[INT_10_STR]
           : WP_WERPS_CODE_DETAILS[dpRetRefDataDetails?.errorCode] ??
             dpRetRefDataDetails?.errorCode;
     }
     return dpRetRefDataDetails;
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         getDpRetRefDataDetails.name,
         exp.message,
         `${wpFileName}`
       )
     );
     return null;
   }
 };
 
 /* DE_RET FILE: SBI CSV RECORD LIST GENERATE */
 const getSbiRefCsvRecordsList = (
   wpFileName,
   dateFromDocHeader,
   loanOthTrans = []
 ) => {
   logger.info("***** getSbiRefCsvRecordsList() START *****");
   try {
     const otherTranCsvDataArr = [];
     const sbiRefBankAccNotFoundCsvDataArr = [];
     const loanOthrTranBankAccTranDetMap = new Map();
     // Create a list of all the loan other transaction records against the bank account.
     loanOthTrans.forEach((eachLoanOthrTran) => {
       loanOthrTranBankAccTranDetMap.set(
         eachLoanOthrTran.loan__Loan_Account__r.loan__Borrower_ACH__r
           .loan__Bank_Account_Number__c,
         eachLoanOthrTran
       );
     });
     if (sbiRefDetArr && sbiRefDetArr.length > 0) {
       sbiRefDetArr.forEach((eachSbiRef) => {
         // Get transaction object from queried data list
         const loanOtherTran = loanOthrTranBankAccTranDetMap.get(
           eachSbiRef.bankAcc
         );
         // Check if both file data and queried data has same txn amout or not
         if (
           loanOtherTran &&
           Number.parseFloat(loanOtherTran.loan__Txn_Amt__c.toString()) ===
             Number.parseFloat(eachSbiRef.amount)
         ) {
           // Push data in an array if txn amout is same
           otherTranCsvDataArr.push({
             fileDate: dateFromDocHeader ?? BLANK_STR,
             clContrac: loanOtherTran.loan__Loan_Account__r.Name ?? BLANK_STR,
             customerName: eachSbiRef.custName ?? BLANK_STR,
             reference: loanOtherTran.Name ?? BLANK_STR,
             otherBankRefNumber: BLANK_STR,
             bsbAndAcct: eachSbiRef.bankDetails ?? BLANK_STR,
             txnDate: eachSbiRef.reversalDate ?? BLANK_STR,
             amount: eachSbiRef.amount ?? BLANK_STR,
             exceptionReason: eachSbiRef.exceptionReason ?? BLANK_STR,
           });
         } else {
           // Push data in an array if txn amout is not same
           sbiRefBankAccNotFoundCsvDataArr.push({
             fileDate: dateFromDocHeader ?? BLANK_STR,
             clContrac: BLANK_STR,
             customerName: eachSbiRef.custName ?? BLANK_STR,
             reference: BLANK_STR ?? BLANK_STR,
             otherBankRefNumber: BLANK_STR,
             bsbAndAcct: eachSbiRef.bankDetails ?? BLANK_STR,
             txnDate: eachSbiRef.reversalDate ?? BLANK_STR,
             amount: eachSbiRef.amount ?? BLANK_STR,
             exceptionReason: eachSbiRef.exceptionReason ?? BLANK_STR,
           });
         }
       });
     }
     // Combine both the array and return it
     return [...otherTranCsvDataArr, ...sbiRefBankAccNotFoundCsvDataArr];
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         getSbiRefCsvRecordsList.name,
         exp.message,
         `${wpFileName}`
       )
     );
     return null;
   }
 };
 
 /* DE_RET FILE: SBI REPORT GENERATE */
 const genDeRateSbiRefReport = async (
   loanOthTransApiRes = []
 ) => {
   logger.info("***** genDeRateSbiRefReport() START *****");
   const { wpFileName, currSysDateTime } =
   wpApiReqParamsForDdi;
   try{
     if (loanOthTransApiRes && loanOthTransApiRes.length > 0) {
       // CSV report array generate
       const refundRevCsvRecorsArr = getSbiRefCsvRecordsList(
         wpFileName,
         dateFromDocHeaderForRep,
         sbiRefDetArr,
         loanOthTransApiRes
       );
       // Csv report string generate
       const refundRevCsvStr = generateCsvFileString(
         WP_REFUND_REVERSAL_CSV_REPORT_HEADERS,
         refundRevCsvRecorsArr
       );
       // Report file name
       const csvFileName = `Refund_Reversal_${currSysDateTime}.csv`;
       // Report insertion api call
       const insertRepInDocumentApiRes =
         await reportInsertInDocumentApiCall(
           csvFileName,
           refundRevCsvStr,
           WP_BANK_REJECT_REPORT_NAME
         );
       if (!insertRepInDocumentApiRes) {
         throw new BaseError(REPORT_GEN_FAILED_MSG);
       }
       deRateSbiRefReportStatus = SUCCESS_STR;
       logger.info(
         `MSG: ${csvFileName} ${
           insertRepInDocumentApiRes ? "INSERTED" : "INSERTION FAILED"
         } IN ${WP_BANK_REJECT_REPORT_NAME} FOLDER`
       );
     } else if (loanOthTransApiRes && loanOthTransApiRes.length === 0) {
       deRateSbiRefReportStatus = SUCCESS_STR;
       logger.info(
         "MSG: EMPTY DATA ARRAY. REFERENCE - loanOthTransApiRes"
       );
     } else {
       throw new BaseError(REPORT_GEN_FAILED_MSG);
     }
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         genDeRateSbiRefReport.name,
         exp.message,
         `${wpFileName}`
       )
     );
   }
 };
 
 const wpGetLoanOthrTranListForSbiReport = (
   loanBankAccFrmBaApiRes = []
 ) => {
   logger.info("***** wpGetLoanOthrTranListForSbiReport() START *****");
   const { wpFileName } =
   wpApiReqParamsForDdi;
   try{
     if (loanBankAccFrmBaApiRes && loanBankAccFrmBaApiRes.length > 0) {
       const loanAccIdArr = loanBankAccFrmBaApiRes.map(
         (eachLoanAccDet) => eachLoanAccDet.Id
       );
       if (loanAccIdArr && loanAccIdArr.length > 0) {
         // Query string generate
         const otherConInQuery = `AND loan__Transaction_Type__c = '${LOAN_TRAN_TYPE_REFUND_STR}'`;
         // Request send
         const queryStr = `${SF_LOAN_OTHER_TRAN_USING_LOAN_ACC_QUERY} ('${Array.from(
           loanAccIdArr
         ).join(COMMA_INSIDE_SINGLE_INV_STR)}') ${otherConInQuery}`;
         sfAsyncQueryHugeDataAndProcess(
           queryStr,
           genDeRateSbiRefReport,
           hugeDataQueryErrHandler
         );
       }
     }else if (
       loanBankAccFrmBaApiRes &&
       loanBankAccFrmBaApiRes.length === 0
     ) {
       deRateSbiRefReportStatus = SUCCESS_STR;
       logger.info(
         "MSG: EMPTY DATA ARRAY. REFERENCE - loanBankAccFrmBaApiRes"
       );
     } else {
       throw new BaseError(REPORT_GEN_FAILED_MSG);
     }
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         wpGetLoanOthrTranListForSbiReport.name,
         exp.message,
         `${wpFileName}`
       )
     );
   }
 };
 
 /* DE_RET FILE: DDI CSV RECORD LIST GENERATE */
 const wpGetLoanAccListForSbiReport = (
   loanBankAccFrmBsbApiRes = []
 ) => {
   logger.info("***** wpGetLoanAccListForSbiReport() START *****");
   const { wpFileName } =
   wpApiReqParamsForDdi;
   try {
     const bankAccArr = sbiRefDetArr.map((eachRefDet) => eachRefDet.bankAcc);
     const baIdArr = [];
     if (loanBankAccFrmBsbApiRes && loanBankAccFrmBsbApiRes.length > 0) {
       loanBankAccFrmBsbApiRes.forEach((eachBankAcc) => {
         if (bankAccArr.includes(eachBankAcc.loan__Bank_Account_Number__c)) {
           baIdArr.push(eachBankAcc.Id);
         }
       });
       let queryStr;
       let idList = baIdArr;
       switch (BA_ID_STR) {
         case CRN_ID_STR:
           queryStr = SF_LOAN_ACC_FETCH_USING_CRN_QUERY;
           break;
         case BA_ID_STR:
           queryStr = SF_LOAN_ACC_FETCH_USING_BOR_ACH_QUERY;
           break;
         default:
           queryStr = null;
           break;
       }
       if (queryStr && baIdArr && baIdArr.length > 0) {
         // Removing Duplicate CRNs
         if (BA_ID_STR === CRN_ID_STR) {
           const idArrSet = new Set(baIdArr);
           idList = [...idArrSet];
         }
       }
       sfAsyncQueryHugeDataAndProcess(
         `${queryStr} ('${Array.from(
           idList
         ).join(COMMA_INSIDE_SINGLE_INV_STR)}')`,
         wpGetLoanOthrTranListForSbiReport,
         hugeDataQueryErrHandler
       );
     }else if (
       loanBankAccFrmBsbApiRes &&
       loanBankAccFrmBsbApiRes.length === 0
     ) {
       deRateSbiRefReportStatus = SUCCESS_STR;
       logger.info(
         "MSG: EMPTY DATA ARRAY. REFERENCE - loanBankAccFrmBsbApiRes"
       );
     } else {
       throw new BaseError(REPORT_GEN_FAILED_MSG);
     }  
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         wpGetLoanAccListForSbiReport.name,
         exp.message,
         `${wpFileName}`
       )
     );
   }
 };
 
 /* DE_RET FILE: SBI REPORT GENERATE */
 const initGenDeRateSbiRefReport = async (
   wpApiReqParams,
   dateFromDocHeader) => {
   logger.info("***** genDeRateSbiRefReport() START *****");
   const { wpFileName } = wpApiReqParams;
   dateFromDocHeaderForRep = dateFromDocHeader;
   wpApiReqParamsForDdi = wpApiReqParams;
   try {
     let sbiReportInsertStatus;
     if (sbiRefDetArr && sbiRefDetArr.length > 0) {
       // const baIdArr = [];
       // Get beb number array from data list
       const bsbNumArr = sbiRefDetArr.map((eachRefDet) => eachRefDet.bsb);
       // Get bank account data array from the list
       // const bankAccArr = sbiRefDetArr.map((eachRefDet) => eachRefDet.bankAcc);
       // Loan account fetch using bsb numbers
       sfAsyncQueryHugeDataAndProcess(
         `${SF_LOAN_BANK_ACC_USING_BSB_NUM_QUERY} ('${Array.from(
           bsbNumArr
         ).join(COMMA_INSIDE_SINGLE_INV_STR)}')`,
         wpGetLoanAccListForSbiReport,
         hugeDataQueryErrHandler
       );
       // const loanBankAccFrmBsbApiRes = await wpGetLoanBankAccListApiCall(
       //   bsbNumArr
       // );
       // if (loanBankAccFrmBsbApiRes && loanBankAccFrmBsbApiRes.length > 0) {
       //   loanBankAccFrmBsbApiRes.forEach((eachBankAcc) => {
       //     if (bankAccArr.includes(eachBankAcc.loan__Bank_Account_Number__c)) {
       //       baIdArr.push(eachBankAcc.Id);
       //     }
       //   });
       //   // Loan bank account fetch using borrowr achs
       //   const loanBankAccFrmBaApiRes = await wpGetLoanAccListApiCall(
       //     BA_ID_STR,
       //     baIdArr
       //   );
         // if (loanBankAccFrmBaApiRes && loanBankAccFrmBaApiRes.length > 0) {
         //   const loanAccIdArr = loanBankAccFrmBaApiRes.map(
         //     (eachLoanAccDet) => eachLoanAccDet.Id
         //   );
           // Loan other transaction fetch using loan account ids
           // const loanOthTransApiRes = await wpGetLoanOthrTranListApiCall(
           //   loanAccIdArr
           // );
           // if (loanOthTransApiRes && loanOthTransApiRes.length > 0) {
           //   // CSV report array generate
           //   const refundRevCsvRecorsArr = getSbiRefCsvRecordsList(
           //     wpFileName,
           //     dateFromDocHeader,
           //     sbiRefDetArr,
           //     loanOthTransApiRes
           //   );
           //   // Csv report string generate
           //   const refundRevCsvStr = generateCsvFileString(
           //     WP_REFUND_REVERSAL_CSV_REPORT_HEADERS,
           //     refundRevCsvRecorsArr
           //   );
           //   // Report file name
           //   const csvFileName = `Refund_Reversal_${currSysDateTime}.csv`;
           //   // Report insertion api call
           //   const insertRepInDocumentApiRes =
           //     await reportInsertInDocumentApiCall(
           //       csvFileName,
           //       refundRevCsvStr,
           //       WP_BANK_REJECT_REPORT_NAME
           //     );
           //   if (!insertRepInDocumentApiRes) {
           //     throw new BaseError(REPORT_GEN_FAILED_MSG);
           //   }
           //   sbiReportInsertStatus = SUCCESS_STR;
           //   logger.info(
           //     `MSG: ${csvFileName} ${
           //       insertRepInDocumentApiRes ? "INSERTED" : "INSERTION FAILED"
           //     } IN ${WP_BANK_REJECT_REPORT_NAME} FOLDER`
           //   );
           // } else if (loanOthTransApiRes && loanOthTransApiRes.length === 0) {
           //   sbiReportInsertStatus = SUCCESS_STR;
           //   logger.info(
           //     "MSG: EMPTY DATA ARRAY. REFERENCE - loanOthTransApiRes"
           //   );
           // } else {
           //   throw new BaseError(REPORT_GEN_FAILED_MSG);
           // }
         // } else if (
         //   loanBankAccFrmBaApiRes &&
         //   loanBankAccFrmBaApiRes.length === 0
         // ) {
         //   sbiReportInsertStatus = SUCCESS_STR;
         //   logger.info(
         //     "MSG: EMPTY DATA ARRAY. REFERENCE - loanBankAccFrmBaApiRes"
         //   );
         // } else {
         //   throw new BaseError(REPORT_GEN_FAILED_MSG);
         // }
       // } else if (
       //   loanBankAccFrmBsbApiRes &&
       //   loanBankAccFrmBsbApiRes.length === 0
       // ) {
       //   sbiReportInsertStatus = SUCCESS_STR;
       //   logger.info(
       //     "MSG: EMPTY DATA ARRAY. REFERENCE - loanBankAccFrmBsbApiRes"
       //   );
       // } else {
       //   throw new BaseError(REPORT_GEN_FAILED_MSG);
       // }
     } else if (sbiRefDetArr && sbiRefDetArr.length === 0) {
       sbiReportInsertStatus = SUCCESS_STR;
       logger.info("MSG: EMPTY DATA ARRAY. REFERENCE - sbiRefDetArr");
     } else {
       throw new BaseError(REPORT_GEN_FAILED_MSG);
     }
     return sbiReportInsertStatus;
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         initGenDeRateSbiRefReport.name,
         exp.message,
         `${wpFileName}`
       )
     );
     return null;
   }
 };
 
 /* DE_RET FILE: DDI CSV RECORD LIST GENERATE */
 const getDdiCsvRecordsList = (
   wpFileName,
   dateFromDocHeader,
   loanDisbTranDistList = []
 ) => {
   logger.info("***** getDdiCsvRecordsList() START *****");
   try {
     const ddiRefCsvDataArr = [];
     const ddiRefNotFoundCsvDataArr = [];
     const loanDisbTranDistMap = new Map();
     if (ddiDetArr && ddiDetArr.length > 0) {
       // Create a list of all the loan disbursal txn distribution records against the DDI name.
       loanDisbTranDistList.forEach((eachLoanDisbTranDist) => {
         if (eachLoanDisbTranDist.Other_Bank_Reference__c) {
           loanDisbTranDistMap.set(
             eachLoanDisbTranDist.Other_Bank_Reference__c,
             eachLoanDisbTranDist
           );
         } else if (eachLoanDisbTranDist.Name) {
           loanDisbTranDistMap.set(
             eachLoanDisbTranDist.Name,
             eachLoanDisbTranDist
           );
         }
       });
       ddiDetArr.forEach((eachDdiDet) => {
         // Get ddi data present in the queried data list
         const loanDisbTxnDisDet = loanDisbTranDistMap.get(eachDdiDet.ddiName);
         // Check if the data's and quereed data's distribution amout is equal or not
         if (
           loanDisbTxnDisDet &&
           Number.parseFloat(
             loanDisbTxnDisDet.loan__Distribution_Amount__c.toString()
           ) === Number.parseFloat(eachDdiDet.amount)
         ) {
           // create record if amount is same and push it into an array
           ddiRefCsvDataArr.push({
             fileDate: dateFromDocHeader ?? BLANK_STR,
             clContrac:
               loanDisbTxnDisDet.loan__Loan_Disbursal_Transaction__r
                 .loan__Loan_Account__r.Name ?? BLANK_STR,
             customerName: eachDdiDet.custName ?? BLANK_STR,
             reference: loanDisbTxnDisDet.Name ?? BLANK_STR,
             otherBankRefNumber:
               loanDisbTxnDisDet.Other_Bank_Reference__c ?? BLANK_STR,
             bsbAndAcct: eachDdiDet.bankDetails ?? BLANK_STR,
             txnDate: eachDdiDet.reversalDate ?? BLANK_STR,
             amount: eachDdiDet.amount ?? BLANK_STR,
             exceptionReason: eachDdiDet.exceptionReason ?? BLANK_STR,
           });
         } else {
           // create record if amount is not same and push it into an array
           ddiRefNotFoundCsvDataArr.push({
             fileDate: dateFromDocHeader ?? BLANK_STR,
             clContrac: BLANK_STR,
             customerName: eachDdiDet.custName ?? BLANK_STR,
             reference: eachDdiDet.ddiName.includes(WP_DDI_STR)
               ? eachDdiDet.ddiNam ?? BLANK_STR
               : BLANK_STR,
             otherBankRefNumber: !eachDdiDet.ddiName.includes(WP_DDI_STR)
               ? eachDdiDet.ddiNam ?? BLANK_STR
               : BLANK_STR,
             bsbAndAcct: eachDdiDet.bankDetails ?? BLANK_STR,
             txnDate: eachDdiDet.reversalDate ?? BLANK_STR,
             amount: eachDdiDet.amount ?? BLANK_STR,
             exceptionReason: eachDdiDet.exceptionReason ?? BLANK_STR,
           });
         }
       });
     }
     // Combine both data array and return it
     return [...ddiRefCsvDataArr, ...ddiRefNotFoundCsvDataArr];
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         getDdiCsvRecordsList.name,
         exp.message,
         `${wpFileName}`
       )
     );
     return null;
   }
 };
 
 /* DE_RET FILE: OTHER REPORT GENERATE */
 const genDeRateDdiReport = async (loanDisbTranDistApiRes = []) => {
   logger.info("***** genDeRateDdiReport() START *****");
   let wpLogAndEvntTriSts;
   const { wpLogId, wpFileName, reverseImmediately, currSysDateTime } =
     wpApiReqParamsForDdi;
   try {
     if (loanDisbTranDistApiRes && loanDisbTranDistApiRes.length > 0) {
       // CSV report array generate
       const ddiReversalCsvRecorsArr = getDdiCsvRecordsList(
         wpFileName,
         dateFromDocHeaderForRep,
         ddiDetArr,
         loanDisbTranDistApiRes
       );
       // Csv report string generate
       const ddiReversalCsvStr = generateCsvFileString(
         WP_DDI_REVERSAL_CSV_REPORT_HEADERS,
         ddiReversalCsvRecorsArr
       );
       // Report insert api call
       const csvFileName = `DDI_Reversal_${currSysDateTime}.csv`;
       // Report insert api call
       const insertRepInDocumentApiRes = await reportInsertInDocumentApiCall(
         csvFileName,
         ddiReversalCsvStr,
         WP_BANK_REJECT_REPORT_NAME
       );
       if (!insertRepInDocumentApiRes) {
         throw new BaseError(REPORT_GEN_FAILED_MSG);
       }
       ddiReportInsertStatus = SUCCESS_STR;
       logger.info(
         `MSG: ${csvFileName} ${
           insertRepInDocumentApiRes ? "INSERTED" : "INSERTION FAILED"
         } IN ${WP_BANK_REJECT_REPORT_NAME} FOLDER`
       );
     } else if (loanDisbTranDistApiRes && loanDisbTranDistApiRes.length === 0) {
       ddiReportInsertStatus = SUCCESS_STR;
       logger.info("MSG: EMPTY DATA ARRAY. REFERENCE - loanDisbTranDistApiRes");
     } else {
       throw new BaseError(REPORT_GEN_FAILED_MSG);
     }
     if (
       deRateLptRevInsertStatus === SUCCESS_STR &&
       deRateSbiRefReportStatus === SUCCESS_STR &&
       ddiReportInsertStatus === SUCCESS_STR
     ) {
       logger.info(
         "MSG: WP EXCEP DOC - ABI REF REPORT, DDI REF REPORT, & LPT REVERSAL RECORD CREATION COMPLETED"
       );
       // Get the batch to execute
       const sfPltEveBatchName = reverseImmediately
         ? SF_LPT_REVERSAL_BATCH_NAME
         : null;
       // WP log update and sf platform event trigger
       wpLogAndEvntTriSts = await wpLogUpdtAndSfPltEveTrigger(
         wpLogId,
         currSysDateTime,
         sfPltEveBatchName
       );
       logger.info(
         `MSG: WP LOG UPDATE ${
           wpLogAndEvntTriSts ? "COMPLETED" : "FAILED"
         } FOR LOG ID ${wpLogId}`
       );
     }
   } catch (exp) {
     logger.error(
       `EXCEPTION INSIDE ${genDeRateDdiReport.name} METHOD. ERROR : ${exp.message}`
     );
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_REPORT,
       genErrorDetailsStr(
         genDeRateDdiReport.name,
         exp.message,
         `DDI_Reversal_${currSysDateTime}.csv`
       )
     );
   }
 };
 
 /* INIT DE_RET FILE: OTHER REPORT GENERATE */
 export const initGenDeRateDdiReport = async (
   wpApiReqParams,
   dateFromDocHeader
 ) => {
   logger.info("***** initGenDeRateDdiReport() START *****");
   const { wpFileName } = wpApiReqParams;
   dateFromDocHeaderForRep = dateFromDocHeader;
   wpApiReqParamsForDdi = wpApiReqParams;
   const DdiNamesOnlyArr = [];
   try {
     if (ddiDetArr && ddiDetArr.length > 0) {
       // Create ddiname arr
       const ddiNameArr = ddiDetArr.map((eachDdiDet) => eachDdiDet.ddiName);
       if (ddiNameArr && ddiNameArr.length > 0) {
         ddiNameArr.forEach((eachDdi) => {
           if (eachDdi.startsWith(WP_DDI_STR)) {
             DdiNamesOnlyArr.push(eachDdi);
           }
         });
         const otherConInQuery = `OR Other_Bank_Reference__c IN ('${Array.from(
           ddiNameArr
         ).join(COMMA_INSIDE_SINGLE_INV_STR)}')`;
         const queryStr = `${SF_LOAN_DISBURSAL_TXN_DISTRIBUTION_QUERY} ('${Array.from(
           DdiNamesOnlyArr
         ).join(COMMA_INSIDE_SINGLE_INV_STR)}') ${otherConInQuery}`;
         sfAsyncQueryHugeDataAndProcess(
           queryStr,
           genDeRateDdiReport,
           hugeDataQueryErrHandler
         );
       }
     } else if (ddiDetArr && ddiDetArr.length === 0) {
       ddiReportInsertStatus = SUCCESS_STR;
       logger.info("MSG: EMPTY DATA ARRAY. REFERENCE - ddiDetArr");
       genDeRateDdiReport();
     } else {
       throw new BaseError(REPORT_GEN_FAILED_MSG);
     }
   } catch (exp) {
     logger.error(
       `EXCEPTION INSIDE ${initGenDeRateDdiReport.name} METHOD. ERROR : ${exp.message}`
     );
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(genDeRateDdiReport.name, exp.message, `${wpFileName}`)
     );
   }
 };
 
 /** ************************
   // DE_EXCP DATA PROCESSING
  *************************** */
 
 /* DE_EXCP DOCUMENT's DATA PROCESS */
 const processExceptionDeedsFileData = async (
   wpApiReqParams,
   excpDeedDocDataArr = []
 ) => {
   logger.info("***** processExceptionDeedsFileData() START *****");
   const { wpLogId, reverseImmediately, wpFileName, currSysDateTime } =
     wpApiReqParams;
   try {
     const passedLptArr = [];
     const lptRevArr = [];
     let wpLogAndEvntTriSts;
     if (excpDeedDocDataArr && excpDeedDocDataArr.length > 0) {
       excpDeedDocDataArr.forEach((eachExcpDeedData, dataIndex) => {
         // Get lpt reference fromm data string
         const lptRef = eachExcpDeedData.substring(62, 77).trim();
         if (eachExcpDeedData.endsWith(WP_REVERSAL_CODE)) {
           // lpt reversal record creation data array prepare
           const revMsg = excpDeedDocDataArr[dataIndex + 1];
           lptRevArr.push({ lptRef, revMsg });
         } else if (eachExcpDeedData.endsWith(WP_PASS_CODE)) {
           // Data prepare for lpt insertion
           passedLptArr.push(lptRef);
         }
       });
       // LPT insertion and LPT reversal process initialted and wait for completion of both task
       const [excpDeedLptUpdateStatus, excpDeedLptRevInsertStatus] =
         await Promise.all([
           wpLptUpdate(currSysDateTime, wpFileName, passedLptArr),
           wpLptRevInsert(DEEDS_STR, wpFileName, lptRevArr),
         ]);
       // Continue if both the task gets completed
       if (
         excpDeedLptUpdateStatus === SUCCESS_STR &&
         excpDeedLptRevInsertStatus === SUCCESS_STR
       ) {
         logger.info(
           "MSG: WP EXCEP DOC - LPT UPDATE & LPT REVERSAL RECORD CREATION COMPLETED"
         );
         // Get batch to execute
         const sfPltEveBatchName = reverseImmediately
           ? SF_LPT_REVERSAL_BATCH_NAME
           : null;
         // WP log update and sf platform event trigger
         wpLogAndEvntTriSts = await wpLogUpdtAndSfPltEveTrigger(
           wpLogId,
           currSysDateTime,
           sfPltEveBatchName
         );
       }
     } else {
       logger.info("MSG: DE_EXCP DOC DATA ARRAY IS EMPTY");
       // TODO(Developer) - LOG INSERT EVENT TRIGGER
     }
     return wpLogAndEvntTriSts;
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         processExceptionDeedsFileData.name,
         exp.message,
         `${wpFileName}`
       )
     );
     return null;
   }
 };
 
 /** ***********************
   // DE_RET DATA PROCESSING
  ************************** */
 
 /* DE_RET DOCUMENT's DATA PROCESS */
 const processDeRateFileData = async (wpApiReqParams, deRetDataArr = []) => {
   logger.info("***** processDeRateFileData() START *****");
   const { wpFileName } = wpApiReqParams;
   try {
     let dateFromDocHeader;
     const lptRevArr = [];
     if (deRetDataArr && deRetDataArr.length > 0) {
       deRetDataArr.forEach((eachDeRateData, dataIndex) => {
         if (dataIndex === 0 && !eachDeRateData.includes(DE_RET_LPT_DATA_TYPE)) {
           // Retrieve date from document header section
           dateFromDocHeader = eachDeRateData?.substring(74, 80)?.trim();
           dateFromDocHeader =
             dateFromDocHeader &&
             `${dateFromDocHeader?.substring(
               0,
               2
             )}/${dateFromDocHeader?.substring(
               2,
               4
             )}/20${dateFromDocHeader?.substring(4)}`;
         } else if (dataIndex === deRetDataArr.length - 1) {
           // Footer line
         } else if (
           eachDeRateData?.includes(DE_RET_LPT_DATA_TYPE) ||
           eachDeRateData?.includes(DE_RET_SBI_DATA_TYPE)
         ) {
           if (eachDeRateData.includes(DE_RET_LPT_DATA_TYPE)) {
             // LPT reversal record creation array prepare
             const lptRefDetails = getDpRetRefDataDetails(
               wpFileName,
               eachDeRateData,
               DE_RET_LPT_DATA_TYPE
             );
             lptRevArr.push(lptRefDetails);
           } else {
             // SBI details data array prepare
             const sbiRefDetails = getDpRetRefDataDetails(
               wpFileName,
               eachDeRateData,
               DE_RET_SBI_DATA_TYPE
             );
             sbiRefDetArr.push(sbiRefDetails);
           }
         } else {
           // DDI details array prepare
           const ddiDetails = getDpRetRefDataDetails(
             wpFileName,
             eachDeRateData,
             DE_RET_DDI_DATA_TYPE
           );
           ddiDetArr.push(ddiDetails);
         }
       });
       // Parallel execution of LPT rev record creationand report generation.
       // Wait until the all callout gets completed.
       deRateLptRevInsertStatus = await wpLptRevInsert(
         DERPS_STR,
         wpFileName,
         lptRevArr
       );
       // deRateSbiRefReportStatus = await genDeRateSbiRefReport(
       //   wpApiReqParams,
       //   dateFromDocHeader,
       //   sbiRefDetArr
       // );
       initGenDeRateSbiRefReport(wpApiReqParams, dateFromDocHeader);
       initGenDeRateDdiReport(wpApiReqParams, dateFromDocHeader);
     } else {
       logger.info("MSG: DE_RATE DOC DATA ARRAY IS EMPTY");
     }
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         processDeRateFileData.name,
         exp.message,
         `${wpFileName}`
       )
     );
   }
 };
 
 /** ***********************
   // BPAY DATA PROCESSING
  ************************** */
 /* BPAY DOCUMENT's DATA PROCESS */
 const processBpayFileData = async (wpApiReqParams, bpayDataArr = []) => {
   logger.info("***** processBpayFileData() START *****");
   const { wpLogId, wpFileName, currSysDateTime } = wpApiReqParams;
   try {
     const bpayParsedDataArr = [];
     let wpLogAndEvntTriSts;
     if (bpayDataArr && bpayDataArr.length > 0) {
       bpayDataArr.forEach((eachBpayData, dataIndex) => {
         if (dataIndex === 0 || isHeader(eachBpayData)) {
           // file header
         } else if (
           dataIndex === bpayDataArr.length - 1 ||
           isFooter(eachBpayData)
         ) {
           // file footer
         } else {
           // Create data object from the file's data string
           const bpayNewData = {
             crnId: eachBpayData.substring(1, 30).trim(),
             loanAmt: Number.parseFloat(
               `${eachBpayData.substring(31, 40).trim()}.${eachBpayData
                 .substring(40, 42)
                 .trim()}`
             ),
             bpayRNo: eachBpayData?.substring(68, 89)?.trim(),
           };
           bpayParsedDataArr.push(bpayNewData);
         }
       });
       // Bpay record insert
       const bpayRecordInsrtRes = await wpBpayRecordInsert(
         wpApiReqParams,
         bpayParsedDataArr
       );
       if (bpayRecordInsrtRes === SUCCESS_STR) {
         logger.info("MSG: WP BPAY DOC - BPAY RECORD CREATION COMPLETED");
         // WP log update and sf platform event trigger
         wpLogAndEvntTriSts = await wpLogUpdtAndSfPltEveTrigger(
           wpLogId,
           currSysDateTime,
           SF_BPAY_PROCESS_BATCH_NAME
         );
       }
     } else {
       logger.info("MSG: BPAY DOC DATA ARRAY IS EMPTY");
     }
     return wpLogAndEvntTriSts;
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_CUSTOMER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(processBpayFileData.name, exp.message, `${wpFileName}`)
     );
     return null;
   }
 };
 
 /** ****************************************************
   // DATA EXTRACT FROM FILE & INITIATED DATA PROCESSING 
  ******************************************************* */
 
 /* START WP FILE PARSED DATA PROCESSING */
 function startWpFileParsedDataProcessing(wpApiReqParams, wpDocDataArr = []) {
   logger.info("***** startWpFileParsedDataProcessing() START *****");
   const { wpFileType, wpFileName } = wpApiReqParams;
   try {
     if (wpDocDataArr && wpDocDataArr.length > 0) {
       if (wpFileType === WP_FILE_TYPE_DE_EXCP) {
         // Innitiate excp deed data processing
         processExceptionDeedsFileData(wpApiReqParams, wpDocDataArr);
       } else if (wpFileType === WP_FILE_TYPE_DE_RET) {
         // Innitiate de rate data processing
         processDeRateFileData(wpApiReqParams, wpDocDataArr);
       } else if (
         wpFileType === WP_FILE_TYPE_BPAY ||
         wpFileType === WP_FILE_TYPE_BPAY_RECALL
       ) {
         // Innitiate bpay data processing
         processBpayFileData(wpApiReqParams, wpDocDataArr);
       }
     } else {
       logger.info(`${wpFileName} - PARSED FILE DATA ARRAY IS EMPMT`);
       throw new BaseError(WP_WPFILE_PARSED_DATA_ARRAY_EMPTY_MSG);
     }
   } catch (exp) {
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(
         startWpFileParsedDataProcessing.name,
         exp.message,
         `${wpFileName}`
       )
     );
   }
 }
 
 /* PARSE WP FILE & START DATA PROCESSING */
 function parseWpFile(wpApiReqParams, currSysDate, wpDoc) {
   logger.info("***** parseWpFile() START *****");
   const { wpFileName } = wpApiReqParams;
   try {
     // Get wpfile local path
     const wpFileLocalPath = `${WP_LOCAL_FILES_ROOT_DIRECTORY}/${currSysDate}/${wpFileName}`;
     if (saveWpFileContentInLocalFile(wpDoc, wpFileName, currSysDate)) {
       const wpDocParsedDataArr = [];
       // Create read stream from file
       const readStream = fs.createReadStream(wpFileLocalPath, UTF_8_STR);
       // Create read line instance
       const readLineInst = readline.createInterface({ input: readStream });
       // Data push in array for each line in file
       readLineInst.on(FILE_READ_LINE_EVENTS.line, (eachLine) => {
         wpDocParsedDataArr.push(eachLine?.toString(UTF_8_STR)?.trim());
       });
       // Throw error if any error occure during file reading
       readLineInst.on(FILE_READ_LINE_EVENTS.error, (error) => {
         logger.error(`${error.message} - FILE READING ERROR`);
         throw new BaseError(FAILED_TO_READ_FILE_MSG);
       });
       // On complete of file reading send data for processing
       readLineInst.on(FILE_READ_LINE_EVENTS.close, () => {
         logger.info(`${wpFileLocalPath} - FILE READING COMPLETED`);
         startWpFileParsedDataProcessing(wpApiReqParams, wpDocParsedDataArr);
       });
     } else {
       throw new BaseError(FAILED_TO_READ_FILE_MSG);
     }
   } catch (exp) {
     logger.error(`MSG: ERROR INSIDE parseWpFile() METHOD: ${exp.message}`);
     // Log insert event trigger
     sfLoggingEventTriggerApiCall(
       SENT_EMAIL_TO_DEVELOPER,
       SERVICE_NAME_WESTPAC,
       genErrorDetailsStr(parseWpFile.name, exp.message, `${wpFileName}`)
     );
   }
 }
 
 /** ********************
 // API REQUEST HANDLERS
  *********************** */
 
 /* WESTPACK REQUEST HANDLER INIT */
 export const westpackRequestHandler = async (req, res) => {
   logger.info("***** westpackRequestHandler() START *****");
   // Fetch current system date
   const { currSysDate, currSysDateTimeInUtc } = await getCurrSysDateApiCall();
   // Add cusrrent sustemdate time in wpApiTeqParams object.
   const wpApiReqParams = {
     ...req.body,
     currSysDateTime: currSysDateTimeInUtc,
   };
   // Get data from request body
   const { wpDocId, wpFileName, wpDocContentType } = wpApiReqParams;
   logger.info(`MSG: FILE TO PARSE - ${wpFileName}`);
   if (!currSysDate) throw new BaseError(CURRENT_SYSTEM_DATE_NOT_FOUND_MSG);
   // Fetch wp document
   const wpDoc = await getWpDocumentApiCall(wpDocId, wpDocContentType);
   if (wpDoc) {
     // Start wp document processing
     parseWpFile(wpApiReqParams, currSysDate, wpDoc);
     // API Response send just to ensure the request does not get terminated/timeout
     handleResponseStringified(
       res,
       genApiResponse(true, { msg: `${wpFileName} File Processing Initiated` })
     );
   } else {
     logger.info(`${wpFileName} - DOCUMENT CONTENT NOT FOUND`);
     throw new BadRequest(`${wpFileName} ${WP_DOCUMENT_NOT_FOUND_MSG}`);
   }
 };