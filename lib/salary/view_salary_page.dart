import 'package:flutter/material.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:math';
import 'package:month_year_picker/month_year_picker.dart';

import 'package:flutter_application_1/data/repositories/profile_repository.dart';
import 'package:flutter_application_1/data/repositories/bonus_repository.dart';
import 'package:flutter_application_1/data/repositories/workingtime_repository.dart';
import 'package:flutter_application_1/data/repositories/leave_repository.dart';
import 'package:flutter_application_1/data/repositories/claim_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application_1/main.dart';

class ViewSalaryPage extends StatefulWidget {
  final String companyId;
  final DateTime selectedMonth;

  const ViewSalaryPage(
      {Key? key, required this.companyId, required this.selectedMonth})
      : super(key: key);

  @override
  _ViewSalaryPageState createState() => _ViewSalaryPageState();
}

List<int> countWeekdaysInEachMonth(int year) {
  List<int> monthWeekdays = List<int>.filled(12, 0);

  for (int month = 1; month <= 12; month++) {
    int weekdaysCount = countWeekdays(year, month);
    monthWeekdays[month - 1] = weekdaysCount;
  }

  return monthWeekdays;
}

int countWeekdays(int year, int month) {
  int weekdaysCount = 0;
  // DateTime firstDay = DateTime(year, month, 1);
  int lastDay = DateTime(year, month + 1, 0).day;

  for (int day = 1; day <= lastDay; day++) {
    DateTime currentDate = DateTime(year, month, day);

    if (currentDate.weekday >= DateTime.monday &&
        currentDate.weekday <= DateTime.friday) {
      weekdaysCount++;
    }
  }

  return weekdaysCount;
}

class _ViewSalaryPageState extends State<ViewSalaryPage> {
  final logger = Logger();
  int weekdayCount = 0;
  DateTime _selected = DateTime.now();
  TextEditingController monthYearController = TextEditingController();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  TextEditingController basicSalaryController = TextEditingController();
  TextEditingController epfNoController = TextEditingController();
  TextEditingController socsoNoController = TextEditingController();

  String name = '';
  String email = '';
  String phone = '';
  DateTime? dateOfBirth;
  String? selectedPosition;
  String? pickedImagePath;
  String imageUrl = '';
  late DateTime joiningDate;
  bool status = true;
  String accountNumber = '';
  String selectedBank = ' ';
  num basicSalary = 0.0;
  String epfNo = '';
  String socsoNo = '';

  String pdfPath = '';
  String pdfName = '';
  final Set<int> usedNotificationIds = {};

  num bonusAmount = 0;
  String formattedBonusAmount = '';
  Future<void>? userDataFuture; // Declare the future variable
  bool _isUserDataFetched = false;

  double normalWorkingTime = 0.0;
  double normalOT = 0.0;
  double holidayWorkingTime = 0.0;
  double holidayOT = 0.0;
  double lessnormalWorkingTime = 0.0;
  int holidayCount = 0;

  late Map<String, double> unpaidLeaveDay;

  double medicalClaim = 0.0;
  double travelClaim = 0.0;
  double mealClaim = 0.0;
  double fuelClaim = 0.0;
  double entertainmentClaim = 0.0;

  late DateTime pickedDate;

  @override
  void initState() {
    super.initState();

    _selected = widget.selectedMonth;
    final DateTime now = DateTime.now();
    monthYearController.text = '${now.month}-${now.year}';
  }

  Future<void> fetchUserData() async {
    try {
      logger.i("Start $_isUserDataFetched");
      // Check if user data has already been fetched
      if (_isUserDataFetched) {
        return;
      }
      weekdayCount = countWeekdays(_selected.year, _selected.month);
      weekdayCount -= holidayCount;

      Map<String, Map<String, dynamic>> claimdata =
          await getClaimSummary(widget.companyId, _selected);

      // // Access the 'summary' key to get the calculated values
      Map<String, dynamic>? claimsummary = claimdata['summary'];

      // // Set the fetched user data to the state variables
      medicalClaim = claimsummary?['medicalClaim'] ?? 0.0;
      travelClaim = claimsummary?['travelClaim'] ?? 0.0;
      mealClaim = claimsummary?['mealClaim'] ?? 0.0;
      fuelClaim = claimsummary?['fuelClaim'] ?? 0.0;
      entertainmentClaim = claimsummary?['entertainmentClaim'] ?? 0.0;

      unpaidLeaveDay = await getLeaveDays(widget.companyId, _selected);

      if (_isUserDataFetched == false) {
        // Call the function to get the monthly working time
        Map<String, Map<String, dynamic>> monthlyWorkingTime =
            await getMonthlyWorkingTime(widget.companyId, _selected);

        // Access the 'summary' key to get the calculated values
        Map<String, dynamic>? summary = monthlyWorkingTime['summary'];

        normalWorkingTime = summary?['normalWorkingTime'] ?? 0.0;
        normalOT = summary?['normalOT'] ?? 0.0;
        holidayWorkingTime = summary?['holidayWorkingTime'] ?? 0.0;
        holidayOT = summary?['holidayOT'] ?? 0.0;
        lessnormalWorkingTime = summary?['lessnormalWorkingTime'] ?? 0.0;
        holidayCount = summary?['holidayCount'] ?? 0;

        logger.i('normalWorkingTime1 $normalWorkingTime');
      }
      final userData = await ProfileRepository()
          .getPreviousUserData(widget.companyId, _selected);

      // ignore: unnecessary_null_comparison
      if (userData != null) {
        // Set the fetched user data to the state variables
        setState(() {
          name = userData['name'] ?? '';
          selectedBank = userData['bankName'] ?? '';
          accountNumber = userData['accountNumber'] ?? '';
          basicSalary = userData['basicSalary'] ?? '';
          epfNo = userData['epfNo'] ?? '';
          socsoNo = userData['socsoNo'] ?? '';
          joiningDate = userData['joiningdate'].toDate() ?? '';

          nameController.text = name;
          accountNumberController.text = accountNumber;
          basicSalaryController.text = basicSalary.toString();
          epfNoController.text = epfNo;
          socsoNoController.text = socsoNo;
        });
        bonusAmount = await getBonus('${widget.companyId}', _selected);
        formattedBonusAmount = bonusAmount.toStringAsFixed(2);

        // Set the flag to indicate that user data has been fetched
      } else {
        // Handle the case when user data is not found
        logger.e('User data not found for companyId: ${widget.companyId}');
      }
      _isUserDataFetched = true;
      logger.i("End $_isUserDataFetched");
    } catch (e) {
      // Handle errors during data fetching
      logger.e('Error fetching user data: $e');
    }
  }

  Future<String> getUniqueFileName(String baseName, String extension) async {
    final directory = '/storage/emulated/0/Download';
    final basePath = directory;
    int suffix = 0;

    while (await File(
            '$basePath/$baseName${suffix == 0 ? '' : '($suffix)'}.$extension')
        .exists()) {
      suffix++;
    }

    // pdfPath = '$basePath/$baseName${suffix == 0 ? '' : '($suffix)'}.$extension';
    pdfName = '$baseName${suffix == 0 ? '' : '($suffix)'}.$extension';
    return '$basePath/$baseName${suffix == 0 ? '' : '($suffix)'}.$extension';
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color.fromARGB(255, 193, 85, 254),
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final Set<int> usedNotificationIds = {};
    Random random = Random();
    int notificationId;

    // Generate a unique notification ID
    do {
      notificationId = random.nextInt(999999);
    } while (usedNotificationIds.contains(notificationId));

    // Add the used ID to the set
    usedNotificationIds.add(notificationId);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      '$pdfName Download Complete',
      'Tap to open the PDF',
      platformChannelSpecifics,
      payload: pdfPath,
    );
  }

  Future<bool> saveAsPDF() async {
    final pdf = pw.Document();

    // Use the font in the document
    // final font = await PdfGoogleFonts.nunitoExtraLight();

    pw.Table _buildInfoTable(String label, String value, bool alignRight) {
      final pw.TableBorder border = pw.TableBorder.all(
        color: PdfColors.grey, // Customize the color
        width: 0.5, // Adjust the border width as needed
      );

      return pw.Table(
        border: border,
        children: [
          pw.TableRow(
            children: [
              pw.Container(
                width: 140,
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(label, style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Container(
                width: 360,
                padding: const pw.EdgeInsets.all(5),
                alignment: alignRight
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                child: pw.Text(
                  value,
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      );
    }

    pw.Table _build4ColumnTable(
        String label, num hour, num rate, String inputString, bool alignRight) {
      final pw.TableBorder border = pw.TableBorder.all(
        color: PdfColors.grey, // Customize the color
        width: 0.5, // Adjust the border width as needed
      );

      return pw.Table(
        border: border,
        children: [
          pw.TableRow(
            children: [
              pw.Container(
                width: 140,
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(label, style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Container(
                width: 120,
                padding: const pw.EdgeInsets.all(5),
                alignment: alignRight
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                child: pw.Text(
                  hour.toStringAsFixed(2),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Container(
                width: 120,
                padding: const pw.EdgeInsets.all(5),
                alignment: alignRight
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                child: pw.Text(
                  (inputString == "OT")
                      ? (basicSalary / weekdayCount / 8 * rate)
                          .toStringAsFixed(2)
                      : (rate).toStringAsFixed(2),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Container(
                width: 120,
                padding: const pw.EdgeInsets.all(5),
                alignment: alignRight
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                child: pw.Text(
                  (inputString == "OT")
                      ? (hour * (basicSalary / weekdayCount / 8 * rate))
                          .toStringAsFixed(2)
                      : (hour + rate).toStringAsFixed(2),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      );
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                color: PdfColors.grey200,
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Pay Slip for Period Ending',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Positioned(
                      right: 0,
                      bottom: 0,
                      child: pw.Text(
                        ' ${DateFormat('MMMM yyyy').format(_selected)} (Monthly)',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: PdfColors.blue,
                        ),
                      ),
                    ),
                    pw.Positioned(
                      right: 0,
                      bottom: 0,
                      child: pw.Text(
                        ' (RM)',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              _buildInfoTable('CompanyID:', '${widget.companyId}', false),
              _buildInfoTable('Name:', '$name', false),
              _buildInfoTable('Payment Method:',
                  '$selectedBank (Account: $accountNumber)', false),
              // Content
              pw.SizedBox(height: 15),
              pw.SizedBox(height: 5),
              _buildInfoTable(
                  'Basic Salary', basicSalary.toStringAsFixed(2), true),

              _buildInfoTable('Total Overtime',
                  calculateTotalOT().toStringAsFixed(2), true),

              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey,
                  width: 0.5,
                ),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                          width: 140,
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          )),
                      pw.Container(
                        width: 120,
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          'Hours',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 120,
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          'HourlyPay',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 120,
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          'Sub-Total',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              _build4ColumnTable('[OT1.5]', normalOT, 1.5, 'OT', true),
              _build4ColumnTable(
                  '[OT2.0]', holidayWorkingTime, 2.0, 'OT', true),
              _build4ColumnTable('[OT3.0]', holidayOT, 3.0, 'OT', true),
              if (medicalClaim != 0.0)
                _buildInfoTable(
                    'Medical Claim', medicalClaim.toStringAsFixed(2), true),
              if (travelClaim != 0.0)
                _buildInfoTable(
                    'Travel Claim', travelClaim.toStringAsFixed(2), true),
              if (mealClaim != 0.0)
                _buildInfoTable(
                    'Meal Claim', mealClaim.toStringAsFixed(2), true),
              if (fuelClaim != 0.0)
                _buildInfoTable(
                    'Fuel Claim', fuelClaim.toStringAsFixed(2), true),
              if (entertainmentClaim != 0.0)
                _buildInfoTable('Entertainment Claim',
                    entertainmentClaim.toStringAsFixed(2), true),
              _buildInfoTable(
                  'Total No Pay', totalnopay().toStringAsFixed(2), true),
              _buildInfoTable('Bonus', formattedBonusAmount, true),
              _buildInfoTable(
                  'Statutory Contribution',
                  '${(calculateEPF('employer') + calculateEPF('employee') + calculateSOCSO('employer') + calculateSOCSO('employee') + (calculateEIS() * 2.0)).toStringAsFixed(2)}',
                  true),

              _buildInfoTable(
                  'Net Salary', calculateNetSalary().toStringAsFixed(2), true),
              pw.SizedBox(height: 10),
              pw.Text('Statutory Contribution:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              _build4ColumnTable('EPF:', calculateEPF('employer'),
                  calculateEPF('employee'), 'statutory', true),
              _build4ColumnTable('SOCSO:', calculateSOCSO('employer'),
                  calculateSOCSO('employee'), 'statutory', true),
              _build4ColumnTable(
                  'EIS:', calculateEIS(), calculateEIS(), 'statutory', true),
              _build4ColumnTable(
                  'Total:',
                  calculateEPF('employer') +
                      calculateSOCSO('employer') +
                      calculateEIS(),
                  calculateEPF('employee') +
                      calculateSOCSO('employee') +
                      calculateEIS(),
                  'statutory',
                  true),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    try {
      // Create a unique file name within the "Download" directory
      final uniqueFileName = await getUniqueFileName(
          '${name}_SalarySlip_${DateFormat('MMMMyyyy').format(widget.selectedMonth)}',
          'pdf');

      // Create a File object with the unique PDF file name
      final file = File(uniqueFileName);

      // Write the PDF content to the file
      await file.writeAsBytes(await pdf.save());

      logger.i('PDF file path: ${file.path}');

      pdfPath = file.path;
      showNotification();

      return true; // Download successful
    } catch (e) {
      logger.e('Error saving PDF: $e');
      return false; // Download failed
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Line144: $name');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
          size: 30,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'View Payroll',
          style: TextStyle(
            color: Colors.black87, // Adjust text color for modern style
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt), // Use the save icon you prefer
            onPressed: saveAsPDF,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<void>(
          future: fetchUserData(), // Replace with your data fetching function
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      // Adjust the fraction (0.1 in this case) as needed
                    ),
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
              return Center(
                child: Text('Error loading data: ${snapshot.error}'),
              );
            } else {
              // Continue with your UI when data is available
              return Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(
                          16.0), // Adjust the padding as needed
                      child: GestureDetector(
                        onTap: () async {
                          // Show date picker and update the text when a date is selected
                          pickedDate = (await showMonthYearPicker(
                            context: context,
                            initialDate: _selected,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          ))!;

                          pickedDate = DateTime(
                              pickedDate.year, pickedDate.month + 1, 0);

                          if (pickedDate.isBefore(joiningDate)) {
                            // Notify the user that the selected date is after the joining date
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'The selected date is before you joined the company. Please choose again.',
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            // ignore: unnecessary_null_comparison
                          } else if (pickedDate != null) {
                            setState(() {
                              _selected = pickedDate;
                              monthYearController.text =
                                  '${pickedDate.month}-${pickedDate.year}';
                              _isUserDataFetched = false;
                            });
                          }
                        },
                        child: Center(
                          child: Container(
                            width: 160,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Month-Year Text
                                Text(
                                  DateFormat('MMM yyyy').format(
                                      _selected), // Format the selected month and year
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color.fromRGBO(229, 63, 248, 1),
                                  ),
                                ),
                                SizedBox(width: 10),

                                // Calendar Icon
                                Icon(
                                  Icons.calendar_today,
                                  size: 30,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Name: $name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'CompanyID: ${widget.companyId}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Pay Period: 1 ${DateFormat('MMM yyyy').format(_selected)} - ${DateFormat('dd MMM yyyy').format(DateTime(_selected.year, _selected.month + 1, 0))}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.0),
                    _buildPayrollDetails(),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildRow('Salary Credited To', selectedBank,
                          bold: true),
                    ),
                    SizedBox(height: 8.0),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child:
                          _buildRow('Bank Account', accountNumber, bold: true),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  num calculateEPF(String name) {
    num tempSalary = basicSalary + bonusAmount - totalnopay();

    if (tempSalary <= 5000) {
      num tempSalaryWithoutHundreds;
      if (tempSalary.truncateToDouble() == tempSalary) {
        tempSalaryWithoutHundreds = tempSalary - (tempSalary % 10);
        if ((tempSalary % 100) % 20 != 0) {
          tempSalaryWithoutHundreds += 10;
        }
      } else {
        tempSalaryWithoutHundreds = tempSalary - (tempSalary % 10) + 10;
        if ((tempSalaryWithoutHundreds % 100) % 20 != 0) {
          tempSalaryWithoutHundreds += 10;
        }
      }
      // Calculate EPF based on the given name (employee or employer)
      if (name == 'employee') {
        // return checkhundred;
        return (tempSalaryWithoutHundreds * 0.11)
            .ceil(); // Round up if not an integer
      } else if (name == 'employer') {
        return (tempSalaryWithoutHundreds * 0.13)
            .ceil(); // Round up if not an integer
      }

      // Calculate EPF based on the given name (employee or employer)
      if (name == 'employee') {
        return (tempSalary * 0.11).ceil(); // Round up if not an integer
      } else if (name == 'employer') {
        return (tempSalary * 0.13).ceil(); // Round up if not an integer
      }
    } else {
      num tempSalaryWithoutHundreds;
      if (tempSalary.truncateToDouble() == tempSalary) {
        tempSalaryWithoutHundreds = tempSalary - (tempSalary % 100);
      } else {
        tempSalaryWithoutHundreds = tempSalary - (tempSalary % 100) + 100;
      }
      // Calculate EPF based on the given name (employee or employer)
      if (name == 'employee') {
        // return checkhundred;
        return (tempSalaryWithoutHundreds * 0.11)
            .ceil(); // Round up if not an integer
      } else if (name == 'employer') {
        return (tempSalaryWithoutHundreds * 0.12)
            .ceil(); // Round up if not an integer
      }
    }

    return 0;
  }

  num calculateEIS() {
    num wages = basicSalary + bonusAmount - totalnopay();
    num baseWage = 200; // RM200 as the starting point
    num baseContribution = 0.50; // 50 sen for the base wage
    num increaseRate =
        0.20; // 20 sen increase for every RM100 increase in wages
    if (wages > 5000) wages = 5000; //capped at RM5000

    if (wages <= baseWage) {
      // If wages are RM200 or below, no EIS contribution
      return 0.0;
    } else if (wages == 200) {
      return baseContribution;
    } else if (wages > 200) {
      // Calculate the additional contribution based on the increase in wages
      num additionalContribution =
          ((wages - baseWage) / 100).floor() * increaseRate;

      // Round the result to 2 decimal places
      String totalContribution =
          (baseContribution + additionalContribution).toStringAsFixed(2);

      // Convert the result back to a num
      return num.parse(totalContribution);
    }

    return 0;
  }

  num calculateSOCSO(String name) {
    num wages = basicSalary + bonusAmount - totalnopay();
    num baseWage = 200; // RM200 as the starting point
    // num baseContribution = (baseWage * 2 + 100) / 2 * 0.0175;
    num rate = 0.0;

    if (wages > 5000) wages = 5000; //capped at RM5000
    if (name == 'employee') {
      rate = 0.005;
    } else if (name == 'employer') {
      rate = 0.0175;
    }

    if (wages <= baseWage) {
      // If wages are RM200 or below, use the base contribution
      return 0.00;
    } else {
      // Remove the tens place from wages
      num adjustedWages = (wages ~/ 100) * 100;
      // Calculate the contribution based on the formula
      num firstcalculatedContribution = (((adjustedWages * 2) + 100) / 2);
      num calculatedContribution = firstcalculatedContribution * rate;

      calculatedContribution =
          double.parse(calculatedContribution.toStringAsFixed(3));

      // Check the second and third decimal points
      num secondDecimal = ((calculatedContribution * 1000) % 100).toInt();

      // Adjust the contribution based on the conditions
      if (secondDecimal == 50) {
        // If the second decimal is 5 and the third decimal is 0, do nothing
      } else if ((secondDecimal == 25)) {
        // If the second and third decimals are 25, add 0.025
        calculatedContribution += 0.025;
      } else {
        // For other cases, subtract 0.025
        calculatedContribution -= 0.025;
      }

      // Return the adjusted contribution
      return calculatedContribution;
    }
  }

  num calculateStatutoryContribution() {
    return calculateEPF('employer') +
        calculateEPF('employee') +
        calculateSOCSO('employer') +
        calculateSOCSO('employee') +
        (calculateEIS() * 2.0);
  }

  num calculateEmployeeStatutoryContribution() {
    return calculateEPF('employee') +
        calculateSOCSO('employee') +
        (calculateEIS());
  }

  num calculateNetSalary() {
    num netSalary = basicSalary +
        bonusAmount +
        calculateTotalOT() -
        calculateEmployeeStatutoryContribution() -
        insuffientHoursFine() -
        (unpaidLeaveDay['Unpaid']!) * (basicSalary / weekdayCount);

    return max(0, netSalary);
  }

  num calculateTotalOT() {
    return (basicSalary / weekdayCount / 8 * 1.5 * normalOT) +
        (basicSalary / weekdayCount / 8 * 2.0 * holidayWorkingTime) +
        (basicSalary / weekdayCount / 8 * 3.0 * holidayOT);
  }

  num mustWorkTime() {
    num monthlyWorkingTime = weekdayCount * 8;
    // num holidayHours = holidayCount * 8;
    // num mustWorkTime = monthlyWorkingTime - holidayHours;
    num mustWorkTime = monthlyWorkingTime;
    if (unpaidLeaveDay['Unpaid'] != 0.0) {
      mustWorkTime -= (unpaidLeaveDay['Unpaid']! * 8);
    }
    if (unpaidLeaveDay['Annual'] != 0.0) {
      mustWorkTime -= (unpaidLeaveDay['Annual']! * 8);
    }

    return mustWorkTime;
  }

  num insuffientHoursFine() {
    if (normalWorkingTime < mustWorkTime()) {
      return (mustWorkTime() - normalWorkingTime) *
          (basicSalary / weekdayCount / 8);
    } else {
      return 0.0;
    }
  }

  num totalnopay() {
    return insuffientHoursFine() +
        (unpaidLeaveDay['Unpaid']! * (basicSalary / weekdayCount));
  }

  Widget _buildOvertimeDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (normalOT != 0.0 || holidayWorkingTime != 0.0 || holidayOT != 0.0)
          Column(
            children: [
              _buildRow(
                'TOTAL OVER TIME',
                (calculateTotalOT().toStringAsFixed(2)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'OT Period(s) 01-${DateFormat('MM-yyyy').format(_selected)} to ${DateFormat('dd-MM-yyyy').format(DateTime(_selected.year, _selected.month + 1, 0))}',
                ),
              ),
              SizedBox(height: 8.0),
            ],
          ),
        if (normalOT != 0.0)
          Column(
            children: [
              _buildRow(
                '[OT 1.5] ${normalOT.toStringAsFixed(2)} Hrs x ${(basicSalary / weekdayCount / 8 * 1.5).toStringAsFixed(2)}',
                (basicSalary / weekdayCount / 8 * 1.5 * normalOT)
                    .toStringAsFixed(2),
              ),
              SizedBox(height: 8.0),
            ],
          ),
        if (holidayWorkingTime != 0.0)
          Column(
            children: [
              _buildRow(
                '[OT 2.0] ${holidayWorkingTime.toStringAsFixed(2)} Hrs x ${(basicSalary / weekdayCount / 8 * 2.0).toStringAsFixed(2)}',
                (basicSalary / weekdayCount / 8 * 2.0 * holidayWorkingTime)
                    .toStringAsFixed(2),
              ),
              SizedBox(height: 8.0),
            ],
          ),
        if (holidayOT != 0.0)
          Column(
            children: [
              _buildRow(
                '[OT 3.0] ${holidayOT.toStringAsFixed(2)} Hrs x ${(basicSalary / weekdayCount / 8 * 3.0).toStringAsFixed(2)}',
                (basicSalary / weekdayCount / 8 * 3.0 * holidayOT)
                    .toStringAsFixed(2),
              ),
              SizedBox(height: 8.0),
            ],
          ),
      ],
    );
  }

  Widget _buildClaimDetails() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (medicalClaim != 0.0 ||
          travelClaim != 0.0 ||
          mealClaim != 0.0 ||
          fuelClaim != 0.0 ||
          entertainmentClaim != 0.0)
        Column(
          children: [
            Text(
              'CLAIM',
            ),
          ],
        ),
      if (medicalClaim != 0.0)
        Column(
          children: [
            _buildRow(' - MEDICAL CLAIM', medicalClaim.toStringAsFixed(2)),
            SizedBox(height: 8.0),
          ],
        ),
      if (travelClaim != 0.0)
        Column(
          children: [
            _buildRow(' - TRAVEL CLAIM', travelClaim.toStringAsFixed(2)),
            SizedBox(height: 8.0),
          ],
        ),
      if (mealClaim != 0.0)
        Column(
          children: [
            _buildRow(' - MEAL CLAIM', mealClaim.toStringAsFixed(2)),
            SizedBox(height: 8.0),
          ],
        ),
      if (fuelClaim != 0.0)
        Column(
          children: [
            _buildRow(' - FUEL CLAIM', fuelClaim.toStringAsFixed(2)),
            SizedBox(height: 8.0),
          ],
        ),
      if (entertainmentClaim != 0.0)
        Column(
          children: [
            _buildRow(' - ENTERTAINMENT CLAIM',
                entertainmentClaim.toStringAsFixed(2)),
            SizedBox(height: 8.0),
          ],
        ),
    ]);
  }

  Widget _buildPayrollDetails() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow(
              'BASIC PAY($weekdayCount Days x ${(basicSalary / weekdayCount).toStringAsFixed(2)})',
              (basicSalary).toStringAsFixed(2)),
          SizedBox(height: 8.0),
          _buildRow('BONUS', formattedBonusAmount),
          SizedBox(height: 8.0),
          _buildOvertimeDetails(),
          _buildClaimDetails(),
          _buildRow('TOTAL NO PAY', totalnopay().toStringAsFixed(2)),
          Text(
            '[${DateFormat('yyyy-MM').format(_selected)}-01 TO ${DateFormat('yyyy-MM-dd').format(DateTime(_selected.year, _selected.month + 1, 0))}]',
          ),
          Text(
              '- Unpaid Leaves - ${unpaidLeaveDay['Unpaid']} Days = ${((unpaidLeaveDay['Unpaid']!) * (basicSalary / weekdayCount)).toStringAsFixed(2)}'),
          Text(
              '- Insufficient Hours Fine - ${(mustWorkTime() - normalWorkingTime).toStringAsFixed(2)} Hours = ${(insuffientHoursFine().toStringAsFixed(2))}'),
          SizedBox(height: 8.0),
          _buildRow('STATUTORY CONTRIBUTION',
              (calculateStatutoryContribution().toStringAsFixed(2))),
          SizedBox(height: 8.0),
          _buildRow('- EMPLOYEE EPF',
              '${calculateEPF('employee')}.00'), //11% of the basic salary(after deduct unpaid salary)
          _buildRow('- EMPLOYEE EIS',
              ('${calculateEIS()}0')), //0.2% of the basic salary
          _buildRow('- EMPLOYEE SOCSO',
              ('${calculateSOCSO('employee')}0')), //0.5% of the basic salary
          _buildRow('- EMPLOYER EPF',
              '${calculateEPF('employer')}.00'), //13% of the basic salary(after deduct unpaid salary)
          _buildRow(
            '- EMPLOYER EIS',
            ('${calculateEIS()}0'), //0.2% of the basic salary
          ),
          _buildRow('- EMPLOYER SOCSO',
              ('${calculateSOCSO('employer')}0')), //1.75% of the basic salary
          SizedBox(height: 16.0),

          _buildRow('NET SALARY',
              ((calculateNetSalary()).toStringAsFixed(2))), //Net Salary
        ],
      ),
    );
  }

  Widget _buildRow(String leftText, String rightText, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            leftText,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            rightText,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            textAlign: TextAlign.right,
            softWrap: false, // Do not wrap to multiple lines
            overflow: TextOverflow.ellipsis, // Truncate text if it overflows
          ),
        ),
      ],
    );
  }
}
