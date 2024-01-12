import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnnouncementPage extends StatefulWidget {
  final String userPosition;
  final String companyId; // Unique user ID

  AnnouncementPage(
      {Key? key, required this.userPosition, required this.companyId})
      : super(key: key);

  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  String currentCategory = 'Unread';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 224, 45, 255),
        title: const Text(
          'Notification',
          style: TextStyle(
            fontSize: 22, // Set the font size
            fontWeight: FontWeight.bold, // Set the font weight
            color: Colors.black, // Set the font color
          ),
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
        actions: [
          if (widget.userPosition == 'Manager')
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: IconButton(
                icon: const Icon(Icons.add),
                color: Colors.black,
                iconSize: 37.0,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MakeAnnouncementPage(companyId: widget.companyId),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
                vertical: 15), //margin between button and title bar
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Read and Unread button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentCategory = 'Unread';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    //Design the read the unread button
                    minimumSize: const Size(150, 43),
                    backgroundColor:
                        currentCategory == 'Unread' //background color
                            ? const Color.fromARGB(
                                255, 224, 45, 255) // Selected color
                            : Colors.white, // Unselected color
                    foregroundColor: currentCategory == 'Unread' //text color
                        ? Colors.white // Selected color
                        : const Color.fromARGB(
                            255, 224, 45, 255), // Unselected color
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0), // Set rounded radius
                        bottomLeft: Radius.circular(
                            20.0), // Adjust the radius as needed
                      ),
                      side: BorderSide(
                        color: Color.fromARGB(
                            255, 158, 158, 158), // Set the color of the border
                        width: 0.5, // Set the width of the border
                      ),
                    ),
                  ),
                  child: const Text(
                    'Unread', // Test display
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold // Set the font size
                        ),
                  ),
                ),
                const SizedBox(width: 0),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentCategory = 'Read';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(150, 43),
                    backgroundColor:
                        currentCategory == 'Read' //background color
                            ? const Color.fromARGB(
                                255, 224, 45, 255) // Selected color
                            : Colors.white, // Unselected color
                    foregroundColor: currentCategory == 'Read' //text color
                        ? Colors.white // Selected color
                        : const Color.fromARGB(
                            255, 224, 45, 255), // Unselected color
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20.0), // Set rounded radius
                        bottomRight: Radius.circular(
                            20.0), // Adjust the radius as needed
                      ),
                      side: BorderSide(
                        color: Color.fromARGB(
                            255, 158, 158, 158), // Set the color of the border
                        width: 0.5, // Set the width of the border
                      ),
                    ),
                  ),
                  child: const Text(
                    'Read',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold // Set the font size
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnnouncementList(
                userPosition: widget.userPosition,
                companyId: widget.companyId,
                category: currentCategory),
          ),
        ],
      ),
    );
  }
}

class AnnouncementList extends StatelessWidget {
  final String userPosition;
  final String companyId;
  final String category;

  AnnouncementList(
      {required this.userPosition,
      required this.companyId,
      required this.category});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('timestamp',
              descending: true) // Order by timestamp in descending order
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading announcements');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Widget> announcementWidgets = [];

        // Display announcements based on category
        for (QueryDocumentSnapshot document in snapshot.data!.docs) {
          Map<String, dynamic> data = document.data() as Map<String, dynamic>;
          String title = data['title']; // Get title
          DateTime timestamp = data['timestamp'].toDate(); //Get timestamp
          List<String> visibleTo =
              List<String>.from(data['visible_to'] ?? []); //Get the visibility
          bool isRead = data['Read_by_$companyId'] ?? false; //Get read by who
          String announcementType =
              data['announcementType'] ?? ''; // Get the announcement type

          if (((category == 'Unread' && !isRead) ||
                  (category == 'Read' && isRead)) &&
              (visibleTo.contains(companyId))) {
            String formattedDate =
                DateFormat('dd MMM yyyy').format(timestamp); // Format the date
            announcementWidgets.add(
              Container(
                margin: const EdgeInsets.only(
                    left: 10.0,
                    right: 10.0,
                    bottom: 15.0), //add margin between each box
                padding: const EdgeInsets.only(bottom: 15.0, right: 10.0),
                decoration: BoxDecoration(
                  //Create a box for each announcement
                  border: Border.all(color: Colors.grey, width: 1.0),
                  borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                ),
                child: Stack(
                  // Wrap the content in a Stack
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.only(
                          top: 8.0, left: 25, right: 25, bottom: 60),
                      title: Text(
                        //Display date as title
                        formattedDate,
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        //Display announcement title as subtitle
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10.0),
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 15.0, color: Colors.black),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('announcements')
                            .doc(document.id)
                            .update({'Read_by_$companyId': true});
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnnouncementDetailPage(
                                title: title, content: data['content']),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      // Positioned for the announcement type box
                      top: (MediaQuery.of(context).size.height * 0.1),
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        width: 140,
                        decoration: BoxDecoration(
                          color: () {
                            if (announcementType == 'Company') {
                              return const Color.fromARGB(255, 193, 85, 254);
                            } else if (announcementType == 'Attendance') {
                              return const Color.fromARGB(255, 254, 85, 85);
                            } else if (announcementType == 'Leave') {
                              return const Color.fromARGB(255, 85, 130, 254);
                            } else {
                              return const Color.fromARGB(255, 112, 212, 188);
                            }
                          }(),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20.0)),
                        ),
                        child: Text(
                          announcementType,
                          style: const TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        return ListView(
          children: announcementWidgets,
        );
      },
    );
  }
}

class AnnouncementDetailPage extends StatelessWidget {
  final String title;
  final String content;

  AnnouncementDetailPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 224, 45, 255),
        title: Text(
          title,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class MakeAnnouncementPage extends StatefulWidget {
  final String companyId;

  MakeAnnouncementPage({required this.companyId});

  @override
  _MakeAnnouncementPageState createState() => _MakeAnnouncementPageState();
}

class _MakeAnnouncementPageState extends State<MakeAnnouncementPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _postAnnouncement() async {
    String title = _titleController.text.trim();
    String content = _contentController.text.trim();
    DateTime now = DateTime.now();

    Future<int> getLatestAnnouncementNumber() async {
      try {
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance.collection('announcements').get();

        int latestNumber = 0;

        for (QueryDocumentSnapshot document in querySnapshot.docs) {
          String documentId = document.id;
          if (documentId.startsWith('General_Announcement_')) {
            // Extract the announcement number
            int number = int.tryParse(documentId.split('_').last) ?? 0;
            if (number > latestNumber) {
              latestNumber = number;
            }
          }
        }

        return latestNumber;
      } catch (e) {
        print('Error fetching latest announcement number: $e');
        return 0;
      }
    }

    // Get the latest announcement number
    int latestAnnouncementNumber = await getLatestAnnouncementNumber();

    // Create a unique document ID for the announcement
    String documentId = 'General_Announcement_${latestAnnouncementNumber + 1}';

    Future<List<String>> getAllCompanyIds() async {
      List<String> companyIds = [];

      try {
        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance.collection('users').get();

        for (QueryDocumentSnapshot document in querySnapshot.docs) {
          // Assuming each document in 'users' has a field 'companyId'
          String companyId = document['companyId'];
          if (companyId.isNotEmpty) {
            companyIds.add(companyId);
          }
        }
      } catch (e) {
        print('Error fetching company IDs: $e');
      }

      return companyIds;
    }

    // Get all company IDs
    List<String> allCompanyIds = await getAllCompanyIds();

    // Add the announcement to Firebase Firestore
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(documentId)
        .set({
      'title': title,
      'content': content,
      'timestamp': now,
      'Read_by_${widget.companyId}': false,
      'visible_to': allCompanyIds, // Set the visible array to all companyId
      'announcementType': 'Company',
    });
    // Close the current page and go back to the previous page
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 224, 45, 255),
        title: const Text(
          'New Notification',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold, // Set the font size
              color: Colors.black),
        ),
        centerTitle: true,
        // Back button in the AppBar
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 400, // Set the width as per your requirement
              height: 50, // Set the height as per your requirement
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 238, 238, 238),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Notification title',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15), // Add space here
            Container(
              width: 400, // Set the width as per your requirement
              height: 100, // Set the height as per your requirement
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 238, 238, 238),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Notification Content',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15), // Add space here
            ElevatedButton(
              onPressed: _postAnnouncement,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 40),
                backgroundColor: const Color.fromARGB(255, 224, 45, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  fontSize: 17, // Set the font size
                  fontWeight: FontWeight.bold, // Set the font weight
                  color: Colors.white, // Set the font color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
