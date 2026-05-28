plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.connectthrive"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.connectthrive"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFileVal = project.findProperty("MYAPP_UPLOAD_STORE_FILE") as? String
            val storePasswordVal = project.findProperty("MYAPP_UPLOAD_STORE_PASSWORD") as? String
            val keyAliasVal = project.findProperty("MYAPP_UPLOAD_KEY_ALIAS") as? String
            val keyPasswordVal = project.findProperty("MYAPP_UPLOAD_KEY_PASSWORD") as? String

            if (storeFileVal != null) {
                storeFile = file(storeFileVal)
                storePassword = storePasswordVal
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            ndk {
                debugSymbolLevel = "none"
            }
        }
    }

    packaging {
        jniLibs {
            doNotStrip.add("**/*.so")
            keepDebugSymbols.add("**/*.so")
        }
    }
}

flutter {
    source = "../.."
}
