# GoCardless Lightning Web Components (LWC) Components

This repository contains Lightning Web Components (LWC) that integrate with the GoCardless API to facilitate various billing and subscription management tasks within Salesforce.

## Components

### GoCardlessRequest

The `GoCardlessRequest` class provides methods to interact with the GoCardless API for creating mandates, managing payments, creating subscription schedules, and more. Here are some of the key methods available:

- `createMandate(String createMandateBody)`: Creates a new mandate for billing requests.
- `createBillingRequestFlow(String createMandateBodyFlow, String currentRecordId)`: Creates a billing request flow and associates it with an Opportunity record.
- `getDetailsForPrefill(String recordId)`: Retrieves details from an Opportunity record for prefilling.
- `getMandate(String billingRequestId, String opportunityId)`: Retrieves mandate details using a billing request ID and updates associated Opportunity records.
- `getMandateChargeDate(String mandateId)`: Retrieves the next possible charge date for a mandate.
- `createMandatePayment(String paymentMandateBody, String oppId)`: Creates a payment and associates it with a mandate and Opportunity record.
- `instalmentSchedules(String instalmentSchedulesBody, String oppId)`: Creates instalment schedules and associates them with an Opportunity record.
- `getInstalmentSchedules(String instalmentScheduleId, String oppId)`: Retrieves instalment schedule details and updates associated Opportunity records.
- `createSubscription(String createSubscriptionBody, String oppId)`: Creates a subscription and associates it with an Opportunity record.
- `getSubscription(String subId)`: Retrieves subscription details and updates associated records.
- `cancelChargedPayment(String specificId, String pageId)`: Cancels a payment, instalment schedule, or subscription and updates associated records.
- `getBillingRequestId(String pageId)`: Retrieves billing request and mandate IDs associated with an Opportunity record.
- `getSpecificId(String objectName, String pageId, List<String> fieldApiNames)`: Retrieves specific data from a Salesforce object based on provided field API names.

## How to Use

1. Clone this repository to your local development environment.
2. Deploy the `GoCardlessRequest` class to your Salesforce org.
3. Implement Lightning Web Components (LWC) using the provided methods for interacting with the GoCardless API.
4. Customize and enhance the components as needed to suit your business requirements.

## Add your access token for authorization

## Compatibility

These components are designed to work with Salesforce Lightning Experience and have been tested with Salesforce API version XX.X.

## Disclaimer

This repository and its contents are provided as-is, without warranty or support. Use at your own risk. The authors are not responsible for any data loss, damages, or issues that may arise from using these components.

