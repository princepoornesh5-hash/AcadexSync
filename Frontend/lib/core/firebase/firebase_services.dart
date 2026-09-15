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

class PaginatedResponse<T> {
  final List<T> data;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedResponse({
    required this.data,
    this.lastDocument,
    required this.hasMore,
  });
}

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

  Future<void> batchSetDocuments(Map<String, Map<String, dynamic>> documentPathToDataMap) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final entry in documentPathToDataMap.entries) {
          final parts = entry.key.split('/');
          if (parts.length >= 2) {
            final collection = parts[0];
            final docId = parts.sublist(1).join('/');
            final docRef = FirebaseFirestore.instance.collection(collection).doc(docId);
            batch.set(docRef, entry.value, SetOptions(merge: true));
          }
        }
        await batch.commit();
      } catch (e) {
        developer.log('Firestore batchSetDocuments error: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          rethrow;
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      throw const BackendNetworkException('Firebase is uninitialized.');
    }

    if (FirebaseInitializer.shouldUseMock) {
      for (final entry in documentPathToDataMap.entries) {
        final parts = entry.key.split('/');
        if (parts.length >= 2) {
          final collection = parts[0];
          final docId = parts.sublist(1).join('/');
          _memoryStore.putIfAbsent(collection, () => {})[docId] = entry.value;
        }
      }
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

  Future<PaginatedResponse<Map<String, dynamic>>> queryCollectionPaginated(
    String collection, 
    Map<String, dynamic> filters, {
    int limit = 20,
    String? orderBy,
    bool descending = false,
    DocumentSnapshot? startAfterDocument,
  }) async {
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

        if (orderBy != null) {
          query = query.orderBy(orderBy, descending: descending);
        }

        if (startAfterDocument != null) {
          query = query.startAfterDocument(startAfterDocument);
        }

        query = query.limit(limit);

        final snapshot = await query.get();
        final docs = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        
        return PaginatedResponse(
          data: docs,
          lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
          hasMore: docs.length == limit,
        );
      } catch (e) {
        developer.log('Firestore queryCollectionPaginated error for $collection: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          rethrow;
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      throw const BackendNetworkException('Firebase is uninitialized.');
    }

    // Mock mode implementation
    final allDocs = _memoryStore[collection]?.values.toList() ?? [];
    var filtered = allDocs.where((doc) {
      for (final entry in filters.entries) {
        if (entry.value is Iterable) {
          if (!(entry.value as Iterable).contains(doc[entry.key])) return false;
        } else {
          if (doc[entry.key] != entry.value) return false;
        }
      }
      return true;
    }).toList();

    if (orderBy != null) {
      filtered.sort((a, b) {
        final aVal = a[orderBy] as Comparable?;
        final bVal = b[orderBy] as Comparable?;
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return descending ? 1 : -1;
        if (bVal == null) return descending ? -1 : 1;
        return descending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
      });
    }

    int startIndex = 0;
    if (startAfterDocument != null && startAfterDocument.id.isNotEmpty) {
      final idx = filtered.indexWhere((doc) => doc['id'] == startAfterDocument.id);
      if (idx != -1) startIndex = idx + 1;
    }

    final endIndex = (startIndex + limit) > filtered.length ? filtered.length : (startIndex + limit);
    final pagedDocs = filtered.sublist(startIndex, endIndex);

    return PaginatedResponse(
      data: pagedDocs,
      lastDocument: null, // Mock mode doesn't use real snapshots
      hasMore: endIndex < filtered.length,
    );
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

  Future<List<Map<String, dynamic>>> queryCollectionPrefix(String collection, String searchField, String prefix, {Map<String, dynamic>? filters, int limit = 20}) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        Query query = FirebaseFirestore.instance.collection(collection);
        if (filters != null) {
          filters.forEach((key, value) {
            if (value is Iterable) {
              query = query.where(key, whereIn: value.toList());
            } else {
              query = query.where(key, isEqualTo: value);
            }
          });
        }
        query = query.where(searchField, isGreaterThanOrEqualTo: prefix)
                     .where(searchField, isLessThan: '$prefix\uf8ff')
                     .limit(limit);
                     
        final snapshot = await query.get();
        return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      } catch (e) {
        developer.log('Firestore queryCollectionPrefix error for $collection: $e', name: 'Acadex.Firestore');
        if (!FirebaseInitializer.shouldUseMock) {
          rethrow;
        }
      }
    } else if (!FirebaseInitializer.shouldUseMock) {
      throw const BackendNetworkException('Firebase is uninitialized.');
    }
    
    final allDocs = _memoryStore[collection]?.values.toList() ?? [];
    return allDocs.where((doc) {
      if (filters != null) {
        for (final entry in filters.entries) {
          if (entry.value is Iterable) {
            if (!(entry.value as Iterable).contains(doc[entry.key])) return false;
          } else {
            if (doc[entry.key] != entry.value) return false;
          }
        }
      }
      final fieldValue = doc[searchField]?.toString().toLowerCase() ?? '';
      return fieldValue.startsWith(prefix.toLowerCase());
    }).take(limit).toList();
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

  Stream<List<Map<String, dynamic>>> watchQuery(
    String collection, 
    Map<String, dynamic> filters, {
    int? limit,
    String? orderBy,
    bool descending = false,
  }) {
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

        if (orderBy != null) {
          query = query.orderBy(orderBy, descending: descending);
        }

        if (limit != null) {
          query = query.limit(limit);
        }

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
    
    var filtered = allDocs.where((doc) {
      for (final entry in filters.entries) {
        if (entry.value is Iterable) {
          if (!(entry.value as Iterable).contains(doc[entry.key])) return false;
        } else {
          if (doc[entry.key] != entry.value) return false;
        }
      }
      return true;
    }).toList();

    if (orderBy != null) {
      filtered.sort((a, b) {
        final aVal = a[orderBy] as Comparable?;
        final bVal = b[orderBy] as Comparable?;
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return descending ? 1 : -1;
        if (bVal == null) return descending ? -1 : 1;
        return descending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
      });
    }

    if (limit != null && filtered.length > limit) {
      filtered = filtered.sublist(0, limit);
    }

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
      return await uploadTask.ref.getMetadata();
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
