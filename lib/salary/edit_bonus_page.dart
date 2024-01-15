import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/repositories/profile_repository.dart';
import 'package:flutter_application_1/data/repositories/bonus_repository.dart';
import 'package:logger/logger.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:intl/intl.dart';

class AddBonusPage extends StatefulWidget {
  @override
  _AddBonusPageState createState() => _AddBonusPageState();
}

class _AddBonusPageState extends State<AddBonusPage> {
  TextEditingController _bonusController = TextEditingController();
  TextEditingController _companyIdController = TextEditingController();
  TextEditingController _dateController = TextEditingController();

  Map<String, dynamic> _userData = {};
  late num _bonusAmount = 0;
  DateTime? picked;
  final logger = Logger();

  String _errorMessage = '';
  DateTime selectedDate =
      DateTime(1000, 1, 1); // Initialize with a default value

  Future<void> _fetchUserData(String companyId) async {
    try {
      setState(() {
        selectedDate = DateTime(1000, 1, 1);
        _dateController.text = 'Select Date';
        picked = null;
        _bonusAmount = 0;
      });

      final userData = await ProfileRepository().getUserData(companyId);
      setState(() {
        _userData = userData;
        _errorMessage = ''; // Clear any previous error message
      });
    } catch (e) {
      logger.i('Error fetching user data: $e');
    }
    if (_userData.isEmpty) {
      setState(() {
        _errorMessage = 'User not found for the entered Company ID.';
      });
    }
  }

  Future<void> _fetchBonus(String companyId, DateTime selectedDate) async {
    try {
      final bonusAmount = await getBonus(companyId, selectedDate);
      setState(() {
        _bonusAmount = bonusAmount;
        _errorMessage = ''; // Clear any previous error message
      });
    } catch (e) {
      logger.i('Error fetching bonus data: $e');
      setState(() {
        _errorMessage = 'Error fetching bonus data.';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    picked = await showMonthYearPicker(
      context: context,
      initialDate: picked ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime(1000, 1, 1)) {
      setState(() {
        _dateController.text = DateFormat('MMMM yyyy').format(picked!);
        selectedDate = DateTime(picked!.year, picked!.month, 1);
      });
    }
    await _fetchBonus(_companyIdController.text, selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, //Solve Bottom overflow

      appBar: AppBar(
        title: const Text(
          'Edit Bonus',
          style: TextStyle(
            color: Colors.black87, // Adjust text color for modern style
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              TextField(
                controller: _companyIdController,
                decoration: InputDecoration(
                  labelText: 'Enter Company ID',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 20),
              if (_userData.isNotEmpty)
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employee Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('Name: ${_userData['name']}'),
                        Text('Company ID: ${_userData['companyId']}'),
                        Text('Bank Name: ${_userData['bankName']}'),
                        Text('Account Number: ${_userData['accountNumber']}'),
                        // Add more details as needed
                      ],
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: () async {
                  // Fetch user data based on entered companyId
                  await _fetchUserData(_companyIdController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
                ),
                child: Text('Search Employee'),
              ),
              SizedBox(height: 20),
              if (_userData.isNotEmpty)
                TextField(
                  controller: _dateController,
                  onTap: () => _selectDate(context),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Select Date',
                    border: OutlineInputBorder(),
                  ),
                ),
              SizedBox(height: 20),
              if (_bonusAmount != 0)
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonus Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('Bonus: $_bonusAmount'),
                        // Add more details as needed
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                // Show a confirmation dialog
                                bool shouldDelete = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Delete Bonus?'),
                                      content: Text(
                                          'Are you sure you want to delete this bonus?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            // Dismiss the dialog and return false
                                            Navigator.of(context).pop(false);
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Dismiss the dialog and return true
                                            Navigator.of(context).pop(true);
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldDelete == true) {
                                  // Call deleteBonus and show SnackBar
                                  deleteBonus(
                                      _userData['companyId'], selectedDate);
                                  setState(() {
                                    _fetchBonus(_companyIdController.text,
                                        selectedDate);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Bonus successfully deleted.'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (_bonusAmount == 0 && selectedDate != DateTime(1000, 1, 1))
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No bonus for this month.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 20),
              if (selectedDate != DateTime(1000, 1, 1))
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: TextField(
                    controller: _bonusController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter Bonus Amount(RM)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              SizedBox(height: 20),
              if (selectedDate != DateTime(1000, 1, 1))
                ElevatedButton(
                  onPressed: () async {
                    // Check if bonus amount is not empty
                    if (_bonusController.text.isNotEmpty) {
                      // Parse the bonus amount as a double
                      double bonusAmount = double.parse(_bonusController.text);

                      // Submit the bonus amount
                      await storeBonus(
                        _userData['companyId'],
                        selectedDate,
                        bonusAmount,
                      );

                      // Fetch updated bonus and show SnackBar
                      setState(() {
                        _fetchBonus(_companyIdController.text, selectedDate);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bonus successfully added.'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
                  ),
                  child: Text('Submit Bonus'),
                ),
              SizedBox(height: 250),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyIdController.dispose();
    _bonusController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
