import 'package:flutter/material.dart';
import 'package:flutter_application_1/salary/edit_bonus_page.dart';
import 'package:flutter_application_1/salary/all_salary_page.dart';
import 'package:logger/logger.dart';

// import 'package:flutter_application_1/reset_leave_balance_page.dart';
class SalaryManagementPage extends StatelessWidget {
  final logger = Logger();

  @override
  Widget build(BuildContext context) {
    double iconSize = MediaQuery.of(context).size.width * 0.25;
    double circleRadius = MediaQuery.of(context).size.width * 0.2;

    return Scaffold(
      resizeToAvoidBottomInset: false, //Solve Bottom overflow

      appBar: AppBar(
        title: const Text(
          'Salary Management',
          style: TextStyle(
            color: Colors.black87, // Adjust text color for modern style
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
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
                  MaterialPageRoute(builder: (context) => SalaryPage()),
                );
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: circleRadius,
                    backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
                    child: Icon(
                      Icons.local_atm,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8), // Adjust spacing between icon and label
                  Text(
                    'All User Salary',
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
                  MaterialPageRoute(builder: (context) => AddBonusPage()),
                );
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: circleRadius,
                    backgroundColor: const Color.fromRGBO(229, 63, 248, 1),
                    child: Icon(
                      Icons.star,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Edit Bonus',
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
}
