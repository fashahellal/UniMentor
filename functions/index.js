const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.createToyyibPayBill = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated in your app
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const { amount, mentorName, subject, menteeEmail, menteeName, menteePhone } = data;

  // Convert amount string (e.g. "RM 50.00") to integer cents for ToyyibPay (e.g. 50.00 * 100 = 5000)
  const cleanAmount = parseFloat(amount.replace(/[^\d.]/g, ''));
  const amountInCents = Math.round(cleanAmount * 100);

  const formData = new URLSearchParams();
  formData.append('userSecretKey', 'wfamrb9k-oj1t-gm8j-8aqz-8guivmvshm1l');
  formData.append('categoryCode', 'jjgc4viv');
  formData.append('billName', `UniMentor Session - ${subject}`);
  formData.append('billDescription', `Tutoring session with ${mentorName}`);
  formData.append('billPriceSetting', '1'); // 1 means fixed price
  formData.append('billPayorInfoSetting', '1'); 
  formData.append('billAmount', amountInCents.toString());
  formData.append('billReturnUrl', 'https://toyyibpay.com/index.php'); // Where ToyyibPay redirects after checking out
  formData.append('billCallbackUrl', 'YOUR_FIREBASE_WEBHOOK_URL_OR_EMPTY_FOR_DEMO');
  formData.append('billExternalReferenceNo', '');
  formData.append('billTo', menteeName);
  formData.append('billEmail', menteeEmail ?? 'student@s.unikl.edu.my');
  formData.append('billPhone', menteePhone ?? '0123456789');

  try {
    const response = await axios.post(
      'https://dev.toyyibpay.com/index.php/api/createBill', // Sandbox endpoint
      formData,
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
    );

    // ToyyibPay returns an array containing a bill code if successful
    if (response.data && response.data[0] && response.data[0].BillCode) {
      const billCode = response.data[0].BillCode;
      return {
        success: true,
        // Construct the staging link to open the payment page
        paymentUrl: `https://dev.toyyibpay.com/${billCode}`
      };
    } else {
      throw new functions.https.HttpsError("internal", "Failed to generate Bill Code from ToyyibPay.");
    }
  } catch (error) {
    console.error("ToyyibPay Error: ", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});