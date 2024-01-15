import 'package:flutter/material.dart';
import 'package:flutter_application_1/main_page.dart';
import 'package:flutter_application_1/data/data_model.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/leave/Apply_FullLeave_page.dart';

class LeavePage extends StatefulWidget {
  final String userPosition;
  final String companyId; // Unique user ID

  LeavePage({Key? key, required this.userPosition, required this.companyId})
      : super(key: key);

  @override
  _LeavePageState createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final logger = Logger();
  String currentCategory = 'Pending';
  late String companyId;
  List<dynamic> pendingLeaveList = [];
  List<dynamic> approvedLeaveList = [];
  List<dynamic> rejectedLeaveList = [];
  @override
  void initState() {
    super.initState();
    companyId = widget.companyId;

    // Fetch user data when the page is initialized
    fetchSpecificUsersWithLeaveHistory();
  }

  Future<void> fetchSpecificUsersWithLeaveHistory() async {
    try {
      final List<Map<String, dynamic>> specificUsersData =
          await LeaveModel().getLeaveDataForUser(companyId);

      setState(() {
        if (specificUsersData.isNotEmpty) {
          //Pending list Data
          pendingLeaveList = specificUsersData
              .where((user) => user['status'] == 'pending')
              .map((user) {
            return {
              'name': user['userData']['name'].toString(),
              'leaveType': user['leaveType'].toString(),
              'leaveDay': user['leaveDay'] as num,
              'startDate':
                  "${user['startDate'].year}-${user['startDate'].month}-${user['startDate'].day}",
              if (user['fullORHalf'] == 'Full')
                'endDate':
                    "${user['endDate'].year}-${user['endDate'].month}-${user['endDate'].day}",
              'fullORHalf': user['fullORHalf'].toString(),
              "reason": user['reason'].toString(),
              "documentId": user['documentId'].toString(),
              "remark": user['remark'].toString(),
              "status": user['status'].toString(),
            };
          }).toList();
          // Sort pendingLeaveList by 'startDate'
          pendingLeaveList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['startDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['startDate']))));

          //Approved list data
          approvedLeaveList = specificUsersData
              .where((user) => user['status'] == 'Approved')
              .map((user) {
            return {
              'name': user['userData']['name'].toString(),
              'leaveType': user['leaveType'].toString(),
              'leaveDay': user['leaveDay'] as num,
              'startDate':
                  "${user['startDate'].year}-${user['startDate'].month}-${user['startDate'].day}",
              if (user['fullORHalf'] == 'Full')
                'endDate':
                    "${user['endDate'].year}-${user['endDate'].month}-${user['endDate'].day}",
              'fullORHalf': user['fullORHalf'].toString(),
              "reason": user['reason'].toString(),
              "documentId": user['documentId'].toString(),
              "remark": user['remark'].toString(),
              "status": user['status'].toString(),
            };
          }).toList();
          // Sort approvedLeaveList by 'startDate'
          approvedLeaveList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['startDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['startDate']))));

          //Rejected list data
          rejectedLeaveList = specificUsersData
              .where((user) => user['status'] == 'Rejected')
              .map((user) {
            return {
              'name': user['userData']['name'].toString(),
              'leaveType': user['leaveType'].toString(),
              'leaveDay': user['leaveDay'] as num,
              'startDate':
                  "${user['startDate'].year}-${user['startDate'].month}-${user['startDate'].day}",
              if (user['fullORHalf'] == 'Full')
                'endDate':
                    "${user['endDate'].year}-${user['endDate'].month}-${user['endDate'].day}",
              'fullORHalf': user['fullORHalf'].toString(),
              "reason": user['reason'].toString(),
              "documentId": user['documentId'].toString(),
              "remark": user['remark'].toString(),
              "status": user['status'].toString(),
            };
          }).toList();
          // Sort rejectedLeaveList by 'startDate'
          rejectedLeaveList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['startDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['startDate']))));
        }
      });
    } catch (e) {
      logger.e('Error fetching user with leave history: $e');
    }
  }

  String _formatDateString(String dateString) {
    // Ensure that the date string has leading zeros in month and day
    final parts = dateString.split('-');
    if (parts.length == 3) {
      return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
    }
    return dateString;
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> currentLeaveList = [];
    if (currentCategory == 'Pending') {
      currentLeaveList = pendingLeaveList;
    } else if (currentCategory == 'Approved') {
      currentLeaveList = approvedLeaveList;
    } else if (currentCategory == 'Rejected') {
      currentLeaveList = rejectedLeaveList;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 224, 45, 255),
        title: const Text(
          'Leave',
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(
                  companyId: widget.companyId,
                  userPosition: widget.userPosition,
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplyLeave(
                    companyId: widget.companyId,
                    userPosition: widget.userPosition,
                  ),
                ),
              ).then((result) {
                // This code will be executed when the ApplyLeave route is popped
                if (result != null && result is bool && result) {
                  // Assuming you have a boolean result to indicate if leave was applied
                  setState(() {
                    fetchSpecificUsersWithLeaveHistory();
                  });
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: currentCategory == 'Approved'
                          ? LinearGradient(
                              colors: [
                                Color.fromARGB(255, 224, 45, 255),
                                const Color.fromARGB(255, 224, 165, 235),
                                Color.fromARGB(255, 224, 45, 255),
                              ],
                            )
                          : null, // Set to null if not 'Approved'
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        bottomLeft: Radius.circular(20.0),
                      ),
                      border: Border.all(
                        color: Color.fromARGB(255, 224, 45, 255),
                        width: 1.0,
                      ),
                    ),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 43),
                          backgroundColor: currentCategory == 'Approved'
                              ? Colors.transparent
                              : Colors.transparent,
                          foregroundColor: currentCategory == 'Approved'
                              ? Colors.white
                              : const Color.fromARGB(255, 224, 45, 255),
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              bottomLeft: Radius.circular(20.0),
                            ),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            currentCategory = 'Approved';
                          });
                        },
                        child: const Text(
                          'Approved',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ))),
                DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: currentCategory == 'Pending'
                          ? LinearGradient(
                              colors: [
                                Color.fromARGB(255, 224, 45, 255),
                                const Color.fromARGB(255, 224, 165, 235),
                                Color.fromARGB(255, 224, 45, 255),
                              ],
                            )
                          : null, // Set to null if not 'Pending'
                      border: Border(
                        top: BorderSide(
                            width: 1.0,
                            color: Color.fromARGB(255, 224, 45, 255)),
                        bottom: BorderSide(
                            width: 1.0,
                            color: Color.fromARGB(255, 224, 45, 255)),
                        left: BorderSide.none,
                        right: BorderSide.none,
                      ),
                    ),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 43),
                          backgroundColor: currentCategory == 'Pending'
                              ? Colors.transparent
                              : Colors.transparent,
                          foregroundColor: currentCategory == 'Pending'
                              ? Colors.white
                              : const Color.fromARGB(255, 224, 45, 255),
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            currentCategory = 'Pending';
                          });
                        },
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ))),
                DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: currentCategory == 'Rejected'
                          ? LinearGradient(
                              colors: [
                                Color.fromARGB(255, 224, 45, 255),
                                const Color.fromARGB(255, 224, 165, 235),
                                Color.fromARGB(255, 224, 45, 255),
                              ],
                            )
                          : null, // Set to null if not 'Rejected'
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                      border: Border.all(
                        color: Color.fromARGB(255, 224, 45, 255),
                        width: 1.0,
                      ),
                    ),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 43),
                          backgroundColor: currentCategory == 'Rejected'
                              ? Colors.transparent
                              : Colors.transparent,
                          foregroundColor: currentCategory == 'Rejected'
                              ? Colors.white
                              : const Color.fromARGB(255, 224, 45, 255),
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20.0),
                              bottomRight: Radius.circular(20.0),
                            ),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            currentCategory = 'Rejected';
                          });
                        },
                        child: const Text(
                          'Rejected',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currentLeaveList.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(
                      left: 5, right: 5, top: 5, bottom: 5),
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      height: 170,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 8.0),
                      padding: const EdgeInsets.all(4.0),
                      child: ListTile(
                        title: Text(
                          currentLeaveList[index]['name'],
                          style: const TextStyle(
                            color: Color.fromARGB(255, 224, 45, 255),
                            fontSize: 21.0, // or your preferred font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            const Text(
                              'Leave Type:',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0, // or your preferred font size
                                fontWeight: FontWeight.bold,
                              ), // Set label color
                            ),
                            Text(
                              '${currentLeaveList[index]['leaveType']}',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 224, 45, 255),
                                fontSize: 16.0, // or your preferred font size
                                fontWeight: FontWeight.bold,
                              ), // Set data color
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.002,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Days:',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${currentLeaveList[index]['leaveDay']}',
                                      style: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 224, 45, 255),
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.07,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment
                                        .start, // Add this line

                                    children: [
                                      const Text(
                                        'Date:',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${currentLeaveList[index]['startDate']}',
                                        style: const TextStyle(
                                          color:
                                              Color.fromARGB(255, 224, 45, 255),
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Center(
                                            child: Text('Leave Details'),
                                          ),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Type: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentLeaveList[index]['leaveType']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Full/Half: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentLeaveList[index]['fullORHalf']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Start Date: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentLeaveList[index]['startDate']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'End Date: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentLeaveList[index]['endDate']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Leave Days: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentLeaveList[index]['leaveDay']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Reason: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentLeaveList[index]['reason']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Remark: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentLeaveList[index]['remark']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Status: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentLeaveList[index]['status']}'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              20.0), // Set the corner radius
                                        ),
                                      ),
                                      fixedSize:
                                          MaterialStateProperty.all<Size>(
                                        const Size(100,
                                            50), // Set the width and height
                                      ),
                                      backgroundColor: MaterialStateProperty
                                          .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(
                                              MaterialState.pressed)) {
                                            // Color when pressed
                                            return Color.fromRGBO(229, 63, 248,
                                                1); // Change this to the desired pressed color
                                          }
                                          // Color when not pressed
                                          return Color.fromRGBO(240, 106, 255,
                                              1); // Change this to the desired normal color
                                        },
                                      ),
                                    ),
                                    child: const Text(
                                      'Details',
                                      style: TextStyle(
                                        color: Colors
                                            .white, // Set the text color to purple
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
