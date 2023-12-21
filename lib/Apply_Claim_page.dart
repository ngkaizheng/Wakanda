import 'package:flutter/material.dart';
import 'package:flutter_application_1/main_page.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/models/data_model.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
//import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';

final List<String> types = [
  'Medical',
  'Travel',
  'Meal',
  'Fuel',
  'Entertainment',
];

class ApplyClaim extends StatefulWidget {
  final String companyId;
  final String userPosition;

  ApplyClaim({Key? key, required this.companyId, required this.userPosition})
      : super(key: key);

  @override
  _ApplyClaim createState() => _ApplyClaim();
}

// ignore: must_be_immutable
class _ApplyClaim extends State<ApplyClaim> {
  final logger = Logger();

  // final TextEditingController _startDateController = TextEditingController();
  // final TextEditingController _endDateController = TextEditingController();
  // final TextEditingController _annualBalanceController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  String? claimType;
  DateTime? claimDate;
  double? claimAmount;
  String remark = '-';
  DateTime selectedDate = DateTime.now();
  String status = 'pending';
  bool isDataLoaded = false;
  String? pickedImagePath;
  String imageUrl = '';

  int _amount = 0;
  Timer? _timer;
  TextEditingController _textEditingController = TextEditingController();

  void _startIncrementTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _increment();
    });
  }

  void _startDecrementTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _decrement();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _increment() {
    setState(() {
      _amount++;
      _textEditingController.text = '$_amount';
    });
  }

  void _decrement() {
    if (_amount > 0) {
      setState(() {
        _amount--;
        _textEditingController.text = '$_amount';
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        claimDate = pickedDate;
      });
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> _createLeave() async {
    logger.i("123");
    logger.i(widget.companyId);
    imageUrl = await LeaveModel().uploadImage(pickedImagePath!, widget.companyId);
    await LeaveModel().createClaim(widget.companyId, {
      'claimType': claimType,
      'claimDate': claimDate,
      'claimAmount': claimAmount,
      'remark': remark,
      'image': imageUrl,
      'status': status
    });

    // Navigate back to the profile page
    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MainPage(
                companyId: widget.companyId,
                userPosition: widget.userPosition,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 224, 45, 255),
          title: const Text(
            'Claim Application',
            style: TextStyle(color: Colors.black),
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
                        )),
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: AssetImage('assets/images/claimpic.png'),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.fromLTRB(38, 10, 38, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        'Claim Type         ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 224, 45, 255),
                        ),
                      ),
                      Container(
                          width: 160, // Set the width as per your requirement
                          height: 60, // Set the height as per your requirement
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 238, 238, 238),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Container(
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Type',
                                border: InputBorder.none,
                              ),
                              style: TextStyle(color: Colors.black),
                              value: claimType,
                              items: types.map((String bank) {
                                return DropdownMenuItem<String>(
                                  value: bank,
                                  child: Text(bank,
                                      style: TextStyle(color: Colors.black)),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  claimType = value;
                                });
                              },
                              selectedItemBuilder: (BuildContext context) {
                                return types.map<Widget>((String value) {
                                  return Text(
                                    value,
                                    style: TextStyle(color: Colors.black),
                                  );
                                }).toList();
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please choose your bank';
                                }
                                return null;
                              },
                              onSaved: (value) => claimType = value ?? '',
                              isDense:
                                  true, // Make the dropdown menu more compact
                              itemHeight:
                                  null, // Set to null to allow the dropdown to determine the height
                              menuMaxHeight:
                                  200, // Set the maximum height for the dropdown menu
                            ),
                          )),
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
                        'Date                   ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 224, 45, 255),
                        ),
                      ),
                      Container(
                        width: 160, // Set the width as per your requirement
                        height: 40, // Set the height as per your requirement
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
                                  if (claimDate == null) {
                                    return 'Please select the date';
                                  }
                                  return null;
                                },
                                onSaved: (value) {},
                                controller: TextEditingController(
                                  text: claimDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(claimDate!)
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

                // Claim Amount
                Container(
                  margin: const EdgeInsets.fromLTRB(45, 10, 45, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        'Amount Claim(RM)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 224, 45, 255),
                        ),
                      ),
                      Container(
                        width: 160, // Set the width as per your requirement
                        height: 40, // Set the height as per your requirement
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onLongPress: _startDecrementTimer,
                              onLongPressUp: _stopTimer,
                              child: IconButton(
                                onPressed: _decrement,
                                icon: const Icon(Icons.remove),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 17),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Amount',
                                ),
                                controller: _textEditingController,
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    _amount = int.parse(value);
                                    claimAmount =
                                        _amount.toDouble(); // Convert to double
                                  } else {
                                    _amount = 0;
                                    claimAmount = 0.0;
                                  }
                                },
                              ),
                            ),
                            GestureDetector(
                              onLongPress: _startIncrementTimer,
                              onLongPressUp: _stopTimer,
                              child: IconButton(
                                onPressed: _increment,
                                icon: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.fromLTRB(55, 15, 10, 20),
                  child: const Text(
                    'Remarks',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 224, 45, 255),
                    ),
                  ),
                ),

                Container(
                  width: 300, // Set the width as per your requirement
                  height: 100, // Set the height as per your requirement
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 238, 238, 238),
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: TextField(
                      controller: _remarkController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'remark (optimal)',
                      ),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () async {
                    // Open the image picker
                    final pickedFile = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      // Handle the picked image (you may want to save it to Firebase Storage)
                      logger.i('Image picked: ${pickedFile.path}');
                      setState(() {
                        pickedImagePath = pickedFile.path;
                      });
                    }
                  },
                  // CircleAvatar for image upload indication
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[300],
                    child: pickedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(70),
                            child: Image.file(
                              File(pickedImagePath!),
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 45,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Upload Image',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // Container(
                //   margin: const EdgeInsets.all(20.0),
                ElevatedButton(
                  onPressed: () {
                    if (claimType == null ||
                        claimDate == null ||
                        claimAmount == null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Empty Space Detected'),
                          content: const Text(
                              'Please fill in all the required information'),
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
                      // reason = _reasonController.text;
                      remark = _remarkController.text.isNotEmpty
                          ? _remarkController.text
                          : '-';
                      _createLeave();
                      setState(() {});
                    }
                  },
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Set the corner radius
                      ),
                    ),
                    fixedSize: MaterialStateProperty.all<Size>(
                      const Size(120, 40), // Set the width and height
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(255, 224, 45,
                          255), // Set the background color to purple
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        ));
  }
}
