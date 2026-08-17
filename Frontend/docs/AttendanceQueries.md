# Acadex Attendance Firestore Queries (`Prompt 24`)

## Query Patterns by Role

### 1. Student Queries
- **Subject Attendance**: `firestore.collection('attendance').where('studentId', '==', studentId)`
- **Attendance History**: `firestore.collection('attendance').where('studentId', '==', studentId).orderBy('date', 'desc')`

### 2. Faculty Queries
- **Get Section Students / Check Existing Session**: `firestore.collection('attendanceSessions').doc(sessionId).get()`
- **Save Attendance Session**: Write batch to `attendanceSessions/{sessionId}` and `attendance/{attendanceId}`

### 3. HOD Queries
- **Department Completion**: `firestore.collection('attendanceSessions').where('departmentId', '==', departmentId).where('date', '==', todayDate)`
- **Department Shortage**: Compute students with percentage < 75% in department scope.

### 4. College & Super Admin Queries
- Aggregate metrics across department and college collections.
