import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/utils/checkholiday.dart';

//Logger Configuration
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // number of method calls to be displayed
    errorMethodCount: 8, // number of method calls if stacktrace is provided
    lineLength: 120, // width of the output
    colors: true, // enable colors
    printEmojis: true, // print an emoji for each log message
    printTime: true, // print time in the log messages
  ),
);
GlobalKey<_AttendancePageState> attendancePageKey =
    GlobalKey<_AttendancePageState>();

class AttendancePage extends StatefulWidget {
  final String companyId;

  AttendancePage({required this.companyId});

  @override
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  //Animation controller
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  //Firebase
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentReference? _recentlyCheckInDoc;
  DocumentSnapshot? _recentlyCheckOutDoc;
  DocumentSnapshot? previousAttendanceDoc;
  Map<String, dynamic>? previousAttendanceData;
  List<Map<String, dynamic>>? sortedAttendanceDocData;
  bool? expectedStatus;
  //Control Flag
  bool? initialButtonState;
  bool _isCheckedIn = false;
  bool _isProcessing = false;
  bool _isGPSEnabled = true;
  bool _isLocationAvailable = true;
  //Current variable
  String _currentDate = '';
  String _currentTime = '';
  //--Animation Handler
  bool _showCircle = false;
  //---Location
  PermissionStatus? LocationPermission;
  LatLng? _currentLocation; // Nullable type for current location

  //Modification in future
  // ignore: unused_field
  GoogleMapController? _mapController;
  // ignore: unused_field
  String _locationName = 'Unknown'; // Variable to store the location name
  String _address = 'Unknown';

  //Update
  StreamSubscription<QuerySnapshot>? _attendanceStream;
  Timer? _listenerTimer;
  Timer? _validateTimer;
  late Timer _dateTimeTimer;

  //Personal
  Map<String, dynamic>? userData;

  Future<Map<String, dynamic>?> _getUserData() async {
    final docSnapshot =
        await _firestore.collection('users').doc(widget.companyId).get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      return data;
    }

    return null; // Return null if data doesn't exist or isn't in the expected format
  }

  Future<void> _fetchUserData() async {
    // Fetch user data asynchronously
    final data = await _getUserData();
    userData = data;
  }

  //Announcement
  Future<int> getLatestAttendAnnouncementNumber(String companyId) async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('announcements').get();

      int latestNumber = 0;

      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        String documentId = document.id;
        if (documentId.startsWith('Attendance_Announcement_$companyId')) {
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

  Future<void> _postCheckInOutAnnouncement(
      String title, String content, String companyId) async {
    try {
      DateTime now = DateTime.now();
      int latestAnnouncementNumber =
          await getLatestAttendAnnouncementNumber(companyId);
      String documentId =
          'Attendance_Announcement_${companyId}_${latestAnnouncementNumber + 1}';

      // Add the announcement to Firebase Firestore
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(documentId)
          .set({
        'title': title,
        'content': content,
        'timestamp': now,
        'Read_by_${widget.companyId}': false,
        'visible_to': [companyId], // Set visible status for the current user
        'announcementType': 'Attendance',
      });
    } catch (e) {
      print("Error posting announcement: $e");
      // Handle error if needed
    }
  }

  //ListenToDatabase
  void listenToAttendanceChanges() {
    _attendanceStream = FirebaseFirestore.instance
        .collection('Attendance')
        .doc(widget.companyId)
        .collection(_currentDate)
        .orderBy('CheckInTime', descending: true)
        .snapshots(includeMetadataChanges: true)
        .listen((QuerySnapshot snapshot) {
      try {
        snapshot.docChanges.forEach((change) {
          var metadata = change.doc.metadata;
          if (metadata.hasPendingWrites) {
            print('Data came frFom the local cache');
          } else {
            print('Data came from the server');
          }

          // Handle other changes in the snapshot as needed
        });
        if (snapshot.docs.isNotEmpty) {
          DocumentSnapshot latestRecord = snapshot.docs.first;
          previousAttendanceDoc = latestRecord;
          setState(() {
            sortedAttendanceDocData = snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
          });

          // ignore: unused_local_variable
          var documentId = latestRecord.id;
          var data = latestRecord.data();
          previousAttendanceData = data as Map<String, dynamic>;

          //Modification in Future
          // ignore: unnecessary_type_check, unnecessary_null_comparison
          if (data != null && data is Map<String, dynamic>) {
            data.forEach((key, value) {});
          } else {
            logger.i('No data available in the latest record');
          }

          // ignore: unnecessary_null_comparison
          if (data != null &&
              // ignore: unnecessary_type_check
              data is Map<String, dynamic> &&
              data.containsKey('CheckOutTime')) {
            setState(() {
              _isCheckedIn = false;
            });
            logger.i(
                'User status: Checked OUT'); // Indicate that the user is checked out
          } else {
            setState(() {
              _isCheckedIn = true;
            });
            logger.i(
                'User status: Checked IN'); // Indicate that the user is checked in
          }

          logger.i(
              'Is checked in? $_isCheckedIn'); // Log the value of _isCheckedIn
        } else {
          // Collection or document doesn't exist
          setState(() {
            _isCheckedIn =
                false; // Handle default state when no data is available
          });
          logger.i(
              'No attendance record found'); // Indicate that no record exists
        }
        if (expectedStatus != null) {
          _checkLatestRecordStatus(expectedStatus: expectedStatus);
        }
      } catch (e) {
        logger.e('Error listenining to attendance changes: $e');
      }
    }, onError: (error) {
      logger
          .e('Error fetching user data: $error'); // Error level log for errors
    });
  }

  //Stop Listener
  void _stopListenerRefresh() {
    _listenerTimer?.cancel();
  }

  //getCurrentDateTime
  Future<void> _getCurrentDate() async {
    DateTime now = DateTime.now();
    _currentDate = '${now.day}-${now.month}-${now.year}';
  }

  Future<void> _getCurrentTime() async {
    // Method to fetch the current time
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('HH:mm:ss').format(now);
    setState(() {
      _currentTime = formattedTime;
    });
  }

  //DateTime Update In Real Time
  void _updateDateTime() {
    // Fetch and update date/time every second
    _dateTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      DateTime now = DateTime.now();
      setState(() {
        _currentDate = '${now.day}-${now.month}-${now.year}';
        _currentTime = DateFormat('HH:mm:ss').format(now);
      });
    });
  }

  //Real DateTime Update Stop
  void _stopDateTimeUpdates() {
    // Cancel the timer to stop updating date/time
    _dateTimeTimer.cancel();
  }

  //getCurrentLocation
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _updateLocationDetails(position.latitude, position.longitude);
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  //LocationPermission
  Future<void> _requestLocationPermission() async {
    PermissionStatus permissionStatus = await Permission.location.request();
    setState(() {
      LocationPermission = permissionStatus;
    });
    if (permissionStatus.isGranted) {
      _getCurrentLocation();
    } else if (permissionStatus.isDenied || permissionStatus.isRestricted) {
      // Handle denied or restricted permission
      _showPermissionDeniedDialog();
    } else {
      // Handle permanently denied permission
      _showPermanentlyDeniedDialog();
    }
    ;
  }

  //MapWidget Init
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    _getCurrentLocation();
    _startLocationUpdates();
  }

  //Real Time Location Update
  void _startLocationUpdates() {
    Geolocator.getPositionStream().listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        _updateLocationDetails(position.latitude, position.longitude);
        if (LocationPermission!.isGranted) {
          checkGPSStatus();
        }
      }
    });
  }

  //Permission Denied Message
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Permission Denied'),
        content:
            Text('Please grant access to the location to use this feature.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // Opens the app settings to allow users to grant permission
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  //Permission Permanently Denied Message
  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Permission Permanently Denied'),
        content: Text(
            'Please grant access to the location from settings to use this feature.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // Opens the app settings for permission
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  //Map Widget Coord Update
  Future<void> _updateLocationDetails(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      setState(() {
        _locationName = placemarks.first.name ?? 'Unknown';
        _address = placemarks.first.street ?? 'Unknown';
        // You can access other address details like locality, subLocality, etc. from the placemarks if needed
      });
    } catch (e) {
      print("Error getting location details: $e");
    }
  }

  //CheckGPSStatus
  Future<void> checkGPSStatus() async {
    bool serviceEnabled;

    //Check if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      //Location services are not enabled
      setState(() {
        _isGPSEnabled = false;
        _currentLocation = null;
        _address = 'Unknown';
        //_isLocationAvailable = true;
      });
      return;
    }
  }

//CheckInOut
  Future<void> _checkInOut() async {
    try {
      // Set initial button state
      initialButtonState = _isCheckedIn;
      _showCircle = true;

      // Timer to hide the circle after 1 second
      Timer(Duration(milliseconds: 100), () {
        setState(() {
          _showCircle = false;
        });
      });

      setState(() {
        _isProcessing = true; // Start the processing/loading indicator
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      GeoPoint geoPoint = GeoPoint(
        position.latitude,
        position.longitude,
      );

      bool isCheckIn = await _getLastAttendanceType();

      DocumentReference latestAttendanceDoc;

      if (!isCheckIn) {
        final checkInDocRef = _firestore
            .collection('Attendance')
            .doc(widget.companyId)
            .collection(_currentDate)
            .doc();

        await checkInDocRef.set({
          'CheckInLocation': geoPoint,
          'CheckInTime': _currentTime,
        });

        _recentlyCheckInDoc = checkInDocRef;

        // Update the user document if it doesn't exist or has no field
        await _updateUserDocumentInAttendanceCollection(widget.companyId);

        latestAttendanceDoc = await _getLatestAttendanceDoc();

        // Post check-in success announcement
        String announcementTitle = 'Check-In Success';
        String announcementContent =
            'You have successfully checked in at ${DateFormat('yyyy-MM-dd HH:mm:ss a').format(DateTime.now())}.';
        await _postCheckInOutAnnouncement(
            announcementTitle, announcementContent, widget.companyId);
      } else {
        latestAttendanceDoc = await _getLatestAttendanceDoc();

        _recentlyCheckOutDoc = await latestAttendanceDoc.get();

        await latestAttendanceDoc.update({
          'CheckOutLocation': geoPoint,
          'CheckOutTime': _currentTime,
        });

        latestAttendanceDoc = await _getLatestAttendanceDoc();

        // Post check-in success announcement
        String announcementTitle = 'Check-Out Success';
        String announcementContent =
            'User ${widget.companyId} has successfully checked out at ${DateFormat('HH:mm:ss a').format(DateTime.now())}.';
        await _postCheckInOutAnnouncement(
            announcementTitle, announcementContent, widget.companyId);

        //Parse date and time strings
        List<String> currentDateParts = _currentDate.split('-');
        DateTime currentDate = DateTime(
          int.parse(currentDateParts[2]), // year
          int.parse(currentDateParts[1]), // month
          int.parse(currentDateParts[0]), // day
        );

        List<String> checkInTimeParts =
            (await latestAttendanceDoc.get())['CheckInTime'].split(':');
        DateTime checkInTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          int.parse(checkInTimeParts[0]), // hour
          int.parse(checkInTimeParts[1]), // minute
          int.parse(checkInTimeParts[2]), // second
        );

        List<String> checkOutTimeParts =
            (await latestAttendanceDoc.get())['CheckOutTime'].split(':');
        DateTime checkOutTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          int.parse(checkOutTimeParts[0]), // hour
          int.parse(checkOutTimeParts[1]), // minute
          int.parse(checkOutTimeParts[2]), // second
        );

        // Retrieve the public holiday status for the current date
        bool isHoliday = await isPublicHoliday(currentDate);

        // Calculate working time
        Duration workingDuration = checkOutTime.difference(checkInTime);
        // Calculate working time in decimal hours
        double totalWorkingHours =
            workingDuration.inSeconds / 3600; // Convert duration to hours

        // Get current date components
        String year = currentDate.year.toString();
        String month = currentDate.month.toString().padLeft(2, '0');
        String day = currentDate.day.toString().padLeft(2, '0');

        // Reference to the workingtime document based on companyId, year, month, and day
        DocumentReference dayDocRef = _firestore
            .collection('workingtime')
            .doc(widget
                .companyId) // Assuming widget.companyId represents the user's companyId
            .collection(year)
            .doc(month)
            .collection(day)
            .doc('dailyWorkingTime');

        // Update the existing document or create a new one if it doesn't exist
        await dayDocRef.set({
          'totalworkingtime': FieldValue.increment(totalWorkingHours),
          'isHoliday': isHoliday,
        }, SetOptions(merge: true));
      }

      var latestDocData = (await latestAttendanceDoc.get()).data();
      var metadata = (await latestAttendanceDoc.get()).metadata;

      // Check metadata for source information
      if (metadata.isFromCache) {
        logger.d('Data retrieved from local cache');
      } else {
        logger.d('Data retrieved from server');
      }

      expectedStatus = !isCheckIn;
      bool latestRecordStatus = !(latestDocData != null &&
          latestDocData is Map<String, dynamic> &&
          latestDocData.containsKey('CheckOutTime'));

      if (latestRecordStatus != expectedStatus) {
        setState(() {
          _isProcessing = true;
        });
      } else {
        if (_isCheckedIn != initialButtonState) {
          setState(() {
            _isProcessing = false;
            _recentlyCheckInDoc = null;
            _recentlyCheckOutDoc = null;
          });
        }
      }

      // Stop the processing/loading indicator immediately if the button state changes
      if (initialButtonState != _isCheckedIn) {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      print("Error checking in/out: $e");
      _revertOrRemoveDocuments(); // Revert or remove documents on error
    }
  }

  Future<void> _updateUserDocumentInAttendanceCollection(
      String companyId) async {
    await _firestore
        .collection('Attendance')
        .doc(companyId)
        .set({'LatestCheckInTime': DateTime.now()}, SetOptions(merge: true));
  }

  @override
  void initState() {
    super.initState();
    attendancePageKey = GlobalKey<_AttendancePageState>();

    //Current
    _getCurrentDate();
    _getCurrentTime();
    //Animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        curve: Curves.easeInOut,
        parent: _slideController,
      ),
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = AlwaysStoppedAnimation<double>(1);
    // Start the animations
    _slideController.forward();
    _fadeController.forward();
    _updateDateTime(); // Fetch and start updating date/time
    _requestLocationPermission(); //LocationPermission
    listenToAttendanceChanges();
    //Personal
    _fetchUserData();
    checkGPSStatus();
  }

  @override
  void dispose() {
    // Stop listening to position updates when the widget is disposed
    // This prevents calling setState() on a disposed widget
    Geolocator.getPositionStream().listen((Position position) {}).cancel();
    _stopListenerRefresh(); // Stop the timer when the widget is disposed
    _attendanceStream?.cancel(); // Cancel the stream subscription;
    _validateTimer?.cancel();
    _stopDateTimeUpdates(); // Stop the timer when the widget is disposed
    _slideController.dispose();
    _fadeController.dispose();
    // Revert database changes if the process is still ongoing when the user exits the page
    if (_isProcessing) {
      _revertOrRemoveDocuments();
    }
    super.dispose();
  }

  void _revertOrRemoveDocuments() async {
    if (_recentlyCheckInDoc != null) {
      // Remove the recently added document
      await _recentlyCheckInDoc!.delete();
      _recentlyCheckInDoc = null; // Reset reference after removal
    }
    if (_recentlyCheckOutDoc != null) {
      // Revert the recently changed document
      await _recentlyCheckOutDoc!.reference.set(_recentlyCheckOutDoc!.data()!);
      _recentlyCheckOutDoc = null; // Reset reference after revert
    }
  }

  Future<void> _checkLatestRecordStatus({required bool? expectedStatus}) async {
    // Compare the global variable directly with the expected status
    if (_isCheckedIn == expectedStatus) {
      setState(() {
        _isProcessing = false; // Reset the processing flag
        _recentlyCheckInDoc = null;
        _recentlyCheckOutDoc = null;
        expectedStatus = null;
      });
    } else {
      print('Latest record status does not match the expected status');
      // Optionally add a delay before the next check
      // await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<DocumentReference> _getLatestAttendanceDoc() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(widget.companyId)
          .collection(_currentDate)
          .orderBy('CheckInTime', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Return the reference to the latest attendance document
        return querySnapshot.docs.first.reference;
      } else {
        // Handle if no documents are found
        // You might want to create a new document in this case
        print('No attendance documents found for $_currentDate');
        // Return a reference to a new document (it can be updated by _checkInOut)
        return FirebaseFirestore.instance
            .collection('Attendance')
            .doc(widget.companyId)
            .collection(_currentDate)
            .doc();
      }
    } catch (e) {
      print('Error getting latest attendance document: $e');
      // Return a reference to a new document as a fallback
      return FirebaseFirestore.instance
          .collection('Attendance')
          .doc(widget.companyId)
          .collection(_currentDate)
          .doc();
    }
  }

  Future<bool> _getLastAttendanceType() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(widget.companyId)
          .collection(_currentDate)
          .orderBy('CheckInTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        return !(data != null &&
            data is Map<String, dynamic> &&
            data.containsKey('CheckOutTime'));
      }
    } catch (e) {
      print("Error getting last attendance type: $e");
    }
    return false;
  }

  void _showUnavailableCheckoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Check-out Unavailable'),
          content: Text(
              'Check-out process is currently unavailable. Please retry after a moment.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // this is all you ne
        title: Text(
          'Attendance View',
          style: TextStyle(
            color: Colors.black87, // Adjust text color for modern style
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.purpleAccent, // Customize app bar color
        elevation: 0, // Remove app bar shadow
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(width: 4),
                                        Text(
                                          'CURRENT',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today, // Calendar icon
                                          color: Colors.grey,
                                          size: 18,
                                        ),
                                        Text(
                                          _currentDate,
                                          key: Key(
                                              _currentDate), // Needed for AnimatedSwitcher
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 4,
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                offset: Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SizedBox(height: 16),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.access_time, // Time icon
                                              color: Colors.grey,
                                              size: 18,
                                            ),
                                            SizedBox(width: 4),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Text(
                                                _currentTime,
                                                key: Key(
                                                    _currentDate), // Needed for AnimatedSwitcher
                                                style: TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                  shadows: [
                                                    Shadow(
                                                      blurRadius: 4,
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      offset: Offset(2, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ])
                                    ],
                                  ),
                                ))
                          ])),
                  Container(
                    height: 200.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _currentLocation != null
                        ? GoogleMap(
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            initialCameraPosition: _currentLocation != null
                                ? CameraPosition(
                                    target: _currentLocation!,
                                    zoom: 15.0,
                                  )
                                : CameraPosition(
                                    target: LatLng(0.0, 0.0),
                                    zoom: 1.0,
                                  ),
                            onMapCreated: _onMapCreated,
                            markers: _currentLocation != null
                                ? {
                                    Marker(
                                      markerId: MarkerId('currentLocation'),
                                      position: _currentLocation!,
                                    ),
                                  }
                                : {},
                          )
                        // this is for Google Map
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromRGBO(229, 63, 248, 1)),
                                ),
                                SizedBox(
                                    height: 10), // Adjust the height as needed
                                Text('Loading...'),
                              ],
                            ),
                          ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.0),
                          color: Colors.blue.withOpacity(0.2),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 24.0,
                        ),
                      ),
                      SizedBox(
                          width: 12), // Add some space between icon and label
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADDRESS',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(
                              height: 8), // Add space between label and value
                        ],
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            '$_address',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black87,
                              // You can apply more styles such as fontFamily, fontStyle, etc.
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  userData != null
                      ? _buildEmployeeRectangle(context)
                      //This is for user information & Record
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromRGBO(229, 63, 248, 1)),
                              ),
                              SizedBox(
                                  height: 10), // Adjust the height as needed
                              Text('Loading...'),
                            ],
                          ),
                        ),
                  SizedBox(height: 20),
                  // Add other widgets and components as needed
                ], //Column Children
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AnimatedOpacity(
                    opacity: _showCircle ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: Container(
                      width: 180.0, // Reduced width
                      height: 80.0, // Reduced height
                      decoration: BoxDecoration(
                        color: _isCheckedIn
                            ? Colors.red.withOpacity(0.5)
                            : Colors.green.withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              80.0), // Half of the height for semicircle
                          topRight: Radius.circular(
                              80.0), // Half of the height for semicircle
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120.0, // Reduced width
                    height: 60.0, // Reduced height
                    child: ElevatedButton(
                      onPressed: _checkInOut,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height:
                                  10), // Adjust the height to position the text below
                          Text(
                            _isCheckedIn ? 'Check Out' : 'Check In',
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                                60.0), // Half of the button's height for top corners
                            topRight: Radius.circular(
                                60.0), // Half of the button's height for top corners
                          ),
                        ),
                        padding: EdgeInsets.all(12.0), // Adjusted padding
                        elevation: 5.0, // Reduced elevation
                        primary: _isCheckedIn
                            ? Color.fromARGB(255, 150, 57, 57)
                            : Color.fromARGB(255, 51, 147, 92),
                        onPrimary: Colors.white,
                        shadowColor: Colors.black,
                        side: BorderSide(
                          width: 1.0,
                          color: _isCheckedIn
                              ? const Color.fromARGB(255, 241, 91, 80)
                              : const Color.fromARGB(255, 73, 186, 77),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if ((LocationPermission?.isGranted ?? false) &&
                  (_currentLocation == null || userData == null) ||
              (initialButtonState == _isCheckedIn))
            DarkOverlay(
              isGPSEnabled: _isGPSEnabled,
              isLocationAvailable: _isLocationAvailable,
              loading: (_currentLocation == null || userData == null),
            ), // Your processing overlay widget00
        ],
      ),
    );
  }

  Widget _buildDarkOverlay() {
    bool _Error = false;
    //Timer to handle the duration of the progress indicator
    Timer(Duration(seconds: 10), () {
      setState() {
        _Error = true;
      }
    });
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(229, 63, 248, 1)),
                ),
                SizedBox(height: 10), // Adjust the height as needed
                Text('Loading...'),
              ],
            ),
          ),
          SizedBox(height: 20), // Adjust the spacing as needed
          if (_Error)
            Text(
              'Feature is currently unavailable.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          if (!_Error)
            Text(
              'Recording in progress...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeRectangle(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                userData!['image'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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
          SizedBox(height: 10), // Spacer
          // Gray round board with user's name
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300], // Gray color
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            padding: EdgeInsets.all(10), // Padding around the text
            child: Text(
              userData!['name']!, // Assuming 'name' exists in userData
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10), // Spacer
          // Display position from userData
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .business, // Replace this with the icon representing the department
                color: Colors.blue, // Adjust icon color as needed
                size: 20.0,
              ),
              SizedBox(width: 8), // Add some space between icon and text
              Text(
                userData!['position'] ??
                    '', // Assuming 'position' exists in userData
                style: TextStyle(
                  color: Colors.grey[600], // Adjust text color as needed
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 10), // Spacer
          // Build attendance table
          buildAttendanceTable(previousAttendanceData)
        ],
      ),
    );
  }

  Widget buildAttendanceTable(Map<String, dynamic>? attendanceData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attendanceData?.isNotEmpty == true
          ? [
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Check In',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Check Out',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Scrollbar(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        SizedBox(
                          height:
                              100, // Define the height of the table within the ListView
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Table(
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              columnWidths: const {
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(1),
                              },
                              border:
                                  TableBorder.all(color: Colors.transparent),
                              children: [
                                ...buildAttendanceTableCell(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ]
          : [Text('No previous attendance data')],
    );
  }

  Container buildTableCheckInCell(
      String text, Color textColor, Color bgColor, double cellOpacity) {
    return Container(
      padding: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(cellOpacity - 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Container buildTableCheckOutCell(
      String text, Color textColor, Color bgColor, double cellOpacity) {
    return Container(
      padding: EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(cellOpacity - 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  List<TableRow> buildAttendanceTableCell() {
    return sortedAttendanceDocData!.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      final cellOpacity =
          index == 0 ? 1.0 : 0.5; // Adjust opacity values as needed

      return TableRow(
        children: [
          buildTableCheckInCell(
              '${data['CheckInTime']}',
              Colors.white.withOpacity(cellOpacity),
              Color.fromARGB(255, 87, 178, 118),
              cellOpacity),
          buildTableCheckOutCell(
              '${data['CheckOutTime']}',
              Colors.white.withOpacity(cellOpacity),
              Color.fromARGB(255, 183, 90, 97),
              cellOpacity),
        ],
      );
    }).toList();
  }

  Widget _buildLoadingInterface() {
    return IgnorePointer(
      ignoring: false,
      child: Container(
        color: Colors.transparent,
        child: Center(
            //child: CircularProgressIndicator(),
            ),
      ),
    );
  }
}

// ignore: must_be_immutable
class DarkOverlay extends StatefulWidget {
  bool? isGPSEnabled;
  bool? isLocationAvailable;
  LatLng? currentLocation;
  bool? loading;

  DarkOverlay(
      {required this.isGPSEnabled,
      required this.isLocationAvailable,
      required this.loading});

  @override
  _DarkOverlayState createState() => _DarkOverlayState();
}

class _DarkOverlayState extends State<DarkOverlay> {
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // Timer to handle the duration of the progress indicator
    Timer(Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    });
  }

  void _restartApp() {
    // Your logic to restart the app
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  void _leavePage() {
    // Your logic to leave the current page
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromRGBO(229, 63, 248, 1)),
                  ),
                  SizedBox(height: 30),
                  _error
                      ? widget.isGPSEnabled!
                          ? Column(
                              children: [
                                Text(
                                  'Feature is currently unavailable.',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _restartApp,
                                  child: Text('Restart the App'),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.red,
                                    onPrimary: Colors.white,
                                    textStyle: TextStyle(fontSize: 16),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _leavePage,
                                  child: Text('Leave the Page'),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.blue,
                                    onPrimary: Colors.white,
                                    textStyle: TextStyle(fontSize: 16),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Feature is currently unavailable because GPS is not enabled',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    Geolocator.openLocationSettings();
                                  },
                                  child: Text('Enable GPS'),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.blue,
                                    onPrimary: Colors.white,
                                    textStyle: TextStyle(fontSize: 16),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            )
                      : Text(
                          !widget.loading!
                              ? 'Recording in progress...'
                              : 'Loading...',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// This class acts as a public interface to access _AttendancePageState
class AttendancePageManager {
  late _AttendancePageState _attendancePageState;

  // Method to initialize the _AttendancePageState
  void initialize() {
    _attendancePageState = _AttendancePageState();
  }

  // Method to retrieve data from _AttendancePageState
  void getAttendanceData() {
    _attendancePageState.listenToAttendanceChanges();
  }
}
