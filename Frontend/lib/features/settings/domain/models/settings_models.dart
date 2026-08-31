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
  final bool attendanceAlerts;
  final bool academicUpdates;
  final bool announcements;
  final bool notesUploaded;
  final bool certificateUpdates;
  final bool generalNotifications;

  const NotificationPreferences({
    required this.attendanceAlerts,
    required this.academicUpdates,
    required this.announcements,
    required this.notesUploaded,
    required this.certificateUpdates,
    required this.generalNotifications,
  });

  NotificationPreferences copyWith({
    bool? attendanceAlerts,
    bool? academicUpdates,
    bool? announcements,
    bool? notesUploaded,
    bool? certificateUpdates,
    bool? generalNotifications,
  }) {
    return NotificationPreferences(
      attendanceAlerts: attendanceAlerts ?? this.attendanceAlerts,
      academicUpdates: academicUpdates ?? this.academicUpdates,
      announcements: announcements ?? this.announcements,
      notesUploaded: notesUploaded ?? this.notesUploaded,
      certificateUpdates: certificateUpdates ?? this.certificateUpdates,
      generalNotifications: generalNotifications ?? this.generalNotifications,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      attendanceAlerts: json['attendanceAlerts'] ?? true,
      academicUpdates: json['academicUpdates'] ?? true,
      announcements: json['announcements'] ?? true,
      notesUploaded: json['notesUploaded'] ?? true,
      certificateUpdates: json['certificateUpdates'] ?? true,
      generalNotifications: json['generalNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendanceAlerts': attendanceAlerts,
      'academicUpdates': academicUpdates,
      'announcements': announcements,
      'notesUploaded': notesUploaded,
      'certificateUpdates': certificateUpdates,
      'generalNotifications': generalNotifications,
    };
  }

  // Factory for default preferences
  factory NotificationPreferences.defaults() {
    return const NotificationPreferences(
      attendanceAlerts: true,
      academicUpdates: true,
      announcements: true,
      notesUploaded: false,
      certificateUpdates: false,
      generalNotifications: true,
    );
  }
}
