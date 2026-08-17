import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dev_identity_registry.dart';
import 'firebase_exceptions.dart';
import 'firebase_initializer.dart';

// --- Auth Service ---

class FirebaseAuthService {
  final FirebaseAuth? _auth;

  FirebaseAuthService(this._auth);

  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth == null) return Stream.value(null);
    try {
      return auth.authStateChanges();
    } catch (e) {
      developer.log('Error getting authStateChanges: $e', name: 'Acadex.Firebase');
      return Stream.value(null);
    }
  }

  User? get currentUser {
    final auth = _auth;
    if (auth == null) return null;
    try {
      return auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw const BackendNetworkException('Firebase Auth service is offline/uninitialized.');
    }
    try {
      return await auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw FirebaseErrorMapper.map(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw const BackendNetworkException('Firebase Auth service is offline/uninitialized.');
    }
    try {
      await auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw FirebaseErrorMapper.map(e);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) {
      throw const BackendNetworkException('No authenticated user found.');
    }
    try {
      await user.updatePassword(newPassword);
    } catch (e) {
      throw FirebaseErrorMapper.map(e);
    }
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    try {
      await auth.signOut();
    } catch (e) {
      throw FirebaseErrorMapper.map(e);
    }
  }
}

// --- Firestore Service Wrapper ---

class FirestoreService {
  final Map<String, Map<String, Map<String, dynamic>>> _memoryStore = {};

  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
        if (doc.exists && doc.data() != null) {
          return doc.data();
        }
      } catch (e) {
        developer.log('Firestore getDocument error for $collection/$id: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          rethrow;
        }
      }
    }
    
    if (!FirebaseInitializer.shouldUseMock) {
      if (Firebase.apps.isEmpty) {
        throw const BackendNetworkException('Firebase is uninitialized.');
      }
      return null; // Return null safely (doc not found). Do NOT fallback to DevIdentityRegistry.
    }

    if (collection == 'users') {
      await Future.delayed(const Duration(milliseconds: 100));
      final currentUser = Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
      final email = currentUser != null && currentUser.uid == id ? currentUser.email : null;
      final displayName = currentUser != null && currentUser.uid == id ? currentUser.displayName : null;
      return DevIdentityRegistry.getProfile(id, email: email, displayName: displayName);
    }
    return _memoryStore[collection]?[id];
  }

  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection(collection).doc(id).set(data, SetOptions(merge: true));
      } catch (e) {
        developer.log('Firestore setDocument error for $collection/$id: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          rethrow;
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      throw const BackendNetworkException('Firebase is uninitialized.');
    }
    
    if (FirebaseInitializer.shouldUseMock) {
      _memoryStore.putIfAbsent(collection, () => {})[id] = data;
    }
  }

  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection(collection).get();
        return snapshot.docs.map((doc) => doc.data()).toList();
      } catch (e) {
        developer.log('Firestore getCollection error for $collection: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          rethrow;
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      throw const BackendNetworkException('Firebase is uninitialized.');
    }
    return _memoryStore[collection]?.values.toList() ?? [];
  }

  Future<void> deleteDocument(String collection, String id) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection(collection).doc(id).delete();
      } catch (e) {
        developer.log('Firestore deleteDocument error for $collection/$id: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          rethrow;
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      throw const BackendNetworkException('Firebase is uninitialized.');
    }
    _memoryStore[collection]?.remove(id);
  }

  Future<List<Map<String, dynamic>>> queryCollection(String collection, Map<String, dynamic> filters) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        Query query = FirebaseFirestore.instance.collection(collection);
        filters.forEach((key, value) {
          if (value is Iterable) {
            query = query.where(key, whereIn: value.toList());
          } else {
            query = query.where(key, isEqualTo: value);
          }
        });
        final snapshot = await query.get();
        return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      } catch (e) {
        developer.log('Firestore queryCollection error for $collection: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          rethrow;
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      throw const BackendNetworkException('Firebase is uninitialized.');
    }
    final allDocs = _memoryStore[collection]?.values.toList() ?? [];
    return allDocs.where((doc) {
      for (final entry in filters.entries) {
        if (entry.value is Iterable) {
          if (!(entry.value as Iterable).contains(doc[entry.key])) return false;
        } else {
          if (doc[entry.key] != entry.value) return false;
        }
      }
      return true;
    }).toList();
  }

  Stream<Map<String, dynamic>?> watchDocument(String collection, String id) {
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseFirestore.instance.collection(collection).doc(id).snapshots().map((doc) => doc.exists ? doc.data() : null);
      } catch (e) {
        developer.log('Firestore watchDocument error for $collection/$id: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          return Stream.error(e);
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      return Stream.error(const BackendNetworkException('Firebase is uninitialized.'));
    }
    return Stream.value(_memoryStore[collection]?[id]);
  }

  Stream<List<Map<String, dynamic>>> watchCollection(String collection) {
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseFirestore.instance.collection(collection).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList()
        );
      } catch (e) {
        developer.log('Firestore watchCollection error for $collection: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          return Stream.error(e);
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      return Stream.error(const BackendNetworkException('Firebase is uninitialized.'));
    }
    return Stream.value(_memoryStore[collection]?.values.toList() ?? []);
  }

  Stream<List<Map<String, dynamic>>> watchQuery(String collection, Map<String, dynamic> filters) {
    if (Firebase.apps.isNotEmpty) {
      try {
        Query query = FirebaseFirestore.instance.collection(collection);
        filters.forEach((key, value) {
          if (value is Iterable) {
            query = query.where(key, whereIn: value.toList());
          } else {
            query = query.where(key, isEqualTo: value);
          }
        });
        return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()
        );
      } catch (e) {
        developer.log('Firestore watchQuery error for $collection: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          return Stream.error(e);
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      return Stream.error(const BackendNetworkException('Firebase is uninitialized.'));
    }
    
    final allDocs = _memoryStore[collection]?.values.toList() ?? [];
    final filtered = allDocs.where((doc) {
      for (final entry in filters.entries) {
        if (entry.value is Iterable) {
          if (!(entry.value as Iterable).contains(doc[entry.key])) return false;
        } else {
          if (doc[entry.key] != entry.value) return false;
        }
      }
      return true;
    }).toList();
    return Stream.value(filtered);
  }
}

// --- Storage Service Wrapper ---

class FirebaseStorageService {
  final FirebaseStorage? _storage;

  FirebaseStorageService({FirebaseStorage? storage}) : _storage = storage ?? (Firebase.apps.isNotEmpty ? FirebaseStorage.instance : null);

  Future<FullMetadata> uploadFile(String path, Uint8List bytes, SettableMetadata metadata) async {
    if (_storage == null) throw const BackendNetworkException('Firebase Storage service is offline/uninitialized.');
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putData(bytes, metadata);
      return uploadTask.ref.getMetadata();
    } on FirebaseException catch (e) {
      throw FirebaseErrorMapper.map(e);
    } catch (e) {
      throw FirebaseErrorMapper.map(Exception(e.toString()));
    }
  }

  Future<String> getDownloadUrl(String path) async {
    if (_storage == null) throw const BackendNetworkException('Firebase Storage service is offline/uninitialized.');
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw FirebaseErrorMapper.map(e);
    } catch (e) {
      throw FirebaseErrorMapper.map(Exception(e.toString()));
    }
  }

  Future<FullMetadata> getMetadata(String path) async {
    if (_storage == null) throw const BackendNetworkException('Firebase Storage service is offline/uninitialized.');
    try {
      final ref = _storage.ref().child(path);
      return await ref.getMetadata();
    } on FirebaseException catch (e) {
      throw FirebaseErrorMapper.map(e);
    } catch (e) {
      throw FirebaseErrorMapper.map(Exception(e.toString()));
    }
  }

  Future<void> deleteFile(String path) async {
    if (_storage == null) throw const BackendNetworkException('Firebase Storage service is offline/uninitialized.');
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw FirebaseErrorMapper.map(e);
    } catch (e) {
      throw FirebaseErrorMapper.map(Exception(e.toString()));
    }
  }

  Future<ListResult> listFiles(String path) async {
    if (_storage == null) throw const BackendNetworkException('Firebase Storage service is offline/uninitialized.');
    try {
      final ref = _storage.ref().child(path);
      return await ref.listAll();
    } on FirebaseException catch (e) {
      throw FirebaseErrorMapper.map(e);
    } catch (e) {
      throw FirebaseErrorMapper.map(Exception(e.toString()));
    }
  }

  Future<FullMetadata> updateMetadata(String path, SettableMetadata metadata) async {
    if (_storage == null) throw const BackendNetworkException('Firebase Storage service is offline/uninitialized.');
    try {
      final ref = _storage.ref().child(path);
      return await ref.updateMetadata(metadata);
    } on FirebaseException catch (e) {
      throw FirebaseErrorMapper.map(e);
    } catch (e) {
      throw FirebaseErrorMapper.map(Exception(e.toString()));
    }
  }
}

// --- Cloud Messaging Service Wrapper ---

class FirebaseMessagingService {
  Future<String?> getDeviceToken() async {
    return 'mock-fcm-token';
  }

  Future<void> subscribeToTopic(String topic) async {}
  Future<void> unsubscribeFromTopic(String topic) async {}
}

// --- Analytics Service Wrapper ---

class FirebaseAnalyticsService {
  Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    // Safe logging (prevents leaking sensitive info)
    final filteredParams = Map<String, dynamic>.from(parameters)
      ..removeWhere((key, value) => 
        key.toLowerCase().contains('password') ||
        key.toLowerCase().contains('email') ||
        key.toLowerCase().contains('name') ||
        key.toLowerCase().contains('student') ||
        key.toLowerCase().contains('faculty')
      );
    developer.log('Logged Analytics Event $name: $filteredParams');
  }
}

// --- Crash Reporting Service Wrapper ---

class CrashReportingService {
  Future<void> recordError(dynamic exception, StackTrace? stack) async {}
  Future<void> log(String message) async {}
}

// --- Riverpod Providers ---

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAuth.instance;
    }
  } catch (e) {
    developer.log('FirebaseAuth instance unavailable: $e', name: 'Acadex.Firebase');
  }
  return null;
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(ref.watch(firebaseAuthProvider));
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});

final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  return FirebaseMessagingService();
});

final firebaseAnalyticsServiceProvider = Provider<FirebaseAnalyticsService>((ref) {
  return FirebaseAnalyticsService();
});

final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  return CrashReportingService();
});
