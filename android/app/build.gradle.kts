import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chargement du fichier key.properties (à la racine du dossier android)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.myapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fastclean.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // CONFIG SIGNATURE RELEASE
    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "4612azer+!AZ"
            storeFile = rootProject.file("upload-keystore-new.jks")
            storePassword = "4612azer+!AZ"
        }
    }

    buildTypes {
        release {
            // On signe maintenant avec la config release (et plus avec debug)
            signingConfig = signingConfigs.getByName("release")
            // Tu peux laisser l’optimisation par défaut ou ajouter :
            // isMinifyEnabled = false
            // isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
