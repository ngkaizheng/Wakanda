import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'attendance_data.dart'; // Import the AttendanceData class


class AttendanceRecordsPage extends StatefulWidget {
  final Map<String, dynamic> userDetails;
  final List<Map<String, dynamic>> attendanceRecords;
  final DateTime selectedDate;

  AttendanceRecordsPage(
      {required this.userDetails,
      required this.attendanceRecords,
      required this.selectedDate});

  @override
  _AttendanceRecordsPageState createState() => _AttendanceRecordsPageState();
}

class _AttendanceRecordsPageState extends State<AttendanceRecordsPage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> checkInAddresses = [];
  List<String> checkOutAddresses = [];
  int? selectedCardIndex; // Track the selected card index
  ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? dailyWorkingTimeData;
  Duration late = Duration.zero;
  Duration overtime = Duration.zero;
  TimeOfDay workingStartTime = TimeOfDay(hour: 8, minute: 0); // 8:00 a.m.

  final logger = Logger();
  List<Map<String, dynamic>> _currentAttendanceRecords = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _currentAttendanceRecords = widget.attendanceRecords;
  }

  Future<void> _initializeData() async {
    await transformGeoPoints(context);
    print("init times");
    await fetchDailyWorkingTime();
    await calculateLateAndOvertime();
  }

Future<void> calculateLateAndOvertime() async {
  if (!isWeekend(widget.selectedDate) && !isHoliday()) {
    if (widget.attendanceRecords.isNotEmpty) {
      final firstCheckInTime =
          parseTimeOfDay(widget.attendanceRecords.last['CheckInTime']);
      if (firstCheckInTime != null) {
        final checkInDateTime = DateTime(
          0,
          1,
          1,
          firstCheckInTime.hour,
          firstCheckInTime.minute,
        );

        final workingStartDateTime = DateTime(
          0,
          1,
          1,
          workingStartTime.hour,
          workingStartTime.minute,
        );
                  logger.i("workingStartDateTime $workingStartDateTime");

        if (checkInDateTime.isAfter(workingStartDateTime)) {
          late = checkInDateTime.difference(workingStartDateTime);
            logger.i("firstCheckInTime $firstCheckInTime");
            logger.i("lateCheckIn $late");
        }
      }

      final totalWorkHours = dailyWorkingTimeData?['totalworkingtime'] ?? 0;
      logger.i("totalWorkHoursNormalDay $totalWorkHours");
      const regularWorkHours = 8;
        Duration totalWorkDuration = Duration(
          hours: totalWorkHours.toInt(),
          minutes: ((totalWorkHours % 1) * 60).toInt(),
          seconds: (((totalWorkHours % 1) * 60) % 1 * 60).toInt(),
        );
        logger.i("totalWorkDurationNormalDay $totalWorkDuration");
        Duration regularWorkDuration = Duration(hours: regularWorkHours);

      if (totalWorkDuration > regularWorkDuration) {
        overtime = totalWorkDuration - regularWorkDuration;
        logger.i("overtimeNormalDay $overtime");
      }
    }
  } else {
      // For weekends or holidays, there's no late and total work time is considered as overtime
      // late = null;
      // final totalWorkHours = dailyWorkingTimeData?['totalworkingtime'] ?? 0;
      num totalWorkHours = dailyWorkingTimeData!["totalworkingtime"];
      logger.i("totalWorkHours $totalWorkHours");
      // overtime = Duration(hours: totalWorkHours.toInt());
      overtime = Duration(
        hours: totalWorkHours.toInt(),
        minutes: ((totalWorkHours % 1) * 60).toInt(),
        seconds: (((totalWorkHours % 1) * 60) % 1 * 60).toInt(),
      );

      logger.i("overtime${overtime}");
    }
}


  bool isWeekend(DateTime date) {
    // Check if the given date falls on a Saturday or Sunday
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  bool isHoliday() {
    return dailyWorkingTimeData?['isHoliday'] ?? false;
  }

  TimeOfDay? parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    final int hours = int.parse(parts[0]);
    final int minutes = int.parse(parts[1]);
    return TimeOfDay(hour: hours, minute: minutes);
  }

// Then, fetching data from the document:
  Future<void> fetchDailyWorkingTime() async {
    print('working');
    try {
      DocumentReference dailyDocRef = _firestore
          .collection('workingtime')
          .doc(widget.userDetails['companyId'])
          .collection(widget.selectedDate.year.toString())
          .doc(widget.selectedDate.month
              .toString()
              .padLeft(2, '0')) // Format month
          .collection(widget.selectedDate.day.toString())
          .doc('dailyWorkingTime');
      print(dailyDocRef);

      DocumentSnapshot dailyWorkingTimeSnapshot = await dailyDocRef.get();
      print("Checking ${dailyWorkingTimeSnapshot}");

      print(dailyWorkingTimeSnapshot.exists);

      if (dailyWorkingTimeSnapshot.exists) {
        print('success');
        print(dailyWorkingTimeSnapshot.data());

        setState(() {
          dailyWorkingTimeData =
              dailyWorkingTimeSnapshot.data() as Map<String, dynamic>;
        });
        logger.i("FetchdailyWorkingTimeData $dailyWorkingTimeData");


        /*      // Access fields from the daily working time document
        String field1 = dailyWorkingTimeData['field1'];
        int field2 = dailyWorkingTimeData['field2'];
        // Access other fields as needed

        // Use the retrieved data or perform operations*/
      } else {
        print('Not Success');
      }
    } catch (e) {
      print('Error fetching daily working time: $e');
    }
  }

  /*Future<void> transformGeoPoints() async {
    for (var record in widget.attendanceRecords) {
      String checkInAddress =
          await getAddressFromLocation(record['CheckInLocation']);
      String checkOutAddress =
          await getAddressFromLocation(record['CheckOutLocation']);
      setState(() {
        checkInAddresses.add(checkInAddress);
        checkOutAddresses.add(checkOutAddress);
      });
    }
  }*/

Future<void> transformGeoPoints(BuildContext context) async {
  AttendanceData attendanceData = context.read<AttendanceData>();
  List<Map<String, dynamic>> attendanceRecords = attendanceData.attendanceRecords;
  _currentAttendanceRecords = attendanceRecords;

  print('Initial Length of checkInAddresses: ${checkInAddresses.length}');
  print('Initial Length of checkOutAddresses: ${checkOutAddresses.length}');

  for (var i = 0; i < attendanceRecords.length; i++) {
    print('Processing record at index $i');

    print('Updating checkInAddresses for index $i');
    String checkInAddress = await getAddressFromLocation(attendanceRecords[i]['CheckInLocation']);
    
    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        if (i >= checkInAddresses.length) {
          checkInAddresses.add(checkInAddress);
        } else {
          checkInAddresses[i] = checkInAddress;
        }
      });
    }

    print('Updating checkOutAddresses for index $i');
    String checkOutAddress = await getAddressFromLocation(attendanceRecords[i]['CheckOutLocation']);
    
    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        if (i >= checkOutAddresses.length) {
          checkOutAddresses.add(checkOutAddress);
        } else {
          checkOutAddresses[i] = checkOutAddress;
        }
      });
    }

    print('Intermediate Length of checkInAddresses: ${checkInAddresses.length}');
    print('Intermediate Length of checkOutAddresses: ${checkOutAddresses.length}');
  }

  print('Final Length of checkInAddresses: ${checkInAddresses.length}');
  print('Final Length of checkOutAddresses: ${checkOutAddresses.length}');

  print('Final checkInAddresses:');
  for (var address in this.checkInAddresses) {
    print(address);
  }

  print('Final checkOutAddresses:');
  for (var address in this.checkOutAddresses) {
    print(address);
  }
}





  Future<String> getAddressFromLocation(GeoPoint? geoPoint) async {
    if (geoPoint != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          geoPoint.latitude,
          geoPoint.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          return '${placemark.locality ?? ''}, ${placemark.postalCode ?? ''}, ${placemark.country ?? ''}';
        }
      } catch (e) {
        print('Error getting address: $e');
      }
    }
    return 'Address not available';
  }

  /* @override
  void didUpdateWidget(covariant AttendanceRecordsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attendanceRecords != oldWidget.attendanceRecords) {
      // Update the state when the attendanceRecords parameter changes
      setState(() {
        _currentAttendanceRecords = widget.attendanceRecords;
      });
    }
  }*/
 
  @override
  Widget build(BuildContext context) {
    final fulltime = 24.0; // Ensure this is a double

    // Create a Duration representing 24 hours
    Duration fulltimeDuration = Duration(
        hours: fulltime.toInt(), minutes: ((fulltime % 1) * 60).toInt());

    // final lateHours = late != null ? late!.inHours.toDouble() : 0.0;
    double lateHours = late != Duration.zero
        ? late.inMicroseconds / Duration.microsecondsPerHour
        : 0.0;

    // final overtimeHours = overtime != null ? overtime!.inHours.toDouble() : 0.0;
    // ignore: unnecessary_null_comparison
    // Duration overtimeHours = overtime != null ? overtime : Duration.zero;
    // ignore: unnecessary_null_comparison
    double overtimeHours = overtime != Duration.zero
        ? overtime.inMicroseconds / Duration.microsecondsPerHour
        : 0.0;

    final latePercentage = lateHours / fulltime;
    final overtimePercentage = overtimeHours / fulltime;

    return Scaffold(
        body: Stack(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MorphingAppBar(
            title: Text(
              widget.userDetails['name'] ?? 'Attendance Records',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.purpleAccent,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          Stack(children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(
                    MediaQuery.of(context).size.height * 0.22,
                  ), // Set rounded radius
                  bottomLeft: Radius.circular(
                    MediaQuery.of(context).size.height * 0.22,
                  ),
                ),
                gradient: LinearGradient(
                  colors: [
                   Color.fromARGB(255, 226, 46, 250), 
                   Color.fromARGB(255, 170, 22, 219)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 164, 0, 252).withOpacity(0.3),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            //Dashboard Container
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 180,
              child: Padding(
                padding: EdgeInsets.only(top: 7, right: 20, left: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24, // Adjust the width of the square
                          height: 24, // Adjust the height of the square
                          color: Color.fromARGB(
                            255, 187, 0, 255), // Color of the square
                          margin: EdgeInsets.only(
                              right: 1,
                              bottom: 1), // Margin between the square and text
                        ),
                        Text(
                          'TOTAL WORK',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Color.fromARGB(255, 147, 39, 255),
                            letterSpacing: 0.1,
                            height: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (dailyWorkingTimeData != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                            begin: 0.0,
                            end: (dailyWorkingTimeData!['totalworkingtime'] ??
                                    0) /
                                24),
                        duration: Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 10,
                                width: MediaQuery.of(context).size.width * 0.6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4D7EFF),
                                      Color.fromARGB(255, 94, 151, 209)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                child: Container(
                                  height: 10,
                                  width: MediaQuery.of(context).size.width *
                                      0.6 * 
                                      value,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF4D7EFF),
                                        Color(0xFF73B9FF)
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        Text(
                          '24',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    // Display the Late and Overtime graphs
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Late',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(
                                      begin: 0.0,
                                      end:
                                          latePercentage), // Use latePercentage for late graph animation
                                  duration: Duration(milliseconds: 800),
                                  builder: (context, value, child) {
                                    return Container(
                                      height: 5,
                                      width: MediaQuery.of(context).size.width * 
                                          0.3 *
                                          value, // Adjust the max width as needed
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red,
                                            Colors.orange
                                          ], // Adjust colors for late
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Repeat the same structure for the overtime graph
                              ],
                            ),
                            Text(
                              '${lateHours.toStringAsFixed(2)} hr',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overtime',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(169, 195, 255, 0),
                                  ),
                                ),
                                Container(
                                  height: 5,
                                  width: MediaQuery.of(context).size.width * 0.3 *
                                      overtimePercentage, // Adjust the width of the overtime graph as needed
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    gradient: LinearGradient(
                                      colors: [Colors.blue, Colors.green],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${overtimeHours.toStringAsFixed(2)} hr',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(169, 195, 255, 0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height:7,
                    ),
                    if (dailyWorkingTimeData != null &&
                        dailyWorkingTimeData!['totalworkingtime'] != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(dailyWorkingTimeData!['totalworkingtime'] ?? 0).toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  color: Colors.white,
                                  height: 0.77),
                            ),
                            SizedBox(
                                width:
                                    4), // Adjust the spacing between the value and 'hr'
                            Text(
                              'hr',
                              style: TextStyle(
                                fontSize: 14, // Change the font size as needed
                                color: Colors.white,
                                height: 0.77,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (dailyWorkingTimeData == null ||
                        dailyWorkingTimeData!['totalworkingtime'] == null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.height * 0.13,
                        height: MediaQuery.of(context).size.height * 0.13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 20,
                              spreadRadius: 10,
                              offset: Offset(0, 15),
                            ),
                          ],
                          // Placeholder color or image decoration here if available in userDetails
                        ),
                        child: widget.userDetails.containsKey('image')
                            ? ClipOval(
                                child: Image.network(
                                  widget.userDetails['image'],
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                              ),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              widget.userDetails['position'],
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 190, 69, 255),
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(224, 152, 255, 1),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              border: Border.all(
                                color: Color.fromARGB(255, 156, 50, 188)!,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              widget.userDetails['name'],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Add more user information or widgets as needed
                ],
              ),
            ),
          ]),
          Expanded(
            child: Stack(
              children: [
                // Other widgets overlapping the ListView if needed
                Align(
                  alignment: Alignment.centerRight,
                  child: RotatedBox(
                    quarterTurns:
                        1, // Rotating text by 90 degrees counter-clockwise
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 108, 0, 191),
                            Color.fromARGB(255, 181, 0, 198)
                          ], // Adjust gradient colors
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 4,
                            blurRadius: 20,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.userDetails['companyId']}',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * 0.135,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Text color
                          fontFamily: 'Montserrat', // Your desired font
                          fontStyle: FontStyle.italic,
                          height: 1.1,
                          letterSpacing:
                              1.5, // Adjust letter spacing for a stylish look
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Rest of your code for ListView.builder and other widgets
                SizedBox(height: 20),
                // Add space after the Company ID
                // Other widgets overlapping the ListView if needed
                Theme(
                    data: ThemeData(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor:
                            MaterialStateProperty.all<Color>(Colors.red),
                      ),
                    ),
                    child: RawScrollbar(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        thickness: 20.0,
                        radius: Radius.circular(5),
                        controller: _scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        trackColor: Colors.blueGrey.withOpacity(0.2),
                        thumbColor: const Color.fromARGB(255, 176, 206, 221)
                            .withOpacity(1.0),
                        trackBorderColor: Colors.transparent,
                        child: ShaderMask(
                          shaderCallback: (Rect rect) {
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.purple,
                                Colors.transparent,
                                Colors.transparent,
                                Colors.purple
                              ],
                              stops: [
                                0.0,
                                0.1,
                                0.9,
                                1.0
                              ], // 10% purple, 80% transparent, 10% purple
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstOut,
                          child:Consumer<AttendanceData>(
                            builder: (context, attendanceData, child){
                              List<Map<String, dynamic>> attendanceRecords = attendanceData.attendanceRecords;
                              print("Checking123");
                              print("${attendanceData.attendanceRecords}");

                              transformGeoPoints(context);
                              return ListView.builder(
                            controller:
                                _scrollController, // Assign the same controller
                            physics:
                                AlwaysScrollableScrollPhysics(), // Ensure scrolling is always enabled
                            itemCount: attendanceRecords.length,
                            padding: EdgeInsets.only(top: 40, right: 100),
                            //clipBehavior: Clip.none,
                            itemBuilder: (BuildContext context, int index) {
                              Map<String, dynamic> record =
                                  attendanceRecords[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                    top: 10, bottom: 0, right: 12, left: 4),
                                child: InteractiveCard(
                                  record: record,
                                  checkInAddresses: checkInAddresses,
                                  checkOutAddresses: checkOutAddresses,
                                  index: index,
                                  isSelected: selectedCardIndex == index,
                                  onTap: () {
                                    setState(() {
                                      selectedCardIndex = index;
                                    });
                                  },
                                ),
                              );
                            },
                          ) ;
                            }
                            ) 
                          
                          
                        ))),
                // Other widgets overlapping the ListView if needed
                // Details Window

              ],
            ),
          ),
        ],
      ),
          if (selectedCardIndex != null)
            Consumer<AttendanceData>(
              builder:(context, attendanceData, child){
                List<Map<String, dynamic>> attendanceRecords = attendanceData.attendanceRecords;
                return PolishedDetailsWindow(
              record: selectedCardIndex != null
                  ?{ ...attendanceRecords[selectedCardIndex!] ?? {},
                    'CheckInLocation': checkInAddresses[selectedCardIndex!],
                    'CheckOutLocation': checkOutAddresses[selectedCardIndex!],
                   } // Provide a default empty map
                  : {},
              onClose: () {
                setState(() {
                  selectedCardIndex = null; // Close the window
                });
              },
              onCheckInTimeEdit: () {
                if (selectedCardIndex != null) {
                  showCheckInTimeEditingInterface(context, selectedCardIndex!);
                }

              },
              onCheckOutTimeEdit: () {
                if (selectedCardIndex != null) {
                  showCheckOutTimeEditingInterface(context, selectedCardIndex!);
                }
              },
            );
              }
            ),
            
    ]));
  }

Future<void> showCheckInTimeEditingInterface(BuildContext context, int index) async {
  TimeOfDay previousCheckInTime = index < widget.attendanceRecords.length - 1
      ? _convertTimeStringToTimeOfDay(widget.attendanceRecords[index + 1]['CheckInTime'] ?? '00:00:00')
      : TimeOfDay(hour: 0, minute: 0);
  print("previousCheckInTime: $previousCheckInTime");

  TimeOfDay ownCheckOutTime = index+1 > 0
      ? _convertTimeStringToTimeOfDay(widget.attendanceRecords[index]['CheckOutTime'] ?? '23:59:59')
      : TimeOfDay(hour: 23, minute: 59);
  print("ownCheckOutTime: $ownCheckOutTime");

  TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: _convertTimeStringToTimeOfDay(widget.attendanceRecords[index]['CheckInTime']),
  );

  if (pickedTime != null) {
    DateTime pickedDateTime = DateTime(1, 1, 1, pickedTime.hour, pickedTime.minute);
    DateTime previousDateTime = DateTime(1, 1, 1, previousCheckInTime.hour, previousCheckInTime.minute);
    DateTime nextDateTime = DateTime(1, 1, 1, ownCheckOutTime.hour, ownCheckOutTime.minute);

    if (pickedDateTime.isAfter(previousDateTime) && pickedDateTime.isBefore(nextDateTime)) {
      // Handle the picked time
      print('Picked time: $pickedTime');
    } else {
      // Show an error message
      _showErrorDialog(context, 'Invalid time. Please select a time between $previousCheckInTime and $ownCheckOutTime');
    }
  }
}

Future<void> showCheckOutTimeEditingInterface(BuildContext context, int index) async {
  TimeOfDay ownCheckInTime = _convertTimeStringToTimeOfDay(widget.attendanceRecords[index]['CheckInTime'] ?? '00:00:00');
  print("ownCheckInTime: $ownCheckInTime");

  TimeOfDay nextCheckInTime = index > 0
      ? _convertTimeStringToTimeOfDay(widget.attendanceRecords[index - 1]['CheckInTime'] ?? '00:00:00')
      : TimeOfDay(hour: 23, minute: 59);
  print("nextCheckInTime: $nextCheckInTime");

TimeOfDay? pickedTime = await showTimePicker(
  context: context,
  initialTime: _convertTimeStringToTimeOfDay(widget.attendanceRecords[index]['CheckOutTime'] ?? '00:00:00') ?? TimeOfDay.now(),
);


  if (pickedTime != null) {
    DateTime pickedDateTime = DateTime(1, 1, 1, pickedTime.hour, pickedTime.minute);
    DateTime ownCheckInDateTime = DateTime(1, 1, 1, ownCheckInTime.hour, ownCheckInTime.minute);
    DateTime nextCheckInDateTime = DateTime(1, 1, 1, nextCheckInTime.hour, nextCheckInTime.minute);

    if (pickedDateTime.isAfter(ownCheckInDateTime) && pickedDateTime.isBefore(nextCheckInDateTime)) {
      // Handle the picked time
      print('Picked time: $pickedTime');
    } else {
      // Show an error message
      _showErrorDialog(context, 'Invalid time. Please select a time between $ownCheckInTime and $nextCheckInTime');
    }
  }
}

void _showErrorDialog(BuildContext context, String errorMessage) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}


TimeOfDay _convertTimeStringToTimeOfDay(String timeString) {
  List<String> timeComponents = timeString.split(':');
  int hour = int.parse(timeComponents[0]);
  int minute = int.parse(timeComponents[1]);
  return TimeOfDay(hour: hour, minute: minute);
}


}


class InteractiveCard extends StatefulWidget {
  final Map<String, dynamic> record;
  final List<String> checkInAddresses;
  final List<String> checkOutAddresses;
  final int index;
  final bool isSelected; // Add isSelected property
  final Function() onTap; // Add onTap function

  const InteractiveCard({
    Key? key,
    required this.record,
    required this.checkInAddresses,
    required this.checkOutAddresses,
    required this.index,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  _InteractiveCardState createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  //bool isSelected = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color checkOutIconColor = Color.fromARGB(255, 176, 95, 95);
    Color checkInIconColor = Colors.teal;
    String checkInAddress = widget.checkInAddresses.length > widget.index
        ? widget.checkInAddresses[widget.index]
        : 'Address not available';

    String checkOutAddress = widget.checkOutAddresses.length > widget.index
        ? widget.checkOutAddresses[widget.index]
        : 'Address not available';

    final maxLength = 11; // Adjust the maximum length as needed

    String limitedCheckInAddress = checkInAddress.length > maxLength
        ? '${checkInAddress.substring(0, maxLength)}...'
        : checkInAddress;

    String limitedCheckOutAddress = checkOutAddress.length > maxLength
        ? '${checkOutAddress.substring(0, maxLength)}...'
        : checkOutAddress;

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        widget.onTap(); // Toggle selection on tap
      },
      onTapUp: (_) {
        _controller.reverse();
        // Add your onTap logic here
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _animation,
        child: Container(
          clipBehavior: Clip.none,
          child: Stack(
            children: [
              Card(
                elevation: widget.isSelected ? 12 : 8,
                margin: EdgeInsets.only(top: 10, bottom: 0, right: 12, left: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: widget.isSelected ? Colors.blue : Colors.transparent,
                    width: widget.isSelected ? 2 : 0,
                  ),
                ),
                color: widget.isSelected
                    ? Colors.blueGrey[50]
                    : widget.index.isEven
                        ? Colors.white
                        : Colors.grey[300],
                child: Material(
                  borderRadius: BorderRadius.circular(20),
                  color: widget.isSelected
                      ? Colors.blueGrey[100]
                      : Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      widget.onTap();
                    },
                    splashColor: widget.isSelected
                        ? Colors.transparent
                        : Colors.blueGrey.withOpacity(0.3),
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        ClipRect(
                          child: Container(
                            padding:
                                EdgeInsets.only(top: 16, bottom: 16, right: 16),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: widget.isSelected
                                      ? Color.fromARGB(255, 213, 60, 255)
                                      : Colors.deepPurple,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Check-In',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Check-Out',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: checkInIconColor,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${widget.record['CheckInTime']}',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        '${widget.record['CheckOutTime']}',
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.access_time,
                                        color: checkOutIconColor,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: checkInIconColor,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          limitedCheckInAddress,
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                limitedCheckOutAddress,
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.location_on,
                                              color: checkOutIconColor,
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ), // Positioned Index Display
              // Positioned Index Display
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                transform: widget.isSelected
                    ? Matrix4.translationValues(-15, -27, 0)
                    : Matrix4.translationValues(0, -10, 0),
                child: Container(
                  padding: EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isSelected
                          ? [
                              Colors.purple.withOpacity(0.7),
                              Color.fromARGB(255, 255, 86, 34).withOpacity(0.3)
                            ]
                          : [
                              Colors.lightBlue.withOpacity(0.0),
                              Colors.teal.withOpacity(0.0)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(0),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isSelected
                            ? const Color.fromARGB(255, 188, 0, 221).withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    width: 60,
                    height: 53,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isSelected
                            ? [
                                Color.fromARGB(255, 234, 16, 190).withOpacity(0.5),
                                Color.fromARGB(255, 255, 34, 100).withOpacity(0.7)
                              ]
                            : [
                                Colors.lightBlue.withOpacity(0.0),
                                Colors.teal.withOpacity(0.0)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.rectangle,
                    ),
                    child: Center(
                      child: Stack(
                        children: [
                          Text(
                            '${widget.index + 1}',
                            style: TextStyle(
                              color: widget.isSelected
                                  ? Colors.red
                                  : Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                              fontSize: 53,
                              letterSpacing: -4,
                            ),
                          ),
                          Text(
                            '${widget.index + 1}',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 50,
                              letterSpacing: -4,
                              fontStyle:
                                  FontStyle.italic, // Apply italic style here
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 10,
                            child: Text(
                              'No.',
                              style: TextStyle(
                                color: Color.fromARGB(255, 119, 8, 229),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                fontStyle:
                                    FontStyle.italic, // Apply italic style here
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PolishedDetailsWindow extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onClose;
  final VoidCallback onCheckInTimeEdit;
  final VoidCallback onCheckOutTimeEdit;

  const PolishedDetailsWindow({required this.record, required this.onClose,required this.onCheckInTimeEdit,
    required this.onCheckOutTimeEdit,});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        //onTap: onClose,
        child: BouncingWidget(
          duration: Duration(milliseconds: 500),
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                width: MediaQuery.of(context).size.width * 0.80,
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF512DA8),
                      Color(0xFF303F9F),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      spreadRadius: 8,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: onClose,
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        // Additional icons or widgets can be added here
                      ],
                    ),
                    SizedBox(height: 20),
                    for (var dynamicDetail in dynamicDetails)
                      PolishedDetailItem(
                        label: dynamicDetail['label'],
                        value: record[dynamicDetail['valueKey']] ?? 'N/A', // Provide a default value or handle null
                        icon: dynamicDetail['icon'],
                        iconColor: dynamicDetail['iconColor'],
                        backgroundColor: dynamicDetail['backgroundColor'],
                        onTap: dynamicDetail['onTap'],
                        onCheckInTimeEdit: onCheckInTimeEdit,
                        onCheckOutTimeEdit: onCheckOutTimeEdit,



                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PolishedDetailItem extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final Function()? onCheckInTimeEdit;
  final Function()? onCheckOutTimeEdit;


  const PolishedDetailItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
    this.onCheckInTimeEdit,
    this.onCheckOutTimeEdit,

  });

  @override
  _PolishedDetailItemState createState() => _PolishedDetailItemState();
}

class _PolishedDetailItemState extends State<PolishedDetailItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _parallaxAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _parallaxAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
    if (widget.label == 'Check-In Time' ) {
      if (widget.onCheckInTimeEdit != null) {
        widget.onCheckInTimeEdit!();
      }

      // Add your logic to handle editing for Check-In Time and Check-Out Time
      // For example, you can show a time picker or navigate to an editing screen
      /*showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      ).then((pickedTime) {
        if (pickedTime != null) {
          // Handle the picked time, you might want to update the value
          // in your data model or perform any necessary actions
          print('Picked time: $pickedTime');
        }
      });*/
    }
    else if(widget.label =='Check-Out Time'){
      if (widget.onCheckOutTimeEdit != null) {
        widget.onCheckOutTimeEdit!();
      }
    } 
    else if (widget.onTap != null) {
      // If it's not Check-In Time or Check-Out Time, perform the provided onTap callback
      widget.onTap!();
    }

  },
    child: Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.backgroundColor.withOpacity(0.9),
            widget.backgroundColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Transform.translate(
            offset: Offset(_parallaxAnimation.value, 0.0),
            child: Row(
              children: [
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 34,
                  ),
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,  // Adjust the font size as needed
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Container(
                      width: 150,  // Set a fixed width
                      child: Text(
                        widget.value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.label == 'Check-In Time' || widget.label == 'Check-Out Time')
            Icon(
              Icons.edit,
              color: Colors.white,
              size: 25,
            ),
        ],
      ),
    ),
  );
}



  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class BouncingWidget extends StatelessWidget {
  final Duration duration;
  final Widget child;

  const BouncingWidget({required this.duration, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + 0.15 * value,
          child: child,
        );
      },
      child: child,
    );
  }
}

final List<Map<String, dynamic>> dynamicDetails = [
  {
    'label': 'Check-In Time',
    'valueKey': 'CheckInTime',
    'icon': Icons.timelapse,
    'iconColor': Colors.green,
    'backgroundColor': Colors.blue,
    'onTap': () {
      // Add specific behavior for Check-In Time
      
    },
  },
  {
    'label': 'Check-In Location',
    'valueKey': 'CheckInLocation',
    'icon': Icons.location_on,
    'iconColor': Colors.blue,
    'backgroundColor': Colors.teal,
    'onTap': () {
      // Add specific behavior for Check-In Location
    },
  },
  {
    'label': 'Check-Out Time',
    'valueKey': 'CheckOutTime',
    'icon': Icons.timelapse,
    'iconColor': Colors.red,
    'backgroundColor': Colors.orange,
    'onTap': () {
      // Add specific behavior for Check-Out Time
      
    },
  },
  {
    'label': 'Check-Out Location',
    'valueKey': 'CheckOutLocation',
    'icon': Icons.location_on,
    'iconColor': Colors.orange,
    'backgroundColor': Colors.deepOrange,
    'onTap': () {
      // Add specific behavior for Check-Out Location
    },
  },
  // Add more dynamic details as needed
];


