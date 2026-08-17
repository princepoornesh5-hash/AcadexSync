# Acadex Firebase Storage & File Management Foundation

## Overview
This document describes the foundational architecture for handling file uploads, downloads, and management in Acadex using Firebase Storage.

The storage foundation provides centralized control over file paths, sizes, and MIME types. It ensures that components never construct arbitrary storage references locally.

## Architecture

```
Future UI Modules (e.g., Profile, Certificates, Notes)
       │
       ▼
Riverpod Provider (fileStorageRepositoryProvider)
       │
       ▼
FileStorageRepository (Abstract Interface)
       │
       ├── Mock Mode ──────► MockFileStorageRepository (In-Memory)
       └── Firebase Mode ──► FirebaseFileStorageRepository
                                   │
                                   ▼
                             FirebaseStorageService
                                   │
                                   ▼
                             Cloud Storage for Firebase
```

## Supported Categories & MIME Constraints
All file uploads are categorized to easily enforce business logic and restrictions.

1. **Profile Images** (`profileImage`):
   - Restricted to `image/*`.
   - Size limit: 5 MB.
2. **Student Certificates** (`certificate`):
   - Used for achievements and certifications.
   - Size limit: 10 MB.
3. **Faculty Notes** (`noteAttachment`):
   - Class materials shared by faculty.
   - Size limit: 25 MB.
   - Excludes `.exe`, `.bat`, `.sh`, `.apk`.
4. **Other** (`other`):
   - General files. Limit: 25 MB.

## Path Structure
Paths are deterministic and mapped by the repository:
- Profile: `colleges/{collegeId}/users/{uid}/profile/{fileId}_{sanitizedName}`
- Certificates: `colleges/{collegeId}/students/{studentId}/certificates/{fileId}_{sanitizedName}`
- Notes: `colleges/{collegeId}/faculty/{facultyUid}/notes/{fileId}_{sanitizedName}`

## Security Rules (`storage.rules`)
Firebase Storage Security Rules enforce authentication, ownership constraints, file sizes, and basic content type rules before files are written. 

> **Important**: You must manually deploy `storage.rules` when enabling Firebase Storage in the Firebase Console!

## File Identity (`StoredFile`)
The authoritative record for a file is the `StoredFile` domain model, mapped from `FullMetadata`. The system relies on custom metadata for lookup parameters (`ownerUid`, `collegeId`, `category`).

## Future Firestore Metadata Considerations
Currently, `StoredFile` metadata remains attached directly to the Firebase Storage object via `customMetadata`. If complex multi-file querying or indexing is needed in the future, developers can safely construct Firestore triggers or parallel writes (e.g., to a `file_metadata` collection) using this architecture as a base.
