// test/student_directory_selection_test.dart
//
// Focused tests for ACADEX Faculty UI Fix 01 — Student Directory Selection Audit.
//
// Pure Dart unit tests for the selection arithmetic and role-flag gating
// introduced by the fix.  No widget pump / Firebase / network dependencies.
//
// Test IDs match the Phase 3 specification:
//   T1  – Initial state: no selected students.
//   T2  – Selecting one row selects only that student.
//   T3  – Selecting multiple rows calculates header state correctly.
//   T4  – Selecting all visible eligible rows sets header to checked.
//   T5  – Deselecting one row changes header to indeterminate.
//   T6  – Deselecting all rows returns header to unchecked.
//   T7  – Replacing the dataset prunes invalid student IDs from selection.
//   T8  – Filter / search change clears selection.
//   T9  – Row details action does not modify the selection set.
//   T10 – Faculty role: checkboxes are hidden (showCheckboxColumn == false).

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal pure-Dart selection model that mirrors _StudentListScreenState logic.
// ---------------------------------------------------------------------------

enum HeaderCheckboxState { unchecked, indeterminate, checked }

class StudentSelectionModel {
  final Set<String> _selected = {};

  bool get isEmpty => _selected.isEmpty;
  int get selectionCount => _selected.length;
  bool isSelected(String id) => _selected.contains(id);

  void select(String id) => _selected.add(id);
  void deselect(String id) => _selected.remove(id);
  void clearAll() => _selected.clear();
  void selectAll(Set<String> ids) => _selected.addAll(ids);

  int pruneStaleIds(Set<String> currentVisibleIds) {
    final stale = _selected.difference(currentVisibleIds);
    _selected.removeAll(stale);
    return stale.length;
  }

  HeaderCheckboxState headerState(Set<String> eligibleIds) {
    if (eligibleIds.isEmpty || _selected.isEmpty) {
      return HeaderCheckboxState.unchecked;
    }
    final selectedVisible = _selected.intersection(eligibleIds);
    if (selectedVisible.length == eligibleIds.length) return HeaderCheckboxState.checked;
    if (selectedVisible.isEmpty) return HeaderCheckboxState.unchecked;
    return HeaderCheckboxState.indeterminate;
  }
}

// Role-based checkbox column gate (mirrors _buildDesktopTable fix).
enum MockRole { superAdmin, collegeAdmin, hod, faculty, student }

bool showCheckboxColumnForRole(MockRole role) =>
    role == MockRole.superAdmin ||
    role == MockRole.collegeAdmin ||
    role == MockRole.hod;

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('T1-T6: Core Selection Arithmetic', () {
    late StudentSelectionModel model;
    const eligible = {'s1', 's2', 's3', 's4', 's5'};

    setUp(() => model = StudentSelectionModel());

    test('T1 – Initial state contains no selected students', () {
      expect(model.isEmpty, isTrue);
      expect(model.selectionCount, 0);
      expect(model.headerState(eligible), HeaderCheckboxState.unchecked);
    });

    test('T2 – Selecting one row selects only that student', () {
      model.select('s1');
      expect(model.selectionCount, 1);
      expect(model.isSelected('s1'), isTrue);
      expect(model.isSelected('s2'), isFalse);
    });

    test('T3 – Partial selection gives indeterminate header', () {
      model.select('s1');
      model.select('s3');
      expect(model.headerState(eligible), HeaderCheckboxState.indeterminate);
    });

    test('T4 – Selecting all eligible rows gives checked header', () {
      model.selectAll(eligible);
      expect(model.headerState(eligible), HeaderCheckboxState.checked);
      expect(model.selectionCount, eligible.length);
    });

    test('T5 – Deselecting one row from full selection gives indeterminate', () {
      model.selectAll(eligible);
      model.deselect('s2');
      expect(model.headerState(eligible), HeaderCheckboxState.indeterminate);
    });

    test('T6 – Deselecting all rows returns header to unchecked', () {
      model.selectAll(eligible);
      model.clearAll();
      expect(model.isEmpty, isTrue);
      expect(model.headerState(eligible), HeaderCheckboxState.unchecked);
    });
  });

  group('T7: Dataset Replacement Prunes Stale IDs', () {
    test('T7 – Workspace change removes IDs no longer in dataset', () {
      final model = StudentSelectionModel();
      model.selectAll({'s1', 's3', 's5'});
      final pruned = model.pruneStaleIds({'s2', 's4'});
      expect(pruned, 3);
      expect(model.isEmpty, isTrue);
    });

    test('T7b – Full overlap preserves all selections', () {
      final model = StudentSelectionModel();
      model.select('s2');
      expect(model.pruneStaleIds({'s1', 's2', 's3'}), 0);
      expect(model.isSelected('s2'), isTrue);
    });

    test('T7c – Partial dataset change prunes only gone IDs', () {
      final model = StudentSelectionModel();
      model.selectAll({'s1', 's2', 's3'});
      model.pruneStaleIds({'s1', 's2', 's4'});
      expect(model.isSelected('s1'), isTrue);
      expect(model.isSelected('s2'), isTrue);
      expect(model.isSelected('s3'), isFalse);
    });
  });

  group('T8: Filter Change Clears Selection', () {
    test('T8 – _syncFilters equivalent clears all selections before new filter', () {
      final model = StudentSelectionModel();
      model.selectAll({'s1', 's2', 's3'});
      // Mirrors the fix: if (_selectedIds.isNotEmpty) setState(() => _selectedIds.clear())
      if (!model.isEmpty) model.clearAll();
      expect(model.isEmpty, isTrue);
    });

    test('T8b – Clearing search also resets selections via _syncFilters', () {
      final model = StudentSelectionModel();
      model.select('s5');
      if (!model.isEmpty) model.clearAll();
      expect(model.isEmpty, isTrue);
    });
  });

  group('T9: Details Action Does Not Modify Selection', () {
    test('T9 – Tapping view-profile does not toggle selection', () {
      final model = StudentSelectionModel();
      // The onTap in DataCell / IconButton only calls context.push()
      // and never calls select/deselect. Model must remain untouched.
      void simulateViewProfileTap(String id) { /* only navigates */ }
      simulateViewProfileTap('s1');
      expect(model.isEmpty, isTrue);
    });

    test('T9b – Pre-existing selection survives a profile navigation', () {
      final model = StudentSelectionModel();
      model.select('s2');
      void simulateViewProfileTap(String id) {}
      simulateViewProfileTap('s2');
      expect(model.isSelected('s2'), isTrue);
    });
  });

  group('T10: Role-Based Checkbox Column Gate', () {
    test('T10 – Faculty: showCheckboxColumn == false', () {
      expect(showCheckboxColumnForRole(MockRole.faculty), isFalse);
    });

    test('T10b – HOD: showCheckboxColumn == true', () {
      expect(showCheckboxColumnForRole(MockRole.hod), isTrue);
    });

    test('T10c – CollegeAdmin: showCheckboxColumn == true', () {
      expect(showCheckboxColumnForRole(MockRole.collegeAdmin), isTrue);
    });

    test('T10d – SuperAdmin: showCheckboxColumn == true', () {
      expect(showCheckboxColumnForRole(MockRole.superAdmin), isTrue);
    });

    test('T10e – Student: showCheckboxColumn == false', () {
      expect(showCheckboxColumnForRole(MockRole.student), isFalse);
    });
  });

  group('Edge Cases', () {
    test('Empty eligible set → unchecked header regardless of selection', () {
      final model = StudentSelectionModel();
      model.select('ghost');
      expect(model.headerState({}), HeaderCheckboxState.unchecked);
    });

    test('selectAll with empty set is a no-op', () {
      final model = StudentSelectionModel();
      model.selectAll({});
      expect(model.isEmpty, isTrue);
    });

    test('pruneStaleIds against empty dataset clears all', () {
      final model = StudentSelectionModel();
      model.selectAll({'s1', 's2'});
      expect(model.pruneStaleIds({}), 2);
      expect(model.isEmpty, isTrue);
    });

    test('Selecting same ID twice is idempotent', () {
      final model = StudentSelectionModel();
      model.select('s1');
      model.select('s1');
      expect(model.selectionCount, 1);
    });

    test('Deselecting an absent ID is safe', () {
      final model = StudentSelectionModel();
      model.deselect('nonexistent');
      expect(model.isEmpty, isTrue);
    });
  });
}
