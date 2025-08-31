# FILE: android/app/proguard-rules.pro
# Flutter's Proguard rules for release builds.
-dontwarn io.flutter.embedding.**
-keep class io.flutter.embedding.android.FlutterActivity
-keep class io.flutter.embedding.android.FlutterFragment
-keep class io.flutter.embedding.android.FlutterView
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep your application's main activity class.
-keep class com.workshop.ix.mykeyapp.MainActivity { *; }