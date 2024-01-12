import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class LeaveModel {
  final logger = Logger();

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

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> createLeave(
      String companyId, Map<String, dynamic> leaveInfo) async {
    try {
      // companyId = 'PF0014';
      DocumentReference userDocRef = usersCollection.doc(companyId);

      // Reference to the leaveHistory subcollection
      CollectionReference leaveHistoryCollection =
          userDocRef.collection('leaveHistory');

      // Add a new document to the salaryHistory subcollection
      await leaveHistoryCollection.add(leaveInfo);
      logger.i('successful run');
    } catch (e) {
      // Handle errors as needed
      logger.i('Error creating user: $e');
      rethrow; // Rethrow the exception for the calling code to handle
    }
  }

  //Create claim
  Future<void> createClaim(
      String companyId, Map<String, dynamic> claimInfo) async {
    try {
      // companyId = 'PF0014';
      DocumentReference userDocRef = usersCollection.doc(companyId);

      // Reference to the leaveHistory subcollection
      CollectionReference claimHistoryCollection =
          userDocRef.collection('claimHistory');

      // Add a new document to the salaryHistory subcollection
      await claimHistoryCollection.add(claimInfo);
      logger.i('successful run');
    } catch (e) {
      // Handle errors as needed
      logger.i('Error creating user: $e');
      rethrow; // Rethrow the exception for the calling code to handle
    }
  }

  Future<Map<String, dynamic>> getUserData(String companyId) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs[0].data() as Map<String, dynamic>;

        return userData;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  //All Leave Query for specific user by lew1
  Future<List<Map<String, dynamic>>> getLeaveDataForUser(
      String paraCompanyId) async {
    try {
      final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: paraCompanyId)
          .limit(1)
          .get();

      final List<Map<String, dynamic>> usersWithLeave = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String companyId = userData['companyId'];

        // Fetch the 'leaveHistory' subcollection for specific user
        final QuerySnapshot leaveHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('leaveHistory')
            .get();

        final List<Map<String, dynamic>> leaveRecords =
            leaveHistorySnapshot.docs.map((leaveDoc) {
          final Map<String, dynamic> leaveData =
              leaveDoc.data() as Map<String, dynamic>;

          final Timestamp timestamp = leaveData['startDate'];
          final DateTime startDate = timestamp.toDate();
          final Timestamp? timestamp1 =
              leaveData.containsKey('endDate') ? leaveData['endDate'] : null;
          final DateTime? endDate = timestamp1?.toDate();
          final String leaveType = leaveData['leaveType'] ?? '';
          final double leaveDay = leaveData['leaveDay'] ?? '';
          final String reason = leaveData['reason'] ?? '';
          final String remark = leaveData['remark'] ?? '';
          final String fullORHalf = leaveData['fullORHalf'] ?? '';
          final String status = leaveData['status'];

          leaveData['startDate'] = startDate;
          leaveData['endDate'] = endDate;
          leaveData['leaveType'] = leaveType;
          leaveData['leaveDay'] = leaveDay;
          leaveData['reason'] = reason;
          leaveData['remark'] = remark;
          leaveData['fullORHalf'] = fullORHalf;
          leaveData['status'] = status;

          // Preserve user data in the leave record
          leaveData['userData'] = userData;

          return leaveData;
        }).toList();

        logger.i('leaveHistorySnapshot $leaveRecords');

        usersWithLeave.addAll(leaveRecords);
      }

      return usersWithLeave;
    } catch (e) {
      logger.e('Error fetching users withleave: $e');
      return [];
    }
  }
  //Until here Lew1

  //Pending Leave Query
  Future<List<Map<String, dynamic>>> getUsersWithPendingLeave() async {
    try {
      final QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> usersWithPendingLeave = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String companyId = userData['companyId'];

        // Fetch the 'leaveHistory' subcollection for each user with 'pending' status
        final QuerySnapshot leaveHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('leaveHistory')
            .where('status', isEqualTo: 'pending')
            .get();

        final List<Map<String, dynamic>> pendingLeaveRecords =
            leaveHistorySnapshot.docs.map((leaveDoc) {
          final Map<String, dynamic> leaveData =
              leaveDoc.data() as Map<String, dynamic>;

          final Timestamp timestamp = leaveData['startDate'];
          final DateTime startDate = timestamp.toDate();
          final Timestamp? timestamp1 =
              leaveData.containsKey('endDate') ? leaveData['endDate'] : null;
          final DateTime? endDate = timestamp1?.toDate();
          final String leaveType = leaveData['leaveType'] ?? '';
          final double leaveDay = leaveData['leaveDay'] ?? '';
          final String reason = leaveData['reason'] ?? '';
          final String remark = leaveData['remark'] ?? '';
          final String fullORHalf = leaveData['fullORHalf'] ?? '';

          leaveData['startDate'] = startDate;
          leaveData['endDate'] = endDate;
          leaveData['leaveType'] = leaveType;
          leaveData['leaveDay'] = leaveDay;
          leaveData['reason'] = reason;
          leaveData['remark'] = remark;
          leaveData['fullORHalf'] = fullORHalf;

          // Preserve user data in the leave record
          leaveData['userData'] = userData;

          // Add the document ID to the leaveData
          leaveData['documentId'] = leaveDoc.id;

          return leaveData;
        }).toList();

        usersWithPendingLeave.addAll(pendingLeaveRecords);
      }

      return usersWithPendingLeave;
    } catch (e) {
      logger.e('Error fetching users with pending leave: $e');
      return [];
    }
  }

  //Approved Leave Query
  Future<List<Map<String, dynamic>>> getUsersWithApprovedLeave() async {
    try {
      final QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> usersWithPendingLeave = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String companyId = userData['companyId'];

        // Fetch the 'leaveHistory' subcollection for each user with 'Approved' status
        final QuerySnapshot leaveHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('leaveHistory')
            .where('status', isEqualTo: 'Approved')
            .get();

        final List<Map<String, dynamic>> pendingLeaveRecords =
            leaveHistorySnapshot.docs.map((leaveDoc) {
          final Map<String, dynamic> leaveData =
              leaveDoc.data() as Map<String, dynamic>;

          final Timestamp timestamp = leaveData['startDate'];
          final DateTime startDate = timestamp.toDate();
          final Timestamp? timestamp1 =
              leaveData.containsKey('endDate') ? leaveData['endDate'] : null;
          final DateTime? endDate = timestamp1?.toDate();
          final String leaveType = leaveData['leaveType'] ?? '';
          final double leaveDay = leaveData['leaveDay'] ?? '';
          final String reason = leaveData['reason'] ?? '';
          final String remark = leaveData['remark'] ?? '';
          final String fullORHalf = leaveData['fullORHalf'] ?? '';

          leaveData['startDate'] = startDate;
          leaveData['endDate'] = endDate;
          leaveData['leaveType'] = leaveType;
          leaveData['leaveDay'] = leaveDay;
          leaveData['reason'] = reason;
          leaveData['remark'] = remark;
          leaveData['fullORHalf'] = fullORHalf;

          // Preserve user data in the leave record
          leaveData['userData'] = userData;

          // Add the document ID to the leaveData
          leaveData['documentId'] = leaveDoc.id;

          return leaveData;
        }).toList();

        usersWithPendingLeave.addAll(pendingLeaveRecords);
      }
      return usersWithPendingLeave;
    } catch (e) {
      logger.e('Error fetching users with pending leave: $e');
      return [];
    }
  }

  //Rejected Leave Query
  Future<List<Map<String, dynamic>>> getUsersWithRejectedLeave() async {
    try {
      final QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> usersWithPendingLeave = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String companyId = userData['companyId'];

        // Fetch the 'leaveHistory' subcollection for each user with 'Rejected' status
        final QuerySnapshot leaveHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('leaveHistory')
            .where('status', isEqualTo: 'Rejected')
            .get();

        final List<Map<String, dynamic>> pendingLeaveRecords =
            leaveHistorySnapshot.docs.map((leaveDoc) {
          final Map<String, dynamic> leaveData =
              leaveDoc.data() as Map<String, dynamic>;

          final Timestamp timestamp = leaveData['startDate'];
          final DateTime startDate = timestamp.toDate();
          final Timestamp? timestamp1 =
              leaveData.containsKey('endDate') ? leaveData['endDate'] : null;
          final DateTime? endDate = timestamp1?.toDate();
          final String leaveType = leaveData['leaveType'] ?? '';
          final double leaveDay = leaveData['leaveDay'] ?? '';
          final String reason = leaveData['reason'] ?? '';
          final String remark = leaveData['remark'] ?? '';
          final String fullORHalf = leaveData['fullORHalf'] ?? '';

          leaveData['startDate'] = startDate;
          leaveData['endDate'] = endDate;
          leaveData['leaveType'] = leaveType;
          leaveData['leaveDay'] = leaveDay;
          leaveData['reason'] = reason;
          leaveData['remark'] = remark;
          leaveData['fullORHalf'] = fullORHalf;

          // Preserve user data in the leave record
          leaveData['userData'] = userData;

          // Add the document ID to the leaveData
          leaveData['documentId'] = leaveDoc.id;

          return leaveData;
        }).toList();

        usersWithPendingLeave.addAll(pendingLeaveRecords);
      }
      return usersWithPendingLeave;
    } catch (e) {
      logger.e('Error fetching users with pending leave: $e');
      return [];
    }
  }

  Future<void> updateLeaveStatusAndBalance(String companyId, String documentId,
      String status, int newBalance) async {
    try {
      // Reference to the user document
      DocumentReference userDocRef = usersCollection.doc(companyId);

      // Reference to the leaveHistory subcollection
      CollectionReference leaveHistoryCollection =
          userDocRef.collection('leaveHistory');

      // Reference to the specific document in the leaveHistory subcollection
      DocumentReference leaveDocRef = leaveHistoryCollection.doc(documentId);

      // Update the status field in leave history
      await leaveDocRef.update({
        'status': status,
      });

      // Update the annualLeaveBalance directly in the user document
      await userDocRef.update({
        'annualLeaveBalance': newBalance,
      });
    } catch (e) {
      // Handle errors as needed
      logger.i('updateFail');
      rethrow; // Rethrow the exception for the calling code to handle
    }
  }

  //All claim Query for specific user by lew2
  Future<List<Map<String, dynamic>>> getClaimDataForUser(
      String paraCompanyId) async {
    try {
      final QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: paraCompanyId)
          .limit(1)
          .get();

      final List<Map<String, dynamic>> usersWithClaim = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String companyId = userData['companyId'];

        // Fetch the 'claimHistory' subcollection for specific user
        final QuerySnapshot claimHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection(
                'claimHistory') //subcollection: claimHistory from collection: users
            .get();

        final List<Map<String, dynamic>> claimRecords =
            claimHistorySnapshot.docs.map((claimDoc) {
          final Map<String, dynamic> claimData =
              claimDoc.data() as Map<String, dynamic>;

          final Timestamp timestamp = claimData['claimDate'];
          final DateTime claimDate = timestamp.toDate();
          final String claimType = claimData['claimType'] ?? '';
          final double claimAmount = claimData['claimAmount'] ?? '';
          final String remark = claimData['remark'] ?? '';
          final String imageURL = claimData['image'] ?? '';

          claimData['claimDate'] = claimDate;
          claimData['claimType'] = claimType;
          claimData['claimAmount'] = claimAmount;
          claimData['remark'] = remark;
          claimData['imageURL'] = imageURL;

          // Preserve user data in the claim record
          claimData['userData'] = userData;

          return claimData;
        }).toList();

        usersWithClaim.addAll(claimRecords);
      }

      return usersWithClaim;
    } catch (e) {
      logger.e('Error fetching users with claim: $e');
      return [];
    }
  }
  //Until here Lew2

  //Pending Claim Query
  Future<List<Map<String, dynamic>>> getUsersWithPendingClaim() async {
    try {
      final QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> usersWithPendingLeave = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String companyId = userData['companyId'];

        // Fetch the 'leaveHistory' subcollection for each user with 'pending' status
        final QuerySnapshot claimHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('claimHistory')
            .where('status', isEqualTo: 'pending')
            .get();

        final List<Map<String, dynamic>> pendingClaimRecords =
            claimHistorySnapshot.docs.map((claimDoc) {
          final Map<String, dynamic> claimData =
              claimDoc.data() as Map<String, dynamic>;

          final Timestamp timestamp = claimData['claimDate'];
          final DateTime claimDate = timestamp.toDate();
          final String claimType = claimData['claimType'] ?? '';
          final double claimAmount = claimData['claimAmount'] ?? '';
          final String remark = claimData['remark'] ?? '';
          final String imageURL = claimData['image'] ?? '';

          claimData['claimDate'] = claimDate;
          claimData['claimType'] = claimType;
          claimData['claimAmount'] = claimAmount;
          claimData['remark'] = remark;
          claimData['imageURL'] = imageURL;

          // Preserve user data in the claim record
          claimData['userData'] = userData;

          // Add the document ID to the leaveData
          claimData['documentId'] = claimDoc.id;

          return claimData;
        }).toList();

        usersWithPendingLeave.addAll(pendingClaimRecords);
      }

      return usersWithPendingLeave;
    } catch (e) {
      logger.e('Error fetching users with pending leave: $e');
      return [];
    }
  }

  //Approved Claim Query
  Future<List<Map<String, dynamic>>> getUsersWithApprovedClaim() async {
    try {
      final QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> usersWithApprovedLeave = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String companyId = userData['companyId'];

        // Fetch the 'leaveHistory' subcollection for each user with 'pending' status
        final QuerySnapshot claimHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('claimHistory')
            .where('status', isEqualTo: 'Approved')
            .get();

        final List<Map<String, dynamic>> approvedClaimRecords =
            claimHistorySnapshot.docs.map((claimDoc) {
          final Map<String, dynamic> claimData =
              claimDoc.data() as Map<String, dynamic>;

          final Timestamp timestamp = claimData['claimDate'];
          final DateTime claimDate = timestamp.toDate();
          final String claimType = claimData['claimType'] ?? '';
          final double claimAmount = claimData['claimAmount'] ?? '';
          final String remark = claimData['remark'] ?? '';
          final String imageURL = claimData['image'] ?? '';

          claimData['claimDate'] = claimDate;
          claimData['claimType'] = claimType;
          claimData['claimAmount'] = claimAmount;
          claimData['remark'] = remark;
          claimData['imageURL'] = imageURL;

          // Preserve user data in the leave record
          claimData['userData'] = userData;

          // Add the document ID to the leaveData
          claimData['documentId'] = claimDoc.id;

          return claimData;
        }).toList();

        usersWithApprovedLeave.addAll(approvedClaimRecords);
      }

      return usersWithApprovedLeave;
    } catch (e) {
      logger.e('Error fetching users with pending leave: $e');
      return [];
    }
  }

  //Rejected Claim Query
  Future<List<Map<String, dynamic>>> getUsersWithRejectedClaim() async {
    try {
      final QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> usersWithRejectedLeave = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String companyId = userData['companyId'];

        // Fetch the 'leaveHistory' subcollection for each user with 'pending' status
        final QuerySnapshot claimHistorySnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(companyId)
            .collection('claimHistory')
            .where('status', isEqualTo: 'Rejected')
            .get();

        final List<Map<String, dynamic>> rejectdClaimRecords =
            claimHistorySnapshot.docs.map((claimDoc) {
          final Map<String, dynamic> claimData =
              claimDoc.data() as Map<String, dynamic>;

          final Timestamp timestamp = claimData['claimDate'];
          final DateTime claimDate = timestamp.toDate();
          final String claimType = claimData['claimType'] ?? '';
          final double claimAmount = claimData['claimAmount'] ?? '';
          final String remark = claimData['remark'] ?? '';
          final String imageURL = claimData['image'] ?? '';

          claimData['claimDate'] = claimDate;
          claimData['claimType'] = claimType;
          claimData['claimAmount'] = claimAmount;
          claimData['remark'] = remark;
          claimData['imageURL'] = imageURL;

          // Preserve user data in the leave record
          claimData['userData'] = userData;

          // Add the document ID to the leaveData
          claimData['documentId'] = claimDoc.id;

          return claimData;
        }).toList();

        usersWithRejectedLeave.addAll(rejectdClaimRecords);
      }

      return usersWithRejectedLeave;
    } catch (e) {
      logger.e('Error fetching users with pending leave: $e');
      return [];
    }
  }

  Future<void> updateClaimStatusAndBalance(
      String companyId, String documentId, String status) async {
    try {
      // Reference to the user document
      DocumentReference userDocRef = usersCollection.doc(companyId);

      // Reference to the claimHistory subcollection
      CollectionReference claimHistoryCollection =
          userDocRef.collection('claimHistory');

      // Reference to the specific document in the leaveHistory subcollection
      DocumentReference claimDocRef = claimHistoryCollection.doc(documentId);

      // Update the status field in leave history
      await claimDocRef.update({
        'status': status,
      });
    } catch (e) {
      // Handle errors as needed
      logger.i('updateFail');
      rethrow; // Rethrow the exception for the calling code to handle
    }
  }
}
