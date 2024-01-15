import 'package:flutter/material.dart';
import 'package:flutter_application_1/leave/half_DayLeave_Page.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/data/data_model.dart';
import 'package:flutter_application_1/utils/checkholiday.dart';

// import 'package:flutter_application_1/leave/Leave_main_page.dart';

class ApplyLeave extends StatefulWidget {
  final String companyId;
  final String userPosition;

  ApplyLeave({Key? key, required this.companyId, required this.userPosition})
      : super(key: key);

  @override
  _ApplyLeave createState() => _ApplyLeave();
}

// ignore: must_be_immutable
class _ApplyLeave extends State<ApplyLeave> {
  final logger = Logger();

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  int? annualLeaveBalance;
  String leaveType = 'Annual';
  String fullORHalf = 'Full';
  DateTime? startDate;
  DateTime? endDate;
  double? leaveDay;
  String? reason;
  String remark = '-';
  DateTime selectedDate = DateTime.now();
  String status = 'pending';
  bool isDataLoaded = false;
  DateTime now = DateTime.now();

  String holidayDateCheck = '';

  Future<String> hasPublicHolidayBetween(
      DateTime? startDate, DateTime? endDate) async {
    // Check for public holidays between startDate and endDate (inclusive)
    DateTime currentDate = startDate!;
    logger.i("currentDateBeforeProcess $currentDate");
    while (currentDate.isBefore(endDate!) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (await isPublicHoliday(currentDate)) {
        logger.i("currentDateHoliday $currentDate");
        return "$currentDate"; // There is a public holiday between startDate and endDate
      }

      // Move to the next day
      currentDate = currentDate.add(Duration(days: 1));
    }
    logger.i("currentDateBeforeEnd $currentDate");
    // No public holiday found between startDate and endDate
    return "";
  }

  DateTime checkTodayWeekDay() {
    DateTime initialDate = startDate ?? DateTime.now();

    // Ensure initialDate is not a weekend
    while (initialDate.weekday == DateTime.saturday ||
        initialDate.weekday == DateTime.sunday) {
      initialDate = initialDate.add(Duration(days: 1));
    }

    return initialDate;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    holidayDateCheck = "";
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: checkTodayWeekDay(),
      firstDate: now,
      lastDate: DateTime(2100),
      selectableDayPredicate: (DateTime date) {
        // Disable weekends (Saturday and Sunday)
        return date.weekday != DateTime.saturday &&
            date.weekday != DateTime.sunday;
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        startDate = pickedDate;
        leaveDay = calculateWeekdayDifference();
      });
    }
    if (endDate != null) {
      if (startDate!.isAfter(endDate!)) {
        setState(() {
          endDate = null;
          leaveDay = calculateWeekdayDifference();
        });
      }
    }
    if (endDate != null) {
      holidayDateCheck = await hasPublicHolidayBetween(pickedDate!, endDate!);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    holidayDateCheck = "";
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? checkTodayWeekDay(),
      firstDate: startDate ?? checkTodayWeekDay(),
      lastDate: DateTime(2100),
      selectableDayPredicate: (DateTime date) {
        // Disable weekends (Saturday and Sunday)
        return date.weekday != DateTime.saturday &&
            date.weekday != DateTime.sunday;
      },
    );

    if (pickedDate != null) {
      if (startDate != null) {
        if (pickedDate.isAfter(startDate!) ||
            pickedDate.isAtSameMomentAs(startDate!)) {
          setState(() {
            endDate = pickedDate;
            leaveDay = calculateWeekdayDifference();
          });
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Invalid Date'),
              content: Text('End date cannot be earlier than start date.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invalid Start Date'),
            content: const Text('Please select start date first.'),
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
      }
    }
    if (startDate != null) {
      holidayDateCheck = await hasPublicHolidayBetween(startDate!, pickedDate!);
    }
  }

  double calculateWeekdayDifference() {
    if (startDate != null && endDate != null) {
      DateTime currentDay = startDate!;
      double weekdayDifference = 0.0;

      while (currentDay.isBefore(endDate!.add(Duration(days: 1)))) {
        if (currentDay.weekday != DateTime.saturday &&
            currentDay.weekday != DateTime.sunday) {
          weekdayDifference++;
        }
        currentDay = currentDay.add(Duration(days: 1));
      }

      return weekdayDifference;
    }

    return 0;
  }

  // Future<double> calculateWeekdayDifference() async {
  //   if (startDate != null && endDate != null) {
  //     DateTime currentDay = startDate!;
  //     double weekdayDifference = 0.0;

  //     while (currentDay.isBefore(endDate!.add(Duration(days: 1)))) {
  //       if (currentDay.weekday != DateTime.saturday &&
  //           currentDay.weekday != DateTime.sunday) {
  //         weekdayDifference++;

  //         bool isHoliday = await isPublicHoliday(currentDay);

  //         if (isHoliday) {
  //           weekdayDifference--;
  //         }
  //       }
  //       currentDay = currentDay.add(Duration(days: 1));
  //     }

  //     return weekdayDifference;
  //   }

  //   return 0;
  // }

  Future<void> _createLeave() async {
    logger.i(widget.companyId);
    await LeaveModel().createLeave(widget.companyId, {
      'leaveType': leaveType,
      'fullORHalf': fullORHalf,
      'startDate': startDate,
      'endDate': endDate,
      'leaveDay': leaveDay,
      'reason': reason,
      'remark': remark,
      'status': status
    });

    Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();

    // Fetch user data when the page is initialized
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final userData = await LeaveModel().getUserData(widget.companyId);

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
          title: const Text(
            'Leave Application',
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
              Navigator.pop(context, true);
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
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: const Text(
                    "Leave Type",
                    style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 224, 45, 255),
                        fontWeight: FontWeight.bold),
                  ),
                ),

                ToggleSwitch(
                  minWidth: 150.0,
                  initialLabelIndex: leaveType == 'Annual' ? 0 : 1,
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
                  totalSwitches: 2,
                  labels: const ['Annual', 'Unpaid'],
                  customTextStyles: const [
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
                  ],
                  onToggle: (index) {
                    if (index == 0) {
                      String selectedLabel = 'Annual';
                      leaveType = selectedLabel;
                    } else if (index == 1) {
                      String selectedLabel = 'Unpaid';
                      leaveType = selectedLabel;
                    }
                  },
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: const Text(
                    "Full/Half",
                    style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 224, 45, 255),
                        fontWeight: FontWeight.bold),
                  ),
                ),

                ToggleSwitch(
                  minWidth: 150.0,
                  initialLabelIndex: 0,
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
                  totalSwitches: 2,
                  labels: const ['Full', 'Half'],
                  customTextStyles: const [
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
                  ],
                  onToggle: (index) {
                    print('switched to: $index');
                    if (index == 1) {
                      // Navigate to the 'Half' page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HalfDayLeave(
                                  companyId: widget.companyId,
                                  userPosition: widget.userPosition,
                                )),
                      );
                    }
                  },
                ),

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
                        height: 45, // Set the height as per your requirement
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
                        width: 150, // Set the width as per your requirement
                        height: 45, // Set the height as per your requirement
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            _selectStartDate(context);
                          },
                          child: AbsorbPointer(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Select Date',
                                  border: InputBorder.none,
                                ),
                                validator: (value) {
                                  if (startDate == null) {
                                    return 'Please select your date of birth';
                                  }
                                  return null;
                                },
                                onSaved: (value) {},
                                controller: TextEditingController(
                                  text: startDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(startDate!)
                                      : '',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                        width: 150, // Set the width as per your requirement
                        height: 45, // Set the height as per your requirement
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            _selectEndDate(context);
                          },
                          child: AbsorbPointer(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 0),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  hintText: 'Select Date',
                                  border: InputBorder.none,
                                ),
                                validator: (value) {
                                  if (endDate == null) {
                                    return 'Please select your date of birth';
                                  }
                                  return null;
                                },
                                onSaved: (value) {},
                                controller: TextEditingController(
                                  text: endDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(endDate!)
                                      : '',
                                ),
                              ),
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
                        width: 150, // Set the width as per your requirement
                        height: 45, // Set the height as per your requirement
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Center(
                          child: Text(
                            '${leaveDay?.toStringAsFixed(0) ?? 0}',
                            style: const TextStyle(fontSize: 18),
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
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          child: TextField(
                            controller: _reasonController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Text',
                            ),
                            onChanged: (value) {
                              reason = value;
                            },
                            onEditingComplete: () {
                              reason = _reasonController.text;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                    width: 300, // Set the width as per your requirement
                    height: 80, // Set the height as per your requirement
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 238, 238, 238),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _remarkController,
                        maxLines:
                            null, // Set to null to allow for multiple lines
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Optional Field',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                ElevatedButton(
                  onPressed: () async {
                    if (startDate == null ||
                        endDate == null ||
                        reason == null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Empty Space Detected'),
                          content: const Text(
                              'Please fill in all the required information'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                logger.i('startDate $startDate');
                                logger.i('endDate $endDate');
                                logger.i('reason $reason');
                                logger.i('leaveDay $leaveDay');
                                logger.i('leaveDay ${leaveDay is double}');
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else if (holidayDateCheck != "") {
                      logger.i("holidayDateCheckInDialog $holidayDateCheck");
                      // logger.i(
                      //     "hasPublicHolidayBetween(startDate!, endDate!) ${hasPublicHolidayBetween(startDate!, endDate!) != }");
                      // // String holidayDate =
                      //     await hasPublicHolidayBetween(startDate!, endDate!);
                      String formattedHolidayDate = holidayDateCheck
                          .split(' ')[0]; // Extracting yyyy-mm-dd

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Holiday Date'),
                          content: Text(
                              'There is a public holiday on $formattedHolidayDate, Please choose a different dates.'),
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
                    } else if (leaveType == 'Annual') {
                      if (leaveDay! > annualLeaveBalance!) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Invalid Date'),
                            content: const Text(
                                'Your have exceeeded your annual limit'),
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
                      } else {
                        logger.i('success');
                        reason = _reasonController.text;
                        remark = _remarkController.text.isNotEmpty
                            ? _remarkController.text
                            : '-';
                        _createLeave();
                      }
                    } else {
                      logger.i('success');
                      reason = _reasonController.text;
                      remark = _remarkController.text.isNotEmpty
                          ? _remarkController.text
                          : '-';
                      _createLeave();
                    }
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            30.0), // Set the corner radius
                      ),
                    ),
                    fixedSize: MaterialStateProperty.all<Size>(
                      const Size(150, 50), // Set the width and height
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
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
                    'Confirm',
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
        ));
  }
}
