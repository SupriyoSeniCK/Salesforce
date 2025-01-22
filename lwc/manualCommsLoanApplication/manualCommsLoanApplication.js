import {LightningElement, track, wire} from "lwc";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {refreshApex} from "@salesforce/apex";
import {loadStyle} from 'lightning/platformResourceLoader';
import searchLoanApplications from "@salesforce/apex/ManualCommunicationsController.searchLoanApplications";
import getLoanApplicationInvestors from "@salesforce/apex/ManualCommunicationsController.getLoanApplicationInvestors";
import sendEmailWithAttachments from "@salesforce/apex/ManualCommunicationsController.sendEmailWithAttachmentsForLoanApplications";
import getHtmlFormattedEmailMap from "@salesforce/apex/ManualCommunicationsController.getHtmlFormattedEmailMapForLoanApplications";
import getFromAddressOptions from "@salesforce/apex/ManualCommunicationsHelper.getFromAddressList";
import CSS_COLORS from '@salesforce/resourceUrl/CSS_COLORS';
const MAX_FILE_SIZE = 2097152; //20MB
const MAX_SEND_EMAIL_COUNT = 2000; 

export default class ManualCommsLoanApplication extends LightningElement {
    isCssLoaded = false;
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
    @track isPreviewEmail = false;
    @track isSendEmailButtonDisabled = true;
    @track proceedWithSendingEmail = false;
    @track isComposeEmailButtonDisabled = false;
    @track isEmailComposerBoxVisible = false;

    // Loan Applications Related variables
    searchLoanApplication = '';
    selectedLoanAppIdList = []
    selectedLoanApplicationRowList = [];
    loanIdVsNameMap;
    loanIdVsAccountNameMap;
    @track showSearchedContractList = false;
    @track loanApplicationRowSelected = false;
    @track showLoanApplicationSearchBox = true;
    @track proceedWithLoanApplications = false;
    @track loanApplicationList =[];
    @track selectedLoanApplicationList = [];
    @track countLoanApplicationRecords = 0;
    @track preSelectedLoanApplicationIdList = [];
    @track loanApplicationColumns = [
        {
            label: "Loan Application ID",
            fieldName: "loanApplicationUrl",
            type: "url",
            wrapText: true,
            hideDefaultActions: true,
            typeAttributes: {
                label: {
                    fieldName: "loanApplicationName",
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
            label: "Stage",
            fieldName: "loanAppStage",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
        },
    ];
    @track selectedLoanColumns = [
        {
            label: "Loan Application Id",
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
    allInvestorIdList;
    @track isClearSelectedInvestorButtonDisabled = false;
    @track countOfInvestorSelected = 0;
    @track preSelectedInvestorRows = [];
    @track selectedRowInvestorIdList = [];
    @track showLoanApplicationInvestors = false;
    @track loanApplicationInvestorList = [];
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
            label: "Stage",
            fieldName: "investorStage",
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
            label: "Recipient Override",
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
            label: "Loan Application",
            fieldName: "investorLoanApplication",
            type: "text",
            wrapText: false,
            hideDefaultActions: true,
            variant : 'border-filled',
            cellAttributes:{
                class:{fieldName:'loanApplicationColor'},
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

    // Capture Loan Applications enetered in the searchbox for search
    handleLoanApplicationSearchFilter(event){
        this.searchLoanApplication = event.target.value;
        if(!this.searchLoanApplication){
            this.showSearchedContractList = false;
        }
    }

    // If Loan Applications is being searched via enter
    handleLoanApplicationSearchKeyUp(event){
        if (event.key === 'Enter') {
            this.handleLoanApplicationSearchClick();
        }
    }

    // When Loan Applications search is initiated
    handleLoanApplicationSearchClick(){
        if(!this.searchLoanApplication){
            this.showToast('Error!', "Please write something in the search box before hitting the 'Search' button or pressing 'Enter'.", 'error', 'pester');
            return;
        }
        this.isLoading = true;
        this.loanApplicationRowSelected = this.countLoanApplicationRecords > 0 ?  true : false;
        let loanIdList = [];
        this.selectedLoanApplicationRowList = [];
        let loanDisplayList = [];
        searchLoanApplications({ loanApplicationName: this.searchLoanApplication })
        .then(loanAppList => {
            if (loanAppList && loanAppList.length > 0) {
                loanAppList.forEach((eachLoan) => {
                    let eachloanDetailJson = JSON.stringify(eachLoan);
                    let eachLoanObj = JSON.parse(eachloanDetailJson);
                    eachLoanObj.loanApplicationName = eachLoanObj.Name;
                    eachLoanObj.loanApplicationUrl =  this.baseUrl + eachLoanObj.Id;
                    eachLoanObj.borrowerName = eachLoanObj.peer__Borrower__r.Name;
                    eachLoanObj.loanAppStage = eachLoanObj.peer__Stage__c;
                    loanIdList.push(eachLoanObj.Id);
                    loanDisplayList.push(eachLoanObj);
                });
                if(loanIdList && (this.selectedLoanAppIdList).length > 0){
                    this.preSelectedLoanApplicationIdList = this.getPreSelectLoanIdList(loanIdList);
                }
                this.showSearchedContractList = true;
                this.loanApplicationList = loanDisplayList;
                this.showToast('Info!', 'Select your Loan Application(s) and proceed to fetch the investor Accounts.', 'Info', 'pester');
            } else {
                this.loanApplicationList = null;
                this.showToast('Error!', 'No Loan Application found.', 'error', 'pester');
            }
        })
        .catch(error => {
            this.loanApplicationList = null;
            if(error?.body?.message && (error.body.message).includes('You do not have access to the Apex class named \'ManualCommunicationsController\'.')){
                this.showToast('Insufficient Access Rights!','You do not have the necessary permissions to access this resource. Please contact your system administrator for further assistance.', 'error', 'sticky');
            }else if(error?.body?.message){
                this.showToast('Insufficient Access Rights!',error.body.message, 'error', 'sticky');
            }else{
                this.showToast('Error!','Something Went Wrong. Please contact your system admin','error','pester');
            }
        }).finally(() => this.isLoading = false);
    }

    // Get Pre Selected loan Applications (in any)
    getPreSelectLoanIdList(loanIdList){
        var results = [];
        results = loanIdList.filter(element => (this.selectedLoanAppIdList).includes(element));
        return results;
    }
    // clear Selection button click on Loan Application seatch page
    handleContractClearSelectionButton(){
        this.countLoanApplicationRecords = 0;
        this.loanApplicationRowSelected = false;
        this.preSelectedLoanApplicationIdList = [];
        this.selectedLoanApplicationRowList = [];
        this.selectedLoanAppIdList = [];
    }

    // This event is fired on Loan Applications row click
    handleLoanApplicationRowclick(event){
        try{
            let idVsAccountNameMap = this.loanIdVsAccountNameMap ? this.loanIdVsAccountNameMap : new Map(); 
            let idVsNameMap = this.loanIdVsNameMap ? this.loanIdVsNameMap : new Map(); 
            // Get current selected rows
            let currentRows = event.detail.selectedRows;
            let selectedRowIdList = currentRows.map(row => row.Id);
            if (this.selectedLoanApplicationRowList.length > 0) {
                let unselectedRowIdList = this.selectedLoanApplicationRowList.filter(row => !selectedRowIdList.includes(row.Id));
                if (unselectedRowIdList.length > 0) {
                    unselectedRowIdList.forEach((eachContract) => {
                        let index = (this.selectedLoanAppIdList).indexOf(eachContract.Id);
                        // Check if the element exists in the array
                        if (index !== -1) {
                            // Remove the element using splice
                            (this.selectedLoanAppIdList).splice(index, 1);
                        }
                    });
                }
            }
            this.selectedLoanApplicationRowList = currentRows;        
            if (currentRows.length > 0) {
                currentRows.forEach((eachLoanApplication) => {
                    let index = (this.selectedLoanAppIdList.length > 0) ? (this.selectedLoanAppIdList).indexOf(eachLoanApplication.Id) : -1;
                    if (index == -1) {
                        this.selectedLoanAppIdList.push(eachLoanApplication.Id);
                        // Store selected loan Name and Borrower name in Maps for future use
                        idVsAccountNameMap.set(eachLoanApplication.Id,eachLoanApplication.peer__Borrower__r.Name);
                        idVsNameMap.set(eachLoanApplication.Id,eachLoanApplication.Name);
                    }
                });
            }
            this.countLoanApplicationRecords = this.selectedLoanAppIdList.length;
            this.loanApplicationRowSelected = this.countLoanApplicationRecords > 0 ? true : false;
            this.loanIdVsAccountNameMap = idVsAccountNameMap;
            this.loanIdVsNameMap = idVsNameMap;
        }catch(error){
            this.displayProperCatchError(error);
        }
    }

    handleLoanApplicationSelection(){
        try{
            this.isLoading = true;
            this.proceedWithLoanApplications = true;
            let selectedLoanDisplayList = [];
            if (this.selectedLoanAppIdList) {
                (this.selectedLoanAppIdList).forEach((eachLoanId) => {
                    const dataRow = {};
                    // Loan Name
                    dataRow.selectedLoan = this.loanIdVsNameMap.get(eachLoanId);
                    //Borrower Name
                    dataRow.selectedBorrowerName = this.loanIdVsAccountNameMap.get(eachLoanId);
                    selectedLoanDisplayList.push(dataRow);
                });
            }
            this.selectedLoanApplicationList = selectedLoanDisplayList;
            this.isLoading = false;
        }catch(error){
            this.displayProperCatchError(error);
            this.isLoading = false;        
        }
    }

    handleBackToContractSearchButton(event){
        this.isLoading = true;
        this.handleContractClearSelectionButton();
        this.showLoanApplicationSearchBox = true;
        this.showLoanApplicationInvestors = false;
        this.proceedWithLoanApplications = false;
        this.countOfInvestorSelected = 0;
        this.preSelectedInvestorRows = [];
        this.selectedRowInvestorIdList = [];
        this.isLoading = false;
    }

    // Fetch the investor List for the datatable in Investor Account List Page
    handleInvestorDetails(event){
        this.proceedWithLoanApplications = false;
        this.showLoanApplicationSearchBox = false;
        this.showLoanApplicationInvestors = true;
        this.isLoading = true;
        let investorDisplayList = [];
        let initialLoanApp = '';
        let currrentContractCss = 'text-dark-orange';
        let preSelectInvestorIdList = [];
        let investorIdArray = [];
        this.investorIdVsEmailMap = new Map(); 
        this.investorIdVsAccountNameMap = new Map(); 
        getLoanApplicationInvestors({ loanAppIdList: this.selectedLoanAppIdList })
        .then(loanInvestorList => {
            if (loanInvestorList && loanInvestorList.length > 0) {
                loanInvestorList.forEach((eachInvestor) => {
                    let eachInvestorDetailJson = JSON.stringify(eachInvestor);
                    let eachInvestorObj = JSON.parse(eachInvestorDetailJson);
                    preSelectInvestorIdList.push(eachInvestorObj.Id);
                    investorIdArray.push(eachInvestorObj.Id);
                    // Preview of email button disable or enable condition
                    eachInvestorObj.previewButtonDisabled = (this.emailBody && this.emailSubject && this.selectedRowInvestorIdList.length > 0
                            && (this.selectedRowInvestorIdList).indexOf(eachInvestorObj.Id) !== -1) ? false : true;
                    eachInvestorObj.investorAccountUrl = this.baseUrl + eachInvestorObj.peer__Booking_Order__r.peer__Investor__r.Id;
                    eachInvestorObj.investorName = eachInvestorObj.peer__Booking_Order__r.peer__Investor__r.Name;
                    eachInvestorObj.investorStage = eachInvestorObj.peer__Stage__c;
                    eachInvestorObj.investorLoanApplication = eachInvestorObj.peer__Loan_Application__r.Name;
                    eachInvestorObj.investorEmail = eachInvestorObj.peer__Booking_Order__r.peer__Investor__r.clcommon__Email__c;
                    eachInvestorObj.recipientOverride = (eachInvestorObj?.peer__Status__c) ? eachInvestorObj?.peer__Status__c : '-';
                    eachInvestorObj.recipientOverrideColor = (eachInvestorObj?.peer__Status__c) ? 'slds-text-color_error' : null;
                    this.investorIdVsEmailMap.set(eachInvestorObj.Id,eachInvestorObj.peer__Booking_Order__r.peer__Investor__r.clcommon__Email__c);
                    this.investorIdVsAccountNameMap.set(eachInvestorObj.Id,eachInvestorObj.peer__Booking_Order__r.peer__Investor__r.Name)
                    if(initialLoanApp != (eachInvestorObj.peer__Loan_Application__r.Name)){
                        currrentContractCss = (currrentContractCss == 'text-dark-orange') ? 'text-dark-pink' : 'text-dark-orange';
                    }
                    eachInvestorObj.loanApplicationColor = currrentContractCss;
                    eachInvestorObj.statusColor = (eachInvestorObj.peer__Stage__c == 'Funded') ? 'text-dark-green' : 'slds-text-color_error';
                    initialLoanApp = eachInvestorObj.peer__Loan_Application__r.Name;
                    eachInvestorObj.loanApplicationColor = currrentContractCss;
                    investorDisplayList.push(eachInvestorObj);
                });
                this.allInvestorIdList = investorIdArray;
                this.isComposeEmailButtonDisabled = false;
                if(this.selectedRowInvestorIdList.length <= 0){
                    this.showToast('Info!', 'All Investors are preselected be default. If required, modify the selections before proceeding.', 'Warning', 'pester');
                }else{
                    this.isSendEmailButtonDisabled = false;
                }
            } else {
                this.loanApplicationInvestorList = null;
                this.isComposeEmailButtonDisabled = true;
                this.showToast('Error!', 'No Investors found. Please return to Loan Application Search Page.', 'error', 'sticky');
            }
            this.loanApplicationInvestorList = investorDisplayList;
            this.selectedRowInvestorIdList = (this.selectedRowInvestorIdList.length > 0) ? this.selectedRowInvestorIdList : preSelectInvestorIdList;
            this.preSelectedInvestorRows = this.selectedRowInvestorIdList;
            this.countOfInvestorSelected = (this.selectedRowInvestorIdList.length > 0) ? this.selectedRowInvestorIdList.length : 0;
        }).catch(error => {
            this.loanApplicationInvestorList = null;
            this.displayProperCatchError(error);      
        }).finally(() => this.isLoading = false);
    }
    
    handleLoanApplicationInvestorClick(event){
        this.isLoading = true;
        this.isSendEmailButtonDisabled = true;
        let currentRows = event.detail.selectedRows;
        this.selectedRowInvestorIdList = [];
        if (currentRows.length > 0) {
            currentRows.forEach((eachInvestor) => {
                (this.selectedRowInvestorIdList).push(eachInvestor.Id);
            });
        }
        if(this.emailBody && this.emailSubject){
            refreshApex(this.handleInvestorDetails());
            if(!currentRows || currentRows.length <= 0){
                this.showToast('Error!', 'To send email at least one investor should be marked.' , 'error', 'pester');
            }
        }else{
            this.isLoading = false;
        }
        this.countOfInvestorSelected = this.selectedRowInvestorIdList.length;
    }

    hideLoanApplicationModelBox() {  
        this.proceedWithLoanApplications = false;
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
        } else if (!this.emailSubject) {
            this.showToast('Error', 'Email Subject is required.', 'error', 'pester');
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

    @wire(getFromAddressOptions)
    wiredEmails({ error, data }) {
        if (data) {
            this.fromAddressOptions = data.map(email => ({
                label: `${email.DisplayName} (${email.Address})`,
                value: email.Id
            }));
        } else if (error) {
            this.showToast('Error', 'Error retrieving from address options: ' + error, 'error', 'pester');
        }
    }

    handleFromAddressChange(event) {
        this.selectedFromAddress = event.target.value;
    }

    handleComposeEmailResetButton(){
        this.emailSubject = '';
        this.emailBody = '';
        this.filesData = []; 
        this.isFirstClickOnEmailBody = false;
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

    handleSendEmailToInvestors(event){
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
                this.previewHtmlEmail = this.investorIdVsHtmlEmailMap ? (this.investorIdVsHtmlEmailMap).get(investorRecordId) : null;
                if(!this.previewHtmlEmail){
                    this.showToast('Error!','Email preview not available.' ,'error','pester');
                }else{
                    this.isPreviewEmail = true;
                    this.showToast('Note!','Email Preview doesn\'t include Subject and Attachments.' ,'warning','pester');
                }
                this.isLoading = false;
            }
        }catch(error){
            this.showToast('Something went wrong!','Please try again.' ,'error','pester');
            this.isLoading = false;
            this.isPreviewEmail = false;
            console.log('error : ' + JSON.stringify(error));
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