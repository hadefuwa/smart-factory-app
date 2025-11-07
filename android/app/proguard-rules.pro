# Keep native methods for JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Snap7 JNI classes and methods
-keep class * extends java.lang.Object {
    native <methods>;
}

# Keep all classes in dart_snap7 package (if any Java/Kotlin bindings exist)
-keep class io.flutter.plugins.** { *; }
-keep class com.matrixtsl.smart_factory.** { *; }

# Keep JNI-related classes
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Preserve native library loading
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Don't warn about missing classes (native libraries)
-dontwarn **.R$*
-dontwarn **.R

# Flutter deferred components - Google Play Core is optional
# These classes are only needed if using deferred components feature
# R8 needs these rules to ignore missing optional dependencies
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager

# Ignore missing classes for deferred components (optional feature)
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep all native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

