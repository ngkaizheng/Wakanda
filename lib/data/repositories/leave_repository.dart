import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Future<double> getUnpaidLeaveDays(
//     String companyId, DateTime selectedDate) async {
//   try {
//     // Extract year and month from the selected date
//     int year = selectedDate.year;
//     int month = selectedDate.month;

//     logger.i('selectedDate $selectedDate');
//     // Reference to the leaveHistory collection
//     CollectionReference leaveCollection = FirebaseFirestore.instance
//         .collection('users')
//         .doc(companyId)
//         .collection('leaveHistory');

//     // Get the start and end dates for the current month
//     DateTime firstDayOfMonth = DateTime(year, month, 1);
//     DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
//     logger.i('firstDayOfMonth $firstDayOfMonth');
//     logger.i('lastDayOfMonth $lastDayOfMonth');

//     // Query to get the approved leaves for the current month
//     QuerySnapshot leaveSnapshot = await leaveCollection
//         .where('status', isEqualTo: 'Approved')
//         .where('leaveType', isEqualTo: 'Unpaid')
//         // .where('startDate', isLessThanOrEqualTo: lastDayOfMonth)
//         .get();

//     // // Filter the leaves based on the date range
//     // List<QueryDocumentSnapshot> filteredLeaves =
//     //     leaveSnapshot.docs.where((leaveDoc) {
//     //   DateTime startDate = leaveDoc['startDate'].toDate();
//     //   DateTime endDate = leaveDoc['endDate'].toDate();
//     //   return ((startDate.isAfter(firstDayOfMonth) &&
//     //           startDate.isBefore(lastDayOfMonth)) ||
//     //       (endDate.isAfter(firstDayOfMonth) &&
//     //           endDate.isBefore(lastDayOfMonth)));
//     // }).toList();
// // Filter the leaves based on the date range
//     List<QueryDocumentSnapshot> filteredLeaves =
//         leaveSnapshot.docs.where((leaveDoc) {
//       DateTime startDate = leaveDoc['startDate'].toDate();
//       DateTime endDate = leaveDoc['endDate'].toDate();

//       logger.i('month ${month}');
//       logger.i('endDate.month ${endDate.month}');
//       logger.i('endDate.month == month ${endDate.month == month}');
//       // Include leaves that overlap with the date range
//       return ((startDate.isBefore(lastDayOfMonth.add(Duration(days: 1))) &&
//               endDate.isAfter(firstDayOfMonth.subtract(Duration(days: 1)))) ||
//           (startDate.isBefore(lastDayOfMonth.add(Duration(days: 1))) &&
//               endDate.month == month) ||
//           (startDate.month == month &&
//               endDate.isAfter(firstDayOfMonth.subtract(Duration(days: 1)))));
//     }).toList();

//     logger.i(
//         'lastDayOfMonth.add(Duration(days: 1) ${lastDayOfMonth.add(Duration(days: 1))}');
//     logger.i(
//         ' endDate.isAfter(firstDayOfMonth.subtract(Duration(days: 1))) ${(firstDayOfMonth.subtract(Duration(days: 1)))}');
//     double unpaidLeaveDays = 0;

//     for (QueryDocumentSnapshot leaveDoc in filteredLeaves) {
//       DateTime startDate = leaveDoc['startDate'].toDate();
//       DateTime endDate = leaveDoc['endDate'].toDate();

//       logger.i('startDate ${startDate}');
//       logger.i('endDate ${endDate}');

//       // // Check if the leave spans multiple months
//       // if (startDate.month == endDate.month && startDate.year == endDate.year) {
//       //   // Case 1: Leave within the same month
//       //   unpaidLeaveDays += endDate.difference(startDate).inDays.toDouble() + 1;
//       // } else if (startDate.month == month && endDate.month != month) {
//       //   // Case 2: Leave starts in the current month and ends in another month
//       //   unpaidLeaveDays +=
//       //       lastDayOfMonth.difference(startDate).inDays.toDouble() + 1;
//       //   logger.i(
//       //       'lastDayOfMonth.difference(startDate).inDays.toDouble()  ${lastDayOfMonth.difference(startDate).inDays.toDouble()}');
//       // } else if (startDate.month != month && endDate.month == month) {
//       //   // Case 3: Leave starts in another month and ends in the current month
//       //   unpaidLeaveDays +=
//       //       endDate.difference(firstDayOfMonth).inDays.toDouble() + 1;
//       // } else {
//       //   // Case 4: Leave spans the entire month
//       //   unpaidLeaveDays += lastDayOfMonth.day.toDouble();
//       // }
//       // Check if the leave spans multiple months
//       if (startDate.month == endDate.month && startDate.year == endDate.year) {
//         // Case 1: Leave within the same month
//         unpaidLeaveDays += 1; // Counting the current day
//       } else if (startDate.month == month && endDate.month != month) {
//         // Case 2: Leave starts in the current month and ends in another month
//         unpaidLeaveDays += lastDayOfMonth.day - startDate.day + 1;
//       } else if (startDate.month != month && endDate.month == month) {
//         // Case 3: Leave starts in another month and ends in the current month
//         unpaidLeaveDays += endDate.day;
//       } else {
//         // Case 4: Leave spans the entire month
//         unpaidLeaveDays += lastDayOfMonth.day;
//       }
//     }

//     logger.i('unpaidLeaveDays $unpaidLeaveDays');
//     return unpaidLeaveDays;
//   } catch (e) {
//     logger.i('Error getting unpaid leave days: $e');
//     return 0.0;
//   }
// }
Future<Map<String, double>> getLeaveDays(
    String companyId, DateTime selectedDate) async {
  try {
    // Extract year and month from the selected date
    int year = selectedDate.year;
    int month = selectedDate.month;

    logger.i('selectedDate $selectedDate');

    // Reference to the leaveHistory collection
    CollectionReference leaveCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(companyId)
        .collection('leaveHistory');

    // Get the start and end dates for the current month
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
    logger.i('firstDayOfMonth $firstDayOfMonth');
    logger.i('lastDayOfMonth $lastDayOfMonth');

    // Query to get the approved leaves for the current month
    QuerySnapshot leaveSnapshot = await leaveCollection
        .where('status', isEqualTo: 'Approved')
        .where('fullORHalf', isEqualTo: 'Half')
        .get();

    // Separate maps for paid and unpaid leave
    Map<String, double> leaveType = {'Annual': 0.0, 'Unpaid': 0.0};

    // Process half-day leaves first
    for (QueryDocumentSnapshot leaveDoc in leaveSnapshot.docs) {
      DateTime startDate = leaveDoc['startDate'].toDate();

      // Check if the leave is for the current month
      if ((startDate.month == month) && startDate.year == year) {
        if (leaveDoc['fullORHalf'] == 'Half') {
          leaveType[leaveDoc['leaveType']] =
              (leaveType[leaveDoc['leaveType']] ?? 0.0) + 0.5;
        }
      }
    }

    QuerySnapshot fullLeaveSnapshot = await leaveCollection
        .where('status', isEqualTo: 'Approved')
        .where('fullORHalf', isEqualTo: 'Full')
        .get();

    // Filter the leaves based on the date range
    List<QueryDocumentSnapshot> filteredLeaves =
        fullLeaveSnapshot.docs.where((leaveDoc) {
      DateTime startDate = leaveDoc['startDate'].toDate();
      DateTime endDate = leaveDoc['endDate'].toDate();

      // Include leaves that overlap with the date range
      return ((startDate.isBefore(lastDayOfMonth.add(Duration(days: 1))) &&
              endDate.isAfter(firstDayOfMonth.subtract(Duration(days: 1)))) ||
          (startDate.isBefore(lastDayOfMonth.add(Duration(days: 1))) &&
              endDate.month == month &&
              endDate.year == year) ||
          (startDate.month == month &&
              endDate.year == year &&
              endDate.isAfter(firstDayOfMonth.subtract(Duration(days: 1)))));
    }).toList();

    for (QueryDocumentSnapshot leaveDoc in filteredLeaves) {
      DateTime startDate = leaveDoc['startDate'].toDate();
      DateTime endDate = leaveDoc['endDate'].toDate();

      // Ensure the leave type key exists in the map
      if (leaveType[leaveDoc['leaveType']] == null) {
        leaveType[leaveDoc['leaveType']] = 0.0;
      }

      // Check if the leave spans multiple months
      if (startDate.month == endDate.month && startDate.year == endDate.year) {
        // Case 1: Leave within the same month
        leaveType[leaveDoc['leaveType']] =
            (leaveType[leaveDoc['leaveType']] ?? 0) +
                (endDate.day - startDate.day + 1);
      } else if (startDate.month == month && endDate.month != month) {
        // Case 2: Leave starts in the current month and ends in another month
        leaveType[leaveDoc['leaveType']] =
            (leaveType[leaveDoc['leaveType']] ?? 0) +
                lastDayOfMonth.day -
                startDate.day +
                1;
      } else if (startDate.month != month && endDate.month == month) {
        // Case 3: Leave starts in another month and ends in the current month
        leaveType[leaveDoc['leaveType']] =
            (leaveType[leaveDoc['leaveType']] ?? 0) + endDate.day;
      } else {
        // Case 4: Leave spans the entire month
        leaveType[leaveDoc['leaveType']] =
            (leaveType[leaveDoc['leaveType']] ?? 0) + lastDayOfMonth.day;
      }
    }

    logger.i('leaveType: $leaveType');
    return leaveType;
  } catch (e) {
    logger.i('Error getting leave days: $e');
    return {'paid': 0.0, 'unpaid': 0.0};
  }
}
