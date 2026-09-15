enum TimetableDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  String get shortName {
    return name.substring(0, 3).toUpperCase();
  }
}

enum TimetableSessionType {
  lecture,
  lab,
  tutorial,
  practical,
  seminar,
  other;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

enum TimetableStatus {
  draft,
  published,
  archived;

  String get displayName {
    switch (this) {
      case TimetableStatus.draft:
        return 'Draft';
      case TimetableStatus.published:
        return 'Published';
      case TimetableStatus.archived:
        return 'Archived';
    }
  }

  static TimetableStatus fromString(String? value) {
    if (value == null) return TimetableStatus.draft;
    return TimetableStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TimetableStatus.draft,
    );
  }
}

enum TimetableTimingMode {
  sameEveryDay,
  differentPerDay;

  String get displayName {
    switch (this) {
      case TimetableTimingMode.sameEveryDay:
        return 'Same Timing Every Day';
      case TimetableTimingMode.differentPerDay:
        return 'Different Timing Per Day';
    }
  }

  static TimetableTimingMode fromString(String? value) {
    if (value == null) return TimetableTimingMode.sameEveryDay;
    return TimetableTimingMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TimetableTimingMode.sameEveryDay,
    );
  }
}

enum TimetableBreakType {
  lunch,
  tea,
  assembly,
  custom;

  String get displayName {
    switch (this) {
      case TimetableBreakType.lunch:
        return 'Lunch Break';
      case TimetableBreakType.tea:
        return 'Tea Break';
      case TimetableBreakType.assembly:
        return 'Assembly';
      case TimetableBreakType.custom:
        return 'Custom Break';
    }
  }

  static TimetableBreakType fromString(String? value) {
    if (value == null) return TimetableBreakType.lunch;
    return TimetableBreakType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TimetableBreakType.lunch,
    );
  }
}

void _validateTimeFormat(String time, String fieldName) {
  final regex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  if (!regex.hasMatch(time)) {
    throw ArgumentError('Invalid $fieldName time format "$time". Expected "HH:mm" (24-hour format).');
  }
}

/// Legacy TimetableModel representing a single timetable class entry.
/// Preserved for complete backward compatibility with existing services, UI, and Attendance module.
class TimetableModel {
  final String id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String academicYearId;
  final String semesterId;
  final String sectionId;
  final String subjectId;
  final String facultyId;
  final TimetableDay dayOfWeek;
  /// Format: "HH:mm" (24-hour)
  final String startTime;
  /// Format: "HH:mm" (24-hour)
  final String endTime;
  final String? timetableId;
  final String? facultyAssignmentId;
  final String? roomId;
  final String roomNumber;
  final String? building;
  final TimetableSessionType sessionType;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimetableModel({
    required this.id,
    this.timetableId,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.academicYearId,
    required this.semesterId,
    required this.sectionId,
    required this.subjectId,
    required this.facultyId,
    this.facultyAssignmentId,
    this.roomId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
    this.building,
    required this.sessionType,
    required this.createdAt,
    required this.updatedAt,
  });

  TimetableModel copyWith({
    String? id,
    String? timetableId,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    String? subjectId,
    String? facultyId,
    String? facultyAssignmentId,
    String? roomId,
    TimetableDay? dayOfWeek,
    String? startTime,
    String? endTime,
    String? roomNumber,
    String? building,
    TimetableSessionType? sessionType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimetableModel(
      id: id ?? this.id,
      timetableId: timetableId ?? this.timetableId,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      facultyId: facultyId ?? this.facultyId,
      facultyAssignmentId: facultyAssignmentId ?? this.facultyAssignmentId,
      roomId: roomId ?? this.roomId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomNumber: roomNumber ?? this.roomNumber,
      building: building ?? this.building,
      sessionType: sessionType ?? this.sessionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      timetableId: json['timetableId'] as String?,
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      facultyAssignmentId: json['facultyAssignmentId'] as String?,
      roomId: json['roomId'] as String?,
      dayOfWeek: TimetableDay.values.firstWhere(
        (e) => e.name == json['dayOfWeek'],
        orElse: () => TimetableDay.monday,
      ),
      startTime: json['startTime'] as String? ?? '00:00',
      endTime: json['endTime'] as String? ?? '00:00',
      roomNumber: json['roomNumber'] as String? ?? '',
      building: json['building'] as String?,
      sessionType: TimetableSessionType.values.firstWhere(
        (e) => e.name == json['sessionType'],
        orElse: () => TimetableSessionType.lecture,
      ),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (timetableId != null) 'timetableId': timetableId,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'facultyId': facultyId,
      if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
      if (roomId != null) 'roomId': roomId,
      'dayOfWeek': dayOfWeek.name,
      'startTime': startTime,
      'endTime': endTime,
      'roomNumber': roomNumber,
      if (building != null) 'building': building,
      'sessionType': sessionType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool overlapsWith(TimetableModel other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    return startTime.compareTo(other.endTime) < 0 && endTime.compareTo(other.startTime) > 0;
  }
}

/// Represents the complete Timetable container belonging to one academic context (Section + Academic Year).
class TimetableContainerModel {
  final String id;
  final String collegeId;
  final String departmentId;
  final String courseId;
  final String academicYearId;
  final String semesterId;
  final String sectionId;
  final String name;
  final TimetableStatus status;
  final int version;
  final List<TimetableDay> activeDays;
  final TimetableTimingMode timingMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String? publishedBy;

  TimetableContainerModel({
    required this.id,
    required this.collegeId,
    required this.departmentId,
    required this.courseId,
    required this.academicYearId,
    required this.semesterId,
    required this.sectionId,
    required this.name,
    this.status = TimetableStatus.draft,
    this.version = 1,
    this.activeDays = const [
      TimetableDay.monday,
      TimetableDay.tuesday,
      TimetableDay.wednesday,
      TimetableDay.thursday,
      TimetableDay.friday,
    ],
    this.timingMode = TimetableTimingMode.sameEveryDay,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.publishedBy,
  });

  bool get isDraft => status == TimetableStatus.draft;
  bool get isPublished => status == TimetableStatus.published;
  bool get isArchived => status == TimetableStatus.archived;

  TimetableContainerModel copyWith({
    String? id,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? academicYearId,
    String? semesterId,
    String? sectionId,
    String? name,
    TimetableStatus? status,
    int? version,
    List<TimetableDay>? activeDays,
    TimetableTimingMode? timingMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? publishedBy,
    bool clearPublished = false,
  }) {
    return TimetableContainerModel(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      academicYearId: academicYearId ?? this.academicYearId,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      status: status ?? this.status,
      version: version ?? this.version,
      activeDays: activeDays ?? this.activeDays,
      timingMode: timingMode ?? this.timingMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: clearPublished ? null : (publishedAt ?? this.publishedAt),
      publishedBy: clearPublished ? null : (publishedBy ?? this.publishedBy),
    );
  }

  factory TimetableContainerModel.fromJson(Map<String, dynamic> json) {
    final activeDaysRaw = json['activeDays'];
    List<TimetableDay> activeDaysList = [];
    if (activeDaysRaw is List) {
      activeDaysList = activeDaysRaw.map((d) {
        return TimetableDay.values.firstWhere(
          (day) => day.name == d,
          orElse: () => TimetableDay.monday,
        );
      }).toList();
    }
    if (activeDaysList.isEmpty) {
      activeDaysList = const [
        TimetableDay.monday,
        TimetableDay.tuesday,
        TimetableDay.wednesday,
        TimetableDay.thursday,
        TimetableDay.friday,
      ];
    }

    return TimetableContainerModel(
      id: json['id'] as String? ?? '',
      collegeId: json['collegeId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      semesterId: json['semesterId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: TimetableStatus.fromString(json['status'] as String?),
      version: (json['version'] as num?)?.toInt() ?? 1,
      activeDays: activeDaysList,
      timingMode: TimetableTimingMode.fromString(json['timingMode'] as String?),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt'] as String) : null,
      publishedBy: json['publishedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'academicYearId': academicYearId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'name': name,
      'status': status.name,
      'version': version,
      'activeDays': activeDays.map((d) => d.name).toList(),
      'timingMode': timingMode.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      if (publishedBy != null) 'publishedBy': publishedBy,
    };
  }

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Timetable container name cannot be empty');
    }
    if (activeDays.isEmpty) {
      throw ArgumentError('Timetable must have at least one active working day');
    }
    if (version < 1) {
      throw ArgumentError('Version must be >= 1');
    }
  }
}

/// Represents a defined period / bell schedule slot in the timetable.
class TimetablePeriodModel {
  final String id;
  /// 1-indexed period position (e.g. 1 for Period 1, 2 for Period 2)
  final int index;
  /// Display name (e.g. "Period 1", "P1")
  final String name;
  /// Format: "HH:mm" (24-hour)
  final String startTime;
  /// Format: "HH:mm" (24-hour)
  final String endTime;
  /// Null if applies to all days in sameEveryDay mode; specified for day-specific timings
  final TimetableDay? dayOfWeek;

  TimetablePeriodModel({
    required this.id,
    required this.index,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.dayOfWeek,
  });

  int get durationInMinutes {
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final startM = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endM = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      return endM - startM;
    } catch (_) {
      return 0;
    }
  }

  TimetablePeriodModel copyWith({
    String? id,
    int? index,
    String? name,
    String? startTime,
    String? endTime,
    TimetableDay? dayOfWeek,
    bool clearDayOfWeek = false,
  }) {
    return TimetablePeriodModel(
      id: id ?? this.id,
      index: index ?? this.index,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayOfWeek: clearDayOfWeek ? null : (dayOfWeek ?? this.dayOfWeek),
    );
  }

  factory TimetablePeriodModel.fromJson(Map<String, dynamic> json) {
    return TimetablePeriodModel(
      id: json['id'] as String? ?? '',
      index: (json['index'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '00:00',
      endTime: json['endTime'] as String? ?? '00:00',
      dayOfWeek: json['dayOfWeek'] != null
          ? TimetableDay.values.firstWhere(
              (d) => d.name == json['dayOfWeek'],
              orElse: () => TimetableDay.monday,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek!.name,
    };
  }

  void validate() {
    if (index < 1) {
      throw ArgumentError('Period index must be >= 1');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Period name cannot be empty');
    }
    _validateTimeFormat(startTime, 'startTime');
    _validateTimeFormat(endTime, 'endTime');
    if (startTime.compareTo(endTime) >= 0) {
      throw ArgumentError('Period startTime ($startTime) must be strictly before endTime ($endTime)');
    }
  }
}

/// Represents a common or day-specific break (lunch, tea, assembly) in the timetable.
class TimetableBreakModel {
  final String id;
  final String name;
  /// Format: "HH:mm" (24-hour)
  final String startTime;
  /// Format: "HH:mm" (24-hour)
  final String endTime;
  /// Days this break applies to. A single record applies to multiple days without per-cell duplication.
  final List<TimetableDay> appliesToDays;
  /// Whether UI renders this as a single visual vertical line/block across days
  final bool isVerticalSpan;
  final TimetableBreakType breakType;

  TimetableBreakModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.appliesToDays,
    this.isVerticalSpan = true,
    this.breakType = TimetableBreakType.lunch,
  });

  bool appliesTo(TimetableDay day) => appliesToDays.contains(day);

  int get durationInMinutes {
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final startM = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endM = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      return endM - startM;
    } catch (_) {
      return 0;
    }
  }

  bool overlapsWithTime(String otherStart, String otherEnd) {
    return startTime.compareTo(otherEnd) < 0 && endTime.compareTo(otherStart) > 0;
  }

  TimetableBreakModel copyWith({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
    List<TimetableDay>? appliesToDays,
    bool? isVerticalSpan,
    TimetableBreakType? breakType,
  }) {
    return TimetableBreakModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      appliesToDays: appliesToDays ?? this.appliesToDays,
      isVerticalSpan: isVerticalSpan ?? this.isVerticalSpan,
      breakType: breakType ?? this.breakType,
    );
  }

  factory TimetableBreakModel.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['appliesToDays'];
    List<TimetableDay> days = [];
    if (daysRaw is List) {
      days = daysRaw.map((d) {
        return TimetableDay.values.firstWhere(
          (day) => day.name == d,
          orElse: () => TimetableDay.monday,
        );
      }).toList();
    }

    return TimetableBreakModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '00:00',
      endTime: json['endTime'] as String? ?? '00:00',
      appliesToDays: days,
      isVerticalSpan: json['isVerticalSpan'] as bool? ?? true,
      breakType: TimetableBreakType.fromString(json['breakType'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'appliesToDays': appliesToDays.map((d) => d.name).toList(),
      'isVerticalSpan': isVerticalSpan,
      'breakType': breakType.name,
    };
  }

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Break name cannot be empty');
    }
    if (appliesToDays.isEmpty) {
      throw ArgumentError('Break must apply to at least one day');
    }
    _validateTimeFormat(startTime, 'startTime');
    _validateTimeFormat(endTime, 'endTime');
    if (startTime.compareTo(endTime) >= 0) {
      throw ArgumentError('Break startTime ($startTime) must be strictly before endTime ($endTime)');
    }
  }
}

/// Represents one teaching entry in the spreadsheet timetable grid.
/// Supports single-period or multi-period merged horizontal classes without duplicating records.
class TimetableGridEntryModel {
  final String id;
  final TimetableDay dayOfWeek;
  /// 1-indexed starting period (e.g. 1 for Period 1, 2 for Period 2)
  final int startPeriodIndex;
  /// Number of consecutive periods this entry occupies (1 = single period, 2 = 2-period lab, etc.)
  final int periodSpan;
  /// Format: "HH:mm" (24-hour)
  final String startTime;
  /// Format: "HH:mm" (24-hour)
  final String endTime;
  final String subjectId;
  final String facultyId;
  final String? facultyAssignmentId;
  final String? roomId;
  final String roomNumber;
  final String? building;
  final TimetableSessionType sessionType;

  TimetableGridEntryModel({
    required this.id,
    required this.dayOfWeek,
    required this.startPeriodIndex,
    this.periodSpan = 1,
    required this.startTime,
    required this.endTime,
    required this.subjectId,
    required this.facultyId,
    this.facultyAssignmentId,
    this.roomId,
    required this.roomNumber,
    this.building,
    required this.sessionType,
  });

  /// Whether this entry merges across multiple consecutive horizontal periods
  bool get isMergedHorizontal => periodSpan > 1;

  /// The 1-indexed ending period index (inclusive).
  /// Example: startPeriodIndex = 2, periodSpan = 3 -> endPeriodIndex = 4 (periods 2, 3, 4)
  int get endPeriodIndex => startPeriodIndex + periodSpan - 1;

  /// Returns the list of all 1-indexed period numbers occupied by this entry.
  /// Example: startPeriodIndex = 2, periodSpan = 3 -> [2, 3, 4]
  List<int> get occupiedPeriodIndexes => List.generate(periodSpan, (i) => startPeriodIndex + i);

  /// Checks if this entry occupies a specific 1-indexed period on its day
  bool occupiesPeriod(int periodIndex) {
    return periodIndex >= startPeriodIndex && periodIndex <= endPeriodIndex;
  }

  /// Checks if two entries on the same day overlap horizontally in period index range
  bool overlapsHorizontallyWith(TimetableGridEntryModel other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    return startPeriodIndex <= other.endPeriodIndex && endPeriodIndex >= other.startPeriodIndex;
  }

  /// Checks if this entry collides with another entry by time range on the same day
  bool overlapsTimeWith(TimetableGridEntryModel other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    return startTime.compareTo(other.endTime) < 0 && endTime.compareTo(other.startTime) > 0;
  }

  /// Checks if this entry conflicts with a break (same day and overlapping time)
  bool conflictsWithBreak(TimetableBreakModel breakModel) {
    if (!breakModel.appliesTo(dayOfWeek)) return false;
    return breakModel.overlapsWithTime(startTime, endTime);
  }

  TimetableGridEntryModel copyWith({
    String? id,
    TimetableDay? dayOfWeek,
    int? startPeriodIndex,
    int? periodSpan,
    String? startTime,
    String? endTime,
    String? subjectId,
    String? facultyId,
    String? facultyAssignmentId,
    String? roomId,
    String? roomNumber,
    String? building,
    TimetableSessionType? sessionType,
  }) {
    return TimetableGridEntryModel(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startPeriodIndex: startPeriodIndex ?? this.startPeriodIndex,
      periodSpan: periodSpan ?? this.periodSpan,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subjectId: subjectId ?? this.subjectId,
      facultyId: facultyId ?? this.facultyId,
      facultyAssignmentId: facultyAssignmentId ?? this.facultyAssignmentId,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      building: building ?? this.building,
      sessionType: sessionType ?? this.sessionType,
    );
  }

  factory TimetableGridEntryModel.fromJson(Map<String, dynamic> json) {
    return TimetableGridEntryModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      dayOfWeek: TimetableDay.values.firstWhere(
        (e) => e.name == json['dayOfWeek'],
        orElse: () => TimetableDay.monday,
      ),
      startPeriodIndex: (json['startPeriodIndex'] as num?)?.toInt() ?? 1,
      periodSpan: (json['periodSpan'] as num?)?.toInt() ?? 1,
      startTime: json['startTime'] as String? ?? '00:00',
      endTime: json['endTime'] as String? ?? '00:00',
      subjectId: json['subjectId'] as String? ?? '',
      facultyId: json['facultyId'] as String? ?? '',
      facultyAssignmentId: json['facultyAssignmentId'] as String?,
      roomId: json['roomId'] as String?,
      roomNumber: json['roomNumber'] as String? ?? '',
      building: json['building'] as String?,
      sessionType: TimetableSessionType.values.firstWhere(
        (e) => e.name == json['sessionType'],
        orElse: () => TimetableSessionType.lecture,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek.name,
      'startPeriodIndex': startPeriodIndex,
      'periodSpan': periodSpan,
      'startTime': startTime,
      'endTime': endTime,
      'subjectId': subjectId,
      'facultyId': facultyId,
      if (facultyAssignmentId != null) 'facultyAssignmentId': facultyAssignmentId,
      if (roomId != null) 'roomId': roomId,
      'roomNumber': roomNumber,
      if (building != null) 'building': building,
      'sessionType': sessionType.name,
      'isMergedHorizontal': isMergedHorizontal,
    };
  }

  void validate() {
    if (startPeriodIndex < 1) {
      throw ArgumentError('startPeriodIndex must be >= 1');
    }
    if (periodSpan < 1) {
      throw ArgumentError('periodSpan must be >= 1');
    }
    _validateTimeFormat(startTime, 'startTime');
    _validateTimeFormat(endTime, 'endTime');
    if (startTime.compareTo(endTime) >= 0) {
      throw ArgumentError('Entry startTime ($startTime) must be strictly before endTime ($endTime)');
    }
  }
}

