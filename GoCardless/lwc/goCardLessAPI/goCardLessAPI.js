import { LightningElement, track, api } from "lwc";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createMandate from "@salesforce/apex/GoCardlessRequest.createMandate";
import createBillingRequestFlow from "@salesforce/apex/GoCardlessRequest.createBillingRequestFlow";
import getMandate from "@salesforce/apex/GoCardlessRequest.getMandate";
import getBillingRequestId from "@salesforce/apex/GoCardlessRequest.getBillingRequestId";

export default class GoCardLessAPI extends LightningElement {
  //Variables
  @track currency = "USD";
  @track billingRequestId;
  @track mandateUrl;
  @track mandate;
  @track mandateId;
  @track customer;
  @track email;
  @track id;
  @track loaded = false;
  @track billingIdOnLoad;
  @track mandateIdOnLoad;
  @track hidden = true;
  @track dynamiclyHide = true;

  //Get the Current Record Id
  @api recordId;

  //Getting the option for the combobox
  get options() {
    return [
      { label: "USD", value: "USD" },
      { label: "GBP", value: "GBP" },
      { label: "AUD", value: "AUD" },
      { label: "EUR", value: "EUR" },
    ];
  }

  //Rendered Call Back
  renderedCallback() {
    //Get the Element from Html
    console.log("Rendered Call Back");
    window.onload = (event) => {
      console.log("page is fully loaded");
    };
    
  }

  //Connected Call Back
  connectedCallback() {
    //Getting the Billing Request id
    getBillingRequestId({ pageId: this.recordId })
      .then((result) => {
        console.log("result from getBillingRequestId", result);
        //Extracting the Billing Id and Mandate Id from Result
        this.billingIdOnLoad = result[0].Billing_Request_Id__c;
        this.mandateIdOnLoad = result[0].Mandate_Id__c;

        //If the Mandate Id Exists
        if (this.mandateIdOnLoad) {

          //Hide the Create Mandate Component
          this.hidden = false;
        } 
        else {

          //Show the Create Mandate Component
          this.hidden = true;
        }

        //If the Billing Id Exists
        if (this.billingIdOnLoad && !this.mandateIdOnLoad) {
          //Calling the Apex Method to get Mandate id
          this.getMandateOnLoad();
        }
      })

      .catch((error) => {
        console.error("Error:", error);

        //Show Error Toast Message
        this.toastEventFire(
          `Error Code ${error.status}`,
          `${error.statusText}`,
          "error"
        );

        //Hide the Spinner on Error
        this.loaded = false;
      });
  }

  //Get the mandate Id Onload
  getMandateOnLoad() {
    //Calling the Apex Method Imperatively to Get Mandate Details
    getMandate({
      billingRequestId: this.billingIdOnLoad,
      opportunityId: this.recordId,
    })
      .then((result) => {
        //Extracting the mandate Id from the response
        this.mandate =
          JSON.parse(result).billing_requests.mandate_request.links.mandate;

        updateRecord({ fields: { Id: this.recordId } });

        //If the Mandate Exists
        if (this.mandate) {
          //Show a toast message
          this.toastEventFire("Mandate created successfully", "", "success");

          //Hide the Create Mandate component
          this.hidden = false;
        } else {
          //Show a Toast Message
          this.toastEventFire("Not a Mandate", "", "info");
        }
      })

      .catch((error) => {
        console.log(error);

        //Show a Toast Message of Error
        this.toastEventFire(
          `Error Code ${error.status}`,
          `${error.statusText}`,
          "error"
        );

        //Hide the Spinner on Error
        this.loaded = false;
      });
  }

  //Get the Currency Selected By the User
  handleCurrency(event) {
    this.currency = event.detail.value;
    console.log("this.currency:", this.currency);
  }

  //Create Mandate OnClick
  handleCreateMandate() {
    //Show the spinner OnClick
    this.loaded = true;

    //JSON Body to Send
    const JSONBody = JSON.stringify({
      billing_requests: {
        mandate_request: {
          currency: this.currency,
          verify: "minimum",
          metadata: {
            key: "value",
          },
        },
      },
    });

    //Calling the Apex Method Imperatively to Create Mandate
    createMandate({ createMandateBody: JSONBody })
      .then((result) => {
        //Getting the Billing request Id from Response
        this.billingRequestId = JSON.parse(result).billing_requests.id;

        //Show a toast message of redirecting you to a secure page
        this.toastEventFire("Redirecting you to a secure page", "", "info");

        //If the Billing Id Exists call the handleCreateMandateFollow() method
        if (this.billingRequestId) {
          console.log("Calling Next Method");

          //Call the Method
          this.handleCreateMandateFollow();
        } else {
          //Show a Toast Message of Connot make a Billing Request
          this.toastEventFire("Cannot make a Billing request", "", "error");

          //Hide the Spinner on Error
          this.loaded = false;
        }
      })

      .catch((error) => {
        console.error("Error:", error);

        //Show a toast message to show Error
        this.toastEventFire(
          `Error Code ${error.status}`,
          `${error.statusText}`,
          "error"
        );

        //Hide the Spinner on Error
        this.loaded = false;
      });
  }

  //Create a billing Request Flow
  handleCreateMandateFollow() {
    //Json Body to Send
    const JSONBody = JSON.stringify({
      billing_request_flows: {
        auto_fulfil: true,
        lock_currency: true,
        lock_bank_account: false,
        lock_customer_details: false,
        redirect_uri: `https://deardoc--aasiadev.sandbox.lightning.force.com/lightning/r/Opportunity/${this.recordId}/view`,
        show_redirect_buttons: true,
        exit_uri: "https://developer.gocardless.com/",
        links: {
          billing_request: this.billingRequestId,
        },
      },
    });

    //Calling Apex Method
    createBillingRequestFlow({
      createMandateBodyFlow: JSONBody,
      currentRecordId: this.recordId,
    })
      .then((result) => {
        //Extract the Url from Response Body
        if (JSON.parse(result).billing_request_flows.authorisation_url) {
          
          //Open New Window
          window.open(JSON.parse(result).billing_request_flows.authorisation_url); 

          //Hide the Spinner
          this.loaded = false;
        }
        else {
          //Show a Toaast Message of Error
          this.toastEventFire(
            `${JSON.parse(result).error.message}`,
            `${JSON.parse(result).error.errors[0].reason}`,
            "error"
          );

          console.log("No Url Found");
        }
      })

      .catch((error) => {
        console.error("Error:", error);

        //Show a Toast Message of Error
        this.toastEventFire(
          `Error Code ${error.status}`,
          `${error.statusText}`,
          "error"
        );

        //Hide the Spinner on Error
        this.loaded = false;
      });
  }

  //Show toast Method
  toastEventFire(title, msg, variant) {
    const e = new ShowToastEvent({
      title: title,
      message: msg,
      variant: variant,
    });
    this.dispatchEvent(e);
  }
}