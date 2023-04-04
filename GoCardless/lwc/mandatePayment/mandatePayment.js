import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createMandatePayment from "@salesforce/apex/GoCardlessRequest.createMandatePayment";
import getBillingRequestId from "@salesforce/apex/GoCardlessRequest.getBillingRequestId";
import getMandateChargeDate from "@salesforce/apex/GoCardlessRequest.getMandateChargeDate";

export default class MandatePayment extends LightningElement {
  @api pageId;

  //Variables for Charge Mandate
  @track dataForChargeMandate;
  @track error;
  @track todayDate;
  @track mandateIdOnLoad;
  @track billingIdOnLoad;
  @track inputAmountByUser;
  @track isShowModal = false;
  //Variables for JSON for Charge Mandate
  @track currency = "USD";
  @track customDate;
  @track mandateIdOnClickForChargeMandate;
  @track inputAmount;
  @track descriptionForChargeMandate;
  @track loaded = false;

  //Getting the option for the all Modals
  get currencyOptions() {
    return [
      { label: "USD", value: "USD" },
      { label: "GBP", value: "GBP" },
      { label: "AUD", value: "AUD" },
      { label: "EUR", value: "EUR" },
    ];
  }

  connectedCallback() {
    console.log("this.pageId: ", this.pageId);
  }

  /******************************   Charge Mandate Methods    ******************************/

  //Get the Currency Selected By the User
  handleCurrency(event) {
    //Get the Currency on Input
    this.currency = event.detail.value;
    console.log("this.currency:", this.currency);
  }

  //Get the date input
  handleDate(event) {
    //Get the date input by the User
    this.customDate = event.target.value;
    console.log("this.customDate", this.customDate);
  }

  //Get the Description
  getDescriptionForChargeMandate(event) {
    //Get the date input by the User
    this.descriptionForChargeMandate = event.target.value;
    console.log("this.customDate", this.descriptionForChargeMandate);
  }

  //Get Amount Input
  getPayment(event) {
    //Get Amount Input by the User
    this.inputAmount = event.target.value;
    console.log("inputAmount", this.inputAmount);
  }

  //Charge Payment to Mandate
  handleCreatePayment() {
    if (!this.inputAmount) {
      this.toastEventFire("Enter a Valid Amount", "", "error");
      return;
    }

    //Show the spinner OnClick
    this.loaded = true;

    //Get Mandate Id
    getBillingRequestId({ pageId: this.pageId })
      .then((result) => {
        this.mandateIdOnClickForChargeMandate = result[0].Mandate_Id__c;
        console.log("Result from Method", result);
        if (this.mandateIdOnClickForChargeMandate) {
          console.log("Firing Method 2");

          //Firing Method to make Payment
          this.createMandatePayment();
        } else {
          this.toastEventFire("Mandate Id not Found", "", "error");

          //Hide the Spinner
          this.loaded = false;
        }
      })
      .catch((error) => {
        //Show Error Toast Message
        this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");
        console.error("Error:", error);

        //Hide the spinner OnClick
        this.loaded = false;
      });
  }

  //Create Payment Method
  createMandatePayment() {
    //JSON Body to Send
    const JSONBody = JSON.stringify({
      payments: {
        amount: Number(this.inputAmount + "00"),
        currency: this.currency,
        description: this.descriptionForChargeMandate,
        //"reference": "{{$randomLoremWord}}",
        charge_date: this.customDate,
        retry_if_possible: true,
        links: {
          mandate: this.mandateIdOnClickForChargeMandate,
        },
      },
    });

    //Calling the Apex Method Imperatively
    createMandatePayment({
      paymentMandateBody: JSONBody,
      oppId: this.pageId,
    })
      .then((result) => {
        //Hide the Spinner on Method
        this.loaded = false;

        //Parsing the response to an Object
        this.dataForChargeMandate = JSON.parse(result);
        //If the Api Succeeds
        if (this.dataForChargeMandate.payments) {
          //Close Modal
          this.handleClose();

          //Show a toast meassge of Success
          this.toastEventFire(
            "Payment Charged",
            `Charge date: ${this.dataForChargeMandate.payments.charge_date}`,
            "success"
          );
          //Close the modal
          setTimeout(() => {
            this.isShowModal = false;
            this.loaded = false;
            this.getComponentName = null;
          }, 500);
        } else if (this.dataForChargeMandate.error.errors[0].field === "charge_date") {
          //Trigger Get Mandate charge date method
          this.getMandateChargeDateOnError();
        }

        //If the Api Gives an Error
        else if (
          this.dataForChargeMandate.error.errors[0].field !== "charge_date" &&
          !this.dataForChargeMandate.payments
        ) {
          //Show a Toast message of Error
          this.toastEventFire(
            "",
            `${
              this.dataForChargeMandate.error.errors[0].field
            }: ${this.dataForChargeMandate.error.errors[0].message.replace("_", " ")}`,
            "error"
          );
        }

        //If the Api Failes
        else {
          //Show a Toast message of Error
          this.toastEventFire("", "Could not send Request", "error");
        }
      })
      .catch((error) => {
        console.error("Error:", error);

        //Hide the Spinner on Method
        this.loaded = false;

        //Show a Toast Message
        this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");
      });
  }

  //Get Mandate Next Possible Charge Date
  getMandateChargeDateOnError() {
    //Show the Spinner on Method
    this.loaded = true;

    //Calling the Apex Method Imperatively
    getMandateChargeDate({ mandateId: this.mandateIdOnClickForChargeMandate })
      .then((result) => {
        const responseFromApi = JSON.parse(result);
        this.toastEventFire(
          `This Mandate's Next Possible Charge Date is ${responseFromApi.mandates.next_possible_charge_date}`,
          ``,
          `error`
        );
        this.customDate = responseFromApi.mandates.next_possible_charge_date;

        //Hide the Spinner on Method
        this.loaded = false;
      })
      .catch((error) => {
        console.error("Error:", error);
        //Show a Toast Message
        this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");

        //Hide the Spinner on Method
        this.loaded = false;
      });
  }

  //Show toast Method
  toastEventFire(title, message, variant) {
    const e = new ShowToastEvent({ title, message, variant });
    this.dispatchEvent(e);
  }

  //Hide Modal
  @api
  handleClose() {
    console.log("Working Child");
    this.dispatchEvent(new CustomEvent("closemodal"));
  }
}