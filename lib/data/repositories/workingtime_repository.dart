import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/utils/checkholiday.dart';

final logger = Logger();
// Future<Map<String, dynamic>> getMonthlyWorkingTime(
//     String companyId, DateTime selectedDate) async {
//   try {
//     // Get the year and month from the selectedDate
//     int year = selectedDate.year;
//     int month = selectedDate.month;

//     // Reference to the working time collection in Firestore
//     CollectionReference workingTimeCollection =
//         FirebaseFirestore.instance.collection('workingtime');

//     // Reference to the company document
//     DocumentReference companyDocRef = workingTimeCollection.doc(companyId);

//     // Reference to the year sub-collection within the company document
//     CollectionReference yearCollection =
//         companyDocRef.collection(year.toString());

//     // Reference to the month document within the year sub-collection
//     DocumentReference monthDocRef = yearCollection.doc(month.toString());

//     // Get all the date sub-collections within the month
//     QuerySnapshot dateSubCollections = await monthDocRef.collection('22').get();

//     logger.i('dateSubCollections $dateSubCollections');

//     // Initialize a map to store the working time data for each date
//     Map<String, dynamic> monthlyWorkingTime = {};

// // Iterate through each date sub-collection
//     for (QueryDocumentSnapshot dateSubCollection in dateSubCollections.docs) {
//       String date = dateSubCollection.id;

//       // Retrieve the dailyWorkingTime field from the document
//       Map<String, dynamic>? dailyWorkingTime =
//           dateSubCollection['dailyWorkingTime'] as Map<String, dynamic>?;

//           logger.i('dailyWorkingTime $dailyWorkingTime');

//       if (dailyWorkingTime != null) {
//         // Retrieve the totalworkingtime and isHoliday fields from the map
//         double totalWorkingTime = dailyWorkingTime['totalworkingtime'] ?? 0.0;
//         bool isHoliday = dailyWorkingTime['isHoliday'] ?? false;

//         // Store the data in the map
//         monthlyWorkingTime[date] = {
//           'totalWorkingTime': totalWorkingTime,
//           'isHoliday': isHoliday,
//         };
//       }
//     }

//     logger.i('monthlyWorkingTime $monthlyWorkingTime');
//     return monthlyWorkingTime;
//   } catch (e) {
//     print('Error getting monthly working time: $e');
//     // Handle the error, e.g., display an error message
//     return {};
//   }
// }

Future<Map<String, Map<String, dynamic>>> getMonthlyWorkingTime(
    String companyId, DateTime selectedDate) async {
  try {
    // Extract year and month from the selected date
    int year = selectedDate.year;
    int month = selectedDate.month;

    logger.i("companyId $companyId");

    // Reference to the workingtime document based on companyId, year, and month
    DocumentReference monthDocRef = FirebaseFirestore.instance
        .collection('workingtime')
        .doc(companyId)
        .collection(year.toString())
        .doc(month.toString());

    // Get the total number of days in the month
    int daysInMonth = DateTime(year, month + 1, 0).day;

    // Initialize variables to store working time values
    double normalWorkingTime = 0.0;
    double normalOT = 0.0;
    double holidayWorkingTime = 0.0;
    double holidayOT = 0.0;
    double lessnormalWorkingTime = 0.0;
    int holidayCount = 0;
    // Initialize a map to store the working time data for each date
    Map<String, Map<String, dynamic>> monthlyWorkingTime = {};

    // Iterate through each day of the month
    for (int day = 1; day <= daysInMonth; day++) {
      // Reference to the dailyWorkingTime document for the current day
      DocumentReference dailyWorkingTimeDocRef =
          monthDocRef.collection(day.toString()).doc('dailyWorkingTime');

      // Get the dailyWorkingTime document data
      DocumentSnapshot dailyWorkingTimeDoc = await dailyWorkingTimeDocRef.get();

      logger.i("dailyWorkingTimeDoc.exists $day ${dailyWorkingTimeDoc.exists}");
      if (dailyWorkingTimeDoc.exists) {
        // Retrieve the totalworkingtime and isHoliday fields from the document
        num totalWorkingTime = dailyWorkingTimeDoc['totalworkingtime'] ?? 0.0;
        bool isHoliday = dailyWorkingTimeDoc['isHoliday'] ?? false;

        if (totalWorkingTime > 8.0 && !isHoliday) {
          normalWorkingTime += 8.0;
          normalOT += totalWorkingTime - 8.0;
        } else if (totalWorkingTime > 8.0 && isHoliday) {
          holidayWorkingTime += 8.0;
          holidayOT += totalWorkingTime - 8.0;
        } else if (totalWorkingTime <= 8.0 && !isHoliday) {
          normalWorkingTime += totalWorkingTime;
          lessnormalWorkingTime += 8.0 - totalWorkingTime;
        } else if (totalWorkingTime <= 8.0 && isHoliday) {
          holidayWorkingTime += totalWorkingTime;
          // lessholidayWorkingTime += 8.0 - totalWorkingTime;
        }

        if (isHoliday) {
          holidayCount += 1;
        }

        logger.i("normalWorkingTime $day $normalWorkingTime");

        // // Store the data in the map
        // monthlyWorkingTime[day.toString()] = {
        //   'totalWorkingTime': totalWorkingTime,
        //   'isHoliday': isHoliday,
        // };
        monthlyWorkingTime['summary'] = {
          'normalWorkingTime': normalWorkingTime,
          'normalOT': normalOT,
          'holidayWorkingTime': holidayWorkingTime,
          'holidayOT': holidayOT,
          'lessnormalWorkingTime': lessnormalWorkingTime,
          'holidayCount': holidayCount
        };

        logger.i('monthlyWorkingTime $monthlyWorkingTime');
      }
      if (!dailyWorkingTimeDoc.exists) {
        DateTime checkHoliday = DateTime(year, month, day);
        logger.i(
            "checkHoliday $checkHoliday ${await isPublicHoliday(checkHoliday)}");
        if (await isPublicHoliday(checkHoliday)) {
          holidayCount += 1;

          monthlyWorkingTime['summary'] = {
            'normalWorkingTime': normalWorkingTime,
            'normalOT': normalOT,
            'holidayWorkingTime': holidayWorkingTime,
            'holidayOT': holidayOT,
            'lessnormalWorkingTime': lessnormalWorkingTime,
            'holidayCount': holidayCount
          };
        }
      }
    }
    logger.i('monthlyWorkingTime $monthlyWorkingTime');

    // Return the map containing the dailyWorkingTime data for the entire month
    return monthlyWorkingTime;
  } catch (e) {
    print('Error getting monthly working time: $e');
    // Handle the error, e.g., return an empty map or rethrow the exception
    return {};
  }
}
