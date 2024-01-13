import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/attendance/making_attendance.dart';

class MockFirestore extends Mock implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    // Return a mock CollectionReference, adjust the path as needed
    return MockCollectionReference();
  }
}

class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('AttendancePage Widget Test', () {
    late FirebaseFirestore firestore;
    late AttendancePage attendancePage;

    setUp(() {
      firestore = MockFirestore();
      attendancePage = AttendancePage(companyId: 'yourCompanyId');
    });

testWidgets('renders widget and fetches user data', (WidgetTester tester) async {
  final mockDocumentSnapshot = MockDocumentSnapshot();

  // Set up mock behavior for FirebaseFirestore
  when(firestore.collection('users')).thenReturn(MockCollectionReference());
  
  // Set up mock behavior for CollectionReference
  when(firestore.collection('users').doc('yourCompanyId').get())
      .thenAnswer((_) async {
        print('Mocked method called');
        return mockDocumentSnapshot;
      });

  // Set up mock behavior for DocumentSnapshot
  when(mockDocumentSnapshot.exists).thenReturn(true);
  when(mockDocumentSnapshot.data()).thenReturn({'key': 'value'});

  await tester.pumpWidget(
    MaterialApp(
      home: attendancePage,
    ),
  );

  // Pump the widget to trigger the asynchronous call
  await tester.pump();

  // Verify that the widget has rendered
  expect(find.byType(AttendancePage), findsOneWidget);

  // Verify that the user data is fetched and displayed (adjust the finder accordingly)
  expect(find.text('Key: value'), findsOneWidget);

  // Additional logging for debugging
  print('Widget tree after pump:');
  tester.pumpAndSettle(); // Wait for all asynchronous tasks to complete
  //print(tester.binding.treeDump());
});
;


    // Add more widget tests as needed...

  });
}
