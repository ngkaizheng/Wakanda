import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/data/data_model.dart';
import 'package:flutter_application_1/leave/CheckpendingLeave.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //for getting announcement data by Lew1
// import 'package:intl/intl.dart'; //for announcement timestamp by Lew2

class processFullLeave extends StatefulWidget {
  final String companyId;
  final String userPosition;
  final List<dynamic> userNameList;

  processFullLeave({
    Key? key,
    required this.companyId,
    required this.userPosition,
    required this.userNameList,
  }) : super(key: key);

  @override
  _processFullLeave createState() => _processFullLeave();
}

// ignore: must_be_immutable
class _processFullLeave extends State<processFullLeave> {
  final logger = Logger();

  String companyId = '';
  String name = '';
  String leaveType = '';
  String fullORHalf = '';
  String? startDate;
  String? endDate;
  double leaveDay = 0;
  String reason = '';
  String remark = '';
  String documentId = '';
  int? annualLeaveBalance;
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Access widget properties in initState
    final Map<String, dynamic> user = widget.userNameList[0];

    companyId = user['companyId']?.toString() ?? '';
    name = user['name']?.toString() ?? '';
    leaveType = user['leaveType']?.toString() ?? '';
    fullORHalf = user['fullORHalf']?.toString() ?? '';
    documentId = user['documentId']?.toString() ?? '';

    // Check if 'startDate' and 'endDate' are not null before converting
    startDate = user['startDate']?.toString() ?? '';
    endDate = user['endDate']?.toString() ?? '';

    // Ensure 'leaveDay' is a double or can be converted to double
    leaveDay = (user['leaveDay'] as num?)?.toDouble() ?? 0.0;

    reason = user['reason']?.toString() ?? '';
    remark = user['remark']?.toString() ?? '';

    fetchUserData(companyId);
  }

  Future<int> getLatestLeaveAnnouncementNumber(String companyId) async {
    //By Lew3
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('announcements').get();

      int latestNumber = 0;

      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        String documentId = document.id;
        if (documentId.startsWith('Leave_Announcement_$companyId')) {
          // Extract the announcement number
          int number = int.tryParse(documentId.split('_').last) ?? 0;
          if (number > latestNumber) {
            latestNumber = number;
          }
        }
      }
      return latestNumber;
    } catch (e) {
      print('Error fetching latest announcement number: $e');
      return 0;
    }
  }

  Future<void> _postLeaveAnnouncement(
      String title, String content, String companyId) async {
    try {
      DateTime now = DateTime.now();
      int latestAnnouncementNumber =
          await getLatestLeaveAnnouncementNumber(companyId);
      String documentId =
          'Leave_Announcement_${companyId}_${latestAnnouncementNumber + 1}';

      // Add the announcement to Firebase Firestore
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(documentId)
          .set({
        'title': title,
        'content': content,
        'timestamp': now,
        'Read_by_${widget.companyId}': false,
        'visible_to': [companyId], // Set visible status for the current user
        'announcementType': 'Leave',
      });
    } catch (e) {
      print("Error posting announcement: $e");
      // Handle error if needed
    } //Until here Lew2
  }

  Future<void> _updateLeaveStatus(
      companyId, documentId, status, balance) async {
    await LeaveModel()
        .updateLeaveStatusAndBalance(companyId, documentId, status, balance);

    // ignore: use_build_context_synchronously
    Navigator.pop(
      context,
      MaterialPageRoute(
          builder: (context) => CheckPendingLeave(
                companyId: widget.companyId,
                userPosition: widget.userPosition,
              )),
    );
  }

  Future<void> fetchUserData(companyId) async {
    try {
      final userData = await LeaveModel().getUserData(companyId);

      // ignore: unnecessary_null_comparison
      if (userData != null) {
        setState(() {
          annualLeaveBalance = userData['annualLeaveBalance'] ?? '';
          isDataLoaded = true;
        });
      }
    } catch (e) {
      logger.e('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 224, 45, 255),
          title: Text(
            '$name',
            style: TextStyle(
              color: Colors.black87, // Adjust text color for modern style
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: const Text(
                    "Leave Type",
                    style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 224, 45, 255),
                        fontWeight: FontWeight.bold),
                  ),
                ),

                Container(
                  height: 42,
                  width: 150,
                  // margin: const EdgeInsets.symmetric(
                  //     horizontal: 10.0, vertical: 8.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 224, 45, 255),
                        const Color.fromARGB(255, 224, 165, 235),
                        Color.fromARGB(255, 224, 45, 255),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      leaveType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: const Text(
                    "Full/Half",
                    style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 224, 45, 255),
                        fontWeight: FontWeight.bold),
                  ),
                ),

                Container(
                  height: 42,
                  width: 150,
                  // margin: const EdgeInsets.symmetric(
                  //     horizontal: 10.0, vertical: 8.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 224, 45, 255),
                        const Color.fromARGB(255, 224, 165, 235),
                        Color.fromARGB(255, 224, 45, 255),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      fullORHalf,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (fullORHalf == 'Full')
                  // Balance Leaves
                  Container(
                    margin: const EdgeInsets.fromLTRB(35, 20, 35, 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text(
                          'Balance Annual',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 224, 45, 255),
                          ),
                        ),
                        Container(
                          width: 150, // Set the width as per your requirement
                          height: 40, // Set the height as per your requirement
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 238, 238, 238),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: isDataLoaded
                              ? Center(
                                  child: Text(
                                    '${annualLeaveBalance ?? "N/A"}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                    ' ', // or any other loading message
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                // Start Date
                Container(
                  margin: const EdgeInsets.fromLTRB(35, 10, 35, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        'Start Date          ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 224, 45, 255),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Center(
                          child: Text(
                            '$startDate',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (fullORHalf == 'Full')
                  // End Date
                  Container(
                    margin: const EdgeInsets.fromLTRB(35, 10, 35, 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text(
                          'End Date          ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 224, 45, 255),
                          ),
                        ),
                        Container(
                          width: 150,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 238, 238, 238),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Center(
                            child: Text(
                              '$endDate',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Leave Days
                Container(
                  margin: const EdgeInsets.fromLTRB(35, 10, 35, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        'Leave Days      ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 224, 45, 255),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Center(
                          // margin: const EdgeInsets.symmetric(
                          //     horizontal: 35, vertical: 10),
                          child: Text(
                            '$leaveDay',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Reasons
                Container(
                  margin: const EdgeInsets.fromLTRB(35, 10, 35, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        'Reason              ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 224, 45, 255),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 10, 0, 10),
                          child: Text(
                            '$reason',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //Remark
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.fromLTRB(55, 10, 10, 20),
                  child: const Text(
                    'Remarks',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 224, 45, 255),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: 300,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 238, 238, 238),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        remark,
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Approve
                      ElevatedButton(
                        onPressed: () {
                          logger.i('Approve');
                          if (leaveType == 'Annual') {
                            annualLeaveBalance =
                                (annualLeaveBalance! - leaveDay).toInt();
                          }
                          _updateLeaveStatus(companyId, documentId, 'Approved',
                              annualLeaveBalance);
                          String announcementTitle = 'Leave Approved'; //By Lew4
                          if (leaveType == "Annual") {
                            String announcementContent =
                                'Your $leaveType leave on $startDate until $endDate has been approved';
                            _postLeaveAnnouncement(announcementTitle,
                                announcementContent, companyId);
                          } else if (leaveType == "Unpaid") {
                            String announcementContent =
                                'Your $leaveType leave on $startDate until $endDate has been approved';
                            _postLeaveAnnouncement(announcementTitle,
                                announcementContent, companyId);
                          } //Until Here Lew3
                        },
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20.0), // Set the corner radius
                            ),
                          ),
                          fixedSize: MaterialStateProperty.all<Size>(
                            const Size(130, 40), // Set the width and height
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 48, 197,
                                53), // Set the background color to blue
                          ),
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 17, // Set the font size
                            fontWeight: FontWeight.bold, // Set the font weight
                            color: Colors.white, // Set the font color
                          ),
                        ),
                      ),

                      const SizedBox(width: 30),

                      //Reject
                      ElevatedButton(
                        onPressed: () {
                          logger.i('Rejected');
                          _updateLeaveStatus(companyId, documentId, 'Rejected',
                              annualLeaveBalance);
                          String announcementTitle = 'Leave Rejected'; //By Lew4
                          if (leaveType == "Annual") {
                            String announcementContent =
                                'Your $leaveType leave on $startDate until $endDate has been rejected';
                            _postLeaveAnnouncement(announcementTitle,
                                announcementContent, companyId);
                          } else if (leaveType == "Unpaid") {
                            String announcementContent =
                                'Your $leaveType leave on $startDate until $endDate has been rejected';
                            _postLeaveAnnouncement(announcementTitle,
                                announcementContent, companyId);
                          } //Until Here Lew4
                        },
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20.0), // Set the corner radius
                            ),
                          ),
                          fixedSize: MaterialStateProperty.all<Size>(
                            const Size(130, 40), // Set the width and height
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 244, 82,
                                70), // Set the background color to blue
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 17, // Set the font size
                            fontWeight: FontWeight.bold, // Set the font weight
                            color: Colors.white, // Set the font color
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
