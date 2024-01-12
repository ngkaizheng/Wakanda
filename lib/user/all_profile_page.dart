import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/user/edit_profile_page.dart';

class AllProfilePage extends StatefulWidget {
  @override
  _AllProfilePageState createState() => _AllProfilePageState();
}

class _AllProfilePageState extends State<AllProfilePage> {
  final logger = Logger();
  String? _search;
  bool activeUser = true;

  final TextEditingController _searchController = TextEditingController();

  // Define the TextEditingController
  TextEditingController monthYearController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();

    // Set the initial value to the current month and year
    final DateTime now = DateTime.now();
    monthYearController.text = '${now.month}-${now.year}';
  }

  Future<List<Map<String, dynamic>>> _getFilteredUsers(
      String? searchTerm, bool activeUser) async {
    final QuerySnapshot querySnapshot =
        await _firestore.collection('users').get();

    final List<Map<String, dynamic>> filteredUsers = [];

    for (var doc in querySnapshot.docs) {
      final userData = doc.data() as Map<String, dynamic>;

      // Check if the user is active or inactive based on the 'status' field
      if ((activeUser && userData['status'] == true) ||
          (!activeUser && userData['status'] == false)) {
        final userName = userData['name'].toString().toLowerCase();

        // Check if searchTerm is null or empty, or if the userName contains the searchTerm
        if (searchTerm == null ||
            searchTerm.isEmpty ||
            userName.contains(searchTerm.toLowerCase())) {
          // Add the user to the filteredUsers list
          filteredUsers.add(userData);
        }
      }
    }

    return filteredUsers;
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
            activeUser ? 'All User Profile' : 'Deactivated User',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                activeUser ? Icons.block : Icons.check_circle,
                color: activeUser
                    ? Colors.red
                    : Colors.green, // Set color to red if editing
              ),
              onPressed: () {
                setState(() {
                  activeUser = !activeUser;
                  if (activeUser) {}
                  if (!activeUser) {}
                });
              },
            ),
          ]),
      body: Column(
        children: [
          //Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Icon
                GestureDetector(
                  onTap: () {
                    // Handle search icon click
                  },
                  child: Icon(
                    Icons.search,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),

                // Search TextField
                Expanded(
                  child: TextField(
                    controller: _searchController, // Assign the controller
                    onChanged: (value) {
                      // Handle text changes
                      setState(() {
                        _search = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Type the user name...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Clear Button
                TextButton(
                  onPressed: () {
                    // Handle clear button click
                    setState(() {
                      _search = null; // Clear the search term
                      _searchController.clear();
                    });
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(229, 63, 248, 1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Employee Rectangles
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getFilteredUsers(_search, activeUser),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final userData = snapshot.data![index];
                      return buildEmployeeRectangle(context, userData);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmployeeRectangle(
      BuildContext context, Map<String, dynamic> userData) {
    return GestureDetector(
      onTap: () async {
        // Navigate to the EditProfilePage with the selected companyId
        Map<String, dynamic>? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EditProfilePage(companyId: userData['companyId']),
          ),
        );

        // Check if there is an updated basicSalary and update the UI
        if (result != null) {
          setState(() {
            // Update the 'basicSalary' for the specific user in filteredUsers
            userData['name'] = result['name'];
            userData['email'] = result['email'];
            userData['phone'] = result['phone'];
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            // Left side: Employee details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${userData['name']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color.fromRGBO(229, 63, 248, 1)),
                  ),
                  const SizedBox(
                      height: 20), // Add space between Name and Position
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: 'Email: ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors
                                .black, // Set the default color for "Email:"
                          ),
                        ),
                        TextSpan(
                          text: userData['email'].length > 20
                              ? '${userData['email'].substring(0, 20)}...'
                              : userData['email'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color.fromRGBO(229, 63, 248, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: 'Phone: ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors
                                .black, // Set the default color for "Email:"
                          ),
                        ),
                        TextSpan(
                          text: userData['phone'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color.fromRGBO(229, 63, 248, 1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add more details as needed
                ],
              ),
            ),

            // Right side: Profile image
            const SizedBox(width: 16),
            Column(
              children: [
                // Profile image
                CircleAvatar(
                  radius: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      userData['image'] ?? '',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Handle errors, e.g., display a default icon
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                            Text(
                              'No Image',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Identity card icon and company ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Identity card icon
                    const Icon(
                      Icons.credit_card,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(
                        width: 5), // Add space between icon and company ID
                    // Company ID
                    Text(
                      '${userData['companyId']}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
