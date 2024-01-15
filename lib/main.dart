// main.dart
import 'dart:async';
import 'package:logger/logger.dart';
import 'utils/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/attendance/attendance_data.dart'; // Import the AttendanceData class

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

var logger = Logger();

String? selectedNotificationPayload;

/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

/// Streams are created so that app can respond to notification-related events
/// since the plugin is initialised in the `main` function
final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();

Future<void> initNotification() async {
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notification_icon');
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      logger.i('Notification clicked');
      _handleNotificationInteraction(notificationResponse);
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

Future askRequiredPermission() async {
  // ignore: unused_local_variable
  Map<Permission, PermissionStatus> statuses = await [
    Permission.storage,
    Permission.manageExternalStorage,
    Permission.accessMediaLocation
  ].request();
}

void _handleNotificationInteraction(NotificationResponse notificationResponse) {
  // Check if the notification response payload is not null
  if (notificationResponse.payload != null) {
    String pdfPath = notificationResponse.payload!;
    logger.i(pdfPath);
    // Open the PDF file using your preferred method
    _openPDF(pdfPath);
  }
}

void _openPDF(String pdfPath) {
  // Implement your logic to open the PDF file
  // For example, you can use the open_file package:
  OpenFile.open(pdfPath);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotification();
  await askRequiredPermission();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AttendanceData(),
      child: MyApp(),
    ),
  );
}

