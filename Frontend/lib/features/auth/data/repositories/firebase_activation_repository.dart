import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../domain/models/activation_model.dart';
import '../../domain/models/role_enum.dart';
import '../../domain/models/user_model.dart' as u;
import '../../domain/repositories/activation_repository.dart';

class FirebaseActivationRepository implements AccountActivationRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  FirebaseActivationRepository(this._firestoreService, {FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<String> generateActivationCode(Student student) async {
    final String plaintextCode = const Uuid().v4().substring(0, 8).toUpperCase();
    final recordId = ActivationRecord.hashCodeString(plaintextCode);
    
    final record = ActivationRecord(
      id: recordId,
      studentId: student.id,
      rollNumber: student.rollNumber,
      role: AppRole.student,
      codeHash: ActivationRecord.hashCodeString(plaintextCode),
      status: ActivationStatus.pending,
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
      createdAt: DateTime.now(),
    );

    await _firestoreService.setDocument(
      'activationCodes',
      recordId,
      record.toJson(),
    );

    return plaintextCode;
  }

  @override
  Future<String> generateFacultyActivationCode(Faculty faculty) async {
    final String plaintextCode = const Uuid().v4().substring(0, 8).toUpperCase();
    final recordId = ActivationRecord.hashCodeString(plaintextCode);
    
    final record = ActivationRecord(
      id: recordId,
      facultyId: faculty.id,
      employeeId: faculty.employeeId,
      role: AppRole.faculty,
      codeHash: ActivationRecord.hashCodeString(plaintextCode),
      status: ActivationStatus.pending,
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
      createdAt: DateTime.now(),
    );

    await _firestoreService.setDocument(
      'activationCodes',
      recordId,
      record.toJson(),
    );

    return plaintextCode;
  }

  @override
  Future<dynamic> validateActivation(String identifier, String code) async {
    final inputHash = ActivationRecord.hashCodeString(code);
    
    final docSnapshot = await FirebaseFirestore.instance
        .collection('activationCodes')
        .doc(inputHash)
        .get();

    if (!docSnapshot.exists || docSnapshot.data() == null) {
      throw Exception("Invalid activation details.");
    }

    final record = ActivationRecord.fromJson(docSnapshot.data()!);
    if (record.rollNumber != identifier && record.employeeId != identifier) {
      throw Exception("Invalid activation details.");
    }

    if (record.status == ActivationStatus.used) {
      throw Exception("This activation code has already been used.");
    }
    if (record.status == ActivationStatus.expired || record.isExpired) {
      throw Exception("This activation code has expired.");
    }
    if (record.status == ActivationStatus.disabled) {
      throw Exception("This activation code has been disabled.");
    }

    if (record.role == AppRole.student) {
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(record.studentId).get();
      if (!studentDoc.exists || studentDoc.data() == null) {
        throw Exception("Associated student record not found.");
      }
      return Student.fromJson(studentDoc.data()!).toJson();
    } else {
      final facultyDoc = await FirebaseFirestore.instance.collection('faculty').doc(record.facultyId).get();
      if (!facultyDoc.exists || facultyDoc.data() == null) {
        throw Exception("Associated faculty record not found.");
      }
      return Faculty.fromJson(facultyDoc.data()!).toJson();
    }
  }

  @override
  Future<String> completeActivation(String identifier, String code, String newPassword) async {
    final inputHash = ActivationRecord.hashCodeString(code);
    
    final docSnapshot = await FirebaseFirestore.instance
        .collection('activationCodes')
        .doc(inputHash)
        .get();

    if (!docSnapshot.exists || docSnapshot.data() == null) {
      throw Exception("Invalid activation details.");
    }

    final recordDoc = docSnapshot;
    final record = ActivationRecord.fromJson(recordDoc.data()!);

    if (record.rollNumber != identifier && record.employeeId != identifier) {
      throw Exception("Invalid activation details.");
    }

    if (record.status != ActivationStatus.pending || record.isExpired) {
      throw Exception("This activation code is no longer valid for activation.");
    }

    // Determine target record
    String email = '';
    String name = '';
    String? collegeId;
    String? departmentId;

    if (record.role == AppRole.student) {
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(record.studentId).get();
      if (!studentDoc.exists || studentDoc.data() == null) {
        throw Exception("Associated student record not found.");
      }
      final student = Student.fromJson(studentDoc.data()!);
      email = student.email;
      name = student.name;
      collegeId = student.collegeId;
      departmentId = student.departmentId;
    } else {
      final facultyDoc = await FirebaseFirestore.instance.collection('faculty').doc(record.facultyId).get();
      if (!facultyDoc.exists || facultyDoc.data() == null) {
        throw Exception("Associated faculty record not found.");
      }
      final faculty = Faculty.fromJson(facultyDoc.data()!);
      email = faculty.email;
      name = faculty.name;
      departmentId = faculty.departmentId;
      
      final deptDoc = await FirebaseFirestore.instance.collection('departments').doc(departmentId).get();
      collegeId = deptDoc.data()?['collegeId'] as String? ?? 'col-1';
    }

    // Run in a transaction to ensure atomicity for Firestore updates (Firebase Auth is external to transaction)
    UserCredential credential;
    try {
      // 1. Create Firebase Auth user
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: newPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception("An account already exists for this email.");
      } else if (e.code == 'weak-password') {
        throw Exception("The password provided is too weak.");
      }
      throw Exception("Failed to create authentication account.");
    }

    final uid = credential.user!.uid;

    try {
      // 2. Perform Firestore transaction to create profile and mark code used
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final freshRecordDoc = await transaction.get(recordDoc.reference);
        if (!freshRecordDoc.exists) {
          throw Exception("Activation record deleted.");
        }
        
        final freshRecord = ActivationRecord.fromJson(freshRecordDoc.data()!);
        if (freshRecord.status != ActivationStatus.pending) {
          throw Exception("Activation code already used.");
        }

        // Create the user profile
        final userProfile = u.UserModel(
          id: uid, // Use Firebase UID as document ID
          firebaseUid: uid,
          name: name,
          email: email,
          role: record.role,
          collegeId: collegeId,
          departmentId: departmentId,
          accountStatus: u.AccountStatus.active,
          createdAt: DateTime.now(),
        );

        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        
        // Ensure user doesn't already exist
        final userCheck = await transaction.get(userRef);
        if (userCheck.exists) {
          throw Exception("User profile already exists.");
        }

        transaction.set(userRef, userProfile.toJson());

        // Mark activation code as used
        transaction.update(recordDoc.reference, {
          'status': ActivationStatus.used.value,
          'usedAt': DateTime.now().toIso8601String(),
        });
      });
      
      return uid;
    } catch (e) {
      // If Firestore transaction fails, we should ideally clean up the Firebase Auth user
      // but standard practice may vary based on retry logic. We will attempt a rollback.
      try {
        await credential.user?.delete();
      } catch (rollbackError) {
        // Log rollback error
      }
      rethrow;
    }
  }
}
