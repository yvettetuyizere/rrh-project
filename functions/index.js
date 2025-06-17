const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendReportNotification = functions.https.onCall(
    async (data, context) => {
      const {reportId, reportType, severity, location} = data;

      if (!reportId || !reportType || !severity || !location) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with all required arguments.",
        );
      }

      const message = {
        notification: {
          title: `New ${reportType} Report - Severity: ${severity}`,
          body: `Location: ${location}`,
        },
        data: {
          reportId: reportId,
        },
        topic: "reports",
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("Notification sent:", response);
        return {success: true, response};
      } catch (error) {
        console.error("Error sending notification:", error);
        throw new functions.https.HttpsError("internal", error.message);
      }
    });
