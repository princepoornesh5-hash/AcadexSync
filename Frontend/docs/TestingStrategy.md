# Testing Strategy

This document outlines the approach for verifying the correctness and reliability of Acadex's business-critical components.

## Testing Prioritization

1. **Unit Testing (High Priority)**:
   - **Projections Engine**: Verify mathematical calculations for `requiredClassesToReachTarget`.
   - **Risk Classification**: Verify mapping of attendance percentage to `goodStanding`, `warning`, and `critical` status levels.
   - **Search Filter Enforcement**: Verify search results are filtered depending on roles.
2. **Widget Testing (Medium Priority)**:
   - Verify layout and initial render of critical widgets (e.g. `LoginScreen`).
   - Ensure responsive components wrap or size correctly under small screens.
3. **Integration Testing (Future)**:
   - Verify routing transitions and authentication redirects under GoRouter configuration.

## Key Test Vectors

- **Attendance Projections**:
  - `total = 100, attended = 70, target = 75` -> expect required consecutive classes = 20.
  - `total = 100, attended = 80, target = 75` -> expect required consecutive classes = 0.
- **Risk Level**:
  - `percentage = 76.5, threshold = 75.0` -> expect `goodStanding`.
  - `percentage = 72.0, threshold = 75.0` -> expect `warning`.
  - `percentage = 61.2, threshold = 75.0` -> expect `critical`.
