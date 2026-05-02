import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Account.Summary__c',
    'Account.Name'
];

export default class PatientSummary extends LightningElement {

    @api recordId;

    summary;
    patientName;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.summary = data.fields.Summary__c.value;
            this.patientName = data.fields.Name.value;
        } else if (error) {
            console.error('Error fetching summary', error);
        }
    }

    get hasSummary() {
        return this.summary && this.summary.trim() !== '';
    }
}