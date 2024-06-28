/** ****************************************************************************************************************
 * Name                 :   constantUtilService
 * Description          :   It containe all the constants.
 * Developer            :   Kiranmoy Pradhan
 * Last Modified By     :   Kiranmoy Pradhan
 * Created Date         :   14/03/2022
 ***************************************************************************************************************** */

/** *******
 * GENERAL
 ********* */

/* ENVIRONMENT */
export const PROD_ENV = "production";
export const DEV_ENV = "development";
export const TEST_ENV = "test";
export const LOCAL_ENV = "localhost";
export const DEBUG_MODE_ON = "on";
export const DEBUG_MODE_OFF = "off";
export const API_DEBUG_MODE_ON = "on";
export const API_DEBUG_MODE_OFF = "off";
export const NODE_ENV_ARR = ["production", "development", "test", "localhost"];
/* STATIC STRING */
export const ERROR_STR = "ERROR";
export const SUCCESS_STR = "SUCCESS";
export const KEY_STR = "key";
export const BASE64_STR = "base64";
export const BINARY_STR = "binary";
export const PDF_FILE_EXT_STR = ".pdf";
export const DOC_CONTENT_TYPE_CV = "CV";
export const DOC_CONTENT_TYPE_ATC = "ATC";
export const DERPS_STR = "DERPS";
export const DEEDS_STR = "DEEDS";
export const UTF_8_STR = "utf-8";
export const LOAN_TRAN_TYPE_REFUND_STR = "Refund";
export const CREDIT = "Credit";
export const DEBIT = "Debit";
export const N_STR = "N";
export const LATITUDE_LOANS = "LATITUDE LOANS";
export const ZERO_8 = "00000000";
export const CURRENCY = "currency";
export const CURRENCY_USD = "USD";
export const NA_STR = "N/A";
export const QUERY_START_DATE = "queryStartDate";
export const QUERY_END_DATE = "queryEndDate";
export const CANCELLED = "Cancelled";
export const TRUE = "True";
export const FALSE = "False";
export const AU = "AU";

/* FILE RELATED */
export const CSV_FILE_MIME_TYPE = "text/csv";
export const FILE_EXT_TXT = ".txt";
export const FILE_EXT_CSV = ".csv";

/* NUMBERS */
export const INT_10_STR = "10";
export const INT_6_STR = "6";
export const INT_1_STR = "1";
export const INT_0_STR = "0";
export const INT_50_STR = "50";
export const INT_7_STR = "7";
export const NINE_STR = "999-999";
export const DEBT = "0000000000";
export const BSB_NUM_MAX_DIGIT = 6;
export const ACC_NUM_MAX_DIGIT = 9;
export const AMOUNT_MAX_DIGIT = 10;
export const ACC_NAME_MAX_CHAR = 32;
export const LOPDGE_NAME_MAX_CHAR = 18;
export const INT_11_STR = "11";
export const INT_21_STR = "21";
export const INT_31_STR = "31";

/* FORM DATA */
export const BOUNDARY_STRING = "boundary_string";
export const ENTITY_CONTENT = "entity_content";
export const MULTIPART_FORM = "multipart/form-data; boundary='boundary_string'";
export const APPLICATION_JSON = "application/json";
export const VERSION_DATA = "VersionData";
export const ORIGIN_H = "H";
export const ORIGIN_I = "I";
export const CONTENT_TYPE = "Content-Type";
export const ALL_USER = "AllUsers";

/* WESTPACK RELATED */
export const WP_LOCAL_FILES_ROOT_DIRECTORY = "./westpac-files";
export const WP_FILE_TYPE_DE_EXCP = "DE_EXCP";
export const WP_FILE_TYPE_DE_RET = "DE_RET";
export const WP_FILE_TYPE_BPAY = "BPAY_040851";
export const DE_RET_LPT_DATA_TYPE = "LPT-";
export const DE_RET_SBI_DATA_TYPE = "SBI";
export const DE_RET_DDI_DATA_TYPE = "DDI";
export const BPAY_MODE = "Bpay";
export const WP_PASS_CODE = "0000G";
export const WP_REVERSAL_CODE = "0000R";
export const BPAY_HEADER_ORG_NAME = [
  "LATITUDE PERSNL LOAN",
  "LATITUDE P LOANS",
  "LATITU-PRSNL PYMT",
];
export const WP_WERPS_CODE_DETAILS = {
  1: "Invalid BSB Number",
  2: "Payment Stopped",
  3: "Account Closed",
  4: "Customer deceased",
  5: "No account/incorrect account Number",
  6: "Insufficient Funds",
  7: "Deleted",
  8: "Invalid User ID Number",
  9: "Technically Invalid",
  10: "Refer to customer",
};
export const WP_REFUND_REVERSAL_CSV_REPORT_HEADERS = [
  { id: "fileDate", title: "File Date" },
  { id: "clContrac", title: "CL Contract" },
  { id: "customerName", title: "Customer Name" },
  { id: "reference", title: "Reference" },
  { id: "otherBankRefNumber", title: "Other Bank Ref Number" },
  { id: "bsbAndAcct", title: "BSB & Acct" },
  { id: "txnDate", title: "Txn Date" },
  { id: "amount", title: "Amount" },
  { id: "exceptionReason", title: "Exception Reason" },
];
export const WP_DDI_REVERSAL_CSV_REPORT_HEADERS = [
  { id: "fileDate", title: "File Date" },
  { id: "clContrac", title: "CL Contract" },
  { id: "customerName", title: "Customer Name" },
  { id: "reference", title: "Reference" },
  { id: "otherBankRefNumber", title: "Other Bank Ref Number" },
  { id: "bsbAndAcct", title: "BSB & Acct" },
  { id: "txnDate", title: "Txn Date" },
  { id: "amount", title: "Amount" },
  { id: "exceptionReason", title: "Exception Reason" },
];
export const WP_BANK_REJECT_REPORT_NAME = "Bank Reject Report";
export const WP_DDI_STR = "DDI";
export const WP_FILE_TO_KEPT_IN_LOCAL = 2; // days of wp file backup
export const DIRECT_CREDIT = "Direct Credit";
export const CRN_NOT_FOUND_IN_LOAN = "CRN Number not found";

/* REPORT RELATED */
// Folder name
export const LFS_FINANCE_FOLDER = "Latitude Finance Folder";
export const LFS_LOAN_PMT_TXN_FOLDER = "LFS Loan PMT TXN FILES";
export const ACH_FOLDER_NAME = "ACH Documents";
export const BPAY_REPORT_FOLDER_NAME = "BPAY";
export const INSURANCE_REPORTS_FOLDER = "Insurance Reports";
export const DEBT_SALE_FOLDER_NAME = "Debt Sale Report";
export const DEBT_SALE_PMT_FOLDER_NAME = "Debt Sale Report Cust Pmt";
export const AML_FRN_JURISDIXN_REPORTS_FOLDER =
  "AML Foreign Jurisdiction Reports";
export const SUNDRY_CREDITOR_REPORT_FOLDER = "Sundry Creditor Report";
export const INTEREST_ACCURED_REPORT = "Interest Accrued Report";

// Receivable balance report
export const RECEIVABLE_BALANCE_REPORT_HEADING =
  "LATITUDE FINANCIAL SERVICES_Q2 Receivable Balance with Charge-offs_Personal Loans (AU)";
export const RECEIVABLE_BALANCE_REPORT_HEADERS = [
  { id: "productCode", title: "Product Code" },
  { id: "loanProductName", title: "Loan Product Name" },
  { id: "clContractId", title: "CL Contract ID" },
  { id: "icbsCustomerNoteNumber", title: "ICBS Customer Note Number" },
  { id: "customerStatus", title: "Customer Status" },
  { id: "isTestData", title: "Is This a Test Data" },
  { id: "daysPastDue", title: "Days Past Due" },
  { id: "paidOffDate", title: "Paid Off Date" },
  { id: "chargedOffDate", title: "Charged Off Date" },
  { id: "closingPrincipalBalance", title: "Closing Principal Balance" },
  { id: "closingInterestBalance", title: "Closing Interest Balance" },
  { id: "closingFeeBalance", title: "Closing Fee Balance" },
  { id: "closingLoanBalance", title: "Closing Loan Balance" },
  { id: "chargedOffPrincipal", title: "Charged Off Principal" },
  {
    id: "chargedOffCapitalizedInterest",
    title: "Charged Off Capitalized Interest",
  },
  { id: "chargedOffCapitalizedFees", title: "Charged Off Capitalized Fees" },
  { id: "totalRecoveryAmtPaid", title: "Total Recovery Amt Paid" },
  { id: "loanBalance", title: "Loan Balance" },
  {
    id: "inteAccruedNotCapitalised",
    title: "Interest Accrued not Capitalised",
  },
  { id: "excess", title: "Excess" },
  { id: "interestRemaining", title: "Interest Remaining" },
  { id: "lateFees", title: "Late Fees" },
];
export const RECEIVABLE_BALANCE_REPORT_SUMATION_LABELS = {
  totalRecLabel: "TOTAL RECEIVABLES",
  totalRecProd0002Label: "Total Receivables Product 0002",
  totalRecProd0666Label: "Total Receivables Product 0666",
  totalRecProd0667Label: "Total Receivables Product 0667",
  totalRecProd0668Label: "Total Receivables Product 0668",
  totalRecProd0669Label: "Total Receivables Product 0669",
  totalRecTestDataLabel: "TOTAL RECEIVABLES - Test Data",
};
export const RECEIVABLE_BALANCE_REPORT_COLUMNS = {
  productCode: "",
  loanProductName: "",
  clContractId: "",
  icbsCustomerNoteNumber: "",
  customerStatus: "",
  isTestData: "",
  daysPastDue: "",
  paidOffDate: "",
  chargedOffDate: "",
  closingPrincipalBalance: 0,
  closingInterestBalance: 0,
  closingFeeBalance: 0,
  closingLoanBalance: 0,
  chargedOffPrincipal: 0,
  chargedOffCapitalizedInterest: 0,
  chargedOffCapitalizedFees: 0,
  totalRecoveryAmtPaid: 0,
  loanBalance: 0,
  inteAccruedNotCapitalised: 0,
  excess: 0,
  interestRemaining: 0,
  lateFees: 0,
};
export const LOAN_PRODUCT_PERSONAL_LOAN = "Personal Loan";
export const LOAN_PRODUCT_PERSONAL_LOAN_FIXED_RATE = "Personal Loan Fixed Rate";
export const LOAN_PRODUCT_PERSONAL_LOAN_VARIABLE_RATE =
  "Personal Loan Variable Rate";
export const LOAN_PRODUCT_SECURED_PERSONAL_LOAN_VARIABLE_RATE =
  "Secured Personal Loan Variable Rate";
export const LOAN_PRODUCT_SECURED_PERSONAL_LOAN_FIXED_RATE =
  "Secured Personal Loan Fixed Rate";
export const DISB_FILE_NAME = "A - DE_527620_";
export const STR_030000 = "030000 ";

// PL INSURANCE POLICY REPORT
export const PL_INSURANCE_POLICY_REPORT_HEADING =
  "LATITIDE FINANCIAL SERVICES - Q2 Insurance Policy (AU)";
export const PL_INSURANCE_POLICY_REPORT_HEADERS = [
  { id: "countryCode", title: "Country" },
  { id: "state", title: "State" },
  { id: "contractId", title: "Contract ID" },
  { id: "icbsAccountNumber", title: "ICBS Account Number" },
  { id: "insProductNumber", title: "Insurance Product Number" },
  { id: "insProductName", title: "Insurance Product Name" },
  { id: "lmpProductNumber", title: "LMP Product Number" },
  { id: "insPolicystatus", title: "Insurance Policy status" },
  { id: "originalNetPremiumAmt", title: "Original Net Premium Amount" },
  { id: "originalGstAmt", title: "Original GST Amount" },
  { id: "originalStampDutyAmt", title: "Original Stamp Duty Amount" },
  { id: "originalTermInMonths", title: "Original Term in Months" },
  { id: "monthsElapsed", title: "Months elapsed" },
  { id: "monthsRemaining", title: "Months Remaining" },
  { id: "originalLoanIntRate", title: "Original Loan Interest Rate" },
  { id: "insPolicyStartDate", title: "Insurance Policy Start Date" },
  { id: "insPolicyEndDate", title: "Insurance Policy End Date" },
  { id: "insPolicyCancelledDate", title: "Insurance Policy Cancelled Date" },
  { id: "unearnedPremiumBalance", title: "Unearned Premium Balance" },
  { id: "grossRebate", title: "Gross Rebate" },
  { id: "premiumRebate", title: "Premium Rebate" },
  { id: "gstRebate", title: "GST Rebate" },
  { id: "stampDutyRebate", title: "Stamp Duty Rebate" },
];
export const PL_INSURANCE_POLICY_REPORT_SUMATION_LABELS = {
  totalLabel: "Total",
};
export const PL_INSURANCE_POLICY_REPORT_COLUMNS = {
  countryCode: "AU",
  state: "",
  contractId: "",
  icbsAccountNumber: "",
  insProductNumber: "",
  insProductName: "",
  lmpProductNumber: "",
  insPolicystatus: "",
  originalNetPremiumAmt: 0,
  originalGstAmt: 0,
  originalStampDutyAmt: 0,
  originalTermInMonths: "",
  monthsElapsed: "",
  monthsRemaining: "",
  originalLoanIntRate: "",
  insPolicyStartDate: "",
  insPolicyEndDate: "",
  insPolicyCancelledDate: "",
  unearnedPremiumBalance: 0,
  grossRebate: 0,
  premiumRebate: 0,
  gstRebate: 0,
  stampDutyRebate: 0,
};
export const REPORT_NAME_PL_INSURANCE_POLICY = "PL Insurance Policy Report";

// PL INSURANCE CHARGED OFF REPORT
export const PL_INSURANCE_CHARGED_OFF_REPORT_HEADING =
  "LATITIDE FINANCIAL SERVICES - Q2 Insurance Policy (AU)";
export const PL_INSURANCE_CHARGED_OFF_REPORT_HEADERS = [
  { id: "loanNumber", title: "Loan Number" },
  { id: "customerTitle", title: "Customer Title" },
  { id: "customerFirstName", title: "Customer First Name" },
  { id: "customerSurname", title: "Customer Last Name" },
  { id: "customerAddressLine1", title: "Customer Address Line 1" },
  { id: "customerAddressLine2", title: "Customer Address Line 2" },
  { id: "customerSuburb", title: "Customer Suburb" },
  { id: "CustomerState", title: "Customer State" },
  { id: "customerPostcode", title: "Customer Postcode" },
  { id: "country", title: "Customer Country" },
  { id: "disabilityUnusedPremiumAmountAU", title: "Disability Unused" },
  { id: "deathUnusedPremiumAmountAU", title: "Life Unused" },
  { id: "unemploymentUnusedPremiumAmountAU", title: "Unemployment Unused" },
  { id: "insuranceCancellationDate", title: "Insurance Cancellation Date" },
  { id: "disabilityCoverTypeAU", title: "Disability Cover" },
  { id: "deathCoverTypeAU", title: "Life Cover" },
  { id: "unemploymentCoverTypeAU", title: "Unemployment Cover" },
  { id: "totalRefundAmount", title: "Total Refund amount" },
];

export const PL_INSURANCE_CHARGED_OFF_REPORT_COLUMNS = {
  loanNumber: "",
  customerTitle: "",
  customerFirstName: "",
  customerSurname: "",
  customerAddressLine1: "",
  customerAddressLine2: "",
  customerSuburb: "",
  CustomerState: "",
  customerPostcode: "",
  country: "",
  disabilityUnusedPremiumAmountAU: "",
  deathUnusedPremiumAmountAU: "",
  unemploymentUnusedPremiumAmountAU: "",
  insuranceCancellationDate: "",
  disabilityCoverTypeAU: "",
  deathCoverTypeAU: "",
  unemploymentCoverTypeAU: "",
  totalRefundAmount: "",
};
export const REPORT_NAME_PL_INSURANCE_CHARGED_OFF_ACCOUNTS =
  "PL Insurance Charged Off Accounts Report";

// PL INSURANCE TXN REPORT
export const PL_INSURANCE_TXN_REPORT_HEADING =
  "LATITIDE FINANCIAL SERVICES - Q2 Insurance Transactions (AU)";
export const PL_INSURANCE_TXN_REPORT_HEADERS = [
  { id: "countryCode", title: "Country" },
  { id: "state", title: "State" },
  { id: "contractId", title: "Contract ID" },
  { id: "icbsAccountNumber", title: "ICBS Account Number" },
  { id: "lmpProductNumber", title: "LMP Product Number" },
  { id: "insPolicyStartDate", title: "Insurance Policy Start Date" },
  { id: "insProductNumber", title: "Insurance Product Number" },
  { id: "insProductName", title: "Insurance Product Name" },
  { id: "insPolicystatus", title: "Insurance Policy status" },
  { id: "q2TxnDescription", title: "Q2 Transaction Description" },
  { id: "q2TxnId", title: "Q2 Transaction ID" },
  { id: "claimPmtRef", title: "Claim Payment Reference" },
  { id: "txnEffectiveDate", title: "Transaction Effective Date" },
  { id: "txnPostingDate", title: "Transaction Posting Date" },
  { id: "txnAmount", title: "Transaction Amount" },
  { id: "premiumAmount", title: "Premium Amount" },
  { id: "gstAmount", title: "GST Amount" },
  { id: "stampDutyAmount", title: "Stamp Duty Amount" },
];
export const PL_INSURANCE_TXN_REPORT_SUMATION_LABELS = {
  totalLabel: "Total",
};
export const PL_INSURANCE_TXN_REPORT_COLUMNS = {
  countryCode: "AU",
  state: "",
  contractId: "",
  icbsAccountNumber: "",
  lmpProductNumber: "",
  insPolicyStartDate: "",
  insProductNumber: "",
  insProductName: "",
  insPolicystatus: "",
  q2TxnDescription: "",
  q2TxnId: "",
  claimPmtRef: "",
  txnEffectiveDate: "",
  txnPostingDate: "",
  txnAmount: 0,
  premiumAmount: 0,
  gstAmount: 0,
  stampDutyAmount: 0,
};
export const REPORT_NAME_PL_INSURANCE_TXN = "PL Insurance Txn Report";
export const PL_INSURANCE_TXN_REPORT_ALLOWED_PMT_MODE = [
  "INSURANCE CLAIM PMT",
  "INS REFUND - STAMP DUTY",
  "INS REFUND - GST",
  "INS REFUND - PREM - UI",
  "INS REFUND - PREM - DIS",
  "INS REFUND - PREM - LIFE",
];

// PAYMENT MODE
export const PAYMENT_MODE_INSURANCE_CLAIM_PMT = "INSURANCE CLAIM PMT";

// BANK & Disbursal TYPE
export const BANK_TYPE_BOR_INV = "Borrower/Investor Account";
export const BANK_TYPE_BOR = "Broker Account";
export const BANK_TYPE_BUSS = "Business Account";
export const DIST_TYPE_DISB = "Disbursement";
export const DIST_TYPE_TOPUP = "PRINCIPAL ADJUSTMENT - TOP UP";
export const BSB_NUMBER_LENGTH = 6;

// LOAN DISBURSAL REPORT
export const REPORT_NAME_LOAN_DISBURSAL = "Loan Disbursal Report";

// LOAN PMT TXN REPORT
export const CREDIT_BANK_PARAM = "credit_bank_params";
export const DEBIT_BANK_PARAM = "debit_bank_params";
export const CREDIT_CODE = "50";
export const DEBIT_CODE = "13";
export const COLLECTION = "Collections Trust Account";
export const DEBIT_0_VALUES = "0000000000";
export const CREDIT_0_VALUES = "0000000000";
export const TAX_0_VALUES = "00000000";
export const LPT_FILE_NAME_END_STR = "030000";
export const LPT_FILE_NAME = "DE_536648_";
export const REPORT_NAME_LOAN_PMT_TXN = "Loan Pmt Txn Report";

// BPAY REPORT
export const BPAY_CSV_REPORT_HEADER = [
  { id: "headerType", title: "H" },
  { id: "customerCode", title: "LATTFINSER" },
  { id: "customerName", title: "Latitude Financial Services Limited" },
  { id: "customerRef", title: "last customer reference" },
  { id: "csvFileGenDate", title: "Csv File Generation Date" },
  { id: "currency", title: "AUD" },
  { id: "version", title: "4" },
  { id: "colH", title: "" },
];
export const CSVFILEGENDATE = "csvFileGenDate";
export const CUSTOMERREF = "customerRef";
export const LFSWBC_00000 = "LFSWBC_000000";
export const REPORT_NAME_BPAY = "BPAY Report";

// RECEIVABLE BALANCE REPORT
export const REPORT_NAME_RECEIVABLE_BALANCE = "Receivable Balance Report";
export const MASTER_LABEL_CREATE_RECV_BALANCE_REPORT =
  "CreateRecievableBalanceReport";

// DAILY TRANSACTION REPORT
export const DAILY_TRANSACTION_REPORT_HEADER1 =
  "LATITIDE FINANCIAL SERVICES - Q2 Daily Transaction Report - Personal Loans (Australia),,,,,,,,Report Run on ";
export const DAILY_TRANSACTION_REPORT_HEADER2 =
  "Transaction Description,Product Code,Product Name,Is This a Test Data,Contract ID,Customer Status,Transaction ID,Transaction Date / Effective Date,Creation Date / Posting Date,Transaction Amount \n";
export const DAILY_TRANSACTION_REPORT_SUM_ROWS = {
  totalDebit0002: "Total - Debits - Product Code 0002,,,,,,,,,",
  totalCredit0002: "Total - Credits - Product Code 0002,,,,,,,,,",
  totalnet0002: "Total - Net - Product Code 0002,,,,,,,,,",
  totalDebit0666: "Total - Debits - Product Code 0666,,,,,,,,,",
  totalCredit0666: "Total - Credits - Product Code 0666,,,,,,,,,",
  totalnet0666: "Total - Net - Product Code 0666,,,,,,,,,",
  totalDebit0667: "Total - Debits - Product Code 0667,,,,,,,,,",
  totalCredit0667: "Total - Credits - Product Code 0667,,,,,,,,,",
  totalnet0667: "Total - Net - Product Code 0667,,,,,,,,,",
  totalDebit0668: "Total - Debits - Product Code 0668,,,,,,,,,",
  totalCredit0668: "Total - Credits - Product Code 0668,,,,,,,,,",
  totalnet0668: "Total - Net - Product Code 0668,,,,,,,,,",
  totalDebit0669: "Total - Debits - Product Code 0669,,,,,,,,,",
  totalCredit0669: "Total - Credits - Product Code 0669,,,,,,,,,",
  totalnet0669: "Total - Net - Product Code 0669,,,,,,,,,",
  totalDebit: "Total - Debits ,,,,,,,,,",
  totalCredit: "Total - Credits,,,,,,,,,",
  totalNet: "Total - Net ,,,,,,,,,",
};
export const PRODUCT_CODE_1 = "LPC-0002";
export const PRODUCT_CODE_2 = "LPC-0666";
export const PRODUCT_CODE_3 = "LPC-0667";
export const PRODUCT_CODE_4 = "LPC-0668";
export const PRODUCT_CODE_5 = "LPC-0669";
export const REV = "- Rev ";
export const PAYMENTMODE_ACH = "ACH";
export const PAYMENTMODE_CASH = "Cash";
export const PAYMENTMODE_DIRECTCREDIT = "Direct Credit";
export const BPAY_FEE = "BPAY Fee";
export const CHARGED_OFF_FEE = "Charged-off Fees";
export const CHARGED_OFF_PRINCIPAL = "Charged-off Principal";
export const CHARGED_OFF_INTEREST = "Charged-off Interest";
export const EARLY_PAYOFF_FEE = "Early Payoff Fee";
export const GOODWILL = "Goodwill/Adjustment";
export const GOODWILLCREDIT = "Goodwill Credit";
export const GOODWILLDEBIT = "Goodwill Debit";
export const INTEREST_CHARGED = "Interest Charged";
export const INTEREST_REV = "INTEREST REV";
export const CHARGE_OFF = "Charge Off";
export const LATE_FEE = "Late Payment Fee";
export const LATITUDE_LATE_FEE = "Latitude Late Payment Fee";
export const ADMIN_FEE = "Loan Administration Fee";
export const LATITUDE_ADMIN_FEE = "Latitude Loan Administration Fee";
export const ESTABLISHMENT_FEE = "Latitude Loan Establishment Fee";
export const LOAN_ESTABLISHMENT_FEE = "Loan Establishment Fee";
export const DISBURSEMENT = "Disbursement";
export const LOAN_DISBURSEMENT = "Loan Disbursement";
export const BPAY_TYPE = "BPAY";
export const LOAN_DISBURSEMENT_BPAY = "Loan Disbursement BPAY";
export const PREPAID_FEE = "Pre-Paid Fee";
export const LOAN_TOPUPFEE = "LOAN TOP UP FEE";
export const PRINCIPAL_ADJUSTMENTADD = "Principal Adjustment - Add";
export const PRINCIPAL_ADJUSTMENT = "Principal Adjustment";
export const PRINCIPAL_ADJUSTMENT_TOPUP = "PRINCIPAL ADJUSTMENT - TOP UP";
export const PPSR_SEARCH_FEE = "PPSR Search Fee";
export const PPSR_REG_FEE = "PPSR Registration Fee";
export const REMINDA = "Reminda";
export const REFUND = "Refund";
export const COMMA_9 = ",,,,,,,,,";
export const TOTAL_ACH_PRODUCT = "Total ACH - Product ";
export const TOTAL_CASH_PRODUCT = "Total Cash - Product ";
export const TOTAL_CASH_REV_PRODUCT = "Total Cash Rev - Product ";
export const TOTAL_ACH_REV_PRODUCT = "Total ACH Rev- Product ";
export const TOTAL_BPAY_PRODUCT = "Total - BPAY Fee- Product ";
export const TOTAL_BPAY_REV_PRODUCT = "Total - BPAY Fee Rev- Product ";
export const TOTAL_CHARGED_OFF_FEES_PRODUCT =
  "Total - Charged-off Fees- Product ";
export const TOTAL_CHARGED_OFF_REV_FEES_PRODUCT =
  "Total - Charged-off Fees Rev- Product ";
export const TOTAL_CHARGED_OFF_PRINCIPAL_REV =
  "Total - Charged-off Principal Rev- Product ";
export const TOTAL_CHARGED_OFF_PRINCIPAL =
  "Total - Charged-off Principal - Product ";
export const TOTAL_CHARGED_OFF_INTEREST =
  "Total - Charged-off Interest - Product ";
export const TOTAL_CHARGED_OFF_REV_INTEREST =
  "Total - Charged-off Interest Rev- Product ";
export const TOTAL_DIRECT_CREDIT_PRODUCT = "Total Direct Credit - Product ";
export const TOTAL_DIRECT_CREDIT_REV_PRODUCT =
  "Total Direct Credit Rev- Product ";
export const TOTAL_EARLY_PAYOFF_FEE_PRODUCT =
  "Total - Early Payoff Fee - Product ";
export const TOTAL_EARLY_PAYOFF_FEE_REV_PRODUCT =
  "Total - Early Payoff Fee Rev- Product ";
export const TOTAL_GOODWILL_CREDIT_PRODUCT =
  "Total Goodwill/Adjustment - Product ";
export const TOTAL_GOODWILL_CREDIT_REV_PRODUCT =
  "Total Goodwill/Adjustment Rev- Product ";
export const TOTAL_GOODWILL_PRODUCT = "Total Goodwill Credit- Product ";
export const TOTAL_GOODWILL_DEBIT_PRODUCT = "Total Goodwill Debit- Product ";
export const TOTAL_INTEREST_CHARGED_PRODUCT =
  "Total Interest Charged - Product ";
export const TOTAL_INTEREST_REV_PRODUCT = "Total Interest Rev - Product ";
export const TOTAL_LATE_FEE_PRODUCT = "Total - Late Payment Fee- Product ";
export const TOTAL_LATE_FEE_REV_PRODUCT =
  "Total - Late Payment Fee Rev- Product ";
export const TOTAL_LATITUDE_LATE_FEE_PRODUCT =
  "Total -Latitude Late Payment Fee- Product ";
export const TOTAL_LATITUDE_LATE_FEE_REV_PRODUCT =
  "Total -Latitude Late Payment Fee Rev- Product ";
export const TOTAL_ADMIN_FEE_PRODUCT =
  "Total -Loan Administration Fee- Product ";
export const TOTAL_ADMIN_FEE_REV_PRODUCT =
  "Total -Loan Administration Fee Rev- Product ";
export const TOTAL_LATITUDE_ADMIN_FEE_PRODUCT =
  "Total -Latitude Loan Administration Fee- Product ";
export const TOTAL_LATITUDE_ADMIN_FEE_REV_PRODUCT =
  "Total -Latitude Loan Administration Fee Rev- Product ";
export const TOTAL_DISBURSEMENT_BPAY_PRODUCT =
  "Total - Loan Disbursement BPAY- Product ";
export const TOTAL_DISBURSEMENT_BPAY_REV_PRODUCT =
  "Total - Loan Disbursement BPAY Rev- Product ";
export const TOTAL_DISBURSEMENT_PRODUCT = "Total - Loan Disbursement- Product ";
export const TOTAL_DISBURSEMENT_REV_PRODUCT =
  "Total - Loan Disbursement Rev- Product ";
export const TOTAL_LOAN_ESTABLISHMENT_FEE_PRODUCT =
  "Total - Loan Establishment Fee- Product ";
export const TOTAL_LOAN_ESTABLISHMENT_FEE_REV_PRODUCT =
  "Total - Loan Establishment Fee Rev- Product ";
export const TOTAL_LOAN_TOPUPFEE_PRODUCT = "Total - LOAN TOP UP FEE- Product ";
export const TOTAL_LOAN_TOPUPFEE_REV_PRODUCT =
  "Total - LOAN TOP UP FEE Rev- Product ";
export const TOTAL_PRINCIPAL_ADJUSTMENT_PRODUCT =
  "Total - Principal Adjustment- Product ";
export const TOTAL_PRINCIPAL_ADJUSTMENT_REV_PRODUCT =
  "Total - Principal Adjustment Rev- Product ";
export const TOTAL_PRINCIPAL_ADJUSTMENT_TOPUP_PRODUCT =
  "Total - Principal Adjustment - Top Up- Product ";
export const TOTAL_PRINCIPAL_ADJUSTMENT_TOPUP_REV_PRODUCT =
  "Total - Principal Adjustment - Top Up Rev- Product ";
export const TOTAL_PPSR_SEARCH_FEE_PRODUCT =
  "Total - PPSR Search Fee- Product ";
export const TOTAL_PPSR_SEARCH_FEE_REV_PRODUCT =
  "Total - PPSR Search Fee Rev- Product ";
export const TOTAL_PPSR_REG_FEE_PRODUCT =
  "Total - PPSR Registration Fee- Product ";
export const TOTAL_PPSR_REG_FEE_REV_PRODUCT =
  "Total - PPSR Registration Fee Rev- Product ";
export const TOTAL_REMINDA_PRODUCT = "Total Reminda- Product ";
export const TOTAL_REMINDA_REV_PRODUCT = "Total Reminda Rev- Product ";
export const TOTAL_REFUND_PRODUCT = "Total - Refund- Product ";
export const TOTAL_REFUND_REV_PRODUCT = "Total - Refund Rev- Product ";
export const DAILY_TRANSACTION_REPORT_NAME = "Q2_AU_PL_DAILY_TXN_RPT_";
export const DAILY_TRANSACTION_REPORT_FOLDER = "Daily Txn Report";

// DEBT SALE PAYMENT REPORT
export const DEBT_SALE_CUST_PMT_REPORT_HEADING =
  "LATITIDE FINANCIAL SERVICES - Q2 Debt Sale Customer Payment Report - Personal Loans (AU)";
export const DEBT_SALE_CUST_PMT_REPORT_HEADERS = [
  { id: "conId", title: "Q2 Contract ID" },
  { id: "icbsAccNum", title: "ICBS Account Number" },
  { id: "accName", title: "Account Name" },
  { id: "product", title: "Product #" },
  { id: "boughtFlag", title: "Bought-Sold Flag" },
  { id: "buyerCode", title: "Buyer Code" },
  { id: "buyerName", title: "Buyer Name" },
  { id: "txnType", title: "Transaction Type" },
  { id: "postingDate", title: "Posting Date" },
  { id: "pmtReceived", title: "Payment Amount Received" },
  { id: "pmtReversed", title: "Payment Amount Reversed" },
];
export const DEBT_SALE_SUMMATION_LABEL = {
  totalLabel: "Total",
};
export const DEBT_SALE_CUST_PMT_REPORT_COLUMNS = {
  conId: "",
  icbsAccNum: "",
  accName: "",
  product: "",
  boughtFlag: "",
  buyerCode: "",
  buyerName: "",
  txnType: "",
  postingDate: "",
  pmtReceived: 0,
  pmtReversed: 0,
};

export const REPORT_NAME_DEBT_SALE_CUSTOMER_PAYMENT =
  "Debt Sale Customer Payment Report";
export const REPORT_NAME_DEBT_SALE = "Debt Sale Report";
export const PAYMENT_REVERSAL_TYPE = "Payment Reversal";
export const PAYMENT_TRANSACTION_TYPE = "Payment Transaction";
export const DEBT_SALE_CUSTOMER_PAYMENT_QUERY =
  "select id, name, loan__Loan_Account__c, loan__Loan_Account__r.Name, loan__Loan_Account__r.ICBS_Genesis_Account_Number__c, loan__Loan_Account__r.loan__Account__c, loan__Loan_Account__r.loan__Account__r.Name, loan__Loan_Account__r.ICBS_Genesis_Product_Code__c, loan__Loan_Account__r.Bought_Sold_Code__c, loan__Loan_Account__r.Buyer_ID__c, loan__Loan_Account__r.Buyer_name__c, loan__Loan_Account__r.loan__Last_Transaction_Type__c, loan__Transaction_Date__c, loan__Transaction_Amount__c, loan__Cleared__c, loan__Reversed__c from loan__Loan_Payment_Transaction__c where loan__Loan_Account__c != null and loan__Loan_Account__r.Account_Sold_Status_del1__c = true and loan__Loan_Account__r.loan__Last_Transaction_Type__c in ('Payment Transaction', 'Payment Reversal') and loan__Cleared__c = true and loan__Rejected__c = false ";
export const DEBT_SALE_PAYMENT_REPORT_FILE_NAME =
  "Q2_AU_PL_DEBT_SALE_CUST_PMT_";

// DEBT SALE REPORT
export const DEBT_SALE_QUERY =
  "select id, name, ICBS_Genesis_Account_Number__c, loan__Account__c, loan__Account__r.Name, ICBS_Genesis_Product_Code__c, Bought_Sold_Code__c, Buyer_ID__c, Buyer_name__c, Sold_Date__c, loan__Buyback_Date__c, loan__Charged_Off_Principal__c, Sold_Amount__c, Buyback_amount__c from loan__Loan_Account__c where ";
export const DEBT_SALE_REPORT_NAME =
  "LATITIDE FINANCIAL SERVICES - Q2 Debt Sale Report - Personal Loans (AU)";
export const DEBT_SALE_FILE_NAME = "Q2_AU_PL_DEBT_SALE_";

export const DEBT_SALE_REPORT_HEADING =
  "LATITIDE FINANCIAL SERVICES - Q2 Debt Sale Report - Personal Loans (AU)";

export const DEBT_SALE_REPORT_HEADERS = [
  { id: "conId", title: "Q2 Contract ID" },
  { id: "icbsAccNum", title: "ICBS Account Number" },
  { id: "accName", title: "Account Name" },
  { id: "product", title: "Product #" },
  { id: "boughtFlag", title: "Bought-Sold Flag" },
  { id: "buyerCode", title: "Buyer Code" },
  { id: "buyerName", title: "Buyer Name" },
  { id: "soldDate", title: "Sold Date" },
  { id: "buybackDate", title: "Buyback Date" },
  { id: "chargedOffPrin", title: "Charged Off Principal" },
  { id: "soldAmt", title: "Sold Amount" },
  { id: "buybackAmt", title: "Buyback Amount" },
];

export const DEBT_SALE_REPORT_COLUMNS = {
  conId: "",
  icbsAccNum: "",
  accName: "",
  product: "",
  boughtFlag: "",
  buyerCode: "",
  buyerName: "",
  soldDate: "",
  buybackDate: "",
  chargedOffPrin: 0,
  soldAmt: 0,
  buybackAmt: 0,
};

// AML Foreign Jurisdiction Report
export const AML_FRN_JURISDICTION_REPORT_COLUMNS = {
  accountId: "",
  accountStatus: "",
  fullName: "",
  address: "",
  town: "",
  state: "",
  postCode: "",
  country: "",
  productCountry: "",
  product: "",
  issuedS88Flag: "",
  onshoreAddressCount: "",
};
export const AML_FOREIGN_JURISDICTION_REPORT_HEADING =
  "LATITUDE FINANCIAL SERVICES - AML Foreign Jurisdiction Reporting (AU)";
export const AML_FRN_JURISDICTION_REPORT_HEADERS = [
  { id: "accountId", title: "Account Id" },
  { id: "accountStatus", title: "Account Status" },
  { id: "fullName", title: "Full Name" },
  { id: "address", title: "Address" },
  { id: "town", title: "Town" },
  { id: "state", title: "State" },
  { id: "postCode", title: "Post Code" },
  { id: "country", title: "Country" },
  { id: "productCountry", title: "Product Country" },
  { id: "product", title: "Product" },
  { id: "issuedS88Flag", title: "Issued S88 Flag" },
  { id: "onshoreAddressCount", title: "Onshore Address Count" },
];
export const REPORT_NAME_AML_FRN_JURISDICTION_REPORT =
  "AML Foreign Jurisdiction Reports";

// INSURANCE CHARGED OFF REPORT
export const INSURANCE_CHARGEDOFF_REPORT_EMAIL_SENT_TO =
  "Supriyo.Seni@cloudkaptan.com";
export const SF_REPORT_PLATFORM_EVENT_OBJ = "Report_Sender__e";
// INTEREST ACCRUED NOT CAPITALISED REPORT
export const INTEREST_ACCRUED_NOT_CAPITALISED_REPORT_HEADING =
  "LATITIDE FINANCIAL SERVICES - Q2 Interest Accrued Not Capitalised Report - Personal Loans (AU)";
export const INTEREST_ACCRUED_NOT_CAPITALISED_REPORT_HEADERS = [
  { id: "productCode", title: "Product Code" },
  { id: "contractId", title: "Contract ID" },
  { id: "customerStatus", title: "Customer Status" },
  { id: "loanAccuralStatus", title: "Loan Accural Status" },
  { id: "daysPastDue", title: "Days Past Due" },
  { id: "lastCapitalisationDate", title: "Last Capitalisation Date" },
  { id: "nextCapitalizationDate", title: "Next Capitalisation Date" },
  {
    id: "interestAccrued",
    title: "Interest Accrued",
  },
  { id: "interestRemaining", title: "Interest Remaining" },
  {
    id: "totalInterestAccruedNotCapitalised",
    title: "Total Interest Accrued not Capitalised",
  },
];
export const INTEREST_ACCRUED_NOT_CAPITALISED_REPORT_TOTAL = {
  totalLabel: "Total",
};
export const INTEREST_ACCRUED_NOT_CAPITALISED_REPORT_COLUMNS = {
  productCode: "",
  contractId: "",
  customerStatus: "",
  loanAccuralStatus: "",
  daysPastDue: "",
  lastCapitalisationDate: "",
  nextCapitalizationDate: "",
  interestAccrued: 0,
  interestRemaining: 0,
  totalInterestAccruedNotCapitalised: 0,
};
export const REPORT_NAME_INTEREST_ACCRUED_NOT_CAPITALISED =
  "Interest Accrued not Capitalised Report";

// SUNDRY CREDITOR INVOICE REPORT
export const ENFORCEMENT_FEE = "Enforcement Fee";
export const ENFORCEMENT_FEE_WAIVED = "Enforcement Fee Waived";
export const CURRENT_MONTH_STR = "currentMonth";
export const CURRENT_YEAR_STR = "currentYear";
export const SUNDRY_CREDITOR_INVOICE_REPORT__HEADING =
  "LATITIDE FINANCIAL SERVICES - Q2 Sundry Creditor Invoice Report - Personal Loans (AU)";
export const SUNDRY_CREDITOR_INVOICE_REPORT__HEADERS = [
  { id: "postingDate", title: "Transaction Posting Date" },
  { id: "effectiveDate", title: "Transaction Effective Date" },
  { id: "transactionName", title: "Transaction Name" },
  { id: "transactionId", title: "Transaction ID" },
  { id: "contractId", title: "Contract ID" },
  { id: "customerName", title: "Customer Name" },
  { id: "productNumber", title: "Product Number" },
  { id: "invoiceDate", title: "Invoice Date" },
  { id: "invoiceNumber", title: "Invoice Number" },
  { id: "vendorName", title: "Vendor Name" },
  { id: "invoiceDesc", title: "Invoice Description" },
  { id: "invAmtIncGst", title: "Invoice Amount including GST" },
  { id: "totalGstAmount", title: "Total GST Amount" },
  { id: "invAmtExcGst", title: "Invoice Amount Excluding GST" },
  { id: "gstChargedAmt", title: "GST Charged to Customer Amount" },
  { id: "gstRecoveryAmt", title: "GST Recovery Amount" },
  { id: "amtCusCharged", title: "Amount Customer Charged" },
  { id: "q2Userprofile", title: "Q2 User Profile" },
];
export const SUNDRY_CREDITOR_INVOICE_REPORT_TOTAL = {
  totalLabel: "Grand Total",
};
export const SUNDRY_CREDITOR_INVOICE_REPORT_COLUMNS = {
  postingDate: "",
  effectiveDate: "",
  transactionName: "",
  transactionId: "",
  contractId: "",
  customerName: "",
  productNumber: "",
  invoiceDate: "",
  invoiceNumber: "",
  vendorName: "",
  invoiceDesc: "",
  invAmtIncGst: 0,
  totalGstAmount: 0,
  invAmtExcGst: 0,
  gstChargedAmt: 0,
  gstRecoveryAmt: 0,
  amtCusCharged: 0,
  q2Userprofile: "",
};
export const REPORT_NAME_SUNDRY_CREDITOR_INVOICE =
  "Sundry Creditor Invoice Report";

/* LOGGER STRING */
export const ERROR = "error";
export const DEBUG = "debug";
export const INFO = "info";
/* JOI RELATED */
export const REQ_OBJ_HOLDER_ARR = ["params", "query", "body"];
/* CHARACTERS */
export const COMMA_STR = ",";
export const COMMA_SPACE_STR = ", ";
export const COMMA_INSIDE_SINGLE_INV_STR = "','";
export const BLANK_STR = "";
export const SPACE_STR = " ";
export const COLON_STR = ":";
export const DOT_STR = ".";
export const FORWARD_SLACE_STR = "/";
export const NEW_LINE_STR = "\n";
export const NEW_LINE_STR_2 = "\r\n";
export const DASH_STR = "-";
export const UNDER_SCORE_STR = "_";
export const DOLLAR_SIGN = "$";
export const MESSAGE_STR = "message";
export const REMOTE_ADDR_STR = ":remote-addr - ";

/* RELATED TO DATE */
export const DATE_YYYY_MM_DD_FORMATE = "YYYY-MM-DD";
export const DATE_DD_MM_YYYY_FORMATE = "DD/MM/YYYY";
export const DATE_IN_UTC_FORMAT = "YYYY-MM-DDTHH:mm:ssZ";
export const DAYS_STR = "days";
export const MONTH_STRING = "month";
export const WEEK_STR = "Weekly";
export const MONTH_STR = "Monthly";

/* INTEGER VALUES */
export const INT_100 = 100;
export const SALT_ROUNDS = 10;
/* SERVER PROCESS ERROR EVENT NAMES */
export const UNCAUGHT_EXEPTION_EVENT = "uncaughtException";
export const UNHANDLED_REJECTION_EVENT = "unhandledRejection";
export const SIGTERM_EVENT = "SIGTERM";
/* FILE RELATED */
export const MULTER_FIELD_SIZE_LIMIT = 100 * 1024 * 1024; // 100MB

/* CRON JOB */
export const CRON_JOB_OFF = "Off";
export const AUS_SYD_TIMEZONE = "Australia/Sydney";
export const LOCAL_LANGUAGE_EN_US = "en-US";

/* FILE READ/WRITE EVENTs */
export const FILE_READ_LINE_EVENTS = {
  line: "line",
  error: "error",
  close: "close",
};
/* SF LOGGING RELATED */
export const SENT_EMAIL_TO_CUSTOMER = "Customer";
export const SENT_EMAIL_TO_DEVELOPER = "Developer";
export const SERVICE_NAME_WESTPAC = "Westpac";
export const SERVICE_NAME_REPORT = "Report";
export const SERVICE_NAME_CRONJOB = "Cronjob";

/** *****
 * REGEX
 ******* */

/* COMMON */
export const REGX_ALL_SPACES = /\s+/g;
export const REGEX_NEW_LINE = /\r?\n/;
export const REGX_EXCEPTION_FILE_PATH = /\((.*):(\d+):(\d+)\)$/;

/** ************
 * SF & APIs RELATED
 ************** */

/* GENERAL */
export const OAUTH_STR = "OAuth ";
export const BEARER_STR = "Bearer ";
export const HOST_STR = "host";

/* GUEST API ENDPOINT BASE URL */
export const API_V1_GUEST = "/api/v1/guest";

/* WESTPAC API ENDPOINT BASE URL */
export const API_V1_WESTPAC = "/api/v1/westpac";

/* REPORTS API ENDPOINT BASE URL */
export const API_V1_REPORT = "/api/v1/report";

/* DOCS API ENDPOINT BASE URL */
export const DOCS_V1 = "/docs/v1/";

/* API DOCs END POINT URLS */
export const API_DOCS_API = "/api-docs";

/* REPORTS */
export const RECEIVABLE_BALANCE_REPORT_API = "/receivable/balance"; // Receivable balance report
export const LOAN_DISB_FILE_REPORT_API = "/loan/disbursal"; // Loan disbursal file report
export const BPAY_FILE_REPORT_API = "/bpay"; // Bpay file report
export const LOAN_PMT_TXN_REPORT_API = "/lpt"; // Loan pmt txn report
export const SF_DAILY_TRANSACTION_REPORT_API = "/daily/txn"; // Daily transaction report
export const SF_PL_INS_POLICY_REPORT_REPORT_API = "/plins/policy"; // PL insurance policy report
export const SF_PL_INS_TXN_REPORT_REPORT_API = "/plins/txn"; // PL insurance txn report
export const DEBT_SALE_ROUTE = "/debtsale"; // Debt sale report
export const DEBT_SALE_PMT_ROUTE = "/debtsale/pmt"; // Debt sale customer payment report
export const SF_INSURANCE_CHARGED_OFF_REPORT_API = "/plins/chargedoff"; // Weekly accounts with chargedoff insurance report
export const AML_FOREIGN_JURISDICTION_ROUTE = "/amlfrn/jurisdiction"; // AML Foreign Jurisdiction Reporting - AU
export const SUNDRY_CREDITOR_INVOICE_REPORT_API = "/suncred/invoice"; // Sundry Creditor Invoice Report
export const INTEREST_ACCRUED_NOT_CAPITALISED_REPORT_API =
  "/interestacc/notcap"; // Interest Accured Not Capitalised report

/* WESTPACK INTEGRATION */
export const WESTPACK_FILE_PARSE_API = "/file/parse";

/* ILLION INTEGRATION */
export const SF_UPLOAD_TO_OCR_API = "/uploadocr";

/* APIS REQUEST & RESPONSE HEADER */
export const X_POWERED_BY_STR = "X-Powered-By";
export const X_FORWARDED_FOR = "x-forwarded-for";
export const AUTH_TOKEN_STR = "x-auth-token";
export const API_KEY_STR = "x-api-key";

/* REQUEST METHOD */
export const HTTP_GET_STR = "GET";
export const HTTP_POST_STR = "POST";

/* REQ & RES STATIC STRING */
// Req
export const REFERENCE_KEY_STR = "reference";
export const FILE_TO_UPLOAD_KEY_STR = "fileToUpload";
export const WP_FILE_TYPE_KEY_STR = "wpFileType";

/* ******************
 * SF APIs END POINTS
 ******************** */

/* ************
 * SF OBJAECTS
 ************** */
export const SF_LPT_OBJ = "loan__Loan_Payment_Transaction__c";
export const SF_LPT_REVERSAL_OBJ = "LPT_Reversal__c";
export const SF_WP_LOG_OBJ = "WP_File_log__c";
export const SF_WP_PLATFORM_EVENT_OBJ = "WestPac_MW__e";
export const SF_BPAY_DATA_STORE_OBJ = "Bpay_Data_Store_Object__c";
export const SF_DOCUMENT_OBJ = "Document";
export const SF_LOGGING_PLATFORM_EVENT_OBJ = "MW_Logs_Fire_Email__e";
export const SF_CONTENT_DOCUMENT_LINK_OBJ = "ContentDocumentLink";
export const SF_LDTI_OBJ = "loan__Loan_Disbursal_Transaction__c";
export const SF_DDI_OBJ = "loan__Disbursal_Txn_Distribution__c";

/* ****************
 * SF RECORD TYPE
 *************** */
export const REJECTED_TXN_DATA_STORE_REC_TYPE =
  "Rejected Transactions Data Store";
export const BPAY_TXN_DATA_STORE_REC_TYPE = "Bpay Data Store Object";

/* ***************
 * SF BATCH NAME
 **************** */
export const SF_LPT_REVERSAL_BATCH_NAME = "LPTReversalBatch";
export const SF_BPAY_PROCESS_BATCH_NAME = "BPayProcessBatch";
/* **********************
 * SF JOB REFERENCE NAME
 ************************ */
export const BPAY_REPORT_GEN_JOB = "BpayReportGenJob";

/* **********
 * JS FORCE
 ************ */
export const BULK_POLLING_TIME = 900000;

/* *********
 * SF QUERY
 *********** */
export const QUERY_LIMIT_1 = "LIMIT 1";
export const MAX_RECORD_QUERY_LIMIT = 500;
export const HUGE_DATA_QUERY_MAX_LIMIT = 400000;
export const MAX_RECORD_UPDATE_LIMIT = 10000;
export const MAX_RECORD_INSERT_LIMIT = 10000;
export const SF_CURRENT_SYSTEM_DATE_QUERY =
  "SELECT Id, loan__Current_System_Date__c, Name FROM loan__Office_Name__c WHERE Name =";
export const SF_CONTENT_VERSION_QUERY =
  "SELECT Id,Title,VersionData FROM ContentVersion WHERE ContentDocumentId = ";
export const SF_ATTACHMENT_QUERY =
  "SELECT Id, Body, Name FROM Attachment WHERE Id = ";
export const SF_LPT_QUERY =
  "SELECT Id, Name, loan__Loan_Account__c FROM loan__Loan_Payment_Transaction__c WHERE Name IN ";
export const SF_LOAN_ACC_FETCH_USING_CRN_QUERY =
  "SELECT Id, CRN_Number__c FROM loan__Loan_Account__c WHERE CRN_Number__c IN ";
export const SF_LOAN_ACC_FETCH_USING_BOR_ACH_QUERY =
  "SELECT Id, Name FROM loan__Loan_Account__c WHERE loan__Borrower_ACH__c IN ";
export const SF_LOAN_BANK_ACC_USING_BSB_NUM_QUERY =
  "SELECT Id, Name, loan__Account__c, BSB_Number__c, loan__Bank_Account_Number__c FROM loan__Bank_Account__c WHERE BSB_Number__c IN ";
export const SF_LOAN_OTHER_TRAN_USING_LOAN_ACC_QUERY =
  "SELECT Id, Name, loan__Txn_Amt__c, loan__Loan_Amount__c, loan__Loan_Account__c, loan__Loan_Account__r.loan__Borrower_ACH__r.loan__Bank_Account_Number__c, loan__Loan_Account__r.Name, loan__Loan_Account__r.loan__Account__r.Name FROM loan__Other_Transaction__c WHERE loan__Loan_Account__c IN ";
export const SF_DOCUMENT_FOLDER_QUERY = "SELECT Id FROM Folder WHERE name = ";
export const SF_LOAN_DISBURSAL_TXN_DISTRIBUTION_QUERY =
  "SELECT Id, Name, loan__Distribution_Amount__c,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.Name, Other_Bank_Reference__c FROM loan__Disbursal_Txn_Distribution__c WHERE Name IN ";
export const BATCH_JOB_METADATA_DETAILS_QUERY =
  "SELECT MasterLabel,DeveloperName,Active__c,Query__c,Size__c FROM BatchJob_Spec__mdt WHERE";
export const LIBRARY_QUERY =
  "SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name = ";
export const CONTENAT_VERSION_QUERY =
  "SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =";
export const SF_LOAN_DISBURSAL_DISTRIBUTION_QUERY =
  "SELECT Id, loan__Disbursed_Amt__c, loan__Loan_Account__c,loan__Sent_To_ACH__c,loan__ACH_Filename__c,loan__Sent_To_ACH_On__c from loan__Loan_Disbursal_Transaction__c WHERE loan__Sent_To_ACH__c = false";
export const SF_LOAN_DISBURSAL_DIST_TXN_QUERY =
  "SELECT Id,Name,loan__Distribution_Amount__c,loan__Loan_Disbursal_Transaction__c,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__c,loan__Distribution_Type__c, loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.loan__Account__r.Name,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.loan__Contact__r.name,loan__Bank_Account__c,loan__Name_of_Entity__c,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.Application__r.Broker_Application__c,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.Application__r.Name,loan__Bank_Account__r.loan__Account__c, loan__Bank_Account__r.loan__Account_Usage__c,loan__Bank_Account__r.loan__Bank_Account_Number__c,loan__Bank_Account__r.Other_Bank_Reference__c,loan__Bank_Account__r.loan__Bank_Name__c,loan__Bank_Account__r.loan__Contact__c,loan__Bank_Account__r.BSB_Number__c,loan__Bank_Account__r.loan__Active__c,loan__Sent_To_ACH__c,loan__Bank_Account__r.Account_Holder_s_Name__c,loan__Sent_To_ACH_On__c FROM loan__Disbursal_Txn_Distribution__c WHERE loan__Bank_Account__r.loan__Account_Type__c !='BPAY' AND loan__Loan_Disbursal_Transaction__c IN ";
export const SF_BANK_TRUST_QUERY =
  "SELECT Id,clcommon__Account__c,clcommon__Account_Type__c, clcommon__Account_Usage__c,clcommon__ACH_Code__c,clcommon__Active__c, clcommon__Bank_Account_Name__c, clcommon__Bank_Account_Number__c, clcommon__Bank_Name__c,clcommon__Contact__c, clcommon__Primary__c, clcommon__Routing_Number__c, BSB_Number__c, Account_Holder_Name__c  FROM clcommon__Bank_Account__c WHERE clcommon__Account_Usage__c ='Investor Trust Account'  AND clcommon__Active__c=true LIMIT 1";
export const SF_LOAN_CONTRACT_QUERY =
  "SELECT Id, loan__Account__c, loan__Contact__c,loan__Contact__r.Name, loan__Account__r.Name FROM loan__Loan_Account__c WHERE Id IN ";
export const SF_FLOWFI_BANK_PARAM_QUERY =
  "SELECT Id,Name,FINANCIAL_INSTITUTE__c,USER_NAME__c,USER_ID__c FROM FlowFi_bank_params__c WHERE Name='credit_bank_params'";
export const LOAN_PAYMENT_TXN_GEN_QUERY =
  "select id, Name, loan__Sent_to_ACH__c,loan__ACH_Filename__c,loan__Sent_To_ACH_On__c, loan__Loan_Account__r.loan__Contact__r.Name, loan__Payment_Type__c, loan__Transaction_Amount__c, loan__Transaction_Date__c, loan__Loan_Account__c, loan__Loan_Account__r.loan__Account__r.Name, loan__Loan_Account__r.loan__Account__r.Id, loan__Payment_Mode__c, loan__Cleared__c from loan__Loan_Payment_Transaction__c where loan__Payment_Mode__r.Name ='ACH' AND loan__Sent_to_ACH__c = FALSE AND loan__Cleared__c = true AND loan__Payment_Type__c IN ('Regular', 'Write-Off Recovery')";
export const LOAN_PMT_BANK_PARAMS =
  "SELECT Id, Name, FINANCIAL_INSTITUTE__c, REMITTER__c, USER_ID__c, USER_NAME__c FROM FlowFi_bank_params__c WHERE Name=";
export const ACCOUNT_DETAILS_TRUST_ACC =
  "SELECT id, clcommon__Account__c,clcommon__Account_Type__c,clcommon__Account_Usage__c,clcommon__ACH_Code__c,clcommon__Active__c,clcommon__Bank_Account_Name__c,clcommon__Bank_Account_Number__c,clcommon__Bank_Name__c,clcommon__Contact__c,clcommon__Primary__c,clcommon__Routing_Number__c,BSB_Number__c,Account_Holder_Name__c FROM clcommon__Bank_Account__c WHERE clcommon__Account_Usage__c = 'Collections Trust Account' AND clcommon__Active__c = true LIMIT 1";
export const SF_BPAY_BATCHJOB_METADATA_QUERY =
  "SELECT DeveloperName,  MasterLabel, Active__c, CF_1__c, CF_2__c,CF_3__c,Query__c,Size__c, Header_Record_Type__c, Customer_Code__c, Customer_Name__c, Last_Customer_File_Reference__c,Currency__c,Version__c, Record_Type__c, BPAY_Biller_Number__c,Trailer_Record_Type__c FROM BatchJob_Spec__mdt WHERE MasterLabel='BpayFileGenJob' AND Active__c=true AND Size__c<>null";
export const SF_BUSINESS_BANK_ACC_QUERY =
  "SELECT id,clcommon__Account__c, clcommon__Account_Type__c, clcommon__Account_Usage__c, clcommon__ACH_Code__c, clcommon__Active__c, clcommon__Bank_Account_Name__c,clcommon__Bank_Account_Number__c,clcommon__Bank_Name__c, clcommon__Contact__c,clcommon__Primary__c, clcommon__Routing_Number__c, BSB_Number__c, Account_Holder_Name__c FROM clcommon__Bank_Account__c WHERE clcommon__Account_Usage__c = 'Business Account' AND clcommon__Active__c=true";
export const SF_ACCOUNT_DETAILS_TRUST_ACC_QUERY =
  "SELECT id, clcommon__Account__c,clcommon__Account_Type__c,clcommon__Account_Usage__c,clcommon__ACH_Code__c,clcommon__Active__c,clcommon__Bank_Account_Name__c,clcommon__Bank_Account_Number__c,clcommon__Bank_Name__c,clcommon__Contact__c,clcommon__Primary__c,clcommon__Routing_Number__c,BSB_Number__c,Account_Holder_Name__c FROM clcommon__Bank_Account__c WHERE clcommon__Account_Usage__c = 'Collections Trust Account' AND clcommon__Active__c = true LIMIT 1";
export const SF_BANK_LIST_QUERY =
  "Select id,loan__Account__c,loan__Account_Usage__c,loan__Contact__c,loan__Bank_Account_Number__c,loan__Bank_Name__c,BSB_Number__c,loan__Active__c From loan__Bank_Account__c Where loan__Active__c = True And loan__Account_Usage__c = 'Borrower/Investor Account' And loan__Account__c != null";
export const SF_LOAN_PAYMENT_TRANSACTION_QUERY =
  "SELECT Id,Name,loan__Loan_Account__c, loan__Payment_Mode__r.Name,loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__Loan_Product_Code__c,loan__Loan_Account__r.loan__Loan_Product_Name__r.Name,loan__Loan_Account__r.Is_this_a_Test_Data__c,loan__Loan_Account__r.Name,loan__Loan_Account__r.loan__Loan_Status__c,loan__Transaction_Date__c,CreatedDate,loan__Transaction_Amount__c,loan__Reversed__c,loan__Loan_Account__r.loan__Charged_Off_Fees__c,loan__Loan_Account__r.loan__Charged_Off_Interest__c,loan__Loan_Account__r.loan__Charged_Off_Principal__c FROM loan__Loan_Payment_Transaction__c WHERE loan__Loan_Account__r.loan__Loan_Status__c LIKE '%Active%'  AND loan__Transaction_Date__c =";
export const SF_CHARGE_QUERY =
  "SELECT Id,Name,loan__Loan_Account__c,loan__Waive__c,loan__Fee__r.Name,loan__Fee__r.loan__Amount__c,loan__Loan_Account__r.Name,loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__Loan_Product_Code__c,loan__Loan_Account__r.loan__Loan_Product_Name__r.Name,loan__Loan_Account__r.Is_this_a_Test_Data__c,loan__Loan_Account__r.loan__Loan_Status__c,CreatedDate,loan__Date__c FROM loan__Charge__c WHERE loan__Date__c=";
export const SF_OTHERLOAN_TRANSACTION_QUERY =
  "SELECT Id,Name,CreatedDate,loan__Charged_Off_Fees__c,loan__Txn_Amt__c,loan__Loan_Account__c,loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__Loan_Product_Code__c,loan__Loan_Account__r.loan__Loan_Product_Name__r.Name,loan__Loan_Account__r.Is_this_a_Test_Data__c,loan__Loan_Account__r.loan__Loan_Status__c,loan__Loan_Account__r.Name,loan__Transaction_Type__c,loan__Reversed__c,loan__Txn_Date__c,loan__Charged_Off_Principal__c,loan__Charged_Off_Interest__c FROM loan__Other_Transaction__c  WHERE loan__Txn_Date__c =";
export const SF_INTEREST_POSTING_QUERY =
  "SELECT Id,Name,CreatedDate,loan__Interest_Posted__c,loan__Loan_Contract__c,loan__Loan_Contract__r.Name,loan__Loan_Contract__r.loan__Loan_Status__c,loan__Loan_Contract__r.loan__Loan_Product_Name__r.Name,loan__Loan_Contract__r.loan__Loan_Product_Name__r.loan__Loan_Product_Code__c,loan__Loan_Contract__r.Is_this_a_Test_Data__c,loan__Reversed__c,loan__Transaction_Posting_Date__c FROM loan__Interest_Posting_Transaction__c WHERE loan__Transaction_Posting_Date__c=";
export const SF_ALL_DDI_QUERY =
  "SELECT Id,Name,CreatedDate,loan__Distribution_Type__c,loan__Distribution_Amount__c,loan__Name_of_Entity__c,loan__Reversed__c,loan__Bank_Account__c,loan__Loan_Disbursal_Transaction__c,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__c,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__Loan_Product_Code__c,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.loan__Loan_Product_Name__r.Name,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.Is_this_a_Test_Data__c,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.loan__Loan_Status__c,loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__r.Name,loan__Bank_Account__r.loan__Account_Type__c,loan__Loan_Disbursal_Transaction__r.loan__Disbursal_Date__c FROM loan__Disbursal_Txn_Distribution__c WHERE loan__Loan_Disbursal_Transaction__r.loan__Disbursal_Date__c=";
export const SF_INSURANCE_POLICY_REPORT_QUERY =
  "SELECT id, Loan_Account__r.Perpetual_Product_Code__c, Loan_Account__r.Original_State__c, Loan_Account__r.Name,Loan_Account__r.ICBS_Genesis_Account_Number__c,Product__c,Policy_Status__c,Premium_Amount_Net__c,Premium_Amount_GST__c,Premium_Amount_S_Duty__c,Loan_Account__r.loan__Number_of_Installments__c,Months_Elapsed__c,Insurance_Product_Name__c,Remaining_Months__c,Loan_Account__r.loan__Contractual_Interest_Rate__c,Policy_Effective_Date__c,Policy_Expiry_Date__c,Cancellation_Date__c,UEP__c,Premium_Rebate_Amount_Gross__c,Premium_Rebate_Amount_Net__c,Premium_Rebate_Amount_GST__c, Premium_Rebate_Amount_S_Duty__c FROM Insurance__c";
export const SF_INSURANCE_TXN_CLAIM_AND_REFUND_REPORT_QUERY =
  "SELECT id,loan__Cleared__c, loan__Loan_Account__r.Original_State__c, loan__Loan_Account__r.name, loan__Loan_Account__r.ICBS_Genesis_Account_Number__c, Insurance__r.Product__c, Insurance__r.Insurance_Product_Name__c, loan__Payment_Mode__r.name , name,  loan__Cheque_Number__c,  loan__Loan_Account__r.Perpetual_Product_Code__c, Insurance__r.Policy_Effective_Date__c, Insurance__r.Policy_Status__c, loan__Transaction_Date__c, createdDate, loan__Transaction_Amount__c,    State__c, Q2_Product_Number__c, Ins_Product__c, Ins_Product_Name__c, Ins_Refund_Prem__c, Ins_Refund_GST__c,  Ins_Refund_S_Duty__c,(SELECT loan__Loan_Payment_Transaction__r.name, loan__Adjustment_Txn_Date__c,loan__Payment_Mode__c, createdDate,loan__Reference__c FROM loan__Repayment_Transaction_Adjustment__r WHERE loan__Payment_Mode__c IN ('INSURANCE CLAIM PMT', 'INS REFUND - STAMP DUTY','INS REFUND - GST','INS REFUND - PREM - UI','INS REFUND - PREM - DIS','INS REFUND - PREM - LIFE')) FROM loan__Loan_Payment_Transaction__c WHERE loan__Cleared__c = true  AND loan__Payment_Mode__r.name IN ('INSURANCE CLAIM PMT', 'INS REFUND - STAMP DUTY','INS REFUND - GST','INS REFUND - PREM - UI','INS REFUND - PREM - DIS','INS REFUND - PREM - LIFE') ORDER BY CreatedDate";
export const SF_INSURANCE_CHARGED_OFF_EXCEPTION_QUERY =
  "SELECT id,CL_Contract__c FROM Exception__c WHERE Exception_Category__c = 'Deceased' AND Reported_Date__c != null";
export const SF_INSURANCE_CHARGED_OFF_QUERY =
  "SELECT id, name,Loan_Account__c, Premium_Rebate_Amount_Net__c, Loan_Account__r.loan__Charged_Off_Date__c ,Cancellation_Date__c FROM Insurance__c where User_Defined_Policy_Status__c  = 'Charged Off' AND Premium_Rebate_Amount_Gross__c !=0";
export const SF_INSURANCE_CHARGED_OFF_LOAN_REPORT_QUERY =
  "SELECT ID, loan__Account__c,loan__Account__r.First_Name__c, loan__Account__r.Last_Name__c, loan__Account__r.BillingStreet,loan__Account__r.BillingCity,loan__Account__r.BillingPostalCode, loan__Account__r.BillingState, loan__Account__r.BillingCountry,ICBS_Genesis_Account_Number__c, loan__Charged_Off_Date__c,(SELECT id, name,Cover_Type__c,Policy_Type__c,Product__c, Premium_Rebate_Amount_Net__c,Premium_Rebate_Amount_GST__c,Premium_Rebate_Amount_S_Duty__c,Premium_Rebate_Amount_Gross__c FROM Insurances__r where User_Defined_Policy_Status__c = 'Charged Off'),(SELECT id, name,loan__Account__r.First_Name__c, loan__Account__r.Last_Name__c,loan__Account__r.BillingStreet, loan__Account__r.BillingCity, loan__Account__r.BillingState, loan__Account__r.BillingPostalCode, loan__Account__r.BillingCountry FROM loan__Coborrowers__r WHERE loan__Party_Type__c = 'COBORROWER') FROM loan__Loan_Account__c WHERE (loan__Charged_Off_Date__c >= queryStartDate AND loan__Charged_Off_Date__c <= queryEndDate) AND ID IN ";
export const SF_DECEASED_EXCEPTION_QUERY =
  "SELECT ID,Name, CL_Contract__c FROM Exception__c WHERE Exception_Category__c = 'Deceased' AND Reported_Date__c !=NULL";
export const SF_AML_FRN_JURISDICTION_LOAN_QUERY =
  "SELECT ID,NAME,Account_Sold_Status_del1__c,loan__Loan_Status__c,loan__Account__r.Name,loan__Loan_Product_Name__r.name, loan__Account__r.BillingCity,loan__Account__r.BillingStreet,loan__Account__r.BillingState,loan__Account__r.BillingPostalCode,loan__Account__r.City__c ,loan__Account__r.State__c ,loan__Account__r.Zip__c ,loan__Account__r.Country__c,(SELECT Id, Name FROM Notices__r WHERE Notice_Type__c = 'S88' AND Notice_State__c = 'Issued'), Onshore_Address_Count__c FROM loan__Loan_Account__c WHERE Account_Sold_Status_del1__c = False AND (loan__Loan_Status__c = 'Active - Good Standing' OR loan__Loan_Status__c = 'Active - Bad Standing') AND loan__Account__r.BillingCountry != 'Australia' AND loan__Account__r.ShippingCountry != 'Australia' AND loan__Account__r.Country__c != 'Australia' AND ( loan__Account__r.Type != 'Aggregator' OR loan__Account__r.Type != 'Subaggregator/Group' OR loan__Account__r.Type != 'Broker' ) AND loan__Account__r.Name != 'Latitude' AND ID Not In(";
export const SF_BPAY_TXN_DATA_STORE_RECORD_TYPE_QUERY =
  "SELECT Id FROM RecordType where Name = ";
export const SUNDRY_CREDITOR_INVOICE_REPORT_QUERY =
  "SELECT CreatedDate,CreatedBy.Name,loan__Date__c,Name,loan__Loan_Account__r.Name, loan__Waive__c,loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__Loan_Product_Code__c,loan__Loan_Account__r.loan__Account__r.Name,Supplier_Name__c, Supplier_ABN__c, Supplier_Address__c, Invoice_Number__c, Invoice_Date__c, GST_Charged_to_Customer__c, Gross_Invoice_Amount_including_GST__c, GST__c, GST_Recovery_Amount_Waived__c, Invoice_Amount_excluding_GST__c, Description__c, GST_Recovery_Amount__c, Amount_Charged_to_Customer__c, Enforcement_Fee_Description__c , (SELECT loan__Loan_Payment_Transaction__r.Name,CreatedBy.Name,CreatedDate,loan__Transaction_Date__c FROM loan__Fee_Payment__r WHERE loan__Loan_Payment_Transaction__r.loan__Payment_Type__c = 'Waived') FROM loan__Charge__c WHERE loan__Fee__r.name = 'Enforcement Fee' AND loan__Loan_Account__r.loan__Loan_Product_Name__r.name like '%Personal Loan%' AND (CALENDAR_MONTH(createdDate) = currentMonth AND CALENDAR_YEAR(createdDate) = currentYear) order by CreatedDate";
export const INTEREST_ACCRUED_NOT_CAPITALISED_REPORT_QUERY =
  "SELECT name, loan__Loan_Status__c, Loan_Accrual_Status__c , loan__Last_Interest_Posting_Date__c , loan__Next_Capitalization_Date__c , loan__Loan_Product_Name__r.loan__Loan_Product_Code__c,loan__Number_of_Days_Overdue__c,loan__Interest_Accrued_Not_Due__c,loan__Interest_Remaining__c FROM loan__Loan_Account__c WHERE loan__Loan_Status__c IN ('Active - Good Standing','Active - Bad Standing','Active - Marked for Closure') AND loan__Loan_Product_Name__r.Name like '%Personal Loan%' AND loan__Number_of_Days_Overdue__c < 90 AND (loan__Interest_Accrued_Not_Due__c>0 OR loan__Interest_Remaining__c>0)";

/* ASYNC JSFORCE EVENTs */
export const RECORD_QUERY_EVENT = {
  record: "record",
  end: "end",
  error: "error",
};

/* **************************
 * SF QUERY CONDITION TYPE
 ************************** */
export const CRN_ID_STR = "crnId";
export const BA_ID_STR = "baId";

/* ***********************
 * APIs END POINTS
 ************************* */

// ILLION - Upload doc
export const ILLION_OCR_UPLOAD_API_DET = {
  URL: "/api/v1/upload",
  METHOD: "POST",
  CONTENT_TYPE: APPLICATION_JSON,
};
// SF - Retrieve cv doc
export const SF_CV_DOCUMENT_RETRIEVE_API_DET = {
  METHOD: "GET",
  CONTENT_TYPE: "plan/text",
};
// SF - Retrieve cv doc
export const SF_ATC_DOCUMENT_RETRIEVE_API_DET = {
  METHOD: "GET",
  CONTENT_TYPE: "plan/text",
};
// SF - Upload cv doc
export const SF_CV_FILE_UPLOAD_API_DET = {
  URL: "/services/data/v51.0/sobjects/ContentVersion",
  METHOD: "POST",
  CONTENT_TYPE: MULTIPART_FORM,
};
