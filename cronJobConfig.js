/** ****************************************************************************************************************
 * Name                 :   cronJobConfig
 * Description          :   It contains all the configurations related to cron jobs.
 * Developer            :   Kiranmoy Pradhan
 * Last Modified By     :   Kiranmoy Pradhan
 * Created Date         :   27/02/2023
 ***************************************************************************************************************** */

// eslint-disable-next-line import/no-extraneous-dependencies
import { CronJob } from "cron";
import {
  AUS_SYD_TIMEZONE,
  BLANK_STR,
  CRON_JOB_OFF,
  SENT_EMAIL_TO_DEVELOPER,
  SERVICE_NAME_CRONJOB,
} from "../services/utils/constantUtilService";
import { genErrorDetailsStr } from "../services/utils/helperUtilService";
import logger from "../services/utils/loggerUtilService";
import { sfLoggingEventTriggerApiCall } from "../services/web/api/utils-api/sfUtilApiCall";
import { cronJobIds } from "../conf/envConfig";
import {
  bpayFileGenCronHandler,
  dailyTxnReportGenCronHandler,
  debtSaleMonthlyHandler,
  debtSaleWeeklyHandler,
  loanDisbursalFileGenCronHandler,
  lptFileGenCronHandler,
  plInsPolicyReportGenCronHandler,
  plInsTxnReportGenCronHandler,
  recBalanceReportCronHandler,
  wpLocalFilesDeleteCronHandler,
  plInsChargedOffReportGenCronHandler,
  intAccNotCapReportGenCronHandler,
  sunCredInvReportGenCronHandler,
  intAmlFrnJrsReportGenCronHandler,
} from "./cronJobHandlers";

/* ****************
 * CRONJOB CONFIGs
 **************** */
/* INIT CRON JOBS */
export const initCronJob = async () => {
  try {
    // Wp file parse cron job
    if (
      cronJobIds?.wpLocalFileDeleteJobId &&
      cronJobIds?.wpLocalFileDeleteJobId.toString() !== CRON_JOB_OFF
    ) {
      const wpLocalFileDeleteJobInst = new CronJob(
        cronJobIds?.wpLocalFileDeleteJobId,
        () => {
          wpLocalFilesDeleteCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      wpLocalFileDeleteJobInst.start();
      logger.info(`MSG: INIT WP LOCAL FILE DELETION JOB`);
    }
    // Receivable balnce file gen cron job
    if (
      cronJobIds?.recvBalanceReportJobId &&
      cronJobIds?.recvBalanceReportJobId !== CRON_JOB_OFF
    ) {
      const recBalanceReportJobInst = new CronJob(
        cronJobIds?.recvBalanceReportJobId,
        () => {
          recBalanceReportCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      recBalanceReportJobInst.start();
      logger.info(`MSG: INIT RECEIVBALE BALANCE FILE GEN JOB`);
    }
    // Loan disbursal file gen cron job
    if (
      cronJobIds?.loanDisbursalFileJobId &&
      cronJobIds?.loanDisbursalFileJobId !== CRON_JOB_OFF
    ) {
      const loanDisbursalFileGenJobInst = new CronJob(
        cronJobIds?.loanDisbursalFileJobId,
        () => {
          loanDisbursalFileGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      loanDisbursalFileGenJobInst.start();
      logger.info(`MSG: INIT LOAN DISBURSAL FILE GEN JOB`);
    }
    // Bpay file gen cron job
    if (
      cronJobIds?.bpayFileGenJobId &&
      cronJobIds?.bpayFileGenJobId !== CRON_JOB_OFF
    ) {
      const bpayFileGenJobInst = new CronJob(
        cronJobIds?.bpayFileGenJobId,
        () => {
          bpayFileGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      bpayFileGenJobInst.start();
      logger.info(`MSG: INIT BPAY FILE GEN JOB`);
    }
    // Lpt file gen cron job
    if (
      cronJobIds?.lptFileGenJobId &&
      cronJobIds?.lptFileGenJobId !== CRON_JOB_OFF
    ) {
      const lptFileGenJobInst = new CronJob(
        cronJobIds?.lptFileGenJobId,
        () => {
          lptFileGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      lptFileGenJobInst.start();
      logger.info(`MSG: INIT LPT FILE GEN JOB`);
    }
    //  Daily transaction Report cron job
    if (
      cronJobIds?.dailyTxnReportJobId &&
      cronJobIds?.dailyTxnReportJobId !== CRON_JOB_OFF
    ) {
      const dailyTxnReportGenJobInst = new CronJob(
        cronJobIds?.dailyTxnReportJobId,
        () => {
          dailyTxnReportGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      dailyTxnReportGenJobInst.start();
      logger.info(`MSG: INIT DAILY TRANSACTION REPORT GEN JOB`);
    }
    //  PL insurance policy Report cron job
    if (
      cronJobIds?.plInsPolicyReportJobId &&
      cronJobIds?.plInsPolicyReportJobId !== CRON_JOB_OFF
    ) {
      const plInsPolicyReportGenJobInst = new CronJob(
        cronJobIds?.plInsPolicyReportJobId,
        () => {
          plInsPolicyReportGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      plInsPolicyReportGenJobInst.start();
      logger.info(`MSG: INIT PL INSURANCE POLICY REPORT GEN JOB`);
    }
    //  PL insurance txn Report cron job
    if (
      cronJobIds?.plInsTxnReportJobId &&
      cronJobIds?.plInsTxnReportJobId !== CRON_JOB_OFF
    ) {
      const plInsTxnReportGenJobInst = new CronJob(
        cronJobIds?.plInsTxnReportJobId,
        () => {
          plInsTxnReportGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      plInsTxnReportGenJobInst.start();
      logger.info(`MSG: INIT PL INSURANCE TXN REPORT GEN JOB`);
    }
    //  PL insurance charged off Report cron job
    if (
      cronJobIds?.plInschargedOffReportJobId &&
      cronJobIds?.plInschargedOffReportJobId !== CRON_JOB_OFF
    ) {
      const plInschargedOffReportGenJobInst = new CronJob(
        cronJobIds?.plInschargedOffReportJobId,
        () => {
          plInsChargedOffReportGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      plInschargedOffReportGenJobInst.start();
      logger.info(`MSG: INIT PL INSURANCE CHARGED OFF REPORT GEN JOB`);
    }
    // Debt sale report gen weekly
    if (
      cronJobIds?.debtSaleReportGenWeeklyId &&
      cronJobIds?.debtSaleReportGenWeeklyId.toString() !== CRON_JOB_OFF
    ) {
      const debtSaleWeeklyHandlerInst = new CronJob(
        cronJobIds?.debtSaleReportGenWeeklyId,
        () => {
          debtSaleWeeklyHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      debtSaleWeeklyHandlerInst.start();
      logger.info(`MSG: INIT DEBT SALE WEEKLY GENERATION JOB INITIATED`);
    }
    // Debt sale report gen monthly
    if (
      cronJobIds?.debtSaleReportGenMonthlyId &&
      cronJobIds?.debtSaleReportGenMonthlyId.toString() !== CRON_JOB_OFF
    ) {
      const debtSaleMonthlyHandlerInst = new CronJob(
        cronJobIds?.debtSaleReportGenMonthlyId,
        () => {
          debtSaleMonthlyHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      debtSaleMonthlyHandlerInst.start();
      logger.info(`MSG: INIT DEBT SALE MONTHLY GENERATION JOB INITIATED`);
    }
    // Interest Accrued not Capitalised Report Cron Job
    if (
      cronJobIds?.intAccNotCapReportJobId &&
      cronJobIds?.intAccNotCapReportJobId !== CRON_JOB_OFF
    ) {
      const intAccNotCapReportGenJobInst = new CronJob(
        cronJobIds?.intAccNotCapReportJobId,
        () => {
          intAccNotCapReportGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      intAccNotCapReportGenJobInst.start();
      logger.info(`MSG: INIT INTEREST ACCURED NOT CAPITALISED REPORT GEN JOB`);
    }

    // Sundry Creditor Invoice report Report Cron Job
    if (
      cronJobIds?.sunCredInvReportJobId &&
      cronJobIds?.sunCredInvReportJobId !== CRON_JOB_OFF
    ) {
      const sunCredInvReportGenJobInst = new CronJob(
        cronJobIds?.sunCredInvReportJobId,
        () => {
          sunCredInvReportGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      sunCredInvReportGenJobInst.start();
      logger.info(`MSG: INIT SUNDRY CREDITOR INVOICE REPORT GEN JOB`);
    }

    // AML Foreign Jurisdiction - AU report cron job
    if (cronJobIds?.amlFrnJrsId && cronJobIds?.amlFrnJrsId !== CRON_JOB_OFF) {
      const intAmlFrnJrsReportGenJobInst = new CronJob(
        cronJobIds?.amlFrnJrsId,
        () => {
          intAmlFrnJrsReportGenCronHandler();
        },
        null,
        true,
        AUS_SYD_TIMEZONE
      );
      intAmlFrnJrsReportGenJobInst.start();
      logger.info(`MSG: INIT AML FOREIGN JURISDICTION REPORT GEN JOB`);
    }
  } catch (exp) {
    logger.info(
      `MSG: EXCEPTION INSIDE ${initCronJob.name} METHOD. ERROR : ${exp.message}`
    );
    // Log insert event trigger
    sfLoggingEventTriggerApiCall(
      SENT_EMAIL_TO_DEVELOPER,
      SERVICE_NAME_CRONJOB,
      genErrorDetailsStr(initCronJob.name, exp.message, BLANK_STR)
    );
  }
};
