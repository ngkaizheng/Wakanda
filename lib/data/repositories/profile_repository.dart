import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileRepository {
  final logger = Logger();

  Future<Map<String, dynamic>> getUserData(String companyId) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs[0].data() as Map<String, dynamic>;

        // Fetch the 'bankHistory' subcollection
        final QuerySnapshot bankHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('bankHistory')
            .orderBy('effectiveDate', descending: true)
            .get();

        // Check if there are documents in the 'bankHistory' subcollection
        if (bankHistorySnapshot.docs.isNotEmpty) {
          // Retrieve the data from the first document (most recent effectiveDate)
          final Map<String, dynamic> latestBankHistory =
              bankHistorySnapshot.docs[0].data() as Map<String, dynamic>;

          final String bankName = latestBankHistory['bankName'] ?? '';
          final String accountNumber = latestBankHistory['accountNumber'] ?? '';

          userData['bankName'] = bankName;
          userData['accountNumber'] = accountNumber;
        }

        // Fetch the 'bankHistory' subcollection
        final QuerySnapshot salaryHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('salaryHistory')
            .orderBy('effectiveDate', descending: true)
            .get();

        // Check if there are documents in the 'bankHistory' subcollection
        if (salaryHistorySnapshot.docs.isNotEmpty) {
          // Retrieve the data from the first document (most recent effectiveDate)
          final Map<String, dynamic> latestsalaryHistory =
              salaryHistorySnapshot.docs[0].data() as Map<String, dynamic>;

          final num basicSalary = latestsalaryHistory['basicSalary'] ?? '';
          final String epfNo = latestsalaryHistory['epfNo'] ?? '';
          final String socsoNo = latestsalaryHistory['socsoNo'] ?? '';

          userData['basicSalary'] = basicSalary;
          userData['epfNo'] = epfNo;
          userData['socsoNo'] = socsoNo;
        }

        return userData;
      } else {
        logger.w('User not found for companyId: $companyId');
        return {};
      }
    } catch (e) {
      logger.e('Error fetching user data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getPreviousUserData(
      String companyId, DateTime effectiveDate) async {
    DateTime lastDay = DateTime(effectiveDate.year, effectiveDate.month + 1, 0);
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs[0].data() as Map<String, dynamic>;

        // Fetch the 'bankHistory' subcollection
        final QuerySnapshot bankHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('bankHistory')
            .where('effectiveDate', isLessThanOrEqualTo: lastDay)
            .orderBy('effectiveDate', descending: true)
            .get();

        // Check if there are documents in the 'bankHistory' subcollection
        if (bankHistorySnapshot.docs.isNotEmpty) {
          // Retrieve the data from the first document (most recent effectiveDate)
          final Map<String, dynamic> latestBankHistory =
              bankHistorySnapshot.docs[0].data() as Map<String, dynamic>;

          final String bankName = latestBankHistory['bankName'] ?? '';
          final String accountNumber = latestBankHistory['accountNumber'] ?? '';

          userData['bankName'] = bankName;
          userData['accountNumber'] = accountNumber;
        }

        // Fetch the 'salaryHistory' subcollection
        final QuerySnapshot salaryHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('salaryHistory')
            .where('effectiveDate', isLessThanOrEqualTo: lastDay)
            .orderBy('effectiveDate', descending: true)
            .get();

        // Check if there are documents in the 'salaryHistory' subcollection
        if (salaryHistorySnapshot.docs.isNotEmpty) {
          // Retrieve the data from the first document (most recent effectiveDate)
          final Map<String, dynamic> latestSalaryHistory =
              salaryHistorySnapshot.docs[0].data() as Map<String, dynamic>;

          final num basicSalary = latestSalaryHistory['basicSalary'] ?? '';
          final String epfNo = latestSalaryHistory['epfNo'] ?? '';
          final String socsoNo = latestSalaryHistory['socsoNo'] ?? '';

          userData['basicSalary'] = basicSalary;
          userData['epfNo'] = epfNo;
          userData['socsoNo'] = socsoNo;
        }

        return userData;
      } else {
        logger.w('User not found for companyId: $companyId');
        return {};
      }
    } catch (e) {
      logger.e('Error fetching user data: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAllUserData() async {
    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      if (querySnapshot.docs.isNotEmpty) {
        final List<Map<String, dynamic>> userDataList = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        return userDataList;
      } else {
        logger.w('No users found');
        return [];
      }
    } catch (e) {
      logger.e('Error fetching user data: $e');
      return [];
    }
  }

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> createUser(
    String companyId,
    Map<String, dynamic> personalInfo,
    Map<String, dynamic> salaryHistory,
    Map<String, dynamic> bankHistory,
  ) async {
    try {
      // Reference to the user document
      DocumentReference userDocRef = usersCollection.doc(companyId);

      // Use companyId as the document ID
      await userDocRef.set(personalInfo);

      // Reference to the salaryHistory subcollection
      CollectionReference salaryHistoryCollection =
          userDocRef.collection('salaryHistory');

      // Add a new document to the salaryHistory subcollection
      await salaryHistoryCollection.add(salaryHistory);

      // Reference to the bankHistory subcollection
      CollectionReference bankHistoryCollection =
          userDocRef.collection('bankHistory');

      // Add a new document to the bankHistory subcollection
      await bankHistoryCollection.add(bankHistory);
    } catch (e) {
      // Handle errors as needed
      print('Error creating user: $e');
      rethrow; // Rethrow the exception for the calling code to handle
    }
  }

  final storage = FirebaseStorage.instance;

  Future<String> uploadImage(String imagePath, String companyId) async {
    try {
      final ref = storage.ref().child('profile_images/$companyId.jpg');
      await ref.putFile(File(imagePath));
      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      logger.e('Error uploading image: $e');
      return '';
    }
  }

  Future<void> updateUser(
    String companyId,
    Map<String, dynamic> personalInfo,
    Map<String, dynamic> salaryHistory,
    Map<String, dynamic> bankHistory,
  ) async {
    try {
      // Reference to the user document
      DocumentReference userDocRef = usersCollection.doc(companyId);

      // Use companyId as the document ID
      await userDocRef.update(personalInfo);

      // Reference to the salaryHistory subcollection
      CollectionReference salaryHistoryCollection =
          userDocRef.collection('salaryHistory');

      // Add a new document to the salaryHistory subcollection
      await salaryHistoryCollection.add(salaryHistory);

      // Reference to the bankHistory subcollection
      CollectionReference bankHistoryCollection =
          userDocRef.collection('bankHistory');

      // Add a new document to the bankHistory subcollection
      await bankHistoryCollection.add(bankHistory);
    } catch (e) {
      // Handle errors as needed
      print('Error updating user: $e');
      rethrow; // Rethrow the exception for the calling code to handle
    }
  }

  Future<bool> checkDuplicateEmail(String email) async {
    // Query the "users" collection to check if the email already exists
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    // If there are documents in the query result, the email already exists
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> updatePassword(String companyId, String newPassword) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(companyId)
          .update({'password': newPassword});

      logger.i('Password updated successfully for companyId: $companyId');
    } catch (e) {
      logger.e('Error updating password: $e');
      // Handle the error as needed
    }
  }

  Future<void> deactivateStatus(String companyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(companyId)
          .update({'status': false});

      logger.i('Status updated successfully for companyId: $companyId');
    } catch (e) {
      logger.e('Error updating status: $e');
      // Handle the error as needed
    }
  }

  Future<void> activateStatus(String companyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(companyId)
          .update({'status': true});

      logger.i('Status activated successfully for companyId: $companyId');
    } catch (e) {
      logger.e('Error updating status: $e');
      // Handle the error as needed
    }
  }

  Future<String> getUserPasswordByEmail(String email) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> userData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;

        final String? password = userData['password'];

        if (password != null) {
          return password;
        } else {
          // Return an empty string or a default value
          return ''; // You can change this to your desired default value
        }
      } else {
        // Return an empty string or a default value
        return ''; // You can change this to your desired default value
      }
    } catch (e) {
      logger.e('Error fetching user password by email: $e');
      // Handle the error as needed
      throw Exception('Error fetching user password by email');
    }
  }

  Future<String> getUserProfileImage(String companyId) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users') // Update the collection name as needed
          .where('companyId', isEqualTo: companyId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> companyData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;

        final String? profileImage = companyData['image'];

        if (profileImage != null) {
          return profileImage;
        } else {
          // Return an empty string or a default image URL
          return ''; // You can change this to your desired default value
        }
      } else {
        // Return an empty string or a default image URL
        return ''; // You can change this to your desired default value
      }
    } catch (e) {
      logger.e('Error fetching user profile image by companyId: $e');
      // Handle the error as needed
      throw Exception('Error fetching user profile image by companyId');
    }
  }

  Future<String> getNameByCompanyId(String companyId) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> userData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;

        final String? name = userData['name'];
        logger.i('name get by companyId: $name');
        if (name != null) {
          return name;
        } else {
          // Return an empty string or a default value
          return 'Worker'; // You can change this to your desired default value
        }
      } else {
        // Return an empty string or a default value
        return 'Worker'; // You can change this to your desired default value
      }
    } catch (e) {
      logger.e('Error fetching company name by companyId: $e');
      // Handle the error as needed
      throw Exception('Error fetching company name by companyId');
    }
  }

  Future<String?> getManagerPassword() async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('position', isEqualTo: 'Manager')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs[0].data() as Map<String, dynamic>;
        logger.i('manager password ${userData}');
        return userData['password'] as String?;
      } else {
        logger.w('Manager not found');
        return null;
      }
    } catch (e) {
      logger.e('Error fetching manager password: $e');
      return null;
    }
  }

  Future<void> updateAnnualLeaveBalance() async {
    try {
      // Fetch all user documents
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Iterate over the user documents
      for (var userDoc in querySnapshot.docs) {
        // Check if the 'annualLeaveBalance' field exists in the document data
        final Map<String, dynamic> userData =
            userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('annualLeaveBalance')) {
          // Update the 'annualLeaveBalance' field to 10 for each user
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .update({'annualLeaveBalance': 10});
        } else {
          // If the field doesn't exist, create it and set it to 10
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .set({'annualLeaveBalance': 10}, SetOptions(merge: true));

          logger.i(
              'Created annualLeaveBalance for user ${userDoc.id} and set it to 10');
        }
      }

      logger.i('Annual Leave Balance updated successfully for all users');
    } catch (e) {
      logger.e('Error updating Annual Leave Balance: $e');
      // Handle the error as needed
    }
  }
}
