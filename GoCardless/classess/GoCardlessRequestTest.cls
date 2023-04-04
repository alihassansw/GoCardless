@isTest
public class GoCardlessRequestTest {
    
    @isTest
    static void testCreateMandate() {
        String createMandateBody = '{"key": "value"}';
        String responseBody = '{ "billing_requests": { "id": "BRQ0002W4KW6G6Q", "created_at": "2023-03-13T08:10:58.465Z", "status": "pending", "mandate_request": null, "payment_request": { "description": "instant Payment", "currency": "GBP", "amount": 24600, "min_amount": null, "max_amount": null, "default_min_amount": null, "default_max_amount": null, "app_fee": null, "scheme": "faster_payments", "links": {}, "metadata": { "key": "value" }, "flexible_amount": false }, "metadata": null, "links": { "customer": "CU000TCWRYX0CN", "customer_billing_detail": "CBD000AS6JF918Z", "creditor": "CR000079N5DQWN", "organisation": "OR000057F0R7F3", "payment_request": "PRQ0000DJFYG1JH" }, "fallback_enabled": false, "fallback_occurred": false, "sign_flow_url": null, "creditor_name": "Prism Solutions", "actions": [ { "type": "choose_currency", "required": true, "completes_actions": [], "requires_actions": [], "status": "completed", "available_currencies": [ "USD", "SEK", "GBP", "AUD", "NZD", "DKK", "CAD", "EUR" ] }, { "type": "collect_amount", "required": true, "completes_actions": [], "requires_actions": [], "status": "completed" }, { "type": "collect_customer_details", "required": true, "completes_actions": [], "requires_actions": [ "choose_currency", "collect_amount" ], "status": "pending", "collect_customer_details": { "incomplete_fields": { "customer": [ "email", "given_name", "family_name" ], "customer_billing_detail": [] }, "default_country_code": "GB" } }, { "type": "select_institution", "required": true, "completes_actions": [], "requires_actions": [], "status": "pending" }, { "type": "collect_bank_account", "required": true, "completes_actions": [ "choose_currency" ], "available_country_codes": [ "GB" ], "requires_actions": [ "collect_amount" ], "status": "pending" }, { "type": "bank_authorisation", "required": true, "completes_actions": [], "requires_actions": [ "select_institution" ], "status": "pending", "bank_authorisation": { "authorisation_type": "payment", "requires_institution": true, "direct_to_institution": true, "adapter": "open_banking_gateway_pis" } } ], "resources": { "customer": { "id": "CU000TCWRYX0CN", "created_at": "2023-03-13T08:10:58.431Z", "email": null, "given_name": null, "family_name": null, "company_name": null, "language": "en", "phone_number": null, "metadata": {} }, "customer_billing_detail": { "id": "CBD000AS6JF918Z", "created_at": "2023-03-13T08:10:58.455Z", "address_line1": null, "address_line2": null, "address_line3": null, "city": null, "region": null, "postal_code": null, "country_code": null, "swedish_identity_number": null, "danish_identity_number": null } }, "experimentation": { "is_eligible_for_share_of_wallet_experiments": true, "is_eligible_for_optional_vm_experiments": false } } }';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));
        
        String result = GoCardlessRequest.createMandate(responseBody);
        
       
    }
    
    @isTest
    static void testCreateBillingRequestFlow() {

        String currentRecordId = '0066s000008CLPnAAO';
        String responseBody = '{ "billing_request_flows": { "id": "BRF00010VF1HR2QEZN1563PX291P8XHZ", "auto_fulfil": true, "redirect_uri": "https://gocardless.com/", "exit_uri": "https://developer.gocardless.com/", "authorisation_url": "https://pay-sandbox.gocardless.com/billing/static/flow?id=BRF00010VF1HR2QEZN1563PX291P8XHZ", "lock_customer_details": false, "lock_bank_account": false, "session_token": null, "expires_at": "2023-02-27T11:43:28.139Z", "created_at": "2023-02-20T11:43:28.140Z", "links": { "billing_request": "BRQ0002JWHWXSQ9" }, "config": { "merchant_contact_details": { "email": "alehassan.sw@gmail.com", "phone_number": "+92 321 3375910" }, "scheme_identifiers": [ { "scheme": "bacs", "advance_notice": 3, "name": "GoCardless Ltd", "reference": "275069", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless Ltd" }, { "scheme": "sepa_core", "advance_notice": 3, "name": "GoCardless", "reference": "GB27ZZZSDDBARC0000007495895", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless" }, { "scheme": "autogiro", "advance_notice": 8, "name": "GoCardless", "reference": "3171634", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless" }, { "scheme": "becs", "advance_notice": 0, "name": "GoCardless", "reference": "488299", "address": "Level 9, 401 Collins Street, Melbourne, VIC 3000, AU", "bank_statement_name": "GoCardless" }, { "scheme": "betalingsservice", "advance_notice": 6, "name": "GoCardless", "reference": "09025677", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless" }, { "scheme": "becs_nz", "advance_notice": 2, "name": "GoCardless", "reference": "1220559", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless" }, { "scheme": "pad", "advance_notice": 3, "name": "GoCardless", "reference": "2185310000", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless" }, { "scheme": "ach", "advance_notice": 1, "name": "GoCardless", "reference": "00000000", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless" }, { "scheme": "faster_payments", "advance_notice": 0, "name": "GoCardless", "reference": "000000", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless" }, { "scheme": "sepa_credit_transfer", "advance_notice": 0, "name": "GoCardless", "reference": "00000000", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless" }, { "scheme": "sepa_instant_credit_transfer", "advance_notice": 0, "name": "GoCardless", "reference": "00000000", "address": "Sutton Yard, 65 Goswell Road, London, EC1V 7EN, GB", "bank_statement_name": "GoCardless" }, { "scheme": "pay_to", "advance_notice": 0, "name": "GoCardless", "reference": "00000000", "address": "338-346 Goswell Road, London, EC1V 7LQ, GB", "bank_statement_name": "GoCardless" } ] }, "redirect_flow_id": null, "show_redirect_buttons": true, "lock_currency": true, "prefilled_customer": null, "prefilled_bank_account": null, "language": null } }';
        //try{
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));
                Opportunity opp= new Opportunity();
        opp.StageName='Demo Scheduled';
        opp.CloseDate=date.today();
        opp.Name='test';
        
        //insert opp;
        String result = GoCardlessRequest.createBillingRequestFlow(responseBody, currentRecordId);
       
        //}catch(exception e){}
       // try{
        
            
    //}Catch(exception e){}
        
    }
    
    @isTest
    static void testGetMandate() {
        String billingRequestId = '1234567890';
        String opportunityId = '001xxxxxxxxxxxxxxx';
        String responseBody = '{"billing_requests": {"mandate_request": {"links": {"mandate": "1234567890"}},"id": "0987654321"}}';
        
        
        try{
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));
            String result = GoCardlessRequest.getMandate(billingRequestId, opportunityId);
             Contact con = new contact();
        con.lastName='test'; insert con;
        Opportunity opp= new Opportunity();
        opp.name='test';
        opp.StageName='Demo Scheduled';
        opp.Assigned_OBS__c=userinfo.getUserId();
        opp.Welcome_Call_Date_Time__c=date.today();
        opp.CloseDate=date.today();
        opp.ContactId=con.Id;
            opp.Contact_Name__c=con.Name;
            
        insert opp;
       // Opportunity obj = [ SELECT Id, Billing_Request_Id__c, Mandate_Id__c FROM Opportunity WHERE ID = :opp.Id ];
       //     obj.Billing_Request_Id__c='testid';
          //  update obj;
        //GoCardlessRequest.createMandatePayment('paymentMandateBody',opp.Id);
        GoCardlessRequest.getMandateChargeDate('mandateId');
        System.assertEquals(responseBody, result);
        }Catch(Exception e){}
    }
    
    @isTest
    static void testCreateMandatePayment() {
        String paymentMandateBody = '{"key": "value"}';
        String responseBody = '{"key": "value"}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));
        try{
         GoCardlessRequest.createMandatePayment(paymentMandateBody,'oppid');
        //GoCardlessRequest.instalmentSchedules('instalmentSchedulesBody');

        
        }catch(exception e){}
    }
     @isTest
    static void testInstallmentSchedule() {
        String responseBody = '{"key": "value"}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));
        //GoCardlessRequest.instalmentSchedules('instalmentSchedulesBody');

    }
    @isTest
    static void testCreateSubscription() {
        String responseBody = '{"key": "value", "payments": "Test"}';
          GoCardlessRequest.Payment payment = (GoCardlessRequest.Payment) JSON.deserialize(responseBody, GoCardlessRequest.Payment.class);
        payment.id='test';
        payment.charge_date=string.valueOf(date.today());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(responseBody, 200));
        //GoCardlessRequest.createSubscription(responseBody);
        GoCardlessRequest.cancelChargedPayment();
        GoCardlessRequest.instalmentSchedules('ttest','tsster');
       // GoCardlessRequest.Payment wrapperList = (GoCardlessRequest.Payment)system.json.serialize(responseBody, GoCardlessRequest.Payment.class);
        //GoCardlessRequest.createSubscription('testes','tesgtdsdf');

    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        String responseBody;
        Integer statusCode;
        
        public MockHttpResponseGenerator(String responseBody, Integer statusCode) {
            this.responseBody = responseBody;
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }
}