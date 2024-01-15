import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/create_user_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/data/repositories/profile_repository.dart';
import 'package:email_validator/email_validator.dart';

enum Gender { male, female }

final List<String> positions = [
  'Sales',
  'Account',
  'Customer Services',
  'Manager'
];
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

class EditProfilePage extends StatefulWidget {
  final String companyId;

  EditProfilePage({Key? key, required this.companyId}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final logger = Logger();
  bool isEditing = false;

  late Future<void> userDataFuture;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  TextEditingController newNameController = TextEditingController();
  TextEditingController icController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  TextEditingController basicSalaryController = TextEditingController();
  TextEditingController epfNoController = TextEditingController();

  String name = '';
  String email = '';
  String ic = '';
  String phone = '';
  Gender? selectedGender;
  DateTime? dateOfBirth;
  String? selectedPosition;
  String? pickedImagePath;
  String imageUrl = '';
  DateTime? joiningDate;
  bool status = true;
  String accountNumber = '';
  String? selectedBank;
  num basicSalary = 0.0;
  String epfNo = '';
  String socsoNo = '';

  String newName = "";
  String position = "";

  void updateSelectedGender(Gender? value) {
    setState(() {
      selectedGender = value;
    });
  }

  @override
  void initState() {
    super.initState();

    // Fetch user data when the page is initialized
    userDataFuture = fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      await Future.delayed(Duration(seconds: 1));

      final userData = await ProfileRepository().getUserData(widget.companyId);

      if (mounted) {
        // Set the fetched user data to the state variables
        setState(() {
          name = userData['name'] ?? '';
          email = userData['email'] ?? '';
          ic = userData['ic'] ?? '';
          phone = userData['phone'] ?? '';
          String genderFromFirestore =
              userData['gender']; // Assuming the field is stored as a String
          selectedGender =
              genderFromFirestore == 'male' ? Gender.male : Gender.female;
          selectedPosition = userData['position'] ?? '';
          pickedImagePath = userData['image'];
          dateOfBirth = userData['dateofbirth'].toDate() ?? '';
          joiningDate = userData['joiningdate'].toDate() ?? '';
          selectedBank = userData['bankName'] ?? '';
          accountNumber = userData['accountNumber'] ?? '';
          basicSalary = userData['basicSalary'] ?? '';
          epfNo = userData['epfNo'] ?? '';
          socsoNo = userData['socsoNo'] ?? '';
          status = userData['status'] ?? true;
          position = userData['position'] ?? '';

          nameController.text = name;
          icController.text = ic;
          emailController.text = email;
          phoneController.text = phone;
          accountNumberController.text = accountNumber;
          basicSalaryController.text = basicSalary.toString();
          epfNoController.text = epfNo;
        });
      } else {
        // Handle the case when user data is not found
        logger.e('User data not found for companyId: ${widget.companyId}');
      }
    } catch (e) {
      // Handle errors during data fetching
      logger.e('Error fetching user data: $e');
    }
  }

  Future<void> _selectDateofBirth(BuildContext context) async {
    final DateTime? pickedDateofBirth = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDateofBirth != null && pickedDateofBirth != dateOfBirth) {
      setState(() {
        dateOfBirth = pickedDateofBirth;
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

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (pickedImagePath != null && pickedImagePath!.startsWith('http')) {
        // If it's an HTTP URL, set imageUrl directly
        imageUrl = pickedImagePath!;
        logger.i("Using existing imageUrl: $imageUrl");
      } else if (pickedImagePath != null) {
        // If it's a local file path, upload the image and get the imageUrl
        imageUrl = await ProfileRepository()
            .uploadImage(pickedImagePath!, widget.companyId);
        logger.i("Uploaded imageUrl: $imageUrl");
      } else {
        // Handle the case where pickedImagePath is null
        logger.i("Error: pickedImagePath is null");
      }

      logger.i("This is name at updateUser $name");

      // Update the user data with the collected data
      await ProfileRepository().updateUser(
        widget.companyId,
        {
          'name': name.formatName(),
          'email': email,
          'ic': ic,
          'phone': phone,
          'gender': selectedGender?.toString().split('.').last,
          'dateofbirth': dateOfBirth,
          'joiningdate': joiningDate,
          'position': selectedPosition,
          'image': imageUrl,
          'status': status,
        },
        {
          'basicSalary': basicSalary,
          'epfNo': epfNo,
          'socsoNo': ic,
          'effectiveDate': DateTime.now(),
        },
        {
          'accountNumber': accountNumber,
          'bankName': selectedBank,
          'effectiveDate': DateTime.now(),
        },
      );

      Map<String, dynamic> result = {
        'name': name,
        'email': email,
        'phone': phone,
      };

      // Navigate back to the profile page
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          isEditing ? 'Edit Profile' : 'View Profile',
          style: TextStyle(
            color: Colors.black87, // Adjust text color for modern style
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isEditing
                  ? (status
                      ? (position == 'Manager' ? null : Icons.block)
                      : Icons.check_circle)
                  : Icons.edit,
              color: isEditing ? (status ? Colors.red : Colors.green) : null,
            ),
            onPressed: () {
              setState(() {
                if (isEditing) {
                  if (status == true) {
                    if (position != 'Manager') _showDeactivateDialog(context);
                  } else {
                    if (position != 'Manager') _showActivateDialog(context);
                  }
                } else {
                  isEditing = !isEditing;
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while waiting for data
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Loading...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            // Handle the error state
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            // Your main content when data is available
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // GestureDetector for image upload
                    GestureDetector(
                      onTap: isEditing
                          ? () async {
                              // Open the image picker
                              final pickedFile = await ImagePicker()
                                  .pickImage(source: ImageSource.gallery);

                              if (pickedFile != null) {
                                // Handle the picked image (you may want to save it to Firebase Storage)
                                logger.i('Image picked: ${pickedFile.path}');
                                setState(() {
                                  pickedImagePath = pickedFile.path;
                                  logger.i('New image path: $pickedImagePath');
                                });
                              }
                            }
                          : null, // Disable onTap when not editing

                      // CircleAvatar for image upload indication
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[300],
                        child: pickedImagePath != null && pickedImagePath != ""
                            ? pickedImagePath!.startsWith(
                                    'http') // Check if the path is a URL
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(70),
                                    child: Image.network(
                                      pickedImagePath!,
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // Handle errors for network images
                                        return Icon(
                                          Icons.error,
                                          size: 45,
                                          color: Colors.red,
                                        );
                                      },
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(70),
                                    child: Image.file(
                                      File(pickedImagePath!),
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // Handle errors for local images
                                        return Icon(
                                          Icons.error,
                                          size: 45,
                                          color: Colors.red,
                                        );
                                      },
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
                      readOnly: !isEditing,
                      decoration: InputDecoration(labelText: 'Name'),
                      controller: nameController,
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
                      enabled: false, // Set to false to make it uneditable
                      readOnly: true,
                      decoration: InputDecoration(labelText: 'Email'),
                      controller: emailController,
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
                      onSaved: (value) {
                        email = value ?? '';
                      },
                    ),

                    TextFormField(
                      readOnly: !isEditing,
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
                      onSaved: (value) {
                        ic = value ?? '';
                      },
                    ),

                    TextFormField(
                      readOnly: !isEditing,
                      decoration: InputDecoration(labelText: 'Phone'),
                      controller: phoneController,
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
                        return null;
                      },
                      onSaved: (value) => phone = value ?? '',
                    ),
                    // Row with radio buttons for gender
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: IgnorePointer(
                        ignoring: !isEditing,
                        child: Row(
                          children: [
                            const Text('Gender:'),
                            Radio<Gender>(
                              value: Gender.male,
                              groupValue: selectedGender,
                              onChanged: (value) {
                                updateSelectedGender(value);
                              },
                            ),
                            const Text('Male'),
                            Radio<Gender>(
                              value: Gender.female,
                              groupValue: selectedGender,
                              onChanged: (value) {
                                updateSelectedGender(value);
                              },
                            ),
                            const Text('Female'),
                          ],
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap:
                          isEditing ? () => _selectDateofBirth(context) : null,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration:
                              InputDecoration(labelText: 'Date of Birth'),
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
                      onTap:
                          isEditing ? () => _selectJoiningDate(context) : null,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration:
                              InputDecoration(labelText: 'Joining Date'),
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
                        onChanged: (widget.companyId != 'PF0000' && isEditing)
                            ? (String? value) {
                                setState(() {
                                  selectedPosition = value;
                                });
                              }
                            : null,
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
                    if (widget.companyId != 'PF0000')
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

                    if (widget.companyId != 'PF0000')
                      // Bank Details Section
                      TextFormField(
                        readOnly: !isEditing,
                        decoration:
                            InputDecoration(labelText: 'Account Number'),
                        controller: accountNumberController,
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

                    if (widget.companyId != 'PF0000')
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
                          onChanged: isEditing
                              ? (String? value) {
                                  setState(() {
                                    selectedBank = value;
                                  });
                                }
                              : null,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please choose your bank';
                            }
                            return null;
                          },
                          onSaved: (value) => selectedBank = value ?? '',
                        ),
                      ),

                    if (widget.companyId != 'PF0000')
                      const SizedBox(height: 20),
                    if (widget.companyId != 'PF0000')
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

                    if (widget.companyId != 'PF0000')
                      // Financial Information
                      TextFormField(
                        readOnly: !isEditing,
                        decoration:
                            InputDecoration(labelText: 'Basic Salary (RM)'),
                        controller: basicSalaryController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}$')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter basic salary';
                          }
                          return null;
                        },
                        onSaved: (value) =>
                            basicSalary = num.parse(value ?? '0'),
                      ),

                    if (widget.companyId != 'PF0000')
                      // EPF No
                      TextFormField(
                        readOnly: !isEditing,
                        decoration:
                            InputDecoration(labelText: 'EPF No (Optional)'),
                        controller: epfNoController,
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

                    if (widget.companyId != 'PF0000')
                      // Note for the user
                      Text(
                        'Note: The EPF No section can be left blank if user don\'t have one.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),

                    if (widget.companyId != 'PF0000')
                      const SizedBox(height: 20),
                    Visibility(
                      visible: isEditing,
                      child: ElevatedButton(
                        onPressed: () {
                          _formKey.currentState?.save();
                          _updateProfile();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(229, 63, 248, 1),
                        ),
                        child: const Text('Update User'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Function to show the deactivation confirmation dialog
  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Deactivate User'),
          content: Text('Are you sure you want to deactivate this user?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Call your deactivateUser function here
                deactivateUser(widget.companyId);

                Navigator.pop(context); // Close the dialog
                setState(() {
                  isEditing = !isEditing;
                });

                // Show SnackBar after successful deactivation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User deactivated successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditProfilePage(companyId: widget.companyId)));
              },
              child: Text('Deactivate'),
            ),
          ],
        );
      },
    );
  }

  // Function to deactivate user
  void deactivateUser(String companyId) async {
    ProfileRepository profileRepository = ProfileRepository();
    try {
      // Call the function to deactive user
      await profileRepository.deactivateStatus(companyId);

      logger.i('User deactivated!');
    } catch (e) {
      logger.e('Error deactive user: $e');
      // Handle the error as needed
    }
  }

  // Function to show the activation confirmation dialog
  void _showActivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Activate User'),
          content: Text('Are you sure you want to Activate this user?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Call your activateUser function here
                activateUser(widget.companyId);

                Navigator.pop(context); // Close the dialog
                setState(() {
                  isEditing = !isEditing;
                });

                // Show SnackBar after successful activation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User Activated successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditProfilePage(companyId: widget.companyId)));
              },
              child: Text('Activate'),
            ),
          ],
        );
      },
    );
  }

  // Function to activate user
  void activateUser(String companyId) async {
    ProfileRepository profileRepository = ProfileRepository();
    try {
      // Call the function to active user
      await profileRepository.activateStatus(companyId);

      logger.i('User Activated!');
    } catch (e) {
      logger.e('Error Active user: $e');
      // Handle the error as needed
    }
  }
}
