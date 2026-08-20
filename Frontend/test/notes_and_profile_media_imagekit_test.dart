import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:campus_management/core/network/api_client.dart';
import 'package:campus_management/core/services/imagekit_uploader.dart';
import 'package:campus_management/features/notes/data/repositories/api_notes_repository.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/domain/utils/note_mime_helper.dart';
import 'package:campus_management/features/profile/data/repositories/profile_repository.dart';

void main() {
  group('ACADEX Phase 9L.3 — Notes & Profile Media ImageKit Integration Tests', () {
    late Dio mockBackendDio;
    late Dio mockImageKitDio;
    late ApiClient testApiClient;
    late ImageKitUploader testUploader;
    late ApiNotesRepository notesRepository;
    late ProfileRepository profileRepository;

    setUp(() {
      mockBackendDio = Dio();
      mockImageKitDio = Dio();

      testApiClient = ApiClient(customDio: mockBackendDio);

      testUploader = ImageKitUploader(mockImageKitDio);
      notesRepository = ApiNotesRepository(
        apiClient: testApiClient,
        uploader: testUploader,
      );
      profileRepository = ProfileRepository(
        apiClient: testApiClient,
        uploader: testUploader,
      );
    });

    // -----------------------------------------------------------------------
    // TEST 1: Notes repository upload authorization
    // -----------------------------------------------------------------------
    test('1. Notes repository requests upload authorization successfully', () async {
      mockBackendDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/academics/notes/upload-url')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'note': {
                        'id': 'note-101',
                        'title': 'Operating Systems Lecture 1',
                        'description': 'Intro to OS',
                        'resourceType': 'file_attachment',
                        'subjectId': 'sub-os',
                        'semesterId': 'sem-1',
                        'authorUserId': 'user-fac-1',
                        'createdAt': DateTime.now().toIso8601String(),
                        'updatedAt': DateTime.now().toIso8601String(),
                      },
                      'uploadAuth': {
                        'token': 'mock-ik-token-123',
                        'expire': 1700000300,
                        'signature': 'mock-ik-signature-abc',
                        'publicKey': 'public_SWyvxdffTgYY7X/b+eMS3B6Vv64=',
                        'urlEndpoint': 'https://ik.imagekit.io/AcadexAi',
                        'folder': '/acadex/colleges/col-1/notes/courses/c1/sem-1/sub-os/note-101',
                        'fileName': 'os_lecture1.pdf',
                        'fileId': 'file-101',
                      },
                      'uploadUrl': 'https://upload.imagekit.io/api/v1/files/upload',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final session = await notesRepository.requestUploadAuth(
        subjectId: 'sub-os',
        title: 'Operating Systems Lecture 1',
        description: 'Intro to OS',
        fileName: 'os_lecture1.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 500,
        semesterId: 'sem-1',
      );

      expect(session.note.id, 'note-101');
      expect(session.note.title, 'Operating Systems Lecture 1');
      expect(session.auth.token, 'mock-ik-token-123');
      expect(session.auth.publicKey, 'public_SWyvxdffTgYY7X/b+eMS3B6Vv64=');
      expect(session.auth.signature, 'mock-ik-signature-abc');
      expect(session.auth.folder, contains('/notes/'));
    });

    // -----------------------------------------------------------------------
    // TEST 2: Notes repository completion
    // -----------------------------------------------------------------------
    test('2. Notes repository completes upload after ImageKit direct upload', () async {
      mockBackendDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/academics/notes/note-101/complete')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'id': 'note-101',
                      'title': 'Operating Systems Lecture 1',
                      'description': 'Intro to OS',
                      'resourceType': 'file_attachment',
                      'fileId': 'ik_file_os_101',
                      'fileUrl': 'https://ik.imagekit.io/AcadexAi/acadex/os_lecture1.pdf',
                      'thumbnailUrl': 'https://ik.imagekit.io/AcadexAi/tr:w-300/acadex/os_lecture1.pdf',
                      'status': 'published',
                      'subjectId': 'sub-os',
                      'semesterId': 'sem-1',
                      'authorUserId': 'user-fac-1',
                      'createdAt': DateTime.now().toIso8601String(),
                      'updatedAt': DateTime.now().toIso8601String(),
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final completedNote = await notesRepository.completeUpload(
        noteId: 'note-101',
        fileId: 'ik_file_os_101',
        fileUrl: 'https://ik.imagekit.io/AcadexAi/acadex/os_lecture1.pdf',
        thumbnailUrl: 'https://ik.imagekit.io/AcadexAi/tr:w-300/acadex/os_lecture1.pdf',
      );

      expect(completedNote.id, 'note-101');
      expect(completedNote.status, NoteStatus.published);
      expect(completedNote.fileUrl, contains('https://ik.imagekit.io/AcadexAi'));
      expect(completedNote.fileId, 'ik_file_os_101');
    });

    // -----------------------------------------------------------------------
    // TEST 3: Notes listing (Faculty & Student feed)
    // -----------------------------------------------------------------------
    test('3. Notes listing retrieves notes for faculty and student feeds', () async {
      mockBackendDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/academics/notes/students/me')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'items': [
                        {
                          'id': 'note-s1',
                          'title': 'Data Structures Tree Traversal',
                          'description': 'Inorder, preorder, postorder',
                          'resourceType': 'file_attachment',
                          'fileName': 'trees.pdf',
                          'fileSize': 1048576,
                          'fileUrl': 'https://ik.imagekit.io/AcadexAi/trees.pdf',
                          'subjectId': 'sub-dsa',
                          'semesterId': 'sem-3',
                          'authorUserId': 'fac-dsa',
                          'status': 'published',
                          'createdAt': DateTime.now().toIso8601String(),
                          'updatedAt': DateTime.now().toIso8601String(),
                        }
                      ],
                      'total': 1,
                    },
                  },
                ),
              );
            } else if (options.path.contains('/academics/notes')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'items': [
                        {
                          'id': 'note-f1',
                          'title': 'Algorithms Lecture Notes',
                          'description': 'Dynamic Programming',
                          'resourceType': 'file_attachment',
                          'subjectId': 'sub-algo',
                          'semesterId': 'sem-4',
                          'authorUserId': 'fac-algo',
                          'status': 'published',
                          'createdAt': DateTime.now().toIso8601String(),
                          'updatedAt': DateTime.now().toIso8601String(),
                        }
                      ],
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final studentNotes = await notesRepository.getStudentPersonalNotes();
      expect(studentNotes.length, 1);
      expect(studentNotes.first.title, 'Data Structures Tree Traversal');
      expect(studentNotes.first.subjectId, 'sub-dsa');

      final facultyNotes = await notesRepository.getNotes(collegeId: 'col-1');
      expect(facultyNotes.length, 1);
      expect(facultyNotes.first.title, 'Algorithms Lecture Notes');
    });

    // -----------------------------------------------------------------------
    // TEST 4: Notes download URL retrieval
    // -----------------------------------------------------------------------
    test('4. Notes download URL retrieval returns fresh short-lived signed URL', () async {
      mockBackendDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/academics/notes/note-101/download')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'downloadUrl': 'https://ik.imagekit.io/AcadexAi/acadex/os_lecture1.pdf?ik-s=signed_token_xyz',
                      'expiresInSeconds': 300,
                      'fileName': 'os_lecture1.pdf',
                      'mimeType': 'application/pdf',
                      'fileSize': 1048576,
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final result = await notesRepository.getDownloadUrl('note-101');
      expect(result.downloadUrl, contains('ik-s=signed_token_xyz'));
      expect(result.expiresInSeconds, 300);
      expect(result.fileName, 'os_lecture1.pdf');
      expect(result.fileSize, 1048576);
    });

    // -----------------------------------------------------------------------
    // TEST 5: Profile image upload flow
    // -----------------------------------------------------------------------
    test('5. Profile image upload flow requests auth, uploads, and verifies', () async {
      mockBackendDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/users/me/profile-image/upload-url')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'uploadAuth': {
                        'token': 'mock-profile-token',
                        'expire': 1700000300,
                        'signature': 'mock-profile-sig',
                        'publicKey': 'public_SWyvxdffTgYY7X/b+eMS3B6Vv64=',
                        'urlEndpoint': 'https://ik.imagekit.io/AcadexAi',
                        'folder': '/acadex/colleges/col-1/profiles/students/stu-1',
                        'fileName': 'avatar.jpg',
                        'fileId': 'file-avatar-1',
                      },
                      'uploadUrl': 'https://upload.imagekit.io/api/v1/files/upload',
                    },
                  },
                ),
              );
            } else if (options.path.contains('/users/me/profile-image/complete')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'id': 'stu-1',
                      'name': 'Alex Johnson',
                      'profilePictureUrl': 'https://ik.imagekit.io/AcadexAi/acadex/colleges/col-1/profiles/students/stu-1/avatar.jpg',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      mockImageKitDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('upload.imagekit.io')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'fileId': 'ik_avatar_file_id',
                    'name': 'avatar.jpg',
                    'url': 'https://ik.imagekit.io/AcadexAi/acadex/colleges/col-1/profiles/students/stu-1/avatar.jpg',
                    'size': 204800,
                    'filePath': '/acadex/colleges/col-1/profiles/students/stu-1/avatar.jpg',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final dummyBytes = Uint8List.fromList(List.generate(100, (i) => i % 256));
      final url = await profileRepository.uploadAndSetProfileImage(
        fileName: 'avatar.jpg',
        imageBytes: dummyBytes,
      );

      expect(url, contains('https://ik.imagekit.io/AcadexAi'));
    });

    // -----------------------------------------------------------------------
    // TEST 6: Authentication failure handling (401)
    // -----------------------------------------------------------------------
    test('6. Unauthenticated request throws 401 error', () async {
      mockBackendDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'success': false, 'message': 'Unauthorized: Token expired or missing'},
                ),
              ),
            );
          },
        ),
      );

      expect(
        () async => await notesRepository.getNotes(collegeId: 'col-1'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
      );
    });

    // -----------------------------------------------------------------------
    // TEST 7: Unauthorized access handling (403)
    // -----------------------------------------------------------------------
    test('7. Unauthorized action throws 403 forbidden error', () async {
      mockBackendDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 403,
                  data: {'success': false, 'message': 'Forbidden: Insufficient academic role permissions'},
                ),
              ),
            );
          },
        ),
      );

      expect(
        () async => await notesRepository.requestUploadAuth(
          subjectId: 'sub-other',
          title: 'Unauthorized Note',
          fileName: 'note.pdf',
          mimeType: 'application/pdf',
          fileSize: 1000,
        ),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 403)),
      );
    });

    // -----------------------------------------------------------------------
    // TEST 8: File-too-large handling
    // -----------------------------------------------------------------------
    test('8. File-too-large is rejected before making network calls', () async {
      // Notes max size: 25MB
      const largeNoteSize = 26 * 1024 * 1024;
      expect(NoteMimeHelper.isFileSizeValid(largeNoteSize), isFalse);

      final oversizedBytes = Uint8List(26 * 1024 * 1024);
      expect(
        () async => await notesRepository.uploadAndPublishNote(
          subjectId: 'sub-1',
          title: 'Too Big Note',
          fileName: 'huge.pdf',
          fileBytes: oversizedBytes,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('exceeds the maximum limit of 25MB'))),
      );

      // Profile max size: 5MB
      final oversizedProfileBytes = Uint8List(6 * 1024 * 1024);
      expect(
        () async => await profileRepository.uploadAndSetProfileImage(
          fileName: 'large_avatar.jpg',
          imageBytes: oversizedProfileBytes,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('exceeds the maximum limit of 5MB'))),
      );
    });

    // -----------------------------------------------------------------------
    // TEST 9: Unsupported-file handling
    // -----------------------------------------------------------------------
    test('9. Unsupported file extensions and MIME types are rejected', () async {
      expect(NoteMimeHelper.isExtensionSupported('malicious.exe'), isFalse);
      expect(NoteMimeHelper.isExtensionSupported('movie.mp4'), isFalse);
      expect(NoteMimeHelper.isExtensionSupported('archive.zip'), isFalse);

      expect(ProfileRepository.isImageExtensionSupported('notes.pdf'), isFalse);
      expect(ProfileRepository.isImageExtensionSupported('script.sh'), isFalse);
      expect(ProfileRepository.isImageExtensionSupported('photo.jpg'), isTrue);
      expect(ProfileRepository.isImageExtensionSupported('photo.png'), isTrue);
      expect(ProfileRepository.isImageExtensionSupported('photo.webp'), isTrue);

      final dummyBytes = Uint8List(100);
      expect(
        () async => await notesRepository.uploadAndPublishNote(
          subjectId: 'sub-1',
          title: 'Executable Note',
          fileName: 'virus.exe',
          fileBytes: dummyBytes,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Unsupported file format'))),
      );
    });

    // -----------------------------------------------------------------------
    // TEST 10: Network failure handling
    // -----------------------------------------------------------------------
    test('10. Network disconnection or timeout throws DioException', () async {
      mockBackendDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
                error: 'Connection timeout with backend',
              ),
            );
          },
        ),
      );

      expect(
        () async => await notesRepository.getNoteById('note-timeout'),
        throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.connectionTimeout)),
      );
    });

    // -----------------------------------------------------------------------
    // TEST 11: ImageKit upload failure handling
    // -----------------------------------------------------------------------
    test('11. Direct ImageKit upload failure triggers exception', () async {
      mockImageKitDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 500,
                data: {'message': 'ImageKit internal processing error'},
              ),
            );
          },
        ),
      );

      const auth = ImageKitUploadAuth(
        token: 'tok',
        expire: 12345,
        signature: 'sig',
        publicKey: 'pub',
        urlEndpoint: 'https://ik.imagekit.io/demo',
        folder: '/test',
        fileName: 'test.pdf',
      );

      expect(
        () async => await testUploader.uploadFile(
          fileBytes: Uint8List(50),
          fileName: 'test.pdf',
          auth: auth,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('ImageKit upload failed'))),
      );
    });

    // -----------------------------------------------------------------------
    // TEST 12: Backend verification failure handling
    // -----------------------------------------------------------------------
    test('12. Backend complete endpoint verification failure throws exception', () async {
      mockBackendDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/complete')) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 400,
                    data: {
                      'success': false,
                      'message': 'Uploaded file was not found in storage. Please upload the file first.'
                    },
                  ),
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      expect(
        () async => await notesRepository.completeUpload(
          noteId: 'note-missing',
          fileId: 'non_existent_file_id',
          fileUrl: 'https://ik.imagekit.io/AcadexAi/missing.pdf',
        ),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 400)),
      );
    });
  });
}
