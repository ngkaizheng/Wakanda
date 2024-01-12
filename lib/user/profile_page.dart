import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/login_page.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data/repositories/profile_repository.dart';

class ProfilePage extends StatelessWidget {
  final String companyId;

  ProfilePage({Key? key, required this.companyId}) : super(key: key);

  final logger = Logger();

  String _formatDate(Timestamp timestamp) {
    // Convert Timestamp to DateTime
    DateTime dateTime = timestamp.toDate();

    // Format DateTime to display only the date
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false, //Solve Bottom overflow

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
            'Profile',
            style: TextStyle(color: Colors.black), // Set title color to black
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // Show a confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            logger.i('Sign out');
                            // Navigate to the login page and replace the current route
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomePage()),
                            );
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: FutureBuilder<Map<String, dynamic>>(
            future: ProfileRepository().getUserData(companyId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Loading indicator while fetching data
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.4), // Optional spacing
                      CircularProgressIndicator(),
                      Text('Loading...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                // Handle error
                logger.e('Error fetching user data: ${snapshot.error}');
                return const Center(
                  child: Text('An error occurred. Please try again later.'),
                );
              }

              // User data found
              final userData = snapshot.data;
              final imageUrl = userData?['image'] ?? '';
              return Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.21,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(229, 63, 248, 1),
                    ),
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 70,
                      child: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(70),
                              child: Image.network(
                                '${imageUrl}',
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                // Calculate the icon size based on the constraints
                                double iconSize =
                                    constraints.maxWidth > constraints.maxHeight
                                        ? constraints.maxHeight * 0.5
                                        : constraints.maxWidth * 0.5;

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: iconSize,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(
                                        height: 5), // Adjust spacing as needed
                                    Text(
                                      'No Image',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: iconSize * 0.25,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                  // ),

                  // Overlay with profile information
                  // Wrap the Column with Padding to add top padding
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.05,
                      horizontal: 75,
                    ),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Name',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w300),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${userData?['name']}',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          const Divider(
                            thickness: 2,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Email',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w300),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${userData?['email']}',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          const Divider(
                            thickness: 2,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Phone',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w300),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${userData?['phone']!.substring(0, 3)}-${userData?['phone']!.substring(3)}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(
                            thickness: 2,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Gender',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w300),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${userData?['gender']}',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          const Divider(
                            thickness: 2,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Date of Birth',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w300),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDate(userData?['dateofbirth']),
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          const Divider(
                            thickness: 2,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Position',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w300),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${userData?['position']}',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          const Divider(
                            thickness: 2,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ));
  }
}
