import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final logger = Logger();

Future<Map<String, Map<String, dynamic>>> getClaimSummary(
    String companyId, DateTime selectedDate) async {
  try {
    int year = selectedDate.year;
    int month = selectedDate.month;

    CollectionReference claimCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(companyId)
        .collection('claimHistory');

    QuerySnapshot claimHistorySnapshot = await claimCollection
        .where('claimDate', isGreaterThanOrEqualTo: DateTime(year, month, 1))
        .where('claimDate', isLessThan: DateTime(year, month + 1, 1))
        .where('status', isEqualTo: 'Approved')
        .get();

    Map<String, Map<String, dynamic>> claimData = {};

    claimData['summary'] = {
      'medicalClaim': 0.0,
      'travelClaim': 0.0,
      'mealClaim': 0.0,
      'fuelClaim': 0.0,
      'entertainmentClaim': 0.0,
    };

    claimHistorySnapshot.docs.forEach((DocumentSnapshot claim) {
      String claimType = claim['claimType'];
      double claimAmount = claim['claimAmount'];

      logger.i('claimType claimAmount $claimType $claimAmount');
      switch (claimType) {
        case 'Medical':
          claimData['summary']?['medicalClaim'] += claimAmount;
          break;
        case 'Travel':
          claimData['summary']?['travelClaim'] += claimAmount;
          break;
        case 'Meal':
          claimData['summary']?['mealClaim'] += claimAmount;
          break;
        case 'Fuel':
          claimData['summary']?['fuelClaim'] += claimAmount;
          break;
        case 'Entertainment':
          claimData['summary']?['entertainmentClaim'] += claimAmount;
          break;
        default:
          // Handle other claim types if needed
          break;
      }
    });

    return claimData;
  } catch (e) {
    logger.i('Error getting claim data: $e');
    return {};
  }
}
