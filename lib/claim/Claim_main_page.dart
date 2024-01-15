import 'package:flutter/material.dart';
import 'package:flutter_application_1/main_page.dart';
import 'package:flutter_application_1/data/data_model.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/claim/Apply_Claim_page.dart';

class ClaimPage extends StatefulWidget {
  final String userPosition;
  final String companyId; // Unique user ID

  ClaimPage({Key? key, required this.userPosition, required this.companyId})
      : super(key: key);

  @override
  _ClaimPageState createState() => _ClaimPageState();
}

class _ClaimPageState extends State<ClaimPage> {
  final logger = Logger();
  String currentCategory = 'Pending';
  late String companyId;
  List<dynamic> pendingClaimList = [];
  List<dynamic> approvedClaimList = [];
  List<dynamic> rejectedClaimList = [];
  @override
  void initState() {
    super.initState();
    companyId = widget.companyId;

    // Fetch user data when the page is initialized
    fetchSpecificUsersWithClaimHistory();
  }

  Future<void> fetchSpecificUsersWithClaimHistory() async {
    try {
      final List<Map<String, dynamic>> specificUsersData =
          await LeaveModel().getClaimDataForUser(companyId);

      setState(() {
        if (specificUsersData.isNotEmpty) {
          //Pending list Data
          pendingClaimList = specificUsersData
              .where((user) => user['status'] == 'pending')
              .map((user) {
            return {
              'name': user['userData']['name'].toString(),
              'claimType': user['claimType'].toString(),
              'claimAmount': user['claimAmount'] as double,
              'claimDate':
                  "${user['claimDate'].year}-${user['claimDate'].month}-${user['claimDate'].day}",
              'imageURL': user['imageURL'].toString(),
              "remark": user['remark'].toString(),
              "status": user['status'].toString(),
            };
          }).toList();
          // Sort pendingClaimList by 'claimDate'
          pendingClaimList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['claimDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['claimDate']))));

          //Approved list data
          approvedClaimList = specificUsersData
              .where((user) => user['status'] == 'Approved')
              .map((user) {
            return {
              'name': user['userData']['name'].toString(),
              'claimType': user['claimType'].toString(),
              'claimAmount': user['claimAmount'] as double,
              'claimDate':
                  "${user['claimDate'].year}-${user['claimDate'].month}-${user['claimDate'].day}",
              'imageURL': user['imageURL'].toString(),
              "remark": user['remark'].toString(),
              "status": user['status'].toString(),
            };
          }).toList();
          // Sort approvedClaimList by 'claimDate'
          approvedClaimList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['claimDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['claimDate']))));

          //Rejected list data
          rejectedClaimList = specificUsersData
              .where((user) => user['status'] == 'Rejected')
              .map((user) {
            return {
              'name': user['userData']['name'].toString(),
              'claimType': user['claimType'].toString(),
              'claimAmount': user['claimAmount'] as double,
              'claimDate':
                  "${user['claimDate'].year}-${user['claimDate'].month}-${user['claimDate'].day}",
              'imageURL': user['imageURL'].toString(),
              "remark": user['remark'].toString(),
              "status": user['status'].toString(),
            };
          }).toList();
          // Sort rejectedClaimList by 'claimDate'
          rejectedClaimList.sort((a, b) =>
              DateTime.parse(_formatDateString(b['claimDate'])).compareTo(
                  DateTime.parse(_formatDateString(a['claimDate']))));
        }
      });
    } catch (e) {
      logger.e('Error fetching user with claim history: $e');
    }
  }

  String _formatDateString(String dateString) {
    // Ensure that the date string has leading zeros in month and day
    final parts = dateString.split('-');
    if (parts.length == 3) {
      return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
    }
    return dateString;
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> currentClaimList = [];
    if (currentCategory == 'Pending') {
      currentClaimList = pendingClaimList;
    } else if (currentCategory == 'Approved') {
      currentClaimList = approvedClaimList;
    } else if (currentCategory == 'Rejected') {
      currentClaimList = rejectedClaimList;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 224, 45, 255),
        title: const Text(
          'Claim',
          style: TextStyle(
            color: Colors.black87, // Adjust text color for modern style
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
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
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplyClaim(
                    companyId: widget.companyId,
                    userPosition: widget.userPosition,
                  ),
                ),
              ).then((result) {
                // This code will be executed when the ApplyLeave route is popped
                if (result != null && result is bool && result) {
                  // Assuming you have a boolean result to indicate if leave was applied
                  setState(() {
                    fetchSpecificUsersWithClaimHistory();
                  });
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: currentCategory == 'Approved'
                          ? LinearGradient(
                              colors: [
                                Color.fromARGB(255, 224, 45, 255),
                                const Color.fromARGB(255, 224, 165, 235),
                                Color.fromARGB(255, 224, 45, 255),
                              ],
                            )
                          : null, // Set to null if not 'Approved'
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        bottomLeft: Radius.circular(20.0),
                      ),
                      border: Border.all(
                        color: Color.fromARGB(255, 224, 45, 255),
                        width: 1.0,
                      ),
                    ),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 43),
                          backgroundColor: currentCategory == 'Approved'
                              ? Colors.transparent
                              : Colors.transparent,
                          foregroundColor: currentCategory == 'Approved'
                              ? Colors.white
                              : const Color.fromARGB(255, 224, 45, 255),
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              bottomLeft: Radius.circular(20.0),
                            ),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            currentCategory = 'Approved';
                          });
                        },
                        child: const Text(
                          'Approved',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ))),
                DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: currentCategory == 'Pending'
                          ? LinearGradient(
                              colors: [
                                Color.fromARGB(255, 224, 45, 255),
                                const Color.fromARGB(255, 224, 165, 235),
                                Color.fromARGB(255, 224, 45, 255),
                              ],
                            )
                          : null, // Set to null if not 'Pending'
                      border: Border(
                        top: BorderSide(
                            width: 1.0,
                            color: Color.fromARGB(255, 224, 45, 255)),
                        bottom: BorderSide(
                            width: 1.0,
                            color: Color.fromARGB(255, 224, 45, 255)),
                        left: BorderSide.none,
                        right: BorderSide.none,
                      ),
                    ),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 43),
                          backgroundColor: currentCategory == 'Pending'
                              ? Colors.transparent
                              : Colors.transparent,
                          foregroundColor: currentCategory == 'Pending'
                              ? Colors.white
                              : const Color.fromARGB(255, 224, 45, 255),
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            currentCategory = 'Pending';
                          });
                        },
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ))),
                DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: currentCategory == 'Rejected'
                          ? LinearGradient(
                              colors: [
                                Color.fromARGB(255, 224, 45, 255),
                                const Color.fromARGB(255, 224, 165, 235),
                                Color.fromARGB(255, 224, 45, 255),
                              ],
                            )
                          : null, // Set to null if not 'Rejected'
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                      border: Border.all(
                        color: Color.fromARGB(255, 224, 45, 255),
                        width: 1.0,
                      ),
                    ),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 43),
                          backgroundColor: currentCategory == 'Rejected'
                              ? Colors.transparent
                              : Colors.transparent,
                          foregroundColor: currentCategory == 'Rejected'
                              ? Colors.white
                              : const Color.fromARGB(255, 224, 45, 255),
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20.0),
                              bottomRight: Radius.circular(20.0),
                            ),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            currentCategory = 'Rejected';
                          });
                        },
                        child: const Text(
                          'Rejected',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currentClaimList.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(
                      left: 5, right: 5, top: 5, bottom: 5),
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      height: 170,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 8.0),
                      padding: const EdgeInsets.all(4.0),
                      child: ListTile(
                        title: Text(
                          currentClaimList[index]['name'],
                          style: const TextStyle(
                            color: Color.fromARGB(255, 224, 45, 255),
                            fontSize: 21.0, // or your preferred font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            const Text(
                              'Claim Type:',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0, // or your preferred font size
                                fontWeight: FontWeight.bold,
                              ), // Set label color
                            ),
                            Text(
                              '${currentClaimList[index]['claimType']}',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 224, 45, 255),
                                fontSize: 16.0, // or your preferred font size
                                fontWeight: FontWeight.bold,
                              ), // Set data color
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.002,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Amount:',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${currentClaimList[index]['claimAmount'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 224, 45, 255),
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.04,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date:',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${currentClaimList[index]['claimDate']}',
                                        style: const TextStyle(
                                          color:
                                              Color.fromARGB(255, 224, 45, 255),
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Center(
                                            child: Text('Claim Details'),
                                          ),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Type: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentClaimList[index]['claimType']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Date: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentClaimList[index]['claimDate']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Amount(RM): ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentClaimList[index]['claimAmount']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Remark: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentClaimList[index]['remark']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Status: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                        '${currentClaimList[index]['status']}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  height: 350,
                                                  width: 400,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color: Colors.lightGreen,
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child:
                                                      '${currentClaimList[index]['imageURL']}'
                                                              .isNotEmpty
                                                          ? Image.network(
                                                              '${currentClaimList[index]['imageURL']}',
                                                              width:
                                                                  260, // Adjust the width as per your requirement
                                                              height:
                                                                  260, // Adjust the height as per your requirement
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Text(
                                                              'No Image Available',
                                                              style: TextStyle(
                                                                  fontSize: 20),
                                                            ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                                    },
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              20.0), // Set the corner radius
                                        ),
                                      ),
                                      fixedSize:
                                          MaterialStateProperty.all<Size>(
                                        const Size(100,
                                            50), // Set the width and height
                                      ),
                                      backgroundColor: MaterialStateProperty
                                          .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(
                                              MaterialState.pressed)) {
                                            // Color when pressed
                                            return Color.fromRGBO(229, 63, 248,
                                                1); // Change this to the desired pressed color
                                          }
                                          // Color when not pressed
                                          return Color.fromRGBO(240, 106, 255,
                                              1); // Change this to the desired normal color
                                        },
                                      ),
                                    ),
                                    child: const Text(
                                      'Details',
                                      style: TextStyle(
                                        color: Colors
                                            .white, // Set the text color to purple
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
