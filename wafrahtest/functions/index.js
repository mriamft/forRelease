const functions = require("firebase-functions");
const express = require("express");
const app = express();

// Middleware to parse JSON request bodies (important for webhooks)
app.use(express.json());

app.post("/lean-webhook", (req, res) => {
  const event = req.body;

  // Log the incoming webhook event for debugging
  console.log("Webhook Event Received:", event);

  // Check for 'entity.created' event type
  if (event.type === "entity.created") {
    const entity = event.data;
    console.log("Entity Created:", entity);

    // process entity save to firebase or actions
    // Example: Save to Firestore (uncomment if you want to save it)
    // const admin = require('firebase-admin');
    // admin.firestore().collection('entities').add(entity)
    //   .then(() => {
    //     console.log('Entity saved to Firestore');
    //   })
    //   .catch(error => {
    //     console.error('Error saving entity:', error);
    //   });
  }

  // Always return a 200 response to acknowledge receipt of the webhook
  res.sendStatus(200);
});

exports.api = functions.https.onRequest(app);
