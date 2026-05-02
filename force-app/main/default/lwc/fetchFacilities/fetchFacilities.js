import { LightningElement, api } from 'lwc';

export default class FetchFacilities extends LightningElement {

    @api value;

    get facilities() {
        console.log('##Value', JSON.stringify(this.value));

        if (!this.value) return [];

        let data = [];

        // ✅ Case 1: direct array (your current case)
        if (Array.isArray(this.value)) {
            data = this.value;
        }
        // ✅ Case 2: wrapped { addresses: [...] }
        else if (this.value.addresses) {
            data = this.value.addresses;
        }

        return data.map(item => ({
            id: item.id,
            parentName: item.parentName,
            drivingDirections: item.drivingDirections,
            fullAddress: [
                item.street,
                item.city,
                item.state,
                item.postalCode
            ].filter(Boolean).join(', ')
        }));
    }
}