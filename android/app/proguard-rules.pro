-keepattributes Signature
-keepattributes *Annotation*

# Moshi
-keep class com.ahmedkhaled.onroute.model.** { *; }
-keepclassmembers class com.ahmedkhaled.onroute.model.** { *; }

# Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
