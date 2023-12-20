import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/models/data_model.dart';
import 'package:flutter_application_1/managerPart/checkpendingClaim.dart';

class processClaim extends StatefulWidget {
  final String companyId;
  final String userPosition;
  final List<dynamic> userNameList;

  processClaim({
    Key? key,
    required this.companyId,
    required this.userPosition,
    required this.userNameList,
  }) : super(key: key);

  @override
  _processClaim createState() => _processClaim();
}

// ignore: must_be_immutable
class _processClaim extends State<processClaim> {
  final logger = Logger();

  String companyId = '';
  String name = '';
  String claimType = '';
  double claimAmount = 0;
  String claimDate = '';
  String remark = '';
  String documentId = '';
  String imageURL = '';
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Access widget properties in initState
    final Map<String, dynamic> user = widget.userNameList[0];

    companyId = user['companyId']?.toString() ?? '';
    name = user['name']?.toString() ?? '';
    claimType = user['claimType']?.toString() ?? '';
    documentId = user['documentId']?.toString() ?? '';

    // Check if 'startDate' and 'endDate' are not null before converting
    claimDate = user['claimDate']?.toString() ?? '';

    // Ensure 'leaveDay' is a double or can be converted to double
    claimAmount = (user['claimAmount'] as num?)?.toDouble() ?? 0.0;

    remark = user['remark']?.toString() ?? '';
    imageURL = user['imageURL'] ?? '';
  }

  Future<void> _updateClaimStatus(companyId, documentId, status) async {
    await LeaveModel()
        .updateClaimStatusAndBalance(companyId, documentId, status);

    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CheckPendingClaim(
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
          title: Text(
            '$name',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: const Text(
                    "Claim Type",
                    style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 224, 45, 255),
                        fontWeight: FontWeight.bold),
                  ),
                ),

                Container(
                  height: 42,
                  width: 150,
                  // margin: const EdgeInsets.symmetric(
                  //     horizontal: 10.0, vertical: 8.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: const Color.fromARGB(255, 224, 45, 255),
                  ),
                  child: Center(
                    child: Text(
                      claimType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // claim Date
                Container(
                  margin: const EdgeInsets.fromLTRB(35, 10, 35, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        'Claim Date          ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 224, 45, 255),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Center(
                          child: Text(
                            '$claimDate',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Leave Days
                Container(
                  margin: const EdgeInsets.fromLTRB(35, 10, 35, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text(
                        'Amount          ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 224, 45, 255),
                        ),
                      ),
                      Container(
                        width: 150,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 238, 238, 238),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Center(
                          // margin: const EdgeInsets.symmetric(
                          //     horizontal: 35, vertical: 10),
                          child: Text(
                            '$claimAmount',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //Remark
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.fromLTRB(55, 20, 10, 10),
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
                    width: 300,
                    height: 80,
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 238, 238, 238),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      remark,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    )),

                const SizedBox(height: 20),
                //upload Picture
                Container(
                  height: 350,
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.blue, 
                      width: 2.0, 
                    ),
                  ),
                  alignment: Alignment.center,
                  child: imageURL.isNotEmpty
                      ? Image.network(
                          imageURL,
                          width:
                              300, // Adjust the width as per your requirement
                          height:
                              300, // Adjust the height as per your requirement
                          fit: BoxFit.cover,
                        )
                      : Text(
                          'No Image Available',
                          style: TextStyle(fontSize: 20),
                        ),
                ),

                const SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 90),
                  child: Row(
                    children: [
                      //Approve
                      ElevatedButton(
                        onPressed: () {
                          logger.i('Approve');
                          _updateClaimStatus(companyId, documentId, 'Approved');
                        },
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20.0), // Set the corner radius
                            ),
                          ),
                          fixedSize: MaterialStateProperty.all<Size>(
                            const Size(100, 40), // Set the width and height
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 48, 197,
                                53), // Set the background color to blue
                          ),
                        ),
                        child: const Text('Approve'),
                      ),

                      const SizedBox(width: 30),

                      //Reject
                      ElevatedButton(
                        onPressed: () {
                          logger.i('Approve');
                          _updateClaimStatus(companyId, documentId, 'Rejected');
                        },
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20.0), // Set the corner radius
                            ),
                          ),
                          fixedSize: MaterialStateProperty.all<Size>(
                            const Size(100, 40), // Set the width and height
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 244, 82,
                                70), // Set the background color to blue
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
