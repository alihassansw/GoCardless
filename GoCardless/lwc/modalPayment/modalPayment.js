import { LightningElement, track, api } from "lwc";
import getBillingRequestId from "@salesforce/apex/GoCardlessRequest.getBillingRequestId";

export default class ModalPayment extends LightningElement {

  //Get the Current Record Id
  @api recordId;

  //Custom Variables
  @track todayDate;
  @track loaded = false;
  @track isPayment = false;
  @track isSubscription = false;
  @track isInstallment = false;
  @track ComponentHeading;
  @track showComponent = true;
  @track mandateIdOnLoad = false;

  //Show Body of modal according to Component
  @track chargeMandateComponent = false;
  @track installmentSubscriptionComponent = false;
  @track subscriptionComponent = false;
  @track getComponentName;

  //Show Modal
  showModalBox() {
    this.isShowModal = true;
  }

  //Hide Modal
  hideModalBox() {
    this.isShowModal = false;
    this.getComponentName = null;
  }

  //Select Component Option
  get getComponents() {
    return [
      { label: "Direct Payment", value: "Direct Payment" },
      {
        label: "Create Instalment Schedules",
        value: "Create Instalment Schedules",
      },
      { label: "Create Subscription", value: "Create Subscription" },
    ];
  }

  //Connected Call Back
  connectedCallback() {
    //Get Today's Date
    this.todayDate = new Date().toISOString().slice(0, 10);

    //Getting the Billing Request id
    getBillingRequestId({ pageId: this.recordId })
      .then((result) => {
        //Extracting the Billing Id and Mandate Id from Result
        this.mandateIdOnLoad = result[0].Mandate_Id__c;

        //If the Mandate Id Exists
        if (this.mandateIdOnLoad) {
          //Show the Create Mandate Component
          this.showComponent = true;
        }
      })
      .catch((error) => {
        console.error("Error:", error);

        //Show Error Toast Message
        this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");

        //Hide the Spinner on Error
        this.loaded = false;
      });
  }

  //Show Selected Component
  getComponent(event) {
    this.getComponentName = event.target.value;
    if (this.getComponentName == "Direct Payment") {
      this.ComponentHeading = "Direct Payment ";
      this.isShowModal = true;
      this.chargeMandateComponent = true;
      this.installmentSubscriptionComponent = false;
      this.subscriptionComponent = false;
    }
    if (this.getComponentName == "Create Instalment Schedules") {
      this.ComponentHeading = "Create Instalment Schedules";
      this.isShowModal = true;
      this.installmentSubscriptionComponent = true;
      this.chargeMandateComponent = false;
      this.subscriptionComponent = false;
    }
    if (this.getComponentName == "Create Subscription") {
      this.ComponentHeading = "Create Subscription";
      this.isShowModal = true;
      this.subscriptionComponent = true;
      this.installmentSubscriptionComponent = false;
      this.chargeMandateComponent = false;
    }
  }

  //Hide Modal
  handleCloseModal() {
    console.log("Activated");
    this.isShowModal = false;
    this.loaded = false;
    this.getComponentName = null;
  }
}