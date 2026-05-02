public with sharing class FetchNearbyFacilities {

    // ===== Request from Agentforce =====
    public class Request {
        @InvocableVariable(required=true)
        public String city;
    }

    // ===== Response to Agentforce =====
    public class Response {
        @InvocableVariable
        public List<AddressWrapper> addresses;
    }

    // ===== Wrapper for clean output =====
    public class AddressWrapper {
        @InvocableVariable public Id id;
        @InvocableVariable public String street;
        @InvocableVariable public String city;
        @InvocableVariable public String state;
        @InvocableVariable public String postalCode;
        @InvocableVariable public String parentName;
        @InvocableVariable public String drivingDirections;
    }

    // ===== Main Invocable Method =====
    @InvocableMethod(
        label='Fetch Nearby Facilities by City'
        description='Returns Address records filtered by city for Agentforce'
    )
    public static List<Response> fetchAddresses(List<Request> requests) {

        List<Response> responseList = new List<Response>();

        for (Request req : requests) {

            Response res = new Response();
            res.addresses = new List<AddressWrapper>();

            // Guard clause
            if (req == null || String.isBlank(req.city)) {
                responseList.add(res);
                continue;
            }

            // Safe search string
            String searchCity = '%' + String.escapeSingleQuotes(req.city.trim()) + '%';

            // IMPORTANT: Use Schema.Address to avoid System.Address conflict
            List<Schema.Address> addressRecords = [
                SELECT Id, Street, City, State, PostalCode, Parent.Name, DrivingDirections
                FROM Address
                WHERE City LIKE :searchCity
                LIMIT 20
            ];

            for (Schema.Address addr : addressRecords) {

                AddressWrapper wrapper = new AddressWrapper();
                wrapper.id = addr.Id;
                wrapper.street = addr.Street;
                wrapper.city = addr.City;
                wrapper.state = addr.State;
                wrapper.postalCode = addr.PostalCode;
                wrapper.parentName = (addr.Parent != null) ? addr.Parent.Name : null;
                wrapper.drivingDirections = addr.DrivingDirections;

                res.addresses.add(wrapper);
            }

            responseList.add(res);
        }

        return responseList;
    }
}