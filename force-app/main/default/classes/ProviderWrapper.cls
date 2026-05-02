public class ProviderWrapper {
    
    @AuraEnabled public Id Id;
    @AuraEnabled public String Name;
    @AuraEnabled public String ProviderType;
    @AuraEnabled public String ProviderClass;
    @AuraEnabled public String Image;
     @InvocableVariable public String Language;
    @InvocableVariable public String Specialty;
    @AuraEnabled public List<String> TimeSlots;
}