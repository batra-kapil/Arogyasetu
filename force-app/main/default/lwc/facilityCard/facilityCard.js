import { LightningElement, api } from 'lwc';

export default class FacilityCard extends LightningElement {
    @api value;

    get facilities() {
        return (this.value?.addresses || []).map(f => ({
            ...f,
            fullAddress: [
                f.street,
                f.city,
                f.state,
                f.postalCode
            ]
            .filter(Boolean)
            .join(', ')
        }));
    }
}