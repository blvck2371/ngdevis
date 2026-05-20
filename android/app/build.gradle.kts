import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val storeFileProp = keystoreProperties.getProperty("storeFile")
val releaseKeystoreFile =
    if (storeFileProp != null) rootProject.file(storeFileProp) else null
val hasReleaseKeystore =
    keystorePropertiesFile.exists() &&
        storeFileProp != null &&
        releaseKeystoreFile != null &&
        releaseKeystoreFile.isFile

// CI Codemagic : identité Android « ngdevis » → CM_KEYSTORE_*, sinon la release retombe en debug → Play rejette le .aab
val cmKeystorePath = System.getenv("CM_KEYSTORE_PATH") ?: ""
val cmStorePwd = System.getenv("CM_KEYSTORE_PASSWORD")
val cmKeyAlias = System.getenv("CM_KEY_ALIAS")
val cmKeyPwd = System.getenv("CM_KEY_PASSWORD")
val codemagicReleaseSigning =
    cmKeystorePath.isNotBlank() &&
        !cmStorePwd.isNullOrBlank() &&
        !cmKeyAlias.isNullOrBlank() &&
        !cmKeyPwd.isNullOrBlank()

android {
    namespace = "com.devisng.app"
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
        // Identifiant unique sur le Play Store (ne pas réutiliser com.example).
        applicationId = "com.devisng.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")!!
                keyPassword = keystoreProperties.getProperty("keyPassword")!!
                storePassword = keystoreProperties.getProperty("storePassword")!!
                storeFile = releaseKeystoreFile!!
            }
        } else if (codemagicReleaseSigning) {
            create("release") {
                storeFile = file(cmKeystorePath)
                storePassword = cmStorePwd
                keyAlias = cmKeyAlias
                keyPassword = cmKeyPwd
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
            // RShink / minify : laisser false sauf si vous ajoutez des règles ProGuard Flutter.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
