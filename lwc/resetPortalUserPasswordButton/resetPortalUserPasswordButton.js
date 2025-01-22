/**
 * @description       : Button to allow users to reset a portal users password directly from the user record.
 * @author            : Daniel Learmont
 * @last modified on  : 09-07-2024
 * @last modified by  : Daniel Learmont
**/
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import resetPassword from '@salesforce/apex/ResetPortalUserPasswordButtonController.resetPassword';

export default class ResetPortalUserPasswordButton extends LightningElement {
    @api recordId;

    handleClick() {
        resetPassword({contactId: this.recordId})
            .then(() => {
                this.showToast('Success', 'Password reset email sent successfully!', 'success', 'pester');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error', 'sticky');
            });
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
}