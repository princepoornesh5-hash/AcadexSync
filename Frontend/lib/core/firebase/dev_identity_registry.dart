import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';


/// Temporary development identity registry.
/// Bridge between Firebase Auth UIDs and Acadex User Identities
/// until Prompt 23 implements the complete Firestore users/{uid} collection.
class DevIdentityRegistry {
  static final Map<String, Map<String, dynamic>> _profilesByUid = {};

  static final Map<String, Map<String, dynamic>> _mockProfiles = {
    'mock-super-admin-uid': {
      'id': '1',
      'firebaseUid': 'mock-super-admin-uid',
      'name': 'Super Admin',
      'email': 'superadmin.test@acadex.com',
      'role': 'superAdmin',
      'accountStatus': 'active'
    },
    'mock-college-admin-uid': {
      'id': '2',
      'firebaseUid': 'mock-college-admin-uid',
      'name': 'College Admin',
      'email': 'admin.test@acadex.com',
      'role': 'collegeAdmin',
      'accountStatus': 'active'
    },
    'mock-hod-uid': {
      'id': '3',
      'firebaseUid': 'mock-hod-uid',
      'name': 'HOD User',
      'email': 'hod.test@acadex.com',
      'role': 'hod',
      'accountStatus': 'active'
    },
    'mock-faculty-uid': {
      'id': '4',
      'firebaseUid': 'mock-faculty-uid',
      'name': 'Faculty User',
      'email': 'faculty.test@acadex.com',
      'role': 'faculty',
      'accountStatus': 'active'
    },
    'mock-student-uid': {
      'id': '5',
      'firebaseUid': 'mock-student-uid',
      'name': 'Student User',
      'email': 'student.test@acadex.com',
      'role': 'student',
      'accountStatus': 'active'
    },
    'mock-suspended-uid': {
      'id': '6',
      'firebaseUid': 'mock-suspended-uid',
      'name': 'Suspended User',
      'email': 'suspended@acadex.com',
      'role': 'student',
      'accountStatus': 'suspended'
    },
  };

  /// Register a specific Firebase UID with a given development identity
  static void registerUidProfile(String uid, Map<String, dynamic> profile) {
    if (!kDebugMode) {
      throw StateError('CRITICAL: DevIdentityRegistry must not be accessed in release builds.');
    }
    _profilesByUid[uid] = profile;
    developer.log('Registered DevIdentity for UID: $uid', name: 'Acadex.Auth');
  }

  /// Get the Acadex user profile map for a given Firebase UID
  static Map<String, dynamic>? getProfile(String uid, {String? email, String? displayName}) {
    if (!kDebugMode) {
      throw StateError('CRITICAL: DevIdentityRegistry must not be accessed in release builds.');
    }
    // 1. Check direct mock UID map
    if (_mockProfiles.containsKey(uid)) {
      return _mockProfiles[uid];
    }

    // 2. Check explicitly registered UID map
    if (_profilesByUid.containsKey(uid)) {
      return _profilesByUid[uid];
    }

    // 3. Temporary Development Identity resolution for Firebase Console test accounts
    if (email != null && email.isNotEmpty) {
      final normEmail = email.toLowerCase().trim();
      String? role;
      
      if (normEmail == 'superadmin.test@acadex.com' || normEmail.startsWith('superadmin.') || normEmail.startsWith('superadmin@')) {
        role = 'superAdmin';
      } else if (normEmail == 'admin.test@acadex.com' || normEmail.startsWith('admin.') || normEmail.startsWith('admin@') || normEmail.startsWith('college.')) {
        role = 'collegeAdmin';
      } else if (normEmail == 'hod.test@acadex.com' || normEmail.startsWith('hod.') || normEmail.startsWith('hod@')) {
        role = 'hod';
      } else if (normEmail == 'faculty.test@acadex.com' || normEmail.startsWith('faculty.') || normEmail.startsWith('faculty@') || normEmail.startsWith('teacher.')) {
        role = 'faculty';
      } else if (normEmail == 'student.test@acadex.com' || normEmail.startsWith('student.') || normEmail.startsWith('student@')) {
        role = 'student';
      }

      if (role != null) {
        final profile = {
          'id': uid,
          'firebaseUid': uid,
          'name': (displayName != null && displayName.isNotEmpty) ? displayName : email.split('@').first,
          'email': email,
          'role': role,
          'accountStatus': 'active',
          'createdAt': DateTime.now().toIso8601String(),
          'lastLoginAt': DateTime.now().toIso8601String(),
        };
        _profilesByUid[uid] = profile;
        developer.log('Resolved temporary dev identity for UID: $uid ($email) -> Role: $role', name: 'Acadex.Auth');
        return profile;
      }
    }

    // 4. Return null if no identity matches — NO DEFAULT STUDENT FALLBACK!
    developer.log('DevIdentityRegistry: Profile resolution returning NULL for UID: $uid', name: 'Acadex.Auth');
    return null;
  }
}
