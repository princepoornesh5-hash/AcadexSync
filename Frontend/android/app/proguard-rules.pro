# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase / Google Services
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

# Plugins
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }

# Suppress harmless warnings
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.google.android.play.core.**
