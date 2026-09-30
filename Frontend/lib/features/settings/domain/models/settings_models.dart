import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String language;
  final double fontScale;

  const AppSettings({
    required this.themeMode,
    required this.language,
    required this.fontScale,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? language,
    double? fontScale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.light,
      language: json['language'] ?? 'en',
      fontScale: (json['fontScale'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': 'light',
      'language': language,
      'fontScale': fontScale,
    };
  }

  // Factory for default settings
  factory AppSettings.defaults() {
    return const AppSettings(
      themeMode: ThemeMode.light,
      language: 'en',
      fontScale: 1.0,
    );
  }
}

class NotificationPreferences {
  final bool inAppEnabled;
  final bool pushEnabled;
  final bool attendanceAlerts;
  final bool academicUpdates;
  final bool assignments;
  final bool practicals;
  final bool assessments;
  final bool calendar;
  final bool announcements;
  final bool notesUploaded;
  final bool timetable;
  final bool certificateUpdates;
  final bool generalNotifications;
  final bool academicResults;
  final bool system;

  const NotificationPreferences({
    this.inAppEnabled = true,
    this.pushEnabled = true,
    required this.attendanceAlerts,
    required this.academicUpdates,
    this.assignments = true,
    this.practicals = true,
    this.assessments = true,
    this.calendar = true,
    required this.announcements,
    required this.notesUploaded,
    this.timetable = true,
    required this.certificateUpdates,
    required this.generalNotifications,
    this.academicResults = true,
    this.system = true,
  });

  // Backward compatible aliases
  bool get notes => notesUploaded;
  bool get attendance => attendanceAlerts;
  bool get academic => academicUpdates;

  NotificationPreferences copyWith({
    bool? inAppEnabled,
    bool? pushEnabled,
    bool? attendanceAlerts,
    bool? academicUpdates,
    bool? assignments,
    bool? practicals,
    bool? assessments,
    bool? calendar,
    bool? announcements,
    bool? notesUploaded,
    bool? timetable,
    bool? certificateUpdates,
    bool? generalNotifications,
    bool? academicResults,
    bool? system,
  }) {
    return NotificationPreferences(
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      attendanceAlerts: attendanceAlerts ?? this.attendanceAlerts,
      academicUpdates: academicUpdates ?? this.academicUpdates,
      assignments: assignments ?? this.assignments,
      practicals: practicals ?? this.practicals,
      assessments: assessments ?? this.assessments,
      calendar: calendar ?? this.calendar,
      announcements: announcements ?? this.announcements,
      notesUploaded: notesUploaded ?? this.notesUploaded,
      timetable: timetable ?? this.timetable,
      certificateUpdates: certificateUpdates ?? this.certificateUpdates,
      generalNotifications: generalNotifications ?? this.generalNotifications,
      academicResults: true, // Mandatory
      system: true, // Mandatory
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      inAppEnabled: json['inAppEnabled'] ?? true,
      pushEnabled: json['pushEnabled'] ?? true,
      attendanceAlerts: json['attendance'] ?? json['attendanceAlerts'] ?? true,
      academicUpdates: json['academic'] ?? json['academicUpdates'] ?? true,
      assignments: json['assignments'] ?? true,
      practicals: json['practicals'] ?? true,
      assessments: json['assessments'] ?? true,
      calendar: json['calendar'] ?? true,
      announcements: json['announcements'] ?? true,
      notesUploaded: json['notes'] ?? json['notesUploaded'] ?? true,
      timetable: json['timetable'] ?? true,
      certificateUpdates: json['certificateUpdates'] ?? true,
      generalNotifications: json['system'] ?? json['generalNotifications'] ?? true,
      academicResults: true,
      system: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inAppEnabled': inAppEnabled,
      'pushEnabled': pushEnabled,
      'attendance': attendanceAlerts,
      'attendanceAlerts': attendanceAlerts,
      'academic': academicUpdates,
      'academicUpdates': academicUpdates,
      'assignments': assignments,
      'practicals': practicals,
      'assessments': assessments,
      'calendar': calendar,
      'announcements': announcements,
      'notes': notesUploaded,
      'notesUploaded': notesUploaded,
      'timetable': timetable,
      'certificateUpdates': certificateUpdates,
      'generalNotifications': generalNotifications,
      'academicResults': true,
      'system': true,
    };
  }

  // Factory for default preferences
  factory NotificationPreferences.defaults() {
    return const NotificationPreferences(
      inAppEnabled: true,
      pushEnabled: true,
      attendanceAlerts: true,
      academicUpdates: true,
      assignments: true,
      practicals: true,
      assessments: true,
      calendar: true,
      announcements: true,
      notesUploaded: true,
      timetable: true,
      certificateUpdates: true,
      generalNotifications: true,
      academicResults: true,
      system: true,
    );
  }
}
