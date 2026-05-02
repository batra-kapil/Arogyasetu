import { LightningElement, api } from 'lwc';

export default class TimeSlotPicker extends LightningElement {

    @api value;
    selectedSlot;

    get slots() {
        let data = [];

        // Handle flat array OR wrapper
        if (Array.isArray(this.value)) {
            data = this.value;
        } else if (this.value?.slots) {
            data = this.value.slots;
        }

        // 🔥 DO NOT MODIFY TIME — USE LABEL DIRECTLY
        return data.map(s => ({
            label: s.timeLabel,      // ✅ EXACT from Apex
            value: s.timeValue,      // backend only
            className: this.selectedSlot === s.timeValue
                ? 'slot selected'
                : 'slot'
        }));
    }

    get hasSlots() {
        return this.slots.length > 0;
    }

    handleClick(event) {
        const slotValue = event.currentTarget.dataset.value;
        this.selectedSlot = slotValue;

        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                timeValue: slotValue
            }
        }));
    }
}