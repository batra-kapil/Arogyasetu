public without sharing class FetchHealthcareProviders {

    public class Input {
        @InvocableVariable(required=true)
        public List<Id> recordIds;

        @InvocableVariable(required=false)
        public String specialtyName;
    }

    public class Output {
        @InvocableVariable
        public List<ProviderWrapper> providers;
    }

    @InvocableMethod(label='Get Providers with Time Slots')
    public static List<Output> getProviders(List<Input> inputs) {

        Set<Id> ids = new Set<Id>();
        String specialty = null;

        for (Input i : inputs) {
            if (i.recordIds != null) ids.addAll(i.recordIds);
            if (specialty == null && i.specialtyName != null) {
                specialty = i.specialtyName;
            }
        }

        // 🔥 STEP 1: Providers
        List<HealthcareProvider> records = [
            SELECT Id, Name, ProviderClass, ProviderType, Image__c,
                   AccountId, Account.OperatingHoursId
            FROM HealthcareProvider
            WHERE Id IN :ids
        ];

        // 🔥 STEP 2: Collect Account + OH
        Set<Id> accountIds = new Set<Id>();
        Set<Id> ohIds = new Set<Id>();
        Map<Id, Id> providerToOH = new Map<Id, Id>();

        for (HealthcareProvider hp : records) {
            if (hp.AccountId != null) {
                accountIds.add(hp.AccountId);
            }
            if (hp.Account != null && hp.Account.OperatingHoursId != null) {
                providerToOH.put(hp.Id, hp.Account.OperatingHoursId);
                ohIds.add(hp.Account.OperatingHoursId);
            }
        }

        // 🔥 STEP 3: Languages
        Map<Id, List<String>> languageMap = new Map<Id, List<String>>();

        for (PersonLanguage pl : [
            SELECT Language, IndividualId
            FROM PersonLanguage
            WHERE IndividualId IN :accountIds
        ]) {
            if (!languageMap.containsKey(pl.IndividualId)) {
                languageMap.put(pl.IndividualId, new List<String>());
            }
            languageMap.get(pl.IndividualId).add(pl.Language);
        }

        // 🔥 STEP 4: TimeSlots
        Map<Id, List<String>> ohToSlots = new Map<Id, List<String>>();

        if (!ohIds.isEmpty()) {
            for (TimeSlot ts : [
                SELECT DayOfWeek, StartTime, EndTime, OperatingHoursId
                FROM TimeSlot
                WHERE OperatingHoursId IN :ohIds
                ORDER BY DayOfWeek, StartTime
            ]) {

                if (!ohToSlots.containsKey(ts.OperatingHoursId)) {
                    ohToSlots.put(ts.OperatingHoursId, new List<String>());
                }

                String slot =
                    ts.DayOfWeek + ' ' +
                    formatTime(ts.StartTime) + ' - ' +
                    formatTime(ts.EndTime);

                ohToSlots.get(ts.OperatingHoursId).add(slot);
            }
        }

        // 🔥 STEP 5: Build Wrapper
        List<ProviderWrapper> providerList = new List<ProviderWrapper>();

        for (HealthcareProvider hp : records) {

            ProviderWrapper p = new ProviderWrapper();
            p.Id = hp.Id;
            p.Name = hp.Name;
            p.ProviderType = hp.ProviderType;
            p.ProviderClass = hp.ProviderClass;

            // IMAGE
            if (hp.Image__c != null) {
                Matcher m = Pattern.compile('https?://[^"\\s>]+').matcher(hp.Image__c);
                if (m.find()) p.Image = m.group(0);
            }

            // LANGUAGE
            if (hp.AccountId != null && languageMap.containsKey(hp.AccountId)) {
                p.Language = String.join(languageMap.get(hp.AccountId), ', ');
            }

            // SPECIALTY
            if (specialty != null) {
                p.Specialty = specialty;
            }

            // 🔥 TIME SLOTS
                if (providerToOH.containsKey(hp.Id)) {
                    Id ohId = providerToOH.get(hp.Id);
                
                    if (ohToSlots.containsKey(ohId)) {
                        p.TimeSlots = new List<String>(ohToSlots.get(ohId)); // ✅ FIX
                    } else {
                        p.TimeSlots = new List<String>{ 'No slots available' };
                    }
                } else {
                    p.TimeSlots = new List<String>{ 'No operating hours assigned' };
                }

            providerList.add(p);
        }

        Output o = new Output();
        o.providers = providerList;

        return new List<Output>{ o };
    }

    private static String formatTime(Time t) {
        if (t == null) return '';

        Integer hour = t.hour();
        Integer minute = t.minute();

        String ampm = hour >= 12 ? 'PM' : 'AM';
        hour = Math.mod(hour, 12);
        if (hour == 0) hour = 12;

        String minStr = minute < 10 ? '0' + minute : String.valueOf(minute);

        return hour + ':' + minStr + ' ' + ampm;
    }
}