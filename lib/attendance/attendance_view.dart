import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_application_1/attendance/attendance_record_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:provider/provider.dart';
import 'attendance_data.dart'; // Import the AttendanceData class

class AttendanceView extends StatefulWidget {
  @override
  _AttendanceViewState createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now(); // Set initial date to today
  Map<String, Map<String, dynamic>> usersWithAttendance = {};
  late StreamSubscription<QuerySnapshot> _attendanceSubscription;
  late StreamController<Map<String, Map<String, dynamic>>>
      _usersWithAttendanceController;
  // late PageController _pageController;
  String? selectedCompanyId;

  Future<Map<String, Map<String, dynamic>>> getUsersWithAttendance(
      DateTime chosenDate) async {
    String formattedDate =
        "${chosenDate.day}-${chosenDate.month}-${chosenDate.year}";
    Map<String, Map<String, dynamic>> usersWithAttendance = {};

    QuerySnapshot attendanceSnapshot =
        await _firestore.collection('Attendance').get();

    print("Attendance Snapshot size: ${attendanceSnapshot.size}");

    for (var doc in attendanceSnapshot.docs) {
      print("Document ID: ${doc.id}");
      print("Document data: ${doc.data()}");
    }

    for (var doc in attendanceSnapshot.docs) {
      QuerySnapshot dateSnapshot = await doc.reference
          .collection(formattedDate)
          .orderBy('CheckInTime', descending: true)
          .get();
      List<Map<String, dynamic>> attendanceRecords = [];
      for (var record in dateSnapshot.docs) {
        attendanceRecords.add(record.data() as Map<String, dynamic>);
      }

      if (attendanceRecords.isNotEmpty) {
        DocumentSnapshot userSnapshot =
            await _firestore.collection('users').doc(doc.id).get();
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        usersWithAttendance[doc.id] = {
          'userDetails': userData,
          'attendanceRecords': attendanceRecords,
        };
      }
    }

    return usersWithAttendance;
  }

  Future<Map<String, dynamic>> getUserDetails(String companyId) async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(companyId).get();

    return userSnapshot.data() as Map<String, dynamic>;
  }

Future<void> checkAttendanceAndFetchUsers() async {
  Map<String, Map<String, dynamic>> usersAttendanceInfo =
      await getUsersWithAttendance(_selectedDate);
  if (!_usersWithAttendanceController.isClosed) {
    if (selectedCompanyId != null) {
      print("selectedCompanyId is not null: $selectedCompanyId");
      simulateUserList(usersAttendanceInfo);
    } else {
      print("selectedCompanyId is null");
    }
    _usersWithAttendanceController.add(usersAttendanceInfo);
    print("latestUsersAttendanceInfo: $usersAttendanceInfo");
  }
}


  void simulateUserList(Map<String, dynamic> rawData) {
  //Map<String, Map<String, dynamic>> usersWithAttendance = {};

  List<Map<String, dynamic>> attendanceRecords = (rawData[selectedCompanyId])['attendanceRecords'];
  print("123attendanceRecords${attendanceRecords}");
  
  Provider.of<AttendanceData>(context, listen: false)
    .updateAttendanceRecords(attendanceRecords);

}

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _usersWithAttendanceController =
        StreamController<Map<String, Map<String, dynamic>>>();
    _listenToAttendanceChanges();
    checkAttendanceAndFetchUsers();
  }

  void navigateToAttendanceRecordPage(
      BuildContext context,
      Map<String, dynamic> userDetails,
      List<Map<String, dynamic>> attendanceRecords,
      String companyId
      ) {
      selectedCompanyId = companyId ;
      print("selectedCompanyId${selectedCompanyId}");
      print("PassinglatestUsersAttendanceInfo${attendanceRecords}");
      
      Provider.of<AttendanceData>(context, listen: false)
        .updateAttendanceRecords(attendanceRecords);

    
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AttendanceRecordsPage(
          userDetails: userDetails,
          attendanceRecords: attendanceRecords,
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _attendanceSubscription.cancel();
    _usersWithAttendanceController.close();
    super.dispose();
  }

  

  void _listenToAttendanceChanges() {
    _attendanceSubscription =
        _firestore.collection('Attendance').snapshots().listen((snapshot) {
      checkAttendanceAndFetchUsers();
    });
    /*_attendanceSubscription = _firestore.collection('Attendance').snapshots().listen((snapshot) {
      checkAttendanceAndFetchUsers();
    });*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MorphingAppBar(
        centerTitle: true,
        backgroundColor: Colors.purpleAccent,
        title: Text(
          'Attendance',
          style: TextStyle(
            color: Colors.black87, // Adjust text color for modern style
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme:
            IconThemeData(color: Colors.black), // Set the back arrow color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );

                if (pickedDate != null && pickedDate != _selectedDate) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                  selectedCompanyId=null;
                  await checkAttendanceAndFetchUsers();
                }
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.pressed)) {
                    return Color.fromRGBO(229, 63, 248, 1);
                  }
                  return Color.fromRGBO(240, 106, 255, 1);// Default button color
                }),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide( color: Color.fromRGBO(229, 63, 248, 1), width: 2),
                  ),
                ),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                  EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                elevation: MaterialStateProperty.all<double>(8),
                textStyle: MaterialStateProperty.all<TextStyle>(
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    DateFormat.yMd()
                        .format(_selectedDate), // Format to display date only
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Active Employees',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<Map<String, Map<String, dynamic>>>(
                stream: _usersWithAttendanceController.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                     return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromRGBO(229, 63, 248, 1)),
                          ),
                          SizedBox(height: 10), // Adjust the height as needed
                          Text('Loading...'),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No data available'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      // ignore: body_might_complete_normally_nullable
                      itemBuilder: (BuildContext context, int index) {
                        String companyId = snapshot.data!.keys.elementAt(index);
                        Map<String, dynamic> userAttendance =
                            snapshot.data![companyId]!;
                        Map<String, dynamic> userDetails =
                            userAttendance['userDetails']
                                as Map<String, dynamic>;
                        List<Map<String, dynamic>> attendanceRecords =
                            userAttendance['attendanceRecords']
                                as List<Map<String, dynamic>>;
                        // Build your user list item based on snapshot data
                        if (userDetails['status'] == true) {
                          // Build your user list item based on snapshot data
                          return GestureDetector(
                            onTap: () {
                              navigateToAttendanceRecordPage(
                                  context, userDetails, attendanceRecords,companyId);
                            },
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: Hero(
                                  tag:
                                      'avatar_${userDetails['name']}', // Unique hero tag
                                  child: CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(userDetails['image']),
                                    radius: 28,
                                  ),
                                ),
                                title: Text(
                                  userDetails['name'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userDetails['position'],
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Total Attendance Records: ${attendanceRecords.length}',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onLongPress: () {
                                  // Handle long press
                                },
                                onTap: () {
                                  navigateToAttendanceRecordPage(
                                      context, userDetails, attendanceRecords,companyId);
                                },
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
