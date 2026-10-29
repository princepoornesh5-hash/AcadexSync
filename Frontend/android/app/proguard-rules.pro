# Flutter Engine & Plugins
-keep class io.flutter.facade.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugins.** { *; }

# Plugins
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Firebase & Google Play Services: Use embedded AAR consumer rules
# Suppress harmless warnings from optional dependencies
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.google.android.play.core.**
