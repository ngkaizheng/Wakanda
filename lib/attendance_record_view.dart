import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:swipeable_page_route/swipeable_page_route.dart';

class AttendanceRecordsPage extends StatefulWidget {
  final Map<String, dynamic> userDetails;
  final List<Map<String, dynamic>> attendanceRecords;
  final DateTime selectedDate;

  AttendanceRecordsPage({required this.userDetails, required this.attendanceRecords, required this.selectedDate});

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
    Duration? late;
    Duration? overtime;
    TimeOfDay workingStartTime = TimeOfDay(hour: 0, minute: 0); // 8:00 a.m.

  @override
    void initState() {
    transformGeoPoints();
    fetchDailyWorkingTime();
    calculateLateAndOvertime();
    super.initState();
  }

  void calculateLateAndOvertime() {
    if (!isWeekend(widget.selectedDate) && !isHoliday()) {
      if (widget.attendanceRecords.isNotEmpty) {
        final firstCheckInTime = parseTimeOfDay(widget.attendanceRecords.last['CheckInTime']);
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

          if (checkInDateTime.isAfter(workingStartDateTime)) {
            late = checkInDateTime.difference(workingStartDateTime);
          }
        }

        final totalWorkHours = dailyWorkingTimeData?['totalworkingtime'] ?? 0;
        const regularWorkHours = 8;
        final totalWorkDuration = Duration(hours: totalWorkHours.toInt());
        final regularWorkDuration = Duration(hours: regularWorkHours);

        if (totalWorkDuration > regularWorkDuration) {
          overtime = totalWorkDuration - regularWorkDuration;
        }
      }
    } else {
      // For weekends or holidays, there's no late and total work time is considered as overtime
      late = null;
      final totalWorkHours = dailyWorkingTimeData?['totalworkingtime'] ?? 0;
      overtime = Duration(hours: totalWorkHours.toInt());
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
      /*DocumentReference dailyDocRef = _firestore
      .collection('workingtime')
      .doc('widget.')
      .collection('2023')
      .doc('12')
      .collection('25')
      .doc('dailyWorkingTime');*/

      DocumentReference dailyDocRef = _firestore
      .collection('workingtime')
      .doc(widget.userDetails['companyId'])
      .collection(widget.selectedDate.year.toString())
      .doc(widget.selectedDate.month.toString())
      .collection(widget.selectedDate.day.toString())
      .doc('dailyWorkingTime');

      DocumentSnapshot dailyWorkingTimeSnapshot = await dailyDocRef.get();

      print(dailyWorkingTimeSnapshot.exists);

      if (dailyWorkingTimeSnapshot.exists) {
        print('success');
        print(dailyWorkingTimeSnapshot.data());

        setState(() {
          dailyWorkingTimeData =
              dailyWorkingTimeSnapshot.data() as Map<String, dynamic>;
        });
        print('This is');
        print(dailyWorkingTimeData);



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

  Future<void> transformGeoPoints() async {
    for (var record in widget.attendanceRecords) {
      String checkInAddress = await getAddressFromLocation(record['CheckInLocation']);
      String checkOutAddress = await getAddressFromLocation(record['CheckOutLocation']);
      setState(() {
        checkInAddresses.add(checkInAddress);
        checkOutAddresses.add(checkOutAddress);
      });
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

  @override
  Widget build(BuildContext context) {
    final fulltime = 24.0; // Ensure this is a double

    final lateHours = late != null ? late!.inHours.toDouble() : 0.0;
    final overtimeHours = overtime != null ? overtime!.inHours.toDouble(): 0.0;

    final latePercentage = lateHours / fulltime;
    final overtimePercentage = overtimeHours / fulltime;
    

    return Scaffold(
      /*appBar: MorphingAppBar(
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
      ),*/
      body:Stack(
        children:[
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
            Stack(
              children:[
  Container(
    width: double.infinity,
    height: 210,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.only(
        bottomRight: Radius.circular(210),  // Set rounded radius
        bottomLeft: Radius.circular(210),),
      gradient: LinearGradient(
        colors: [Color(0xFF73B9FF), Color(0xFF4D7EFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.3),
          spreadRadius: 3,
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
  ),
  Container(
      width: 280,
      height: 180,
      child: Padding(
        padding: EdgeInsets.only(top:7,right:20,left:30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24, // Adjust the width of the square
                  height: 24, // Adjust the height of the square
                    color: Color.fromARGB(255, 84, 114, 249), // Color of the square
                    margin: EdgeInsets.only(right: 1,bottom:1), // Margin between the square and text
                ),
                Text(
                'TOTAL WORK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color.fromARGB(255, 100, 39, 255),
                  letterSpacing: 0.1,
                  height: 0.5,
                  ),
                ),
              ],
            ),
            if (dailyWorkingTimeData != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: (dailyWorkingTimeData!['totalworkingtime']?? 0) / 24),
                duration: Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 10,
                        width: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                          colors: [Color(0xFF4D7EFF), Color.fromARGB(255, 94, 151, 209)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                      Positioned(
                        left: 0,
                        child: Container(
                          height: 10,
                          width: 280 * value,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: LinearGradient(
                              colors: [Color(0xFF4D7EFF), Color(0xFF73B9FF)],
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
                style: 
                TextStyle(
                  fontSize: 14, 
                  color: Colors.white),
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
                        tween: Tween(begin: 0.0, end: latePercentage), // Use latePercentage for late graph animation
                        duration: Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Container(
                            height: 5,
                            width: 280 * value, // Adjust the max width as needed
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: LinearGradient(
                                colors: [Colors.red, Colors.orange], // Adjust colors for late
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
                width: 100 * overtimePercentage, // Adjust the width of the overtime graph as needed
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
              if (dailyWorkingTimeData != null && dailyWorkingTimeData!['totalworkingtime'] != null)
              Align(
                alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(dailyWorkingTimeData!['totalworkingtime'] ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 50,
                        color: Colors.white,
                        height:0.77
                          ),
                        ),
                      SizedBox(width: 4), // Adjust the spacing between the value and 'hr'
                      Text(
                        'hr',
                        style: TextStyle(
                          fontSize: 14, // Change the font size as needed
                          color: Colors.white,
                          height:0.77,
                          
                        ),
                        
                      ),
                    ],
                  ),
                ),
              if (dailyWorkingTimeData == null || dailyWorkingTimeData!['totalworkingtime'] == null)
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
                      width: 120,
                      height: 120,
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
                      // If an image is available, you can use it here:
                      // child: Image.network(
                      //   widget.userDetails['Image'],
                      //   fit: BoxFit.cover,
                      // ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                              color: Colors.blue[400],
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue[200],
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                            border: Border.all(
                              color: Colors.blue[400]!,
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
        ]
      ),

      Expanded(
        child: Stack(
          children: [
        // Other widgets overlapping the ListView if needed
            Align(
              alignment: Alignment.centerRight,
              child:
                RotatedBox(
              quarterTurns: 1, // Rotating text by 90 degrees counter-clockwise
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0072FF), Color(0xFF00C6A7)], // Adjust gradient colors
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
                      fontSize: 150,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Text color
                      fontFamily: 'Montserrat', // Your desired font
                      fontStyle: FontStyle.italic,
                      height:1.1,
                      letterSpacing: 1.5, // Adjust letter spacing for a stylish look
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
                thumbColor: MaterialStateProperty.all<Color>(Colors.red),
              ),
            ),
            child:RawScrollbar(
              padding:EdgeInsets.symmetric(vertical: 30) ,
              thickness:20.0,
              radius:Radius.circular(5),
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              trackColor:Colors.blueGrey.withOpacity(0.2),
              thumbColor: const Color.fromARGB(255, 176, 206, 221).withOpacity(1.0),
              trackBorderColor: Colors.transparent,
              child:ShaderMask(
                shaderCallback: (Rect rect){
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
                    stops: [0.0, 0.1, 0.9, 1.0], // 10% purple, 80% transparent, 10% purple
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstOut,
                child:ListView.builder(
                controller: _scrollController, // Assign the same controller
                physics: AlwaysScrollableScrollPhysics(), // Ensure scrolling is always enabled
            itemCount: widget.attendanceRecords.length,
            padding: EdgeInsets.only(top: 40,right:100),
            //clipBehavior: Clip.none,
            itemBuilder: (BuildContext context, int index) {
              Map<String, dynamic> record = widget.attendanceRecords[index];
              return Padding(
                padding: EdgeInsets.only(top: 10, bottom: 0, right: 12, left: 4),
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
          ),
              )
              
            )
          ),
                // Other widgets overlapping the ListView if needed
              ],
            ),
          ),
        ],
      ),
        ]
      )
       
    );
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

    /*void _toggleSelection() {
    setState(() {
      isSelected = !isSelected;
    });*/

  @override
  Widget build(BuildContext context) {
    Color checkOutIconColor = Color.fromARGB(255, 176, 95, 95);
    Color checkInIconColor = Colors.teal;
    String checkInAddress = widget.checkInAddresses.length > widget.index
    ? widget.checkInAddresses[widget.index] ?? 'Address not available'
    : 'Address not available';

String checkOutAddress = widget.checkOutAddresses.length > widget.index
    ? widget.checkOutAddresses[widget.index] ?? 'Address not available'
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
            margin: EdgeInsets.only(top:10,bottom:0,right:12,left:4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: widget.isSelected ? Colors.blue : Colors.transparent,
                width: widget.isSelected ? 2 : 0,
              ),
            ),
            color: widget.isSelected ? Colors.blueGrey[50] :
             widget.index.isEven? Colors.white : Colors.grey[300],
            child: Material(
              borderRadius: BorderRadius.circular(20),
              color: widget.isSelected ? Colors.blueGrey[100] : Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  widget.onTap();
                },
                splashColor: widget.isSelected ? Colors.transparent : Colors.blueGrey.withOpacity(0.3),
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    ClipRect(
                      child: Container(
                        padding: EdgeInsets.only(top:16,bottom:16,right:16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Container(
  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
  decoration: BoxDecoration(
    color:widget. isSelected ? Colors.blue : Colors.deepPurple,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
)

,

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
                                      mainAxisAlignment: MainAxisAlignment.end,
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
          ),// Positioned Index Display
        // Positioned Index Display
    AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: widget.isSelected
          ? Matrix4.translationValues(-15, -27, 0)
          : Matrix4.translationValues(0, -10, 0),
      child: Container(
        padding: EdgeInsets.only(left:20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isSelected
                  ? [Colors.purple.withOpacity(0.5), Colors.deepOrange.withOpacity(0.7)]
                  : [Colors.lightBlue.withOpacity(0.0), Colors.teal.withOpacity(0.0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: widget.isSelected ? Colors.purple.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
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
              colors:widget. isSelected
                  ? [Colors.purple.withOpacity(0.5), Colors.deepOrange.withOpacity(0.7)]
                  : [Colors.lightBlue.withOpacity(0.0), Colors.teal.withOpacity(0.0)],
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
        color: widget.isSelected ? Colors.red : Colors.white.withOpacity(0.5),
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
        fontStyle: FontStyle.italic, // Apply italic style here
      ),
    ),
    Positioned(
      top: 0,
      left:10,
      child: Text(
        'No.',
        style: TextStyle(
          color: Colors.blueGrey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontStyle: FontStyle.italic, // Apply italic style here
        ),
      ),
    ),
  ],
),
        ),
      ),
    ),
    // Adjusted Index with Opacity
    /*AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: isSelected
          ? Matrix4.translationValues(-20, -27, 0)
          : Matrix4.translationValues(0, 0, 0),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                  ? [Colors.purple.withOpacity(0.9), Colors.deepOrange.withOpacity(0.7)]
                  : [Colors.lightBlue.withOpacity(0.9), Colors.teal.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Opacity(
            opacity: isSelected ? 1.0 : 0.0, // Set the opacity accordingly
            child: Text(
              '${widget.index+10}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 52,
              ),
            ),
          ),
        ),
      ),
    ),*/
      )],
      ),
    ),
  ),
);
  }
}

