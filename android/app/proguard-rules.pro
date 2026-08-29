# Flutter proguard rules
# Keep Flutter's core classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native plugin classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep all classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable creators
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Fix R8 missing classes for Play Core (not bundled, only via Play Store)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.app.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager$*

# Kotlin metadata
-keepattributes *Annotation*
-keepclassmembers class ** {
    @androidx.annotation.Keep *;
}

