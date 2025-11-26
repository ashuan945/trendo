import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
val flutterVersionCodeInt = if (flutterVersionCode == null) {
    1
} else {
    flutterVersionCode.toInt()
}

val flutterVersionName = localProperties.getProperty("flutter.versionName")
val flutterVersionNameStr = if (flutterVersionName == null) {
    "1.0"
} else {
    flutterVersionName
}

android {
    namespace = "com.example.trendo" // Replace with your actual package name
    compileSdk = 35
    
    // Add this NDK version specification
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.trendo" // Replace with your actual app ID
        minSdk = 24
        targetSdk = 34
        versionCode = flutterVersionCodeInt
        versionName = flutterVersionNameStr
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}