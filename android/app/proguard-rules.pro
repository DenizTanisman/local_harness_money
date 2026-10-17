# WorkManager: WorkDatabase_Impl is instantiated via reflection by Room —
# R8 must not strip its no-arg constructor (release crash on startup).
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keepclassmembers class androidx.work.** { *; }

# flutter_local_notifications persists scheduled notifications with gson;
# generic signatures and the plugin's model classes must survive R8.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Huawei Wear Engine (watch quick entry): AIDL binders and parcelables are
# reached through Huawei Health — keep them intact.
-keep class com.huawei.wearengine.** { *; }
-keep class com.huawei.hmf.** { *; }
-dontwarn com.huawei.**
