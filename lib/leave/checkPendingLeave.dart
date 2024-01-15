import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/data/data_model.dart';
import 'package:flutter_application_1/leave/process_PendingLeave_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckPendingLeave extends StatefulWidget {
  final String companyId;
  final String userPosition;

  CheckPendingLeave(
      {Key? key, required this.companyId, required this.userPosition})
      : super(key: key);

  @override
  _CheckPendingLeave createState() => _CheckPendingLeave();
}

class _CheckPendingLeave extends State<CheckPendingLeave> {
  final logger = Logger();
  bool isLoading = false;
  List<dynamic> userNameList = [];
  String? _search;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Fetch user data when the page is initialized
    fetchAllUsersWithPendingLeave(1);
  }

  String _formatDateString(String dateString) {
    // Ensure that the date string has leading zeros in month and day
    final parts = dateString.split('-');
    if (parts.length == 3) {
      return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
    }
    return dateString;
  }

  Future<void> fetchAllUsersWithRejectedLeave() async {
    try {
      setState(() {
        isLoading = true;
      });
      final List<Map<String, dynamic>> allUsersData =
          await LeaveModel().getUsersWithRejectedLeave();

      setState(() {
        if (allUsersData.isNotEmpty) {
          userNameList = allUsersData.map((user) {
            final String companyId = user['userData']['companyId'].toString();
            final String name = user['userData']['name'].toString();
            final String leaveType = user['leaveType'].toString();
            final num leaveDay = user['leaveDay'] as num;
            final DateTime startDate = user['startDate'] as DateTime;
            final DateTime? endDate = user['endDate'] as DateTime?;
            final String fullORHalf = user['fullORHalf'].toString();
            final String reason = user['reason'].toString();
            final String documentId = user['documentId'].toString();
            final String remark = user['remark'].toString();

            final formattedStartDate =
                "${startDate.year}-${startDate.month}-${startDate.day}";
            final formattedEndDate = endDate != null
                ? "${endDate.year}-${endDate.month}-${endDate.day}"
                : '';

            return {
              'companyId': companyId,
              'name': name,
              'leaveType': leaveType,
              'leaveDay': leaveDay,
              'startDate': formattedStartDate,
              'endDate': formattedEndDate,
              'fullORHalf': fullORHalf,
              'reason': reason,
              'remark': remark,
              'documentId': documentId,
            };
          }).toList();
          // Sort rejectedLeaveList by 'startDate'
          userNameList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['startDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['startDate']))));
        }
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error fetching all users with leave history: $e');
      isLoading = false;
    }
  }

  Future<void> fetchAllUsersWithApprovedLeave() async {
    try {
      setState(() {
        isLoading = true;
      });
      final List<Map<String, dynamic>> allUsersData =
          await LeaveModel().getUsersWithApprovedLeave();

      setState(() {
        if (allUsersData.isNotEmpty) {
          userNameList = allUsersData.map((user) {
            final String companyId = user['userData']['companyId'].toString();
            final String name = user['userData']['name'].toString();
            final String leaveType = user['leaveType'].toString();
            final num leaveDay = user['leaveDay'] as num;
            final DateTime startDate = user['startDate'] as DateTime;
            final DateTime? endDate = user['endDate'] as DateTime?;
            final String fullORHalf = user['fullORHalf'].toString();
            final String reason = user['reason'].toString();
            final String documentId = user['documentId'].toString();
            final String remark = user['remark'].toString();

            final formattedStartDate =
                "${startDate.year}-${startDate.month}-${startDate.day}";
            final formattedEndDate = endDate != null
                ? "${endDate.year}-${endDate.month}-${endDate.day}"
                : '';

            return {
              'companyId': companyId,
              'name': name,
              'leaveType': leaveType,
              'leaveDay': leaveDay,
              'startDate': formattedStartDate,
              'endDate': formattedEndDate,
              'fullORHalf': fullORHalf,
              'reason': reason,
              'remark': remark,
              'documentId': documentId,
            };
          }).toList();
          // Sort rejectedLeaveList by 'startDate'
          userNameList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['startDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['startDate']))));
        }
        if (allUsersData.isNotEmpty) {
          userNameList = allUsersData.map((user) {
            final String companyId = user['userData']['companyId'].toString();
            final String name = user['userData']['name'].toString();
            final String leaveType = user['leaveType'].toString();
            final num leaveDay = user['leaveDay'] as num;
            final DateTime startDate = user['startDate'] as DateTime;
            final DateTime? endDate = user['endDate'] as DateTime?;
            final String fullORHalf = user['fullORHalf'].toString();
            final String reason = user['reason'].toString();
            final String documentId = user['documentId'].toString();
            final String remark = user['remark'].toString();

            final formattedStartDate =
                "${startDate.year}-${startDate.month}-${startDate.day}";
            final formattedEndDate = endDate != null
                ? "${endDate.year}-${endDate.month}-${endDate.day}"
                : '';

            return {
              'companyId': companyId,
              'name': name,
              'leaveType': leaveType,
              'leaveDay': leaveDay,
              'startDate': formattedStartDate,
              'endDate': formattedEndDate,
              'fullORHalf': fullORHalf,
              'reason': reason,
              'remark': remark,
              'documentId': documentId,
            };
          }).toList();
          // Sort rejectedLeaveList by 'startDate'
          userNameList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['startDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['startDate']))));
        }
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error fetching all users with leave history: $e');
      isLoading = false;
    }
  }

  Future<void> fetchAllUsersWithPendingLeave(int index) async {
    try {
      setState(() {
        isLoading = true;
      });
      late List<Map<String, dynamic>> allUsersData;
      if (index == 0) {
        allUsersData = await LeaveModel().getUsersWithApprovedLeave();
      } else if (index == 1) {
        allUsersData = await LeaveModel().getUsersWithPendingLeave();
      } else if (index == 2) {
        allUsersData = await LeaveModel().getUsersWithRejectedLeave();
      }
      setState(() {
        if (allUsersData.isNotEmpty) {
          userNameList = allUsersData.map((user) {
            final String companyId = user['userData']['companyId'].toString();
            final String name = user['userData']['name'].toString();
            final String leaveType = user['leaveType'].toString();
            final num leaveDay = user['leaveDay'] as num;
            final DateTime startDate = user['startDate'] as DateTime;
            final DateTime? endDate = user['endDate'] as DateTime?;
            final String fullORHalf = user['fullORHalf'].toString();
            final String reason = user['reason'].toString();
            final String remark = user['remark'].toString();
            final String documentId = user['documentId'].toString();

            final formattedStartDate =
                "${startDate.year}-${startDate.month}-${startDate.day}";
            final formattedEndDate = endDate != null
                ? "${endDate.year}-${endDate.month}-${endDate.day}"
                : '';

            return {
              'companyId': companyId,
              'name': name,
              'leaveType': leaveType,
              'leaveDay': leaveDay,
              'startDate': formattedStartDate,
              'endDate': formattedEndDate,
              'fullORHalf': fullORHalf,
              'reason': reason,
              'remark': remark,
              'documentId': documentId,
            };
          }).toList();
          // Sort rejectedLeaveList by 'startDate'
          userNameList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['startDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['startDate']))));
        }
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error fetching all users with leave history: $e');
      isLoading = false;
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _getFilteredUsers(
      String? searchTerm) async {
    final QuerySnapshot querySnapshot =
        await _firestore.collection('users').get();

    final List<Map<String, dynamic>> filteredUsers = [];
    final List<Map<String, dynamic>> matchedUsers = [];

    for (var doc in querySnapshot.docs) {
      final userData = doc.data() as Map<String, dynamic>;

      String userName = userData['name'].toString();
      userName = userName.toLowerCase();

      // Check if searchTerm is null or empty, or if the userName contains the searchTerm
      if (searchTerm == null ||
          searchTerm.isEmpty ||
          userName.contains(searchTerm.toLowerCase())) {
        // Add the user to the filteredUsers list
        filteredUsers.add(userData);
      }
    }
    for (var userName in userNameList) {
      for (var filteredUser in filteredUsers) {
        if (userName['name'] == filteredUser['name']) {
          matchedUsers.add(userName);
          logger.i("matchedUsers $matchedUsers");
          // break; // Stop searching for this userName once a match is found
        }
      }
    }

    return matchedUsers;
  }

  int activeLabelIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 224, 45, 255),
        title: const Text(
          'Check Leave',
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
            Navigator.pop(
              context,
              // MaterialPageRoute(
              //     builder: (context) => MainPage(
              //           companyId: widget.companyId,
              //           userPosition: widget.userPosition,
              //         )),
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            ToggleSwitch(
              minWidth: 150.0,
              initialLabelIndex: activeLabelIndex,
              cornerRadius: 30.0,
              activeFgColor: Colors.white,
              inactiveBgColor: Colors.white,
              inactiveFgColor: const Color.fromARGB(255, 224, 45, 255),
              borderColor: const [
                Color.fromARGB(255, 224, 45, 255),
                const Color.fromARGB(255, 224, 165, 235),
                Color.fromARGB(255, 224, 45, 255)
              ],
              borderWidth: 1.5,
              totalSwitches: 3,
              labels: const ['Approved', 'Pending', 'Rejected'],
              customTextStyles: const [
                TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900),
                TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900),
                TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900),
              ],
              activeBgColors: const [
                [
                  Color.fromARGB(255, 224, 45, 255),
                  const Color.fromARGB(255, 224, 165, 235),
                  Color.fromARGB(255, 224, 45, 255)
                ],
                [
                  Color.fromARGB(255, 224, 45, 255),
                  const Color.fromARGB(255, 224, 165, 235),
                  Color.fromARGB(255, 224, 45, 255)
                ],
                [
                  Color.fromARGB(255, 224, 45, 255),
                  const Color.fromARGB(255, 224, 165, 235),
                  Color.fromARGB(255, 224, 45, 255)
                ],
              ],
              onToggle: (index) {
                setState(
                  () {
                    activeLabelIndex = index!;
                    isLoading = true;
                  },
                );
                fetchAllUsersWithPendingLeave(index!);
              },
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.01,
            ),
            Expanded(
              child: isLoading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromRGBO(229, 63, 248, 1)),
                        ),
                        SizedBox(height: 10), // Adjust the height as needed
                        Text('Loading...'),
                      ],
                    )
                  : Column(
                      children: [
                        //Search Bar
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Search Icon
                              GestureDetector(
                                onTap: () {
                                  // Handle search icon click
                                },
                                child: Icon(
                                  Icons.search,
                                  size: 30,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Search TextField
                              Expanded(
                                child: TextField(
                                  controller:
                                      _searchController, // Assign the controller
                                  onChanged: (value) {
                                    // Handle text changes
                                    setState(() {
                                      _search = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Type the user name...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Clear Button
                              TextButton(
                                onPressed: () {
                                  // Handle clear button click
                                  setState(() {
                                    _search = null; // Clear the search term
                                    _searchController.clear();
                                  });
                                },
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(229, 63, 248, 1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Employee Rectangles
                        Expanded(
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _getFilteredUsers(_search),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<
                                                  Color>(
                                              Color.fromRGBO(229, 63, 248, 1)),
                                        ),
                                        SizedBox(
                                            height:
                                                10), // Adjust the height as needed
                                        Text('Loading...'),
                                      ],
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                      child: Text('No users found'));
                                } else {
                                  logger.i(
                                      "print(snapshot.data![index]) ${snapshot.data![0]['name']}");
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.only(
                                            left: 5,
                                            right: 5,
                                            top: 5,
                                            bottom: 5),
                                        padding: const EdgeInsets.only(
                                            left: 5, right: 5),
                                        child: Card(
                                          elevation: 6,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          child: Container(
                                            height: 170,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4.0, vertical: 8.0),
                                            padding: const EdgeInsets.all(4.0),
                                            child: ListTile(
                                              title: Text(
                                                snapshot.data![index]['name'],
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 224, 45, 255),
                                                  fontSize:
                                                      21.0, // or your preferred font size
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 5),
                                                  const Text(
                                                    'Leave Type:',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize:
                                                          16.0, // or your preferred font size
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ), // Set label color
                                                  ),
                                                  Text(
                                                    '${snapshot.data![index]['leaveType']}',
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 224, 45, 255),
                                                      fontSize:
                                                          16.0, // or your preferred font size
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ), // Set data color
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.002,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                            'Days:',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 16.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${snapshot.data![index]['leaveDay']}',
                                                            style:
                                                                const TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      224,
                                                                      45,
                                                                      255),
                                                              fontSize: 16.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.07,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Text(
                                                              'Date:',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${snapshot.data![index]['startDate']}',
                                                              style:
                                                                  const TextStyle(
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        224,
                                                                        45,
                                                                        255),
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (activeLabelIndex == 1)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .fromLTRB(10,
                                                                  0, 10, 10),
                                                          child: ElevatedButton(
                                                            onPressed: () {
                                                              final Map<String,
                                                                      dynamic>
                                                                  user =
                                                                  snapshot.data![
                                                                      index];
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            processFullLeave(
                                                                              companyId: widget.companyId,
                                                                              userPosition: widget.userPosition,
                                                                              userNameList: [
                                                                                user
                                                                              ],
                                                                            )),
                                                              );
                                                            },
                                                            style: ButtonStyle(
                                                              shape: MaterialStateProperty
                                                                  .all<
                                                                      RoundedRectangleBorder>(
                                                                RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20.0), // Set the corner radius
                                                                ),
                                                              ),
                                                              fixedSize:
                                                                  MaterialStateProperty
                                                                      .all<
                                                                          Size>(
                                                                const Size(100,
                                                                    50), // Set the width and height
                                                              ),
                                                              backgroundColor:
                                                                  MaterialStateProperty
                                                                      .resolveWith<
                                                                          Color>(
                                                                (Set<MaterialState>
                                                                    states) {
                                                                  if (states.contains(
                                                                      MaterialState
                                                                          .pressed)) {
                                                                    // Color when pressed
                                                                    return Color
                                                                        .fromRGBO(
                                                                            229,
                                                                            63,
                                                                            248,
                                                                            1); // Change this to the desired pressed color
                                                                  }
                                                                  // Color when not pressed
                                                                  return Color
                                                                      .fromRGBO(
                                                                          240,
                                                                          106,
                                                                          255,
                                                                          1); // Change this to the desired normal color
                                                                },
                                                              ),
                                                            ),
                                                            child: const Text(
                                                              'Check',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white, // Set the text color to purple
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      if (activeLabelIndex != 1)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .fromLTRB(10,
                                                                  0, 10, 10),
                                                          child: ElevatedButton(
                                                            onPressed: () {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                  title:
                                                                      const Center(
                                                                    child: Text(
                                                                        'Leave Details'),
                                                                  ),
                                                                  content:
                                                                      SingleChildScrollView(
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            const Text(
                                                                              'Type: ',
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                            Text('${snapshot.data![index]['leaveType']}'),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            const Text(
                                                                              'Full/Half: ',
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                            Text('${snapshot.data![index]['fullORHalf']}'),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            const Text(
                                                                              'Start Date: ',
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                            Text('${snapshot.data![index]['startDate']}'),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            const Text(
                                                                              'End Date: ',
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                            Text('${snapshot.data![index]['endDate']}'),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            const Text(
                                                                              'Leave Days: ',
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                            Text('${snapshot.data![index]['leaveDay']}'),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            const Text(
                                                                              'Reason: ',
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                            Text('${snapshot.data![index]['reason']}'),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            const Text(
                                                                              'Remark: ',
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                            Text('${snapshot.data![index]['remark']}'),
                                                                          ],
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            Text(
                                                                              'Status: ',
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              activeLabelIndex == 0 ? 'Approved' : (activeLabelIndex == 2 ? 'Rejected' : ''),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: const Text(
                                                                          'OK'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                            style: ButtonStyle(
                                                              shape: MaterialStateProperty
                                                                  .all<
                                                                      RoundedRectangleBorder>(
                                                                RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20.0), // Set the corner radius
                                                                ),
                                                              ),
                                                              fixedSize:
                                                                  MaterialStateProperty
                                                                      .all<
                                                                          Size>(
                                                                const Size(100,
                                                                    50), // Set the width and height
                                                              ),
                                                              backgroundColor:
                                                                  MaterialStateProperty
                                                                      .resolveWith<
                                                                          Color>(
                                                                (Set<MaterialState>
                                                                    states) {
                                                                  if (states.contains(
                                                                      MaterialState
                                                                          .pressed)) {
                                                                    // Color when pressed
                                                                    return Color
                                                                        .fromRGBO(
                                                                            229,
                                                                            63,
                                                                            248,
                                                                            1); // Change this to the desired pressed color
                                                                  }
                                                                  // Color when not pressed
                                                                  return Color
                                                                      .fromRGBO(
                                                                          240,
                                                                          106,
                                                                          255,
                                                                          1); // Change this to the desired normal color
                                                                },
                                                              ),
                                                            ),
                                                            child: const Text(
                                                              'Check',
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
                                  );
                                }
                              }),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
