/** ****************************************************************************************************************
 * Name                 :   cronJobHandlers
 * Description          :   It contains all the handlers related to cron jobs.
 * Developer            :   Kiranmoy Pradhan
 * Last Modified By     :   Kiranmoy Pradhan
 * Created Date         :   27/02/2023
 ***************************************************************************************************************** */

 import { initBpayReportGen } from "../controllers/reports-ctrl/bpayCtrl";
 import { initdailyTransactionReportGen } from "../controllers/reports-ctrl/dailyTxnReportCtrl";
 import { initLoanDisFileReportGen } from "../controllers/reports-ctrl/loanDisbursalFileCtrl";
 import { initLoanPmtTxnFileReportGen } from "../controllers/reports-ctrl/loanPmtTxnFileCtrl";
 import { initPlInsPolicyReportGen } from "../controllers/reports-ctrl/plInsPolicyReportCtrl";
 import { initPlInsTxnReportGen } from "../controllers/reports-ctrl/plInsTxnReportCtrl";
 import { initPlInsChargedOffReportGen } from "../controllers/reports-ctrl/insChargedOffReportCtrl";
 import { initRecvBalanceReportGen } from "../controllers/reports-ctrl/receivableBalanceCtrl";
 import { initDebtSaleCustPmtReportGen } from "../controllers/reports-ctrl/debtSaleCustPmtCtrl";
 import { initIntAccNotCapReportGen } from "../controllers/reports-ctrl/intAccNotCapReportCtrl";
 import { initSundryCredInvReportGen } from "../controllers/reports-ctrl/sundryCredInvoiceCtrl";
 import {
   MONTH_STR,
   WEEK_STR,
   WP_FILE_TO_KEPT_IN_LOCAL,
   WP_LOCAL_FILES_ROOT_DIRECTORY,
 } from "../services/utils/constantUtilService";
 import {
   getDirectories,
   isFileOrFolderPresent,
   removeDirectory,
 } from "../services/utils/fileOperationsUtilService";
 import {
   isPreviousDateBetween,
   isLastDayOfMonth,
 } from "../services/utils/helperUtilService";
 import logger from "../services/utils/loggerUtilService";
 import { getCurrSysDateApiCall } from "../services/web/api/utils-api/sfUtilApiCall";
 import { initDebtSaleReportGen } from "../controllers/reports-ctrl/debtSaleCtrl";
 import { initAMLFrnJrdReportGen } from "../controllers/reports-ctrl/amlFrnJurisdictionCtrl";
 
 /* ****************
  * CRONJOB HANDLERS
  ****************** */
 
 /* WP FILE DELETION FROM LOCAL */
 export const wpLocalFilesDeleteCronHandler = async () => {
   logger.info("***** wpLocalFilesDeleteCronHandler() START *****");
   try {
     const deletedDirArr = [];
     if (isFileOrFolderPresent(WP_LOCAL_FILES_ROOT_DIRECTORY)) {
       // Fetch current system date
       const { currSysDate } = await getCurrSysDateApiCall();
       // Fetch all wp files all directories
       const wpFilesDateWiseDirArr = getDirectories(
         WP_LOCAL_FILES_ROOT_DIRECTORY
       );
       if (wpFilesDateWiseDirArr && wpFilesDateWiseDirArr.length > 0) {
         wpFilesDateWiseDirArr.forEach((eachDirName) => {
           // Check if the date is lies between specific previous days
           if (
             !isPreviousDateBetween(
               currSysDate,
               WP_FILE_TO_KEPT_IN_LOCAL,
               eachDirName
             )
           ) {
             // Craete the path of the folder/file to delete
             const dirPathToDelete = `${WP_LOCAL_FILES_ROOT_DIRECTORY}/${eachDirName}`;
             // Delete folder/file and store the deleted file reference in an array;
             if (removeDirectory(dirPathToDelete))
               deletedDirArr.push(eachDirName);
           }
         });
       }
       logger.info(`MSG: DELETED WP FILES DIRECTORIES :[${deletedDirArr}]`);
     } else {
       logger.info("MSG: WP FOLDER/FILES ROOT DIRECTORY NOT PRESENT");
     }
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${wpLocalFilesDeleteCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 /* RECEIVABLE BALANCE REPORT CRON HANDLER */
 export const recBalanceReportCronHandler = async () => {
   logger.info("***** recBalanceReportCronHandler() START *****");
   try {
     initRecvBalanceReportGen();
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${recBalanceReportCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 /* LOAN DISBURSAL FILE GEN REPORT CRON HANDLER */
 export const loanDisbursalFileGenCronHandler = async () => {
   logger.info("***** loanDisbursalFileGenCronHandler() START *****");
   try {
     initLoanDisFileReportGen();
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${loanDisbursalFileGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 /* BPAY FILE GEN REPORT CRON HANDLER */
 export const bpayFileGenCronHandler = async () => {
   logger.info("***** bpayFileGenCronHandler() START *****");
   try {
     initBpayReportGen();
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${bpayFileGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 /* LPT REPORT CRON HANDLER */
 export const lptFileGenCronHandler = async () => {
   logger.info("***** lptFileGenCronHandler() START *****");
   try {
     initLoanPmtTxnFileReportGen();
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${lptFileGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 /* DAILY TRANSACTION REPORT CRON HANDLER */
 export const dailyTxnReportGenCronHandler = async () => {
   logger.info("***** dailyTransactionReportGenCronHandler() START *****");
   try {
     initdailyTransactionReportGen();
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${dailyTxnReportGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 export const debtSaleWeeklyHandler = async () => {
   logger.info("***** debtSaleCustPmtWeeklyHandler() START *****");
   try {
     initDebtSaleCustPmtReportGen(null, WEEK_STR);
     initDebtSaleReportGen(null, WEEK_STR);
     logger.info(`MSG: DEBT SALE REPORT WEEKLY GENERATION INITTIATED`);
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${debtSaleWeeklyHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 export const debtSaleMonthlyHandler = async () => {
   logger.info("***** debtSaleCustPmtMonthlyHandler() START *****");
   try {
     initDebtSaleCustPmtReportGen(null, MONTH_STR);
     initDebtSaleReportGen(null, MONTH_STR);
     logger.info(`MSG: DEBT SALE REPORT MONTHLY GENERATION INITTIATED`);
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${debtSaleMonthlyHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 /* PL INSURANCE POLICY REPORT CRON HANDLER */
 export const plInsPolicyReportGenCronHandler = async () => {
   logger.info("***** plInsPolicyReportGenCronHandler() START *****");
   try {
     initPlInsPolicyReportGen();
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${plInsPolicyReportGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 /* PL INSURANCE TXN REPORT CRON HANDLER */
 export const plInsTxnReportGenCronHandler = async () => {
   logger.info("***** plInsTxnReportGenCronHandler() START *****");
   try {
     initPlInsTxnReportGen();
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${plInsTxnReportGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 /* PL INSURANCE CHARGED OFF REPORT CRON HANDLER */
 export const plInsChargedOffReportGenCronHandler = async () => {
   logger.info("***** plInsChargedOffReportGenCronHandler() START *****");
   try {
     initPlInsChargedOffReportGen();
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${plInsChargedOffReportGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
 };
 
 /* INTEREST ACCURED NOT CAPITALISED REPORT CRON HANDLER */
 export const intAccNotCapReportGenCronHandler = async () => {
   logger.info("***** intAccNotCapReportGenCronHandler() START *****");
   try {
     // Fetch current system date
     const { currSysDate } = await getCurrSysDateApiCall();
     if (isLastDayOfMonth(currSysDate)) {
       initIntAccNotCapReportGen();
     }
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${intAccNotCapReportGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
 };
 
 /* AML FOREIGN JURISDICTION - AU REPORT CRON HANDLER */
 export const intAmlFrnJrsReportGenCronHandler = async () => {
   logger.info("***** intAmlFrnJrsReportGenCronHandler() START *****");
   try {
     initAMLFrnJrdReportGen();
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${intAmlFrnJrsReportGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 
 /* SUNDRY CREDITOR INVOICE REPORT CRON HANDLER */
 export const sunCredInvReportGenCronHandler = async () => {
   logger.info("***** sunCredInvReportGenCronHandler() START *****");
   try {
     // Fetch current system date
     const { currSysDate } = await getCurrSysDateApiCall();
     if (isLastDayOfMonth(currSysDate)) {
       initSundryCredInvReportGen();
     }
   } catch (exp) {
     logger.info(
       `MSG: EXCEPTION INSIDE ${sunCredInvReportGenCronHandler.name} METHOD. ERROR : ${exp.message}`
     );
   }
   return null;
 };
 