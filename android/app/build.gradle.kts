plugins {
    id("com.android.application")
    id("com.google.gms.google-services") 
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}



android {
    namespace = "com.example.rrh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Keep your existing ndkVersion

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11 // Updated to VERSION_11
        targetCompatibility = JavaVersion.VERSION_11 // Updated to VERSION_11
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString() // Keep your existing jvmTarget
    }

    defaultConfig {
        applicationId = "com.example.rwanda_resilience_hub"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // isCoreLibraryDesugaringEnabled is handled by compileOptions, no need to repeat here.
        }
        debug {
            // isCoreLibraryDesugaringEnabled is handled by compileOptions, no need to repeat here.
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Keep your other existing dependencies here, for example:
    // implementation(platform("com.google.firebase:firebase-bom:32.7.4"))
    // implementation("com.google.firebase:firebase-analytics")
    implementation(platform("com.google.firebase:firebase-bom:33.14.0"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // Corrected syntax for Kotlin DSL
    implementation("com.google.firebase:firebase-analytics")
}

apply(plugin = "com.google.gms.google-services")

