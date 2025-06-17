// setup-admin.js
const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin with service account
// Replace 'service-account-key.json' with your actual filename
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function setAdminClaims() {
  try {
    console.log('🔄 Setting up admin claims...');
    
    const email = 'yvettetuyizere@gmail.com';
    
    // Get user by email
    const user = await admin.auth().getUserByEmail(email);
    console.log('✅ User found:', user.uid);
    console.log('📧 Email:', user.email);
    
    // Set admin custom claims
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    console.log('🔧 Setting admin claims...');
    
    // Wait a moment for the claims to be set
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Verify the claims were set
    const updatedUser = await admin.auth().getUser(user.uid);
    console.log('✅ Admin claims set successfully!');
    console.log('🎯 Custom claims:', updatedUser.customClaims);
    
    if (updatedUser.customClaims && updatedUser.customClaims.admin) {
      console.log('🎉 SUCCESS! Admin privileges granted to', email);
      console.log('⚠️  Note: User needs to sign out and sign back in for changes to take effect');
    } else {
      console.log('❌ Warning: Claims may not have been set properly');
    }
    
  } catch (error) {
    console.error('❌ Error setting admin claims:');
    
    if (error.code === 'auth/user-not-found') {
      console.error('🔍 User not found. Make sure the email address is correct and the user exists in Firebase Auth');
    } else if (error.code === 'auth/invalid-credential') {
      console.error('🔑 Invalid credentials. Check your service account key file');
    } else {
      console.error('💥 Error details:', error.message);
    }
  } finally {
    // Close the app
    console.log('🏁 Cleaning up...');
    await admin.app().delete();
    process.exit(0);
  }
}

// Check if service account file exists
const fs = require('fs');
if (!fs.existsSync('./service-account-key.json')) {
  console.error('❌ Service account key file not found!');
  console.log('📋 Please follow these steps:');
  console.log('1. Go to Firebase Console → Project Settings → Service Accounts');
  console.log('2. Click "Generate new private key"');
  console.log('3. Download the JSON file');
  console.log('4. Save it as "service-account-key.json" in this folder');
  process.exit(1);
}

// Run the function
console.log('🚀 Starting Firebase Admin setup...');
setAdminClaims();