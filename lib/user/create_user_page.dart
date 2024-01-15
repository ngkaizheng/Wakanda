import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data/repositories/profile_repository.dart';
import 'package:email_validator/email_validator.dart';

enum Gender { male, female }

final List<String> positions = ['Sales', 'Account', 'Customer Services'];
final List<String> banks = [
  'Affin Bank',
  'Agrobank',
  'Alliance Bank',
  'AmBank',
  'Bank Islam Malaysia',
  'Bank Muamalat Malaysia',
  'Bank Rakyat',
  'Bank Simpanan Nasional (BSN)',
  'CIMB Bank',
  'Citibank',
  'Deutsche Bank',
  'Hong Leong Bank',
  'HSBC Bank',
  'Industrial and Commercial Bank of China (ICBC)',
  'J.P. Morgan Chase Bank',
  'Kuwait Finance House (KFH)',
  'Maybank',
  'MBSB Bank',
  'OCBC Bank',
  'Public Bank',
  'RHB Bank',
  'Standard Chartered Bank',
  'Sumitomo Mitsui Banking Corporation (SMBC)',
  'UOB Bank',
  'United Overseas Bank (Malaysia)',
  'Zurich Insurance Malaysia',
];

class CreateUserPage extends StatefulWidget {
  @override
  _CreateUserPageState createState() => _CreateUserPageState();
}

extension StringExtension on String? {
  String? capitalizeFirstLetter() {
    if (this == null || this!.isEmpty) {
      return this;
    }
    return this![0].toUpperCase() + this!.substring(1);
  }

  String formatName() {
    return this!
        .toLowerCase()
        .split(' ')
        .map((word) => word.capitalizeFirstLetter())
        .join(' ');
  }
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final logger = Logger();
  late String companyId; // User ID with the desired format
  late int counter = 0;
  ProfileRepository profileRepository = ProfileRepository();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController icController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController basicSalaryController = TextEditingController();
  final TextEditingController epfNoController = TextEditingController();

  String name = '';
  String ic = '';
  String email = '';
  String phone = '';
  Gender? selectedGender;
  DateTime? dateOfBirth;
  String? selectedPosition;
  String? pickedImagePath;
  String imageUrl = '';
  DateTime? joiningDate;
  String password = '';

  // Financial Information
  String accountNumber = '';
  String? selectedBank;
  num basicSalary = 0.0;
  String epfNo = '';
  String socsoNo = '';

  User? managerUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Other initialization code...
    nameController.clear(); // Clear the controller on initialization
  }

  Future<void> _selectDateofBirth(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != dateOfBirth) {
      setState(() {
        dateOfBirth = pickedDate;
      });
    }
  }

  Future<void> _selectJoiningDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: joiningDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        joiningDate = pickedDate;
      });
    }
  }

  void generateCompanyId() {
    // Increment the counter to generate the next companyId
    counter++;

    // Use the fetched counter as the sequential part of the ID
    companyId = 'PF${counter.toString().padLeft(4, '0')}';

    logger.i('companyId: $companyId');
  }

  Future<void> fetchLatestCounter() async {
    try {
      // Get data from users collection
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Check if there is any document in the collection
      if (querySnapshot.docs.isNotEmpty) {
        // Initialize the counter to a minimum value

        // Iterate through all documents to find the maximum companyId
        for (final document in querySnapshot.docs) {
          if (document.data().containsKey('companyId')) {
            final companyId = document['companyId'];

            // Extract the last 4 digits and convert to a number
            final lastFourDigits = int.parse(companyId.substring(2));

            // Update the counter if the current companyId is greater
            counter = lastFourDigits > counter ? lastFourDigits : counter;
          }
        }

        // You can now use the counter variable as needed
        logger.i('Latest counter: $counter');
      } else {
        // Handle the case when the collection is empty
        logger.i('No documents found in the users collection.');
      }
    } catch (error) {
      // Handle any errors that may occur during the process
      print('Error fetching data: $error');
    }
  }

  Future<void> signUp() async {
    try {
      // Create the new user
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Send email verification
      User? user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      // Sign back in as the manager
      if (managerUser != null) {
        // Show a loading indicator
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text('Completing create user...'),
          ),
          barrierDismissible: false, // Prevent user from dismissing the dialog
        );

        String _password = await ProfileRepository()
            .getUserPasswordByEmail(managerUser!.email!);
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(
          EmailAuthProvider.credential(
              email: managerUser!.email!,
              password: _password // Use the UID as a "dummy" password
              ),
        );

        // Sign-in successful
        User? user = userCredential.user;
        logger.i('Sign-in successful for user: ${user?.email}');
      }
      // Close the loading indicator dialog
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      logger.i(e);
      // Close the loading indicator dialog
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _createUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Check if an image is uploaded
      if (pickedImagePath == null) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Empty Image'),
              content: Text('Please upload an image.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      if (await ProfileRepository().checkDuplicateEmail(email)) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Duplicate Email'),
              content:
                  Text('Email already exists. Please enter a different email.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      await fetchLatestCounter(); // Fetch the latest counter
      generateCompanyId(); // Generate the userId with the desired format

      // Generate the password based on the user's name and phone number
      String firstName = name.split(' ').first.toUpperCase();
      String birthMonth = DateFormat('MM').format(dateOfBirth!);
      String birthDay = DateFormat('dd').format(dateOfBirth!);
      password = '$firstName$birthMonth$birthDay';

      // Upload the image and get the imageUrl
      imageUrl =
          await ProfileRepository().uploadImage(pickedImagePath!, companyId);

      await ProfileRepository().createUser(
        companyId,
        {
          'name': name.formatName(),
          'email': email,
          'ic': ic,
          'phone': phone,
          'gender': selectedGender
              ?.toString()
              .split('.')
              .last // Convert enum to string
              .capitalizeFirstLetter(),
          'dateofbirth': dateOfBirth,
          'joiningdate': joiningDate,
          'position': selectedPosition,
          'image': imageUrl,
          'companyId': companyId,
          'password': password, // Include the generated password
          'status': true,
          'annualLeaveBalance': 10,
        },
        {
          'basicSalary': basicSalary,
          'epfNo': epfNo,
          'socsoNo': ic,
          'effectiveDate': joiningDate,
        },
        {
          'accountNumber': accountNumber,
          'bankName': selectedBank,
          'effectiveDate': joiningDate,
        },
      );

      signUp();
      // Show a SnackBar to indicate successful user creation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User created successfully!'),
          duration: Duration(seconds: 3), // Optional: Set the duration
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(
            229, 63, 248, 1), // Set the background color to transparent
        elevation: 0, // Remove the shadow
        iconTheme: const IconThemeData(
            color: Colors.black, size: 30), // Set the icon color to black
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Create User',
          style: TextStyle(
            color: Colors.black87, // Adjust text color for modern style
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // GestureDetector for image upload
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              // Personal Information Section
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Handle the change in value
                  name = value;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }

                  final bool isValid = EmailValidator.validate(value);

                  if (!isValid) {
                    return 'Please enter a valid email address';
                  }

                  return null;
                },
                onChanged: (value) {
                  // Handle the change in value
                  email = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'IC Number'),
                controller: icController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter user IC Number';
                  }

                  return null;
                },
                onChanged: (value) {
                  // Remove dashes before saving
                  ic = value.replaceAll('-', '');
                },
              ),

              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(
                      11), // Adjust the limit as needed
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // You can add additional phone validation logic here if needed
                  return null;
                },
                onSaved: (value) => phone = value ?? '',
              ),
              // Row with radio buttons for gender
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Text('Gender:'),
                    Radio<Gender>(
                      value: Gender.male,
                      groupValue: selectedGender,
                      onChanged: (Gender? value) {
                        setState(() {
                          selectedGender = value;
                        });
                      },
                    ),
                    const Text('Male'),
                    Radio<Gender>(
                      value: Gender.female,
                      groupValue: selectedGender,
                      onChanged: (Gender? value) {
                        setState(() {
                          selectedGender = value;
                        });
                      },
                    ),
                    const Text('Female'),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () => _selectDateofBirth(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    readOnly: true, // Set to true to make it read-only
                    decoration: InputDecoration(labelText: 'Date of Birth'),
                    validator: (value) {
                      if (dateOfBirth == null) {
                        return 'Please select your date of birth';
                      }
                      return null;
                    },
                    onSaved: (value) {},
                    controller: TextEditingController(
                      text: dateOfBirth != null
                          ? DateFormat('yyyy-MM-dd').format(dateOfBirth!)
                          : '',
                    ),
                  ),
                ),
              ),

              GestureDetector(
                onTap: () => _selectJoiningDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    readOnly: true, // Set to true to make it read-only
                    decoration: InputDecoration(labelText: 'Joining Date'),
                    validator: (value) {
                      if (joiningDate == null) {
                        return 'Please select the Joining Date';
                      }
                      return null;
                    },
                    onSaved: (value) {},
                    controller: TextEditingController(
                      text: joiningDate != null
                          ? DateFormat('yyyy-MM-dd').format(joiningDate!)
                          : '',
                    ),
                  ),
                ),
              ),
              // Dropdown list for position
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Position'),
                  value: selectedPosition,
                  items: positions.map((String position) {
                    return DropdownMenuItem<String>(
                      value: position,
                      child: Text(position),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedPosition = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please choose your position';
                    }
                    return null;
                  },
                  onSaved: (value) => selectedPosition = value ?? '',
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Bank Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              // Bank Details Section
              TextFormField(
                controller: accountNumberController,
                decoration: InputDecoration(labelText: 'Account Number'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  return null;
                },
                onSaved: (value) => accountNumber = value ?? '',
              ),

              // Dropdown list for bank selection
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Bank Name'),
                  value: selectedBank,
                  items: banks.map((String bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Text(bank),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedBank = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please choose your bank';
                    }
                    return null;
                  },
                  onSaved: (value) => selectedBank = value ?? '',
                  isDense: true, // Make the dropdown menu more compact
                  itemHeight:
                      null, // Set to null to allow the dropdown to determine the height
                  menuMaxHeight:
                      200, // Set the maximum height for the dropdown menu
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Financial Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              // Financial Information
              TextFormField(
                controller: basicSalaryController,
                decoration: InputDecoration(labelText: 'Basic Salary (RM)'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter basic salary';
                  }
                  return null;
                },
                onSaved: (value) => basicSalary = num.parse(value ?? '0'),
              ),

              // EPF No
              TextFormField(
                controller: epfNoController,
                decoration: InputDecoration(labelText: 'EPF No (Optional)'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                onSaved: (value) => epfNo = value ?? '',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length != 8) {
                      return 'EPF number must be 8 digits long.';
                    }
                  }
                  return null; // Return null if the field is optional and empty
                },
              ),

              // Note for the user
              Text(
                'Note: The EPF No section can be left blank if user don\'t have one.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    _createUser(); // Call your method to create the user
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
                ),
                child: const Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
