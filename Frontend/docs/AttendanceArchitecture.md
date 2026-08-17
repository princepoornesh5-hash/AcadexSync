# Attendance Architecture Documentation

The attendance system acts as the operational core of Acadex. It handles class assignments, session creations, status entries, locking constraints, and statistics aggregations.

## Session Lifespan

1. **Creation**:
   - A Faculty member starts an attendance session for a specific `subjectId` and `sectionId`.
   - Firestore/Local mock generates a new `AttendanceSession` document.
2. **Logging**:
   - The list of students registered in the selected `sectionId` is loaded.
   - Faculty logs attendance status (`present` or `absent`) for each student.
   - Individual `AttendanceRecord`s are created linking back to the `sessionId`.
3. **Locking**:
   - Once submitted, the session enters an edit lock phase (defined globally, e.g. 24 hours).
   - Once locked, updates to that session are rejected unless overridden by an HOD or College Admin.

## Analytics Propagation

Attendance metrics are reactively parsed by the Analytics module:
- Changes in attendance records recalculate the `Overall Attendance` average.
- If a student's score falls below the required threshold (configured globally via settings), a `StudentShortage` entry is computed, which triggers a notification.
- Projections and risk levels (Warning/Critical) are updated reactively using these stats.
