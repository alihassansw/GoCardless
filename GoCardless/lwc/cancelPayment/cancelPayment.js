import { LightningElement, track, api, wire } from "lwc";
import { updateRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from "lightning/navigation";
import specificId from "@salesforce/apex/GoCardlessRequest.getSpecificId";
import cancelChargedPayment from "@salesforce/apex/GoCardlessRequest.cancelChargedPayment";

export default class CancelPayment extends LightningElement {
  //Variables
  @track data;
  @track dataId;
  @track responseData;
  @track error;
  @track loaded = false;
  @track pageReference;
  @track updatedField;
  @track showConfirmation = false;

  //Fields to Query
  fields = ["Id__c", "Subscription_id__c"];

  @wire(CurrentPageReference) pageRef;

  //Get Record Id
  @api recordId;

  @wire(getObjectInfo, { objectApiName: "$objectApiName" })
  objectInfo;

  get objectApiName() {
    if (this.pageRef) {
      return this.pageRef.attributes.objectApiName;
    }
    return null;
  }

  handleCancelPaymentClick() {
    this.showConfirmation = true;
  }

  handleCancelConfirmationClick() {
    this.showConfirmation = false;
  }

  //Cancel Payment
  handleConfirmCancellationClick() {
    //Show the loading Spinner
    this.loaded = true;

    if (this.objectApiName === 'GoCardless_Order__c') {
      this.updatedField = this.fields[0]; 
    } else if (this.objectApiName === 'AcctSeed__Recurring_Billing__c') {
      this.updatedField = this.fields[1]; 
    }

    //Get the Payment Id from DataBase
    setTimeout(() => {
      specificId({ objectName: this.objectApiName, pageId: this.recordId, fieldApiNames: this.updatedField })
        .then((result) => {
          this.data = result;
          console.log("result: ", result);
          const dataId = result[0].Id__c || result[0].Subscription_id__c;
          if (!dataId) {
            this.toastEventFire(`Could not find payment id`, ``, "info");
            this.loaded = false;
            this.showConfirmation = false;
            return;
          }
          return cancelChargedPayment({
            specificId: dataId,
            pageId: this.recordId,
          });
        })
        .then(async (result) => {
          if (result) {
            //Update the Record Page
            await updateRecord({ fields: { Id: this.recordId } });

            //Parsing the Api Response in to an Object
            this.responseData = JSON.parse(result);

            const keys = Object.keys(this.responseData);
            const element = this.responseData[keys[0]];

            //If the Api Response Returns Success (payment cancelled)
            if (element.status === "cancelled") {
              this.toastEventFire(`Status: ${element.status}`, ``, "success");

              //Hide the Confirmation Window
              this.showConfirmation = false;

            } else if (this.responseData.error) {
              this.toastEventFire(
                `${this.responseData.error.message}`,
                `The request may be in 'submitted or cancelled' status`,
                "error"
              );
              //Hide the Confirmation Window
              this.showConfirmation = false;
              
            } else {
              this.toastEventFire(`Cannot Make Request`, ``, "error");

              //Hide the Confirmation Window
              this.showConfirmation = false;
            }
          }
        })
        .catch((error) => {
          this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");
          console.error("Error:", error);
        })
        .finally(() => {
          this.loaded = false;
        });
    }, 1000);
  }

  // //Get Specific Id
  // getSpecificIdOnclick() {
  //   //Show loading Spinner
  //   this.loaded = true;

  //   specificId({ objectName: this.objectApiName, pageId: this.recordId, fieldApiNames: this.fields })
  //     .then((result) => {
  //       this.data = result;
  //       console.log('result: ', result);
  //       this.dataId = result[0].Id__c;
  //       this.dataId = result[0].Subscription_id__c;
  //       if (this.dataId) {
  //         this.cancelPayment();
  //       } else {
  //         //Show Error Toast Message
  //         this.toastEventFire(`Could not find payment id`, ``, "info");

  //         //Hide the Spinner
  //         this.loaded = false;
  //       }
  //     })
  //     .catch((error) => {
  //       //Show Error Toast Message
  //       this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");

  //       //Hide the Spinner
  //       this.loaded = false;

  //       console.error("Error:", error);
  //     });
  // }

  // //Cancel Payment
  // cancelPayment() {
  //   setTimeout(async () => {
  //     try {
  //       const result = await cancelChargedPayment({
  //         specificId: this.dataId,
  //         pageId: this.recordId,
  //       });
  //       await updateRecord({ fields: { Id: this.recordId } });
  //       this.responseData = JSON.parse(result);
  //       const keys = Object.keys(this.responseData);
  //       const element = this.responseData[keys[0]];
  //       if (element.status === "cancelled") {
  //         this.toastEventFire(`Status: ${element.status}`, ``, "success");
  //       } else if (this.responseData.error) {
  //         this.toastEventFire(
  //           `${this.responseData.error.message}`,
  //           `The request may be in 'submitted or cancelled' status`,
  //           "error"
  //         );
  //       } else {
  //         this.toastEventFire(`Cannot Make Request`, ``, "error");
  //       }
  //       this.loaded = false;
  //     } catch (error) {
  //       this.toastEventFire(`Error Code ${error.status}`, `${error.statusText}`, "error");
  //       console.error("Error:", error);
  //       this.loaded = false;
  //     }
  //   }, 1000);
  // }

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