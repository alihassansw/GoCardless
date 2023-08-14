/*
********************************************************
@Method Name    : GoCardlessRequest
@written by     : Ali Hassan
@description    : Methods to hit APIs to GoCardless
@param          :
@return         : Output
********************************************************
*/

public with sharing class GoCardlessRequest {
  /******************************   AccessTokken From GoCardless    ******************************/

  private static final String ACCESS_TOKEN = 'x.xxxxxxxxxxxxxxxxxxxxxxxyyyyyyyyyzzzzzzzzzz';
  private static final String BASE_URL = 'https://api-sandbox.gocardless.com';
  private static final String VERSION = '2015-07-06';

  /******************************   Create Mandate Methods    ******************************/

  //Create Billing Request
  @AuraEnabled
  public static String createMandate(String createMandateBody) {
    // Construct the REST API endpoint URL
    String endpoint = BASE_URL + '/billing_requests';

    // Send HTTP request
    HttpResponse res = callAPI('POST', endpoint, createMandateBody, null);

    //Get The Response Body
    return res.getBody();
  }

  //Create Billing Request flow
  @AuraEnabled
  public static String createBillingRequestFlow(String createMandateBodyFlow, String currentRecordId) {
    // Construct the REST API endpoint URL
    String endpoint = BASE_URL + '/billing_request_flows';

    // Send HTTP request
    HttpResponse res = callAPI('POST', endpoint, createMandateBodyFlow, null);

    // If the Api Succeeds
    if (res.getStatusCode() == 200) {
      //Extracting the Billing Id from the response
      Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
      String billingRequest = (String) ((Map<String, Object>) ((Map<String, Object>) jsonMap.get(
            'billing_request_flows'
          ))
          .get('links'))
        .get('billing_request');

      //Get the Active Record from Opportunity
      Opportunity obj = [
        SELECT Id, Billing_Request_Id__c, Mandate_Id__c
        FROM Opportunity
        WHERE ID = :currentRecordId
      ];

      //Set the Billing Request into the field
      obj.Billing_Request_Id__c = billingRequest;
      update obj;
    }
    //Get The Response Body
    return res.getBody();
  }

  //Get Mandate Id using Billing Request Id
  @AuraEnabled
  public static String getMandate(String billingRequestId, String opportunityId) {
    // Construct the REST API endpoint URL
    String endpoint = BASE_URL + '/billing_requests/' + billingRequestId;

    // Send HTTP request
    HttpResponse res = callAPI('GET', endpoint, null, null);

    try {
      //If the Status Code is 200 (returns Success)
      if (res.getStatusCode() == 200) {
        Map<String, Object> newMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> billingRequests = (Map<String, Object>) newMap.get('billing_requests');
        Map<String, Object> mandateRequest = (Map<String, Object>) billingRequests.get('mandate_request');
        Map<String, Object> links = (Map<String, Object>) mandateRequest.get('links');
        String mandate = (String) links.get('mandate');
        String billingId = (String) billingRequests.get('id');

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<Contact> contactsToUpdate = new List<Contact>();

        // Query Opportunities and related Contacts
        List<Opportunity> opportunities = [
          SELECT Id, Mandate_Id__c, Contact_Name__c, Contact_Name__r.Mandate_Id__c
          FROM Opportunity
          WHERE Id = :opportunityId
        ];

        // Loop through Opportunities and update records
        for (Opportunity opp : opportunities) {
          if (opp.Contact_Name__c != null) {
            opp.Contact_Name__r.Mandate_Id__c = mandate;
            contactsToUpdate.add(opp.Contact_Name__r);
          }
          opp.Mandate_Id__c = mandate;
          opportunitiesToUpdate.add(opp);
        }

        // Update Opportunities and related Contacts
        if (!opportunitiesToUpdate.isEmpty()) {
          update opportunitiesToUpdate;
        }
        if (!contactsToUpdate.isEmpty()) {
          update contactsToUpdate;
        }
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    //Get the Response
    return res.getBody();
  }

  //Get Mandate Next Possible Charge Date using Mandate Id
  @AuraEnabled
  public static String getMandateChargeDate(String mandateId) {
    // Construct the REST API endpoint URL
    String endpoint = BASE_URL + '/mandates/' + mandateId;

    // Send HTTP request
    HttpResponse res = callAPI('GET', endpoint, null, null);

    //Get the Response
    return res.getBody();
  }

  /******************************   Charging Direct Payment To Mandate    ******************************/

  //Charge Payment to Mandate
  @AuraEnabled
  public static String createMandatePayment(String paymentMandateBody, String oppId) {
    // Construct the REST API endpoint URL
    String endpoint = BASE_URL + '/payments';

    // Send HTTP request
    HttpResponse res = callAPI('POST', endpoint, paymentMandateBody, null);

    String jsonString = res.getBody();
    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

    Payment payment = (Payment) JSON.deserialize(JSON.serialize(jsonMap.get('payments')), Payment.class);

    if (res.getStatusCode() == 201) {
      //Extracting the Currency in the response
      Map<String, Object> paymentMap = (Map<String, Object>) jsonMap.get('payments');
      String paymentCurrency = (String) paymentMap.get('currency');

      //Setting to variables
      String id = payment.id;
      DateTime createdAt = payment.created_at;
      String chargeDate = payment.charge_date;
      String amount = payment.amount;
      String description = payment.description;
      // String paymentCurrency = payment.currency_code;
      String status = payment.status;
      Integer amountRefunded = payment.amount_refunded;
      String reference = payment.reference;
      Map<String, Object> metadata = payment.metadata;
      PaymentFX fx = payment.fx;
      PaymentLinks links = payment.links;
      Boolean retryIfPossible = payment.retry_if_possible;

      // Access nested fields using dot notation
      String fxCurrency = fx.fx_currency;
      Integer fxAmount = fx.fx_amount;
      Decimal exchangeRate = fx.exchange_rate;
      String estimatedExchangeRate = fx.estimated_exchange_rate;

      String mandate = links.mandate;
      String creditor = links.creditor;

      List<GoCardless_Order__c> objsToInsert = new List<GoCardless_Order__c>();
      // Query Opportunities and related Contacts
      List<Opportunity> opportunities = [
        SELECT Id, AccountId, Contact_Name__c, Mandate_Id__c
        FROM Opportunity
        WHERE Id = :oppId
      ];

      String paymentName = null;

      // Iterate over the keys in the JSON string
      for (String key : jsonMap.keySet()) {
        // Check if the value associated with this key is the instalment_schedules object
        if (
          jsonMap.get(key) instanceof Map<String, Object> && ((Map<String, Object>) jsonMap.get(key)).containsKey('id')
        ) {
          paymentName = key.replaceAll('_', ' ').capitalize();
          List<String> paymentNameParts = paymentName.split(' ');
          if (paymentNameParts.size() == 1) {
            paymentName = paymentName.capitalize();
          }
          for (Opportunity opp : opportunities) {
            GoCardless_Order__c obj = new GoCardless_Order__c();
            obj.Name = paymentName;
            obj.Order_Description__c = description;
            obj.Id__c = id;
            obj.Created_at__c = Datetime.valueOf(createdAt);
            obj.Total_amount__c = Decimal.valueOf(amount.Substring(0, amount.length() - 2));
            obj.Currency__c = paymentCurrency;
            obj.Status__c = status;
            obj.Mandate_Id__c = opp.Mandate_Id__c;
            obj.Reference__c = reference;
            obj.LookupOpportunity__c = opp.Id;
            obj.LookupAccount__c = opp.AccountId;
            obj.LookupContact__c = opp.Contact_Name__c;
            objsToInsert.add(obj);
          }
        }
      }
      //Insert the List to the Object
      insert objsToInsert;
    }

    //Get The Response Body
    return res.getBody();
  }

  /******************************   Create Instalment Schedule To Mandate    ******************************/

  //Create instalment Schedules to Mandate
  @AuraEnabled
  public static String instalmentSchedules(String instalmentSchedulesBody, String oppId) {
    // Construct the REST API endpoint URL
    String endpoint = BASE_URL + '/instalment_schedules';

    // Construct the REST API endpoint URL
    HttpResponse res = callAPI('POST', endpoint, instalmentSchedulesBody, null);

    //Get The Response Body
    return res.getBody();
  }

  //Get Instalment Schedule Status
  @AuraEnabled
  public static String getInstalmentSchedules(String instalmentScheduleId, String oppId) {
    // Construct the REST API endpoint URL
    String endpoint = BASE_URL + '/instalment_schedules/' + instalmentScheduleId;

    // Construct the REST API endpoint URL
    HttpResponse res = callAPI('GET', endpoint, null, null);

    String responseFromApi = res.getBody();
    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseFromApi);

    InstalmentSchedules InstalmentSchedules = (InstalmentSchedules) JSON.deserialize(
      JSON.serialize(jsonMap.get('instalment_schedules')),
      InstalmentSchedules.class
    );

    if (res.getStatusCode() == 200) {
      List<GoCardless_Order__c> objsToInsert = new List<GoCardless_Order__c>();
      // Query Opportunities and related Contacts
      List<Opportunity> opportunities = [
        SELECT Id, AccountId, Contact_Name__c, Mandate_Id__c
        FROM Opportunity
        WHERE Id = :oppId
      ];

      String paymentName = null;

      // Iterate over the keys in the JSON string
      for (String key : jsonMap.keySet()) {
        //Extracting the Currency in the response
        Map<String, Object> installmentMap = (Map<String, Object>) jsonMap.get('instalment_schedules');
        String installmentCurrency = (String) installmentMap.get('currency');

        //Extracting Values
        String id = InstalmentSchedules.id;
        DateTime createdAt = InstalmentSchedules.created_at;
        String totalAmount = InstalmentSchedules.total_amount;
        String instalment_currency = InstalmentSchedules.instalment_currency;
        String status = InstalmentSchedules.status;
        String name = InstalmentSchedules.name;
        Map<String, Object> metadata = InstalmentSchedules.metadata;
        Map<String, Object> payment_errors = InstalmentSchedules.payment_errors;
        InstallmentLinks links = InstalmentSchedules.links;
        String mandate = links.mandate;
        String customer = links.customer;
        // Check if the value associated with this key is the instalment_schedules object
        if (
          jsonMap.get(key) instanceof Map<String, Object> && ((Map<String, Object>) jsonMap.get(key)).containsKey('id')
        ) {
          paymentName = key.replaceAll('_', ' ').capitalize();
          List<String> paymentNameParts = paymentName.split(' ');
          if (paymentNameParts.size() == 1) {
            paymentName = paymentName.capitalize();
          }
          for (Opportunity opp : opportunities) {
            GoCardless_Order__c obj = new GoCardless_Order__c();
            obj.Name = paymentName;
            obj.Order_Description__c = name;
            obj.Id__c = id;
            obj.Created_at__c = Datetime.valueOf(createdAt);
            obj.Total_amount__c = Decimal.valueOf(totalAmount.Substring(0, totalAmount.length() - 2));
            obj.Currency__c = installmentCurrency;
            obj.Status__c = status;
            obj.Mandate_Id__c = opp.Mandate_Id__c;
            obj.Customer_Id__c = customer;
            obj.LookupOpportunity__c = opp.Id;
            obj.LookupAccount__c = opp.AccountId;
            obj.LookupContact__c = opp.Contact_Name__c;
            objsToInsert.add(obj);
          }
        }
      }
      //Insert the List to the Object
      insert objsToInsert;
    }

    //Get The Response Body
    return res.getBody();
  }

  /******************************   Create Subscription To Mandate    ******************************/

  //Create Subscription to Mandate
  @AuraEnabled
  public static String createSubscription(String createSubscriptionBody, String oppId) {
    // Construct the REST API endpoint URL
    String endpoint = BASE_URL + '/subscriptions';

    // Construct the REST API endpoint URL
    HttpResponse res = callAPI('POST', endpoint, createSubscriptionBody, null);

    String responseString = res.getBody();
    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseString);

    Subscriptions Subscriptions = (Subscriptions) JSON.deserialize(
      JSON.serialize(jsonMap.get('subscriptions')),
      Subscriptions.class
    );

    if (res.getStatusCode() == 201) {
      String id = Subscriptions.id;
      DateTime createdAt = Subscriptions.created_at;
      String amount = Subscriptions.amount;
      // String paymentCurrency = Subscriptions.instalment_currency;
      String name = Subscriptions.name;
      String status = Subscriptions.status;
      Date startDate = Subscriptions.start_date;
      Date endDate = Subscriptions.end_date;
      String interval = Subscriptions.interval;
      String interval_unit = Subscriptions.interval_unit;
      Integer day_of_month = Subscriptions.day_of_month;
      String count = Subscriptions.count;
      Map<String, Object> metadata = Subscriptions.metadata;
      Boolean payment_reference = Subscriptions.payment_reference;
      SubscriptionLinks links = Subscriptions.links;
      String mandate = links.mandate;
      List<UpcomingPayment> upcoming_payments = Subscriptions.upcoming_payments;

      //Extracting the Currency in the response
      Map<String, Object> SubscriptionMap = (Map<String, Object>) jsonMap.get('subscriptions');
      String SubscriptionCurrency = (String) SubscriptionMap.get('currency');

      List<GoCardless_Order__c> objsToInsert = new List<GoCardless_Order__c>();
      List<Opportunity> objForOpportunity = new List<Opportunity>();
      List<AcctSeed__Recurring_Billing__c> billingsToInsert = new List<AcctSeed__Recurring_Billing__c>();
      // Query Opportunities and related Contacts
      List<Opportunity> opportunities = [
        SELECT
          Id,
          Account.AcctSeed__Accounting_Type__c,
          AccountId,
          Contact_Name__c,
          Mandate_Id__c,
          Billing_Created__c,
          Contract_Duration__c,
          Billing_Frequency__c
        FROM Opportunity
        WHERE Id = :oppId
      ];

      String paymentName = null;

      // Iterate over the keys in the JSON string
      for (String key : jsonMap.keySet()) {
        // Check if the value associated with this key is the instalment_schedules object
        if (
          jsonMap.get(key) instanceof Map<String, Object> && ((Map<String, Object>) jsonMap.get(key)).containsKey('id')
        ) {
          paymentName = key.replaceAll('_', ' ').capitalize();
          List<String> paymentNameParts = paymentName.split(' ');
          if (paymentNameParts.size() == 1) {
            paymentName = paymentName.capitalize();
          }
          for (Opportunity opp : opportunities) {
            GoCardless_Order__c obj = new GoCardless_Order__c();
            obj.Name = paymentName;
            obj.Order_Description__c = name;
            obj.Id__c = id;
            obj.Created_at__c = Datetime.valueOf(createdAt);
            obj.Total_amount__c = Decimal.valueOf(amount.Substring(0, amount.length() - 2));
            obj.Currency__c = SubscriptionCurrency;
            obj.Status__c = status;
            obj.Day_of_month__c = day_of_month;
            obj.End_date__c = endDate;
            obj.Count__c = count == null ? 'Not Specified' : String.valueOf(count);
            obj.Interval__c = interval;
            obj.Mandate_Id__c = opp.Mandate_Id__c;
            obj.Interval_unit__c = interval_unit;
            obj.LookupOpportunity__c = opp.Id;
            obj.LookupAccount__c = opp.AccountId;
            obj.LookupContact__c = opp.Contact_Name__c;

            // Get the object metadata for the Account object
            Schema.DescribeSObjectResult describeResult = Opportunity.SObjectType.getDescribe();

            // Check if the field "Custom_Field__c" exists in the metadata
            if (
              describeResult.fields.getMap().containsKey('Billing_Created__c') &&
              describeResult.fields.getMap().containsKey('Contract_Duration__c') &&
              describeResult.fields.getMap().containsKey('Billing_Frequency__c')
            ) {
              opp.Billing_Created__c = true;

              Map<String, String> durations = new Map<String, String>{
                '1monthly' => 'Monthly',
                '1yearly' => 'Annual',
                '3monthly' => 'Quarterly',
                '6monthly' => 'Semi-Annual',
                '2yearly' => 'Biennial',
                '3yearly' => '3 Year',
                '4yearly' => '4 Year',
                '5yearly' => '5 Year',
                '6yearly' => '6 Year',
                '7yearly' => '7 Year',
                '8yearly' => '8 Year',
                '9yearly' => '9 Year',
                '10yearly' => '10 Year'
              };

              String durationKey = interval + interval_unit;
              if (durations.containsKey(durationKey)) {
                String durationValue = durations.get(durationKey);
                // opp.Contract_Duration__c = durationValue;
                opp.Billing_Frequency__c = durationValue;
              }
            }

            objsToInsert.add(obj);
            objForOpportunity.add(opp);
          }

          if (!objForOpportunity.isEmpty()) {
            //Insert the List to the Object
            update objForOpportunity;
          }

          //Query the record of AcctSeed__Recurring_Billing__c to get the newly made record
          List<AcctSeed__Recurring_Billing__c> recurringBillings = [
            SELECT
              Id,
              Mandate_Id__c,
              Subscription_id__c,
              Created_at__c,
              Subscription_amount__c,
              GoCardless_Status__c,
              Day_of_month__c,
              Count__c,
              Subscription_description__c,
              Subscription_Start_Date__c,
              Subscription_End_Date__c
            FROM AcctSeed__Recurring_Billing__c
            WHERE AcctSeed__Opportunity__c = :oppId
          ];

          for (AcctSeed__Recurring_Billing__c billings : recurringBillings) {
            //Inserting in AcctSeed__Recurring_Billing__c Object
            billings.Subscription_id__c = id;
            billings.Mandate_Id__c = mandate;
            billings.Subscription_description__c = name;
            billings.Created_at__c = Datetime.valueOf(createdAt);
            billings.Subscription_amount__c = Decimal.valueOf(amount.Substring(0, amount.length() - 2));
            billings.GoCardless_Status__c = status;
            billings.Day_of_month__c = Decimal.valueOf(day_of_month);
            billings.Count__c = (count == null) ? 'Not Specified' : count;
            billings.Subscription_Start_Date__c = startDate;
            billings.Subscription_End_Date__c = endDate;
            // // order.AcctSeed__Last_Billing_Date__c = ;
            // // order.AcctSeed__Next_Billing_Date__c = ;

            //Add the data to the List(billingsToInsert) : AcctSeed__Recurring_Billing__c Object
            billingsToInsert.add(billings);
          }
        }
      }

      if (!objsToInsert.isEmpty()) {
        //Insert the List to the Object
        insert objsToInsert;
      }

      if (!billingsToInsert.isEmpty()) {
        //Insert the List to the Object
        update billingsToInsert;
      }
    }

    //Get The Response Body
    return res.getBody();
  }

  /******************************   Cancel Any Payment to Mandate    ******************************/

  //Cancel Any Payment to Mandate
  @AuraEnabled
  public static String cancelChargedPayment(String specificId, String pageId) {
    //Check Endpoint based on Specific Id
    Map<String, String> endpointMap = new Map<String, String>{
      'PM' => 'payments',
      'IS' => 'instalment_schedules',
      'SB' => 'subscriptions'
    };

    //Get Endpoint
    String finalEndpoint = endpointMap.get(specificId.substring(0, 2));

    if (finalEndpoint == null) {
      System.debug('Invalid Enpoint Variable');
      return null;
    }

    // Construct the REST API endpoint URL
    String endpoint = BASE_URL + '/' + finalEndpoint + '/' + specificId + '/actions/cancel';

    // Send HTTP request
    HttpResponse res = callAPI('POST', endpoint, '{}', null);

    try {
      if (res.getStatusCode() == 200 && res.getBody().contains('cancelled')) {
        List<GoCardless_Order__c> GCRecordList = [
          SELECT Id, Id__c, Status__c
          FROM GoCardless_Order__c
          WHERE Id__c = :specificId
        ];
        List<AcctSeed__Recurring_Billing__c> recurringRecordList = [
          SELECT Id, GoCardless_Status__c
          FROM AcctSeed__Recurring_Billing__c
          WHERE Id = :pageId
        ];
        List<GoCardless_Order__c> GCrecordsToUpdate = new List<GoCardless_Order__c>();
        List<AcctSeed__Recurring_Billing__c> recurringRecordsToUpdate = new List<AcctSeed__Recurring_Billing__c>();

        for (GoCardless_Order__c i : GCRecordList) {
          i.Status__c = 'cancelled__c';
          GCrecordsToUpdate.add(i);
        }
        for (AcctSeed__Recurring_Billing__c i : recurringRecordList) {
          i.GoCardless_Status__c = 'cancelled';
          recurringRecordsToUpdate.add(i);
        }
        System.debug('recurringRecordsToUpdate' + recurringRecordsToUpdate); 
        System.debug('GCrecordsToUpdate' + GCrecordsToUpdate); 

        if (!GCrecordsToUpdate.isEmpty()) {
          update GCrecordsToUpdate;
        }
        if (!recurringRecordsToUpdate.isEmpty()) {
          update recurringRecordsToUpdate;
        }
      }
    } catch (Exception e) {
      System.debug('Error: ' + e);
    }
    return res.getBody();
  }

  /******************************   Get Data from Salesforce    ******************************/

  //Get Billing request Id and Mandate Id
  @AuraEnabled
  public static List<Opportunity> getBillingRequestId(String pageId) {
    List<Opportunity> billingRequestIdOnLoad = new List<Opportunity>();
    try {
      billingRequestIdOnLoad = [
        SELECT Id, Billing_Request_Id__c, Mandate_Id__c
        FROM Opportunity
        WHERE ID = :pageId
        LIMIT 1
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return billingRequestIdOnLoad;
  }

  //Get Payment Id from GoCardless Orders Object
  @AuraEnabled
  public static List<sObject> getSpecificId(String objectName, String pageId, List<String> fieldApiNames) {
    List<sObject> specificId = new List<sObject>();
    String x = String.join(fieldApiNames, ',');
    try {
      String query =
        'SELECT ' +
        String.join(fieldApiNames, ',') +
        ' FROM ' +
        objectName +
        ' WHERE Id = :pageId LIMIT 1';
      System.debug('query: ' + query);
      specificId = Database.query(query);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return specificId;
  }

  /******************************   Method to hit Api    ******************************/

  public static HttpResponse callAPI(String method, String endpoint, String requestBody, String contentLength) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod(method);
    req.setHeader('GoCardless-Version', VERSION);
    req.setHeader('Authorization', 'Bearer ' + ACCESS_TOKEN);
    req.setHeader('Accept', 'application/json');
    req.setHeader('Content-Type', 'application/json');
    if (requestBody != null) {
      req.setBody(requestBody);
    }
    if (contentLength != null) {
      req.setHeader('Content-Length', String.valueOf(requestBody.length()));
    }
    Http http = new Http();
    HttpResponse res = http.send(req);
    return res;
  }

  /******************************   Wrapper Classes for Api Responses    ******************************/

  //Wrapper Class for createMandatePayment response
  public class Payment {
    public String id;
    public DateTime created_at;
    public String charge_date;
    public String amount;
    public String description;
    public String currency_code;
    public String status;
    public Integer amount_refunded;
    public String reference;
    public Map<String, Object> metadata;
    public PaymentFX fx;
    public PaymentLinks links;
    public Boolean retry_if_possible;
  }
  public class PaymentFX {
    public String fx_currency;
    public Integer fx_amount;
    public Decimal exchange_rate;
    public String estimated_exchange_rate;
  }
  public class PaymentLinks {
    public String mandate;
    public String creditor;
  }

  //Wrapper Class for instalmentSchedules response
  public class InstalmentSchedules {
    public String id;
    public Datetime created_at;
    public String total_amount;
    public String instalment_currency;
    public String status;
    public String name;
    public Map<String, Object> metadata;
    public Map<String, Object> payment_errors;
    public InstallmentLinks links;
  }
  public class InstallmentLinks {
    public String mandate;
    public String customer;
    public List<String> paymments;
  }

  //Wrapper Class for createSubscription response
  public class Subscriptions {
    public String id;
    public Datetime created_at;
    public String amount;
    public String instalment_currency;
    public String status;
    public String name;
    public Date start_date;
    public Date end_date;
    public String interval;
    public String interval_unit;
    public Integer day_of_month;
    public String count;
    public Map<String, Object> metadata;
    public Boolean payment_reference;
    public SubscriptionLinks links;
    public List<UpcomingPayment> upcoming_payments;
  }
  public class SubscriptionLinks {
    public String mandate;
  }
  public class UpcomingPayment {
    public Date charge_date;
    public Decimal amount;
  }
}
