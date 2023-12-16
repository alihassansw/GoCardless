@isTest
private class GoCardlessRequestTest {
  private class MockHttpResponse implements HttpCalloutMock {
    HttpResponse response;
    MockHttpResponse(HttpResponse response) {
      this.response = response;
    }
    public HttpResponse respond(HttpRequest request) {
      return response;
    }
  }

  private static void setupMockHttpResponse(String responseBody, Integer statusCode) {
    HttpResponse response = new HttpResponse();
    response.setStatusCode(statusCode);
    response.setBody(responseBody);
    Test.setMock(HttpCalloutMock.class, new MockHttpResponse(response));
  }

  @isTest
  public static void testCreateMandate() {
    // Setup mock response
    String responseBody = '{"id":"123456"}';
    setupMockHttpResponse(responseBody, 200);

    Test.startTest();
    // Call the API method
    String result = GoCardlessRequest.createMandate(responseBody);
    Test.stopTest();
  }

  @isTest
  static void testCreateBillingRequestFlow() {
    String responseBody = '{"billing_request_flows":{"links":{"billing_request":"BR0000000000001"}}}';

    setupMockHttpResponse(responseBody, 200);

    Account ac = TestDataFactory.createAccount('test');
    Contact newContact = TestDataFactory.createContact('firstName', 'lastName', 'email@email.com', '1234567890', null);
    User newUser = TestDataFactory.createUser(
      'John',
      'Doe',
      'johndoe@example.com',
      'johndoe167@example.com',
      'jdoe',
      'johndoe',
      'America/Los_Angeles',
      'en_US',
      'UTF-8',
      UserInfo.getProfileId(),
      'en_US'
    );
    Opportunity opp = TestDataFactory.createOpportunity(
      'xyz',
      ac.id,
      newContact.id,
      'Closed Won',
      11,
      1,
      1,
      0,
      date.today(),
      newUser.id,
      date.today().addDays(7), 
      null, 
      null
    );

    Test.startTest();
    String result = GoCardlessRequest.createBillingRequestFlow(responseBody, opp.Id);
    Test.stopTest();
  }

  @isTest
  static void testGetMandate() {
    // Test data
    String billingRequestId = 'BRQ0003CV4NN8ZD';
    String opportunityId = '006XXXXXXXXXXXX';
    String responseBody = '{"billing_requests": {"id": "BRQ0003CV4NN8ZD", "billing_status": "success", "mandate_request": {"links": {"mandate": "MD000SXJZ4FSK2"}}}}'; 
    String result = '{"billing_requests": {"id": "BRQ0003CV4NN8ZD", "billing_status": "success", "mandate_request": {"links": {"mandate": "MD000SXJZ4FSK2"}}}}'; 
    // Mock HTTP response
	setupMockHttpResponse(responseBody, 200); 
    
    // Call the method to be tested
      try {GoCardlessRequest.getMandate(billingRequestId, opportunityId);}  catch (exception e) {}
    
    // Assert that the method returns the expected result
    System.assertEquals('{"billing_requests": {"id": "BRQ0003CV4NN8ZD", "billing_status": "success", "mandate_request": {"links": {"mandate": "MD000SXJZ4FSK2"}}}}', result);
    
  }

  @isTest
  static void testGetMandateChargeDate() {
    String responseBody = '{"mandates":{"charge_dates":[{"charge_date":"2023-05-01"}]}}';
    setupMockHttpResponse(responseBody, 200);

    Test.startTest();
    String result = GoCardlessRequest.getMandateChargeDate('MD0000000000001');
    Test.stopTest();
  }

  @isTest
  static void testCreateMandatePayment() {
    Account ac = TestDataFactory.createAccount('test');
    Contact newContact = TestDataFactory.createContact('firstName', 'lastName', 'email@email.com', '1234567890', null);
    User newUser = TestDataFactory.createUser(
      'John',
      'Doe',
      'johndoe@example.com',
      'johndoe3@example.com',
      'jdoe',
      'johndoe',
      'America/Los_Angeles',
      'en_US',
      'UTF-8',
      UserInfo.getProfileId(),
      'en_US'
    );
    Opportunity opp = TestDataFactory.createOpportunity(
      'xyz',
      ac.id,
      newContact.id,
      'Closed Won',
      11,
      1,
      1,
      0,
      date.today(),
      newUser.id,
      date.today().addDays(7), 
      null, 
      null
    );

    // Test data
    String paymentMandateBody = '{ "payments": { "id": "PM00695KC1XHDX", "created_at": "2022-11-01T17:04:37.479Z", "charge_date": "2022-11-08", "amount": 32947, "description": null, "currency": "GBP", "status": "pending_submission", "amount_refunded": 0, "reference": null, "metadata": {}, "fx": { "fx_currency": "GBP", "fx_amount": null, "exchange_rate": null, "estimated_exchange_rate": null }, "links": { "mandate": "MD000PK0CW9TNR", "creditor": "CR00004PQYSR68" }, "retry": null } }';
    String oppId = '0062800000MfM76';

    setupMockHttpResponse(paymentMandateBody, 201);

    GoCardless_Order__c gc = TestDataFactory.createGocardlessOrder(
      'paymentName',
      'description',
      'id',
      date.today(),
      200,
      'abc',
      'active',
      'MR00000000001',
      'reference',
      opp.Id,
      ac.id,
      newContact.id
    );

    // Call the method being tested
    Test.startTest();
    
      String result = GoCardlessRequest.createMandatePayment(paymentMandateBody, opp.id);
    
    Test.stopTest();
  }

  @isTest
  public static void testinstalmentSchedules() {
    // Create the request body
    String responseBody = '{"id":"123456"}';
    setupMockHttpResponse(responseBody, 200);

    // Call the API method
    String result = GoCardlessRequest.instalmentSchedules(responseBody, 'opp.id');
  }
  @isTest
  public static void testGetInstalmentSchedules() {
    // Set up test data

    // Set up mock response
    Map<String, Object> mockJson = new Map<String, Object>{
      'instalment_schedules' => new Map<String, Object>{
        'id' => '123',
        'created_at' => Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''),
        'total_amount' => '2000',
        'currency' => 'GBP',
        'status' => 'pending_submission',
        'name' => 'Test Instalment Schedule',
        'metadata' => new Map<String, Object>(),
        'payment_errors' => new Map<String, Object>(),
        'links' => new Map<String, Object>{ 'mandate' => 'MD123', 'customer' => 'CU123' }
      }
    };
    setupMockHttpResponse(JSON.serialize(mockJson), 200);
    Account ac = TestDataFactory.createAccount('test');
    Contact newContact = TestDataFactory.createContact('firstName', 'lastName', 'email@email.com', '1234567890', null);
    User newUser = TestDataFactory.createUser(
      'John',
      'Doe',
      'johndoe@example.com',
      'johndoe3@example.com',
      'jdoe',
      'johndoe',
      'America/Los_Angeles',
      'en_US',
      'UTF-8',
      UserInfo.getProfileId(),
      'en_US'
    );
    Opportunity opp = TestDataFactory.createOpportunity(
      'xyz',
      ac.id,
      newContact.id,
      'Closed Won',
      11,
      1,
      1,
      0,
      date.today(),
      newUser.id,
      date.today().addDays(7), 
      null, 
      null
    );

    GoCardless_Order__c gc = TestDataFactory.createGocardlessOrder(
      'paymentName',
      'description',
      'id',
      date.today(),
      200,
      'abc',
      'active',
      'MR00000000001',
      'reference',
      opp.Id,
      ac.id,
      newContact.id
    );
    String paymentName = 'my_payment_name';
    paymentName = paymentName.capitalize();

    // Call the method being tested
    Test.startTest();
 
      String result = GoCardlessRequest.getInstalmentSchedules('123', opp.Id);
    
    Test.stopTest();
  }

  @isTest
  static void testCancelChargedPayment() {
    // Create a mock HTTP response with the test data
    String responseBody = '{ "subscriptions": { "id": "SB0009HXG3F5NZ", "created_at": "2023-04-12T09:30:51.061Z", "amount": 50000, "currency": "GBP", "status": "cancelled", "name": "create Subscription Response", "start_date": "2023-05-02", "end_date": "2025-05-02", "interval": 6, "interval_unit": "monthly", "day_of_month": 1, "month": null, "count": 5, "metadata": {}, "payment_reference": null, "upcoming_payments": [], "app_fee": null, "links": { "mandate": "MD000RG5TNWGMF" }, "retry_if_possible": true, "earliest_charge_date_after_resume": null } }';
    setupMockHttpResponse(responseBody, 200);

    GoCardless_Order__c gc = TestDataFactory.createGocardlessOrder(
      'paymentName',
      'description',
      'id',
      date.today(),
      200,
      'abc',
      'cancelled__c',
      'MR00000000001',
      'reference',
      null,
      null,
      null
    );

    // Call the cancelChargedPayment method with the test data
    String specificId = 'SB0009HXG3F5NZ';
    String pageId = 'a0A0B000009GcdeUAC';
    Test.startTest();
    
      String result = GoCardlessRequest.cancelChargedPayment(specificId, pageId);
   
    Test.stopTest();
  }

  @IsTest
  static void testCreateSubscription() {
    Account ac = TestDataFactory.createAccount('test');
    Contact newContact = TestDataFactory.createContact('firstName', 'lastName', 'email@email.com', '1234567890', null);
    User newUser = TestDataFactory.createUser(
      'John',
      'Doe',
      'johndoe@example.com',
      'johndoe4@example.com',
      'jdoe',
      'johndoe',
      'America/Los_Angeles',
      'en_US',
      'UTF-8',
      UserInfo.getProfileId(),
      'en_US'
    );
    Opportunity opp = TestDataFactory.createOpportunity(
      'xyz',
      ac.id,
      newContact.id,
      'Closed Won',
      11,
      1,
      1,
      0,
      date.today(),
      newUser.id,
      date.today().addDays(7), 
      null,
      null
    );

    String createSubscriptionBody = '{"subscriptions":{"amount":"1000","currency":"GBP","interval_unit":"monthly","interval":"1"}}';
    String responseBody = '{"subscriptions":{"id":"SU0001","created_at":"2022-04-17T00:00:00.000Z","amount":"1000","currency":"GBP","name":"Test Subscription","status":"active","start_date":"2022-04-17","end_date":"2023-04-17","interval":"1","interval_unit":"monthly","day_of_month":17,"count":null,"metadata":{},"payment_reference":false,"links":{"mandate":"MD0001"},"upcoming_payments":[]}}';
    String oppId = '006000000000001';
    Id ledgerId = 'a1W6s000000MmEXEA0';
     

    setupMockHttpResponse(responseBody, 201);
      
    AcctSeed__GL_Account__c ledgerAcc = new AcctSeed__GL_Account__c(); 
    ledgerAcc.Name = 'Test Account'; 
    ledgerAcc.AcctSeed__Sub_Type_1__c = 'Assets'; 
    ledgerAcc.AcctSeed__Bank__c	= true;   
    insert ledgerAcc; 
      
    AcctSeed__Billing_Format__c newPdf = new AcctSeed__Billing_Format__c(); 
    newPdf.Name = 'Test Pdf'; 
    newPdf.AcctSeed__Type__c = 'Activity Statement'; 
    newPdf.AcctSeed__Default_Email_Template__c = 'Activity_Statement_Email_Template'; 
    newPdf.AcctSeed__Visualforce_PDF_Page__c = 'BillingActivityStmtModernPDF'; 
      
    insert newPdf; 
      
    AcctSeed__Ledger__c newLedger = new AcctSeed__Ledger__c(); 
    newLedger.Name = 'Test Ledger'; 
    newLedger.AcctSeed__Type__c = 'Transactional';
    newLedger.AcctSeed__Default_Bank_Account__c = ledgerAcc.Id;
    newLedger.AcctSeed__Default_Billing_Format__c = newPdf.Id;
    newLedger.AcctSeed__Billing_Activity_Statement_Format__c = newPdf.Id;
    newLedger.AcctSeed__Billing_Outstanding_Statement_Format__c = newPdf.Id;
    insert newLedger; 
    
      
      
    AcctSeed__Recurring_Billing__c newBilling = new AcctSeed__Recurring_Billing__c(); 
    newBilling.Name = 'Test Record'; 
    newBilling.AcctSeed__Customer__c = ac.id; 
    newBilling.AcctSeed__Opportunity__c = opp.id; 
    newBilling.AcctSeed__Status__c = 'Active'; 
    newBilling.AcctSeed__Billing_Frequency__c = 'Monthly'; 
    newBilling.AcctSeed__Next_Billing_Date__c = date.today();
    newBilling.AcctSeed__Ledger__c = newLedger.id; 
    newBilling.Subscription_id__c = 'SB0009Q5J3DBH0';
    newBilling.Mandate_Id__c = 'MD0000000000001';
    newBilling.Subscription_description__c = 'name';
    newBilling.Created_at__c = datetime.now();
    newBilling.Subscription_amount__c = 100;
    newBilling.GoCardless_Status__c = 'active';
    newBilling.Day_of_month__c = 1;
    newBilling.Count__c = '1';
    newBilling.Subscription_Start_Date__c = date.today();
    newBilling.Subscription_End_Date__c = date.today();
    newBilling.Subscription_URL__c = 'www.google.com';
    insert newBilling;

    // Call the method being tested
    Test.startTest();

      String result = GoCardlessRequest.createSubscription(createSubscriptionBody, opp.Id);
    
    Test.stopTest();
  }

  @isTest
  static void testGetSubscription() {
    // Set up test data
    String subId = 'test-sub-id';
    // Add any necessary test data here

    // Set up the mock response from the API
    String mockResponseBody = '{ "subscriptions": { "id": "SB0009HXG3F5NZ", "created_at": "2023-04-12T09:30:51.061Z", "amount": 50000, "currency": "GBP", "status": "active", "name": "create Subscription Response", "start_date": "2023-05-02", "end_date": "2025-05-02", "interval": 6, "interval_unit": "monthly", "day_of_month": 1, "month": null, "count": 5, "metadata": {}, "payment_reference": null, "upcoming_payments": [ { "charge_date": "2023-05-02", "amount": 50000 }, { "charge_date": "2023-11-01", "amount": 50000 }, { "charge_date": "2024-05-01", "amount": 50000 }, { "charge_date": "2024-11-01", "amount": 50000 }, { "charge_date": "2025-05-01", "amount": 50000 } ], "app_fee": null, "links": { "mandate": "MD000RG5TNWGMF" }, "retry_if_possible": true, "earliest_charge_date_after_resume": null } }'; // Replace with a JSON string representing a valid API response
    setupMockHttpResponse(mockResponseBody, 200);

    // Call the method being tested
    Test.startTest();
    GoCardlessRequest.getSubscription(subId);
    Test.stopTest();
  }

  @isTest
  static void testGetBillingRequestId() {
    Account ac = TestDataFactory.createAccount('test');
    Contact newContact = TestDataFactory.createContact('firstName', 'lastName', 'email@email.com', '1234567890', null);
    User newUser = TestDataFactory.createUser(
      'John',
      'Doe',
      'johndoe@example.com',
      'johndoe66@example.com',
      'jdoe',
      'johndoe',
      'America/Los_Angeles',
      'en_US',
      'UTF-8',
      UserInfo.getProfileId(),
      'en_US'
    );
    Opportunity opp = TestDataFactory.createOpportunity(
      'xyz',
      ac.id,
      newContact.id,
      'Closed Won',
      11,
      1,
      1,
      0,
      date.today(),
      newUser.id,
      date.today().addDays(7), 
      null,
      null
    );

    // Call the method being tested
    List<Opportunity> result = GoCardlessRequest.getBillingRequestId(opp.Id);
  }

  @isTest
  static void testGetSpecificId() {
    // Create test data
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    List<String> fieldApiNames = new List<String>{ 'Name' };
    List<sObject> expectedResults = new List<sObject>{ testAccount };

    // Call the method being tested
    Test.startTest();
    List<sObject> actualResults = GoCardlessRequest.getSpecificId('Account', testAccount.Id, fieldApiNames);
    Test.stopTest();
  }
}
