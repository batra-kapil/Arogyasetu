public with sharing class AppointmentSlotService {

    // ===== INPUT WRAPPER =====
    public class SlotRequest {
        @InvocableVariable(required=true)
        public Id doctorId;

        @InvocableVariable(required=true)
        public Date selectedDate;

        @InvocableVariable(required=true)
        public Datetime scheduleStart;

        @InvocableVariable(required=true)
        public Datetime scheduleEnd;
    }

    // ===== MAIN METHOD =====
    @InvocableMethod(label='Get Available Appointment Slots')
    public static List<SlotListWrapper> getAvailableSlots(List<SlotRequest> requests) {

        List<SlotListWrapper> finalResponse = new List<SlotListWrapper>();

        for (SlotRequest req : requests) {

            Datetime startTime = req.scheduleStart;
            Datetime endTime   = req.scheduleEnd;

            // ===== STEP 1: Generate Slots =====
            List<Datetime> generatedSlots = new List<Datetime>();

            while (startTime.addMinutes(30) <= endTime) {

                Datetime slot = Datetime.newInstance(
                    startTime.year(),
                    startTime.month(),
                    startTime.day(),
                    startTime.hour(),
                    startTime.minute(),
                    0
                );

                generatedSlots.add(slot);
                startTime = startTime.addMinutes(30);
            }

            // ===== STEP 2: Existing Appointments =====
            Datetime startOfDay = Datetime.newInstance(
                req.selectedDate,
                Time.newInstance(0, 0, 0, 0)
            );

            Datetime endOfDay = startOfDay.addDays(1);

            List<ServiceAppointment> existingAppointments = [
                SELECT EarliestStartTime
                FROM ServiceAppointment
                WHERE EarliestStartTime >= :startOfDay
                AND EarliestStartTime < :endOfDay
                AND Status = 'Scheduled'
                AND Doctor__c = :req.doctorId
            ];

            Set<Long> bookedSlots = new Set<Long>();

            for (ServiceAppointment sa : existingAppointments) {
                bookedSlots.add(sa.EarliestStartTime.getTime());
            }

            // ===== STEP 3: Build Available Slots =====
            List<SlotResponseWrapper> availableSlots = new List<SlotResponseWrapper>();

            for (Datetime slot : generatedSlots) {

                if (!bookedSlots.contains(slot.getTime())) {

                    SlotResponseWrapper sr = new SlotResponseWrapper();
                    sr.timeValue = slot;
                    sr.timeLabel = formatTime(slot);

                    availableSlots.add(sr);
                }
            }

            // ===== STEP 4: Sort =====
            availableSlots.sort(new SlotComparator());

            // ===== STEP 5: Limit =====
            availableSlots = limitSlots(availableSlots, 8);

            // ===== STEP 6: Wrap into SINGLE OUTPUT =====
            SlotListWrapper wrapper = new SlotListWrapper();
            wrapper.slots = availableSlots;

            finalResponse.add(wrapper);
        }

        return finalResponse;
    }

    // ===== FORMAT TIME =====
    private static String formatTime(Datetime dt) {
        Time t = dt.time();

        Integer hour = t.hour();
        Integer minute = t.minute();

        String ampm = hour >= 12 ? 'PM' : 'AM';

        hour = Math.mod(hour, 12);
        if (hour == 0) hour = 12;

        String minuteStr = minute < 10 ? '0' + minute : String.valueOf(minute);

        return hour + ':' + minuteStr + ' ' + ampm;
    }

    // ===== LIMIT =====
    private static List<SlotResponseWrapper> limitSlots(List<SlotResponseWrapper> slots, Integer maxSize) {
        List<SlotResponseWrapper> result = new List<SlotResponseWrapper>();

        Integer size = Math.min(maxSize, slots.size());

        for (Integer i = 0; i < size; i++) {
            result.add(slots[i]);
        }

        return result;
    }

    // ===== SORT =====
    public class SlotComparator implements Comparator<SlotResponseWrapper> {
        public Integer compare(SlotResponseWrapper a, SlotResponseWrapper b) {
            if (a.timeValue == b.timeValue) return 0;
            return a.timeValue > b.timeValue ? 1 : -1;
        }
    }
}