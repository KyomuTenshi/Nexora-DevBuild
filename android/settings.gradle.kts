// AGP 9+ compatibility: fix AndroidLocationsException when both ANDROID_PREFS_ROOT and ANDROID_USER_HOME are set
try {
    val pe = Class.forName("java.lang.ProcessEnvironment")
    val theEnvField = pe.getDeclaredField("theEnvironment")
    theEnvField.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val map = theEnvField.get(null) as? MutableMap<Any, Any>
    if (map != null) {
        val toRemove = map.keys.filter { it.toString() == "ANDROID_PREFS_ROOT" }
        for (k in toRemove) {
            map.remove(k)
        }
    }
} catch (_: Throwable) {
}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.4.4") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    id("com.google.firebase.crashlytics") version "3.0.8" apply false
}

include(":app")
