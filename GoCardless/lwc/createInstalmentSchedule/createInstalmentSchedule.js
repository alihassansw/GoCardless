import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//Apex Methods
import getBillingRequestId from "@salesforce/apex/GoCardlessRequest.getBillingRequestId";
import instalmentSchedules from "@salesforce/apex/GoCardlessRequest.instalmentSchedules";
import getInstalmentSchedules from "@salesforce/apex/GoCardlessRequest.getInstalmentSchedules";

export default class CreateInstalmentSchedule extends LightningElement {
  //Get the Current Page Id
  @api pageId;

  //Variables for Create Installment Subscription
  @track instalmentScheduledata;
  @track loaded;
  @track mandateId;
  @track instalmentScheduleData;
  @track instalmentScheduleId;
  @track tabContent = "";
  //Variables for JSON Create Installment Subscription
  @track descriptionForInstallmentSubscription;
  @track currency = "USD";
  @track startDate;
  @track intervalUnit = "weekly";
  @track interval = "1";
  @track presetValueOne;
  @track presetValueTwo;
  @track presetValueThree;
  //Variables for JSON Create Installment Subscription for Date API
  @track descriptionForDateApi;
  @track presetValueOneForDateApi;
  @track presetValueTwoForDateApi;
  @track presetValueThreeForDateApi;
  @track presetDateOneForDateApi;
  @track presetDateTwoForDateApi;
  @track presetDateThreeForDateApi;

  //Get optionsForIntervalUnit
  get optionsForIntervalUnit() {
    return [
      { label: "1", value: "1" },
      { label: "2", value: "2" },
      { label: "3", value: "3" },
      { label: "4", value: "4" },
      { label: "5", value: "5" },
    ];
  }

  //Get optionsForIntervalUnit
  get intervalOptions() {
    return [
      { label: "weekly", value: "weekly" },
      { label: "monthly", value: "monthly" },
      { label: "annually", value: "annually" },
    ];
  }

  //Getting the option for the all Modals
  get currencyOptions() {
    return [
      { label: "USD", value: "USD" },
      { label: "GBP", value: "GBP" },
      { label: "AUD", value: "AUD" },
      { label: "EUR", value: "EUR" },
    ];
  }

  /*************************   Create Installment Subscription Method Starts    *************************/

  //Active Tab
  handleActive(event) {
    this.tabContent = event.target.value;
    console.log("tabContent", this.tabContent);
  }

  //Get optionsForIntervalUnit

  //Get the Total Amount
  getTotalAmount(event) {
    this.amount = event.target.value;
    console.log("this.amount:", this.amount);
  }

  //Get the Currency Selected By the User
  getCurrency(event) {
    this.currency = event.detail.value;
    console.log("this.currency:", this.currency);
  }

  //Get the Input from Field
  getDescriptionForInstallmentSubscription(event) {
    this.descriptionForInstallmentSubscription = event.target.value;
    console.log("description", this.descriptionForInstallmentSubscription);
  }

  //Get the start date from the User
  getStartDate(event) {
    this.startDate = event.target.value;
    console.log("startDate", this.startDate);
  }

  //Get the Interval Unit
  getIntervalUnitForInstallmentSubscription(event) {
    this.intervalUnit = event.target.value;
    console.log("intervalUnit", this.intervalUnit);
  }

  //Get the Internal
  getInterval(event) {
    this.interval = event.target.value;
    console.log("interval", this.interval);
  }

  //Get the Internal
  getPresetValueOne(event) {
    this.presetValueOne = event.target.value;
    console.log("presetValueOne", this.presetValueOne);
  }

  //Get the Internal
  getPresetValueTwo(event) {
    this.presetValueTwo = event.target.value;
    console.log("presetValueTwo", this.presetValueTwo);
  }

  //Get the Internal
  getPresetValueThree(event) {
    this.presetValueThree = event.target.value;
    console.log("presetValueThree", this.presetValueThree);
  }

  //Get the Description for Date Api
  getDescriptionForDateAPI(event) {
    this.descriptionForDateApi = event.target.value;
    console.log("getDescriptionForDateAPI", this.descriptionForDateApi);
  }

  //Get the Description for Date Api
  getPresetValueOneForDateApi(event) {
    this.presetValueOneForDateApi = event.target.value;
    console.log("getPresetValueOneForDateApi", this.presetValueOneForDateApi);
  }

  //Get the Description for Date Api
  getPresetValueTwoForDateApi(event) {
    this.presetValueTwoForDateApi = event.target.value;
    console.log("getPresetValueTwoForDateApi", this.presetValueTwoForDateApi);
  }

  //Get the Description for Date Api
  getPresetValueThreeForDateApi(event) {
    this.presetValueThreeForDateApi = event.target.value;
    console.log("getPresetValueThreeForDateApi", this.presetValueThreeForDateApi);
  }

  //Get the Description for Date Api
  getStartDateOneForDateApi(event) {
    this.presetDateOneForDateApi = event.target.value;
    console.log("getStartDateOneForDateApi", this.presetDateOneForDateApi);
  }

  //Get the Description for Date Api
  getStartDateTwoForDateApi(event) {
    this.presetDateTwoForDateApi = event.target.value;
    console.log("getStartDateTwoForDateApi", this.presetDateTwoForDateApi);
  }

  //Get the Description for Date Api
  getStartDateThreeForDateApi(event) {
    this.presetDateThreeForDateApi = event.target.value;
    console.log("getStartDateThreeForDateApi", this.presetDateThreeForDateApi);
  }

  //get All Details
  getAllDetails() {
    //Check if the Amount if Empty
    if (!this.amount) {
      this.toastEventFire("Enter a Valid Amount", "", "error");
      return;
    }
    //Show the Spinner
    this.loaded = true;

    //Get the Mandate Id By Apex Method
    getBillingRequestId({ pageId: this.pageId })
      .then((result) => {
        console.log("Result", result);
        this.mandateId = result[0].Mandate_Id__c;

        //If the Mandate Id Exists
        if (this.mandateId) {
          if (this.tabContent === "1") {
            //JSON Body to Send
            const JSONBody = JSON.stringify({
              instalment_schedules: {
                name: this.descriptionForInstallmentSubscription,
                currency: this.currency,
                total_amount: Number(this.amount + "00"),
                app_fee: 10,
                instalments: {
                  start_date: this.startDate,
                  interval: Number(this.interval),
                  interval_unit: this.intervalUnit,
                  amounts: this.presetValueThree
                    ? [
                        Number(this.presetValueOne + "00"),
                        Number(this.presetValueTwo + "00"),
                        Number(this.presetValueThree + "00"),
                      ]
                    : [Number(this.presetValueOne + "00"), Number(this.presetValueTwo + "00")],
                },
                links: {
                  mandate: this.mandateId,
                },
                metadata: {},
              },
            });
            console.log("JSONBody", JSONBody);

            //Calling Apex Method
            instalmentSchedules({ instalmentSchedulesBody: JSONBody })
              .then((result) => {
                //Parsing the response
                this.instalmentScheduledata = JSON.parse(result);
                if (this.instalmentScheduledata.error) {
                  //Hide the Spinner
                  this.loaded = false;

                  //Show a Toast message of Error
                  this.toastEventFire(
                    `${this.instalmentScheduledata.error.message}`,
                    `${this.instalmentScheduledata.error.errors[0].field}: ${this.instalmentScheduledata.error.errors[0].message}`,
                    "error"
                  );
                } else {
                  this.activateScheduleStatus();
                  console.log("Activating Status");
                }
              })
              .catch((error) => {
                //Show Error Toast Message
                this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");

                console.error("Error:", error);

                //Hide the Spinner
                this.loaded = false;
              });
          } else if (this.tabContent === "2") {
            //JSON Body to Send for Date Api
            const JSONBodyDate = JSON.stringify({
              instalment_schedules: {
                name: this.descriptionForDateApi,
                total_amount: Number(this.amount + "00"),
                app_fee: 10,
                currency: this.currency,
                instalments: this.presetValueThreeForDateApi
                  ? [
                      {
                        charge_date: this.presetDateOneForDateApi,
                        amount: Number(this.presetValueOneForDateApi + "00"),
                      },
                      {
                        charge_date: this.presetDateTwoForDateApi,
                        amount: Number(this.presetValueTwoForDateApi + "00"),
                      },
                      {
                        charge_date: this.presetDateThreeForDateApi,
                        amount: Number(this.presetValueThreeForDateApi + "00"),
                      },
                    ]
                  : [
                      {
                        charge_date: this.presetDateOneForDateApi,
                        amount: Number(this.presetValueOneForDateApi + "00"),
                      },
                      {
                        charge_date: this.presetDateTwoForDateApi,
                        amount: Number(this.presetValueTwoForDateApi + "00"),
                      },
                    ],
                links: {
                  mandate: this.mandateId,
                },
                metadata: {},
              },
            });
            console.log("JSONBodyDate", JSONBodyDate);

            //Calling Apex Method Imperatively
            instalmentSchedules({ instalmentSchedulesBody: JSONBodyDate })
              .then((result) => {
                this.instalmentScheduledata = JSON.parse(result);
                if (this.instalmentScheduledata.error) {
                  //Hide the Spinner
                  this.loaded = false;

                  //Show a Toast message of Error
                  this.toastEventFire(
                    `${this.instalmentScheduledata.error.message}`,
                    `${this.instalmentScheduledata.error.errors[0].field}: ${this.instalmentScheduledata.error.errors[0].message}`,
                    "error"
                  );
                } else {
                  this.activateScheduleStatus();
                  console.log("Activating Status");
                }
                console.log("Result", result);
              })
              .catch((error) => {
                //Show Error Toast Message
                this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");

                console.error("Error:", error);

                //Hide the Spinner
                this.loaded = false;
              });
          } else {
            //Show Toast of Error
            this.toastEventFire("Details Not Specified", "", "error");
            console.log("Nothing Found");
            //Hide the Spinner
            this.loaded = false;
          }
        } else {
          this.toastEventFire("", "Mandate Id Not Found", "error");
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

  //Activate Schedule Status
  activateScheduleStatus() {
    //Extracting the Id from Response
    this.instalmentScheduleId = this.instalmentScheduledata.instalment_schedules.id;

    //If the Installment Id Exists in the response
    if (this.instalmentScheduleId) {
      //Wait for 2seconds
      setTimeout(() => {
        //Calling the Apex Method to get the Status
        getInstalmentSchedules({
          instalmentScheduleId: this.instalmentScheduleId,
          oppId: this.pageId,
        })
          .then((result) => {
            //Parsing the Data
            this.instalmentScheduleData = JSON.parse(result);
            console.log("instalmentScheduleData", this.instalmentScheduleData);

            //If the Ststus is Active in the Response
            if (this.instalmentScheduleData.instalment_schedules.status === "active") {
              //Show a Toast of Activated
              this.toastEventFire(
                `${this.instalmentScheduleData.instalment_schedules.name}`,
                `Status: ${this.instalmentScheduleData.instalment_schedules.status}`,
                "success"
              );

              //Close the modal
              setTimeout(() => {
                this.handleClose();
              }, 500);

              //Hide the Spinner
              this.loaded = false;
            } else {
              //Show a Toast of Activated
              this.toastEventFire(
                `${this.instalmentScheduleData.instalment_schedules.name}`,
                `Status: ${this.instalmentScheduleData.instalment_schedules.status}`,
                "info"
              );

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
      }, 5000);
    }
  }

  //Show toast Method
  toastEventFire(title, message, variant) {
    const event = new ShowToastEvent({ title, message, variant });
    this.dispatchEvent(event);
  }

  //Close Modal through child to parent
  @api
  handleClose() {
    console.log("Working Child");
    this.dispatchEvent(new CustomEvent("closemodal"));
  }
}