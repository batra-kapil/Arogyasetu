import { LightningElement, api } from 'lwc';

export default class DoctorCardList extends LightningElement {

    @api value;

    get doctors() {
        let data = Array.isArray(this.value) ? this.value : [];

        return data.map(d => ({
            id: d.Id,
            name: d.Name,
            type: d.ProviderType,
            providerClass: d.ProviderClass,
            imageUrl: d.Image ? d.Image : this.defaultAvatar(),
            language: d.Language,
            specialty: d.Specialty,
            timeSlots: d.TimeSlots // 🔥 ADD THIS
        }));
    }

    defaultAvatar() {
        return 'https://cdn-icons-png.flaticon.com/512/149/149071.png';
    }
}