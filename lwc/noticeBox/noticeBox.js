// noticeBox.js
import { LightningElement, api } from 'lwc';

export default class NoticeBox extends LightningElement {
    @api type = 'information'; // default type
    @api message = 'This is a notice box.'; // default message

    get iconName() {
        switch (this.type) {
            case 'warning':
                return 'utility:warning';
            case 'error':
                return 'utility:error';
            default:
                return 'utility:info';
        }
    }

    get boxStyle() {
        switch (this.type) {
            case 'warning':
                return 'background-color: #fff7e5; color: #f6a400; padding: 0.75rem 1rem; border-radius: 0.5rem; display: flex; align-items: center;';
            case 'error':
                return 'background-color: #fdecea; color: #d92d20; padding: 0.75rem 1rem; border-radius: 0.5rem; display: flex; align-items: center;';
            default:
                return 'background-color: #e3f7fc; color: #0070d2; padding: 0.75rem 1rem; border-radius: 0.5rem; display: flex; align-items: center;';
        }
    }

    get iconStyle() {
        return 'margin-right: 0.5rem;';
    }
}