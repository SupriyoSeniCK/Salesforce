/**
 * @description       : 
 * @author            : Supriyo Seni
 * @group             : 
 * @last modified on  : 01-20-2025
 * @last modified by  : Supriyo Seni
**/
import {LightningElement, track, wire} from "lwc";
import searchLoanContracts from "@salesforce/apex/ManualCommunicationsController.searchLoanContracts";
import getClContractInvestors from "@salesforce/apex/ManualCommunicationsController.getClContractInvestors";
import sendEmailWithAttachments from "@salesforce/apex/ManualCommunicationsController.sendEmailWithAttachments";
import getHtmlFormattedEmailMap from "@salesforce/apex/ManualCommunicationsController.getHtmlFormattedEmailMap";
import getFromAddressOptions from "@salesforce/apex/ManualCommunicationsHelper.getFromAddressList";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import CSS_COLORS from '@salesforce/resourceUrl/CSS_COLORS';
import {refreshApex} from "@salesforce/apex";
import {loadStyle} from 'lightning/platformResourceLoader';
const MAX_FILE_SIZE = 2097152; //20MB
const MAX_SEND_EMAIL_COUNT = 3000;
const EMAIL_SUBJECT_PREFIX = 'FOLK2FOLK Loan to ';

export default class ManualCommunications extends LightningElement {
    isCssLoaded = false;
    // Map to store html email body against selected investor Ids
    investorIdVsHtmlEmailMap = [];
    
    // Base Url for record redirection
    @track baseUrl = "https://" + location.host + "/";
    @track isLoading = false;

    // File or attachment related variables
    @track isFilePresent = false;
    @track filesData = [];
    savedFileList = [];

    //Send Email related variables
    fromAddressOptions = [];
    selectedFromAddress = '';
    emailBody = '';
    emailSubject = '';
    savedEmailBody = '';
    savedEmailSubject = '';
    isFirstClickOnEmailBody = false;
    @track previewHtmlEmail;
    @track previewSubject;
    @track isPreviewEmail = false;
    @track isSendEmailButtonDisabled = true;
    @track proceedWithSendingEmail = false;
    @track isComposeEmailButtonDisabled = false;
    @track isEmailComposerBoxVisible = false;

    // Cl Contract Related variables
    searchClContract = '';
    selectedLoanIdList = []
    selectedClContractRowList = [];
    loanIdVsNameMap;
    loanIdVsAccountNameMap;
    @track showSearchedContractList = false;
    @track clContractRowSelected = false;
    @track showClContractSearchBox = true;
    @track proceedWithClContracts = false;
    @track clContractList =[];
    @track selectedClContractList = [];
    @track countClContractRecords = 0;
    @track preSelectedClContractIdList = [];
    @track clContractColumns = [
        {
            label: "CL Contract",
            fieldName: "clContractUrl",
            type: "url",
            wrapText: true,
            hideDefaultActions: true,
            typeAttributes: {
                label: {
                    fieldName: "clContractName",
                },
                target: "_blank",
            },
        },
        {
            label: "Borrower Name",
            fieldName: "borrowerName",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
        },
        {
            label: "Loan Status",
            fieldName: "loanStatus",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
        },
        {
            label: "Current Loan Amount",
            fieldName: "loanAmount",
            type: "currency",
            wrapText: false,
            hideDefaultActions: true,
            variant: "border-filled",
            typeAttributes: {
                currencyCode: "GBP",
                minimumFractionDigits: 2,
            },
            cellAttributes: {
                alignment: "left",
            },
        },
    ];
    @track selectedLoanColumns = [
        {
            label: "CL Contract",
            fieldName: "selectedLoan",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
        },
        {
            label: "Borrower Name",
            fieldName: "selectedBorrowerName",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
        },
    ];

    // Investor Related Variables
    investorIdVsEmailMap;
    investorIdVsAccountNameMap;
    investorIdVsLoanAccNoMap;
    investorIdVsBorrowerNameMap;
    allInvestorIdList;
    @track isClearSelectedInvestorButtonDisabled = false;
    @track countOfInvestorSelected = 0;
    @track preSelectedInvestorRows = [];
    @track selectedRowInvestorIdList = [];
    @track showClContractInvestors = false;
    @track clContractInvestorList = [];
    @track selectedInvestorList = [];
    @track investorDisplayColumns = [
        {
            label: "Investor Name",
            fieldName: "investorAccountUrl",
            type: "url",
            wrapText: true,
            hideDefaultActions: true,
            typeAttributes: {
                label: {
                    fieldName: "investorName",
                },
                target: "_blank",
            },
        },
        {
            label: "Status",
            fieldName: "investorStatus",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
            cellAttributes:{
                class:{fieldName:'statusColor'},
            }
        },
        {
            label: "Email",
            fieldName: "investorEmail",
            type: "email",
            wrapText: true,
            hideDefaultActions: true,
            variant : 'border-filled',
        },
        {
            label: "Recipient Override Reason",
            fieldName: "recipientOverride",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
            cellAttributes:{
                class:{fieldName:'recipientOverrideColor'},
            }
        },
        {
            label: "CL Contract",
            fieldName: "investorClContract",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
            cellAttributes:{
                class:{fieldName:'clContractColor'},
            }
        },
        {
            type: "button", label: 'Preview Email', typeAttributes: {
                label: 'Preview',
                name: 'Preview',
                title: 'Preview',
                disabled: {fieldName:'previewButtonDisabled'},
                value: 'Preview',
                iconPosition: 'left',
                iconName:'utility:preview',
                variant:'Brand'
            }
        },
    ];
    @track selectedInvestorColumns = [
        {
            label: "Investor Name",
            fieldName: "selectedInvestorName",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
        },
        {
            label: "Email",
            fieldName: "selectedInvestorEmail",
            type: "text",
            wrapText: true,
            hideDefaultActions: true,
            variant : 'border-filled',
        },
    ];

    // Capture Cl Contract enetered in the searchbox for search
    handleClContractSearchFilter(event){
        this.searchClContract = event.target.value;
        if(!this.searchClContract){
            this.showSearchedContractList = false;
        }
    }

    // If cl contract is being searched via enter
    handleClContractSearchKeyUp(event){
        if (event.key === 'Enter') {
            this.handleClContractSearchClick();
        }
    }

    // When cl contract search is initiated
    handleClContractSearchClick(){
        if(!this.searchClContract){
            this.showToast('Error!', "Please write something in the search box before hitting the 'Search' button or pressing 'Enter'.", 'error', 'pester');
            return;
        }
        this.isLoading = true;
        this.clContractRowSelected = this.countClContractRecords > 0 ?  true : false;
        let loanIdList = [];
        this.selectedClContractRowList = [];
        let loanDisplayList = [];
        searchLoanContracts({ searchTerm: this.searchClContract })
        .then(loanList => {
            if (loanList && loanList.length > 0) {
                loanList.forEach((eachLoan) => {
                    let eachloanDetailJson = JSON.stringify(eachLoan);
                    let eachLoanObj = JSON.parse(eachloanDetailJson);
                    eachLoanObj.clContractName = eachLoanObj?.Name;
                    eachLoanObj.clContractUrl = this.baseUrl + eachLoanObj?.Id;
                    eachLoanObj.borrowerName = eachLoanObj?.loan__Account__r?.Name;
                    eachLoanObj.loanStatus = eachLoanObj?.loan__Loan_Status__c;
                    eachLoanObj.loanAmount = eachLoanObj?.loan__Loan_Amount__c;
                    loanIdList.push(eachLoanObj.Id);
                    loanDisplayList.push(eachLoanObj);
                });
                if(loanIdList && this.selectedLoanIdList && (this.selectedLoanIdList).length > 0){
                    this.preSelectedClContractIdList = this.getPreSelectLoanIdList(loanIdList);
                }
                this.showSearchedContractList = true;
                this.clContractList = loanDisplayList;
                this.showToast('Info!', 'Select your contract(s) and proceed to fetch the investor Accounts.', 'Info', 'pester');
            } else {
                this.clContractList = null;
                this.showToast('Error!', 'No contracts found.', 'error', 'pester');
            }
        })
        .catch(error => {
            this.clContractList = null;
            if(error?.body?.message && (error.body.message).includes('You do not have access to the Apex class named \'ManualCommunicationsController\'.')){
                this.showToast('Insufficient Access Rights!','You do not have the necessary permissions to access this resource. Please contact your system administrator for further assistance.', 'error', 'sticky');
            }else if(error?.body?.message){
                this.showToast('Insufficient Access Rights!',error.body.message, 'error', 'sticky');
            }else{
                this.showToast('Error!','Something Went Wrong. Please contact your system admin','error','pester');
            }
        }).finally(() => this.isLoading = false);
    }

    // Get Pre Selected loans (in any)
    getPreSelectLoanIdList(loanIdList){
        var results = [];
        results = loanIdList.filter(element => (this.selectedLoanIdList).includes(element));
        return results;
    }
    // 
    handleContractClearSelectionButton(){
        this.countClContractRecords = 0;
        this.clContractRowSelected = false;
        this.preSelectedClContractIdList = [];
        this.selectedClContractRowList = [];
        this.selectedLoanIdList = [];
    }

    // This event is fired on CL Contract row click
    handleClContractRowclick(event){
        try{
            let idVsAccountNameMap = this.loanIdVsAccountNameMap ? this.loanIdVsAccountNameMap : new Map(); 
            let idVsNameMap = this.loanIdVsNameMap ? this.loanIdVsNameMap : new Map(); 
            // Get current selected rows
            let currentRows = event.detail.selectedRows;
            let selectedRowIdList = currentRows.map(row => row.Id);
            if (this.selectedClContractRowList.length > 0) {
                let unselectedRowIdList = this.selectedClContractRowList.filter(row => !selectedRowIdList.includes(row.Id));
                if (unselectedRowIdList.length > 0) {
                    unselectedRowIdList.forEach((eachContract) => {
                        let index = (this.selectedLoanIdList).indexOf(eachContract?.Id);
                        // Check if the element exists in the array
                        if (index !== -1) {
                            // Remove the element using splice
                            (this.selectedLoanIdList).splice(index, 1);
                        }
                    });
                }
            }
            this.selectedClContractRowList = currentRows;        
            if (currentRows.length > 0) {
                currentRows.forEach((eachClContract) => {
                    let index = (this.selectedLoanIdList.length > 0) ? (this.selectedLoanIdList).indexOf(eachClContract.Id) : -1;
                    if (index == -1) {
                        this.selectedLoanIdList.push(eachClContract.Id);
                        // Store selected loan Name and Borrower name in Maps for future use
                        idVsAccountNameMap.set(eachClContract.Id,eachClContract?.loan__Account__r?.Name);
                        idVsNameMap.set(eachClContract.Id,eachClContract?.Name);
                    }
                });
            }
            this.countClContractRecords = this.selectedLoanIdList.length;
            this.clContractRowSelected = this.countClContractRecords > 0 ? true : false;
            this.loanIdVsAccountNameMap = idVsAccountNameMap;
            this.loanIdVsNameMap = idVsNameMap;
        }catch(error){
            this.displayProperCatchError(error);
        }
    }

    handleClContractSelection(){
        try{
            this.isLoading = true;
            this.proceedWithClContracts = true;
            let selectedLoanDisplayList = [];
            if (this.selectedLoanIdList) {
                (this.selectedLoanIdList).forEach((eachLoanId) => {
                    const dataRow = {};
                    // Loan Name
                    dataRow.selectedLoan = this.loanIdVsNameMap.get(eachLoanId);
                    //Borrower Name
                    dataRow.selectedBorrowerName = this.loanIdVsAccountNameMap.get(eachLoanId);
                    selectedLoanDisplayList.push(dataRow);
                });
            }
            this.selectedClContractList = selectedLoanDisplayList;
            this.isLoading = false;
        }catch(error){
            this.displayProperCatchError(error);
            this.isLoading = false;        
        }
    }

    handleBackToContractSearchButton(event){
        this.isLoading = true;
        this.handleContractClearSelectionButton();
        this.showClContractSearchBox = true;
        this.showClContractInvestors = false;
        this.proceedWithClContracts = false;
        this.countOfInvestorSelected = 0;
        this.preSelectedInvestorRows = [];
        this.selectedRowInvestorIdList = [];
        this.isLoading = false;
    }

    handleInvestorDetails(event){
        this.proceedWithClContracts = false;
        this.showClContractSearchBox = false;
        this.showClContractInvestors = true;
        this.isLoading = true;
        let investorDisplayList = [];
        let initialContract = '';
        let currrentContractCss = 'text-dark-blue';
        let preSelectInvestorIdList = [];
        this.investorIdVsEmailMap = new Map(); 
        this.investorIdVsAccountNameMap = new Map(); 
        this.investorIdVsLoanAccNoMap = new Map();
        this.investorIdVsBorrowerNameMap = new Map();
        let investorIdArray = [];
        getClContractInvestors({ loanIdList: this.selectedLoanIdList })
        .then(loanInvestorList => {
            if (loanInvestorList && loanInvestorList.length > 0) {
                loanInvestorList.forEach((eachInvestor) => {
                    let eachInvestorDetailJson = JSON.stringify(eachInvestor);
                    let eachInvestorObj = JSON.parse(eachInvestorDetailJson);
                    if(eachInvestorObj.loan__Status__c == 'Active'){
                        preSelectInvestorIdList.push(eachInvestorObj.Id);
                    }
                    // Array to store all Investor Ids for email template fetch further
                    investorIdArray.push(eachInvestorObj.Id);
                    eachInvestorObj.previewButtonDisabled = (this.emailBody && this.selectedRowInvestorIdList.length > 0
                        && (this.selectedRowInvestorIdList).indexOf(eachInvestorObj.Id) !== -1) ? false : true;
                    eachInvestorObj.investorAccountUrl = this.baseUrl +  eachInvestorObj?.loan__Account__c;
                    eachInvestorObj.investorName = eachInvestorObj?.loan__Account__r?.Name;
                    eachInvestorObj.investorStatus =  eachInvestorObj?.loan__Status__c;
                    eachInvestorObj.investorClContract = eachInvestorObj?.loan__Loan__r.Name;
                    eachInvestorObj.investorEmail = eachInvestorObj?.loan__Account__r?.clcommon__Email__c;
                    eachInvestorObj.recipientOverride = (eachInvestorObj?.loan__Loan_Status__c) ? eachInvestorObj?.loan__Loan_Status__c : '-';
                    eachInvestorObj.recipientOverrideColor = (eachInvestorObj?.loan__Loan_Status__c) ? 'slds-text-color_error' : null;
                    this.investorIdVsEmailMap.set(eachInvestorObj.Id,eachInvestorObj?.loan__Account__r?.clcommon__Email__c);
                    this.investorIdVsAccountNameMap.set(eachInvestorObj.Id,eachInvestorObj?.loan__Account__r?.Name);
                    this.investorIdVsLoanAccNoMap.set(eachInvestorObj.Id, eachInvestorObj?.loan__Loan__r.Name);
                    this.investorIdVsBorrowerNameMap.set(eachInvestorObj.Id, eachInvestorObj.Borrower_Name__c);
                    if(initialContract != (eachInvestorObj?.loan__Loan__r?.Name)){
                        currrentContractCss = (currrentContractCss == 'text-dark-blue') ? 'text-dark-purple' : 'text-dark-blue';
                    }
                    eachInvestorObj.clContractColor = currrentContractCss;
                    eachInvestorObj.statusColor = (eachInvestorObj?.loan__Status__c == 'Active') ? 'text-dark-green' : 'slds-text-color_error';
                    initialContract = eachInvestorObj?.loan__Loan__r?.Name;
                    eachInvestorObj.clContractColor = currrentContractCss;
                    investorDisplayList.push(eachInvestorObj);
                });
                this.isComposeEmailButtonDisabled = false;
                if(this.selectedRowInvestorIdList.length <= 0){
                    this.showToast('Info!', 'All Active Investors are preselected. If required, modify the selections before proceeding.', 'Info', 'pester');
                }else{
                    this.isSendEmailButtonDisabled = false;
                }
                this.allInvestorIdList = investorIdArray;
            } else {
                this.clContractInvestorList = null;
                this.isComposeEmailButtonDisabled = true;
                this.showToast('Error!', 'No Investors found. Please return to CL Contract Search Page.', 'error', 'sticky');
            }
            this.clContractInvestorList = investorDisplayList;
            this.selectedRowInvestorIdList = (this.selectedRowInvestorIdList.length > 0) ? this.selectedRowInvestorIdList : preSelectInvestorIdList;
            this.preSelectedInvestorRows = this.selectedRowInvestorIdList;
            this.countOfInvestorSelected = (this.selectedRowInvestorIdList.length > 0) ? this.selectedRowInvestorIdList.length : 0;
        }).catch(error => {
            this.clContractInvestorList = null;
            this.displayProperCatchError(error);      
        }).finally(() => this.isLoading = false);
    }
    
    handleClContractInvestorClick(event){
        this.isLoading = true;
        let currentRows = event.detail.selectedRows;
        this.isSendEmailButtonDisabled = true;
        let preiouslySelectedIdArray = [...this.selectedRowInvestorIdList];
        this.selectedRowInvestorIdList = [];
        if (currentRows.length > 0) {
            currentRows.forEach((eachInvestor) => {
                (this.selectedRowInvestorIdList).push(eachInvestor.Id);
            });
        }
        if(this.emailBody){
            if(!currentRows || currentRows.length <= 0){
                this.selectedRowInvestorIdList = preiouslySelectedIdArray;
                this.showToast('Error!', 'To send email at least one investor should be marked.' , 'error', 'pester');
            }
            refreshApex(this.handleInvestorDetails());
        }else{
            this.isLoading = false;
        }
        this.countOfInvestorSelected = this.selectedRowInvestorIdList.length;
    }

    hideClContractModelBox() {  
        this.proceedWithClContracts = false;
    }

    hideSendEmailModelBox(){
        this.proceedWithSendingEmail = false;
    }

    handleComposeEmailButton(){
        if(this.selectedRowInvestorIdList.length == 0){
            this.isEmailComposerBoxVisible = false;
            this.showToast('Forbidden!', 'Select at least one investor to be able to compose email.' , 'error', 'pester');
            return;
        }
        this.filesData = [...this.savedFileList];
        this.isEmailComposerBoxVisible = true;
        this.emailBody = this.savedEmailBody;
        this.emailSubject = this.savedEmailSubject;
        if(this.filesData.length > 0) {
            this.isFilePresent = true;
        }
    }

    hideEmailComposerModalBox(){
        this.isEmailComposerBoxVisible = false;
        this.isFirstClickOnEmailBody = false;
        if(!(this.savedEmailBody && this.savedEmailBody)){
            this.isSendEmailButtonDisabled = true;
            this.isClearSelectedInvestorButtonDisabled = false;
        }else{
            this.isSendEmailButtonDisabled = false;
            this.isClearSelectedInvestorButtonDisabled = true;
            this.isLoading = true;
            refreshApex(this.handleInvestorDetails());
            this.investorIdVsHtmlEmailMap = new Map();
            getHtmlFormattedEmailMap({
                investorIdList : this.allInvestorIdList,
                body : this.savedEmailBody
            }).then(data => {
                if(data){
                    for (var key in data) {
                        this.investorIdVsHtmlEmailMap.set(key,data[key]);
                    }
                }
            }).catch(error => {
                this.displayProperCatchError(error);
            }).finally(() => this.isLoading = false );
        }
        this.filesData = [];
    }

    handleSubjectChange(event){
        this.emailSubject = event.target.value;
    }

    handleEmailBodyChange(event){
        if(!this.isFirstClickOnEmailBody){
            this.isFirstClickOnEmailBody = true;
            this.showToast('Important!', 'Please ensure you do NOT add any salutations like "Dear XYZ" in the body, but please do add a footer.', 'warning', 'sticky');
        }        
        this.emailBody = event.target.value;
    }

    handleComposeEmailSaveButton(){
        if (!this.selectedFromAddress) {
            this.showToast('Error', 'From Address is required.', 'error', 'pester');
        } else if (!this.emailBody) {
            this.showToast('Error', 'Email Body is required.', 'error', 'pester');
        } else {
            this.isSendEmailButtonDisabled = false;
            this.savedEmailBody = this.emailBody;
            this.savedEmailSubject = this.emailSubject;
            this.savedFileList = [...this.filesData];
            this.showToast('Success!', 'Saved Successfully.', 'success', 'pester');
        }
    }

    handleComposeEmailResetButton(){
        this.emailSubject = '';
        this.emailBody = '';
        this.filesData = []; 
        this.isFirstClickOnEmailBody = false;
    }

    @wire(getFromAddressOptions)
    wiredEmails({ error, data }) {
        if (data) {
            this.fromAddressOptions = data.map(email => ({
                label: `${email.DisplayName} (${email.Address})`,
                value: email.Id
            }));
        } else if (error) {
            this.showToast('Error', 'Error retrieving from address options: ' + JSON.stringify(error), 'error', 'pester');
        }
    }

    handleFromAddressChange(event) {
        this.selectedFromAddress = event.target.value;
    }

    openSendEmailDialogueBox(){
        this.proceedWithSendingEmail = true;
        if(this.selectedRowInvestorIdList.length > MAX_SEND_EMAIL_COUNT){
            this.proceedWithSendingEmail = false;
            this.showToast('Error!', 'The system cannot send more than ' + MAX_SEND_EMAIL_COUNT + ' emails at a time. Please select the investors accordingly.', 'error','sticky');
            return;
        }
        this.isLoading = true;
        let selectedInvestorDisplayList = [];
        if (this.selectedRowInvestorIdList) {
            (this.selectedRowInvestorIdList).forEach((eachInvestorId) => {
                const dataRow = {};
                // Investor Account Name
                dataRow.selectedInvestorName = this.investorIdVsAccountNameMap.get(eachInvestorId);
                //Investor Email
                dataRow.selectedInvestorEmail = this.investorIdVsEmailMap.get(eachInvestorId);
                selectedInvestorDisplayList.push(dataRow);
            });
        }
        this.selectedInvestorList = selectedInvestorDisplayList;
        this.isLoading = false;
    }

    handleSendEmailToInvestors(){
        this.proceedWithSendingEmail = false;
        this.isLoading = true;
        let paramArray = [];
        let fileDataJson = (this.savedFileList != [] && this.savedFileList.length > 0) ? JSON.stringify(this.savedFileList) : '';
        paramArray.push(this.savedEmailSubject);
        paramArray.push(this.savedEmailBody);
        paramArray.push(fileDataJson);
        paramArray.push(this.selectedFromAddress);
        sendEmailWithAttachments({
            investorIdList : this.selectedRowInvestorIdList,
            investorIdVsEmailsJson : JSON.stringify(Object.fromEntries(this.investorIdVsEmailMap)),
            paramList : paramArray
        })
        .then(result => {
            if(result && result == 'SUCCESS') {
                this.showToast('Success!', 'Emails Sent successfully.','success','pester');
            } else {
                this.showToast('Error!', result, 'error','pester');
            }
        }).catch(error => {
            this.displayProperCatchError(error);
        }).finally(() => this.isLoading = false );
    }

    // File Uploads
    handleFileUploaded(event) {
        if (event.target.files.length > 0) {
            for(var i=0; i< event.target.files.length; i++){
                if (event.target.files[i].size > MAX_FILE_SIZE) {
                    this.showToast('Error!', 'File size exceeded the upload size limit.','error','pester');
                    return;
                }
                let file = event.target.files[i];
                let reader = new FileReader();
                reader.onload = e => {
                    var fileContents = reader.result.split(',')[1]
                    this.filesData.push({'fileName':file.name, 'fileContent':fileContents});
                    this.isFilePresent = true;
                };
                reader.readAsDataURL(file);
            }
        }
    }

    removeReceiptImage(event) {
        var index = event.currentTarget.dataset.id;
        this.filesData.splice(index, 1);
        if(this.filesData == [] || this.filesData.length == 0) {
            this.isFilePresent = false;
        }
    }

    callRowActionForInvestors(event){
        try{
            const investorRecordId = event.detail.row.Id;
            const actionName = event.detail.action.name;
            if (actionName === 'Preview') {
                this.isLoading = true;
                this.previewSubject = EMAIL_SUBJECT_PREFIX +  this.investorIdVsBorrowerNameMap.get(investorRecordId) + ' ' + this.investorIdVsLoanAccNoMap.get(investorRecordId) + ' ' + this.savedEmailSubject;
                this.previewHtmlEmail = this.investorIdVsHtmlEmailMap ? (this.investorIdVsHtmlEmailMap).get(investorRecordId) : null;
                if(!this.previewHtmlEmail){
                    this.showToast('Error!','Email preview not available.' ,'error','pester');
                }else{
                    this.isPreviewEmail = true;
                }
                this.isLoading = false;
            }
        }catch(error){
            this.showToast('Something went wrong!','Please try again after sometime.' ,'error','pester');
            this.isLoading = false;
            this.isPreviewEmail = false;
            console.log('error : ',error);
        }
    }

    hidePreviewEmailModalBox(){
        this.isPreviewEmail = false;
    }

    clearSelectedInvestor(){
        this.countOfInvestorSelected = 0;
        this.preSelectedInvestorRows = [];
        this.selectedRowInvestorIdList = [];
        this.isSendEmailButtonDisabled = true;
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode,
        });
        this.dispatchEvent(event);
    }

    // Load CSS to apply custom color to the componenets
    renderedCallback(){ 
        if(this.isCssLoaded) return
        this.isCssLoaded = true;
        loadStyle(this, CSS_COLORS).then(()=>{
            console.log("Loaded Successfully");
        }).catch(error=>{ 
            console.error("Error in loading the colors");
        })
    }
    
    displayProperCatchError(error){
        if(error?.body?.message) {
            this.showToast('Error!!',error.body.message,'error','sticky');
        }else{
            this.showToast('Error!','Something Went Wrong.','error','pester');
        }  
    }
}