plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.eseason"
    compileSdk = 36 // Updated to support required plugins (google_sign_in, path_provider require 36)
    ndkVersion = "27.0.12077973" // Updated to the highest required NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11 // Updated to Java 11
        targetCompatibility = JavaVersion.VERSION_11 // Updated to Java 11
    }

    kotlinOptions {
        jvmTarget = "11" // Updated to Java 11
    }
    
    defaultConfig {
        // Specify your own unique Application ID
        applicationId = "com.example.eseason"
        // Update the following values to match your application needs
        minSdk = flutter.minSdkVersion // Updated to the required minSdkVersion
        targetSdk = 35 // Updated to support required plugins
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // Add your own signing config for the release build
            // Signing with the debug keys for now, so `flutter run --release` works
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    
    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
    
    // Firebase Authentication
    implementation("com.google.firebase:firebase-auth")
    
    // Cloud Firestore
    implementation("com.google.firebase:firebase-firestore")
    
    // Realtime Database
    implementation("com.google.firebase:firebase-database")
    
    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth")
}
