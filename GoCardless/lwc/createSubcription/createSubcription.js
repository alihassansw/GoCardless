import { LightningElement, track, api, wire } from "lwc";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Contract_Duration_field from "@salesforce/schema/Opportunity.Contract_Duration__c";
import getBillingRequestId from "@salesforce/apex/GoCardlessRequest.getBillingRequestId";
import createSubscription from "@salesforce/apex/GoCardlessRequest.createSubscription";

export default class CreateSubcription extends LightningElement {
  //Calling Wire Methid
  @wire(getPicklistValues, {
    recordTypeId: "0126g0000007rswAAA",
    fieldApiName: Contract_Duration_field,
  })
  contractDurationPicklistValues({ data, error }) {
    if (data) {
      console.log('durationOptions: ', this.contractDurationPicklistValues); 
      console.log('data: ', data); 
      this.durationOptions = data.values.map((option) => ({
        label: option.label,
        value: option.value,
      }));
    } else if (error) {
      console.error(error);
    }
  }
  //Get the Current Page Id
  @api pageId;

  //Custom Variables
  @track fieldUpdate;
  @track loaded = false;
  @track selectedDuration;

  //Variables for Create Subscription
  @track createSubscriptionResponse;

  //Variables for JSON Data for Create Subscription
  @track totalAmount;
  @track currency = "USD";
  @track description;
  @track dayOfMonth;
  @track endDate;
  @track intervalUnit = "weekly";
  @track intervalForSubscription = 1;
  @track totalCount;
  @track dynamicBody;

  //Getting the option
  get currencyOptions() {
    return [
      { label: "USD", value: "USD" },
      { label: "GBP", value: "GBP" },
      { label: "AUD", value: "AUD" },
      { label: "EUR", value: "EUR" },
    ];
  }

  //Get optionsForInterval
  get billingFrequency() {
    return [
      { label: "Weekly", value: "Weekly" },
      { label: "Bi-weekly", value: "Bi-weekly" },
      { label: "Monthly", value: "Monthly" },
      { label: "Quarterly", value: "Quarterly" },
      { label: "Semi-annual", value: "Semi-annual" },
      { label: "Annual", value: "Annual" },
      { label: "Biennial", value: "Biennial" },
      { label: "3 Year", value: "3 Year" },
      { label: "4 Year", value: "4 Year" },
      { label: "5 Year", value: "5 Year" },
      // { label: "6 Year", value: "6 Year" },
      // { label: "7 Year", value: "7 Year" },
      // { label: "8 Year", value: "8 Year" },
      // { label: "9 Year", value: "9 Year" },
      // { label: "10 Year", value: "10 Year" },
    ];
  }

  /*************************   Create Subscription Method Starts    *************************/

  //Get Interval
  getIntervalForSubscription(event) {
    this.intervalForSubscription = event.target.value;
  }

  //Get the Total Amount
  getTotalAmount(event) {
    this.totalAmount = event.target.value;
    console.log("this.totalAmount:", this.totalAmount);
  }

  //Get the Currency Selected By the User
  getCurrencyForSubscription(event) {
    this.currency = event.detail.value;
    console.log("this.currency:", this.currency);
  }

  //Get the Input from Field
  getDescription(event) {
    this.description = event.target.value;
    console.log("description", this.description);
  }

  //Get the start date from the User
  getDayOfMonth(event) {
    this.dayOfMonth = event.target.value;
    console.log("dayOfMonth", this.dayOfMonth);
  }

  //Get the Interval Unit
  getbillingFrequency(event) {
    this.intervalUnit = event.target.value;
  }

  //Get the Total Count
  getCount(event) {
    this.totalCount = event.target.value;
    console.log("totalCount", this.totalCount);
  }

  handleChange(event) {
    //Get Selected Value by User
    this.selectedDuration = event.detail.value;

    //Prepare a body for updating record
    this.fieldUpdate = {
      fields: {
        Contract_Duration__c: this.selectedDuration,
        Id: this.pageId,
      },
    };
  }

  //Get Details
  getAllDetailsForSubscription() {
    if (!this.totalAmount) {
      this.toastEventFire("Enter a Valid Amount", "", "error");
      return;
    }

    //Show the Spinner
    this.loaded = true;

    //Getting the Mandate Id
    getBillingRequestId({ pageId: this.pageId })
      .then((result) => {
        console.log("Result", result);
        console.log("pageId", this.pageId);
        this.mandateId = result[0].Mandate_Id__c;

        //If the Mandate Id Exists
        if (this.mandateId) {
          this.initializeSubscription();
        } else {
          //Show a toast Message
          this.toastEventFire("Mandate Id not Found", "", "error");

          //Hide the Spinner
          this.loaded = false;
        }
      })
      .catch((error) => {
        //Show Error Toast Message
        this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");
        console.error("Error:", error);

        //Hide the Spinner
        this.loaded = false;
      });
  }

  //Initialize Subscription
  async initializeSubscription() {
    const intervals = {
      Weekly: [1, "weekly"],
      "Bi-weekly": [2, "weekly"],
      Monthly: [1, "monthly"],
      Quarterly: [3, "monthly"],
      "Semi-annual": [6, "monthly"],
      Annual: [1, "yearly"],
      Biennial: [2, "yearly"],
      "3 Year": [3, "yearly"],
      "4 Year": [4, "yearly"],
      "5 Year": [5, "yearly"],
      // "6 Year": [6, "yearly"],
      // "7 Year": [7, "yearly"],
      // "8 Year": [8, "yearly"],
      // "9 Year": [9, "yearly"],
      // "10 Year": [10, "yearly"],
    };

    const [interval, interval_unit] = intervals[this.intervalUnit] || [0, "error"];

    //JSON Body to Send to GoCardless Api
    const dynamicBody = JSON.stringify({
      subscriptions: {
        amount: Number(this.totalAmount + "00"),
        currency: this.currency,
        day_of_month: this.dayOfMonth,
        end_date: this.endDate,
        count: this.totalCount,
        name: this.description,
        retry_if_possible: true,
        metadata: {},
        links: {
          mandate: this.mandateId,
        },
        interval_unit,
        interval,
      },
    });

    try {
      //Calling Create Subscription Method
      const result = await createSubscription({
        createSubscriptionBody: dynamicBody,
        oppId: this.pageId,
      });

      //Parsing the data
      this.createSubscriptionResponse = JSON.parse(result);

      console.log("createSubscriptionResponse: ", this.createSubscriptionResponse);

      //Check if the Api Response returns An Error
      if (this.createSubscriptionResponse.error) {
        this.loaded = false;
        this.toastEventFire(
          `${this.createSubscriptionResponse.error.errors[0].field}: ${this.createSubscriptionResponse.error.errors[0].message}`,
          `${this.createSubscriptionResponse.error.message}`,
          "error"
        );
        return;
      }
      //Check If the Api Returns Success
      else if (this.createSubscriptionResponse.subscriptions.id) {
        //update the Record Page and selected field
        await updateRecord(this.fieldUpdate);
        await updateRecord({ fields: { Id: this.pageId } });

        //Show a success toast
        this.toastEventFire(
          `${this.createSubscriptionResponse.subscriptions.name}`,
          `Subscription amount: ${String(this.createSubscriptionResponse.subscriptions.amount).slice(0, -2)} ${
            this.createSubscriptionResponse.subscriptions.currency
          }`,
          "success"
        );
        //Close the Modal on Success Return
        setTimeout(() => {
          this.handleClose();
        }, 500);
      }
    } catch (error) {
      //Show a Toast Message of error
      this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");
      //Hide a Spinner on error
      this.loaded = false;
      console.error("Error:", error);
    } finally {
      //Hide a Spinner on error
      this.loaded = false;
    }
  }

  //Close Modal through child to parent
  @api
  handleClose() {
    this.dispatchEvent(new CustomEvent("closemodal"));
  }

  //Show toast Method
  toastEventFire(title, message, variant) {
    const event = new ShowToastEvent({ title, message, variant });
    this.dispatchEvent(event);
  }
}