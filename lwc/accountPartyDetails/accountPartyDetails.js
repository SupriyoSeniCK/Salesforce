/**
 * @description       : Display Account party Details
 * @author            : Supriyo Seni
 * @group             : JS file for LWC accountPartyDetails
 * @last modified on  : 12-26-2024
 * @last modified by  : Riya Kundu
**/
import { LightningElement,api,track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPartyContactDetails from '@salesforce/apex/AccountPartyDetailsController.getPartyContactDetails';
import updateRecords from '@salesforce/apex/AccountPartyDetailsController.updateRecords';

export default class AccountPartyDetails extends LightningElement {
    draftValues = [];
    rowVsAccountIdMap;
    rowVsContactIdMap;
    rowVsRelationIdMap; 
    rowVsPartyIdMap; 
    @track displayNoDataMessage = false;
    @api recordId;
    @track allPartyList;
    section = 'A';
    @track isLoading = false;
    @track baseUrl = "https://" + location.host + "/";
    @track partyDetailsColumns = [
        {
            label: "Full Name",
            fieldName: "accountUrl",
            type: "url",
            wrapText: true,
            hideDefaultActions: true,
            editable: false,
            typeAttributes: {
                label: {
                    fieldName: "accountFullName",
                },
                target: "_blank",
            },
        },
        {
            label: "Party Type",
            fieldName: "partyType",
            type: "text",
            initialWidth: 100,
            wrapText: false,
            hideDefaultActions: true,
            editable: false,
        },
        {
            label: "Key Info",
            fieldName: "keyInfo",
            type: "text",
            wrapText: true,
            hideDefaultActions: true,
            editable: true,
        },
        {
            label: "Telephone",
            fieldName: "primaryTelephone",
            type: "phone",
            initialWidth: 160,
            wrapText: false,
            hideDefaultActions: true,
            editable: true,
            cellAttributes: { iconName: 'standard:log_a_call', iconPosition: 'left' },
        },
        {
            label: "Email",
            fieldName: "emailAddress",
            type: "email",
            wrapText: false,
            hideDefaultActions: true,
            editable: true,
        },
        {
            label: "Address",
            fieldName: "addressUrl",
            type: "url",
            wrapText: true,
            initialWidth: 230,
            hideDefaultActions: true,
            typeAttributes: {
                label: {
                    fieldName: "address",
                },
                target: "_blank",
            },
        },
        {
            label: "DOB",
            fieldName: "dateOfBirth",
            wrapText: true,
            hideDefaultActions: true,
            editable: true,
            initialWidth: 120,
            type: "date-local",
            typeAttributes:{
                month: "2-digit",
                day: "2-digit"
            },
        },
        {
            label: "Deceased",
            fieldName: "deceasedFlag",
            type: "boolean",
            initialWidth: 70,
            wrapText: false,
            hideDefaultActions: true,
            editable: true,
        },
        {
            label: "Acting as POA",
            fieldName: "poaFlag",
            type: "boolean",
            wrapText: false,
            initialWidth: 70,
            hideDefaultActions: true,
            editable: true,
        },
        {
            label: "Primary",
            fieldName: "primaryContactFlag",
            type: "boolean",
            wrapText: false,
            initialWidth: 70,
            hideDefaultActions: true,
            editable: true,
        },
        {
            label: "Vulnerable",
            fieldName: "vulnerableFlag",
            type: "boolean",
            initialWidth: 70,
            wrapText: false,
            hideDefaultActions: true,
            editable: true,
        },
    ];

    connectedCallback(){
        this.isLoading = true;
        let partyDisplayList = [];
        let rowNumber = 0;
        this.section = 'A';
        let rowNumberVsAccountIdMap = new Map(); 
        let rowNumberVsContactIdMap = new Map(); 
        let rowNumberVsRelationIdMap = new Map(); 
        let rowNumberVsPartyIdMap = new Map(); 
        getPartyContactDetails({accountId : this.recordId})
        .then((partyDetailsList) => {
            if (partyDetailsList && partyDetailsList != ""){
                partyDetailsList.forEach((eachPartyDetail) => {
                    let eachPartyDetailJson = JSON.stringify(eachPartyDetail);
                    let eachPartyDetailObj = JSON.parse(eachPartyDetailJson);
                    // Account Full Name
                    eachPartyDetailObj.accountFullName = eachPartyDetailObj.fullName ?? '-';
                    eachPartyDetailObj.accountUrl = (eachPartyDetailObj.accountId == null) ? null : this.baseUrl + eachPartyDetailObj.accountId;
                    //Party Type
                    eachPartyDetailObj.partyType = eachPartyDetailObj.partyType;
                    //Key Info
                    eachPartyDetailObj.keyInfo = eachPartyDetailObj.keyInfo;
                    // Telephone
                    eachPartyDetailObj.primaryTelephone = eachPartyDetailObj.primaryTelephone;
                    //Email
                    eachPartyDetailObj.emailAddress = eachPartyDetailObj.emailAddress;
                    //Address
                    eachPartyDetailObj.address = eachPartyDetailObj.address ?? '-' ;
                    eachPartyDetailObj.addressUrl = (eachPartyDetailObj.addressId == null) ? null : this.baseUrl + eachPartyDetailObj.addressId;
                    //DOB
                    eachPartyDetailObj.dateOfBirth = eachPartyDetailObj.dateOfBirth;
                    //Primary Contact Flag
                    eachPartyDetailObj.primaryContactFlag = eachPartyDetailObj.primaryContactFlag;
                    //Deceased Flag
                    eachPartyDetailObj.deceasedFlag = eachPartyDetailObj.deceasedFlag;
                    //POA flag
                    eachPartyDetailObj.poaFlag = eachPartyDetailObj.poaFlag;
                    //Vulnarable Flag
                    eachPartyDetailObj.vulnerableFlag = eachPartyDetailObj.vulnerableFlag;

                    partyDisplayList.push(eachPartyDetailObj);
                    //Store record IDs in maps for use in apex class
                    rowNumberVsAccountIdMap.set('row-'+rowNumber,eachPartyDetailObj.accountId);
                    rowNumberVsContactIdMap.set('row-'+rowNumber,eachPartyDetailObj.contactId);
                    rowNumberVsRelationIdMap.set('row-'+rowNumber,eachPartyDetailObj.relationId);
                    rowNumberVsPartyIdMap.set('row-'+rowNumber,eachPartyDetailObj.partyId)
                    rowNumber = rowNumber + 1;
                });
            }else{
                this.section = '';
                this.displayNoDataMessage = true;
            }
            this.allPartyList = partyDisplayList;
            this.isLoading = false;
            this.rowVsAccountIdMap = rowNumberVsAccountIdMap;
            this.rowVsContactIdMap = rowNumberVsContactIdMap;
            this.rowVsRelationIdMap = rowNumberVsRelationIdMap; 
            this.rowVsPartyIdMap = rowNumberVsPartyIdMap;
        }).catch((error) =>{
            this.allPartyList = error;
            this.isLoading = false;
        })
    }

    async handleSave(event) {
        this.isLoading = true;
        let idMapArray = [];
        idMapArray.push(JSON.stringify(Object.fromEntries(this.rowVsAccountIdMap)));
        idMapArray.push(JSON.stringify(Object.fromEntries(this.rowVsContactIdMap)));
        idMapArray.push(JSON.stringify(Object.fromEntries(this.rowVsRelationIdMap)));
        idMapArray.push(JSON.stringify(Object.fromEntries(this.rowVsPartyIdMap)));
        // Convert datatable draft values into record objects
        const rowdraftValuesList = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);
            return { fields };
        });
        if (!rowdraftValuesList || rowdraftValuesList == ""){
            return;
        }
        let jsonString = JSON.stringify(rowdraftValuesList);
        // Call apex class for update records
        let result = await updateRecords({idMapList :idMapArray,jsonString : JSON.stringify(rowdraftValuesList)});
        if(result == 'success'){
            if(jsonString.includes('poaFlag')){
                // In cases POA Approed is being updated, wait for few secs to finish the async process in salesforce
                setTimeout(() => {
                    this.displaySuccessMessage('Successfully updated');
                    window.location.reload();
                }, 10000 );
            }else{
                this.displaySuccessMessage('Successfully updated');
                window.location.reload();
            }
        }else{
            this.displayErrorMessage('Failed to update. Error Message - '+result);
        }
        // Clear all datatable draft values
        this.draftValues = [];
    }

    displayErrorMessage(displayMessage){
        const toastEvent = new ShowToastEvent({
            title:'Error!',
            message: displayMessage,
            variant:'error'
        });
        this.dispatchEvent(toastEvent);
        this.isLoading = false;
    }

    displaySuccessMessage(displayMessage){
        const toastEvent = new ShowToastEvent({
            title:'Success!',
            message: displayMessage,
            variant:'success'
        });
        this.dispatchEvent(toastEvent);
        this.isLoading = false;
    }
}