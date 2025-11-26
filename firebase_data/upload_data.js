const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');
const categories = require('./categories.json');
const foodItems = require('./food_items.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadData() {
  try {
    console.log('Starting data upload...');
    
    // Upload categories
    console.log('\n📁 Uploading categories...');
    for (const category of categories.categories) {
      await db.collection('categories').doc(category.id).set(category);
      console.log(`✅ Uploaded category: ${category.name}`);
    }

    // Upload food items
    console.log('\n🍕 Uploading food items...');
    for (const item of foodItems.foodItems) {
      await db.collection('foodItems').doc(item.id).set(item);
      console.log(`✅ Uploaded food item: ${item.name}`);
    }

    console.log('\n🎉 Data upload completed successfully!');
    console.log(`📊 Uploaded ${categories.categories.length} categories and ${foodItems.foodItems.length} food items`);
    
  } catch (error) {
    console.error('❌ Error uploading data:', error);
  } finally {
    process.exit();
  }
}

uploadData();