import { LightningElement, api, wire } from 'lwc';
import getAppointmentSummary from '@salesforce/apex/AppointmentSummaryService.getAppointmentSummary';

export default class AppointmentSummary extends LightningElement {

    @api recordId;
    summary;

    @wire(getAppointmentSummary, { accountId: '$recordId' })
    wiredSummary({ data, error }) {
        if (data) {
            this.summary = data;
        } else if (error) {
            console.error(error);
        }
    }

    get hasSummary() {
        return this.summary && this.summary.trim() !== '';
    }
}