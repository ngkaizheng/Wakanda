import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/all_profile_page.dart';
import 'package:flutter_application_1/user/create_user_page.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/data/repositories/profile_repository.dart';

// import 'package:flutter_application_1/reset_leave_balance_page.dart';
class UserManagementPage extends StatelessWidget {
  final logger = Logger();

  @override
  Widget build(BuildContext context) {
    double iconSize = MediaQuery.of(context).size.width * 0.25;
    double circleRadius = MediaQuery.of(context).size.width * 0.2;

    return Scaffold(
      resizeToAvoidBottomInset: false, //Solve Bottom overflow

      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(color: Colors.black), // Set title color to black
        ),
        centerTitle: true,
        elevation: 0, // Remove the shadow
        iconTheme: const IconThemeData(
            color: Colors.black, size: 30), // Set the icon color to black
        backgroundColor: const Color.fromRGBO(
            229, 63, 248, 1), // Set the background color to transparent
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
              onPressed: () {
                // Navigate to the first page when the top icon is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllProfilePage()),
                );
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: circleRadius,
                    backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
                    child: Icon(
                      Icons.group,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8), // Adjust spacing between icon and label
                  Text(
                    'All User Profile',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateUserPage()),
                );
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: circleRadius,
                    backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
                    child: Icon(
                      Icons.person_add,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create User',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                showConfirmationDialog(context);
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: circleRadius,
                    backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
                    child: Icon(
                      Icons.autorenew,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Reset All User Leave Balance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show the confirmation dialog
  void showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Are you sure you want to reset the leave balance?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                showPasswordDialog(context);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void showPasswordDialog(BuildContext context) {
    String enteredPassword = '';
    ProfileRepository profileRepository = ProfileRepository();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<String?>(
          future: profileRepository.getManagerPassword(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Loading state, you can show a loading indicator if needed
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10), // Adjust the height as needed
                    Text('Loading...'),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              // Error state, handle the error
              return AlertDialog(
                title: Text('Error'),
                content:
                    Text('Error fetching manager password. Please try again.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the error dialog
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            } else {
              // Manager's password is fetched, compare it with the entered password
              String? managerPassword = snapshot.data;

              return AlertDialog(
                title: Text('Enter Password'),
                content: SingleChildScrollView(
                  child: Container(
                    width: 300.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          obscureText: true,
                          onChanged: (value) {
                            enteredPassword = value;
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the password dialog
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (enteredPassword == managerPassword) {
                        // Password is correct, perform the resetLeaveBalance action
                        Navigator.of(context).pop(); // Close the error dialog
                        resetLeaveBalance();
                        showSuccessDialog(context);
                      } else {
                        // Password is incorrect, show an error message
                        Navigator.of(context).pop(); // Close the error dialog
                        showErrorMessage(
                            context, 'Incorrect password. Please try again.');
                      }
                    },
                    child: Text('Submit'),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  // Function to show a success dialog
  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Leave balance reset successfully!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the success dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to show an error message
  void showErrorMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Incorrect Password'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the error dialog
                showPasswordDialog(context); // Show the password dialog again
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to reset leave balance
  void resetLeaveBalance() async {
    ProfileRepository profileRepository = ProfileRepository();
    try {
      // Call the function to update annualLeaveBalance
      await profileRepository.updateAnnualLeaveBalance();

      // Implement your logic to reset leave balance here
      logger.i('Leave balance reset!');
    } catch (e) {
      logger.e('Error resetting leave balance: $e');
      // Handle the error as needed
    }
  }
}
