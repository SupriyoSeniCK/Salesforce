import { LightningElement, wire, api } from 'lwc';
import getUserLoginHistory from '@salesforce/apex/PortalUserLoginHistoryController.getLoginHistoryFromContactId';
const columns = [
    { label: 'Login Time', fieldName: 'LoginTime', type: 'date', 
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        } 
    },
    { label: 'Status', fieldName: 'Status', type: 'text' },
    { label: 'Application', fieldName: 'Application', type: 'text' },
    { label: 'Login URL', fieldName: 'LoginUrl', type: 'text' },
    { label: 'Platform', fieldName: 'Platform', type: 'text' }
];

export default class PortalUserLoginHistory extends LightningElement {
    @api recordId; //record Id of the contact
    columns = columns;
    loginHistory;
    error;

    @wire(getUserLoginHistory, { contactId: '$recordId' })
    wiredLoginHistory({ error, data }) {
        if (data) {
            this.loginHistory = data;
        } else if (error) {
            this.error = error;
            console.log('error: ' + JSON.stringify(error));
        }
    }
}
