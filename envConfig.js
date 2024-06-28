/** ****************************************************************************************************************
 * Name                 :   envConfig
 * Description          :   It validate the environemtn variables and stored it in local variables.
 * Developer            :   Kiranmoy Pradhan
 * Last Modified By     :   Kiranmoy Pradhan
 * Created Date         :   28/03/2022
 ***************************************************************************************************************** */

 import { config } from "dotenv";
 import { join } from "path";
 import pkgJoi from "joi";
 import { BaseError } from "../services/web/errorWebService";
 import { NODE_ENV_ARR } from "../services/utils/constantUtilService";
 
 config({ path: join(__dirname, "../../.env") });
 
 // Environment variable joe schema object create
 const envVarsSchema = pkgJoi
   .object()
   .keys({
     NODE_ENV: pkgJoi
       .string()
       .valid(...NODE_ENV_ARR)
       .required()
       .description("node environment"),
     PORT: pkgJoi.number().default(8000).description("server port"),
     DEBUG_MODE: pkgJoi
       .string()
       .valid("on", "off")
       .required()
       .description(
         "debug mode on/off to show/hide the api callout related loges"
       ),
     API_DEBUG_MODE: pkgJoi
       .string()
       .valid("on", "off")
       .required()
       .description("debug mode on/off to show/hide the api res related loges"),
     MW_ACCESS_KEY: pkgJoi.string().required().description("mw access key"),
     JSON_BODY_SIZE_LIMIT: pkgJoi
       .string()
       .required()
       .description("json body size limit"),
     MW_SERVER_DOMAIN: pkgJoi.string().description("middleware server domain"),
     WHITE_LISTED_REQ_METHODS: pkgJoi
       .string()
       .required()
       .description("whitelisted http methods for cors"),
     WHITE_LISTED_IP_LIST: pkgJoi
       .string()
       .description("whitelisted ip to access the api documents"),
     COMPANY_NAME: pkgJoi.string().required().description("company name"),
     SF_LOGIN_URL: pkgJoi.string().required().description("sf login url"),
     SF_USERNAME: pkgJoi.string().required().description("sf api user username"),
     SF_PASSWORD: pkgJoi.string().required().description("sf api user password"),
     SF_CA_CLIENT_ID: pkgJoi
       .string()
       .required()
       .description("sf connected app client id"),
     SF_CA_CLIENT_SECRET: pkgJoi
       .string()
       .required()
       .description("sf connected app client secret"),
     SF_WEBHOOK_DOMAIN: pkgJoi
       .string()
       .required()
       .description("sf webhook domain"),
     ILLION_OCR_DOMAIN: pkgJoi
       .string()
       .required()
       .description("Illion ocr api endpoint domain"),
     ILLION_OCR_API_KEY: pkgJoi
       .string()
       .required()
       .description("Illion ocr api access key"),
     WP_LOCAL_FILE_DELETE_JOB_ID: pkgJoi
       .string()
       .required()
       .description("Westpac local file delete job"),
     RECEIVABLE_BALANCE_REPORT_CRON_JOB_ID: pkgJoi
       .string()
       .required()
       .description("Receivable report gen job"),
     LOAN_DISBURSAL_FILEGEN_CRON_JOB_ID: pkgJoi
       .string()
       .required()
       .description("Loan disbursal file gen job"),
     BPAY_FILEGEN_CRON_JOB_ID: pkgJoi
       .string()
       .required()
       .description("Bpay file gen job"),
     LPT_FILEGEN_CRON_JOB_ID: pkgJoi
       .string()
       .required()
       .description("Lpt file gen job"),
     DAILY_TRANSACTION_REPORT_JOB_ID: pkgJoi
       .string()
       .required()
       .description("Daily transaction report access key"),
     DEBT_SALE_WEEKLY_ID: pkgJoi
       .string()
       .required()
       .description("Debt sale weekly job"),
     DEBT_SALE_MONTHLY_ID: pkgJoi
       .string()
       .required()
       .description("Debt sale monthly job"),
     PL_INS_POLICY_REPORT_JOB_ID: pkgJoi
       .string()
       .required()
       .description("PL insurance policy report access key"),
     PL_INS_TXN_REPORT_JOB_ID: pkgJoi
       .string()
       .required()
       .description("PL insurance txn report access key"),
     PL_INS_CHARGED_OFF_REPORT_JOB_ID: pkgJoi
       .string()
       .required()
       .description("PL insurance charged off report access key"),
     INTEREST_ACCRUED_NOT_CAPITALISED_REPORT_JOB_ID: pkgJoi
       .string()
       .required()
       .description("Interest Accrued not Capitalised report access key"),
     SUNDRY_CREDITOR_INVOICE_REPORT_JOB_ID: pkgJoi
       .string()
       .required()
       .description("Sundry Creditor Invoice report access key"),
     AML_FRN_JRS_JOB_ID: pkgJoi
       .string()
       .required()
       .description("AML Frn Jrs report access key"),
   })
   .unknown();
 
 /* VALIDATING THE ENV SCHEMA */
 const { value: envVars, error } = envVarsSchema
   .prefs({ errors: { label: "key" } })
   .validate(process.env);
 
 /* VALIDATION ERROR HANDLER */
 const validationErrorHandler = () => {
   /* THORW ERROR IF ERROR */
   if (error) {
     throw new BaseError(`Config validation error: ${error.message}`);
   }
 };
 
 /* CALL VALIDATION ERROR HANDLER */
 validationErrorHandler();
 
 /* COMPANY DETAILS */
 export const companyName = envVars.COMPANY_NAME;
 
 /* GENERIC */
 export const nodeEnv = envVars.NODE_ENV;
 export const port = envVars.PORT;
 export const debugMode = envVars.DEBUG_MODE;
 export const apiDebugMode = envVars.API_DEBUG_MODE;
 export const mwAccessKey = envVars.MW_ACCESS_KEY;
 export const jsonBodySizeLimit = envVars.JSON_BODY_SIZE_LIMIT;
 export const mwServerDomain = envVars.MW_SERVER_DOMAIN;
 
 /* CORS */
 export const whiteListed = {
   reqMethods: envVars.WHITE_LISTED_REQ_METHODS,
   ipForApiDocAccess: envVars.WHITE_LISTED_IP_LIST,
 };
 
 /* SALESFORCE CONNECT */
 export const sfConnectDetails = {
   loginUrl: envVars.SF_LOGIN_URL,
   username: envVars.SF_USERNAME,
   password: envVars.SF_PASSWORD,
   clientId: envVars.SF_CA_CLIENT_ID,
   clientSecret: envVars.SF_CA_CLIENT_SECRET,
 };
 
 /* SF OTHER DETAILS */
 export const sfOtherDet = {
   sfWebhookDomain: envVars.SF_WEBHOOK_DOMAIN,
 };
 
 /* Illion OCR */
 export const illionOcrDet = {
   apiDomain: envVars.ILLION_OCR_DOMAIN,
   apiAccessKey: envVars.ILLION_OCR_API_KEY,
 };
 
 /* CRON JOB IDs */
 export const cronJobIds = {
   wpLocalFileDeleteJobId: envVars.WP_LOCAL_FILE_DELETE_JOB_ID,
   recvBalanceReportJobId: envVars.RECEIVABLE_BALANCE_REPORT_CRON_JOB_ID,
   loanDisbursalFileJobId: envVars.LOAN_DISBURSAL_FILEGEN_CRON_JOB_ID,
   bpayFileGenJobId: envVars.BPAY_FILEGEN_CRON_JOB_ID,
   lptFileGenJobId: envVars.LPT_FILEGEN_CRON_JOB_ID,
   dailyTxnReportJobId: envVars.DAILY_TRANSACTION_REPORT_JOB_ID,
   debtSaleReportGenWeeklyId: envVars.DEBT_SALE_WEEKLY_ID,
   debtSaleReportGenMonthlyId: envVars.DEBT_SALE_MONTHLY_ID,
   plInsPolicyReportJobId: envVars.PL_INS_POLICY_REPORT_JOB_ID,
   plInsTxnReportJobId: envVars.PL_INS_TXN_REPORT_JOB_ID,
   plInschargedOffReportJobId: envVars.PL_INS_CHARGED_OFF_REPORT_JOB_ID,
   intAccNotCapReportJobId:
     envVars.INTEREST_ACCRUED_NOT_CAPITALISED_REPORT_JOB_ID,
   sunCredInvReportJobId: envVars.SUNDRY_CREDITOR_INVOICE_REPORT_JOB_ID,
   amlFrnJrsId: envVars.AML_FRN_JRS_JOB_ID,
 };
 