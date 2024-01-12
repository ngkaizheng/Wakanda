import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final logger = Logger();

Future<void> storeBonus(
    String companyId, DateTime selectedDate, double bonusAmount) async {
  try {
    // Get the year and month from the selectedDate
    int year = selectedDate.year;
    int month = selectedDate.month;

    // Reference to the bonus collection in Firestore
    CollectionReference bonusCollection =
        FirebaseFirestore.instance.collection('bonus');

    // Reference to the company document
    DocumentReference companyDocRef = bonusCollection.doc(companyId);

    // Reference to the year collection within the company document
    CollectionReference yearCollection =
        companyDocRef.collection(year.toString());

    // Reference to the month document within the year collection
    DocumentReference monthDocRef = yearCollection.doc(month.toString());

    // Store the bonusAmount field in the month document
    await monthDocRef.set({
      'bonusAmount': FieldValue.increment(
          bonusAmount), // Use increment to add to existing value
    }, SetOptions(merge: true));
  } catch (e) {
    logger.i('Error storing bonus: $e');
    // Handle the error, e.g., display an error message
  }
}

Future<num> getBonus(String companyId, DateTime selectedDate) async {
  try {
    logger.i('selectedDate $selectedDate');
    // Get the year and month from the selectedDate
    int year = selectedDate.year;
    int month = selectedDate.month;

    // Reference to the bonus collection in Firestore
    CollectionReference bonusCollection =
        FirebaseFirestore.instance.collection('bonus');

    // Reference to the company document
    DocumentReference companyDocRef = bonusCollection.doc(companyId);

    // Reference to the year collection within the company document
    CollectionReference yearCollection =
        companyDocRef.collection(year.toString());

    // Reference to the month document within the year collection
    DocumentSnapshot monthSnapshot =
        await yearCollection.doc(month.toString()).get();

    // Check if the month document exists
    if (monthSnapshot.exists) {
      // Retrieve the bonusAmount field from the month document
      num bonusAmount = monthSnapshot['bonusAmount'] ?? 0.0;
      logger.i('bonusAmount $bonusAmount');
      // You can now use the bonusAmount variable as needed
      return bonusAmount;
    } else {
      // Handle the case when the month document doesn't exist
      logger.i('No bonus found for the specified month and year.');
      return 0.0; // Or any default value
    }
  } catch (e) {
    logger.i('Error getting bonus: $e');
    // Handle the error, e.g., display an error message
    return 0.0; // Or any default value
  }
}

Future<void> deleteBonus(String companyId, DateTime selectedDate) async {
  try {
    // Get the year and month from the selectedDate
    int year = selectedDate.year;
    int month = selectedDate.month;

    // Reference to the bonus collection in Firestore
    CollectionReference bonusCollection =
        FirebaseFirestore.instance.collection('bonus');

    // Reference to the company document
    DocumentReference companyDocRef = bonusCollection.doc(companyId);

    // Reference to the year collection within the company document
    CollectionReference yearCollection =
        companyDocRef.collection(year.toString());

    // Delete the month document within the year collection
    await yearCollection.doc(month.toString()).delete();

    print('Bonus successfully deleted.');
  } catch (e) {
    print('Error deleting bonus: $e');
    // Handle the error, e.g., display an error message
  }
}
