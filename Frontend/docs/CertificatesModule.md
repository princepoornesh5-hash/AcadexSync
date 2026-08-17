# Acadex Certificate Management Module

## Overview
The Certificate Management module enables students to upload, manage, and track their academic and extracurricular certificates. Authorized faculty can view, verify, and manage student certificates within their academic scope.

The module is designed with a **storage-provider-independent architecture**. The actual binary file is stored via `FileStorageRepository`. The certificate metadata is stored separately in `CertificateRepository`. These two concerns are completely decoupled.

---

## Architecture

```
Certificate UI (Student Dashboard / Faculty Dashboard)
       │
       ▼
Riverpod Providers (certificateRepositoryProvider, fileStorageRepositoryProvider)
       │
       ├── CertificateRepository ──► MockCertificateRepository (current)
       │                           └──► Future: FirebaseCertificateRepository
       │
       └── FileStorageRepository ──► MockFileStorageRepository (current)
                                    └──► Future: Supabase / Firebase / Cloudinary
```

The Certificate UI **never** directly imports or calls Firebase Storage, Supabase, or any storage SDK.

---

## Certificate Model
| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique certificate ID |
| `studentId` | `String` | Stable app student ID (permanent) |
| `studentUid` | `String` | Firebase UID (permanent identity) |
| `studentName` | `String` | Denormalized for display |
| `collegeId` | `String?` | Context at upload time |
| `departmentId` | `String?` | Context at upload time |
| `title` | `String` | Certificate title |
| `type` | `CertificateType` | Enum category |
| `issuer` | `String` | Issuing organization |
| `issueDate` | `DateTime` | Date the certificate was issued |
| `fileName` | `String` | Sanitized storage filename |
| `fileType` | `String` | Extension (pdf, jpg, etc.) |
| `fileSizeBytes` | `int` | Size for display |
| `storageFileId` | `String` | File ID in storage provider |
| `storagePath` | `String` | Path in storage provider |
| `status` | `CertificateStatus` | active / verified / archived / removed |
| `uploadedAt` | `DateTime` | First upload timestamp |
| `uploadedBy` | `String` | UID of uploader (immutable) |
| `isVerified` | `bool` | Whether faculty has verified |
| `verifiedBy` | `String?` | UID of verifier |
| `verifiedAt` | `DateTime?` | When verified |

---

## Certificate Types
`academic`, `technical`, `internship`, `workshop`, `participation`, `achievement`, `sports`, `cultural`, `other`

## Certificate Statuses
| Status | Description |
|---|---|
| `active` | Normal, unverified certificate |
| `pendingVerification` | Submitted for verification |
| `verified` | Verified by authorized faculty |
| `archived` | Preserved but de-emphasized |
| `removed` | Soft deleted — record preserved for audit |

---

## Role Permissions
| Action | Student | Faculty | HOD | College Admin | Super Admin |
|---|---|---|---|---|---|
| View own certificates | ✓ | — | — | — | — |
| Upload own certificates | ✓ | — | — | — | — |
| Edit own metadata | ✓ | — | — | — | — |
| Remove own certificate | ✓ | — | — | — | — |
| Verify own certificate | ✗ | ✗ | ✗ | ✗ | ✗ |
| View dept student certs | — | ✓ | ✓ | ✓ | ✓ |
| Verify student certs | — | ✓ | ✓ | ✓ | ✓ |
| Edit student cert metadata | — | ✓ | ✓ | ✓ | ✓ |
| Archive student cert | — | ✓ | ✓ | ✓ | ✓ |
| Change certificate ownership | ✗ | ✗ | ✗ | ✗ | ✗ |

---

## File Limits & Validation
Configured centrally in `CertificateFileConfig`:
- **Maximum size**: 10 MB
- **Allowed extensions**: `pdf`, `jpg`, `jpeg`, `png`, `doc`, `docx`
- **Blocked extensions**: `exe`, `dmg`, `apk`, `bat`, `sh`, `cmd`, `msi`

---

## Graduation / Student Identity Preservation
**Certificates are permanently associated with `studentId` and `studentUid`.**

Even when:
- The student graduates
- Academic year changes
- Section/semester changes
- Student status changes to `graduated` or `alumni`

Certificates remain retrievable via `getStudentCertificates(studentUid)` because the query never depends on `sectionId` or `semesterId`.

---

## Current Storage Mode
**Development / Mock Mode**

The `MockFileStorageRepository` stores file metadata in memory during the session. Files are **not** persisted between application restarts.

The `MockCertificateRepository` also stores certificates in memory.

---

## How to Connect a Real Storage Provider
To connect Supabase Storage (or any other provider):
1. Create `SupabaseFileStorageRepository implements FileStorageRepository`
2. In `storage_providers.dart`, return `SupabaseFileStorageRepository(...)` instead of the mock
3. No certificate UI screens need to change

To persist certificate metadata in Firestore:
1. Create `FirebaseCertificateRepository implements CertificateRepository`
2. In `certificate_providers.dart`, return `FirebaseCertificateRepository(...)` instead of the mock
3. No certificate UI screens need to change
