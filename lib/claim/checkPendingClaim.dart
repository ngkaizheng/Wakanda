import 'package:flutter/material.dart';
import 'package:flutter_application_1/main_page.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/data/data_model.dart';
import 'package:flutter_application_1/claim/process_PendingClaim_page.dart';

class CheckPendingClaim extends StatefulWidget {
  final String companyId;
  final String userPosition;

  CheckPendingClaim(
      {Key? key, required this.companyId, required this.userPosition})
      : super(key: key);

  @override
  _CheckPendingClaim createState() => _CheckPendingClaim();
}

class _CheckPendingClaim extends State<CheckPendingClaim> {
  final logger = Logger();
  List<dynamic> userNameList = [];
  bool isLoading = false;
  int activeLabelIndex = 1;

  @override
  void initState() {
    super.initState();

    // Fetch user data when the page is initialized
    fetchAllUsersWithClaimHistory(1);
  }

  Future<void> fetchAllUsersWithClaimHistory(int index) async {
    try {
      // Set loading to true before fetching
      setState(() {
        isLoading = true;
      });
      late List<Map<String, dynamic>> allUsersData;
      if (index == 0) {
        allUsersData = await LeaveModel().getUsersWithApprovedClaim();
      } else if (index == 1) {
        allUsersData = await LeaveModel().getUsersWithPendingClaim();
      } else if (index == 2) {
        allUsersData = await LeaveModel().getUsersWithRejectedClaim();
      }

      setState(() {
        if (allUsersData.isNotEmpty) {
          userNameList = allUsersData.map((user) {
            final String companyId = user['userData']['companyId'].toString();
            final String name = user['userData']['name'].toString();
            final String claimType = user['claimType'].toString();
            final double claimAmount = user['claimAmount'] as double;
            final DateTime claimDate = user['claimDate'] as DateTime;
            final String imageURL = user['imageURL'].toString();
            final String remark = user['remark'].toString();
            final String documentId = user['documentId'].toString();

            final formattedStartDate =
                "${claimDate.year}-${claimDate.month}-${claimDate.day}";

            return {
              'companyId': companyId,
              'name': name,
              'claimType': claimType,
              'claimAmount': claimAmount,
              'claimDate': formattedStartDate,
              'imageURL': imageURL,
              'remark': remark,
              'documentId': documentId,
            };
          }).toList();
        }
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error fetching all users with leave history: $e');
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 224, 45, 255),
        title: const Text(
          'Check Claim',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(
              context,
              MaterialPageRoute(
                  builder: (context) => MainPage(
                        companyId: widget.companyId,
                        userPosition: widget.userPosition,
                      )),
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            ToggleSwitch(
              minWidth: 150.0,
              initialLabelIndex: activeLabelIndex,
              cornerRadius: 20.0,
              activeFgColor: Colors.white,
              inactiveBgColor: Colors.white,
              inactiveFgColor: Color.fromARGB(255, 224, 45, 255),
              borderColor: [Colors.grey],
              borderWidth: 0.5,
              totalSwitches: 3,
              labels: ['Approved', 'Pending', 'Rejected'],
              customTextStyles: [
                TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900),
                TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900),
                TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900),
              ],
              changeOnTap: true,
              activeBgColors: [
                [Color.fromARGB(255, 224, 45, 255)],
                [Color.fromARGB(255, 224, 45, 255)],
                [Color.fromARGB(255, 224, 45, 255)]
              ],
              onToggle: (index) {
                setState(
                  () {
                    activeLabelIndex = index!;
                    isLoading = true;
                  },
                );
                fetchAllUsersWithClaimHistory(index!);
              },
            ),
            Expanded(
              child: isLoading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10), // Adjust the height as needed
                        Text('Loading...'),
                      ],
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: userNameList.length,
                      itemBuilder: (context, index) {
                        return Container(
                          height: 170,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: ListTile(
                            title: Text(
                              userNameList[index]['name'],
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
                                    fontSize:
                                        16.0, // or your preferred font size
                                    fontWeight: FontWeight.bold,
                                  ), // Set label color
                                ),
                                Text(
                                  '${userNameList[index]['claimType']}',
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 224, 45, 255),
                                    fontSize:
                                        16.0, // or your preferred font size
                                    fontWeight: FontWeight.bold,
                                  ), // Set data color
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.002,
                                ),
                                Container(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              '${userNameList[index]['claimAmount'].toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                    255, 224, 45, 255),
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
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
                                            '${userNameList[index]['claimDate']}',
                                            style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 224, 45, 255),
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (activeLabelIndex == 1)
                                        Container(
                                          margin: const EdgeInsets.fromLTRB(
                                              30, 0, 10, 10),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              final Map<String, dynamic> user =
                                                  userNameList[index];
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        processClaim(
                                                          companyId:
                                                              widget.companyId,
                                                          userPosition: widget
                                                              .userPosition,
                                                          userNameList: [user],
                                                        )),
                                              );
                                            },
                                            style: ButtonStyle(
                                              shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0), // Set the corner radius
                                                ),
                                              ),
                                              fixedSize: MaterialStateProperty
                                                  .all<Size>(
                                                const Size(100,
                                                    50), // Set the width and height
                                              ),
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(
                                                Color.fromARGB(255, 55, 142,
                                                    242), // Set the background color to blue
                                              ),
                                            ),
                                            child: const Text('Check'),
                                          ),
                                        ),
                                      if (activeLabelIndex != 1)
                                        Container(
                                          margin: const EdgeInsets.fromLTRB(
                                              30, 0, 10, 10),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Center(
                                                    child:
                                                        Text('Claim Details'),
                                                  ),
                                                  content:
                                                      SingleChildScrollView(
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            const Text(
                                                              'Type: ',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                                '${userNameList[index]['claimType']}'),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                              'Date: ',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                                '${userNameList[index]['claimDate']}'),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                              'Amount(RM): ',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                                '${userNameList[index]['claimAmount']}'),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                              'Remark: ',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                                '${userNameList[index]['remark']}'),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              'Status: ',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                              activeLabelIndex ==
                                                                      0
                                                                  ? 'Approved'
                                                                  : (activeLabelIndex ==
                                                                          2
                                                                      ? 'Rejected'
                                                                      : ''),
                                                            ),
                                                          ],
                                                        ),
                                                        Container(
                                                          height: 350,
                                                          width: 400,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            border: Border.all(
                                                              color: Colors
                                                                  .lightGreen,
                                                              width: 2.0,
                                                            ),
                                                          ),
                                                          alignment:
                                                              Alignment.center,
                                                          child:
                                                              '${userNameList[index]['imageURL']}'
                                                                      .isNotEmpty
                                                                  ? Image
                                                                      .network(
                                                                      '${userNameList[index]['imageURL']}',
                                                                      width:
                                                                          260, // Adjust the width as per your requirement
                                                                      height:
                                                                          260, // Adjust the height as per your requirement
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    )
                                                                  : Text(
                                                                      'No Image Available',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              20),
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
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0), // Set the corner radius
                                                ),
                                              ),
                                              fixedSize: MaterialStateProperty
                                                  .all<Size>(
                                                const Size(100,
                                                    50), // Set the width and height
                                              ),
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(
                                                Color.fromARGB(255, 55, 142,
                                                    242), // Set the background color to blue
                                              ),
                                            ),
                                            child: const Text('Details'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
