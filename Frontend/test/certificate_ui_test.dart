import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/certificates/domain/models/certificate.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_type.dart';
import 'package:campus_management/features/certificates/domain/models/certificate_status.dart';
import 'package:campus_management/features/certificates/presentation/widgets/certificate_type_badge.dart';
import 'package:campus_management/features/certificates/presentation/widgets/file_preview_placeholder.dart';
import 'package:campus_management/features/certificates/presentation/widgets/certificate_card.dart';

void main() {
  group('CertificateTypeBadge Widget Tests', () {
    testWidgets('renders correct display name for Academic type', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CertificateTypeBadge(type: CertificateType.academic),
          ),
        ),
      );

      expect(find.text('Academic'), findsOneWidget);
    });

    testWidgets('renders correct display name for Technical type', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CertificateTypeBadge(type: CertificateType.technical),
          ),
        ),
      );

      expect(find.text('Technical'), findsOneWidget);
    });

    testWidgets('renders correct display name for Internship type', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CertificateTypeBadge(type: CertificateType.internship),
          ),
        ),
      );

      expect(find.text('Internship'), findsOneWidget);
    });
  });

  group('FilePreviewPlaceholder Widget Tests', () {
    testWidgets('indicates In-App Preview Ready for PDF format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FilePreviewPlaceholder(
              fileType: 'pdf',
              fileName: 'google_cloud_architect.pdf',
              fileSize: '1.2 MB',
            ),
          ),
        ),
      );

      expect(find.text('google_cloud_architect.pdf'), findsOneWidget);
      expect(find.text('1.2 MB · PDF'), findsOneWidget);
      expect(find.text('In-App Preview Ready'), findsOneWidget);
    });

    testWidgets('indicates Download Required for DOCX format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FilePreviewPlaceholder(
              fileType: 'docx',
              fileName: 'internship_report.docx',
              fileSize: '450.0 KB',
            ),
          ),
        ),
      );

      expect(find.text('internship_report.docx'), findsOneWidget);
      expect(find.text('450.0 KB · DOCX'), findsOneWidget);
      expect(find.text('Download Required to View'), findsOneWidget);
    });
  });

  group('CertificateCard Widget Tests', () {
    final testCert = Certificate(
      id: 'c-card-test',
      studentId: 'STU-001',
      studentUid: 'uid-001',
      studentName: 'Alice Johnson',
      collegeId: 'COL-1',
      departmentId: 'DEP-CSE',
      title: 'AWS Solutions Architect Associate',
      type: CertificateType.technical,
      issuer: 'Amazon Web Services',
      issueDate: DateTime(2025, 4, 10),
      fileName: 'aws_cert.pdf',
      fileType: 'pdf',
      fileSizeBytes: 1024 * 350,
      storageFileId: 'file-123',
      storagePath: 'certificates/uid-001/aws_cert.pdf',
      status: CertificateStatus.active,
      uploadedAt: DateTime(2025, 4, 11),
      updatedAt: DateTime(2025, 4, 11),
      uploadedBy: 'uid-001',
      isVerified: false,
    );

    testWidgets('renders title, issuer, type badge, and format pill', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CertificateCard(
              certificate: testCert,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('AWS Solutions Architect Associate'), findsOneWidget);
      expect(find.text('Amazon Web Services'), findsOneWidget);
      expect(find.text('Technical'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);

      await tester.tap(find.byType(CertificateCard));
      expect(tapped, isTrue);
    });

    testWidgets('displays verified badge when isVerified is true', (tester) async {
      final verifiedCert = testCert.copyWith(isVerified: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CertificateCard(
              certificate: verifiedCert,
            ),
          ),
        ),
      );

      expect(find.text('Verified ✓'), findsOneWidget);
    });

    testWidgets('displays student name when showStudentName is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CertificateCard(
              certificate: testCert,
              showStudentName: true,
            ),
          ),
        ),
      );

      expect(find.text('Alice Johnson (STU-001)'), findsOneWidget);
    });
  });
}
