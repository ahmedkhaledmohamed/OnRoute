-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses

# Moshi
-keep class com.ahmedkhaled.onroute.model.** { *; }
-keepclassmembers class com.ahmedkhaled.onroute.model.** { *; }
-keep class com.squareup.moshi.** { *; }
-keepclassmembers class * {
    @com.squareup.moshi.Json <fields>;
}
-keepnames @com.squareup.moshi.JsonClass class *

# Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Coil
-keep class coil.** { *; }
-dontwarn coil.**

# Google Places SDK
-keep class com.google.android.libraries.places.** { *; }
-dontwarn com.google.android.libraries.places.**

# AndroidX DataStore
-keep class androidx.datastore.** { *; }
-dontwarn androidx.datastore.**
