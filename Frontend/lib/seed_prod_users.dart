import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:campus_management/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final testUsers = [
    {
      'email': 'admin@acadex.com',
      'password': 'acadexPassword123!',
      'name': 'Super Admin User',
      'role': 'Super Admin',
      'accountStatus': 'active'
    },
    {
      'email': 'college@acadex.com',
      'password': 'acadexPassword123!',
      'name': 'College Admin User',
      'role': 'College Admin',
      'collegeId': 'col-123',
      'accountStatus': 'active'
    },
    {
      'email': 'hod@acadex.com',
      'password': 'acadexPassword123!',
      'name': 'HOD User',
      'role': 'HOD',
      'collegeId': 'col-123',
      'departmentId': 'dep-456',
      'accountStatus': 'active'
    },
    {
      'email': 'faculty@acadex.com',
      'password': 'acadexPassword123!',
      'name': 'Faculty User',
      'role': 'Faculty',
      'collegeId': 'col-123',
      'departmentId': 'dep-456',
      'accountStatus': 'active'
    },
    {
      'email': 'student@acadex.com',
      'password': 'acadexPassword123!',
      'name': 'Student User',
      'role': 'Student',
      'collegeId': 'col-123',
      'departmentId': 'dep-456',
      'accountStatus': 'active'
    }
  ];

  for (final userMap in testUsers) {
    try {
      print('Creating ${userMap['email']}...');
      final cred = await auth.createUserWithEmailAndPassword(
        email: userMap['email']!,
        password: userMap['password']!,
      );
      final uid = cred.user!.uid;

      final profileData = {
        'id': uid,
        'firebaseUid': uid,
        'name': userMap['name'],
        'email': userMap['email'],
        'role': userMap['role'],
        'accountStatus': userMap['accountStatus'],
      };
      
      if (userMap.containsKey('collegeId')) {
        profileData['collegeId'] = userMap['collegeId']!;
      }
      if (userMap.containsKey('departmentId')) {
        profileData['departmentId'] = userMap['departmentId']!;
      }

      await firestore.collection('users').doc(uid).set(profileData);
      print('Successfully created ${userMap['email']} with UID: $uid');
      
      // Sign out so the next iteration can create a new user.
      await auth.signOut();
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('User ${userMap['email']} already exists.');
      } else {
        print('Error creating ${userMap['email']}: ${e.code} - ${e.message}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  print('Seeding complete.');
}
