import { LightningElement, api, wire } from 'lwc';
import getAppointments from '@salesforce/apex/PatientAppointmentController.getAppointments';

export default class PatientAppointments extends LightningElement {

    @api recordId;

    nextAppointment;
    upcomingAppointments = [];
    pastAppointments = [];

    @wire(getAppointments, { accountId: '$recordId' })
    wiredAppointments({ data, error }) {
        if (data) {

            const now = new Date();

            let sorted = [...data].sort((a, b) =>
                new Date(a.appointmentDateTime) - new Date(b.appointmentDateTime)
            );

            let nextFound = false;

            sorted.forEach(item => {
                const date = new Date(item.appointmentDateTime);
                const isUpcoming = date >= now;

                const enriched = {
                    ...item,
                    formattedDate: this.formatDate(item.appointmentDateTime),
                    isUpcoming: isUpcoming,
                    statusClass: this.getStatusClass(item.status),
                    tagClass: isUpcoming ? 'tag upcoming-tag' : 'tag past-tag'
                };

                if (isUpcoming && !nextFound) {
                    enriched.cardClass = 'appointment-card next';
                    enriched.countdown = this.getCountdown(date); // 🔥 ADD THIS
                    this.nextAppointment = enriched;
                    nextFound = true;
                } 
                else if (isUpcoming) {
                    enriched.cardClass = 'appointment-card upcoming';
                    this.upcomingAppointments.push(enriched);
                } 
                else {
                    enriched.cardClass = 'appointment-card past';
                    this.pastAppointments.push(enriched);
                }
            });

        } else if (error) {
            console.error(error);
        }
    }

    formatDate(dateString) {
        return new Date(dateString).toLocaleString('en-US', {
            day: '2-digit',
            month: 'short',
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        });
    }

    // 🔥 STATUS COLOR
    getStatusClass(status) {
        switch (status) {
            case 'Scheduled':
                return 'status scheduled';
            case 'Completed':
                return 'status completed';
            case 'Canceled':
            case 'Cancelled':
                return 'status cancelled';
            default:
                return 'status';
        }
    }

    // 🔥 COUNTDOWN LOGIC
    getCountdown(date) {
        const now = new Date();
        const diff = Math.ceil((date - now) / (1000 * 60 * 60 * 24));

        if (diff === 0) return 'Today';
        if (diff === 1) return 'Tomorrow';
        if (diff > 1) return `In ${diff} days`;

        return '';
    }

    get hasAppointments() {
        return this.nextAppointment || this.upcomingAppointments.length || this.pastAppointments.length;
    }
}