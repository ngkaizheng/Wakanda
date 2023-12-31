import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/login_page.dart';
import 'package:intl/intl.dart';

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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false, // Remove all routes below the new route
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('companyId', isEqualTo: companyId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading indicator while fetching data
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            // Handle error
            logger.e('Error fetching user data: ${snapshot.error}');
            return const Center(
              child: Text('An error occurred. Please try again later.'),
            );
          }

          final documents = snapshot.data?.docs;

          if (documents == null || documents.isEmpty) {
            // User not found
            return const Center(
              child: Text('User not found.'),
            );
          }

          // User data found
          final userData = documents[0].data() as Map<String, dynamic>;
          final imageUrl =
              userData['image']; // Replace 'image' with the actual field name

          return Stack(
            children: [
              // Purple background
              Container(
                height: MediaQuery.of(context).size.height * 0.2,
                color: const Color.fromRGBO(229, 63, 248, 1),
              ),
              // White background
              Container(
                height: MediaQuery.of(context).size.height * 0.17,
                color: const Color.fromRGBO(229, 63, 248, 1),
                child: const Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 60,
                    // Load the image from the fetched URL
                    backgroundImage: AssetImage('assets/images/logo.png'),
                    // NetworkImage(imageUrl),;
                  ),
                ),
              ),
              // Overlay with profile information
              // Wrap the Column with Padding to add top padding
              Container(
                // height: MediaQuery.of(context).size.height * 1,
                // padding: EdgeInsets.all(top: 10),
                // padding: EdgeInsets.all(75),
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height *
                      0.08, // Adjust the vertical padding as needed
                  horizontal: 75, // Adjust the horizontal padding as needed
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
                        '${userData['name']}',
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
                        '${userData['email']}',
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
                        '${userData['phone']}',
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
                        'Gender',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${userData['gender']}',
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
                        _formatDate(userData['dateofbirth']),
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
                        '${userData['position']}',
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
    );
  }
}
