/** ****************************************************************************************************************
 * Name                 :   sundryCredInvoiceCtrl
 * Description          :   This controller will handle the Sundry Creditor Invoice Report generation
 * Developer            :   Supriyo Seni
 * Last Modified By     :   Supriyo Seni
 * Created Date         :   03/05/2023
 ***************************************************************************************************************** */
 import {
    BLANK_STR,
    COMMA_STR,
    DASH_STR,
    SENT_EMAIL_TO_CUSTOMER,
    SENT_EMAIL_TO_DEVELOPER,
    SERVICE_NAME_REPORT,
    FORWARD_SLACE_STR,
    SUNDRY_CREDITOR_REPORT_FOLDER,
    REPORT_NAME_SUNDRY_CREDITOR_INVOICE,
    SUNDRY_CREDITOR_INVOICE_REPORT_QUERY,
    SUNDRY_CREDITOR_INVOICE_REPORT__HEADERS,
    SUNDRY_CREDITOR_INVOICE_REPORT_COLUMNS,
    SUNDRY_CREDITOR_INVOICE_REPORT__HEADING,
    SUNDRY_CREDITOR_INVOICE_REPORT_TOTAL,
    DATE_DD_MM_YYYY_FORMATE,
    CURRENCY,
    CURRENCY_USD,
    ENFORCEMENT_FEE,
    ENFORCEMENT_FEE_WAIVED,
    CURRENT_MONTH_STR,
    CURRENT_YEAR_STR,
  } from "../../services/utils/constantUtilService";
  import {
    genApiResponse,
    genErrorDetailsStr,
    getCurrencyFormat,
    getDateFromStr,
    getDayMonthYearFromDate,
  } from "../../services/utils/helperUtilService";
  import logger from "../../services/utils/loggerUtilService";
  import {
    BULK_DATA_QUERY_FAILED,
    REPORT_GEN_FAILED_MSG,
    REPORT_GEN_INITIATED_MSG,
  } from "../../services/utils/msgUtilService";
  import { uploadReportsInLibraryOfSfApiCall } from "../../services/web/api/reports-api/reportsApiCall";
  import {
    getCurrSysDateApiCall,
    sfLoggingEventTriggerApiCall,
  } from "../../services/web/api/utils-api/sfUtilApiCall";
  import { BaseError } from "../../services/web/errorWebService";
  import { sfAsyncQueryHugeDataAndProcess } from "../../services/web/requestWebService";
  import { handleResponseStringified } from "../../services/web/responseWebService";
  import { generateCsvFileString } from "../../services/utils/csvGeneratorUtilService";
  /** ********
        // VARIABLES
         *********** */
  let reqFilterDate;
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
          `${REPORT_NAME_SUNDRY_CREDITOR_INVOICE}`
        )
      );
    }
  };
  /* GENERATE CSV REPORT DATA ATRRAY */
  const genCsvReportDataArr = (dataArr = []) => {
    logger.info("***** genCsvReportDataArr() START *****");
    const csvReportDataArr = [];
    try {
      // Blank row data object prepare;
      const blankRow = {
        ...SUNDRY_CREDITOR_INVOICE_REPORT_COLUMNS,
        postingDate: BLANK_STR,
        effectiveDate: BLANK_STR,
        transactionName: BLANK_STR,
        transactionId: BLANK_STR,
        contractId: BLANK_STR,
        customerName: BLANK_STR,
        productNumber: BLANK_STR,
        invoiceDate: BLANK_STR,
        invoiceNumber: BLANK_STR,
        vendorName: BLANK_STR,
        invoiceDesc: BLANK_STR,
        invAmtIncGst: BLANK_STR,
        totalGstAmount: BLANK_STR,
        invAmtExcGst: BLANK_STR,
        gstChargedAmt: BLANK_STR,
        gstRecoveryAmt: BLANK_STR,
        amtCusCharged: BLANK_STR,
        q2Userprofile: BLANK_STR,
      };
      // Bottom of csv show sumation of different data, initial csv data object create for that
      const amtTotalCont = {
        ...SUNDRY_CREDITOR_INVOICE_REPORT_COLUMNS,
        postingDate: SUNDRY_CREDITOR_INVOICE_REPORT_TOTAL.totalLabel,
      };
      // Read each data in the list and create csv data array
      if (dataArr && dataArr.length > 0) {
        dataArr.forEach((eachData) => {
          let loanFeePmtArr;
          if (eachData.loan__Fee_Payment__r) {
            loanFeePmtArr = Object.values(eachData.loan__Fee_Payment__r);
          }
          // Report data list prepare
          csvReportDataArr.push({
            ...SUNDRY_CREDITOR_INVOICE_REPORT_COLUMNS,
            postingDate:
              getDateFromStr(eachData?.CreatedDate, DATE_DD_MM_YYYY_FORMATE) ??
              BLANK_STR,
            effectiveDate:
              getDateFromStr(eachData?.loan__Date__c, DATE_DD_MM_YYYY_FORMATE) ??
              BLANK_STR,
            transactionId: eachData?.Name ?? BLANK_STR,
            transactionName: ENFORCEMENT_FEE,
            contractId: eachData?.loan__Loan_Account__r?.Name ?? BLANK_STR,
            customerName:
              eachData?.loan__Loan_Account__r?.loan__Account__r?.Name ??
              BLANK_STR,
            productNumber:
              eachData?.loan__Loan_Account__r?.loan__Loan_Product_Name__r
                ?.loan__Loan_Product_Code__c ?? BLANK_STR,
            invoiceDate:
              getDateFromStr(
                eachData?.Invoice_Date__c,
                DATE_DD_MM_YYYY_FORMATE
              ) ?? BLANK_STR,
            invoiceNumber: eachData?.Invoice_Number__c ?? BLANK_STR,
            vendorName: eachData?.Supplier_Name__c ?? BLANK_STR,
            invoiceDesc: eachData?.Description__c ?? BLANK_STR,
            invAmtIncGst: getCurrencyFormat(
              eachData?.Gross_Invoice_Amount_including_GST__c ?? 0,
              2,
              CURRENCY,
              CURRENCY_USD
            ),
            totalGstAmount: getCurrencyFormat(
              eachData?.GST__c ?? 0,
              2,
              CURRENCY,
              CURRENCY_USD
            ),
            invAmtExcGst: getCurrencyFormat(
              eachData?.Invoice_Amount_excluding_GST__c ?? 0,
              2,
              CURRENCY,
              CURRENCY_USD
            ),
            gstChargedAmt: getCurrencyFormat(
              eachData?.GST_Charged_to_Customer__c ?? 0,
              2,
              CURRENCY,
              CURRENCY_USD
            ),
            gstRecoveryAmt: getCurrencyFormat(
              eachData?.GST_Recovery_Amount__c ?? 0,
              2,
              CURRENCY,
              CURRENCY_USD
            ),
            amtCusCharged: getCurrencyFormat(
              (eachData?.Invoice_Amount_excluding_GST__c ?? 0) +
                (eachData?.GST_Charged_to_Customer__c ?? 0),
              2,
              CURRENCY,
              CURRENCY_USD
            ),
            q2Userprofile: eachData?.CreatedBy?.Name ?? BLANK_STR,
          });
          // Total amount calculation
          amtTotalCont.invAmtIncGst +=
            eachData?.Gross_Invoice_Amount_including_GST__c ?? 0;
          amtTotalCont.totalGstAmount += eachData?.GST__c ?? 0;
          amtTotalCont.invAmtExcGst +=
            eachData?.Invoice_Amount_excluding_GST__c ?? 0;
          amtTotalCont.gstChargedAmt += eachData?.GST_Charged_to_Customer__c ?? 0;
          amtTotalCont.gstRecoveryAmt += eachData?.GST_Recovery_Amount__c ?? 0;
          amtTotalCont.amtCusCharged +=
            eachData?.Amount_Charged_to_Customer__c ?? 0;
  
          // If Charged is waived then add waived transactions
          if (
            eachData.loan__Waive__c &&
            loanFeePmtArr &&
            loanFeePmtArr.length >= 2
          ) {
            loanFeePmtArr[2].forEach((eachElement) => {
              csvReportDataArr.push({
                ...SUNDRY_CREDITOR_INVOICE_REPORT_COLUMNS,
                postingDate:
                  getDateFromStr(
                    eachElement?.CreatedDate,
                    DATE_DD_MM_YYYY_FORMATE
                  ) ?? BLANK_STR,
                effectiveDate:
                  getDateFromStr(
                    eachElement?.loan__Transaction_Date__c,
                    DATE_DD_MM_YYYY_FORMATE
                  ) ?? BLANK_STR,
                transactionId:
                  eachElement?.loan__Loan_Payment_Transaction__r?.Name ??
                  BLANK_STR,
                transactionName: ENFORCEMENT_FEE_WAIVED,
                contractId: eachData?.loan__Loan_Account__r?.Name ?? BLANK_STR,
                customerName:
                  eachData?.loan__Loan_Account__r?.loan__Account__r?.Name ??
                  BLANK_STR,
                productNumber:
                  eachData?.loan__Loan_Account__r?.loan__Loan_Product_Name__r
                    ?.loan__Loan_Product_Code__c ?? BLANK_STR,
                invoiceDate:
                  getDateFromStr(
                    eachData?.Invoice_Date__c,
                    DATE_DD_MM_YYYY_FORMATE
                  ) ?? BLANK_STR,
                invoiceNumber: eachData?.Invoice_Number__c ?? BLANK_STR,
                vendorName: eachData?.Supplier_Name__c ?? BLANK_STR,
                invoiceDesc: eachData?.Description__c ?? BLANK_STR,
                invAmtIncGst: getCurrencyFormat(
                  -(eachData?.Gross_Invoice_Amount_including_GST__c ?? 0),
                  2,
                  CURRENCY,
                  CURRENCY_USD
                ),
                totalGstAmount: getCurrencyFormat(
                  -(eachData?.GST__c ?? 0),
                  2,
                  CURRENCY,
                  CURRENCY_USD
                ),
                invAmtExcGst: getCurrencyFormat(
                  -(eachData?.Invoice_Amount_excluding_GST__c ?? 0),
                  2,
                  CURRENCY,
                  CURRENCY_USD
                ),
                gstChargedAmt: getCurrencyFormat(
                  -(eachData?.GST_Charged_to_Customer__c ?? 0),
                  2,
                  CURRENCY,
                  CURRENCY_USD
                ),
                gstRecoveryAmt: getCurrencyFormat(
                  -(eachData?.GST_Recovery_Amount__c ?? 0),
                  2,
                  CURRENCY,
                  CURRENCY_USD
                ),
                amtCusCharged: getCurrencyFormat(
                  -(
                    (eachData?.Invoice_Amount_excluding_GST__c ?? 0) +
                    (eachData?.GST_Charged_to_Customer__c ?? 0)
                  ),
                  2,
                  CURRENCY,
                  CURRENCY_USD
                ),
                q2Userprofile: eachElement?.CreatedBy?.Name ?? BLANK_STR,
              });
              // Total amount calculation
              amtTotalCont.invAmtIncGst -=
                eachData?.Gross_Invoice_Amount_including_GST__c ?? 0;
              amtTotalCont.totalGstAmount -= eachData?.GST__c ?? 0;
              amtTotalCont.invAmtExcGst -=
                eachData?.Invoice_Amount_excluding_GST__c ?? 0;
              amtTotalCont.gstChargedAmt -=
                eachData?.GST_Charged_to_Customer__c ?? 0;
              amtTotalCont.gstRecoveryAmt -=
                eachData?.GST_Recovery_Amount__c ?? 0;
              amtTotalCont.amtCusCharged -=
                eachData?.Amount_Charged_to_Customer__c ?? 0;
            });
          }
        });
  
        // Blank row add
        csvReportDataArr.push(blankRow);
        // Push sumationed data objests in csv report data array
        csvReportDataArr.push({
          ...amtTotalCont,
          invAmtIncGst: getCurrencyFormat(
            amtTotalCont.invAmtIncGst,
            2,
            CURRENCY,
            CURRENCY_USD
          ),
          totalGstAmount: getCurrencyFormat(
            amtTotalCont.totalGstAmount,
            2,
            CURRENCY,
            CURRENCY_USD
          ),
          invAmtExcGst: getCurrencyFormat(
            amtTotalCont.invAmtExcGst,
            2,
            CURRENCY,
            CURRENCY_USD
          ),
          gstChargedAmt: getCurrencyFormat(
            amtTotalCont.gstChargedAmt,
            2,
            CURRENCY,
            CURRENCY_USD
          ),
          gstRecoveryAmt: getCurrencyFormat(
            amtTotalCont.gstRecoveryAmt,
            2,
            CURRENCY,
            CURRENCY_USD
          ),
          amtCusCharged: getCurrencyFormat(
            amtTotalCont.amtCusCharged,
            2,
            CURRENCY,
            CURRENCY_USD
          ),
        });
      }
      return csvReportDataArr;
    } catch (exp) {
      logger.error(
        `EXCEPTION INSIDE ${genCsvReportDataArr.name} METHOD. ERROR : ${exp.message}`
      );
      // Log insert event trigger
      sfLoggingEventTriggerApiCall(
        SENT_EMAIL_TO_DEVELOPER,
        SERVICE_NAME_REPORT,
        genErrorDetailsStr(
          genCsvReportDataArr.name,
          exp.message,
          `${REPORT_NAME_SUNDRY_CREDITOR_INVOICE}`
        )
      );
      return null;
    }
  };
  /* GENERATE REPORT FILE */
  const genReport = async (csvReportDataArr = []) => {
    try {
      logger.info("***** genReport() START *****");
      // Fetch current system date
      const { currSysDate, localDateInDDMMYYYY, localTime } =
        await getCurrSysDateApiCall();
      // Report heading generate
      const reportHeading = `${Object.values({
        ...SUNDRY_CREDITOR_INVOICE_REPORT_COLUMNS,
  
        postingDate: SUNDRY_CREDITOR_INVOICE_REPORT__HEADING,
        effectiveDate: BLANK_STR,
        transactionName: BLANK_STR,
        transactionId: BLANK_STR,
        contractId: BLANK_STR,
        productNumber: BLANK_STR,
        invoiceDate: BLANK_STR,
        invoiceNumber: BLANK_STR,
        vendorName: BLANK_STR,
        invoiceDesc: BLANK_STR,
        invAmtIncGst: BLANK_STR,
        totalGstAmount: BLANK_STR,
        invAmtExcGst: BLANK_STR,
        gstChargedAmt: BLANK_STR,
        gstRecoveryAmt: BLANK_STR,
        amtCusCharged: BLANK_STR,
        q2Userprofile: BLANK_STR,
        customerName: `Report Run on ${localDateInDDMMYYYY.replaceAll(
          DASH_STR,
          FORWARD_SLACE_STR
        )} at ${localTime}`,
      }).join(COMMA_STR)}\r\n`;
      // Report content prepare
      if (csvReportDataArr) {
        // Csv report string generate
        const sundryCredInvReportCsvStr = generateCsvFileString(
          SUNDRY_CREDITOR_INVOICE_REPORT__HEADERS,
          csvReportDataArr
        );
        // Report file name
        const csvFileName = `	Q2_AU_PL_SUNDRY_CREDITOR_INVOICES_${(
          reqFilterDate ?? currSysDate
        ).replaceAll(DASH_STR, BLANK_STR)}.csv`;
        // Report insertion api call
        const insertReportApiRes = await uploadReportsInLibraryOfSfApiCall(
          csvFileName,
          `${reportHeading}${sundryCredInvReportCsvStr}`,
          SUNDRY_CREDITOR_REPORT_FOLDER
        );
        logger.info(
          `MSG: ${csvFileName} ${
            insertReportApiRes ? "INSERTED" : "INSERTION FAILED"
          } IN ${SUNDRY_CREDITOR_REPORT_FOLDER} FOLDER`
        );
      } else {
        throw new BaseError(REPORT_GEN_FAILED_MSG);
      }
    } catch (exp) {
      logger.error(
        `EXCEPTION INSIDE ${genReport.name} METHOD. ERROR : ${exp.message}`
      );
      // Log insert event trigger
      sfLoggingEventTriggerApiCall(
        SENT_EMAIL_TO_CUSTOMER,
        SERVICE_NAME_REPORT,
        genErrorDetailsStr(
          genReport.name,
          exp.message,
          `${REPORT_NAME_SUNDRY_CREDITOR_INVOICE}`
        )
      );
    }
  };
  /* GENERATE DATA ARRAY */
  const genSundryCredInvDataArr = async (dataArr = []) => {
    try {
      logger.info("***** genSundryCredInvDataArr() START *****");
      // Generate final csv report data array
      const finalCsvReportDataArr = genCsvReportDataArr(dataArr);
      // initiate csv report generation
      genReport(finalCsvReportDataArr);
    } catch (exp) {
      logger.error(
        `EXCEPTION INSIDE ${genSundryCredInvDataArr.name} METHOD. ERROR : ${exp.message}`
      );
      // Log insert event trigger
      sfLoggingEventTriggerApiCall(
        SENT_EMAIL_TO_CUSTOMER,
        SERVICE_NAME_REPORT,
        genErrorDetailsStr(
          genSundryCredInvDataArr.name,
          exp.message,
          `${REPORT_NAME_SUNDRY_CREDITOR_INVOICE}`
        )
      );
    }
  };
  /* INIT SUNDRY CREDITOR INVOICE REPORT GENERATION */
  export const initSundryCredInvReportGen = async () => {
    try {
      logger.info("***** initSundryCredInvReportGen() START *****");
      // Fetch current system date
      const { currSysDate } = await getCurrSysDateApiCall();
      const { month, year } = getDayMonthYearFromDate(
        reqFilterDate ?? currSysDate
      );
      let sundryCredInvReportQuery = SUNDRY_CREDITOR_INVOICE_REPORT_QUERY;
      sundryCredInvReportQuery = sundryCredInvReportQuery.replace(
        CURRENT_MONTH_STR,
        month
      );
      sundryCredInvReportQuery = sundryCredInvReportQuery.replace(
        CURRENT_YEAR_STR,
        year
      );
      // Charge Query and initiate report generation
      sfAsyncQueryHugeDataAndProcess(
        sundryCredInvReportQuery,
        genSundryCredInvDataArr,
        hugeDataQueryErrHandler
      );
    } catch (exp) {
      logger.error(
        `MSG: ERROR INSIDE ${initSundryCredInvReportGen.name} METHOD: ${exp.message}`
      );
      // Log insert event trigger
      sfLoggingEventTriggerApiCall(
        SENT_EMAIL_TO_CUSTOMER,
        SERVICE_NAME_REPORT,
        genErrorDetailsStr(
          initSundryCredInvReportGen.name,
          exp.message,
          `${REPORT_NAME_SUNDRY_CREDITOR_INVOICE}`
        )
      );
    }
  };
  /** ********************
        // API REQUEST HANDLERS
         *********************** */
  /* SUNDRY CREDITOR INVOICE REPORT HANDLER INIT */
  export const sundryCredInvoiceHandler = async (req, res) => {
    logger.info("***** sundryCredInvoiceHandler() START *****");
  
    // Receiving filter Date
    const { filterDate } = req.body;
    reqFilterDate = filterDate;
  
    // Init Sundry Creditor Invoice report generation
    initSundryCredInvReportGen();
    // API Response send just to ensure the request does not get terminated/timeout
    handleResponseStringified(
      res,
      genApiResponse(true, { msg: REPORT_GEN_INITIATED_MSG })
    );
  };
  